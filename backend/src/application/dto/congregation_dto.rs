use serde::Deserialize;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateCongregationRequest {
    #[validate(length(min = 2, max = 200, message = "Nome da congregação deve ter entre 2 e 200 caracteres"))]
    pub name: String,
    #[validate(length(max = 50, message = "Nome curto deve ter no máximo 50 caracteres"))]
    pub short_name: Option<String>,
    pub congregation_type: Option<String>,
    pub leader_id: Option<Uuid>,
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateCongregationRequest {
    #[validate(length(min = 2, max = 200, message = "Nome da congregação deve ter entre 2 e 200 caracteres"))]
    pub name: Option<String>,
    pub short_name: Option<String>,
    pub congregation_type: Option<String>,
    pub leader_id: Option<Uuid>,
    pub zip_code: Option<String>,
    pub street: Option<String>,
    pub number: Option<String>,
    pub complement: Option<String>,
    pub neighborhood: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub is_active: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct AssignMembersRequest {
    pub member_ids: Vec<Uuid>,
    #[serde(default)]
    pub overwrite: bool,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct AddUserToCongregationRequest {
    pub user_id: Uuid,
    pub role_in_congregation: String,
    #[serde(default)]
    pub is_primary: bool,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct SetActiveCongregationRequest {
    pub congregation_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct CongregationCompareFilter {
    pub metric: Option<String>,
    pub period_start: Option<String>,
    pub period_end: Option<String>,
    pub congregation_ids: Option<String>,
}
