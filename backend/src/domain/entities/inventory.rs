use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Inventory {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub reference_date: NaiveDate,
    pub status: String,
    pub total_items: Option<i32>,
    pub found_items: Option<i32>,
    pub missing_items: Option<i32>,
    pub divergent_items: Option<i32>,
    pub conducted_by: Option<Uuid>,
    pub notes: Option<String>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct InventorySummary {
    pub id: Uuid,
    pub name: String,
    pub reference_date: NaiveDate,
    pub status: String,
    pub total_items: Option<i32>,
    pub found_items: Option<i32>,
    pub missing_items: Option<i32>,
    pub divergent_items: Option<i32>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct InventoryItem {
    pub id: Uuid,
    pub inventory_id: Uuid,
    pub asset_id: Uuid,
    pub status: String,
    pub observed_condition: Option<String>,
    pub notes: Option<String>,
    pub checked_at: Option<DateTime<Utc>>,
    pub checked_by: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct InventoryItemDetail {
    pub id: Uuid,
    pub inventory_id: Uuid,
    pub asset_id: Uuid,
    pub asset_code: Option<String>,
    pub asset_description: Option<String>,
    pub asset_location: Option<String>,
    pub registered_condition: Option<String>,
    pub status: String,
    pub observed_condition: Option<String>,
    pub notes: Option<String>,
    pub checked_at: Option<DateTime<Utc>>,
}
