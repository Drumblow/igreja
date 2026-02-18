use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{AddFamilyMemberRequest, CreateFamilyRequest, UpdateFamilyRequest};
use crate::application::services::FamilyService;
use crate::config::AppConfig;
use crate::errors::AppError;

/// List families with pagination
#[utoipa::path(
    get,
    path = "/api/v1/families",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
    ),
    responses(
        (status = 200, description = "List of families"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/families")]
pub async fn list_families(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let (families, total) = FamilyService::list(
        pool.get_ref(),
        church_id,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        families,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get family details with members
#[utoipa::path(
    get,
    path = "/api/v1/families/{id}",
    params(("id" = uuid::Uuid, Path, description = "Family ID")),
    responses(
        (status = 200, description = "Family details with members"),
        (status = 404, description = "Family not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/families/{id}")]
pub async fn get_family(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let family_id = path.into_inner();

    let family = FamilyService::get_by_id(pool.get_ref(), church_id, family_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(family)))
}

/// Create a new family
#[utoipa::path(
    post,
    path = "/api/v1/families",
    request_body = CreateFamilyRequest,
    responses(
        (status = 201, description = "Family created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/families")]
pub async fn create_family(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateFamilyRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let family = FamilyService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(family, "Família criada com sucesso")))
}

/// Update a family
#[utoipa::path(
    put,
    path = "/api/v1/families/{id}",
    params(("id" = uuid::Uuid, Path, description = "Family ID")),
    request_body = UpdateFamilyRequest,
    responses(
        (status = 200, description = "Family updated"),
        (status = 404, description = "Family not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/families/{id}")]
pub async fn update_family(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateFamilyRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let family_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let family = FamilyService::update(pool.get_ref(), church_id, family_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(family, "Família atualizada com sucesso")))
}

/// Delete a family
#[utoipa::path(
    delete,
    path = "/api/v1/families/{id}",
    params(("id" = uuid::Uuid, Path, description = "Family ID")),
    responses(
        (status = 200, description = "Family deleted"),
        (status = 404, description = "Family not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/families/{id}")]
pub async fn delete_family(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:delete")?;
    let church_id = middleware::get_church_id(&claims)?;
    let family_id = path.into_inner();

    FamilyService::delete(pool.get_ref(), church_id, family_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({"message": "Família removida com sucesso"}))))
}

/// Add a member to a family
#[utoipa::path(
    post,
    path = "/api/v1/families/{id}/members",
    params(("id" = uuid::Uuid, Path, description = "Family ID")),
    request_body = AddFamilyMemberRequest,
    responses(
        (status = 201, description = "Member added to family"),
        (status = 409, description = "Member already in another family")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/families/{id}/members")]
pub async fn add_family_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<AddFamilyMemberRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let family_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let rel = FamilyService::add_member(pool.get_ref(), church_id, family_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(rel, "Membro adicionado à família")))
}

/// Remove a member from a family
#[utoipa::path(
    delete,
    path = "/api/v1/families/{family_id}/members/{member_id}",
    params(
        ("family_id" = uuid::Uuid, Path, description = "Family ID"),
        ("member_id" = uuid::Uuid, Path, description = "Member ID")
    ),
    responses(
        (status = 200, description = "Member removed from family"),
        (status = 404, description = "Relationship not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/families/{family_id}/members/{member_id}")]
pub async fn remove_family_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<(uuid::Uuid, uuid::Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let (family_id, member_id) = path.into_inner();

    FamilyService::remove_member(pool.get_ref(), church_id, family_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({"message": "Membro removido da família"}))))
}
