use chrono::NaiveDate;
use rust_decimal::Decimal;
use serde::Deserialize;
use utoipa::ToSchema;
use uuid::Uuid;
use validator::Validate;

// ==========================================
// Account Plans
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateAccountPlanRequest {
    pub parent_id: Option<Uuid>,
    #[validate(length(min = 1, max = 20, message = "Código deve ter entre 1 e 20 caracteres"))]
    pub code: String,
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    /// "receita" or "despesa"
    #[validate(length(min = 1, message = "Tipo é obrigatório"))]
    #[serde(rename = "type")]
    pub plan_type: String,
    pub level: Option<i16>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateAccountPlanRequest {
    #[validate(length(min = 1, max = 20, message = "Código deve ter entre 1 e 20 caracteres"))]
    pub code: Option<String>,
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub is_active: Option<bool>,
}

// ==========================================
// Bank Accounts
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateBankAccountRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: String,
    /// "caixa", "conta_corrente", "poupanca", "digital"
    #[validate(length(min = 1, message = "Tipo é obrigatório"))]
    #[serde(rename = "type")]
    pub account_type: String,
    pub bank_name: Option<String>,
    pub agency: Option<String>,
    pub account_number: Option<String>,
    pub initial_balance: Option<Decimal>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateBankAccountRequest {
    #[validate(length(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres"))]
    pub name: Option<String>,
    pub bank_name: Option<String>,
    pub agency: Option<String>,
    pub account_number: Option<String>,
    pub is_active: Option<bool>,
}

// ==========================================
// Campaigns
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateCampaignRequest {
    #[validate(length(min = 2, max = 150, message = "Nome deve ter entre 2 e 150 caracteres"))]
    pub name: String,
    pub description: Option<String>,
    pub goal_amount: Option<Decimal>,
    pub start_date: NaiveDate,
    pub end_date: Option<NaiveDate>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateCampaignRequest {
    #[validate(length(min = 2, max = 150, message = "Nome deve ter entre 2 e 150 caracteres"))]
    pub name: Option<String>,
    pub description: Option<String>,
    pub goal_amount: Option<Decimal>,
    pub end_date: Option<NaiveDate>,
    /// "ativa", "encerrada", "cancelada"
    pub status: Option<String>,
}

// ==========================================
// Financial Entries
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct CreateFinancialEntryRequest {
    /// "receita" or "despesa"
    #[validate(length(min = 1, message = "Tipo é obrigatório"))]
    #[serde(rename = "type")]
    pub entry_type: String,
    pub account_plan_id: Uuid,
    pub bank_account_id: Uuid,
    pub campaign_id: Option<Uuid>,
    pub amount: Decimal,
    pub entry_date: NaiveDate,
    pub due_date: Option<NaiveDate>,
    pub payment_date: Option<NaiveDate>,
    #[validate(length(min = 1, message = "Descrição é obrigatória"))]
    pub description: String,
    /// "dinheiro", "pix", "transferencia", "cartao_debito", "cartao_credito", "cheque", "boleto", "outro"
    pub payment_method: Option<String>,
    pub member_id: Option<Uuid>,
    pub supplier_name: Option<String>,
    pub receipt_url: Option<String>,
    /// "pendente", "confirmado"
    pub status: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct UpdateFinancialEntryRequest {
    pub account_plan_id: Option<Uuid>,
    pub bank_account_id: Option<Uuid>,
    pub campaign_id: Option<Uuid>,
    pub amount: Option<Decimal>,
    pub entry_date: Option<NaiveDate>,
    pub due_date: Option<NaiveDate>,
    pub payment_date: Option<NaiveDate>,
    pub description: Option<String>,
    pub payment_method: Option<String>,
    pub member_id: Option<Uuid>,
    pub supplier_name: Option<String>,
    pub receipt_url: Option<String>,
    pub status: Option<String>,
    pub notes: Option<String>,
}

// ==========================================
// Monthly Closing
// ==========================================

#[derive(Debug, Deserialize, Validate, ToSchema)]
pub struct MonthlyClosingRequest {
    /// First day of the month to close (e.g., "2026-02-01")
    pub reference_month: NaiveDate,
    pub notes: Option<String>,
}

// ==========================================
// Report Filters
// ==========================================

#[derive(Debug, Deserialize)]
pub struct FinancialEntryFilter {
    /// "receita" or "despesa"
    #[serde(rename = "type")]
    pub entry_type: Option<String>,
    pub account_plan_id: Option<Uuid>,
    pub bank_account_id: Option<Uuid>,
    pub status: Option<String>,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub member_id: Option<Uuid>,
    pub campaign_id: Option<Uuid>,
    pub payment_method: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct BalanceReportFilter {
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}
