use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdAttendance {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub member_id: Uuid,
    pub status: String,
    pub brought_bible: Option<bool>,
    pub brought_magazine: Option<bool>,
    pub offering_amount: Option<Decimal>,
    pub is_visitor: bool,
    pub visitor_name: Option<String>,
    pub notes: Option<String>,
    pub registered_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdAttendanceDetail {
    pub id: Uuid,
    pub lesson_id: Uuid,
    pub member_id: Uuid,
    pub member_name: Option<String>,
    pub status: String,
    pub brought_bible: Option<bool>,
    pub brought_magazine: Option<bool>,
    pub offering_amount: Option<Decimal>,
    pub is_visitor: bool,
    pub visitor_name: Option<String>,
    pub notes: Option<String>,
}
