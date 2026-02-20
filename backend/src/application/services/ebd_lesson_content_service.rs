use crate::application::dto::{CreateLessonContentRequest, ReorderContentsRequest, UpdateLessonContentRequest};
use crate::domain::entities::EbdLessonContent;
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdLessonContentService;

impl EbdLessonContentService {
    /// List all content blocks for a lesson, ordered by sort_order
    pub async fn list(
        pool: &PgPool,
        lesson_id: Uuid,
    ) -> Result<Vec<EbdLessonContent>, AppError> {
        let contents = sqlx::query_as::<_, EbdLessonContent>(
            r#"
            SELECT id, lesson_id, content_type, title, body, image_url, image_caption,
                   sort_order, created_at, updated_at
            FROM ebd_lesson_contents
            WHERE lesson_id = $1
            ORDER BY sort_order ASC, created_at ASC
            "#,
        )
        .bind(lesson_id)
        .fetch_all(pool)
        .await?;

        Ok(contents)
    }

    /// Create a new content block for a lesson
    /// RN-EBD-E1-001: Max 20 blocks per lesson
    pub async fn create(
        pool: &PgPool,
        lesson_id: Uuid,
        church_id: Uuid,
        req: &CreateLessonContentRequest,
    ) -> Result<EbdLessonContent, AppError> {
        // Validate lesson belongs to church
        let lesson_exists = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_lessons WHERE id = $1 AND church_id = $2",
        )
        .bind(lesson_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        if lesson_exists == 0 {
            return Err(AppError::not_found("Aula EBD"));
        }

        // RN-EBD-E1-001: Max 20 blocks
        let count = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_lesson_contents WHERE lesson_id = $1",
        )
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        if count >= 20 {
            return Err(AppError::validation(
                "Cada lição pode ter no máximo 20 blocos de conteúdo",
            ));
        }

        // Validate content_type
        if !["text", "image", "bible_reference", "note"].contains(&req.content_type.as_str()) {
            return Err(AppError::validation(
                "Tipo de conteúdo deve ser: text, image, bible_reference ou note",
            ));
        }

        // Auto sort_order if not provided
        let sort_order = match req.sort_order {
            Some(s) => s,
            None => {
                let max: Option<i32> = sqlx::query_scalar(
                    "SELECT MAX(sort_order) FROM ebd_lesson_contents WHERE lesson_id = $1",
                )
                .bind(lesson_id)
                .fetch_one(pool)
                .await?;
                max.unwrap_or(0) + 1
            }
        };

        let content = sqlx::query_as::<_, EbdLessonContent>(
            r#"
            INSERT INTO ebd_lesson_contents (lesson_id, content_type, title, body, image_url, image_caption, sort_order)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
        .bind(lesson_id)
        .bind(&req.content_type)
        .bind(&req.title)
        .bind(&req.body)
        .bind(&req.image_url)
        .bind(&req.image_caption)
        .bind(sort_order)
        .fetch_one(pool)
        .await?;

        Ok(content)
    }

    /// Update a content block
    pub async fn update(
        pool: &PgPool,
        lesson_id: Uuid,
        content_id: Uuid,
        req: &UpdateLessonContentRequest,
    ) -> Result<EbdLessonContent, AppError> {
        // Verify content exists and belongs to the lesson
        let existing = sqlx::query_as::<_, EbdLessonContent>(
            "SELECT * FROM ebd_lesson_contents WHERE id = $1 AND lesson_id = $2",
        )
        .bind(content_id)
        .bind(lesson_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Conteúdo da lição"))?;

        // Validate content_type if provided
        if let Some(ct) = &req.content_type {
            if !["text", "image", "bible_reference", "note"].contains(&ct.as_str()) {
                return Err(AppError::validation(
                    "Tipo de conteúdo deve ser: text, image, bible_reference ou note",
                ));
            }
        }

        let content_type = req.content_type.as_deref().unwrap_or(&existing.content_type);
        let title = req.title.as_deref().or(existing.title.as_deref());
        let body = req.body.as_deref().or(existing.body.as_deref());
        let image_url = req.image_url.as_deref().or(existing.image_url.as_deref());
        let image_caption = req.image_caption.as_deref().or(existing.image_caption.as_deref());
        let sort_order = req.sort_order.unwrap_or(existing.sort_order);

        let content = sqlx::query_as::<_, EbdLessonContent>(
            r#"
            UPDATE ebd_lesson_contents
            SET content_type = $1, title = $2, body = $3, image_url = $4,
                image_caption = $5, sort_order = $6, updated_at = NOW()
            WHERE id = $7 AND lesson_id = $8
            RETURNING *
            "#,
        )
        .bind(content_type)
        .bind(title)
        .bind(body)
        .bind(image_url)
        .bind(image_caption)
        .bind(sort_order)
        .bind(content_id)
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        Ok(content)
    }

    /// Delete a content block
    pub async fn delete(
        pool: &PgPool,
        lesson_id: Uuid,
        content_id: Uuid,
    ) -> Result<(), AppError> {
        let rows = sqlx::query(
            "DELETE FROM ebd_lesson_contents WHERE id = $1 AND lesson_id = $2",
        )
        .bind(content_id)
        .bind(lesson_id)
        .execute(pool)
        .await?
        .rows_affected();

        if rows == 0 {
            return Err(AppError::not_found("Conteúdo da lição"));
        }

        Ok(())
    }

    /// Reorder content blocks in a single transaction
    /// RN-EBD-E1-006: Reorder updates sort_order in a single transaction
    pub async fn reorder(
        pool: &PgPool,
        lesson_id: Uuid,
        req: &ReorderContentsRequest,
    ) -> Result<Vec<EbdLessonContent>, AppError> {
        let mut tx = pool.begin().await?;

        for (idx, content_id) in req.content_ids.iter().enumerate() {
            let rows = sqlx::query(
                "UPDATE ebd_lesson_contents SET sort_order = $1, updated_at = NOW() WHERE id = $2 AND lesson_id = $3",
            )
            .bind(idx as i32)
            .bind(content_id)
            .bind(lesson_id)
            .execute(&mut *tx)
            .await?
            .rows_affected();

            if rows == 0 {
                return Err(AppError::validation(
                    format!("Conteúdo {} não encontrado na lição", content_id),
                ));
            }
        }

        tx.commit().await?;

        Self::list(pool, lesson_id).await
    }
}
