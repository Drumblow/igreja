use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct BankAccount {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub account_type: String,
    pub bank_name: Option<String>,
    pub agency: Option<String>,
    pub account_number: Option<String>,
    pub initial_balance: Decimal,
    pub current_balance: Decimal,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
