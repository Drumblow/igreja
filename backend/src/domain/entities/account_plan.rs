use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AccountPlan {
    pub id: Uuid,
    pub church_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub plan_type: String,
    pub level: i16,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// AccountPlan with children count for list views
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AccountPlanSummary {
    pub id: Uuid,
    pub parent_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub plan_type: String,
    pub level: i16,
    pub is_active: bool,
    pub parent_name: Option<String>,
    pub children_count: Option<i64>,
    pub created_at: DateTime<Utc>,
}
