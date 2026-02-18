use serde::Deserialize;
use utoipa::ToSchema;
use validator::Validate;
use uuid::Uuid;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateFamilyRequest {
    #[validate(length(min = 2, max = 100, message = "Nome da família deve ter entre 2 e 100 caracteres"))]
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

    /// Members to add when creating the family
    pub members: Option<Vec<FamilyMemberInput>>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateFamilyRequest {
    #[validate(length(min = 2, max = 100, message = "Nome da família deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub head_id: Option<Uuid>,

    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,

    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct FamilyMemberInput {
    pub member_id: Uuid,
    #[validate(length(min = 1, message = "Relacionamento é obrigatório"))]
    pub relationship: String,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct AddFamilyMemberRequest {
    pub member_id: Uuid,
    #[validate(length(min = 1, message = "Relacionamento é obrigatório"))]
    pub relationship: String,
}
