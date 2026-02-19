use actix_web::{get, post, put, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{CreateChurchRequest, UpdateChurchRequest};
use crate::application::services::{ChurchService, AuditService};
use crate::config::AppConfig;
use crate::errors::AppError;

/// List all churches (super_admin only)
#[utoipa::path(
    get,
    path = "/api/v1/churches",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
    ),
    responses(
        (status = 200, description = "List of churches"),
        (status = 401, description = "Not authenticated"),
        (status = 403, description = "Forbidden")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/churches")]
pub async fn list_churches(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    // Only super_admin can list all churches
    if claims.role != "super_admin" {
        return Err(AppError::Forbidden("Apenas super administradores podem listar igrejas".into()));
    }

    let (churches, total) = ChurchService::list(
        pool.get_ref(),
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        churches,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get church details
#[utoipa::path(
    get,
    path = "/api/v1/churches/{id}",
    params(("id" = uuid::Uuid, Path, description = "Church ID")),
    responses(
        (status = 200, description = "Church details"),
        (status = 404, description = "Church not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/churches/{id}")]
pub async fn get_church(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = path.into_inner();

    // Non-super_admin can only view their own church
    if claims.role != "super_admin" {
        let user_church_id = middleware::get_church_id(&claims)?;
        if user_church_id != church_id {
            return Err(AppError::Forbidden("Sem permissão para visualizar esta igreja".into()));
        }
    }

    let church = ChurchService::get_by_id(pool.get_ref(), church_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(church)))
}

/// Get current user's church
#[utoipa::path(
    get,
    path = "/api/v1/churches/me",
    responses(
        (status = 200, description = "Current church details"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/churches/me")]
pub async fn get_my_church(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let church = ChurchService::get_by_id(pool.get_ref(), church_id).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::ok(church)))
}

/// Create a new church (super_admin only)
#[utoipa::path(
    post,
    path = "/api/v1/churches",
    request_body = CreateChurchRequest,
    responses(
        (status = 201, description = "Church created"),
        (status = 400, description = "Validation error"),
        (status = 403, description = "Forbidden")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/churches")]
pub async fn create_church(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateChurchRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    if claims.role != "super_admin" {
        return Err(AppError::Forbidden("Apenas super administradores podem criar igrejas".into()));
    }

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let church = ChurchService::create(pool.get_ref(), &body).await?;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church.id, Some(user_id), "create", "church", church.id,
    ).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        church,
        "Igreja criada com sucesso",
    )))
}

/// Update a church
#[utoipa::path(
    put,
    path = "/api/v1/churches/{id}",
    params(("id" = uuid::Uuid, Path, description = "Church ID")),
    request_body = UpdateChurchRequest,
    responses(
        (status = 200, description = "Church updated"),
        (status = 400, description = "Validation error"),
        (status = 404, description = "Church not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/churches/{id}")]
pub async fn update_church(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateChurchRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = path.into_inner();

    // Non-super_admin can only update their own church (and must be admin/pastor)
    if claims.role != "super_admin" {
        let user_church_id = middleware::get_church_id(&claims)?;
        if user_church_id != church_id {
            return Err(AppError::Forbidden("Sem permissão para editar esta igreja".into()));
        }
        middleware::require_permission(&claims, "settings:write")?;
    }

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let church = ChurchService::update(pool.get_ref(), church_id, &body).await?;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "update", "church", church_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        church,
        "Igreja atualizada com sucesso",
    )))
}
