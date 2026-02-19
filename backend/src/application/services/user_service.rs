use crate::application::dto::{CreateUserRequest, UpdateUserRequest, UserSummary};
use crate::application::services::AuthService;
use crate::domain::entities::user::{Role, User};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct UserService;

impl UserService {
    /// List users for a church with pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<UserSummary>, i64), AppError> {
        let (rows, total) = if let Some(term) = search {
            let pattern = format!("%{term}%");
            let total = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM users u WHERE u.church_id = $1 AND u.email ILIKE $2",
            )
            .bind(church_id)
            .bind(&pattern)
            .fetch_one(pool)
            .await?;

            let rows = sqlx::query_as::<_, UserSummaryRow>(
                r#"SELECT u.id, u.email, r.name AS role_name, r.display_name AS role_display_name,
                   m.full_name AS member_name, u.is_active, u.email_verified,
                   u.last_login_at, u.created_at
                   FROM users u
                   JOIN roles r ON r.id = u.role_id
                   LEFT JOIN members m ON m.id = u.member_id
                   WHERE u.church_id = $1 AND u.email ILIKE $2
                   ORDER BY u.created_at DESC LIMIT $3 OFFSET $4"#,
            )
            .bind(church_id)
            .bind(&pattern)
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await?;

            (rows, total)
        } else {
            let total = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM users WHERE church_id = $1",
            )
            .bind(church_id)
            .fetch_one(pool)
            .await?;

            let rows = sqlx::query_as::<_, UserSummaryRow>(
                r#"SELECT u.id, u.email, r.name AS role_name, r.display_name AS role_display_name,
                   m.full_name AS member_name, u.is_active, u.email_verified,
                   u.last_login_at, u.created_at
                   FROM users u
                   JOIN roles r ON r.id = u.role_id
                   LEFT JOIN members m ON m.id = u.member_id
                   WHERE u.church_id = $1
                   ORDER BY u.created_at DESC LIMIT $2 OFFSET $3"#,
            )
            .bind(church_id)
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await?;

            (rows, total)
        };

        Ok((rows.into_iter().map(|r| r.into()).collect(), total))
    }

    /// Get user by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Uuid,
    ) -> Result<UserSummary, AppError> {
        sqlx::query_as::<_, UserSummaryRow>(
            r#"SELECT u.id, u.email, r.name AS role_name, r.display_name AS role_display_name,
               m.full_name AS member_name, u.is_active, u.email_verified,
               u.last_login_at, u.created_at
               FROM users u
               JOIN roles r ON r.id = u.role_id
               LEFT JOIN members m ON m.id = u.member_id
               WHERE u.id = $1 AND u.church_id = $2"#,
        )
        .bind(user_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .map(|r| r.into())
        .ok_or_else(|| AppError::not_found("Usuário"))
    }

    /// Create a new user
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateUserRequest,
    ) -> Result<User, AppError> {
        // Check if email already taken in this church
        let existing = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM users WHERE email = $1 AND church_id = $2",
        )
        .bind(&req.email)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        if existing > 0 {
            return Err(AppError::Conflict("E-mail já cadastrado nesta igreja".into()));
        }

        // Verify role exists
        let _role = sqlx::query_as::<_, Role>(
            "SELECT * FROM roles WHERE id = $1",
        )
        .bind(req.role_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Papel/Role"))?;

        let password_hash = AuthService::hash_password(&req.password)
            .map_err(|e| AppError::Internal(format!("Erro ao criar hash da senha: {e}")))?;

        let user = sqlx::query_as::<_, User>(
            r#"INSERT INTO users (church_id, email, password_hash, role_id, member_id, is_active, email_verified)
               VALUES ($1, $2, $3, $4, $5, $6, FALSE)
               RETURNING *"#,
        )
        .bind(church_id)
        .bind(&req.email)
        .bind(&password_hash)
        .bind(req.role_id)
        .bind(req.member_id)
        .bind(req.is_active.unwrap_or(true))
        .fetch_one(pool)
        .await?;

        Ok(user)
    }

    /// Update a user
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Uuid,
        req: &UpdateUserRequest,
    ) -> Result<User, AppError> {
        let existing = sqlx::query_as::<_, User>(
            "SELECT * FROM users WHERE id = $1 AND church_id = $2",
        )
        .bind(user_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Usuário"))?;

        // Check email conflict if changing
        if let Some(new_email) = &req.email {
            if new_email != &existing.email {
                let conflict = sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM users WHERE email = $1 AND church_id = $2 AND id != $3",
                )
                .bind(new_email)
                .bind(church_id)
                .bind(user_id)
                .fetch_one(pool)
                .await?;

                if conflict > 0 {
                    return Err(AppError::Conflict("E-mail já cadastrado nesta igreja".into()));
                }
            }
        }

        // If password is changing, hash it
        let password_hash = if let Some(new_password) = &req.password {
            AuthService::hash_password(new_password)
                .map_err(|e| AppError::Internal(format!("Erro ao criar hash da senha: {e}")))?
        } else {
            existing.password_hash.clone()
        };

        let user = sqlx::query_as::<_, User>(
            r#"UPDATE users SET
                email = $3, password_hash = $4, role_id = $5, member_id = $6,
                is_active = $7, updated_at = NOW()
               WHERE id = $1 AND church_id = $2
               RETURNING *"#,
        )
        .bind(user_id)
        .bind(church_id)
        .bind(req.email.as_deref().unwrap_or(&existing.email))
        .bind(&password_hash)
        .bind(req.role_id.unwrap_or(existing.role_id))
        .bind(req.member_id.or(existing.member_id))
        .bind(req.is_active.unwrap_or(existing.is_active))
        .fetch_one(pool)
        .await?;

        Ok(user)
    }

    /// List all roles
    pub async fn list_roles(pool: &PgPool) -> Result<Vec<Role>, AppError> {
        let roles = sqlx::query_as::<_, Role>(
            "SELECT * FROM roles ORDER BY name ASC",
        )
        .fetch_all(pool)
        .await?;

        Ok(roles)
    }
}

/// Internal row struct for the summary query
#[derive(Debug, sqlx::FromRow)]
struct UserSummaryRow {
    pub id: Uuid,
    pub email: String,
    pub role_name: String,
    pub role_display_name: String,
    pub member_name: Option<String>,
    pub is_active: bool,
    pub email_verified: bool,
    pub last_login_at: Option<chrono::DateTime<chrono::Utc>>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

impl From<UserSummaryRow> for UserSummary {
    fn from(row: UserSummaryRow) -> Self {
        UserSummary {
            id: row.id,
            email: row.email,
            role_name: row.role_name,
            role_display_name: row.role_display_name,
            member_name: row.member_name,
            is_active: row.is_active,
            email_verified: row.email_verified,
            last_login_at: row.last_login_at,
            created_at: row.created_at,
        }
    }
}
