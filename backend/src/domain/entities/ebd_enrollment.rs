use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdEnrollment {
    pub id: Uuid,
    pub class_id: Uuid,
    pub member_id: Uuid,
    pub enrolled_at: NaiveDate,
    pub left_at: Option<NaiveDate>,
    pub is_active: bool,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct EbdEnrollmentDetail {
    pub id: Uuid,
    pub class_id: Uuid,
    pub member_id: Uuid,
    pub member_name: Option<String>,
    pub enrolled_at: NaiveDate,
    pub left_at: Option<NaiveDate>,
    pub is_active: bool,
}
