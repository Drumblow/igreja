use crate::application::dto::{CreateChurchRoleRequest, UpdateChurchRoleRequest};
use crate::domain::entities::ChurchRole;
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct ChurchRoleService;

impl ChurchRoleService {
    /// List all active roles for a church, ordered by sort_order.
    pub async fn list(pool: &PgPool, church_id: Uuid) -> Result<Vec<ChurchRole>, AppError> {
        let roles = sqlx::query_as::<_, ChurchRole>(
            "SELECT * FROM church_roles WHERE church_id = $1 AND is_active = TRUE ORDER BY sort_order ASC, display_name ASC",
        )
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        Ok(roles)
    }

    /// List all roles (including inactive) for admin management.
    pub async fn list_all(pool: &PgPool, church_id: Uuid) -> Result<Vec<ChurchRole>, AppError> {
        let roles = sqlx::query_as::<_, ChurchRole>(
            "SELECT * FROM church_roles WHERE church_id = $1 ORDER BY sort_order ASC, display_name ASC",
        )
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        Ok(roles)
    }

    /// Create a new custom role for a church.
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateChurchRoleRequest,
    ) -> Result<ChurchRole, AppError> {
        // Normalize key: lowercase, replace spaces with underscores
        let key = req
            .key
            .trim()
            .to_lowercase()
            .replace(' ', "_")
            .replace('-', "_");

        // Get max sort_order for the church
        let max_order = sqlx::query_scalar::<_, Option<i32>>(
            "SELECT MAX(sort_order) FROM church_roles WHERE church_id = $1",
        )
        .bind(church_id)
        .fetch_one(pool)
        .await?
        .unwrap_or(0);

        let sort_order = req.sort_order.unwrap_or(max_order + 1);

        let role = sqlx::query_as::<_, ChurchRole>(
            r#"
            INSERT INTO church_roles (church_id, key, display_name, investiture_type, sort_order, is_default)
            VALUES ($1, $2, $3, $4, $5, FALSE)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&key)
        .bind(req.display_name.trim())
        .bind(&req.investiture_type)
        .bind(sort_order)
        .fetch_one(pool)
        .await
        .map_err(|e| {
            if let sqlx::Error::Database(ref db_err) = e {
                if db_err.constraint() == Some("church_roles_church_id_key_key") {
                    return AppError::conflict("Já existe um cargo com esta chave");
                }
            }
            AppError::from(e)
        })?;

        Ok(role)
    }

    /// Update a custom role. Default roles can have display_name and sort_order changed,
    /// but not key or is_default.
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        role_id: Uuid,
        req: &UpdateChurchRoleRequest,
    ) -> Result<ChurchRole, AppError> {
        let existing = sqlx::query_as::<_, ChurchRole>(
            "SELECT * FROM church_roles WHERE id = $1 AND church_id = $2",
        )
        .bind(role_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Cargo"))?;

        let display_name = req
            .display_name
            .as_deref()
            .unwrap_or(&existing.display_name);
        let investiture_type = req
            .investiture_type
            .as_deref()
            .or(existing.investiture_type.as_deref());
        let sort_order = req.sort_order.unwrap_or(existing.sort_order);
        let is_active = req.is_active.unwrap_or(existing.is_active);

        let role = sqlx::query_as::<_, ChurchRole>(
            r#"
            UPDATE church_roles
            SET display_name = $3, investiture_type = $4, sort_order = $5, is_active = $6
            WHERE id = $1 AND church_id = $2
            RETURNING *
            "#,
        )
        .bind(role_id)
        .bind(church_id)
        .bind(display_name)
        .bind(investiture_type)
        .bind(sort_order)
        .bind(is_active)
        .fetch_one(pool)
        .await?;

        Ok(role)
    }

    /// Delete a custom role. Default roles cannot be deleted, only deactivated.
    pub async fn delete(pool: &PgPool, church_id: Uuid, role_id: Uuid) -> Result<(), AppError> {
        let existing = sqlx::query_as::<_, ChurchRole>(
            "SELECT * FROM church_roles WHERE id = $1 AND church_id = $2",
        )
        .bind(role_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Cargo"))?;

        if existing.is_default {
            return Err(AppError::validation(
                "Cargos padrão não podem ser excluídos, apenas desativados",
            ));
        }

        sqlx::query("DELETE FROM church_roles WHERE id = $1 AND church_id = $2")
            .bind(role_id)
            .bind(church_id)
            .execute(pool)
            .await?;

        Ok(())
    }
}
