use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdActivityResponse {
    pub id: Uuid,
    pub activity_id: Uuid,
    pub member_id: Uuid,
    pub response_text: Option<String>,
    pub is_completed: bool,
    pub score: Option<i16>,
    pub teacher_feedback: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdActivityResponseDetail {
    pub id: Uuid,
    pub activity_id: Uuid,
    pub member_id: Uuid,
    pub member_name: Option<String>,
    pub response_text: Option<String>,
    pub is_completed: bool,
    pub score: Option<i16>,
    pub teacher_feedback: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
