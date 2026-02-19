use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Maintenance {
    pub id: Uuid,
    pub church_id: Uuid,
    pub asset_id: Uuid,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub maintenance_type: String,
    pub description: String,
    pub supplier_name: Option<String>,
    pub cost: Option<Decimal>,
    pub scheduled_date: Option<NaiveDate>,
    pub execution_date: Option<NaiveDate>,
    pub next_maintenance_date: Option<NaiveDate>,
    pub status: String,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MaintenanceSummary {
    pub id: Uuid,
    pub asset_id: Uuid,
    pub asset_code: Option<String>,
    pub asset_description: Option<String>,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub maintenance_type: String,
    pub description: String,
    pub supplier_name: Option<String>,
    pub cost: Option<Decimal>,
    pub scheduled_date: Option<NaiveDate>,
    pub execution_date: Option<NaiveDate>,
    pub status: String,
    pub created_at: DateTime<Utc>,
}
