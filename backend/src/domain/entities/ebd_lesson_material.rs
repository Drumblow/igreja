use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdLessonMaterial {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub material_type: String,
    pub title: String,
    pub description: Option<String>,
    pub url: String,
    pub file_size_bytes: Option<i64>,
    pub mime_type: Option<String>,
    pub uploaded_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}
