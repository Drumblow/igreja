use actix_web::{delete, get, post, put, web, HttpRequest, HttpResponse};
use chrono::NaiveDate;
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;

use crate::api::middleware;
use crate::api::response::{ApiResponse, PaginationParams};
use crate::application::dto::{
    CreateEbdAttendanceRequest, CreateEbdClassRequest, CreateEbdEnrollmentRequest,
    CreateEbdLessonRequest, CreateEbdTermRequest, EbdClassFilter, EbdLessonFilter,
    UpdateEbdClassRequest, UpdateEbdTermRequest,
};
use crate::application::services::{
    EbdAttendanceService, EbdClassService, EbdLessonService, EbdTermService,
};
use crate::config::AppConfig;
use crate::errors::AppError;
use crate::infrastructure::cache::CacheService;

// ==========================================
// EBD Terms (Períodos/Trimestres)
// ==========================================

/// List EBD terms
#[utoipa::path(
    get,
    path = "/api/v1/ebd/terms",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
    ),
    responses(
        (status = 200, description = "List of EBD terms"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/terms")]
pub async fn list_ebd_terms(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    pagination: web::Query<PaginationParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let is_active: Option<bool> = None;

    let (terms, total) = EbdTermService::list(
        pool.get_ref(),
        church_id,
        &is_active,
        pagination.per_page(),
        pagination.offset(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(
        terms,
        pagination.page(),
        pagination.per_page(),
        total,
    )))
}

/// Get EBD term by ID
#[utoipa::path(
    get,
    path = "/api/v1/ebd/terms/{term_id}",
    params(
        ("term_id" = Uuid, Path, description = "Term ID"),
    ),
    responses(
        (status = 200, description = "EBD term details"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/terms/{term_id}")]
pub async fn get_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    let term = EbdTermService::get_by_id(pool.get_ref(), church_id, term_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(term)))
}

/// Create a new EBD term
#[utoipa::path(
    post,
    path = "/api/v1/ebd/terms",
    request_body = CreateEbdTermRequest,
    responses(
        (status = 201, description = "Term created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/terms")]
pub async fn create_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateEbdTermRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let term = EbdTermService::create(pool.get_ref(), church_id, &body).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(term, "Período EBD criado com sucesso")))
}

/// Update an EBD term
#[utoipa::path(
    put,
    path = "/api/v1/ebd/terms/{term_id}",
    params(
        ("term_id" = Uuid, Path, description = "Term ID"),
    ),
    request_body = UpdateEbdTermRequest,
    responses(
        (status = 200, description = "Term updated"),
        (status = 404, description = "Term not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/terms/{term_id}")]
pub async fn update_ebd_term(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<UpdateEbdTermRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let term_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let term = EbdTermService::update(pool.get_ref(), church_id, term_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(term, "Período EBD atualizado")))
}

// ==========================================
// EBD Classes (Turmas)
// ==========================================

#[derive(Deserialize)]
pub struct EbdClassQueryParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub search: Option<String>,
    pub term_id: Option<Uuid>,
    pub is_active: Option<bool>,
    pub teacher_id: Option<Uuid>,
}

/// List EBD classes
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("search" = Option<String>, Query, description = "Search by name"),
        ("term_id" = Option<Uuid>, Query, description = "Filter by term"),
        ("is_active" = Option<bool>, Query, description = "Filter by active status"),
        ("teacher_id" = Option<Uuid>, Query, description = "Filter by teacher"),
    ),
    responses(
        (status = 200, description = "List of EBD classes"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes")]
pub async fn list_ebd_classes(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    query: web::Query<EbdClassQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let filter = EbdClassFilter {
        term_id: query.term_id,
        is_active: query.is_active,
        teacher_id: query.teacher_id,
    };

    let (classes, total) = EbdClassService::list(
        pool.get_ref(),
        church_id,
        &filter,
        &query.search,
        per_page,
        offset,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(classes, page, per_page, total)))
}

/// Get EBD class by ID
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes/{class_id}",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    responses(
        (status = 200, description = "EBD class details"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes/{class_id}")]
pub async fn get_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    let class = EbdClassService::get_by_id(pool.get_ref(), church_id, class_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(class)))
}

/// Create a new EBD class
#[utoipa::path(
    post,
    path = "/api/v1/ebd/classes",
    request_body = CreateEbdClassRequest,
    responses(
        (status = 201, description = "Class created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/classes")]
pub async fn create_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    body: web::Json<CreateEbdClassRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let class = EbdClassService::create(pool.get_ref(), church_id, &body).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(class, "Turma EBD criada com sucesso")))
}

/// Update an EBD class
#[utoipa::path(
    put,
    path = "/api/v1/ebd/classes/{class_id}",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    request_body = UpdateEbdClassRequest,
    responses(
        (status = 200, description = "Class updated"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[put("/api/v1/ebd/classes/{class_id}")]
pub async fn update_ebd_class(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    body: web::Json<UpdateEbdClassRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let class = EbdClassService::update(pool.get_ref(), church_id, class_id, &body).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message(class, "Turma EBD atualizada")))
}

// ==========================================
// EBD Enrollments (Matrículas)
// ==========================================

/// List enrollments for a class
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes/{class_id}/enrollments",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    responses(
        (status = 200, description = "List of enrollments"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes/{class_id}/enrollments")]
pub async fn list_class_enrollments(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let class_id = path.into_inner();

    let enrollments = EbdClassService::list_enrollments(pool.get_ref(), class_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(enrollments)))
}

/// Enroll a member in a class
#[utoipa::path(
    post,
    path = "/api/v1/ebd/classes/{class_id}/enrollments",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
    ),
    request_body = CreateEbdEnrollmentRequest,
    responses(
        (status = 201, description = "Member enrolled"),
        (status = 409, description = "Member already enrolled")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/classes/{class_id}/enrollments")]
pub async fn enroll_member(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    body: web::Json<CreateEbdEnrollmentRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let enrollment = EbdClassService::enroll_member(pool.get_ref(), class_id, &body).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(enrollment, "Membro matriculado com sucesso")))
}

/// Remove enrollment
#[utoipa::path(
    delete,
    path = "/api/v1/ebd/classes/{class_id}/enrollments/{enrollment_id}",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
        ("enrollment_id" = Uuid, Path, description = "Enrollment ID"),
    ),
    responses(
        (status = 200, description = "Enrollment removed"),
        (status = 404, description = "Enrollment not found")
    ),
    security(("bearer_auth" = []))
)]
#[delete("/api/v1/ebd/classes/{class_id}/enrollments/{enrollment_id}")]
pub async fn remove_enrollment(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<(Uuid, Uuid)>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let (class_id, enrollment_id) = path.into_inner();

    EbdClassService::remove_enrollment(pool.get_ref(), class_id, enrollment_id).await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    Ok(HttpResponse::Ok().json(ApiResponse::with_message((), "Matrícula removida")))
}

// ==========================================
// EBD Lessons (Aulas)
// ==========================================

#[derive(Deserialize)]
pub struct EbdLessonQueryParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub class_id: Option<Uuid>,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}

/// List EBD lessons
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
        ("class_id" = Option<Uuid>, Query, description = "Filter by class"),
        ("date_from" = Option<NaiveDate>, Query, description = "Start date filter"),
        ("date_to" = Option<NaiveDate>, Query, description = "End date filter"),
    ),
    responses(
        (status = 200, description = "List of EBD lessons"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons")]
pub async fn list_ebd_lessons(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    query: web::Query<EbdLessonQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    let page = query.page.unwrap_or(1);
    let per_page = query.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let filter = EbdLessonFilter {
        class_id: query.class_id,
        date_from: query.date_from,
        date_to: query.date_to,
    };

    let (lessons, total) = EbdLessonService::list(
        pool.get_ref(),
        church_id,
        &filter,
        per_page,
        offset,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::paginated(lessons, page, per_page, total)))
}

/// Get EBD lesson by ID
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
    ),
    responses(
        (status = 200, description = "EBD lesson details"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}")]
pub async fn get_ebd_lesson(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let lesson_id = path.into_inner();

    let lesson = EbdLessonService::get_by_id(pool.get_ref(), church_id, lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(lesson)))
}

/// Create a new EBD lesson
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons",
    request_body = CreateEbdLessonRequest,
    responses(
        (status = 201, description = "Lesson created"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons")]
pub async fn create_ebd_lesson(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    body: web::Json<CreateEbdLessonRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let lesson = EbdLessonService::create(pool.get_ref(), church_id, &body).await?;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(lesson, "Aula EBD criada com sucesso")))
}

// ==========================================
// EBD Attendance (Frequência)
// ==========================================

/// Record attendance for a lesson (batch)
#[utoipa::path(
    post,
    path = "/api/v1/ebd/lessons/{lesson_id}/attendance",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
    ),
    request_body = CreateEbdAttendanceRequest,
    responses(
        (status = 201, description = "Attendance recorded"),
        (status = 400, description = "Validation error")
    ),
    security(("bearer_auth" = []))
)]
#[post("/api/v1/ebd/lessons/{lesson_id}/attendance")]
pub async fn record_attendance(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
    path: web::Path<Uuid>,
    body: web::Json<CreateEbdAttendanceRequest>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:write")?;
    let church_id = middleware::get_church_id(&claims)?;
    let user_id = middleware::get_user_id(&claims)?;
    let lesson_id = path.into_inner();

    body.validate().map_err(|e| AppError::validation(&e.to_string()))?;

    let attendances = EbdAttendanceService::record_attendance(
        pool.get_ref(),
        lesson_id,
        user_id,
        &body,
    )
    .await?;

    // Invalidate EBD cache
    cache.del_pattern(&format!("ebd:*:{church_id}")).await;

    Ok(HttpResponse::Created().json(ApiResponse::with_message(
        attendances,
        "Frequência registrada com sucesso",
    )))
}

/// Get attendance records for a lesson
#[utoipa::path(
    get,
    path = "/api/v1/ebd/lessons/{lesson_id}/attendance",
    params(
        ("lesson_id" = Uuid, Path, description = "Lesson ID"),
    ),
    responses(
        (status = 200, description = "Attendance records"),
        (status = 404, description = "Lesson not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/lessons/{lesson_id}/attendance")]
pub async fn get_lesson_attendance(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let lesson_id = path.into_inner();

    let attendances = EbdAttendanceService::get_by_lesson(pool.get_ref(), lesson_id).await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(attendances)))
}

/// Get attendance report for a class
#[utoipa::path(
    get,
    path = "/api/v1/ebd/classes/{class_id}/report",
    params(
        ("class_id" = Uuid, Path, description = "Class ID"),
        ("date_from" = Option<NaiveDate>, Query, description = "Start date"),
        ("date_to" = Option<NaiveDate>, Query, description = "End date"),
    ),
    responses(
        (status = 200, description = "Class attendance report"),
        (status = 404, description = "Class not found")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/classes/{class_id}/report")]
pub async fn get_class_report(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    path: web::Path<Uuid>,
    query: web::Query<ReportQueryParams>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;
    let class_id = path.into_inner();

    let report = EbdAttendanceService::report(
        pool.get_ref(),
        church_id,
        class_id,
        &query.date_from,
        &query.date_to,
    )
    .await?;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(report)))
}

#[derive(Deserialize)]
pub struct ReportQueryParams {
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}

// ==========================================
// EBD Stats
// ==========================================

/// Get EBD statistics for the dashboard
#[utoipa::path(
    get,
    path = "/api/v1/ebd/stats",
    responses(
        (status = 200, description = "EBD statistics"),
        (status = 401, description = "Not authenticated")
    ),
    security(("bearer_auth" = []))
)]
#[get("/api/v1/ebd/stats")]
pub async fn ebd_stats(
    req: HttpRequest,
    pool: web::Data<PgPool>,
    config: web::Data<AppConfig>,
    cache: web::Data<CacheService>,
) -> Result<HttpResponse, AppError> {
    let claims = middleware::auth_middleware(req, config).await?;
    middleware::require_permission(&claims, "ebd:read")?;
    let church_id = middleware::get_church_id(&claims)?;

    // Try cache first
    let cache_key = format!("ebd:stats:{church_id}");
    if let Some(cached) = cache.get::<serde_json::Value>(&cache_key).await {
        return Ok(HttpResponse::Ok().json(ApiResponse::ok(cached)));
    }

    let total_classes = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ebd_classes WHERE church_id = $1 AND is_active = TRUE"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let total_enrolled = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ebd_enrollments en \
         JOIN ebd_classes c ON c.id = en.class_id \
         WHERE c.church_id = $1 AND c.is_active = TRUE AND en.is_active = TRUE"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let active_terms = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM ebd_terms WHERE church_id = $1 AND is_active = TRUE"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    // Average attendance rate for the current month
    let avg_attendance: Option<f64> = sqlx::query_scalar(
        "SELECT AVG(CASE WHEN ea.status = 'presente' THEN 1.0 ELSE 0.0 END) \
         FROM ebd_attendances ea \
         JOIN ebd_lessons el ON el.id = ea.lesson_id \
         JOIN ebd_classes ec ON ec.id = el.class_id \
         WHERE ec.church_id = $1 \
         AND EXTRACT(MONTH FROM el.lesson_date) = EXTRACT(MONTH FROM NOW()) \
         AND EXTRACT(YEAR FROM el.lesson_date) = EXTRACT(YEAR FROM NOW())"
    )
    .bind(church_id)
    .fetch_one(pool.get_ref())
    .await?;

    let stats = serde_json::json!({
        "total_classes": total_classes,
        "total_enrolled": total_enrolled,
        "active_terms": active_terms,
        "avg_attendance_rate": avg_attendance.unwrap_or(0.0)
    });

    // Cache for 120 seconds
    cache.set(&cache_key, &stats, 120).await;

    Ok(HttpResponse::Ok().json(ApiResponse::ok(stats)))
}
