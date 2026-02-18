use crate::application::dto::CreateMemberHistoryRequest;
use crate::domain::entities::MemberHistory;
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct MemberHistoryService;

impl MemberHistoryService {
    /// List history events for a member
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
    ) -> Result<Vec<MemberHistory>, AppError> {
        // Verify member exists
        let exists = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?;

        if exists.is_none() {
            return Err(AppError::not_found("Membro"));
        }

        let history = sqlx::query_as::<_, MemberHistory>(
            r#"
            SELECT * FROM member_history
            WHERE member_id = $1 AND church_id = $2
            ORDER BY event_date DESC, created_at DESC
            "#,
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        Ok(history)
    }

    /// Create a new history event for a member
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
        user_id: Uuid,
        req: &CreateMemberHistoryRequest,
    ) -> Result<MemberHistory, AppError> {
        // Verify member exists
        let exists = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?;

        if exists.is_none() {
            return Err(AppError::not_found("Membro"));
        }

        let history = sqlx::query_as::<_, MemberHistory>(
            r#"
            INSERT INTO member_history (church_id, member_id, event_type, event_date, description, previous_value, new_value, registered_by)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(member_id)
        .bind(&req.event_type)
        .bind(req.event_date)
        .bind(&req.description)
        .bind(&req.previous_value)
        .bind(&req.new_value)
        .bind(user_id)
        .fetch_one(pool)
        .await?;

        Ok(history)
    }
}
