use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Ministry {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub leader_id: Option<Uuid>,
    pub congregation_id: Option<Uuid>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MemberMinistry {
    pub id: Uuid,
    pub member_id: Uuid,
    pub ministry_id: Uuid,
    pub joined_at: NaiveDate,
    pub left_at: Option<NaiveDate>,
    pub role_in_ministry: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

/// Ministry with member count for list views
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MinistrySummary {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub leader_id: Option<Uuid>,
    pub leader_name: Option<String>,
    pub congregation_id: Option<Uuid>,
    pub congregation_name: Option<String>,
    pub is_active: bool,
    pub member_count: Option<i64>,
    pub created_at: DateTime<Utc>,
}

/// Member info within a ministry context
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MinistryMemberInfo {
    pub member_id: Uuid,
    pub full_name: String,
    pub role_in_ministry: Option<String>,
    pub joined_at: NaiveDate,
    pub phone_primary: Option<String>,
    pub email: Option<String>,
}
