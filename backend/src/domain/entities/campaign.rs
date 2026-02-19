use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Campaign {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub goal_amount: Option<Decimal>,
    pub raised_amount: Decimal,
    pub start_date: NaiveDate,
    pub end_date: Option<NaiveDate>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Campaign with computed progress percentage
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct CampaignSummary {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub goal_amount: Option<Decimal>,
    pub raised_amount: Decimal,
    pub start_date: NaiveDate,
    pub end_date: Option<NaiveDate>,
    pub status: String,
    pub entries_count: Option<i64>,
    pub created_at: DateTime<Utc>,
}
