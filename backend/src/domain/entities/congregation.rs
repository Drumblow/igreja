use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Congregation {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub short_name: Option<String>,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub congregation_type: String,
    pub leader_id: Option<Uuid>,
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub is_active: bool,
    pub sort_order: i32,
    pub settings: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Congregation summary for list views (includes leader name and member stats)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct CongregationSummary {
    pub id: Uuid,
    pub name: String,
    pub short_name: Option<String>,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub congregation_type: String,
    pub leader_id: Option<Uuid>,
    pub leader_name: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub is_active: bool,
    pub sort_order: i32,
    pub active_members: Option<i64>,
    pub total_members: Option<i64>,
    pub created_at: DateTime<Utc>,
}

/// Stats for a single congregation
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct CongregationStats {
    pub active_members: i64,
    pub total_members: i64,
    pub visitors: i64,
    pub congregados: i64,
    pub new_this_month: i64,
    pub income_this_month: f64,
    pub expense_this_month: f64,
    pub balance: f64,
    pub ebd_classes: i64,
    pub ebd_students: i64,
    pub total_assets: i64,
}

/// User's congregation access
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct UserCongregation {
    pub id: Uuid,
    pub user_id: Uuid,
    pub congregation_id: Uuid,
    pub role_in_congregation: String,
    pub is_primary: bool,
    pub created_at: DateTime<Utc>,
}

/// User congregation info for listing users of a congregation
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct CongregationUserInfo {
    pub user_id: Uuid,
    pub email: String,
    pub role_in_congregation: String,
    pub is_primary: bool,
    pub user_role_name: Option<String>,
}

/// Result of batch member assignment
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AssignMembersResult {
    pub assigned: i64,
    pub skipped: i64,
    pub skipped_members: Vec<SkippedMember>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct SkippedMember {
    pub id: Uuid,
    pub full_name: String,
    pub current_congregation: Option<String>,
}

/// Congregations overview for reports
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct CongregationsOverview {
    pub total_congregations: i64,
    pub total_members_all: i64,
    pub total_income_month: f64,
    pub total_expense_month: f64,
    pub congregations: Vec<CongregationOverviewItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct CongregationOverviewItem {
    pub id: Uuid,
    pub name: String,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub congregation_type: String,
    pub active_members: Option<i64>,
    pub income_month: Option<f64>,
    pub expense_month: Option<f64>,
}
