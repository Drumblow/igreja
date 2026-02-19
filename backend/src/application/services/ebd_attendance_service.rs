use crate::application::dto::CreateEbdAttendanceRequest;
use crate::domain::entities::{EbdAttendance, EbdAttendanceDetail};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdAttendanceService;

impl EbdAttendanceService {
    /// Record attendance for a lesson (batch insert/upsert)
    /// RN-EBD-004: Attendance editable up to 7 days
    pub async fn record_attendance(
        pool: &PgPool,
        lesson_id: Uuid,
        user_id: Uuid,
        req: &CreateEbdAttendanceRequest,
    ) -> Result<Vec<EbdAttendance>, AppError> {
        // Validate the lesson exists
        let lesson_exists = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_lessons WHERE id = $1",
        )
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        if lesson_exists == 0 {
            return Err(AppError::not_found("Aula EBD"));
        }

        // RN-EBD-004: Check if lesson is within 7-day edit window
        let days_old = sqlx::query_scalar::<_, Option<i32>>(
            "SELECT EXTRACT(DAY FROM NOW() - lesson_date::timestamp)::int FROM ebd_lessons WHERE id = $1",
        )
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        if let Some(days) = days_old {
            if days > 7 {
                return Err(AppError::validation(
                    "Frequência só pode ser editada até 7 dias após a aula",
                ));
            }
        }

        let mut results = Vec::new();

        for record in &req.attendances {
            // Validate status
            if !["presente", "ausente", "justificado"].contains(&record.status.as_str()) {
                return Err(AppError::validation(
                    "Status deve ser: presente, ausente ou justificado",
                ));
            }

            let attendance = sqlx::query_as::<_, EbdAttendance>(
                r#"
                INSERT INTO ebd_attendances (lesson_id, member_id, status, brought_bible, brought_magazine, offering_amount, is_visitor, visitor_name, registered_by)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                ON CONFLICT (lesson_id, member_id) DO UPDATE SET
                    status = EXCLUDED.status,
                    brought_bible = EXCLUDED.brought_bible,
                    brought_magazine = EXCLUDED.brought_magazine,
                    offering_amount = EXCLUDED.offering_amount,
                    is_visitor = EXCLUDED.is_visitor,
                    visitor_name = EXCLUDED.visitor_name,
                    registered_by = EXCLUDED.registered_by
                RETURNING *
                "#,
            )
            .bind(lesson_id)
            .bind(record.member_id)
            .bind(&record.status)
            .bind(record.brought_bible.unwrap_or(false))
            .bind(record.brought_magazine.unwrap_or(false))
            .bind(record.offering_amount)
            .bind(record.is_visitor.unwrap_or(false))
            .bind(&record.visitor_name)
            .bind(user_id)
            .fetch_one(pool)
            .await?;

            results.push(attendance);
        }

        Ok(results)
    }

    /// Get attendance records for a lesson
    pub async fn get_by_lesson(
        pool: &PgPool,
        lesson_id: Uuid,
    ) -> Result<Vec<EbdAttendanceDetail>, AppError> {
        let attendances = sqlx::query_as::<_, EbdAttendanceDetail>(
            r#"
            SELECT a.id, a.lesson_id, a.member_id,
                   CASE WHEN a.is_visitor THEN a.visitor_name ELSE m.full_name END AS member_name,
                   a.status, a.brought_bible, a.brought_magazine,
                   a.offering_amount, a.is_visitor, a.visitor_name
            FROM ebd_attendances a
            LEFT JOIN members m ON m.id = a.member_id
            WHERE a.lesson_id = $1
            ORDER BY COALESCE(m.full_name, a.visitor_name) ASC
            "#,
        )
        .bind(lesson_id)
        .fetch_all(pool)
        .await?;

        Ok(attendances)
    }

    /// Generate attendance report for a class within a date range
    pub async fn report(
        pool: &PgPool,
        church_id: Uuid,
        class_id: Uuid,
        date_from: &Option<chrono::NaiveDate>,
        date_to: &Option<chrono::NaiveDate>,
    ) -> Result<serde_json::Value, AppError> {
        // Validate class belongs to church
        let class_exists = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_classes WHERE id = $1 AND church_id = $2",
        )
        .bind(class_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        if class_exists == 0 {
            return Err(AppError::not_found("Turma EBD"));
        }

        // Build date conditions
        let mut lesson_conditions = vec!["l.class_id = $1".to_string()];
        let mut param_idx = 2u32;

        if date_from.is_some() {
            lesson_conditions.push(format!("l.lesson_date >= ${param_idx}"));
            param_idx += 1;
        }
        if date_to.is_some() {
            lesson_conditions.push(format!("l.lesson_date <= ${param_idx}"));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = lesson_conditions.join(" AND ");

        // Total lessons
        let total_lessons_sql = format!(
            "SELECT COUNT(*) FROM ebd_lessons l WHERE {where_clause}"
        );

        let mut args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut args, class_id).unwrap();
        if let Some(df) = date_from {
            sqlx::Arguments::add(&mut args, *df).unwrap();
        }
        if let Some(dt) = date_to {
            sqlx::Arguments::add(&mut args, *dt).unwrap();
        }

        let total_lessons = sqlx::query_scalar_with::<_, i64, _>(&total_lessons_sql, args)
            .fetch_one(pool)
            .await?;

        // Average attendance
        let avg_sql = format!(
            r#"
            SELECT COALESCE(AVG(cnt), 0)::float8 FROM (
                SELECT COUNT(*) AS cnt FROM ebd_attendances a
                JOIN ebd_lessons l ON l.id = a.lesson_id
                WHERE {where_clause} AND a.status = 'presente'
                GROUP BY a.lesson_id
            ) sub
            "#
        );

        let mut avg_args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut avg_args, class_id).unwrap();
        if let Some(df) = date_from {
            sqlx::Arguments::add(&mut avg_args, *df).unwrap();
        }
        if let Some(dt) = date_to {
            sqlx::Arguments::add(&mut avg_args, *dt).unwrap();
        }

        let avg_attendance = sqlx::query_scalar_with::<_, f64, _>(&avg_sql, avg_args)
            .fetch_one(pool)
            .await
            .unwrap_or(0.0);

        // Total offering
        let offering_sql = format!(
            r#"
            SELECT COALESCE(SUM(a.offering_amount), 0)::float8
            FROM ebd_attendances a
            JOIN ebd_lessons l ON l.id = a.lesson_id
            WHERE {where_clause}
            "#
        );

        let mut off_args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut off_args, class_id).unwrap();
        if let Some(df) = date_from {
            sqlx::Arguments::add(&mut off_args, *df).unwrap();
        }
        if let Some(dt) = date_to {
            sqlx::Arguments::add(&mut off_args, *dt).unwrap();
        }

        let total_offering = sqlx::query_scalar_with::<_, f64, _>(&offering_sql, off_args)
            .fetch_one(pool)
            .await
            .unwrap_or(0.0);

        // Bible/Magazine stats
        let stats_sql = format!(
            r#"
            SELECT
                COUNT(*) FILTER (WHERE a.brought_bible = TRUE)::float8 AS bibles,
                COUNT(*) FILTER (WHERE a.brought_magazine = TRUE)::float8 AS magazines,
                COUNT(*)::float8 AS total_records
            FROM ebd_attendances a
            JOIN ebd_lessons l ON l.id = a.lesson_id
            WHERE {where_clause} AND a.status = 'presente'
            "#
        );

        let mut stats_args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut stats_args, class_id).unwrap();
        if let Some(df) = date_from {
            sqlx::Arguments::add(&mut stats_args, *df).unwrap();
        }
        if let Some(dt) = date_to {
            sqlx::Arguments::add(&mut stats_args, *dt).unwrap();
        }

        let stats: (f64, f64, f64) = sqlx::query_as_with(&stats_sql, stats_args)
            .fetch_optional(pool)
            .await?
            .unwrap_or((0.0, 0.0, 0.0));

        let bible_pct = if stats.2 > 0.0 { (stats.0 / stats.2) * 100.0 } else { 0.0 };
        let magazine_pct = if stats.2 > 0.0 { (stats.1 / stats.2) * 100.0 } else { 0.0 };

        let report = serde_json::json!({
            "class_id": class_id,
            "total_lessons": total_lessons,
            "average_attendance": avg_attendance,
            "total_offering": total_offering,
            "bible_percentage": bible_pct,
            "magazine_percentage": magazine_pct,
        });

        Ok(report)
    }
}
