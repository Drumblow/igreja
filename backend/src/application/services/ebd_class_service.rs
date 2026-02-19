use crate::application::dto::{CreateEbdClassRequest, CreateEbdEnrollmentRequest, EbdClassFilter, UpdateEbdClassRequest};
use crate::domain::entities::{EbdClass, EbdClassSummary, EbdEnrollment, EbdEnrollmentDetail};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdClassService;

impl EbdClassService {
    /// List EBD classes with filtering and pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &EbdClassFilter,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<EbdClassSummary>, i64), AppError> {
        let mut conditions = vec!["c.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if filter.term_id.is_some() {
            conditions.push(format!("c.term_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.is_active.is_some() {
            conditions.push(format!("c.is_active = ${param_idx}"));
            param_idx += 1;
        }
        if filter.teacher_id.is_some() {
            conditions.push(format!("(c.teacher_id = ${param_idx} OR c.aux_teacher_id = ${param_idx})"));
            param_idx += 1;
        }
        if search.is_some() {
            conditions.push(format!(
                "unaccent(c.name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM ebd_classes c WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT c.id, c.term_id, c.name, c.age_range_start, c.age_range_end,
                   c.room, c.max_capacity,
                   m.full_name AS teacher_name,
                   c.is_active,
                   (SELECT COUNT(*) FROM ebd_enrollments e WHERE e.class_id = c.id AND e.is_active = TRUE) AS enrolled_count,
                   c.created_at
            FROM ebd_classes c
            LEFT JOIN members m ON m.id = c.teacher_id
            WHERE {where_clause}
            ORDER BY c.name ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(term_id) = &filter.term_id {
            sqlx::Arguments::add(&mut count_args, *term_id).unwrap();
            sqlx::Arguments::add(&mut data_args, *term_id).unwrap();
        }
        if let Some(is_active) = &filter.is_active {
            sqlx::Arguments::add(&mut count_args, *is_active).unwrap();
            sqlx::Arguments::add(&mut data_args, *is_active).unwrap();
        }
        if let Some(teacher_id) = &filter.teacher_id {
            sqlx::Arguments::add(&mut count_args, *teacher_id).unwrap();
            sqlx::Arguments::add(&mut data_args, *teacher_id).unwrap();
        }
        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let classes = sqlx::query_as_with::<_, EbdClassSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((classes, total))
    }

    /// Get class by ID (full details)
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        class_id: Uuid,
    ) -> Result<EbdClass, AppError> {
        sqlx::query_as::<_, EbdClass>(
            "SELECT * FROM ebd_classes WHERE id = $1 AND church_id = $2",
        )
        .bind(class_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Turma EBD"))
    }

    /// Create a new EBD class
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateEbdClassRequest,
    ) -> Result<EbdClass, AppError> {
        // Validate age range
        if let (Some(start), Some(end)) = (req.age_range_start, req.age_range_end) {
            if end < start {
                return Err(AppError::validation(
                    "Faixa etária final deve ser maior ou igual à inicial",
                ));
            }
        }

        let class = sqlx::query_as::<_, EbdClass>(
            r#"
            INSERT INTO ebd_classes (church_id, term_id, name, age_range_start, age_range_end, room, max_capacity, teacher_id, aux_teacher_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.term_id)
        .bind(&req.name)
        .bind(req.age_range_start)
        .bind(req.age_range_end)
        .bind(&req.room)
        .bind(req.max_capacity)
        .bind(req.teacher_id)
        .bind(req.aux_teacher_id)
        .fetch_one(pool)
        .await?;

        Ok(class)
    }

    /// Update an EBD class
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        class_id: Uuid,
        req: &UpdateEbdClassRequest,
    ) -> Result<EbdClass, AppError> {
        Self::get_by_id(pool, church_id, class_id).await?;

        let mut set_clauses = Vec::new();
        let mut param_idx = 3u32;

        if req.name.is_some() {
            set_clauses.push(format!("name = ${param_idx}"));
            param_idx += 1;
        }
        if req.age_range_start.is_some() {
            set_clauses.push(format!("age_range_start = ${param_idx}"));
            param_idx += 1;
        }
        if req.age_range_end.is_some() {
            set_clauses.push(format!("age_range_end = ${param_idx}"));
            param_idx += 1;
        }
        if req.room.is_some() {
            set_clauses.push(format!("room = ${param_idx}"));
            param_idx += 1;
        }
        if req.max_capacity.is_some() {
            set_clauses.push(format!("max_capacity = ${param_idx}"));
            param_idx += 1;
        }
        if req.teacher_id.is_some() {
            set_clauses.push(format!("teacher_id = ${param_idx}"));
            param_idx += 1;
        }
        if req.aux_teacher_id.is_some() {
            set_clauses.push(format!("aux_teacher_id = ${param_idx}"));
            param_idx += 1;
        }
        if req.is_active.is_some() {
            set_clauses.push(format!("is_active = ${param_idx}"));
            param_idx += 1;
        }

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, class_id).await;
        }

        let _ = param_idx;
        set_clauses.push("updated_at = NOW()".to_string());
        let set_clause = set_clauses.join(", ");

        let sql = format!(
            "UPDATE ebd_classes SET {set_clause} WHERE id = $1 AND church_id = $2 RETURNING *"
        );

        let mut args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut args, class_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(name) = &req.name {
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
        }
        if let Some(v) = &req.age_range_start {
            sqlx::Arguments::add(&mut args, *v).unwrap();
        }
        if let Some(v) = &req.age_range_end {
            sqlx::Arguments::add(&mut args, *v).unwrap();
        }
        if let Some(v) = &req.room {
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
        }
        if let Some(v) = &req.max_capacity {
            sqlx::Arguments::add(&mut args, *v).unwrap();
        }
        if let Some(v) = &req.teacher_id {
            sqlx::Arguments::add(&mut args, *v).unwrap();
        }
        if let Some(v) = &req.aux_teacher_id {
            sqlx::Arguments::add(&mut args, *v).unwrap();
        }
        if let Some(v) = &req.is_active {
            sqlx::Arguments::add(&mut args, *v).unwrap();
        }

        let class = sqlx::query_as_with::<_, EbdClass, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(class)
    }

    /// List enrollments for a class
    pub async fn list_enrollments(
        pool: &PgPool,
        class_id: Uuid,
    ) -> Result<Vec<EbdEnrollmentDetail>, AppError> {
        let enrollments = sqlx::query_as::<_, EbdEnrollmentDetail>(
            r#"
            SELECT e.id, e.class_id, e.member_id, m.full_name AS member_name,
                   e.enrolled_at, e.left_at, e.is_active
            FROM ebd_enrollments e
            JOIN members m ON m.id = e.member_id
            WHERE e.class_id = $1
            ORDER BY m.full_name ASC
            "#,
        )
        .bind(class_id)
        .fetch_all(pool)
        .await?;

        Ok(enrollments)
    }

    /// RN-EBD-003: Enroll a member in a class (one student per class per term)
    pub async fn enroll_member(
        pool: &PgPool,
        class_id: Uuid,
        req: &CreateEbdEnrollmentRequest,
    ) -> Result<EbdEnrollment, AppError> {
        // Check if already enrolled in this class
        let existing = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_enrollments WHERE class_id = $1 AND member_id = $2 AND is_active = TRUE",
        )
        .bind(class_id)
        .bind(req.member_id)
        .fetch_one(pool)
        .await?;

        if existing > 0 {
            return Err(AppError::Conflict(
                "Membro já está matriculado nesta turma".to_string(),
            ));
        }

        // RN-EBD-003: Check if member is already enrolled in another class of the same term
        let same_term = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM ebd_enrollments en
            JOIN ebd_classes c1 ON c1.id = en.class_id
            JOIN ebd_classes c2 ON c2.id = $1
            WHERE en.member_id = $2 AND en.is_active = TRUE
            AND c1.term_id = c2.term_id AND c1.id != $1
            "#,
        )
        .bind(class_id)
        .bind(req.member_id)
        .fetch_one(pool)
        .await?;

        if same_term > 0 {
            return Err(AppError::Conflict(
                "Membro já está matriculado em outra turma do mesmo período".to_string(),
            ));
        }

        // Check capacity
        let class = sqlx::query_as::<_, EbdClass>(
            "SELECT * FROM ebd_classes WHERE id = $1",
        )
        .bind(class_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Turma EBD"))?;

        if let Some(max_capacity) = class.max_capacity {
            let count = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM ebd_enrollments WHERE class_id = $1 AND is_active = TRUE",
            )
            .bind(class_id)
            .fetch_one(pool)
            .await?;

            if count >= max_capacity as i64 {
                return Err(AppError::validation("Turma atingiu a capacidade máxima"));
            }
        }

        let enrollment = sqlx::query_as::<_, EbdEnrollment>(
            r#"
            INSERT INTO ebd_enrollments (class_id, member_id)
            VALUES ($1, $2)
            RETURNING *
            "#,
        )
        .bind(class_id)
        .bind(req.member_id)
        .fetch_one(pool)
        .await?;

        Ok(enrollment)
    }

    /// Remove enrollment (soft delete - set is_active to false)
    pub async fn remove_enrollment(
        pool: &PgPool,
        class_id: Uuid,
        enrollment_id: Uuid,
    ) -> Result<(), AppError> {
        let rows = sqlx::query(
            "UPDATE ebd_enrollments SET is_active = FALSE, left_at = CURRENT_DATE WHERE id = $1 AND class_id = $2",
        )
        .bind(enrollment_id)
        .bind(class_id)
        .execute(pool)
        .await?
        .rows_affected();

        if rows == 0 {
            return Err(AppError::not_found("Matrícula"));
        }

        Ok(())
    }
}
