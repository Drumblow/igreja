use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateChurchRequest {
    #[validate(length(min = 2, max = 200, message = "Nome deve ter entre 2 e 200 caracteres"))]
    pub name: String,
    pub legal_name: Option<String>,
    #[validate(length(max = 18))]
    pub cnpj: Option<String>,
    #[validate(email(message = "E-mail inválido"))]
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
    pub denomination: Option<String>,
    pub founded_at: Option<chrono::NaiveDate>,
    pub pastor_name: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateChurchRequest {
    #[validate(length(min = 2, max = 200, message = "Nome deve ter entre 2 e 200 caracteres"))]
    pub name: Option<String>,
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
    pub is_active: Option<bool>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ChurchSummary {
    pub id: Uuid,
    pub name: String,
    pub denomination: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub pastor_name: Option<String>,
    pub is_active: bool,
    pub member_count: i64,
}
