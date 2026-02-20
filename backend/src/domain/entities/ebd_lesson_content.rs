use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdLessonContent {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub content_type: String,
    pub title: Option<String>,
    pub body: Option<String>,
    pub image_url: Option<String>,
    pub image_caption: Option<String>,
    pub sort_order: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
