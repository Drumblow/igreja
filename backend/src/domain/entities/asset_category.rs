use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AssetCategory {
    pub id: Uuid,
    pub church_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub name: String,
    pub useful_life_months: Option<i32>,
    pub depreciation_rate: Option<rust_decimal::Decimal>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AssetCategorySummary {
    pub id: Uuid,
    pub parent_id: Option<Uuid>,
    pub name: String,
    pub useful_life_months: Option<i32>,
    pub depreciation_rate: Option<rust_decimal::Decimal>,
    pub assets_count: Option<i64>,
    pub created_at: DateTime<Utc>,
}
