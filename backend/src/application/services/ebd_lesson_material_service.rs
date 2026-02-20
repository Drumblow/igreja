use crate::application::dto::CreateLessonMaterialRequest;
use crate::domain::entities::EbdLessonMaterial;
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdLessonMaterialService;

impl EbdLessonMaterialService {
    /// List all materials for a lesson
    pub async fn list(
        pool: &PgPool,
        lesson_id: Uuid,
    ) -> Result<Vec<EbdLessonMaterial>, AppError> {
        let materials = sqlx::query_as::<_, EbdLessonMaterial>(
            r#"
            SELECT id, lesson_id, material_type, title, description, url,
                   file_size_bytes, mime_type, uploaded_by, created_at
            FROM ebd_lesson_materials
            WHERE lesson_id = $1
            ORDER BY created_at ASC
            "#,
        )
        .bind(lesson_id)
        .fetch_all(pool)
        .await?;

        Ok(materials)
    }

    /// Create a new material for a lesson
    /// RN-EBD-E4-001: Max 10 materials per lesson
    pub async fn create(
        pool: &PgPool,
        lesson_id: Uuid,
        church_id: Uuid,
        user_id: Uuid,
        req: &CreateLessonMaterialRequest,
    ) -> Result<EbdLessonMaterial, AppError> {
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

        // RN-EBD-E4-001: Max 10 materials
        let count = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_lesson_materials WHERE lesson_id = $1",
        )
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        if count >= 10 {
            return Err(AppError::validation(
                "Cada lição pode ter no máximo 10 materiais",
            ));
        }

        // Validate material_type
        if !["document", "video", "audio", "link", "image"].contains(&req.material_type.as_str()) {
            return Err(AppError::validation(
                "Tipo de material deve ser: document, video, audio, link ou image",
            ));
        }

        let material = sqlx::query_as::<_, EbdLessonMaterial>(
            r#"
            INSERT INTO ebd_lesson_materials
                (lesson_id, material_type, title, description, url, file_size_bytes, mime_type, uploaded_by)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
            "#,
        )
        .bind(lesson_id)
        .bind(&req.material_type)
        .bind(&req.title)
        .bind(&req.description)
        .bind(&req.url)
        .bind(req.file_size_bytes)
        .bind(&req.mime_type)
        .bind(user_id)
        .fetch_one(pool)
        .await?;

        Ok(material)
    }

    /// Delete a material
    pub async fn delete(
        pool: &PgPool,
        lesson_id: Uuid,
        material_id: Uuid,
    ) -> Result<(), AppError> {
        let rows = sqlx::query(
            "DELETE FROM ebd_lesson_materials WHERE id = $1 AND lesson_id = $2",
        )
        .bind(material_id)
        .bind(lesson_id)
        .execute(pool)
        .await?
        .rows_affected();

        if rows == 0 {
            return Err(AppError::not_found("Material"));
        }

        Ok(())
    }
}
