use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MonthlyClosing {
    pub id: Uuid,
    pub church_id: Uuid,
    pub reference_month: NaiveDate,
    pub total_income: Decimal,
    pub total_expense: Decimal,
    pub balance: Decimal,
    pub previous_balance: Decimal,
    pub accumulated_balance: Decimal,
    pub closed_by: Uuid,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Monthly closing with user name
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MonthlyClosingSummary {
    pub id: Uuid,
    pub reference_month: NaiveDate,
    pub total_income: Decimal,
    pub total_expense: Decimal,
    pub balance: Decimal,
    pub previous_balance: Decimal,
    pub accumulated_balance: Decimal,
    pub closed_by_name: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}
