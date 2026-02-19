use chrono::NaiveDate;
use rust_decimal::Decimal;
use serde::Deserialize;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

// ==========================================
// Asset Categories
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateAssetCategoryRequest {
    pub parent_id: Option<Uuid>,
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    pub useful_life_months: Option<i32>,
    pub depreciation_rate: Option<Decimal>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateAssetCategoryRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub useful_life_months: Option<i32>,
    pub depreciation_rate: Option<Decimal>,
}

// ==========================================
// Assets
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateAssetRequest {
    pub category_id: Uuid,
    #[validate(length(min = 2, max = 300, message = "Descrição deve ter entre 2 e 300 caracteres"))]
    pub description: String,
    pub brand: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub acquisition_date: Option<NaiveDate>,
    pub acquisition_value: Option<Decimal>,
    /// "compra", "doacao", "construcao", "outro"
    pub acquisition_type: Option<String>,
    pub donor_member_id: Option<Uuid>,
    pub invoice_url: Option<String>,
    pub current_value: Option<Decimal>,
    pub residual_value: Option<Decimal>,
    pub location: Option<String>,
    /// "novo", "bom", "regular", "ruim", "inservivel"
    pub condition: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateAssetRequest {
    pub category_id: Option<Uuid>,
    #[validate(length(min = 2, max = 300, message = "Descrição deve ter entre 2 e 300 caracteres"))]
    pub description: Option<String>,
    pub brand: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub acquisition_date: Option<NaiveDate>,
    pub acquisition_value: Option<Decimal>,
    pub acquisition_type: Option<String>,
    pub donor_member_id: Option<Uuid>,
    pub invoice_url: Option<String>,
    pub current_value: Option<Decimal>,
    pub residual_value: Option<Decimal>,
    pub location: Option<String>,
    /// "novo", "bom", "regular", "ruim", "inservivel"
    pub condition: Option<String>,
    /// "ativo", "em_manutencao", "baixado", "cedido", "alienado"
    pub status: Option<String>,
    pub status_reason: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AssetFilter {
    pub category_id: Option<Uuid>,
    pub status: Option<String>,
    pub condition: Option<String>,
    pub location: Option<String>,
}

// ==========================================
// Maintenances
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateMaintenanceRequest {
    pub asset_id: Uuid,
    /// "preventiva" or "corretiva"
    #[validate(length(min = 1, message = "Tipo é obrigatório"))]
    #[serde(rename = "type")]
    pub maintenance_type: String,
    #[validate(length(min = 2, message = "Descrição é obrigatória"))]
    pub description: String,
    pub supplier_name: Option<String>,
    pub cost: Option<Decimal>,
    pub scheduled_date: Option<NaiveDate>,
    pub execution_date: Option<NaiveDate>,
    pub next_maintenance_date: Option<NaiveDate>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateMaintenanceRequest {
    pub description: Option<String>,
    pub supplier_name: Option<String>,
    pub cost: Option<Decimal>,
    pub scheduled_date: Option<NaiveDate>,
    pub execution_date: Option<NaiveDate>,
    pub next_maintenance_date: Option<NaiveDate>,
    /// "agendada", "em_andamento", "concluida", "cancelada"
    pub status: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct MaintenanceFilter {
    pub asset_id: Option<Uuid>,
    pub status: Option<String>,
    #[serde(rename = "type")]
    pub maintenance_type: Option<String>,
}

// ==========================================
// Inventories
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateInventoryRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    pub reference_date: NaiveDate,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateInventoryItemRequest {
    /// "encontrado", "nao_encontrado", "divergencia"
    pub status: String,
    /// "novo", "bom", "regular", "ruim", "inservivel"
    pub observed_condition: Option<String>,
    pub notes: Option<String>,
}

// ==========================================
// Asset Loans
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateAssetLoanRequest {
    pub asset_id: Uuid,
    pub borrower_member_id: Uuid,
    pub loan_date: NaiveDate,
    pub expected_return_date: NaiveDate,
    /// "novo", "bom", "regular", "ruim"
    #[validate(length(min = 1, message = "Condição de saída é obrigatória"))]
    pub condition_out: String,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct ReturnAssetLoanRequest {
    pub actual_return_date: NaiveDate,
    /// "novo", "bom", "regular", "ruim"
    #[validate(length(min = 1, message = "Condição de devolução é obrigatória"))]
    pub condition_in: String,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct AssetLoanFilter {
    pub asset_id: Option<Uuid>,
    pub borrower_member_id: Option<Uuid>,
    /// "active" (not returned), "returned", "overdue"
    pub status: Option<String>,
}
