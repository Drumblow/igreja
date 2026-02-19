use crate::application::dto::{CreateEbdLessonRequest, EbdLessonFilter};
use crate::domain::entities::{EbdLesson, EbdLessonSummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdLessonService;

impl EbdLessonService {
    /// List EBD lessons with filtering and pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &EbdLessonFilter,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<EbdLessonSummary>, i64), AppError> {
        let mut conditions = vec!["l.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if filter.class_id.is_some() {
            conditions.push(format!("l.class_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.date_from.is_some() {
            conditions.push(format!("l.lesson_date >= ${param_idx}"));
            param_idx += 1;
        }
        if filter.date_to.is_some() {
            conditions.push(format!("l.lesson_date <= ${param_idx}"));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM ebd_lessons l WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT l.id, l.class_id, c.name AS class_name, l.lesson_date, l.lesson_number,
                   l.title,
                   m.full_name AS teacher_name,
                   (SELECT COUNT(*) FROM ebd_attendances a WHERE a.lesson_id = l.id) AS attendance_count,
                   l.created_at
            FROM ebd_lessons l
            JOIN ebd_classes c ON c.id = l.class_id
            LEFT JOIN members m ON m.id = l.teacher_id
            WHERE {where_clause}
            ORDER BY l.lesson_date DESC, l.lesson_number ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(class_id) = &filter.class_id {
            sqlx::Arguments::add(&mut count_args, *class_id).unwrap();
            sqlx::Arguments::add(&mut data_args, *class_id).unwrap();
        }
        if let Some(date_from) = &filter.date_from {
            sqlx::Arguments::add(&mut count_args, *date_from).unwrap();
            sqlx::Arguments::add(&mut data_args, *date_from).unwrap();
        }
        if let Some(date_to) = &filter.date_to {
            sqlx::Arguments::add(&mut count_args, *date_to).unwrap();
            sqlx::Arguments::add(&mut data_args, *date_to).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let lessons = sqlx::query_as_with::<_, EbdLessonSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((lessons, total))
    }

    /// Get lesson by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        lesson_id: Uuid,
    ) -> Result<EbdLesson, AppError> {
        sqlx::query_as::<_, EbdLesson>(
            "SELECT * FROM ebd_lessons WHERE id = $1 AND church_id = $2",
        )
        .bind(lesson_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Aula EBD"))
    }

    /// Create a new lesson
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateEbdLessonRequest,
    ) -> Result<EbdLesson, AppError> {
        // Validate class belongs to the church
        let class_exists = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_classes WHERE id = $1 AND church_id = $2",
        )
        .bind(req.class_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        if class_exists == 0 {
            return Err(AppError::not_found("Turma EBD"));
        }

        let lesson = sqlx::query_as::<_, EbdLesson>(
            r#"
            INSERT INTO ebd_lessons (church_id, class_id, lesson_date, lesson_number, title, theme, bible_text, summary, teacher_id, materials_used)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.class_id)
        .bind(req.lesson_date)
        .bind(req.lesson_number)
        .bind(&req.title)
        .bind(&req.theme)
        .bind(&req.bible_text)
        .bind(&req.summary)
        .bind(req.teacher_id)
        .bind(&req.materials_used)
        .fetch_one(pool)
        .await?;

        Ok(lesson)
    }
}
