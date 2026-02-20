use crate::application::dto::{
    CreateActivityResponsesRequest, CreateLessonActivityRequest,
    UpdateActivityResponseRequest, UpdateLessonActivityRequest,
};
use crate::domain::entities::{
    EbdActivityResponse, EbdActivityResponseDetail, EbdLessonActivity,
};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct EbdLessonActivityService;

impl EbdLessonActivityService {
    /// List all activities for a lesson
    pub async fn list(
        pool: &PgPool,
        lesson_id: Uuid,
    ) -> Result<Vec<EbdLessonActivity>, AppError> {
        let activities = sqlx::query_as::<_, EbdLessonActivity>(
            r#"
            SELECT id, lesson_id, activity_type, title, description, options,
                   correct_answer, bible_reference, is_required, sort_order,
                   created_at, updated_at
            FROM ebd_lesson_activities
            WHERE lesson_id = $1
            ORDER BY sort_order ASC, created_at ASC
            "#,
        )
        .bind(lesson_id)
        .fetch_all(pool)
        .await?;

        Ok(activities)
    }

    /// Create a new activity for a lesson
    /// RN-EBD-E2-001: Max 10 activities per lesson
    /// RN-EBD-E2-002: multiple_choice must have 2-6 options
    pub async fn create(
        pool: &PgPool,
        lesson_id: Uuid,
        church_id: Uuid,
        req: &CreateLessonActivityRequest,
    ) -> Result<EbdLessonActivity, AppError> {
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

        // RN-EBD-E2-007: Check 7-day edit window
        let days_old = sqlx::query_scalar::<_, Option<i32>>(
            "SELECT EXTRACT(DAY FROM NOW() - lesson_date::timestamp)::int FROM ebd_lessons WHERE id = $1",
        )
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        if let Some(days) = days_old {
            if days > 7 {
                return Err(AppError::validation(
                    "Atividades só podem ser criadas até 7 dias após a aula",
                ));
            }
        }

        // RN-EBD-E2-001: Max 10 activities
        let count = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_lesson_activities WHERE lesson_id = $1",
        )
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        if count >= 10 {
            return Err(AppError::validation(
                "Cada lição pode ter no máximo 10 atividades",
            ));
        }

        // Validate activity_type
        let valid_types = ["question", "multiple_choice", "fill_blank", "group_activity", "homework", "other"];
        if !valid_types.contains(&req.activity_type.as_str()) {
            return Err(AppError::validation(
                "Tipo de atividade inválido. Valores aceitos: question, multiple_choice, fill_blank, group_activity, homework, other",
            ));
        }

        // RN-EBD-E2-002: Validate multiple_choice options
        if req.activity_type == "multiple_choice" {
            match &req.options {
                Some(opts) => {
                    if let Some(arr) = opts.as_array() {
                        if arr.len() < 2 || arr.len() > 6 {
                            return Err(AppError::validation(
                                "Múltipla escolha deve ter entre 2 e 6 opções",
                            ));
                        }
                    } else {
                        return Err(AppError::validation(
                            "Opções devem ser um array JSON",
                        ));
                    }
                }
                None => {
                    return Err(AppError::validation(
                        "Atividade de múltipla escolha requer opções",
                    ));
                }
            }
        }

        let sort_order = match req.sort_order {
            Some(s) => s,
            None => {
                let max: Option<i32> = sqlx::query_scalar(
                    "SELECT MAX(sort_order) FROM ebd_lesson_activities WHERE lesson_id = $1",
                )
                .bind(lesson_id)
                .fetch_one(pool)
                .await?;
                max.unwrap_or(0) + 1
            }
        };

        let activity = sqlx::query_as::<_, EbdLessonActivity>(
            r#"
            INSERT INTO ebd_lesson_activities
                (lesson_id, activity_type, title, description, options, correct_answer,
                 bible_reference, is_required, sort_order)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
            "#,
        )
        .bind(lesson_id)
        .bind(&req.activity_type)
        .bind(&req.title)
        .bind(&req.description)
        .bind(&req.options)
        .bind(&req.correct_answer)
        .bind(&req.bible_reference)
        .bind(req.is_required.unwrap_or(false))
        .bind(sort_order)
        .fetch_one(pool)
        .await?;

        Ok(activity)
    }

    /// Update an activity
    pub async fn update(
        pool: &PgPool,
        lesson_id: Uuid,
        activity_id: Uuid,
        req: &UpdateLessonActivityRequest,
    ) -> Result<EbdLessonActivity, AppError> {
        // Verify activity exists
        let existing = sqlx::query_as::<_, EbdLessonActivity>(
            "SELECT * FROM ebd_lesson_activities WHERE id = $1 AND lesson_id = $2",
        )
        .bind(activity_id)
        .bind(lesson_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Atividade"))?;

        // Validate activity_type if provided
        if let Some(at) = &req.activity_type {
            let valid_types = ["question", "multiple_choice", "fill_blank", "group_activity", "homework", "other"];
            if !valid_types.contains(&at.as_str()) {
                return Err(AppError::validation("Tipo de atividade inválido"));
            }
        }

        let activity_type = req.activity_type.as_deref().unwrap_or(&existing.activity_type);
        let title = req.title.as_deref().unwrap_or(&existing.title);
        let description = req.description.as_deref().or(existing.description.as_deref());
        let options = req.options.as_ref().or(existing.options.as_ref());
        let correct_answer = req.correct_answer.as_deref().or(existing.correct_answer.as_deref());
        let bible_reference = req.bible_reference.as_deref().or(existing.bible_reference.as_deref());
        let is_required = req.is_required.unwrap_or(existing.is_required);
        let sort_order = req.sort_order.unwrap_or(existing.sort_order);

        // RN-EBD-E2-002: Validate if changing to/keeping multiple_choice
        if activity_type == "multiple_choice" {
            match options {
                Some(opts) => {
                    if let Some(arr) = opts.as_array() {
                        if arr.len() < 2 || arr.len() > 6 {
                            return Err(AppError::validation(
                                "Múltipla escolha deve ter entre 2 e 6 opções",
                            ));
                        }
                    }
                }
                None => {
                    return Err(AppError::validation(
                        "Atividade de múltipla escolha requer opções",
                    ));
                }
            }
        }

        let activity = sqlx::query_as::<_, EbdLessonActivity>(
            r#"
            UPDATE ebd_lesson_activities
            SET activity_type = $1, title = $2, description = $3, options = $4,
                correct_answer = $5, bible_reference = $6, is_required = $7,
                sort_order = $8, updated_at = NOW()
            WHERE id = $9 AND lesson_id = $10
            RETURNING *
            "#,
        )
        .bind(activity_type)
        .bind(title)
        .bind(description)
        .bind(options)
        .bind(correct_answer)
        .bind(bible_reference)
        .bind(is_required)
        .bind(sort_order)
        .bind(activity_id)
        .bind(lesson_id)
        .fetch_one(pool)
        .await?;

        Ok(activity)
    }

    /// Delete an activity
    pub async fn delete(
        pool: &PgPool,
        lesson_id: Uuid,
        activity_id: Uuid,
    ) -> Result<(), AppError> {
        let rows = sqlx::query(
            "DELETE FROM ebd_lesson_activities WHERE id = $1 AND lesson_id = $2",
        )
        .bind(activity_id)
        .bind(lesson_id)
        .execute(pool)
        .await?
        .rows_affected();

        if rows == 0 {
            return Err(AppError::not_found("Atividade"));
        }

        Ok(())
    }

    /// List responses for an activity
    pub async fn list_responses(
        pool: &PgPool,
        activity_id: Uuid,
    ) -> Result<Vec<EbdActivityResponseDetail>, AppError> {
        let responses = sqlx::query_as::<_, EbdActivityResponseDetail>(
            r#"
            SELECT r.id, r.activity_id, r.member_id, m.full_name AS member_name,
                   r.response_text, r.is_completed, r.score, r.teacher_feedback,
                   r.created_at, r.updated_at
            FROM ebd_activity_responses r
            JOIN members m ON m.id = r.member_id
            WHERE r.activity_id = $1
            ORDER BY m.full_name ASC
            "#,
        )
        .bind(activity_id)
        .fetch_all(pool)
        .await?;

        Ok(responses)
    }

    /// Record responses in batch (UPSERT)
    /// RN-EBD-E2-004: Uses UPSERT so students can update their response
    pub async fn record_responses(
        pool: &PgPool,
        activity_id: Uuid,
        req: &CreateActivityResponsesRequest,
    ) -> Result<Vec<EbdActivityResponse>, AppError> {
        // Verify activity exists
        let exists = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM ebd_lesson_activities WHERE id = $1",
        )
        .bind(activity_id)
        .fetch_one(pool)
        .await?;

        if exists == 0 {
            return Err(AppError::not_found("Atividade"));
        }

        // RN-EBD-E2-006: Validate score range
        for record in &req.responses {
            if let Some(score) = record.score {
                if score < 0 || score > 10 {
                    return Err(AppError::validation("Nota deve ser entre 0 e 10"));
                }
            }
        }

        let mut results = Vec::new();

        for record in &req.responses {
            let response = sqlx::query_as::<_, EbdActivityResponse>(
                r#"
                INSERT INTO ebd_activity_responses
                    (activity_id, member_id, response_text, is_completed, score, teacher_feedback)
                VALUES ($1, $2, $3, $4, $5, $6)
                ON CONFLICT (activity_id, member_id) DO UPDATE SET
                    response_text = EXCLUDED.response_text,
                    is_completed = EXCLUDED.is_completed,
                    score = EXCLUDED.score,
                    teacher_feedback = EXCLUDED.teacher_feedback,
                    updated_at = NOW()
                RETURNING *
                "#,
            )
            .bind(activity_id)
            .bind(record.member_id)
            .bind(&record.response_text)
            .bind(record.is_completed)
            .bind(record.score)
            .bind(&record.teacher_feedback)
            .fetch_one(pool)
            .await?;

            results.push(response);
        }

        Ok(results)
    }

    /// Update a single response (e.g., teacher feedback)
    pub async fn update_response(
        pool: &PgPool,
        activity_id: Uuid,
        response_id: Uuid,
        req: &UpdateActivityResponseRequest,
    ) -> Result<EbdActivityResponse, AppError> {
        let existing = sqlx::query_as::<_, EbdActivityResponse>(
            "SELECT * FROM ebd_activity_responses WHERE id = $1 AND activity_id = $2",
        )
        .bind(response_id)
        .bind(activity_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Resposta"))?;

        let response_text = req.response_text.as_deref().or(existing.response_text.as_deref());
        let is_completed = req.is_completed.unwrap_or(existing.is_completed);
        let score = req.score.or(existing.score);
        let teacher_feedback = req.teacher_feedback.as_deref().or(existing.teacher_feedback.as_deref());

        let response = sqlx::query_as::<_, EbdActivityResponse>(
            r#"
            UPDATE ebd_activity_responses
            SET response_text = $1, is_completed = $2, score = $3,
                teacher_feedback = $4, updated_at = NOW()
            WHERE id = $5 AND activity_id = $6
            RETURNING *
            "#,
        )
        .bind(response_text)
        .bind(is_completed)
        .bind(score)
        .bind(teacher_feedback)
        .bind(response_id)
        .bind(activity_id)
        .fetch_one(pool)
        .await?;

        Ok(response)
    }
}
