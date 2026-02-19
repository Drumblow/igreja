use crate::application::dto::{CreateMaintenanceRequest, MaintenanceFilter, UpdateMaintenanceRequest};
use crate::domain::entities::{Maintenance, MaintenanceSummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct MaintenanceService;

impl MaintenanceService {
    /// List maintenances with pagination and filters
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &MaintenanceFilter,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<MaintenanceSummary>, i64), AppError> {
        let mut conditions = vec!["m.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if filter.asset_id.is_some() {
            conditions.push(format!("m.asset_id = ${param_idx}"));
            param_idx += 1;
        }

        if filter.status.is_some() {
            conditions.push(format!("m.status = ${param_idx}"));
            param_idx += 1;
        }

        if filter.maintenance_type.is_some() {
            conditions.push(format!("m.type = ${param_idx}"));
            param_idx += 1;
        }

        if search.is_some() {
            conditions.push(format!(
                "unaccent(m.description) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM maintenances m WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT m.id, m.asset_id, a.asset_code, a.description AS asset_description,
                   m.type, m.description, m.supplier_name, m.cost,
                   m.scheduled_date, m.execution_date, m.status, m.created_at
            FROM maintenances m
            LEFT JOIN assets a ON a.id = m.asset_id
            WHERE {where_clause}
            ORDER BY COALESCE(m.scheduled_date, m.execution_date, m.created_at::date) DESC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(asset_id) = filter.asset_id {
            sqlx::Arguments::add(&mut count_args, asset_id).unwrap();
            sqlx::Arguments::add(&mut data_args, asset_id).unwrap();
        }

        if let Some(ref status) = filter.status {
            sqlx::Arguments::add(&mut count_args, status.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, status.as_str()).unwrap();
        }

        if let Some(ref mt) = filter.maintenance_type {
            sqlx::Arguments::add(&mut count_args, mt.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, mt.as_str()).unwrap();
        }

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let maintenances = sqlx::query_as_with::<_, MaintenanceSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((maintenances, total))
    }

    /// Get maintenance by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        maintenance_id: Uuid,
    ) -> Result<Maintenance, AppError> {
        sqlx::query_as::<_, Maintenance>(
            "SELECT * FROM maintenances WHERE id = $1 AND church_id = $2",
        )
        .bind(maintenance_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Manutenção"))
    }

    /// Create a new maintenance
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateMaintenanceRequest,
    ) -> Result<Maintenance, AppError> {
        // Validate type
        let valid_types = ["preventiva", "corretiva"];
        if !valid_types.contains(&req.maintenance_type.as_str()) {
            return Err(AppError::validation(
                "Tipo deve ser: preventiva ou corretiva",
            ));
        }

        // Optionally update asset status to em_manutencao
        if req.execution_date.is_none() || req.execution_date == req.scheduled_date {
            sqlx::query(
                "UPDATE assets SET status = 'em_manutencao', status_date = CURRENT_DATE WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL AND status = 'ativo'",
            )
            .bind(req.asset_id)
            .bind(church_id)
            .execute(pool)
            .await?;
        }

        let maintenance = sqlx::query_as::<_, Maintenance>(
            r#"
            INSERT INTO maintenances (
                church_id, asset_id, type, description, supplier_name, cost,
                scheduled_date, execution_date, next_maintenance_date, notes
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.asset_id)
        .bind(&req.maintenance_type)
        .bind(&req.description)
        .bind(&req.supplier_name)
        .bind(req.cost)
        .bind(req.scheduled_date)
        .bind(req.execution_date)
        .bind(req.next_maintenance_date)
        .bind(&req.notes)
        .fetch_one(pool)
        .await?;

        Ok(maintenance)
    }

    /// Update a maintenance
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        maintenance_id: Uuid,
        req: &UpdateMaintenanceRequest,
    ) -> Result<Maintenance, AppError> {
        let existing = Self::get_by_id(pool, church_id, maintenance_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut pi = 3u32;

        sqlx::Arguments::add(&mut args, maintenance_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref v) = req.description {
            set_clauses.push(format!("description = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.supplier_name {
            set_clauses.push(format!("supplier_name = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }
        if let Some(v) = req.cost {
            set_clauses.push(format!("cost = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(v) = req.scheduled_date {
            set_clauses.push(format!("scheduled_date = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(v) = req.execution_date {
            set_clauses.push(format!("execution_date = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(v) = req.next_maintenance_date {
            set_clauses.push(format!("next_maintenance_date = ${pi}"));
            sqlx::Arguments::add(&mut args, v).unwrap();
            pi += 1;
        }
        if let Some(ref v) = req.status {
            let valid = ["agendada", "em_andamento", "concluida", "cancelada"];
            if !valid.contains(&v.as_str()) {
                return Err(AppError::validation(
                    "Status deve ser: agendada, em_andamento, concluida ou cancelada",
                ));
            }
            set_clauses.push(format!("status = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;

            // If completed, return asset to active
            if v == "concluida" {
                sqlx::query(
                    "UPDATE assets SET status = 'ativo', status_date = CURRENT_DATE WHERE id = $1 AND church_id = $2 AND status = 'em_manutencao'",
                )
                .bind(existing.asset_id)
                .bind(church_id)
                .execute(pool)
                .await?;
            }
        }
        if let Some(ref v) = req.notes {
            set_clauses.push(format!("notes = ${pi}"));
            sqlx::Arguments::add(&mut args, v.as_str()).unwrap();
            pi += 1;
        }

        let _ = pi;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, maintenance_id).await;
        }

        let sql = format!(
            "UPDATE maintenances SET {} WHERE id = $1 AND church_id = $2 RETURNING *",
            set_clauses.join(", ")
        );

        let maintenance = sqlx::query_as_with::<_, Maintenance, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(maintenance)
    }
}
