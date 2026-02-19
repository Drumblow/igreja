use redis::AsyncCommands;
use serde::{de::DeserializeOwned, Serialize};
use std::sync::Arc;
use tokio::sync::OnceCell;

/// A thin wrapper around a Redis connection pool for caching.
///
/// Usage:
/// ```ignore
/// // At startup (main.rs):
/// let cache = CacheService::connect(&config.redis_url).await;
/// let cache_data = web::Data::new(cache);
///
/// // In a handler:
/// if let Some(cached) = cache.get::<Vec<MemberSummary>>("members:list:church_id:page1").await {
///     return Ok(HttpResponse::Ok().json(ApiResponse::ok(cached)));
/// }
/// // ... fetch from DB, then:
/// cache.set("members:list:church_id:page1", &data, 300).await; // 5 min TTL
/// ```
#[derive(Clone)]
pub struct CacheService {
    client: Arc<OnceCell<redis::Client>>,
    #[allow(dead_code)]
    url: String,
}

impl CacheService {
    pub async fn connect(redis_url: &str) -> Self {
        let service = Self {
            client: Arc::new(OnceCell::new()),
            url: redis_url.to_string(),
        };

        // Eagerly test connection but don't panic — cache is optional
        match redis::Client::open(redis_url) {
            Ok(client) => {
                match client.get_multiplexed_async_connection().await {
                    Ok(_conn) => {
                        let _ = service.client.set(client);
                        tracing::info!("Redis cache connected at {redis_url}");
                    }
                    Err(e) => {
                        tracing::warn!("Redis unavailable (cache disabled): {e}");
                    }
                }
            }
            Err(e) => {
                tracing::warn!("Invalid Redis URL (cache disabled): {e}");
            }
        }

        service
    }

    /// Get a cached value, deserialised from JSON.
    /// Returns `None` on cache miss or any error (fail-open).
    pub async fn get<T: DeserializeOwned>(&self, key: &str) -> Option<T> {
        let client = self.client.get()?;
        let mut conn = client.get_multiplexed_async_connection().await.ok()?;
        let raw: Option<String> = conn.get(key).await.ok()?;
        raw.and_then(|s| serde_json::from_str(&s).ok())
    }

    /// Set a cached value as JSON with a TTL in seconds.
    /// Silently fails (cache is best-effort).
    pub async fn set<T: Serialize>(&self, key: &str, value: &T, ttl_seconds: u64) {
        if let Some(client) = self.client.get() {
            if let Ok(mut conn) = client.get_multiplexed_async_connection().await {
                if let Ok(json) = serde_json::to_string(value) {
                    let _: Result<(), _> = conn.set_ex(key, json, ttl_seconds).await;
                }
            }
        }
    }

    /// Delete a cached key (e.g. after mutation).
    #[allow(dead_code)]
    pub async fn del(&self, key: &str) {
        if let Some(client) = self.client.get() {
            if let Ok(mut conn) = client.get_multiplexed_async_connection().await {
                let _: Result<(), _> = conn.del(key).await;
            }
        }
    }

    /// Delete all keys matching a pattern (e.g. "members:*").
    pub async fn del_pattern(&self, pattern: &str) {
        if let Some(client) = self.client.get() {
            if let Ok(mut conn) = client.get_multiplexed_async_connection().await {
                let keys: Vec<String> = redis::cmd("KEYS")
                    .arg(pattern)
                    .query_async(&mut conn)
                    .await
                    .unwrap_or_default();

                for key in keys {
                    let _: Result<(), _> = conn.del(&key).await;
                }
            }
        }
    }

    /// Check if the cache is connected.
    #[allow(dead_code)]
    pub fn is_connected(&self) -> bool {
        self.client.get().is_some()
    }
}
