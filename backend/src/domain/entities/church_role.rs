use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct ChurchRole {
    pub id: Uuid,
    pub church_id: Uuid,
    pub key: String,
    pub display_name: String,
    pub investiture_type: Option<String>,
    pub sort_order: i32,
    pub is_default: bool,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
