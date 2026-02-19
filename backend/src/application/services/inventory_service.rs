use crate::application::dto::{CreateInventoryRequest, UpdateInventoryItemRequest};
use crate::domain::entities::{Inventory, InventoryItem, InventoryItemDetail, InventorySummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct InventoryService;

impl InventoryService {
    /// List inventories with pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<InventorySummary>, i64), AppError> {
        let total = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM inventories WHERE church_id = $1",
        )
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        let inventories = sqlx::query_as::<_, InventorySummary>(
            r#"
            SELECT id, name, reference_date, status, total_items, found_items,
                   missing_items, divergent_items, created_at
            FROM inventories
            WHERE church_id = $1
            ORDER BY reference_date DESC
            LIMIT $2 OFFSET $3
            "#,
        )
        .bind(church_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await?;

        Ok((inventories, total))
    }

    /// Get inventory by ID with items
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        inventory_id: Uuid,
    ) -> Result<Inventory, AppError> {
        sqlx::query_as::<_, Inventory>(
            "SELECT * FROM inventories WHERE id = $1 AND church_id = $2",
        )
        .bind(inventory_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Inventário"))
    }

    /// Get inventory items with asset details
    pub async fn get_items(
        pool: &PgPool,
        inventory_id: Uuid,
    ) -> Result<Vec<InventoryItemDetail>, AppError> {
        let items = sqlx::query_as::<_, InventoryItemDetail>(
            r#"
            SELECT ii.id, ii.inventory_id, ii.asset_id,
                   a.asset_code, a.description AS asset_description,
                   a.location AS asset_location, a.condition AS registered_condition,
                   ii.status, ii.observed_condition, ii.notes, ii.checked_at
            FROM inventory_items ii
            LEFT JOIN assets a ON a.id = ii.asset_id
            WHERE ii.inventory_id = $1
            ORDER BY a.asset_code ASC
            "#,
        )
        .bind(inventory_id)
        .fetch_all(pool)
        .await?;

        Ok(items)
    }

    /// Create a new inventory (auto-populates items from active assets)
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Uuid,
        req: &CreateInventoryRequest,
    ) -> Result<Inventory, AppError> {
        // Create the inventory
        let inventory = sqlx::query_as::<_, Inventory>(
            r#"
            INSERT INTO inventories (church_id, name, reference_date, notes, conducted_by, status, started_at)
            VALUES ($1, $2, $3, $4, $5, 'em_andamento', NOW())
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(req.reference_date)
        .bind(&req.notes)
        .bind(user_id)
        .fetch_one(pool)
        .await?;

        // Populate inventory items from all active assets
        let affected = sqlx::query(
            r#"
            INSERT INTO inventory_items (inventory_id, asset_id, status)
            SELECT $1, id, 'pendente'
            FROM assets
            WHERE church_id = $2 AND deleted_at IS NULL AND status IN ('ativo', 'em_manutencao', 'cedido')
            "#,
        )
        .bind(inventory.id)
        .bind(church_id)
        .execute(pool)
        .await?
        .rows_affected();

        // Update total_items count
        sqlx::query("UPDATE inventories SET total_items = $1 WHERE id = $2")
            .bind(affected as i32)
            .bind(inventory.id)
            .execute(pool)
            .await?;

        // Re-fetch with updated count
        Self::get_by_id(pool, church_id, inventory.id).await
    }

    /// Update a single inventory item (conferência)
    pub async fn update_item(
        pool: &PgPool,
        church_id: Uuid,
        inventory_id: Uuid,
        item_id: Uuid,
        user_id: Uuid,
        req: &UpdateInventoryItemRequest,
    ) -> Result<InventoryItem, AppError> {
        // Verify inventory belongs to church and is open
        let inventory = Self::get_by_id(pool, church_id, inventory_id).await?;
        if inventory.status == "concluido" {
            return Err(AppError::validation(
                "Inventário já foi concluído. Não é possível alterar itens.",
            ));
        }

        let valid_statuses = ["encontrado", "nao_encontrado", "divergencia"];
        if !valid_statuses.contains(&req.status.as_str()) {
            return Err(AppError::validation(
                "Status deve ser: encontrado, nao_encontrado ou divergencia",
            ));
        }

        let item = sqlx::query_as::<_, InventoryItem>(
            r#"
            UPDATE inventory_items
            SET status = $1, observed_condition = $2, notes = $3, checked_at = NOW(), checked_by = $4
            WHERE id = $5 AND inventory_id = $6
            RETURNING *
            "#,
        )
        .bind(&req.status)
        .bind(&req.observed_condition)
        .bind(&req.notes)
        .bind(user_id)
        .bind(item_id)
        .bind(inventory_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Item do inventário"))?;

        // Recalculate summary counts
        sqlx::query(
            r#"
            UPDATE inventories SET
                found_items = (SELECT COUNT(*) FROM inventory_items WHERE inventory_id = $1 AND status = 'encontrado'),
                missing_items = (SELECT COUNT(*) FROM inventory_items WHERE inventory_id = $1 AND status = 'nao_encontrado'),
                divergent_items = (SELECT COUNT(*) FROM inventory_items WHERE inventory_id = $1 AND status = 'divergencia')
            WHERE id = $1
            "#,
        )
        .bind(inventory_id)
        .execute(pool)
        .await?;

        Ok(item)
    }

    /// Close an inventory
    pub async fn close(
        pool: &PgPool,
        church_id: Uuid,
        inventory_id: Uuid,
    ) -> Result<Inventory, AppError> {
        let inventory = Self::get_by_id(pool, church_id, inventory_id).await?;
        if inventory.status == "concluido" {
            return Err(AppError::Conflict("Inventário já está concluído".into()));
        }

        // Check if all items have been checked
        let pending: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM inventory_items WHERE inventory_id = $1 AND status = 'pendente'",
        )
        .bind(inventory_id)
        .fetch_one(pool)
        .await?;

        if pending > 0 {
            return Err(AppError::validation(format!(
                "Ainda há {pending} itens pendentes de conferência"
            )));
        }

        sqlx::query(
            r#"
            UPDATE inventories
            SET status = 'concluido', completed_at = NOW()
            WHERE id = $1 AND church_id = $2
            "#,
        )
        .bind(inventory_id)
        .bind(church_id)
        .execute(pool)
        .await?;

        Self::get_by_id(pool, church_id, inventory_id).await
    }
}
