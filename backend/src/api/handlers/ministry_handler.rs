use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use serde::Deserialize;
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{AddMinistryMemberRequest, CreateMinistryRequest, UpdateMinistryRequest};
use crate::application::services::MinistryService;
use crate::config::AppConfig;
use crate::errors::AppError;

#[derive(Debug, Deserialize)]
pub struct MinistryFilter {
    pub is_active: Option<bool>,
    pub congregation_id: Option<uuid::Uuid>,
}

/// List ministries with pagination
#[utoipa::path(
    get,
    path = "/api/v1/ministries",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
        ("congregation_id" = Option<uuid::Uuid>, Query, description = "Filter by congregation"),
    ),
    responses(
        (status = 200, description = "List of ministries"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ministries")]
pub async fn list_ministries(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<MinistryFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let (ministries, total) = MinistryService::list(
        pool.get_ref(),
        church_id,
        &pagination.search,
        filter.is_active,
        filter.congregation_id,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        ministries,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get ministry by ID
#[utoipa::path(
    get,
    path = "/api/v1/ministries/{id}",
    params(("id" = uuid::Uuid, Path, description = "Ministry ID")),
    responses(
        (status = 200, description = "Ministry details"),
        (status = 404, description = "Ministry not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ministries/{id}")]
pub async fn get_ministry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let ministry_id = path.into_inner();

    let ministry = MinistryService::get_by_id(pool.get_ref(), church_id, ministry_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(ministry)))
}

/// Create a new ministry
#[utoipa::path(
    post,
    path = "/api/v1/ministries",
    request_body = CreateMinistryRequest,
    responses(
        (status = 201, description = "Ministry created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ministries")]
pub async fn create_ministry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateMinistryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let ministry = MinistryService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(ministry, "Ministério criado com sucesso")))
}

/// Update a ministry
#[utoipa::path(
    put,
    path = "/api/v1/ministries/{id}",
    params(("id" = uuid::Uuid, Path, description = "Ministry ID")),
    request_body = UpdateMinistryRequest,
    responses(
        (status = 200, description = "Ministry updated"),
        (status = 404, description = "Ministry not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ministries/{id}")]
pub async fn update_ministry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateMinistryRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let ministry_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let ministry = MinistryService::update(pool.get_ref(), church_id, ministry_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(ministry, "Ministério atualizado com sucesso")))
}

/// Delete a ministry
#[utoipa::path(
    delete,
    path = "/api/v1/ministries/{id}",
    params(("id" = uuid::Uuid, Path, description = "Ministry ID")),
    responses(
        (status = 200, description = "Ministry deleted"),
        (status = 404, description = "Ministry not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ministries/{id}")]
pub async fn delete_ministry(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:delete")?;
    let church_id = middleware::get_church_id(&claims)?;
    let ministry_id = path.into_inner();

    MinistryService::delete(pool.get_ref(), church_id, ministry_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({"message": "Ministério removido com sucesso"}))))
}

/// List members of a ministry
#[utoipa::path(
    get,
    path = "/api/v1/ministries/{id}/members",
    params(("id" = uuid::Uuid, Path, description = "Ministry ID")),
    responses(
        (status = 200, description = "List of ministry members"),
        (status = 404, description = "Ministry not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ministries/{id}/members")]
pub async fn list_ministry_members(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let ministry_id = path.into_inner();

    let members = MinistryService::list_members(pool.get_ref(), church_id, ministry_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(members)))
}

/// Add a member to a ministry
#[utoipa::path(
    post,
    path = "/api/v1/ministries/{id}/members",
    params(("id" = uuid::Uuid, Path, description = "Ministry ID")),
    request_body = AddMinistryMemberRequest,
    responses(
        (status = 201, description = "Member added to ministry"),
        (status = 409, description = "Member already in ministry")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ministries/{id}/members")]
pub async fn add_ministry_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<AddMinistryMemberRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let ministry_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let mm = MinistryService::add_member(pool.get_ref(), church_id, ministry_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(mm, "Membro adicionado ao ministério")))
}

/// Remove a member from a ministry
#[utoipa::path(
    delete,
    path = "/api/v1/ministries/{ministry_id}/members/{member_id}",
    params(
        ("ministry_id" = uuid::Uuid, Path, description = "Ministry ID"),
        ("member_id" = uuid::Uuid, Path, description = "Member ID")
    ),
    responses(
        (status = 200, description = "Member removed from ministry"),
        (status = 404, description = "Association not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ministries/{ministry_id}/members/{member_id}")]
pub async fn remove_ministry_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(uuid::Uuid, uuid::Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let (ministry_id, member_id) = path.into_inner();

    MinistryService::remove_member(pool.get_ref(), church_id, ministry_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({"message": "Membro removido do ministério"}))))
}
