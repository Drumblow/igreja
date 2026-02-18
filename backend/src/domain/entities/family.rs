use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Family {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub head_id: Option<Uuid>,

    // Address
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct FamilyRelationship {
    pub id: Uuid,
    pub family_id: Uuid,
    pub member_id: Uuid,
    pub relationship: String,
    pub created_at: DateTime<Utc>,
}

/// Family with its members for detail views
#[derive(Debug, Clone, Serialize, ToSchema)]
pub struct FamilyDetail {
    pub id: Uuid,
    pub church_id: Uuid,
    pub name: String,
    pub head_id: Option<Uuid>,

    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,

    pub members: Vec<FamilyMemberInfo>,
}

/// Member info within a family context
#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct FamilyMemberInfo {
    pub member_id: Uuid,
    pub full_name: String,
    pub relationship: String,
    pub phone_primary: Option<String>,
    pub email: Option<String>,
    pub birth_date: Option<chrono::NaiveDate>,
}
