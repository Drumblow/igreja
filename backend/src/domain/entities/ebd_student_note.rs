use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdStudentNote {
    pub id: Uuid,
    pub church_id: Uuid,
    pub member_id: Uuid,
    pub term_id: Option<Uuid>,
    pub note_type: String,
    pub title: Option<String>,
    pub content: String,
    pub is_private: bool,
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdStudentNoteDetail {
    pub id: Uuid,
    pub church_id: Uuid,
    pub member_id: Uuid,
    pub term_id: Option<Uuid>,
    pub term_name: Option<String>,
    pub note_type: String,
    pub title: Option<String>,
    pub content: String,
    pub is_private: bool,
    pub created_by: Uuid,
    pub created_by_name: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
