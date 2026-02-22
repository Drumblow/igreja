use serde::Deserialize;
use utoipa::ToSchema;
use validator::Validate;
use uuid::Uuid;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateMinistryRequest {
    #[validate(length(min = 2, max = 100, message = "Nome do ministério deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    pub description: Option<String>,
    pub leader_id: Option<Uuid>,
    pub congregation_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateMinistryRequest {
    #[validate(length(min = 2, max = 100, message = "Nome do ministério deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub description: Option<String>,
    pub leader_id: Option<Uuid>,
    pub is_active: Option<bool>,
    pub congregation_id: Option<Option<Uuid>>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct AddMinistryMemberRequest {
    pub member_id: Uuid,
    pub role_in_ministry: Option<String>,
}
