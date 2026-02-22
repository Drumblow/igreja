use crate::application::dto::{AuthUser, Claims, LoginRequest, LoginResponse};
use crate::config::AppConfig;
use crate::errors::AppError;
use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::SaltString;
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use chrono::{DateTime, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use lettre::message::header::ContentType;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

#[derive(Debug, FromRow)]
struct UserLoginRow {
    id: Uuid,
    email: String,
    password_hash: String,
    church_id: Uuid,
    is_active: bool,
    failed_attempts: i32,
    locked_until: Option<DateTime<Utc>>,
    role_name: String,
    role_permissions: serde_json::Value,
    church_name: String,
    member_id: Option<Uuid>,
    force_password_change: bool,
}

/// Scope information determined at login time
struct ScopeInfo {
    scope_type: String,
    congregation_ids: Vec<Uuid>,
    primary_congregation_id: Option<Uuid>,
    primary_congregation_name: Option<String>,
    member_name: Option<String>,
}

#[derive(Debug, FromRow)]
struct UserCongregationRow {
    congregation_id: Uuid,
    congregation_name: String,
    is_primary: bool,
}

pub struct AuthService;

impl AuthService {
    pub fn hash_password(password: &str) -> Result<String, AppError> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let hash = argon2
            .hash_password(password.as_bytes(), &salt)
            .map_err(|e| AppError::Internal(format!("Failed to hash password: {e}")))?;
        Ok(hash.to_string())
    }

    pub fn verify_password(password: &str, hash: &str) -> Result<bool, AppError> {
        let parsed_hash = PasswordHash::new(hash)
            .map_err(|e| AppError::Internal(format!("Invalid password hash: {e}")))?;
        Ok(Argon2::default()
            .verify_password(password.as_bytes(), &parsed_hash)
            .is_ok())
    }

    pub fn generate_access_token(
        user_id: Uuid,
        church_id: Uuid,
        role: &str,
        permissions: Vec<String>,
        scope_type: &str,
        congregation_ids: Vec<Uuid>,
        primary_congregation_id: Option<Uuid>,
        member_id: Option<Uuid>,
        config: &AppConfig,
    ) -> Result<String, AppError> {
        let now = Utc::now().timestamp();
        let claims = Claims {
            sub: user_id.to_string(),
            church_id: church_id.to_string(),
            role: role.to_string(),
            permissions,
            scope_type: scope_type.to_string(),
            congregation_ids: congregation_ids.iter().map(|id| id.to_string()).collect(),
            primary_congregation_id: primary_congregation_id.map(|id| id.to_string()),
            member_id: member_id.map(|id| id.to_string()),
            iat: now,
            exp: now + config.jwt_access_expiry,
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(config.jwt_secret.as_bytes()),
        )
        .map_err(|e| AppError::Internal(format!("Failed to generate token: {e}")))
    }

    pub fn generate_refresh_token() -> String {
        use base64::Engine;
        let mut bytes = [0u8; 32];
        rand::fill(&mut bytes);
        base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(bytes)
    }

    /// Generate a 6-character alphanumeric reset token (easy to copy from email)
    pub fn generate_reset_token() -> String {
        const CHARSET: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no I/O/0/1 for clarity
        let mut bytes = [0u8; 6];
        rand::fill(&mut bytes);
        bytes
            .iter()
            .map(|b| CHARSET[(*b as usize) % CHARSET.len()] as char)
            .collect()
    }

    /// Send password reset email using lettre SMTP transport
    pub async fn send_reset_email(
        to_email: &str,
        token: &str,
        config: &AppConfig,
    ) -> Result<(), AppError> {
        let email = Message::builder()
            .from(
                config
                    .smtp_from
                    .parse()
                    .map_err(|e| AppError::Internal(format!("Invalid SMTP from address: {e}")))?,
            )
            .to(to_email
                .parse()
                .map_err(|e| AppError::Internal(format!("Invalid recipient address: {e}")))?)
            .subject("Igreja Manager — Redefinição de Senha")
            .header(ContentType::TEXT_HTML)
            .body(format!(
                r#"<h2>Redefinição de Senha</h2>
<p>Você solicitou a redefinição de sua senha no <strong>Igreja Manager</strong>.</p>
<p>Use o código abaixo para redefinir sua senha:</p>
<h1 style="letter-spacing:8px;font-family:monospace;text-align:center;color:#D4A843;">{token}</h1>
<p>Este código expira em <strong>30 minutos</strong>.</p>
<p>Se você não solicitou esta redefinição, ignore este e-mail.</p>"#
            ))
            .map_err(|e| AppError::Internal(format!("Failed to build email: {e}")))?;

        let creds = Credentials::new(
            config.smtp_username.clone(),
            config.smtp_password.clone(),
        );

        let mailer = AsyncSmtpTransport::<Tokio1Executor>::relay(&config.smtp_host)
            .map_err(|e| AppError::Internal(format!("SMTP relay error: {e}")))?
            .credentials(creds)
            .build();

        mailer
            .send(email)
            .await
            .map_err(|e| AppError::Internal(format!("Failed to send email: {e}")))?;

        Ok(())
    }

    #[allow(dead_code)]
    pub fn validate_token(token: &str, config: &AppConfig) -> Result<Claims, AppError> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(config.jwt_secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|e| AppError::Unauthorized(format!("Token inválido: {e}")))?;

        Ok(token_data.claims)
    }

    pub async fn login(
        pool: &PgPool,
        request: &LoginRequest,
        config: &AppConfig,
    ) -> Result<LoginResponse, AppError> {
        // Find user by email (with member_id and force_password_change)
        let user = sqlx::query_as::<_, UserLoginRow>(
            r#"
            SELECT u.id, u.email, u.password_hash, u.church_id, u.is_active,
                   u.failed_attempts, u.locked_until,
                   r.name as role_name, r.permissions as role_permissions,
                   c.name as church_name,
                   u.member_id, u.force_password_change
            FROM users u
            JOIN roles r ON u.role_id = r.id
            JOIN churches c ON u.church_id = c.id
            WHERE u.email = $1
            "#,
        )
        .bind(&request.email)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::Unauthorized("Credenciais inválidas".to_string()))?;

        // Check if account is locked
        if let Some(locked_until) = user.locked_until {
            if locked_until > Utc::now() {
                return Err(AppError::Unauthorized(
                    "Conta temporariamente bloqueada. Tente novamente mais tarde.".to_string(),
                ));
            }
        }

        // Check if user is active
        if !user.is_active {
            return Err(AppError::Unauthorized("Conta desativada".to_string()));
        }

        // Verify password
        let valid = Self::verify_password(&request.password, &user.password_hash)?;
        if !valid {
            // Increment failed attempts
            let new_attempts = user.failed_attempts + 1;
            let lock_until = if new_attempts >= 5 {
                Some(Utc::now() + chrono::Duration::minutes(15))
            } else {
                None
            };

            sqlx::query(
                "UPDATE users SET failed_attempts = $1, locked_until = $2 WHERE id = $3",
            )
            .bind(new_attempts)
            .bind(lock_until)
            .bind(user.id)
            .execute(pool)
            .await?;

            return Err(AppError::Unauthorized("Credenciais inválidas".to_string()));
        }

        // Reset failed attempts and update last login
        sqlx::query(
            "UPDATE users SET failed_attempts = 0, locked_until = NULL, last_login_at = NOW() WHERE id = $1",
        )
        .bind(user.id)
        .execute(pool)
        .await?;

        // Parse permissions from JSON
        let permissions: Vec<String> =
            serde_json::from_value(user.role_permissions).unwrap_or_default();

        // Determine congregation scope
        let scope = Self::determine_scope(pool, user.id, &user.role_name, user.member_id).await;

        // Generate tokens
        let access_token = Self::generate_access_token(
            user.id,
            user.church_id,
            &user.role_name,
            permissions,
            &scope.scope_type,
            scope.congregation_ids.clone(),
            scope.primary_congregation_id,
            user.member_id,
            config,
        )?;

        let refresh_token_raw = Self::generate_refresh_token();
        let refresh_token_hash = Self::hash_password(&refresh_token_raw)?;

        // Store refresh token
        let expires_at = Utc::now() + chrono::Duration::seconds(config.jwt_refresh_expiry);
        sqlx::query(
            "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)",
        )
        .bind(user.id)
        .bind(&refresh_token_hash)
        .bind(expires_at)
        .execute(pool)
        .await?;

        Ok(LoginResponse {
            access_token,
            refresh_token: refresh_token_raw,
            token_type: "Bearer".to_string(),
            expires_in: config.jwt_access_expiry,
            user: AuthUser {
                id: user.id,
                email: user.email,
                role: user.role_name,
                church_id: user.church_id,
                church_name: user.church_name,
                member_id: user.member_id,
                member_name: scope.member_name,
                scope_type: scope.scope_type,
                congregation_ids: scope.congregation_ids,
                primary_congregation_id: scope.primary_congregation_id,
                primary_congregation_name: scope.primary_congregation_name,
                force_password_change: user.force_password_change,
            },
        })
    }

    /// Determine the congregation scope for a user at login time.
    async fn determine_scope(
        pool: &PgPool,
        user_id: Uuid,
        role_name: &str,
        member_id: Option<Uuid>,
    ) -> ScopeInfo {
        // Get member name if linked
        let member_name = if let Some(mid) = member_id {
            sqlx::query_scalar::<_, String>(
                "SELECT full_name FROM members WHERE id = $1 AND deleted_at IS NULL",
            )
            .bind(mid)
            .fetch_optional(pool)
            .await
            .ok()
            .flatten()
        } else {
            None
        };

        // Rule 1: super_admin and pastor are ALWAYS global
        if role_name == "super_admin" || role_name == "pastor" {
            return ScopeInfo {
                scope_type: "global".to_string(),
                congregation_ids: vec![],
                primary_congregation_id: None,
                primary_congregation_name: None,
                member_name,
            };
        }

        // Rule 2: "member" role is ALWAYS self
        if role_name == "member" {
            let primary = Self::get_user_primary_congregation(pool, user_id).await;
            return ScopeInfo {
                scope_type: "self".to_string(),
                congregation_ids: primary.as_ref().map(|c| vec![c.congregation_id]).unwrap_or_default(),
                primary_congregation_id: primary.as_ref().map(|c| c.congregation_id),
                primary_congregation_name: primary.map(|c| c.congregation_name),
                member_name,
            };
        }

        // Rule 3: Other roles — check user_congregations
        let user_congs = sqlx::query_as::<_, UserCongregationRow>(
            r#"
            SELECT uc.congregation_id, c.name AS congregation_name, uc.is_primary
            FROM user_congregations uc
            JOIN congregations c ON c.id = uc.congregation_id
            WHERE uc.user_id = $1 AND c.is_active = true
            ORDER BY uc.is_primary DESC, c.name ASC
            "#,
        )
        .bind(user_id)
        .fetch_all(pool)
        .await
        .unwrap_or_default();

        if user_congs.is_empty() {
            // No congregation binding = global (legacy compatibility)
            return ScopeInfo {
                scope_type: "global".to_string(),
                congregation_ids: vec![],
                primary_congregation_id: None,
                primary_congregation_name: None,
                member_name,
            };
        }

        let primary = user_congs.iter().find(|c| c.is_primary).or(user_congs.first());
        ScopeInfo {
            scope_type: "congregation".to_string(),
            congregation_ids: user_congs.iter().map(|c| c.congregation_id).collect(),
            primary_congregation_id: primary.map(|c| c.congregation_id),
            primary_congregation_name: primary.map(|c| c.congregation_name.clone()),
            member_name,
        }
    }

    /// Get the primary congregation for a user
    async fn get_user_primary_congregation(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Option<UserCongregationRow> {
        sqlx::query_as::<_, UserCongregationRow>(
            r#"
            SELECT uc.congregation_id, c.name AS congregation_name, uc.is_primary
            FROM user_congregations uc
            JOIN congregations c ON c.id = uc.congregation_id
            WHERE uc.user_id = $1 AND c.is_active = true
            ORDER BY uc.is_primary DESC
            LIMIT 1
            "#,
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
    }

    /// Generate a random password of given length (excludes ambiguous chars)
    pub fn generate_random_password(length: usize) -> String {
        const CHARSET: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
        let mut bytes = vec![0u8; length];
        rand::fill(&mut bytes[..]);
        bytes
            .iter()
            .map(|b| CHARSET[(*b as usize) % CHARSET.len()] as char)
            .collect()
    }

    /// Change password for authenticated user (used for forced password change)
    pub async fn change_password(
        pool: &PgPool,
        user_id: Uuid,
        new_password: &str,
    ) -> Result<(), AppError> {
        let new_hash = Self::hash_password(new_password)?;

        sqlx::query(
            r#"UPDATE users
               SET password_hash = $1, force_password_change = FALSE,
                   failed_attempts = 0, locked_until = NULL, updated_at = NOW()
               WHERE id = $2"#,
        )
        .bind(&new_hash)
        .bind(user_id)
        .execute(pool)
        .await?;

        // Revoke all refresh tokens (force re-login on other devices)
        sqlx::query(
            "UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL",
        )
        .bind(user_id)
        .execute(pool)
        .await?;

        Ok(())
    }

    /// Public version of determine_scope for use in refresh_token handler.
    /// Returns (scope_type, congregation_ids, primary_congregation_id)
    pub async fn determine_scope_public(
        pool: &PgPool,
        user_id: Uuid,
        role_name: &str,
        member_id: Option<Uuid>,
    ) -> (String, Vec<Uuid>, Option<Uuid>) {
        let scope = Self::determine_scope(pool, user_id, role_name, member_id).await;
        (scope.scope_type, scope.congregation_ids, scope.primary_congregation_id)
    }

    /// Create a user account for an existing member.
    /// Returns (user_id, generated_password) — generated_password is Some only when auto-generated.
    pub async fn create_user_for_member(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
        password: Option<&str>,
        role_id: Option<Uuid>,
        force_password_change: bool,
    ) -> Result<(Uuid, Option<String>), AppError> {
        // 1. Fetch member
        let member = sqlx::query_as::<_, (Uuid, Option<String>, String, Option<Uuid>)>(
            r#"SELECT id, email, full_name, congregation_id
               FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL"#,
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Membro"))?;

        let email = member.1.ok_or_else(|| {
            AppError::validation("Membro não possui email cadastrado. Informe o email primeiro.")
        })?;
        let congregation_id = member.3;

        // 2. Check if email already taken
        let existing = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM users WHERE email = $1 AND church_id = $2",
        )
        .bind(&email)
        .bind(church_id)
        .fetch_one(pool)
        .await?;
        if existing > 0 {
            return Err(AppError::conflict("Este email já possui login no sistema"));
        }

        // 3. Check if member already has user linked
        let linked = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM users WHERE member_id = $1 AND church_id = $2",
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;
        if linked > 0 {
            return Err(AppError::conflict("Membro já possui login vinculado"));
        }

        // 4. Resolve role (default: "member")
        let resolved_role_id = match role_id {
            Some(id) => id,
            None => {
                sqlx::query_scalar::<_, Uuid>(
                    "SELECT id FROM roles WHERE name = 'member'",
                )
                .fetch_one(pool)
                .await
                .map_err(|_| AppError::Internal("Role 'member' not found".into()))?
            }
        };

        // 5. Generate or use provided password
        let (pwd, was_generated) = match password {
            Some(p) => (p.to_string(), false),
            None => (Self::generate_random_password(8), true),
        };

        // 6. Hash password
        let password_hash = Self::hash_password(&pwd)?;

        // 7. Create user in transaction
        let mut tx = pool.begin().await?;

        let user_id = sqlx::query_scalar::<_, Uuid>(
            r#"INSERT INTO users (church_id, member_id, email, password_hash, role_id,
                                  is_active, email_verified, force_password_change)
               VALUES ($1, $2, $3, $4, $5, TRUE, FALSE, $6)
               RETURNING id"#,
        )
        .bind(church_id)
        .bind(member_id)
        .bind(&email)
        .bind(&password_hash)
        .bind(resolved_role_id)
        .bind(force_password_change)
        .fetch_one(&mut *tx)
        .await?;

        // 8. If member has congregation, create user_congregations entry
        if let Some(cong_id) = congregation_id {
            sqlx::query(
                r#"INSERT INTO user_congregations (user_id, congregation_id, role_in_congregation, is_primary)
                   VALUES ($1, $2, 'viewer', TRUE)
                   ON CONFLICT DO NOTHING"#,
            )
            .bind(user_id)
            .bind(cong_id)
            .execute(&mut *tx)
            .await?;
        }

        tx.commit().await?;

        let generated = if was_generated { Some(pwd) } else { None };
        Ok((user_id, generated))
    }
}
