mod api;
mod application;
mod config;
mod domain;
mod errors;
mod infrastructure;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpServer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use crate::api::handlers::{asset_handler, auth_handler, church_handler, ebd_handler, family_handler, financial_handler, health_handler, member_handler, member_history_handler, ministry_handler, user_handler};
use crate::application::services::AuthService;
use crate::config::AppConfig;
use crate::infrastructure::database;
use crate::infrastructure::cache::CacheService;

#[derive(OpenApi)]
#[openapi(
    info(title = "Igreja Manager API", version = "1.0.0", description = "API de gestão para igrejas"),
    paths(
        // Health
        health_handler::health_check,
        // Auth
        auth_handler::login,
        auth_handler::refresh_token,
        auth_handler::logout,
        auth_handler::me,
        auth_handler::forgot_password,
        auth_handler::reset_password,
        // Churches
        church_handler::list_churches,
        church_handler::get_church,
        church_handler::get_my_church,
        church_handler::create_church,
        church_handler::update_church,
        // Users
        user_handler::list_users,
        user_handler::get_user,
        user_handler::create_user,
        user_handler::update_user,
        user_handler::list_roles,
        // Members
        member_handler::list_members,
        member_handler::get_member,
        member_handler::create_member,
        member_handler::update_member,
        member_handler::delete_member,
        member_handler::member_stats,
        // Member History
        member_history_handler::get_member_history,
        member_history_handler::create_member_history,
        // Families
        family_handler::list_families,
        family_handler::get_family,
        family_handler::create_family,
        family_handler::update_family,
        family_handler::delete_family,
        family_handler::add_family_member,
        family_handler::remove_family_member,
        // Ministries
        ministry_handler::list_ministries,
        ministry_handler::get_ministry,
        ministry_handler::create_ministry,
        ministry_handler::update_ministry,
        ministry_handler::delete_ministry,
        ministry_handler::list_ministry_members,
        ministry_handler::add_ministry_member,
        ministry_handler::remove_ministry_member,
        // Financial
        financial_handler::list_account_plans,
        financial_handler::create_account_plan,
        financial_handler::update_account_plan,
        financial_handler::list_bank_accounts,
        financial_handler::create_bank_account,
        financial_handler::update_bank_account,
        financial_handler::list_campaigns,
        financial_handler::get_campaign,
        financial_handler::create_campaign,
        financial_handler::update_campaign,
        financial_handler::list_financial_entries,
        financial_handler::get_financial_entry,
        financial_handler::create_financial_entry,
        financial_handler::update_financial_entry,
        financial_handler::delete_financial_entry,
        financial_handler::balance_report,
        financial_handler::list_monthly_closings,
        financial_handler::create_monthly_closing,
        // Assets
        asset_handler::list_asset_categories,
        asset_handler::create_asset_category,
        asset_handler::update_asset_category,
        asset_handler::list_assets,
        asset_handler::get_asset,
        asset_handler::create_asset,
        asset_handler::update_asset,
        asset_handler::delete_asset,
        asset_handler::list_maintenances,
        asset_handler::create_maintenance,
        asset_handler::update_maintenance,
        asset_handler::list_inventories,
        asset_handler::get_inventory,
        asset_handler::create_inventory,
        asset_handler::update_inventory_item,
        asset_handler::close_inventory,
        asset_handler::list_asset_loans,
        asset_handler::create_asset_loan,
        asset_handler::return_asset_loan,
        asset_handler::asset_stats,
        // EBD
        ebd_handler::list_ebd_terms,
        ebd_handler::get_ebd_term,
        ebd_handler::create_ebd_term,
        ebd_handler::update_ebd_term,
        ebd_handler::delete_ebd_term,
        ebd_handler::list_ebd_classes,
        ebd_handler::get_ebd_class,
        ebd_handler::create_ebd_class,
        ebd_handler::update_ebd_class,
        ebd_handler::delete_ebd_class,
        ebd_handler::list_class_enrollments,
        ebd_handler::enroll_member,
        ebd_handler::remove_enrollment,
        ebd_handler::list_ebd_lessons,
        ebd_handler::get_ebd_lesson,
        ebd_handler::create_ebd_lesson,
        ebd_handler::update_ebd_lesson,
        ebd_handler::delete_ebd_lesson,
        ebd_handler::record_attendance,
        ebd_handler::get_lesson_attendance,
        ebd_handler::get_class_report,
        ebd_handler::ebd_stats,
        // EBD — Lesson Contents
        ebd_handler::list_lesson_contents,
        ebd_handler::create_lesson_content,
        ebd_handler::update_lesson_content,
        ebd_handler::delete_lesson_content,
        ebd_handler::reorder_lesson_contents,
        // EBD — Lesson Activities
        ebd_handler::list_lesson_activities,
        ebd_handler::create_lesson_activity,
        ebd_handler::update_lesson_activity,
        ebd_handler::delete_lesson_activity,
        // EBD — Activity Responses
        ebd_handler::list_activity_responses,
        ebd_handler::record_activity_responses,
        ebd_handler::update_activity_response,
        // EBD — Lesson Materials
        ebd_handler::list_lesson_materials,
        ebd_handler::create_lesson_material,
        ebd_handler::delete_lesson_material,
        // EBD — Students
        ebd_handler::list_ebd_students,
        ebd_handler::get_student_profile,
        ebd_handler::get_student_history,
        ebd_handler::get_student_activities,
        // EBD — Student Notes
        ebd_handler::list_student_notes,
        ebd_handler::create_student_note,
        ebd_handler::update_student_note,
        ebd_handler::delete_student_note,
        // EBD — Clone Classes
        ebd_handler::clone_classes,
        // EBD — Advanced Reports (E6)
        ebd_handler::get_term_report,
        ebd_handler::get_term_ranking,
        ebd_handler::get_term_comparison,
        ebd_handler::get_absent_students,
    ),
    components(schemas(
        crate::api::response::ApiResponse<serde_json::Value>,
        crate::api::response::PaginationMeta,
    )),
    tags(
        (name = "Health", description = "Health check"),
        (name = "Auth", description = "Autenticação"),
        (name = "Churches", description = "Gestão de igrejas"),
        (name = "Users", description = "Gestão de usuários"),
        (name = "Members", description = "Gestão de membros"),
        (name = "Families", description = "Gestão de famílias"),
        (name = "Ministries", description = "Gestão de ministérios"),
        (name = "Financial", description = "Módulo financeiro"),
        (name = "Assets", description = "Gestão de patrimônio"),
        (name = "EBD", description = "Escola Bíblica Dominical"),
    ),
    modifiers(&SecurityAddon),
)]
struct ApiDoc;

struct SecurityAddon;

impl utoipa::Modify for SecurityAddon {
    fn modify(&self, openapi: &mut utoipa::openapi::OpenApi) {
        if let Some(components) = openapi.components.as_mut() {
            components.add_security_scheme(
                "bearer_auth",
                utoipa::openapi::security::SecurityScheme::Http(
                    utoipa::openapi::security::Http::new(
                        utoipa::openapi::security::HttpAuthScheme::Bearer,
                    ),
                ),
            );
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env
    dotenvy::dotenv().ok();

    // Init tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            "igreja_manager_api=debug,actix_web=info,sqlx=warn".into()
        }))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load config
    let config = AppConfig::from_env();
    let server_addr = config.server_addr();

    tracing::info!("Starting Igreja Manager API on {server_addr}");

    // Create DB pool
    let pool = database::create_pool(&config.database_url).await;

    // Run migrations
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run database migrations");

    tracing::info!("Database migrations applied successfully");

    // Seed test data if no users exist
    seed_test_data(&pool).await;

    // Connect to Redis cache (optional — fails gracefully)
    let cache = CacheService::connect(&config.redis_url).await;

    // Shared state
    let pool_data = web::Data::new(pool);
    let config_data = web::Data::new(config);
    let cache_data = web::Data::new(cache);

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(cors)
            .wrap(Logger::default())
            .app_data(pool_data.clone())
            .app_data(config_data.clone())
            .app_data(cache_data.clone())
            .app_data(web::JsonConfig::default().limit(10 * 1024 * 1024)) // 10MB
            // Health
            .service(health_handler::health_check)
            // Churches
            .service(church_handler::get_my_church) // before {id} route
            .service(church_handler::list_churches)
            .service(church_handler::get_church)
            .service(church_handler::create_church)
            .service(church_handler::update_church)
            // Users
            .service(user_handler::list_users)
            .service(user_handler::get_user)
            .service(user_handler::create_user)
            .service(user_handler::update_user)
            // Roles
            .service(user_handler::list_roles)
            // Auth
            .service(auth_handler::login)
            .service(auth_handler::refresh_token)
            .service(auth_handler::logout)
            .service(auth_handler::me)
            .service(auth_handler::forgot_password)
            .service(auth_handler::reset_password)
            // Members
            .service(member_handler::member_stats) // before {id} route
            .service(member_handler::list_members)
            .service(member_handler::get_member)
            .service(member_handler::create_member)
            .service(member_handler::update_member)
            .service(member_handler::delete_member)            // Member History
            .service(member_history_handler::get_member_history)
            .service(member_history_handler::create_member_history)
            // Families
            .service(family_handler::list_families)
            .service(family_handler::get_family)
            .service(family_handler::create_family)
            .service(family_handler::update_family)
            .service(family_handler::delete_family)
            .service(family_handler::add_family_member)
            .service(family_handler::remove_family_member)
            // Ministries
            .service(ministry_handler::list_ministries)
            .service(ministry_handler::get_ministry)
            .service(ministry_handler::create_ministry)
            .service(ministry_handler::update_ministry)
            .service(ministry_handler::delete_ministry)
            .service(ministry_handler::list_ministry_members)
            .service(ministry_handler::add_ministry_member)
            .service(ministry_handler::remove_ministry_member)
            // Financial — Account Plans
            .service(financial_handler::list_account_plans)
            .service(financial_handler::create_account_plan)
            .service(financial_handler::update_account_plan)
            // Financial — Bank Accounts
            .service(financial_handler::list_bank_accounts)
            .service(financial_handler::create_bank_account)
            .service(financial_handler::update_bank_account)
            // Financial — Campaigns
            .service(financial_handler::list_campaigns)
            .service(financial_handler::get_campaign)
            .service(financial_handler::create_campaign)
            .service(financial_handler::update_campaign)
            // Financial — Entries
            .service(financial_handler::list_financial_entries)
            .service(financial_handler::get_financial_entry)
            .service(financial_handler::create_financial_entry)
            .service(financial_handler::update_financial_entry)
            .service(financial_handler::delete_financial_entry)
            // Financial — Reports
            .service(financial_handler::balance_report)
            // Financial — Monthly Closings
            .service(financial_handler::list_monthly_closings)
            .service(financial_handler::create_monthly_closing)
            // Assets — Categories
            .service(asset_handler::list_asset_categories)
            .service(asset_handler::create_asset_category)
            .service(asset_handler::update_asset_category)
            // Assets — CRUD
            .service(asset_handler::list_assets)
            .service(asset_handler::get_asset)
            .service(asset_handler::create_asset)
            .service(asset_handler::update_asset)
            .service(asset_handler::delete_asset)
            // Assets — Maintenances
            .service(asset_handler::list_maintenances)
            .service(asset_handler::create_maintenance)
            .service(asset_handler::update_maintenance)
            // Assets — Inventories
            .service(asset_handler::list_inventories)
            .service(asset_handler::get_inventory)
            .service(asset_handler::create_inventory)
            .service(asset_handler::update_inventory_item)
            .service(asset_handler::close_inventory)
            // Assets — Stats
            .service(asset_handler::asset_stats)
            // Assets — Loans
            .service(asset_handler::list_asset_loans)
            .service(asset_handler::create_asset_loan)
            .service(asset_handler::return_asset_loan)
            // EBD — Stats
            .service(ebd_handler::ebd_stats)
            // EBD — Terms
            .service(ebd_handler::list_ebd_terms)
            .service(ebd_handler::get_ebd_term)
            .service(ebd_handler::create_ebd_term)
            .service(ebd_handler::update_ebd_term)
            .service(ebd_handler::delete_ebd_term)
            // EBD — Classes
            .service(ebd_handler::list_ebd_classes)
            .service(ebd_handler::get_ebd_class)
            .service(ebd_handler::create_ebd_class)
            .service(ebd_handler::update_ebd_class)
            .service(ebd_handler::delete_ebd_class)
            // EBD — Enrollments
            .service(ebd_handler::list_class_enrollments)
            .service(ebd_handler::enroll_member)
            .service(ebd_handler::remove_enrollment)
            // EBD — Lessons
            .service(ebd_handler::list_ebd_lessons)
            .service(ebd_handler::get_ebd_lesson)
            .service(ebd_handler::create_ebd_lesson)
            .service(ebd_handler::update_ebd_lesson)
            .service(ebd_handler::delete_ebd_lesson)
            // EBD — Attendance
            .service(ebd_handler::record_attendance)
            .service(ebd_handler::get_lesson_attendance)
            .service(ebd_handler::get_class_report)
            // EBD — Lesson Contents (E1)
            .service(ebd_handler::list_lesson_contents)
            .service(ebd_handler::create_lesson_content)
            .service(ebd_handler::update_lesson_content)
            .service(ebd_handler::delete_lesson_content)
            .service(ebd_handler::reorder_lesson_contents)
            // EBD — Lesson Activities (E2)
            .service(ebd_handler::list_lesson_activities)
            .service(ebd_handler::create_lesson_activity)
            .service(ebd_handler::update_lesson_activity)
            .service(ebd_handler::delete_lesson_activity)
            // EBD — Activity Responses (E2)
            .service(ebd_handler::list_activity_responses)
            .service(ebd_handler::record_activity_responses)
            .service(ebd_handler::update_activity_response)
            // EBD — Lesson Materials (E4)
            .service(ebd_handler::list_lesson_materials)
            .service(ebd_handler::create_lesson_material)
            .service(ebd_handler::delete_lesson_material)
            // EBD — Students (E3)
            .service(ebd_handler::list_ebd_students)
            .service(ebd_handler::get_student_profile)
            .service(ebd_handler::get_student_history)
            .service(ebd_handler::get_student_activities)
            // EBD — Student Notes (E5)
            .service(ebd_handler::list_student_notes)
            .service(ebd_handler::create_student_note)
            .service(ebd_handler::update_student_note)
            .service(ebd_handler::delete_student_note)
            // EBD — Clone Classes (E7)
            .service(ebd_handler::clone_classes)
            // EBD — Advanced Reports (E6)
            .service(ebd_handler::get_term_report)
            .service(ebd_handler::get_term_ranking)
            .service(ebd_handler::get_term_comparison)
            .service(ebd_handler::get_absent_students)
            // Swagger UI
            .service(
                SwaggerUi::new("/swagger-ui/{_:.*}")
                    .url("/api-docs/openapi.json", ApiDoc::openapi()),
            )
    })    .bind(&server_addr)?
    .run()
    .await
}

/// Seeds initial test data (church + admin user) if no users exist.
/// Credentials: admin@igreja.com / admin123
async fn seed_test_data(pool: &sqlx::PgPool) {
    let user_count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM users")
        .fetch_one(pool)
        .await
        .unwrap_or((0,));

    if user_count.0 > 0 {
        tracing::info!("Users already exist, skipping seed");
        return;
    }

    tracing::info!("No users found — seeding test data...");

    // 1. Create test church
    let church_id: (uuid::Uuid,) = sqlx::query_as(
        r#"INSERT INTO churches (name, denomination, pastor_name, city, state, email, is_active)
           VALUES ('Igreja Exemplo', 'Assembleia de Deus', 'Pr. João Silva', 'São Paulo', 'SP', 'contato@igrejaexemplo.com', TRUE)
           RETURNING id"#,
    )
    .fetch_one(pool)
    .await
    .expect("Failed to seed test church");

    tracing::info!("Test church created: {}", church_id.0);

    // 2. Get admin role (super_admin)
    let role_id: (uuid::Uuid,) = sqlx::query_as(
        "SELECT id FROM roles WHERE name = 'super_admin' LIMIT 1",
    )
    .fetch_one(pool)
    .await
    .expect("Role super_admin not found — run migrations first");

    // 3. Create admin user with password "admin123"
    let password_hash = AuthService::hash_password("admin123")
        .expect("Failed to hash seed password");

    sqlx::query(
        r#"INSERT INTO users (church_id, email, password_hash, role_id, is_active, email_verified)
           VALUES ($1, 'admin@igreja.com', $2, $3, TRUE, TRUE)"#,
    )
    .bind(church_id.0)
    .bind(&password_hash)
    .bind(role_id.0)
    .execute(pool)
    .await
    .expect("Failed to seed test user");

    // 4. Also create a secretary user for testing different roles
    let sec_role_id: (uuid::Uuid,) = sqlx::query_as(
        "SELECT id FROM roles WHERE name = 'secretary' LIMIT 1",
    )
    .fetch_one(pool)
    .await
    .expect("Role secretary not found");

    let sec_hash = AuthService::hash_password("secret123")
        .expect("Failed to hash seed password");

    sqlx::query(
        r#"INSERT INTO users (church_id, email, password_hash, role_id, is_active, email_verified)
           VALUES ($1, 'secretaria@igreja.com', $2, $3, TRUE, TRUE)"#,
    )
    .bind(church_id.0)
    .bind(&sec_hash)
    .bind(sec_role_id.0)
    .execute(pool)
    .await
    .expect("Failed to seed secretary user");

    // 5. Create a treasurer user
    let tres_role_id: (uuid::Uuid,) = sqlx::query_as(
        "SELECT id FROM roles WHERE name = 'treasurer' LIMIT 1",
    )
    .fetch_one(pool)
    .await
    .expect("Role treasurer not found");

    let tres_hash = AuthService::hash_password("tesour123")
        .expect("Failed to hash seed password");

    sqlx::query(
        r#"INSERT INTO users (church_id, email, password_hash, role_id, is_active, email_verified)
           VALUES ($1, 'tesoureiro@igreja.com', $2, $3, TRUE, TRUE)"#,
    )
    .bind(church_id.0)
    .bind(&tres_hash)
    .bind(tres_role_id.0)
    .execute(pool)
    .await
    .expect("Failed to seed treasurer user");

    tracing::info!("✅ Test data seeded successfully!");
    tracing::info!("   Admin:      admin@igreja.com / admin123");
    tracing::info!("   Secretária: secretaria@igreja.com / secret123");
    tracing::info!("   Tesoureiro: tesoureiro@igreja.com / tesour123");
}