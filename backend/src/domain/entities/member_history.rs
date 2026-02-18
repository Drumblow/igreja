use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MemberHistory {
    pub id: Uuid,
    pub church_id: Uuid,
    pub member_id: Uuid,
    pub event_type: String,
    pub event_date: NaiveDate,
    pub description: String,
    pub previous_value: Option<String>,
    pub new_value: Option<String>,
    pub registered_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}
