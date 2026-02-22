use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdClass {
    pub id: Uuid,
    pub church_id: Uuid,
    pub term_id: Uuid,
    pub name: String,
    pub age_range_start: Option<i32>,
    pub age_range_end: Option<i32>,
    pub room: Option<String>,
    pub max_capacity: Option<i32>,
    pub teacher_id: Option<Uuid>,
    pub aux_teacher_id: Option<Uuid>,
    pub congregation_id: Option<Uuid>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdClassSummary {
    pub id: Uuid,
    pub term_id: Uuid,
    pub name: String,
    pub age_range_start: Option<i32>,
    pub age_range_end: Option<i32>,
    pub room: Option<String>,
    pub max_capacity: Option<i32>,
    pub teacher_name: Option<String>,
    pub congregation_id: Option<Uuid>,
    pub congregation_name: Option<String>,
    pub is_active: bool,
    pub enrolled_count: Option<i64>,
    pub created_at: DateTime<Utc>,
}
