mod api;
mod application;
mod config;
mod domain;
mod errors;
mod infrastructure;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpServer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::api::handlers::{auth_handler, health_handler, member_handler};
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
            .service(member_handler::delete_member)
    })
    .bind(&server_addr)?
    .run()
    .await
}
