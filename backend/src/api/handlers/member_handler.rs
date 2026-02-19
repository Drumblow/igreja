use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{CreateMemberRequest, MemberFilter, UpdateMemberRequest};
use crate::application::services::{AuditService, MemberService};
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cache::CacheService;

/// List members with pagination and filters
#[utoipa::path(
    get,
    path = "/api/v1/members",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("status" = Option<String>, Query, description = "Filter by status"),
        ("gender" = Option<String>, Query, description = "Filter by gender"),
    ),
    responses(
        (status = 200, description = "List of members"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/members")]
pub async fn list_members(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
    filter: web::Query<MemberFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let (members, total) = MemberService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        members,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get a single member by ID
#[utoipa::path(
    get,
    path = "/api/v1/members/{id}",
    params(("id" = uuid::Uuid, Path, description = "Member ID")),
    responses(
        (status = 200, description = "Member details"),
        (status = 404, description = "Member not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/members/{id}")]
pub async fn get_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    let member = MemberService::get_by_id(pool.get_ref(), church_id, member_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(member)))
}

/// Create a new member
#[utoipa::path(
    post,
    path = "/api/v1/members",
    request_body = CreateMemberRequest,
    responses(
        (status = 201, description = "Member created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/members")]
pub async fn create_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateMemberRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:create")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let member = MemberService::create(pool.get_ref(), church_id, &body).await?;

    // Invalidate members cache
    cache.del_pattern(&format!("members:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "create", "member", member.id,
    ).await.ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(member, "Membro cadastrado com sucesso")))
}

/// Update an existing member
#[utoipa::path(
    put,
    path = "/api/v1/members/{id}",
    params(("id" = uuid::Uuid, Path, description = "Member ID")),
    request_body = UpdateMemberRequest,
    responses(
        (status = 200, description = "Member updated"),
        (status = 400, description = "Validation error"),
        (status = 404, description = "Member not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/members/{id}")]
pub async fn update_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<UpdateMemberRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:update")?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    body.validate()
        .map_err(|e| AppError::validation(e.to_string()))?;

    let member = MemberService::update(pool.get_ref(), church_id, member_id, &body).await?;

    // Invalidate members cache
    cache.del_pattern(&format!("members:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "update", "member", member_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(member, "Membro atualizado com sucesso")))
}

/// Delete a member (soft delete)
#[utoipa::path(
    delete,
    path = "/api/v1/members/{id}",
    params(("id" = uuid::Uuid, Path, description = "Member ID")),
    responses(
        (status = 200, description = "Member deleted"),
        (status = 404, description = "Member not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/members/{id}")]
pub async fn delete_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<uuid::Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:delete")?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    MemberService::delete(pool.get_ref(), church_id, member_id).await?;

    // Invalidate members cache
    cache.del_pattern(&format!("members:*:{church_id}")).await;

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(), church_id, Some(user_id), "delete", "member", member_id,
    ).await.ok();

    Ok(HttpResponse::Ok().json(ApiResponse::ok(serde_json::json!({"message": "Membro removido com sucesso"}))))
}

/// Get member statistics
#[utoipa::path(
    get,
    path = "/api/v1/members/stats",
    responses(
        (status = 200, description = "Member statistics"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/members/stats")]
pub async fn member_stats(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    // Try cache first (TTL 60s for stats)
    let cache_key = format!("members:stats:{church_id}");
    if let Some(cached) = cache.get::<serde_json::Value>(&cache_key).await {
        return Ok(HttpResponse::Ok().json(ApiResponse::ok(cached)));
    }

    let total_active = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM members WHERE church_id = $1 AND status = 'ativo' AND deleted_at IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let total_inactive = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM members WHERE church_id = $1 AND status != 'ativo' AND deleted_at IS NULL"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let new_this_month = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM members WHERE church_id = $1 AND deleted_at IS NULL \
         AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM NOW()) \
         AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let new_this_year = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM members WHERE church_id = $1 AND deleted_at IS NULL \
         AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let stats = serde_json::json!({
        "total_active": total_active,
        "total_inactive": total_inactive,
        "new_members_this_month": new_this_month,
        "new_members_this_year": new_this_year
    });

    // Cache for 60 seconds
    cache.set(&cache_key, &stats, 60).await;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(stats)))
}
