use serde::Deserialize;
use utoipa::ToSchema;
use validator::Validate;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateChurchRoleRequest {
    #[validate(length(min = 2, max = 50, message = "Chave deve ter entre 2 e 50 caracteres"))]
    pub key: String,
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub display_name: String,
    /// Tipo de investidura: consagracao, ordenacao, eleicao, nomeacao
    pub investiture_type: Option<String>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateChurchRoleRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub display_name: Option<String>,
    pub investiture_type: Option<String>,
    pub sort_order: Option<i32>,
    pub is_active: Option<bool>,
}
