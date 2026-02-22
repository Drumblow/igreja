use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Asset {
    pub id: Uuid,
    pub church_id: Uuid,
    pub category_id: Uuid,
    pub asset_code: String,
    pub description: String,
    pub brand: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub acquisition_date: Option<NaiveDate>,
    pub acquisition_value: Option<Decimal>,
    pub acquisition_type: Option<String>,
    pub donor_member_id: Option<Uuid>,
    pub invoice_url: Option<String>,
    pub current_value: Option<Decimal>,
    pub residual_value: Option<Decimal>,
    pub accumulated_depreciation: Option<Decimal>,
    pub location: Option<String>,
    pub condition: String,
    pub status: String,
    pub status_date: Option<NaiveDate>,
    pub status_reason: Option<String>,
    pub notes: Option<String>,
    pub congregation_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AssetSummary {
    pub id: Uuid,
    pub asset_code: String,
    pub description: String,
    pub category_name: Option<String>,
    pub brand: Option<String>,
    pub model: Option<String>,
    pub location: Option<String>,
    pub condition: String,
    pub status: String,
    pub acquisition_date: Option<NaiveDate>,
    pub acquisition_value: Option<Decimal>,
    pub current_value: Option<Decimal>,
    pub congregation_id: Option<Uuid>,
    pub congregation_name: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AssetPhoto {
    pub id: Uuid,
    pub asset_id: Uuid,
    pub photo_url: String,
    pub caption: Option<String>,
    pub is_primary: bool,
    pub uploaded_at: DateTime<Utc>,
}
