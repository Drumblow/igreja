use crate::errors::AppError;
use serde::Serialize;
use sqlx::PgPool;
use uuid::Uuid;

/// Lightweight service for writing audit log entries.
/// The `audit_logs` table already exists in the database.
///
/// Usage from any handler:
/// ```ignore
/// AuditService::log(
///     &pool,
///     church_id,
///     Some(user_id),
///     "create",
///     "member",
///     entity_id,
///     None,
///     Some(&new_member),
///     req.peer_addr().map(|a| a.to_string()),
///     req.headers().get("user-agent").and_then(|v| v.to_str().ok()).map(String::from),
/// ).await?;
/// ```
pub struct AuditService;

impl AuditService {
    /// Write a single audit log entry.
    ///
    /// - `action`: "create", "update", "delete", "login", "logout", "reset_password", etc.
    /// - `entity_type`: "member", "family", "financial_entry", "asset", "ebd_class", etc.
    /// - `old_values` / `new_values`: serialisable structs (pass `None` when not applicable).
    pub async fn log<O: Serialize, N: Serialize>(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Option<Uuid>,
        action: &str,
        entity_type: &str,
        entity_id: Uuid,
        old_values: Option<&O>,
        new_values: Option<&N>,
        ip_address: Option<String>,
        user_agent: Option<String>,
    ) -> Result<(), AppError> {
        let old_json = old_values
            .map(|v| serde_json::to_value(v).ok())
            .flatten();
        let new_json = new_values
            .map(|v| serde_json::to_value(v).ok())
            .flatten();

        // ip_address needs to be cast to INET in PostgreSQL
        sqlx::query(
            r#"
            INSERT INTO audit_logs
                (church_id, user_id, action, entity_type, entity_id,
                 old_values, new_values, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8::inet, $9)
            "#,
        )
        .bind(church_id)
        .bind(user_id)
        .bind(action)
        .bind(entity_type)
        .bind(entity_id)
        .bind(old_json)
        .bind(new_json)
        .bind(ip_address)
        .bind(user_agent)
        .execute(pool)
        .await?;

        Ok(())
    }

    /// Convenience: log without old/new values (e.g. login, logout, delete).
    pub async fn log_action(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Option<Uuid>,
        action: &str,
        entity_type: &str,
        entity_id: Uuid,
    ) -> Result<(), AppError> {
        Self::log::<serde_json::Value, serde_json::Value>(
            pool,
            church_id,
            user_id,
            action,
            entity_type,
            entity_id,
            None,
            None,
            None,
            None,
        )
        .await
    }
}
