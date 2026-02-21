use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use serde::Deserialize;
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{
    AssetFilter, AssetLoanFilter, CreateAssetCategoryRequest, CreateAssetLoanRequest,
    CreateAssetRequest, CreateInventoryRequest, CreateMaintenanceRequest, MaintenanceFilter,
    ReturnAssetLoanRequest, UpdateAssetCategoryRequest, UpdateAssetRequest,
    UpdateInventoryItemRequest, UpdateMaintenanceRequest,
};
use crate::application::services::{
    AssetCategoryService, AssetLoanService, AssetService, InventoryService, MaintenanceService,
    AuditService,
};
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cache::CacheService;

// ==========================================
// Asset Categories
// ==========================================

/// List asset categories
#[utoipa::path(
    get,
    path = "/api/v1/assets/categories",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
    ),
    responses(
        (status = 200, description = "List of asset categories"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/categories")]
pub async fn list_asset_categories(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (categories, total) = AssetCategoryService::list(
        pool.get_ref(),
        church_id,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        categories,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Create a new asset category
#[utoipa::path(
    post,
    path = "/api/v1/assets/categories",
    request_body = CreateAssetCategoryRequest,
    responses(
        (status = 201, description = "Category created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/assets/categories")]
pub async fn create_asset_category(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateAssetCategoryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let category = AssetCategoryService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        category,
        "Categoria criada com sucesso",
    )))
}

/// Update an asset category
#[utoipa::path(
    put,
    path = "/api/v1/assets/categories/{id}",
    params(("id" = uuid::Uuid, Path, description = "Category ID")),
    request_body = UpdateAssetCategoryRequest,
    responses(
        (status = 200, description = "Category updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/assets/categories/{id}")]
pub async fn update_asset_category(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateAssetCategoryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let category_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let category =
        AssetCategoryService::update(pool.get_ref(), church_id, category_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        category,
        "Categoria atualizada com sucesso",
    )))
}

// ==========================================
// Assets
// ==========================================

/// List assets with filters and pagination
#[utoipa::path(
    get,
    path = "/api/v1/assets",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by description or code"),
        ("category_id" = Option<uuid::Uuid>, Query, description = "Filter by category"),
        ("status" = Option<String>, Query, description = "Filter by status"),
        ("condition" = Option<String>, Query, description = "Filter by condition"),
        ("location" = Option<String>, Query, description = "Filter by location"),
    ),
    responses(
        (status = 200, description = "List of assets"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets")]
pub async fn list_assets(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<AssetFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (assets, total) = AssetService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        assets,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get asset by ID
#[utoipa::path(
    get,
    path = "/api/v1/assets/{id}",
    params(("id" = uuid::Uuid, Path, description = "Asset ID")),
    responses(
        (status = 200, description = "Asset details"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/{id}")]
pub async fn get_asset(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let asset_id = path.into_inner();

    let asset = AssetService::get_by_id(pool.get_ref(), church_id, asset_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(asset)))
}

/// Create a new asset
#[utoipa::path(
    post,
    path = "/api/v1/assets",
    request_body = CreateAssetRequest,
    responses(
        (status = 201, description = "Asset created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/assets")]
pub async fn create_asset(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateAssetRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let asset = AssetService::create(pool.get_ref(), church_id, &body).await?;

    // Invalidate assets cache
    cache.del_pattern(&format!("assets:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "create", "asset", asset.id,
    ).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        asset,
        "Bem patrimonial cadastrado com sucesso",
    )))
}

/// Update an asset
#[utoipa::path(
    put,
    path = "/api/v1/assets/{id}",
    params(("id" = uuid::Uuid, Path, description = "Asset ID")),
    request_body = UpdateAssetRequest,
    responses(
        (status = 200, description = "Asset updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/assets/{id}")]
pub async fn update_asset(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateAssetRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let asset_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let asset = AssetService::update(pool.get_ref(), church_id, asset_id, &body).await?;

    // Invalidate assets cache
    cache.del_pattern(&format!("assets:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "update", "asset", asset_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        asset,
        "Bem patrimonial atualizado com sucesso",
    )))
}

/// Soft-delete an asset (baixa)
#[derive(Debug, Deserialize)]
pub struct DeleteAssetQuery {
    pub reason: Option<String>,
}

#[utoipa::path(
    delete,
    path = "/api/v1/assets/{id}",
    params(
        ("id" = uuid::Uuid, Path, description = "Asset ID"),
        ("reason" = Option<String>, Query, description = "Reason for deactivation"),
    ),
    responses(
        (status = 200, description = "Asset deactivated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/assets/{id}")]
pub async fn delete_asset(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<uuid::Uuid>,
    query: web::Query<DeleteAssetQuery>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:delete")?;
    let church_id = middleware::get_church_id(&claims)?;
    let asset_id = path.into_inner();

    AssetService::delete(
        pool.get_ref(),
        church_id,
        asset_id,
        query.reason.as_deref(),
    )
    .await?;

    // Invalidate assets cache
    cache.del_pattern(&format!("assets:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "delete", "asset", asset_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({
        "message": "Bem patrimonial baixado com sucesso"
    }))))
}

// ==========================================
// Maintenances
// ==========================================

/// List maintenances
#[utoipa::path(
    get,
    path = "/api/v1/assets/maintenances",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search"),
        ("asset_id" = Option<uuid::Uuid>, Query, description = "Filter by asset"),
        ("status" = Option<String>, Query, description = "Filter by status"),
        ("type" = Option<String>, Query, description = "Filter by type"),
    ),
    responses(
        (status = 200, description = "List of maintenances"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/maintenances")]
pub async fn list_maintenances(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<MaintenanceFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (maintenances, total) = MaintenanceService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        maintenances,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Create a maintenance
#[utoipa::path(
    post,
    path = "/api/v1/assets/maintenances",
    request_body = CreateMaintenanceRequest,
    responses(
        (status = 201, description = "Maintenance created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/assets/maintenances")]
pub async fn create_maintenance(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateMaintenanceRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let maintenance = MaintenanceService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        maintenance,
        "Manutenção registrada com sucesso",
    )))
}

/// Update a maintenance
#[utoipa::path(
    put,
    path = "/api/v1/assets/maintenances/{id}",
    params(("id" = uuid::Uuid, Path, description = "Maintenance ID")),
    request_body = UpdateMaintenanceRequest,
    responses(
        (status = 200, description = "Maintenance updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/assets/maintenances/{id}")]
pub async fn update_maintenance(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateMaintenanceRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let maintenance_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let maintenance =
        MaintenanceService::update(pool.get_ref(), church_id, maintenance_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        maintenance,
        "Manutenção atualizada com sucesso",
    )))
}

// ==========================================
// Inventories
// ==========================================

/// List inventories
#[utoipa::path(
    get,
    path = "/api/v1/assets/inventories",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
    ),
    responses(
        (status = 200, description = "List of inventories"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/inventories")]
pub async fn list_inventories(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (inventories, total) = InventoryService::list(
        pool.get_ref(),
        church_id,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        inventories,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get inventory with items
#[utoipa::path(
    get,
    path = "/api/v1/assets/inventories/{id}",
    params(("id" = uuid::Uuid, Path, description = "Inventory ID")),
    responses(
        (status = 200, description = "Inventory details with items"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/inventories/{id}")]
pub async fn get_inventory(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let inventory_id = path.into_inner();

    let inventory = InventoryService::get_by_id(pool.get_ref(), church_id, inventory_id).await?;
    let items = InventoryService::get_items(pool.get_ref(), inventory_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({
        "inventory": inventory,
        "items": items,
    }))))
}

/// Create a new inventory
#[utoipa::path(
    post,
    path = "/api/v1/assets/inventories",
    request_body = CreateInventoryRequest,
    responses(
        (status = 201, description = "Inventory created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/assets/inventories")]
pub async fn create_inventory(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateInventoryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let inventory =
        InventoryService::create(pool.get_ref(), church_id, user_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        inventory,
        "Inventário criado com sucesso",
    )))
}

/// Update an inventory item (conferência)
#[utoipa::path(
    put,
    path = "/api/v1/assets/inventories/{inventory_id}/items/{item_id}",
    params(
        ("inventory_id" = uuid::Uuid, Path, description = "Inventory ID"),
        ("item_id" = uuid::Uuid, Path, description = "Inventory Item ID"),
    ),
    request_body = UpdateInventoryItemRequest,
    responses(
        (status = 200, description = "Item updated"),
        (status = 404, description = "Not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/assets/inventories/{inventory_id}/items/{item_id}")]
pub async fn update_inventory_item(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(uuid::Uuid, uuid::Uuid)>,
    body: web::Json<UpdateInventoryItemRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let (inventory_id, item_id) = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let item = InventoryService::update_item(
        pool.get_ref(),
        church_id,
        inventory_id,
        item_id,
        user_id,
        &body,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        item,
        "Item do inventário atualizado",
    )))
}

/// Close an inventory
#[utoipa::path(
    post,
    path = "/api/v1/assets/inventories/{id}/close",
    params(("id" = uuid::Uuid, Path, description = "Inventory ID")),
    responses(
        (status = 200, description = "Inventory closed"),
        (status = 409, description = "Already closed or pending items")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/assets/inventories/{id}/close")]
pub async fn close_inventory(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let inventory_id = path.into_inner();

    let inventory = InventoryService::close(pool.get_ref(), church_id, inventory_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        inventory,
        "Inventário concluído com sucesso",
    )))
}

// ==========================================
// Asset Loans
// ==========================================

/// List asset loans
#[utoipa::path(
    get,
    path = "/api/v1/assets/loans",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search"),
        ("asset_id" = Option<uuid::Uuid>, Query, description = "Filter by asset"),
        ("borrower_member_id" = Option<uuid::Uuid>, Query, description = "Filter by borrower"),
        ("status" = Option<String>, Query, description = "active, returned, or overdue"),
    ),
    responses(
        (status = 200, description = "List of loans"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/loans")]
pub async fn list_asset_loans(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<AssetLoanFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let (loans, total) = AssetLoanService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        loans,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Create an asset loan
#[utoipa::path(
    post,
    path = "/api/v1/assets/loans",
    request_body = CreateAssetLoanRequest,
    responses(
        (status = 201, description = "Loan created"),
        (status = 400, description = "Validation error"),
        (status = 409, description = "Asset already loaned")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/assets/loans")]
pub async fn create_asset_loan(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateAssetLoanRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let loan = AssetLoanService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        loan,
        "Empréstimo registrado com sucesso",
    )))
}

/// Return an asset loan
#[utoipa::path(
    put,
    path = "/api/v1/assets/loans/{id}/return",
    params(("id" = uuid::Uuid, Path, description = "Loan ID")),
    request_body = ReturnAssetLoanRequest,
    responses(
        (status = 200, description = "Loan returned"),
        (status = 409, description = "Already returned")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/assets/loans/{id}/return")]
pub async fn return_asset_loan(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<ReturnAssetLoanRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let loan_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let loan =
        AssetLoanService::return_loan(pool.get_ref(), church_id, loan_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        loan,
        "Devolução registrada com sucesso",
    )))
}

// ==========================================
// Asset Stats
// ==========================================

/// Get asset statistics for the dashboard
#[utoipa::path(
    get,
    path = "/api/v1/assets/stats",
    responses(
        (status = 200, description = "Asset statistics"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/assets/stats")]
pub async fn asset_stats(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "assets:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    // Try cache first
    let cache_key = format!("assets:stats:{church_id}");
    if let Some(cached) = cache.get::<serde_json::Value>(&cache_key).await {
        return Ok(HttpResponse::Ok().json(ApiResponse::ok(cached)));
    }

    let total_assets = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM assets WHERE church_id = $1 AND deleted_at IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let total_active = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM assets WHERE church_id = $1 AND status = 'ativo' AND deleted_at IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let in_maintenance = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM assets WHERE church_id = $1 AND status = 'em_manutencao' AND deleted_at IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let on_loan = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM asset_loans al \
         JOIN assets a ON a.id = al.asset_id \
         WHERE a.church_id = $1 AND al.actual_return_date IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let total_value: Option<f64> = sqlx::query_scalar(
        "SELECT COALESCE(SUM(CAST(current_value AS DOUBLE PRECISION)), 0) FROM assets \
         WHERE church_id = $1 AND status = 'ativo' AND deleted_at IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let stats = serde_json::json!({
        "total_assets": total_assets,
        "total_active": total_active,
        "in_maintenance": in_maintenance,
        "on_loan": on_loan,
        "total_value": total_value.unwrap_or(0.0)
    });

    // Cache for 120 seconds
    cache.set(&cache_key, &stats, 120).await;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(stats)))
}
