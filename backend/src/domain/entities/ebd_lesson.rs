use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdLesson {
    pub id: Uuid,
    pub church_id: Uuid,
    pub class_id: Uuid,
    pub lesson_date: NaiveDate,
    pub lesson_number: Option<i32>,
    pub title: Option<String>,
    pub theme: Option<String>,
    pub bible_text: Option<String>,
    pub summary: Option<String>,
    pub teacher_id: Option<Uuid>,
    pub materials_used: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdLessonSummary {
    pub id: Uuid,
    pub class_id: Uuid,
    pub class_name: Option<String>,
    pub lesson_date: NaiveDate,
    pub lesson_number: Option<i32>,
    pub title: Option<String>,
    pub teacher_name: Option<String>,
    pub attendance_count: Option<i64>,
    pub created_at: DateTime<Utc>,
}
