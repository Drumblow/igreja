use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
#[allow(dead_code)]
pub struct Church {
    pub id: Uuid,
    pub name: String,
    pub legal_name: Option<String>,
    pub cnpj: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub website: Option<String>,

    // Address
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    // Details
    pub logo_url: Option<String>,
    pub denomination: Option<String>,
    pub founded_at: Option<chrono::NaiveDate>,
    pub pastor_name: Option<String>,

    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
