use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use serde::Deserialize;
use sqlx::PgPool;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{
    BatchCreateUserItem, BatchCreateUsersRequest, BatchCreateUsersResponse, BatchSkippedItem,
    CreateMemberRequest, CreateUserForMemberRequest, CreateUserForMemberResponse, MemberFilter,
    UpdateMemberRequest,
};
use crate::application::services::{AuditService, AuthService, MemberService};
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cache::CacheService;

/// Optional congregation_id filter for stats endpoints
#[derive(Debug, Deserialize)]
pub struct CongregationIdFilter {
    pub congregation_id: Option<uuid::Uuid>,
}

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
        ("congregation_id" = Option<uuid::Uuid>, Query, description = "Filter by congregation"),
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
    let allowed_congregations = middleware::get_allowed_congregations(&claims);

    let (members, total) = MemberService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &pagination.search,
        pagination.per_page(),
        pagination.offset(),
        allowed_congregations.as_deref(),
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

    // Enforce congregation scope
    if let Some(allowed) = middleware::get_allowed_congregations(&claims) {
        if let Some(cong_id) = member.congregation_id {
            if !allowed.contains(&cong_id) {
                return Err(AppError::Forbidden(
                    "Sem permissão para acessar membros desta congregação".into(),
                ));
            }
        }
    }

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

    // Enforce congregation scope on creation
    if let Some(allowed) = middleware::get_allowed_congregations(&claims) {
        if let Some(cong_id) = body.congregation_id {
            if !allowed.contains(&cong_id) {
                return Err(AppError::Forbidden(
                    "Sem permissão para criar membros nesta congregação".into(),
                ));
            }
        }
    }

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

    // Enforce congregation scope: verify the member belongs to an allowed congregation
    if let Some(allowed) = middleware::get_allowed_congregations(&claims) {
        let existing = MemberService::get_by_id(pool.get_ref(), church_id, member_id).await?;
        if let Some(cong_id) = existing.congregation_id {
            if !allowed.contains(&cong_id) {
                return Err(AppError::Forbidden(
                    "Sem permissão para editar membros desta congregação".into(),
                ));
            }
        }
    }

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
    params(
        ("congregation_id" = Option<uuid::Uuid>, Query, description = "Filter by congregation"),
    ),
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
    filter: web::Query<CongregationIdFilter>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    let church_id = middleware::get_church_id(&claims)?;

    let mut congregation_filter = filter.congregation_id;

    // Enforce congregation scope: if user has restricted access, use their first allowed congregation
    if let Some(allowed) = middleware::get_allowed_congregations(&claims) {
        match congregation_filter {
            Some(cid) if !allowed.contains(&cid) => {
                return Err(AppError::Forbidden(
                    "Sem permissão para ver estatísticas desta congregação".into(),
                ));
            }
            None if allowed.len() == 1 => {
                congregation_filter = Some(allowed[0]);
            }
            _ => {}
        }
    }

    // Try cache first (TTL 60s for stats)
    let cache_suffix = congregation_filter
        .map(|c| c.to_string())
        .unwrap_or_else(|| "all".to_string());
    let cache_key = format!("members:stats:{church_id}:{cache_suffix}");
    if let Some(cached) = cache.get::<serde_json::Value>(&cache_key).await {
        return Ok(HttpResponse::Ok().json(ApiResponse::ok(cached)));
    }

    let cong_condition = if congregation_filter.is_some() {
        " AND congregation_id = $2"
    } else {
        ""
    };

    let total_active = {
        let sql = format!(
            "SELECT COUNT(*) FROM members WHERE church_id = $1 AND status = 'ativo' AND deleted_at IS NULL{}",
            cong_condition
        );
        let mut q = sqlx::query_scalar::<_, i64>(&sql).bind(church_id);
        if let Some(cid) = congregation_filter { q = q.bind(cid); }
        q.fetch_one(pool.get_ref()).await?
    };

    let total_inactive = {
        let sql = format!(
            "SELECT COUNT(*) FROM members WHERE church_id = $1 AND status != 'ativo' AND deleted_at IS NULL{}",
            cong_condition
        );
        let mut q = sqlx::query_scalar::<_, i64>(&sql).bind(church_id);
        if let Some(cid) = congregation_filter { q = q.bind(cid); }
        q.fetch_one(pool.get_ref()).await?
    };

    let new_this_month = {
        let sql = format!(
            "SELECT COUNT(*) FROM members WHERE church_id = $1 AND deleted_at IS NULL \
             AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM NOW()) \
             AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW()){}",
            cong_condition
        );
        let mut q = sqlx::query_scalar::<_, i64>(&sql).bind(church_id);
        if let Some(cid) = congregation_filter { q = q.bind(cid); }
        q.fetch_one(pool.get_ref()).await?
    };

    let new_this_year = {
        let sql = format!(
            "SELECT COUNT(*) FROM members WHERE church_id = $1 AND deleted_at IS NULL \
             AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW()){}",
            cong_condition
        );
        let mut q = sqlx::query_scalar::<_, i64>(&sql).bind(church_id);
        if let Some(cid) = congregation_filter { q = q.bind(cid); }
        q.fetch_one(pool.get_ref()).await?
    };

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

/// Create a user login for an existing member
#[utoipa::path(
    post,
    path = "/api/v1/members/{id}/create-user",
    params(("id" = uuid::Uuid, Path, description = "Member ID")),
    request_body = CreateUserForMemberRequest,
    responses(
        (status = 201, description = "User created for member"),
        (status = 400, description = "Validation error"),
        (status = 404, description = "Member not found"),
        (status = 409, description = "User already exists")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/members/{id}/create-user")]
pub async fn create_user_for_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<uuid::Uuid>,
    body: web::Json<CreateUserForMemberRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:update")?;
    let church_id = middleware::get_church_id(&claims)?;
    let member_id = path.into_inner();

    let force_change = body.force_password_change.unwrap_or(true);

    let (user_id, generated_password) = AuthService::create_user_for_member(
        pool.get_ref(),
        church_id,
        member_id,
        body.password.as_deref(),
        body.role_id,
        force_change,
    )
    .await?;

    // Fetch role name & email for response
    let row = sqlx::query_as::<_, (String, String)>(
        r#"SELECT u.email, r.name
           FROM users u JOIN roles r ON u.role_id = r.id
           WHERE u.id = $1"#,
    )
    .bind(user_id)
    .fetch_one(pool.get_ref())
    .await?;

    let response = CreateUserForMemberResponse {
        user_id,
        email: row.0,
        role_name: row.1,
        generated_password,
        force_password_change: force_change,
    };

    // Audit log
    let admin_user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(),
        church_id,
        Some(admin_user_id),
        "create_user",
        "member",
        member_id,
    )
    .await
    .ok();

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        response,
        "Login criado para o membro com sucesso",
    )))
}

/// Batch create user logins for multiple members
#[utoipa::path(
    post,
    path = "/api/v1/members/batch-create-users",
    request_body = BatchCreateUsersRequest,
    responses(
        (status = 200, description = "Batch user creation results"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/members/batch-create-users")]
pub async fn batch_create_users(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<BatchCreateUsersRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "members:update")?;
    let church_id = middleware::get_church_id(&claims)?;

    if body.member_ids.is_empty() {
        return Err(AppError::validation("Lista de membros não pode ser vazia"));
    }
    if body.member_ids.len() > 100 {
        return Err(AppError::validation("Máximo de 100 membros por vez"));
    }

    let force_change = body.force_password_change.unwrap_or(true);

    let mut created: Vec<BatchCreateUserItem> = Vec::new();
    let mut skipped: Vec<BatchSkippedItem> = Vec::new();

    for &mid in &body.member_ids {
        // Fetch member info for the response
        let member_info = sqlx::query_as::<_, (String, Option<String>)>(
            "SELECT full_name, email FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(mid)
        .bind(church_id)
        .fetch_optional(pool.get_ref())
        .await?;

        let (member_name, member_email) = match member_info {
            Some(info) => info,
            None => {
                skipped.push(BatchSkippedItem {
                    member_id: mid,
                    member_name: "Não encontrado".into(),
                    reason: "Membro não encontrado".into(),
                });
                continue;
            }
        };

        let email = match member_email {
            Some(e) => e,
            None => {
                skipped.push(BatchSkippedItem {
                    member_id: mid,
                    member_name: member_name.clone(),
                    reason: "Membro sem email cadastrado".into(),
                });
                continue;
            }
        };

        match AuthService::create_user_for_member(
            pool.get_ref(),
            church_id,
            mid,
            None, // auto-generate password
            body.role_id,
            force_change,
        )
        .await
        {
            Ok((_user_id, generated_password)) => {
                created.push(BatchCreateUserItem {
                    member_id: mid,
                    member_name,
                    email,
                    password: generated_password.unwrap_or_default(),
                });
            }
            Err(e) => {
                skipped.push(BatchSkippedItem {
                    member_id: mid,
                    member_name,
                    reason: e.to_string(),
                });
            }
        }
    }

    let total_created = created.len();
    let total_skipped = skipped.len();

    let response = BatchCreateUsersResponse {
        created,
        skipped,
        total_created,
        total_skipped,
    };

    // Audit log
    let user_id = middleware::get_user_id(&claims)?;
    AuditService::log_action(
        pool.get_ref(),
        church_id,
        Some(user_id),
        "batch_create_users",
        "member",
        uuid::Uuid::nil(),
    )
    .await
    .ok();

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(
        response,
        &format!(
            "{} logins criados, {} ignorados",
            total_created, total_skipped
        ),
    )))
}
