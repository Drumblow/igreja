use crate::application::dto::{CreateStudentNoteRequest, StudentNoteFilter, UpdateStudentNoteRequest};
use crate::domain::entities::{EbdStudentNote, EbdStudentNoteDetail};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdStudentNoteService;

impl EbdStudentNoteService {
    /// List notes for a student (with filters)
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
        filter: &StudentNoteFilter,
        has_write_permission: bool,
    ) -> Result<Vec<EbdStudentNoteDetail>, AppError> {
        let mut conditions = vec![
            "n.church_id = $1".to_string(),
            "n.member_id = $2".to_string(),
        ];
        let mut param_idx = 3u32;

        if !has_write_permission {
            conditions.push("n.is_private = FALSE".to_string());
        }

        if filter.term_id.is_some() {
            conditions.push(format!("n.term_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.note_type.is_some() {
            conditions.push(format!("n.note_type = ${param_idx}"));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let sql = format!(
            r#"
            SELECT n.id, n.church_id, n.member_id, n.term_id,
                   t.name AS term_name,
                   n.note_type, n.title, n.content, n.is_private,
                   n.created_by,
                   u.email AS created_by_name,
                   n.created_at, n.updated_at
            FROM ebd_student_notes n
            LEFT JOIN ebd_terms t ON t.id = n.term_id
            LEFT JOIN users u ON u.id = n.created_by
            WHERE {where_clause}
            ORDER BY n.created_at DESC
            "#
        );

        let mut args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut args, church_id).unwrap();
        sqlx::Arguments::add(&mut args, member_id).unwrap();

        if let Some(term_id) = &filter.term_id {
            sqlx::Arguments::add(&mut args, *term_id).unwrap();
        }
        if let Some(note_type) = &filter.note_type {
            sqlx::Arguments::add(&mut args, note_type.as_str()).unwrap();
        }

        let notes = sqlx::query_as_with::<_, EbdStudentNoteDetail, _>(&sql, args)
            .fetch_all(pool)
            .await?;

        Ok(notes)
    }

    /// Create a new student note
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
        user_id: Uuid,
        req: &CreateStudentNoteRequest,
    ) -> Result<EbdStudentNote, AppError> {
        // Verify member exists
        let member_exists = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        if member_exists == 0 {
            return Err(AppError::not_found("Membro"));
        }

        // Validate note_type
        let valid_types = ["observation", "behavior", "progress", "special_need", "praise", "concern"];
        if !valid_types.contains(&req.note_type.as_str()) {
            return Err(AppError::validation(
                "Tipo de nota inválido. Valores aceitos: observation, behavior, progress, special_need, praise, concern",
            ));
        }

        // Validate term_id if provided (RN-EBD-E5-004)
        if let Some(term_id) = &req.term_id {
            let term_exists = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM ebd_terms WHERE id = $1 AND church_id = $2",
            )
            .bind(term_id)
            .bind(church_id)
            .fetch_one(pool)
            .await?;

            if term_exists == 0 {
                return Err(AppError::not_found("Período EBD"));
            }
        }

        let note = sqlx::query_as::<_, EbdStudentNote>(
            r#"
            INSERT INTO ebd_student_notes
                (church_id, member_id, term_id, note_type, title, content, is_private, created_by)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(member_id)
        .bind(req.term_id)
        .bind(&req.note_type)
        .bind(&req.title)
        .bind(&req.content)
        .bind(req.is_private.unwrap_or(true))
        .bind(user_id)
        .fetch_one(pool)
        .await?;

        Ok(note)
    }

    /// Update a note (RN-EBD-E5-002: only the author can edit)
    pub async fn update(
        pool: &PgPool,
        member_id: Uuid,
        note_id: Uuid,
        user_id: Uuid,
        req: &UpdateStudentNoteRequest,
    ) -> Result<EbdStudentNote, AppError> {
        let existing = sqlx::query_as::<_, EbdStudentNote>(
            "SELECT * FROM ebd_student_notes WHERE id = $1 AND member_id = $2",
        )
        .bind(note_id)
        .bind(member_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Nota"))?;

        // RN-EBD-E5-002: Only the author can edit
        if existing.created_by != user_id {
            return Err(AppError::Forbidden(
                "Apenas o autor pode editar esta nota".to_string(),
            ));
        }

        // Validate note_type if provided
        if let Some(nt) = &req.note_type {
            let valid_types = ["observation", "behavior", "progress", "special_need", "praise", "concern"];
            if !valid_types.contains(&nt.as_str()) {
                return Err(AppError::validation("Tipo de nota inválido"));
            }
        }

        let note_type = req.note_type.as_deref().unwrap_or(&existing.note_type);
        let title = req.title.as_deref().or(existing.title.as_deref());
        let content = req.content.as_deref().unwrap_or(&existing.content);
        let is_private = req.is_private.unwrap_or(existing.is_private);

        let note = sqlx::query_as::<_, EbdStudentNote>(
            r#"
            UPDATE ebd_student_notes
            SET note_type = $1, title = $2, content = $3, is_private = $4, updated_at = NOW()
            WHERE id = $5 AND member_id = $6
            RETURNING *
            "#,
        )
        .bind(note_type)
        .bind(title)
        .bind(content)
        .bind(is_private)
        .bind(note_id)
        .bind(member_id)
        .fetch_one(pool)
        .await?;

        Ok(note)
    }

    /// Delete a note (RN-EBD-E5-002: only the author can delete)
    pub async fn delete(
        pool: &PgPool,
        member_id: Uuid,
        note_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), AppError> {
        let existing = sqlx::query_as::<_, EbdStudentNote>(
            "SELECT * FROM ebd_student_notes WHERE id = $1 AND member_id = $2",
        )
        .bind(note_id)
        .bind(member_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Nota"))?;

        if existing.created_by != user_id {
            return Err(AppError::Forbidden(
                "Apenas o autor pode excluir esta nota".to_string(),
            ));
        }

        sqlx::query("DELETE FROM ebd_student_notes WHERE id = $1")
            .bind(note_id)
            .execute(pool)
            .await?;

        Ok(())
    }
}
