mod api;
mod application;
mod config;
mod domain;
mod errors;
mod infrastructure;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpServer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::api::handlers::{auth_handler, family_handler, financial_handler, health_handler, member_handler, member_history_handler, ministry_handler};
use crate::application::services::AuthService;
use crate::config::AppConfig;
use crate::infrastructure::database;

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

    // Shared state
    let pool_data = web::Data::new(pool);
    let config_data = web::Data::new(config);

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
            .app_data(web::JsonConfig::default().limit(10 * 1024 * 1024)) // 10MB
            // Health
            .service(health_handler::health_check)
            // Auth
            .service(auth_handler::login)
            .service(auth_handler::refresh_token)
            .service(auth_handler::logout)
            .service(auth_handler::me)
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