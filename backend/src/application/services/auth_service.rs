use crate::application::dto::{AuthUser, Claims, LoginRequest, LoginResponse};
use crate::config::AppConfig;
use crate::errors::AppError;
use argon2::password_hash::rand_core::OsRng;
use argon2::password_hash::SaltString;
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use chrono::{DateTime, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
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
        config: &AppConfig,
    ) -> Result<String, AppError> {
        let now = Utc::now().timestamp();
        let claims = Claims {
            sub: user_id.to_string(),
            church_id: church_id.to_string(),
            role: role.to_string(),
            permissions,
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
        // Find user by email
        let user = sqlx::query_as::<_, UserLoginRow>(
            r#"
            SELECT u.id, u.email, u.password_hash, u.church_id, u.is_active,
                   u.failed_attempts, u.locked_until,
                   r.name as role_name, r.permissions as role_permissions,
                   c.name as church_name
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

        // Generate tokens
        let access_token = Self::generate_access_token(
            user.id,
            user.church_id,
            &user.role_name,
            permissions,
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
            },
        })
    }
}
