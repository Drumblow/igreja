use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Member {
    pub id: Uuid,
    pub church_id: Uuid,
    pub family_id: Option<Uuid>,

    // Personal data
    pub full_name: String,
    pub social_name: Option<String>,
    pub birth_date: Option<NaiveDate>,
    pub gender: String,
    pub marital_status: Option<String>,
    pub cpf: Option<String>,
    pub email: Option<String>,
    pub phone_primary: Option<String>,
    pub phone_secondary: Option<String>,
    pub photo_url: Option<String>,

    // Address
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    // Additional
    pub profession: Option<String>,
    pub workplace: Option<String>,
    pub birthplace_city: Option<String>,
    pub birthplace_state: Option<String>,
    pub nationality: Option<String>,
    pub education_level: Option<String>,
    pub blood_type: Option<String>,

    // Ecclesiastical
    pub conversion_date: Option<NaiveDate>,
    pub water_baptism_date: Option<NaiveDate>,
    pub spirit_baptism_date: Option<NaiveDate>,
    pub origin_church: Option<String>,
    pub entry_date: Option<NaiveDate>,
    pub entry_type: Option<String>,
    pub role_position: Option<String>,
    pub ordination_date: Option<NaiveDate>,
    pub marriage_date: Option<NaiveDate>,

    // Status
    pub status: String,
    pub status_changed_at: Option<DateTime<Utc>>,
    pub status_reason: Option<String>,

    pub notes: Option<String>,

    // Congregation (transversal)
    pub congregation_id: Option<Uuid>,

    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

/// Lightweight member for list views
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct MemberSummary {
    pub id: Uuid,
    pub full_name: String,
    pub birth_date: Option<NaiveDate>,
    pub gender: String,
    pub phone_primary: Option<String>,
    pub email: Option<String>,
    pub status: String,
    pub role_position: Option<String>,
    pub photo_url: Option<String>,
    pub entry_date: Option<NaiveDate>,
    pub congregation_id: Option<Uuid>,
    pub congregation_name: Option<String>,
    pub created_at: DateTime<Utc>,
}
