use crate::application::dto::{CreateEbdTermRequest, UpdateEbdTermRequest};
use crate::domain::entities::EbdTerm;
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdTermService;

impl EbdTermService {
    /// List EBD terms with pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        is_active: &Option<bool>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<EbdTerm>, i64), AppError> {
        let mut conditions = vec!["church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if is_active.is_some() {
            conditions.push(format!("is_active = ${param_idx}"));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!("SELECT COUNT(*) FROM ebd_terms WHERE {where_clause}");
        let query_sql = format!(
            r#"
            SELECT id, church_id, name, start_date, end_date, theme, magazine_title, is_active, created_at, updated_at
            FROM ebd_terms
            WHERE {where_clause}
            ORDER BY start_date DESC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(active) = is_active {
            sqlx::Arguments::add(&mut count_args, *active).unwrap();
            sqlx::Arguments::add(&mut data_args, *active).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let terms = sqlx::query_as_with::<_, EbdTerm, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((terms, total))
    }

    /// Get term by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        term_id: Uuid,
    ) -> Result<EbdTerm, AppError> {
        sqlx::query_as::<_, EbdTerm>(
            "SELECT * FROM ebd_terms WHERE id = $1 AND church_id = $2",
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Período EBD"))
    }

    /// Create a new EBD term
    /// Business rule RN-EBD-001: Only one active term at a time
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateEbdTermRequest,
    ) -> Result<EbdTerm, AppError> {
        if req.end_date <= req.start_date {
            return Err(AppError::validation(
                "Data de término deve ser posterior à data de início",
            ));
        }

        // RN-EBD-001: Deactivate other active terms
        sqlx::query("UPDATE ebd_terms SET is_active = FALSE, updated_at = NOW() WHERE church_id = $1 AND is_active = TRUE")
            .bind(church_id)
            .execute(pool)
            .await?;

        let term = sqlx::query_as::<_, EbdTerm>(
            r#"
            INSERT INTO ebd_terms (church_id, name, start_date, end_date, theme, magazine_title, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, TRUE)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(req.start_date)
        .bind(req.end_date)
        .bind(&req.theme)
        .bind(&req.magazine_title)
        .fetch_one(pool)
        .await?;

        Ok(term)
    }

    /// Update an EBD term
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        term_id: Uuid,
        req: &UpdateEbdTermRequest,
    ) -> Result<EbdTerm, AppError> {
        // Verify term exists
        Self::get_by_id(pool, church_id, term_id).await?;

        let mut set_clauses = Vec::new();
        let mut param_idx = 3u32;

        if req.name.is_some() {
            set_clauses.push(format!("name = ${param_idx}"));
            param_idx += 1;
        }
        if req.start_date.is_some() {
            set_clauses.push(format!("start_date = ${param_idx}"));
            param_idx += 1;
        }
        if req.end_date.is_some() {
            set_clauses.push(format!("end_date = ${param_idx}"));
            param_idx += 1;
        }
        if req.theme.is_some() {
            set_clauses.push(format!("theme = ${param_idx}"));
            param_idx += 1;
        }
        if req.magazine_title.is_some() {
            set_clauses.push(format!("magazine_title = ${param_idx}"));
            param_idx += 1;
        }
        if req.is_active.is_some() {
            set_clauses.push(format!("is_active = ${param_idx}"));
            param_idx += 1;
        }

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, term_id).await;
        }

        let _ = param_idx;
        set_clauses.push("updated_at = NOW()".to_string());
        let set_clause = set_clauses.join(", ");

        // RN-EBD-001: If activating this term, deactivate others
        if req.is_active == Some(true) {
            sqlx::query("UPDATE ebd_terms SET is_active = FALSE, updated_at = NOW() WHERE church_id = $1 AND id != $2 AND is_active = TRUE")
                .bind(church_id)
                .bind(term_id)
                .execute(pool)
                .await?;
        }

        let sql = format!(
            "UPDATE ebd_terms SET {set_clause} WHERE id = $1 AND church_id = $2 RETURNING *"
        );

        let mut args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut args, term_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(name) = &req.name {
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
        }
        if let Some(start_date) = &req.start_date {
            sqlx::Arguments::add(&mut args, *start_date).unwrap();
        }
        if let Some(end_date) = &req.end_date {
            sqlx::Arguments::add(&mut args, *end_date).unwrap();
        }
        if let Some(theme) = &req.theme {
            sqlx::Arguments::add(&mut args, theme.as_str()).unwrap();
        }
        if let Some(magazine_title) = &req.magazine_title {
            sqlx::Arguments::add(&mut args, magazine_title.as_str()).unwrap();
        }
        if let Some(is_active) = &req.is_active {
            sqlx::Arguments::add(&mut args, *is_active).unwrap();
        }

        let term = sqlx::query_as_with::<_, EbdTerm, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(term)
    }

    /// Delete an EBD term and all related data (classes, lessons, etc.)
    pub async fn delete(
        pool: &PgPool,
        church_id: Uuid,
        term_id: Uuid,
    ) -> Result<(), AppError> {
        // Verify term exists
        Self::get_by_id(pool, church_id, term_id).await?;

        let mut tx = pool.begin().await?;

        // 1. Delete lessons that belong to classes in this term
        //    (cascades: attendances, contents, activities, responses, materials)
        sqlx::query(
            r#"DELETE FROM ebd_lessons WHERE class_id IN (
                SELECT id FROM ebd_classes WHERE term_id = $1 AND church_id = $2
            )"#,
        )
        .bind(term_id)
        .bind(church_id)
        .execute(&mut *tx)
        .await?;

        // 2. Delete classes (cascades: enrollments)
        sqlx::query("DELETE FROM ebd_classes WHERE term_id = $1 AND church_id = $2")
            .bind(term_id)
            .bind(church_id)
            .execute(&mut *tx)
            .await?;

        // 3. Nullify student notes referencing this term
        sqlx::query("UPDATE ebd_student_notes SET term_id = NULL WHERE term_id = $1 AND church_id = $2")
            .bind(term_id)
            .bind(church_id)
            .execute(&mut *tx)
            .await?;

        // 4. Delete the term
        sqlx::query("DELETE FROM ebd_terms WHERE id = $1 AND church_id = $2")
            .bind(term_id)
            .bind(church_id)
            .execute(&mut *tx)
            .await?;

        tx.commit().await?;
        Ok(())
    }
}
