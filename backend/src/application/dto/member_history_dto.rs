use chrono::NaiveDate;
use serde::Deserialize;
use utoipa::ToSchema;
use validator::Validate;

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateMemberHistoryRequest {
    #[validate(length(min = 1, message = "Tipo de evento é obrigatório"))]
    pub event_type: String,
    pub event_date: NaiveDate,
    #[validate(length(min = 1, message = "Descrição é obrigatória"))]
    pub description: String,
    pub previous_value: Option<String>,
    pub new_value: Option<String>,
}
