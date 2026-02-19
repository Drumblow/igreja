use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use serde::Deserialize;
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{
    BalanceReportFilter, CreateAccountPlanRequest, CreateBankAccountRequest,
    CreateCampaignRequest, CreateFinancialEntryRequest, FinancialEntryFilter,
    MonthlyClosingRequest, UpdateAccountPlanRequest, UpdateBankAccountRequest,
    UpdateCampaignRequest, UpdateFinancialEntryRequest,
};
use crate::application::services::{
    AccountPlanService, BankAccountService, CampaignService, FinancialEntryService,
    MonthlyClosingService, AuditService,
};
use crate::config::AppConfig;
use crate::errors::AppError;

// ==========================================
// Account Plans
// ==========================================

#[derive(Debug, Deserialize)]
pub struct AccountPlanFilter {
    #[serde(rename = "type")]
    pub plan_type: Option<String>,
    pub is_active: Option<bool>,
}

/// List account plans with pagination and filters
#[utoipa::path(
    get,
    path = "/api/v1/financial/account-plans",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("type" = Option<String>, Query, description = "Filter by type: receita, despesa"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
    ),
    responses(
        (status = 200, description = "List of account plans"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/account-plans")]
pub async fn list_account_plans(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<AccountPlanFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (plans, total) = AccountPlanService::list(
        pool.get_ref(),
        church_id,
        filter.plan_type.as_deref(),
        filter.is_active,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        plans,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Create a new account plan
#[utoipa::path(
    post,
    path = "/api/v1/financial/account-plans",
    request_body = CreateAccountPlanRequest,
    responses(
        (status = 201, description = "Account plan created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/financial/account-plans")]
pub async fn create_account_plan(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateAccountPlanRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let plan = AccountPlanService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        plan,
        "Plano de contas criado com sucesso",
    )))
}

/// Update an account plan
#[utoipa::path(
    put,
    path = "/api/v1/financial/account-plans/{id}",
    params(("id" = uuid::Uuid, Path, description = "Account plan ID")),
    request_body = UpdateAccountPlanRequest,
    responses(
        (status = 200, description = "Account plan updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/financial/account-plans/{id}")]
pub async fn update_account_plan(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateAccountPlanRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let plan_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let plan = AccountPlanService::update(pool.get_ref(), church_id, plan_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        plan,
        "Plano de contas atualizado com sucesso",
    )))
}

// ==========================================
// Bank Accounts
// ==========================================

#[derive(Debug, Deserialize)]
pub struct BankAccountFilter {
    pub is_active: Option<bool>,
}

/// List bank accounts
#[utoipa::path(
    get,
    path = "/api/v1/financial/bank-accounts",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
    ),
    responses(
        (status = 200, description = "List of bank accounts"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/bank-accounts")]
pub async fn list_bank_accounts(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<BankAccountFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (accounts, total) = BankAccountService::list(
        pool.get_ref(),
        church_id,
        filter.is_active,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        accounts,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Create a new bank account
#[utoipa::path(
    post,
    path = "/api/v1/financial/bank-accounts",
    request_body = CreateBankAccountRequest,
    responses(
        (status = 201, description = "Bank account created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/financial/bank-accounts")]
pub async fn create_bank_account(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateBankAccountRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let account = BankAccountService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        account,
        "Conta bancária criada com sucesso",
    )))
}

/// Update a bank account
#[utoipa::path(
    put,
    path = "/api/v1/financial/bank-accounts/{id}",
    params(("id" = uuid::Uuid, Path, description = "Bank account ID")),
    request_body = UpdateBankAccountRequest,
    responses(
        (status = 200, description = "Bank account updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/financial/bank-accounts/{id}")]
pub async fn update_bank_account(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateBankAccountRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let account_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let account =
        BankAccountService::update(pool.get_ref(), church_id, account_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        account,
        "Conta bancária atualizada com sucesso",
    )))
}

// ==========================================
// Campaigns
// ==========================================

#[derive(Debug, Deserialize)]
pub struct CampaignFilter {
    pub status: Option<String>,
}

/// List campaigns
#[utoipa::path(
    get,
    path = "/api/v1/financial/campaigns",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("status" = Option<String>, Query, description = "Filter by status"),
    ),
    responses(
        (status = 200, description = "List of campaigns"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/campaigns")]
pub async fn list_campaigns(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<CampaignFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (campaigns, total) = CampaignService::list(
        pool.get_ref(),
        church_id,
        filter.status.as_deref(),
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        campaigns,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get campaign by ID
#[utoipa::path(
    get,
    path = "/api/v1/financial/campaigns/{id}",
    params(("id" = uuid::Uuid, Path, description = "Campaign ID")),
    responses(
        (status = 200, description = "Campaign details"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/campaigns/{id}")]
pub async fn get_campaign(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let campaign_id = path.into_inner();

    let campaign = CampaignService::get_by_id(pool.get_ref(), church_id, campaign_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(campaign)))
}

/// Create a new campaign
#[utoipa::path(
    post,
    path = "/api/v1/financial/campaigns",
    request_body = CreateCampaignRequest,
    responses(
        (status = 201, description = "Campaign created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/financial/campaigns")]
pub async fn create_campaign(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateCampaignRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let campaign = CampaignService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        campaign,
        "Campanha criada com sucesso",
    )))
}

/// Update a campaign
#[utoipa::path(
    put,
    path = "/api/v1/financial/campaigns/{id}",
    params(("id" = uuid::Uuid, Path, description = "Campaign ID")),
    request_body = UpdateCampaignRequest,
    responses(
        (status = 200, description = "Campaign updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/financial/campaigns/{id}")]
pub async fn update_campaign(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateCampaignRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let campaign_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let campaign =
        CampaignService::update(pool.get_ref(), church_id, campaign_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        campaign,
        "Campanha atualizada com sucesso",
    )))
}

// ==========================================
// Financial Entries
// ==========================================

/// List financial entries with filters
#[utoipa::path(
    get,
    path = "/api/v1/financial/entries",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by description"),
        ("type" = Option<String>, Query, description = "receita or despesa"),
        ("status" = Option<String>, Query, description = "pendente, confirmado, cancelado"),
        ("date_from" = Option<String>, Query, description = "Start date"),
        ("date_to" = Option<String>, Query, description = "End date"),
    ),
    responses(
        (status = 200, description = "List of financial entries"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/entries")]
pub async fn list_financial_entries(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<FinancialEntryFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (entries, total) = FinancialEntryService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        entries,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get financial entry by ID
#[utoipa::path(
    get,
    path = "/api/v1/financial/entries/{id}",
    params(("id" = uuid::Uuid, Path, description = "Entry ID")),
    responses(
        (status = 200, description = "Financial entry details"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/entries/{id}")]
pub async fn get_financial_entry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let entry_id = path.into_inner();

    let entry = FinancialEntryService::get_by_id(pool.get_ref(), church_id, entry_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(entry)))
}

/// Create a new financial entry
#[utoipa::path(
    post,
    path = "/api/v1/financial/entries",
    request_body = CreateFinancialEntryRequest,
    responses(
        (status = 201, description = "Financial entry created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/financial/entries")]
pub async fn create_financial_entry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateFinancialEntryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let entry =
        FinancialEntryService::create(pool.get_ref(), church_id, user_id, &body).await?;

    // Audit log
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "create", "financial_entry", entry.id,
    ).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        entry,
        "Lançamento criado com sucesso",
    )))
}

/// Update a financial entry
#[utoipa::path(
    put,
    path = "/api/v1/financial/entries/{id}",
    params(("id" = uuid::Uuid, Path, description = "Entry ID")),
    request_body = UpdateFinancialEntryRequest,
    responses(
        (status = 200, description = "Financial entry updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/financial/entries/{id}")]
pub async fn update_financial_entry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateFinancialEntryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let entry_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let entry =
        FinancialEntryService::update(pool.get_ref(), church_id, entry_id, &body).await?;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "update", "financial_entry", entry_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        entry,
        "Lançamento atualizado com sucesso",
    )))
}

/// Delete (cancel) a financial entry
#[utoipa::path(
    delete,
    path = "/api/v1/financial/entries/{id}",
    params(("id" = uuid::Uuid, Path, description = "Entry ID")),
    responses(
        (status = 200, description = "Financial entry deleted"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/financial/entries/{id}")]
pub async fn delete_financial_entry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let entry_id = path.into_inner();

    FinancialEntryService::delete(pool.get_ref(), church_id, entry_id).await?;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "delete", "financial_entry", entry_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({
        "message": "Lançamento removido com sucesso"
    }))))
}

// ==========================================
// Balance Report
// ==========================================

/// Get financial balance report
#[utoipa::path(
    get,
    path = "/api/v1/financial/reports/balance",
    params(
        ("date_from" = Option<String>, Query, description = "Start date"),
        ("date_to" = Option<String>, Query, description = "End date"),
    ),
    responses(
        (status = 200, description = "Balance report"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/reports/balance")]
pub async fn balance_report(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    filter: web::Query<BalanceReportFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let report = FinancialEntryService::balance_report(pool.get_ref(), church_id, &filter).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(report)))
}

// ==========================================
// Monthly Closings
// ==========================================

/// List monthly closings
#[utoipa::path(
    get,
    path = "/api/v1/financial/monthly-closings",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
    ),
    responses(
        (status = 200, description = "List of monthly closings"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/financial/monthly-closings")]
pub async fn list_monthly_closings(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (closings, total) = MonthlyClosingService::list(
        pool.get_ref(),
        church_id,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        closings,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Perform monthly closing
#[utoipa::path(
    post,
    path = "/api/v1/financial/monthly-closings",
    request_body = MonthlyClosingRequest,
    responses(
        (status = 201, description = "Month closed successfully"),
        (status = 409, description = "Month already closed")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/financial/monthly-closings")]
pub async fn create_monthly_closing(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<MonthlyClosingRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "financial:close")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let closing =
        MonthlyClosingService::close_month(pool.get_ref(), church_id, user_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        closing,
        "Fechamento mensal realizado com sucesso",
    )))
}
