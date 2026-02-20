use crate::errors::AppError;
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdReportService;

impl EbdReportService {
    /// E6-1: Consolidated term report
    pub async fn term_report(
        pool: &PgPool,
        church_id: Uuid,
        term_id: Uuid,
    ) -> Result<serde_json::Value, AppError> {
        // Validate term belongs to church
        let term = sqlx::query_as::<_, (Uuid, String, Option<chrono::NaiveDate>, Option<chrono::NaiveDate>, Option<String>, bool)>(
            "SELECT id, name, start_date, end_date, theme, is_active FROM ebd_terms WHERE id = $1 AND church_id = $2",
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?;

        let term = match term {
            Some(t) => t,
            None => return Err(AppError::not_found("Período EBD")),
        };

        // Total classes
        let total_classes = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_classes WHERE term_id = $1 AND church_id = $2",
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        // Total students (active enrollments)
        let total_students = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(DISTINCT e.member_id)
            FROM ebd_enrollments e
            JOIN ebd_classes c ON c.id = e.class_id
            WHERE c.term_id = $1 AND c.church_id = $2 AND e.is_active = TRUE
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        // Total lessons
        let total_lessons = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*)
            FROM ebd_lessons l
            JOIN ebd_classes c ON c.id = l.class_id
            WHERE c.term_id = $1 AND l.church_id = $2
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        // Average attendance percentage across the term
        let avg_attendance_pct = sqlx::query_scalar::<_, Option<f64>>(
            r#"
            SELECT AVG(pct)::float8 FROM (
                SELECT
                    CASE WHEN COUNT(*) > 0
                        THEN (COUNT(*) FILTER (WHERE a.status = 'presente')::float8 / COUNT(*)::float8) * 100.0
                        ELSE 0.0
                    END AS pct
                FROM ebd_attendances a
                JOIN ebd_lessons l ON l.id = a.lesson_id
                JOIN ebd_classes c ON c.id = l.class_id
                WHERE c.term_id = $1 AND l.church_id = $2
                GROUP BY a.lesson_id
            ) sub
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?
        .unwrap_or(0.0);

        // Total offerings
        let total_offerings = sqlx::query_scalar::<_, Option<f64>>(
            r#"
            SELECT SUM(a.offering_amount)::float8
            FROM ebd_attendances a
            JOIN ebd_lessons l ON l.id = a.lesson_id
            JOIN ebd_classes c ON c.id = l.class_id
            WHERE c.term_id = $1 AND l.church_id = $2
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_one(pool)
        .await?
        .unwrap_or(0.0);

        // Bible/Magazine stats
        let (bibles, magazines, total_present): (f64, f64, f64) = sqlx::query_as(
            r#"
            SELECT
                COUNT(*) FILTER (WHERE a.brought_bible = TRUE)::float8,
                COUNT(*) FILTER (WHERE a.brought_magazine = TRUE)::float8,
                COUNT(*)::float8
            FROM ebd_attendances a
            JOIN ebd_lessons l ON l.id = a.lesson_id
            JOIN ebd_classes c ON c.id = l.class_id
            WHERE c.term_id = $1 AND l.church_id = $2 AND a.status = 'presente'
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .unwrap_or((0.0, 0.0, 0.0));

        let bible_pct = if total_present > 0.0 { (bibles / total_present) * 100.0 } else { 0.0 };
        let magazine_pct = if total_present > 0.0 { (magazines / total_present) * 100.0 } else { 0.0 };

        // Per-class summary
        let classes_summary = sqlx::query_as::<_, (Uuid, String, Option<String>, i64, i64, f64, f64)>(
            r#"
            SELECT
                c.id,
                c.name,
                m.full_name AS teacher_name,
                (SELECT COUNT(*) FROM ebd_enrollments e WHERE e.class_id = c.id AND e.is_active = TRUE) AS enrolled,
                (SELECT COUNT(*) FROM ebd_lessons l WHERE l.class_id = c.id) AS lessons_count,
                COALESCE((
                    SELECT AVG(pct)::float8 FROM (
                        SELECT
                            CASE WHEN COUNT(*) > 0
                                THEN (COUNT(*) FILTER (WHERE a2.status = 'presente')::float8 / COUNT(*)::float8) * 100.0
                                ELSE 0.0
                            END AS pct
                        FROM ebd_attendances a2
                        JOIN ebd_lessons l2 ON l2.id = a2.lesson_id
                        WHERE l2.class_id = c.id
                        GROUP BY a2.lesson_id
                    ) sub
                ), 0.0) AS attendance_pct,
                COALESCE((
                    SELECT SUM(a3.offering_amount)::float8
                    FROM ebd_attendances a3
                    JOIN ebd_lessons l3 ON l3.id = a3.lesson_id
                    WHERE l3.class_id = c.id
                ), 0.0) AS offerings
            FROM ebd_classes c
            LEFT JOIN members m ON m.id = c.teacher_id
            WHERE c.term_id = $1 AND c.church_id = $2
            ORDER BY c.name
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        let classes_json: Vec<serde_json::Value> = classes_summary
            .into_iter()
            .map(|(id, name, teacher, enrolled, lessons, att_pct, offerings)| {
                json!({
                    "class_id": id,
                    "class_name": name,
                    "teacher_name": teacher,
                    "enrolled_students": enrolled,
                    "total_lessons": lessons,
                    "attendance_percentage": (att_pct * 100.0).round() / 100.0,
                    "total_offerings": offerings,
                })
            })
            .collect();

        let report = json!({
            "term": {
                "id": term.0,
                "name": term.1,
                "start_date": term.2,
                "end_date": term.3,
                "theme": term.4,
                "is_active": term.5,
            },
            "total_classes": total_classes,
            "total_students": total_students,
            "total_lessons": total_lessons,
            "average_attendance_percentage": (avg_attendance_pct * 100.0).round() / 100.0,
            "total_offerings": total_offerings,
            "bible_percentage": (bible_pct * 100.0).round() / 100.0,
            "magazine_percentage": (magazine_pct * 100.0).round() / 100.0,
            "classes_summary": classes_json,
        });

        Ok(report)
    }

    /// E6-2: Classes ranked by attendance percentage
    pub async fn term_ranking(
        pool: &PgPool,
        church_id: Uuid,
        term_id: Uuid,
    ) -> Result<serde_json::Value, AppError> {
        // Validate term belongs to church
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

        let rows = sqlx::query_as::<_, (Uuid, String, Option<String>, i64, i64, f64, f64)>(
            r#"
            SELECT
                c.id,
                c.name,
                m.full_name AS teacher_name,
                (SELECT COUNT(*) FROM ebd_enrollments e WHERE e.class_id = c.id AND e.is_active = TRUE) AS enrolled,
                (SELECT COUNT(*) FROM ebd_lessons l WHERE l.class_id = c.id) AS lessons_count,
                COALESCE((
                    SELECT AVG(pct)::float8 FROM (
                        SELECT
                            CASE WHEN COUNT(*) > 0
                                THEN (COUNT(*) FILTER (WHERE a2.status = 'presente')::float8 / COUNT(*)::float8) * 100.0
                                ELSE 0.0
                            END AS pct
                        FROM ebd_attendances a2
                        JOIN ebd_lessons l2 ON l2.id = a2.lesson_id
                        WHERE l2.class_id = c.id
                        GROUP BY a2.lesson_id
                    ) sub
                ), 0.0) AS attendance_pct,
                COALESCE((
                    SELECT SUM(a3.offering_amount)::float8
                    FROM ebd_attendances a3
                    JOIN ebd_lessons l3 ON l3.id = a3.lesson_id
                    WHERE l3.class_id = c.id
                ), 0.0) AS offerings
            FROM ebd_classes c
            LEFT JOIN members m ON m.id = c.teacher_id
            WHERE c.term_id = $1 AND c.church_id = $2
            ORDER BY attendance_pct DESC
            "#,
        )
        .bind(term_id)
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        let ranking: Vec<serde_json::Value> = rows
            .into_iter()
            .enumerate()
            .map(|(i, (id, name, teacher, enrolled, lessons, att_pct, offerings))| {
                json!({
                    "rank": i + 1,
                    "class_id": id,
                    "class_name": name,
                    "teacher_name": teacher,
                    "enrolled_students": enrolled,
                    "total_lessons": lessons,
                    "attendance_percentage": (att_pct * 100.0).round() / 100.0,
                    "total_offerings": offerings,
                })
            })
            .collect();

        Ok(json!(ranking))
    }

    /// E6-3: Compare multiple terms side by side
    pub async fn term_comparison(
        pool: &PgPool,
        church_id: Uuid,
        term_ids: Vec<Uuid>,
    ) -> Result<serde_json::Value, AppError> {
        let mut comparisons = Vec::new();

        for tid in &term_ids {
            let term = sqlx::query_as::<_, (Uuid, String)>(
                "SELECT id, name FROM ebd_terms WHERE id = $1 AND church_id = $2",
            )
            .bind(tid)
            .bind(church_id)
            .fetch_optional(pool)
            .await?;

            let (term_id, term_name) = match term {
                Some(t) => t,
                None => continue, // skip invalid term_ids
            };

            let total_students = sqlx::query_scalar::<_, i64>(
                r#"
                SELECT COUNT(DISTINCT e.member_id)
                FROM ebd_enrollments e
                JOIN ebd_classes c ON c.id = e.class_id
                WHERE c.term_id = $1 AND c.church_id = $2
                "#,
            )
            .bind(term_id)
            .bind(church_id)
            .fetch_one(pool)
            .await?;

            let total_lessons = sqlx::query_scalar::<_, i64>(
                r#"
                SELECT COUNT(*)
                FROM ebd_lessons l
                JOIN ebd_classes c ON c.id = l.class_id
                WHERE c.term_id = $1 AND l.church_id = $2
                "#,
            )
            .bind(term_id)
            .bind(church_id)
            .fetch_one(pool)
            .await?;

            let avg_attendance_pct = sqlx::query_scalar::<_, Option<f64>>(
                r#"
                SELECT AVG(pct)::float8 FROM (
                    SELECT
                        CASE WHEN COUNT(*) > 0
                            THEN (COUNT(*) FILTER (WHERE a.status = 'presente')::float8 / COUNT(*)::float8) * 100.0
                            ELSE 0.0
                        END AS pct
                    FROM ebd_attendances a
                    JOIN ebd_lessons l ON l.id = a.lesson_id
                    JOIN ebd_classes c ON c.id = l.class_id
                    WHERE c.term_id = $1 AND l.church_id = $2
                    GROUP BY a.lesson_id
                ) sub
                "#,
            )
            .bind(term_id)
            .bind(church_id)
            .fetch_one(pool)
            .await?
            .unwrap_or(0.0);

            let total_offerings = sqlx::query_scalar::<_, Option<f64>>(
                r#"
                SELECT SUM(a.offering_amount)::float8
                FROM ebd_attendances a
                JOIN ebd_lessons l ON l.id = a.lesson_id
                JOIN ebd_classes c ON c.id = l.class_id
                WHERE c.term_id = $1 AND l.church_id = $2
                "#,
            )
            .bind(term_id)
            .bind(church_id)
            .fetch_one(pool)
            .await?
            .unwrap_or(0.0);

            comparisons.push(json!({
                "term_id": term_id,
                "term_name": term_name,
                "total_students": total_students,
                "total_lessons": total_lessons,
                "average_attendance_percentage": (avg_attendance_pct * 100.0).round() / 100.0,
                "total_offerings": total_offerings,
            }));
        }

        Ok(json!(comparisons))
    }

    /// E6-4: Students with 3+ consecutive absences
    pub async fn absent_students(
        pool: &PgPool,
        church_id: Uuid,
    ) -> Result<serde_json::Value, AppError> {
        // Find students with 3+ consecutive absences using window functions
        let rows = sqlx::query_as::<_, (Uuid, String, String, i64, Option<chrono::NaiveDate>, Option<String>)>(
            r#"
            WITH attendance_ordered AS (
                SELECT
                    a.member_id,
                    m.full_name AS member_name,
                    c.name AS class_name,
                    l.lesson_date,
                    a.status,
                    m.phone_primary,
                    ROW_NUMBER() OVER (PARTITION BY a.member_id, l.class_id ORDER BY l.lesson_date DESC) AS rn,
                    SUM(CASE WHEN a.status = 'presente' THEN 1 ELSE 0 END)
                        OVER (PARTITION BY a.member_id, l.class_id ORDER BY l.lesson_date DESC ROWS UNBOUNDED PRECEDING) AS running_present
                FROM ebd_attendances a
                JOIN ebd_lessons l ON l.id = a.lesson_id
                JOIN ebd_classes c ON c.id = l.class_id
                JOIN ebd_terms t ON t.id = c.term_id
                JOIN members m ON m.id = a.member_id
                WHERE l.church_id = $1 AND t.is_active = TRUE
            ),
            consecutive_absences AS (
                SELECT
                    member_id,
                    member_name,
                    class_name,
                    phone_primary,
                    COUNT(*) AS consecutive_absences,
                    MAX(lesson_date) FILTER (WHERE status = 'presente') AS last_present_date
                FROM attendance_ordered
                WHERE running_present = 0
                GROUP BY member_id, member_name, class_name, phone_primary
                HAVING COUNT(*) >= 3
            )
            SELECT
                member_id,
                member_name,
                class_name,
                consecutive_absences,
                last_present_date,
                phone_primary
            FROM consecutive_absences
            ORDER BY consecutive_absences DESC, member_name
            "#,
        )
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        let result: Vec<serde_json::Value> = rows
            .into_iter()
            .map(|(member_id, member_name, class_name, consecutive, last_present, phone)| {
                json!({
                    "member_id": member_id,
                    "member_name": member_name,
                    "class_name": class_name,
                    "consecutive_absences": consecutive,
                    "last_present_date": last_present,
                    "phone_primary": phone,
                })
            })
            .collect();

        Ok(json!(result))
    }
}
