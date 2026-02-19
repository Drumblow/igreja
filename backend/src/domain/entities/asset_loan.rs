use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AssetLoan {
    pub id: Uuid,
    pub church_id: Uuid,
    pub asset_id: Uuid,
    pub borrower_member_id: Uuid,
    pub loan_date: NaiveDate,
    pub expected_return_date: NaiveDate,
    pub actual_return_date: Option<NaiveDate>,
    pub condition_out: String,
    pub condition_in: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct AssetLoanSummary {
    pub id: Uuid,
    pub asset_id: Uuid,
    pub asset_code: Option<String>,
    pub asset_description: Option<String>,
    pub borrower_member_id: Uuid,
    pub borrower_name: Option<String>,
    pub loan_date: NaiveDate,
    pub expected_return_date: NaiveDate,
    pub actual_return_date: Option<NaiveDate>,
    pub condition_out: String,
    pub condition_in: Option<String>,
    pub created_at: DateTime<Utc>,
}
