use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct FinancialEntry {
    pub id: Uuid,
    pub church_id: Uuid,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub entry_type: String,
    pub account_plan_id: Uuid,
    pub bank_account_id: Uuid,
    pub campaign_id: Option<Uuid>,
    pub amount: Decimal,
    pub entry_date: NaiveDate,
    pub due_date: Option<NaiveDate>,
    pub payment_date: Option<NaiveDate>,
    pub description: String,
    pub payment_method: Option<String>,
    pub member_id: Option<Uuid>,
    pub supplier_name: Option<String>,
    pub receipt_url: Option<String>,
    pub status: String,
    pub is_recurring: bool,
    pub recurring_id: Option<Uuid>,
    pub is_closed: bool,
    pub closed_at: Option<DateTime<Utc>>,
    pub closed_by: Option<Uuid>,
    pub registered_by: Uuid,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

/// Financial entry with related names for list views
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct FinancialEntrySummary {
    pub id: Uuid,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub entry_type: String,
    pub amount: Decimal,
    pub entry_date: NaiveDate,
    pub due_date: Option<NaiveDate>,
    pub payment_date: Option<NaiveDate>,
    pub description: String,
    pub payment_method: Option<String>,
    pub status: String,
    pub is_closed: bool,
    pub account_plan_name: Option<String>,
    pub bank_account_name: Option<String>,
    pub member_name: Option<String>,
    pub campaign_name: Option<String>,
    pub supplier_name: Option<String>,
    pub created_at: DateTime<Utc>,
}

/// Financial summary / balance report
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct FinancialBalance {
    pub total_income: Decimal,
    pub total_expense: Decimal,
    pub balance: Decimal,
    pub income_by_category: Vec<CategoryAmount>,
    pub expense_by_category: Vec<CategoryAmount>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct CategoryAmount {
    pub category_name: String,
    pub amount: Decimal,
    pub count: Option<i64>,
}
