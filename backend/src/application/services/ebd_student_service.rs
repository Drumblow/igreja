use crate::application::dto::EbdStudentFilter;
use crate::domain::entities::{EbdEnrollmentHistory, EbdStudentSummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdStudentService;

impl EbdStudentService {
    /// List EBD students using the vw_ebd_student_profile view
    /// RN-EBD-E3-002: Member is an EBD student only if they have at least 1 enrollment
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &EbdStudentFilter,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<EbdStudentSummary>, i64), AppError> {
        let mut conditions = vec!["v.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if filter.term_id.is_some() {
            // Filter students who are enrolled in the specified term
            conditions.push(format!(
                "v.member_id IN (SELECT ee.member_id FROM ebd_enrollments ee \
                 JOIN ebd_classes ec ON ec.id = ee.class_id WHERE ec.term_id = ${param_idx})"
            ));
            param_idx += 1;
        }

        if filter.class_id.is_some() {
            conditions.push(format!(
                "v.member_id IN (SELECT ee.member_id FROM ebd_enrollments ee WHERE ee.class_id = ${param_idx} AND ee.is_active = TRUE)"
            ));
            param_idx += 1;
        }

        if filter.search.is_some() {
            conditions.push(format!(
                "unaccent(v.full_name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        if filter.min_attendance.is_some() {
            conditions.push(format!("v.attendance_percentage >= ${param_idx}"));
            param_idx += 1;
        }

        if filter.max_attendance.is_some() {
            conditions.push(format!("v.attendance_percentage <= ${param_idx}"));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM vw_ebd_student_profile v WHERE {where_clause}"
        );
        let query_sql = format!(
            r#"
            SELECT v.member_id, v.church_id, v.full_name, v.birth_date, v.gender,
                   v.phone_primary, v.photo_url, v.member_status,
                   v.active_enrollments, v.total_enrollments, v.terms_attended,
                   v.total_present, v.total_absent, v.total_justified,
                   v.total_attendance_records, v.attendance_percentage,
                   v.times_brought_bible, v.times_brought_magazine, v.total_offerings
            FROM vw_ebd_student_profile v
            WHERE {where_clause}
            ORDER BY v.full_name ASC
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
        if let Some(class_id) = &filter.class_id {
            sqlx::Arguments::add(&mut count_args, *class_id).unwrap();
            sqlx::Arguments::add(&mut data_args, *class_id).unwrap();
        }
        if let Some(search) = &filter.search {
            sqlx::Arguments::add(&mut count_args, search.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, search.as_str()).unwrap();
        }
        if let Some(min) = &filter.min_attendance {
            sqlx::Arguments::add(&mut count_args, *min).unwrap();
            sqlx::Arguments::add(&mut data_args, *min).unwrap();
        }
        if let Some(max) = &filter.max_attendance {
            sqlx::Arguments::add(&mut count_args, *max).unwrap();
            sqlx::Arguments::add(&mut data_args, *max).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let students = sqlx::query_as_with::<_, EbdStudentSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((students, total))
    }

    /// Get aggregated profile for a single student
    pub async fn get_profile(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
    ) -> Result<EbdStudentSummary, AppError> {
        let student = sqlx::query_as::<_, EbdStudentSummary>(
            r#"
            SELECT member_id, church_id, full_name, birth_date, gender,
                   phone_primary, photo_url, member_status,
                   active_enrollments, total_enrollments, terms_attended,
                   total_present, total_absent, total_justified,
                   total_attendance_records, attendance_percentage,
                   times_brought_bible, times_brought_magazine, total_offerings
            FROM vw_ebd_student_profile
            WHERE member_id = $1 AND church_id = $2
            "#,
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Aluno EBD"))?;

        Ok(student)
    }

    /// Get enrollment history for a student across all terms
    pub async fn get_history(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
    ) -> Result<Vec<EbdEnrollmentHistory>, AppError> {
        let history = sqlx::query_as::<_, EbdEnrollmentHistory>(
            r#"
            SELECT
                t.name AS term_name,
                c.name AS class_name,
                ee.enrolled_at,
                ee.left_at,
                ee.is_active,
                COUNT(ea.id) FILTER (WHERE ea.status = 'presente') AS lessons_attended,
                COUNT(DISTINCT el.id) AS total_lessons
            FROM ebd_enrollments ee
            JOIN ebd_classes c ON c.id = ee.class_id
            JOIN ebd_terms t ON t.id = c.term_id
            LEFT JOIN ebd_lessons el ON el.class_id = c.id
            LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id AND ea.member_id = ee.member_id
            WHERE ee.member_id = $1 AND c.church_id = $2
            GROUP BY t.name, t.start_date, c.name, ee.enrolled_at, ee.left_at, ee.is_active
            ORDER BY t.start_date DESC, c.name ASC
            "#,
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        Ok(history)
    }

    /// Get student's activity responses across all lessons
    pub async fn get_activities(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
    ) -> Result<serde_json::Value, AppError> {
        // Fetch all activity responses for the student
        let responses: Vec<(Uuid, String, String, Option<String>, bool, Option<i16>, Option<String>, String)> = sqlx::query_as(
            r#"
            SELECT
                r.activity_id,
                a.activity_type,
                a.title AS activity_title,
                r.response_text,
                r.is_completed,
                r.score,
                r.teacher_feedback,
                l.title AS lesson_title
            FROM ebd_activity_responses r
            JOIN ebd_lesson_activities a ON a.id = r.activity_id
            JOIN ebd_lessons l ON l.id = a.lesson_id
            WHERE r.member_id = $1 AND l.church_id = $2
            ORDER BY l.lesson_date DESC, a.sort_order ASC
            "#,
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        let data: Vec<serde_json::Value> = responses
            .iter()
            .map(|r| {
                serde_json::json!({
                    "activity_id": r.0,
                    "activity_type": r.1,
                    "activity_title": r.2,
                    "response_text": r.3,
                    "is_completed": r.4,
                    "score": r.5,
                    "teacher_feedback": r.6,
                    "lesson_title": r.7,
                })
            })
            .collect();

        Ok(serde_json::json!(data))
    }
}
