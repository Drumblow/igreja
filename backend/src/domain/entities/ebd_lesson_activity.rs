use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdLessonActivity {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub activity_type: String,
    pub title: String,
    pub description: Option<String>,
    pub options: Option<serde_json::Value>,
    pub correct_answer: Option<String>,
    pub bible_reference: Option<String>,
    pub is_required: bool,
    pub sort_order: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Activity without correct_answer (for students/read-only view)
#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdLessonActivityPublic {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub activity_type: String,
    pub title: String,
    pub description: Option<String>,
    pub options: Option<serde_json::Value>,
    pub bible_reference: Option<String>,
    pub is_required: bool,
    pub sort_order: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
