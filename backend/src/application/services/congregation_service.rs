use crate::application::dto::{
    AddUserToCongregationRequest, AssignMembersRequest, CongregationCompareFilter,
    CreateCongregationRequest, UpdateCongregationRequest,
};
use crate::domain::entities::{
    AssignMembersResult, Congregation, CongregationCompareItem, CongregationCompareReport,
    CongregationDetail, CongregationOverviewItem, CongregationStats, CongregationSummary,
    CongregationUserInfo, CongregationsOverview, SkippedMember, UserCongregation,
};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct CongregationService;

impl CongregationService {
    /// List congregations with leader info and member counts
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        is_active: Option<bool>,
        congregation_type: Option<String>,
    ) -> Result<Vec<CongregationSummary>, AppError> {
        let mut conditions = vec!["c.church_id = $1".to_string()];
        let mut param_index = 2u32;

        if is_active.is_some() {
            conditions.push(format!("c.is_active = ${param_index}"));
            param_index += 1;
        }

        if congregation_type.is_some() {
            conditions.push(format!("c.type = ${param_index}"));
            param_index += 1;
        }

        let _ = param_index;

        let where_clause = conditions.join(" AND ");

        let sql = format!(
            r#"
            SELECT c.id, c.name, c.short_name, c.type, c.leader_id,
                   m.full_name AS leader_name,
                   c.neighborhood, c.city, c.state, c.phone,
                   c.is_active, c.sort_order,
                   (SELECT COUNT(*) FROM members mem WHERE mem.congregation_id = c.id AND mem.status = 'ativo' AND mem.deleted_at IS NULL) AS active_members,
                   (SELECT COUNT(*) FROM members mem WHERE mem.congregation_id = c.id AND mem.deleted_at IS NULL) AS total_members,
                   c.created_at
            FROM congregations c
            LEFT JOIN members m ON m.id = c.leader_id AND m.deleted_at IS NULL
            WHERE {where_clause}
            ORDER BY c.sort_order ASC, c.name ASC
            "#
        );

        let mut args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(active) = is_active {
            sqlx::Arguments::add(&mut args, active).unwrap();
        }

        if let Some(ref t) = congregation_type {
            sqlx::Arguments::add(&mut args, t.as_str()).unwrap();
        }

        let congregations = sqlx::query_as_with::<_, CongregationSummary, _>(&sql, args)
            .fetch_all(pool)
            .await?;

        Ok(congregations)
    }

    /// Get congregation by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
    ) -> Result<Congregation, AppError> {
        sqlx::query_as::<_, Congregation>(
            r#"
            SELECT id, church_id, name, short_name, type, leader_id,
                   zip_code, street, number, complement, neighborhood, city, state,
                   phone, email, is_active, sort_order, settings,
                   created_at, updated_at
            FROM congregations 
            WHERE id = $1 AND church_id = $2
            "#,
        )
        .bind(congregation_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Congregação"))
    }

    /// Create a new congregation
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateCongregationRequest,
    ) -> Result<Congregation, AppError> {
        let ctype = req.congregation_type.as_deref().unwrap_or("congregacao");

        // Validate type
        if !["sede", "congregacao", "ponto_de_pregacao"].contains(&ctype) {
            return Err(AppError::validation(
                "Tipo inválido. Use: sede, congregacao ou ponto_de_pregacao",
            ));
        }

        // RN-CONG-001: Only one 'sede' per church
        if ctype == "sede" {
            let existing_sede = sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM congregations WHERE church_id = $1 AND type = 'sede' AND is_active = TRUE",
            )
            .bind(church_id)
            .fetch_optional(pool)
            .await?;

            if existing_sede.is_some() {
                return Err(AppError::conflict(
                    "Já existe uma sede cadastrada para esta igreja",
                ));
            }
        }

        // RN-CONG-002: Validate leader exists and is active
        if let Some(leader_id) = req.leader_id {
            let _leader = sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
            )
            .bind(leader_id)
            .bind(church_id)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| AppError::validation("Dirigente não encontrado ou não pertence a esta igreja"))?;
        }

        let congregation = sqlx::query_as::<_, Congregation>(
            r#"
            INSERT INTO congregations (church_id, name, short_name, type, leader_id,
                                       zip_code, street, number, complement, neighborhood, city, state,
                                       phone, email)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            RETURNING id, church_id, name, short_name, type, leader_id,
                      zip_code, street, number, complement, neighborhood, city, state,
                      phone, email, is_active, sort_order, settings, created_at, updated_at
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(&req.short_name)
        .bind(ctype)
        .bind(req.leader_id)
        .bind(&req.zip_code)
        .bind(&req.street)
        .bind(&req.number)
        .bind(&req.complement)
        .bind(&req.neighborhood)
        .bind(&req.city)
        .bind(&req.state)
        .bind(&req.phone)
        .bind(&req.email)
        .fetch_one(pool)
        .await?;

        Ok(congregation)
    }

    /// Update a congregation
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
        req: &UpdateCongregationRequest,
    ) -> Result<Congregation, AppError> {
        // Verify exists
        let existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32; // $1 = congregation_id, $2 = church_id

        sqlx::Arguments::add(&mut args, congregation_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref name) = req.name {
            set_clauses.push(format!("name = ${param_index}"));
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref short_name) = req.short_name {
            set_clauses.push(format!("short_name = ${param_index}"));
            sqlx::Arguments::add(&mut args, short_name.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref ctype) = req.congregation_type {
            if !["sede", "congregacao", "ponto_de_pregacao"].contains(&ctype.as_str()) {
                return Err(AppError::validation(
                    "Tipo inválido. Use: sede, congregacao ou ponto_de_pregacao",
                ));
            }
            // RN-CONG-001: Only one 'sede' per church
            if ctype == "sede" && existing.congregation_type != "sede" {
                let existing_sede = sqlx::query_scalar::<_, Uuid>(
                    "SELECT id FROM congregations WHERE church_id = $1 AND type = 'sede' AND is_active = TRUE AND id != $2",
                )
                .bind(church_id)
                .bind(congregation_id)
                .fetch_optional(pool)
                .await?;

                if existing_sede.is_some() {
                    return Err(AppError::conflict(
                        "Já existe uma sede cadastrada para esta igreja",
                    ));
                }
            }
            set_clauses.push(format!("type = ${param_index}"));
            sqlx::Arguments::add(&mut args, ctype.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(leader_id) = req.leader_id {
            // Validate leader
            let _leader = sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
            )
            .bind(leader_id)
            .bind(church_id)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| AppError::validation("Dirigente não encontrado ou não pertence a esta igreja"))?;

            set_clauses.push(format!("leader_id = ${param_index}"));
            sqlx::Arguments::add(&mut args, leader_id).unwrap();
            param_index += 1;
        }
        if let Some(ref zip_code) = req.zip_code {
            set_clauses.push(format!("zip_code = ${param_index}"));
            sqlx::Arguments::add(&mut args, zip_code.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref street) = req.street {
            set_clauses.push(format!("street = ${param_index}"));
            sqlx::Arguments::add(&mut args, street.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref number) = req.number {
            set_clauses.push(format!("number = ${param_index}"));
            sqlx::Arguments::add(&mut args, number.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref complement) = req.complement {
            set_clauses.push(format!("complement = ${param_index}"));
            sqlx::Arguments::add(&mut args, complement.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref neighborhood) = req.neighborhood {
            set_clauses.push(format!("neighborhood = ${param_index}"));
            sqlx::Arguments::add(&mut args, neighborhood.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref city) = req.city {
            set_clauses.push(format!("city = ${param_index}"));
            sqlx::Arguments::add(&mut args, city.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref state_val) = req.state {
            set_clauses.push(format!("state = ${param_index}"));
            sqlx::Arguments::add(&mut args, state_val.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref phone) = req.phone {
            set_clauses.push(format!("phone = ${param_index}"));
            sqlx::Arguments::add(&mut args, phone.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref email) = req.email {
            set_clauses.push(format!("email = ${param_index}"));
            sqlx::Arguments::add(&mut args, email.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(is_active) = req.is_active {
            set_clauses.push(format!("is_active = ${param_index}"));
            sqlx::Arguments::add(&mut args, is_active).unwrap();
            param_index += 1;
        }
        if let Some(sort_order) = req.sort_order {
            set_clauses.push(format!("sort_order = ${param_index}"));
            sqlx::Arguments::add(&mut args, sort_order).unwrap();
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, congregation_id).await;
        }

        let sql = format!(
            r#"UPDATE congregations SET {} 
               WHERE id = $1 AND church_id = $2 
               RETURNING id, church_id, name, short_name, type, leader_id,
                         zip_code, street, number, complement, neighborhood, city, state,
                         phone, email, is_active, sort_order, settings, created_at, updated_at"#,
            set_clauses.join(", ")
        );

        let congregation = sqlx::query_as_with::<_, Congregation, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(congregation)
    }

    /// Deactivate a congregation (soft delete)
    pub async fn deactivate(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
    ) -> Result<(), AppError> {
        let existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        // RN-CONG-001: Sede cannot be deactivated if other active congregations exist
        if existing.congregation_type == "sede" {
            let other_active = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM congregations WHERE church_id = $1 AND id != $2 AND is_active = TRUE",
            )
            .bind(church_id)
            .bind(congregation_id)
            .fetch_one(pool)
            .await?;

            if other_active > 0 {
                return Err(AppError::conflict(
                    "A sede não pode ser desativada enquanto houver outras congregações ativas",
                ));
            }
        }

        let result = sqlx::query(
            "UPDATE congregations SET is_active = FALSE WHERE id = $1 AND church_id = $2",
        )
        .bind(congregation_id)
        .bind(church_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Congregação"));
        }

        Ok(())
    }

    /// Get stats for a congregation
    pub async fn get_stats(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
    ) -> Result<CongregationStats, AppError> {
        // Verify exists
        let _existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        // Member stats
        let active_members: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM members WHERE congregation_id = $1 AND status = 'ativo' AND deleted_at IS NULL",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let total_members: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM members WHERE congregation_id = $1 AND deleted_at IS NULL",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let visitors: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM members WHERE congregation_id = $1 AND status = 'visitante' AND deleted_at IS NULL",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let congregados: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM members WHERE congregation_id = $1 AND status = 'congregado' AND deleted_at IS NULL",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let new_this_month: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM members WHERE congregation_id = $1 AND deleted_at IS NULL AND created_at >= DATE_TRUNC('month', NOW())",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        // Financial stats (current month)
        let income: (Option<f64>,) = sqlx::query_as(
            r#"SELECT COALESCE(SUM(amount::float8), 0.0) FROM financial_entries 
               WHERE congregation_id = $1 AND type = 'receita' AND status = 'confirmado' 
               AND entry_date >= DATE_TRUNC('month', NOW()) AND deleted_at IS NULL"#,
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let expense: (Option<f64>,) = sqlx::query_as(
            r#"SELECT COALESCE(SUM(amount::float8), 0.0) FROM financial_entries 
               WHERE congregation_id = $1 AND type = 'despesa' AND status = 'confirmado' 
               AND entry_date >= DATE_TRUNC('month', NOW()) AND deleted_at IS NULL"#,
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let income_val = income.0.unwrap_or(0.0);
        let expense_val = expense.0.unwrap_or(0.0);

        // EBD stats
        let ebd_classes: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM ebd_classes WHERE congregation_id = $1 AND is_active = TRUE",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        let ebd_students: (i64,) = sqlx::query_as(
            r#"SELECT COUNT(DISTINCT ee.member_id) FROM ebd_enrollments ee
               JOIN ebd_classes ec ON ec.id = ee.class_id
               WHERE ec.congregation_id = $1 AND ee.is_active = TRUE"#,
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        // Assets
        let total_assets: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM assets WHERE congregation_id = $1 AND deleted_at IS NULL",
        )
        .bind(congregation_id)
        .fetch_one(pool)
        .await?;

        Ok(CongregationStats {
            active_members: active_members.0,
            total_members: total_members.0,
            visitors: visitors.0,
            congregados: congregados.0,
            new_this_month: new_this_month.0,
            income_this_month: income_val,
            expense_this_month: expense_val,
            balance: income_val - expense_val,
            ebd_classes: ebd_classes.0,
            ebd_students: ebd_students.0,
            total_assets: total_assets.0,
        })
    }

    /// List users with access to a congregation
    pub async fn list_users(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
    ) -> Result<Vec<CongregationUserInfo>, AppError> {
        // Verify congregation exists
        let _existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        let users = sqlx::query_as::<_, CongregationUserInfo>(
            r#"
            SELECT uc.user_id, u.email, uc.role_in_congregation, uc.is_primary,
                   r.display_name AS user_role_name
            FROM user_congregations uc
            JOIN users u ON u.id = uc.user_id
            LEFT JOIN roles r ON r.id = u.role_id
            WHERE uc.congregation_id = $1 AND u.church_id = $2
            ORDER BY uc.role_in_congregation ASC, u.email ASC
            "#,
        )
        .bind(congregation_id)
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        Ok(users)
    }

    /// Add user to a congregation
    pub async fn add_user(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
        req: &AddUserToCongregationRequest,
    ) -> Result<UserCongregation, AppError> {
        // Verify congregation exists
        let _existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        // Verify user exists in same church
        let _user = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM users WHERE id = $1 AND church_id = $2",
        )
        .bind(req.user_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Usuário"))?;

        // Check if already has access
        let existing = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM user_congregations WHERE user_id = $1 AND congregation_id = $2",
        )
        .bind(req.user_id)
        .bind(congregation_id)
        .fetch_optional(pool)
        .await?;

        if existing.is_some() {
            return Err(AppError::conflict(
                "Usuário já possui acesso a esta congregação",
            ));
        }

        // If is_primary, unset other primaries for this user
        if req.is_primary {
            sqlx::query(
                "UPDATE user_congregations SET is_primary = FALSE WHERE user_id = $1 AND is_primary = TRUE",
            )
            .bind(req.user_id)
            .execute(pool)
            .await?;
        }

        let uc = sqlx::query_as::<_, UserCongregation>(
            r#"
            INSERT INTO user_congregations (user_id, congregation_id, role_in_congregation, is_primary)
            VALUES ($1, $2, $3, $4)
            RETURNING *
            "#,
        )
        .bind(req.user_id)
        .bind(congregation_id)
        .bind(&req.role_in_congregation)
        .bind(req.is_primary)
        .fetch_one(pool)
        .await?;

        Ok(uc)
    }

    /// Remove user from a congregation
    pub async fn remove_user(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
        user_id: Uuid,
    ) -> Result<(), AppError> {
        // Verify congregation exists
        let _existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        let result = sqlx::query(
            "DELETE FROM user_congregations WHERE user_id = $1 AND congregation_id = $2",
        )
        .bind(user_id)
        .bind(congregation_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Vínculo usuário-congregação"));
        }

        Ok(())
    }

    /// Assign members to a congregation in batch (with transaction)
    pub async fn assign_members(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
        req: &AssignMembersRequest,
    ) -> Result<AssignMembersResult, AppError> {
        // Verify congregation exists
        let _existing = Self::get_by_id(pool, church_id, congregation_id).await?;

        let mut tx = pool.begin().await.map_err(|e| AppError::Internal(e.to_string()))?;

        let mut assigned: i64 = 0;
        let mut skipped: i64 = 0;
        let mut skipped_members: Vec<SkippedMember> = Vec::new();

        for member_id in &req.member_ids {
            // Check member exists in this church
            let member = sqlx::query_as::<_, (Uuid, String, Option<Uuid>)>(
                "SELECT id, full_name, congregation_id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
            )
            .bind(member_id)
            .bind(church_id)
            .fetch_optional(&mut *tx)
            .await?;

            let Some((mid, full_name, current_cong_id)) = member else {
                continue; // Member not found, skip
            };

            // If already assigned to another congregation and overwrite is false, skip
            if current_cong_id.is_some() && current_cong_id != Some(congregation_id) && !req.overwrite {
                // Get current congregation name
                let current_name = if let Some(cid) = current_cong_id {
                    sqlx::query_scalar::<_, String>(
                        "SELECT name FROM congregations WHERE id = $1",
                    )
                    .bind(cid)
                    .fetch_optional(&mut *tx)
                    .await?
                } else {
                    None
                };

                skipped_members.push(SkippedMember {
                    id: mid,
                    full_name,
                    current_congregation: current_name,
                });
                skipped += 1;
                continue;
            }

            // Assign member
            sqlx::query("UPDATE members SET congregation_id = $1 WHERE id = $2")
                .bind(congregation_id)
                .bind(mid)
                .execute(&mut *tx)
                .await?;

            // Create history entry for internal transfer
            if current_cong_id.is_some() && current_cong_id != Some(congregation_id) {
                let _ = sqlx::query(
                    r#"INSERT INTO member_history (member_id, event_type, description)
                       VALUES ($1, 'transferencia_interna', $2)"#,
                )
                .bind(mid)
                .bind("Transferido para congregação via associação em lote")
                .execute(&mut *tx)
                .await;
            }

            assigned += 1;
        }

        tx.commit().await.map_err(|e| AppError::Internal(e.to_string()))?;

        Ok(AssignMembersResult {
            assigned,
            skipped,
            skipped_members,
        })
    }

    /// Congregations overview report
    pub async fn get_overview(
        pool: &PgPool,
        church_id: Uuid,
    ) -> Result<CongregationsOverview, AppError> {
        let congregations = sqlx::query_as::<_, CongregationOverviewItem>(
            r#"
            SELECT c.id, c.name, c.type,
                   (SELECT COUNT(*) FROM members m WHERE m.congregation_id = c.id AND m.status = 'ativo' AND m.deleted_at IS NULL) AS active_members,
                   (SELECT COALESCE(SUM(fe.amount::float8), 0.0) FROM financial_entries fe 
                    WHERE fe.congregation_id = c.id AND fe.type = 'receita' AND fe.status = 'confirmado' 
                    AND fe.entry_date >= DATE_TRUNC('month', NOW()) AND fe.deleted_at IS NULL) AS income_month,
                   (SELECT COALESCE(SUM(fe.amount::float8), 0.0) FROM financial_entries fe 
                    WHERE fe.congregation_id = c.id AND fe.type = 'despesa' AND fe.status = 'confirmado' 
                    AND fe.entry_date >= DATE_TRUNC('month', NOW()) AND fe.deleted_at IS NULL) AS expense_month
            FROM congregations c
            WHERE c.church_id = $1 AND c.is_active = TRUE
            ORDER BY c.sort_order ASC, c.name ASC
            "#,
        )
        .bind(church_id)
        .fetch_all(pool)
        .await?;

        let total_congregations = congregations.len() as i64;
        let total_members_all: i64 = congregations.iter().map(|c| c.active_members.unwrap_or(0)).sum();
        let total_income_month: f64 = congregations.iter().map(|c| c.income_month.unwrap_or(0.0)).sum();
        let total_expense_month: f64 = congregations.iter().map(|c| c.expense_month.unwrap_or(0.0)).sum();

        Ok(CongregationsOverview {
            total_congregations,
            total_members_all,
            total_income_month,
            total_expense_month,
            congregations,
        })
    }

    /// Get congregation detail with leader name and stats
    pub async fn get_detail(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
    ) -> Result<CongregationDetail, AppError> {
        let congregation = Self::get_by_id(pool, church_id, congregation_id).await?;

        // Get leader name
        let leader_name = if let Some(leader_id) = congregation.leader_id {
            sqlx::query_scalar::<_, String>(
                "SELECT full_name FROM members WHERE id = $1 AND deleted_at IS NULL",
            )
            .bind(leader_id)
            .fetch_optional(pool)
            .await?
        } else {
            None
        };

        // Get stats
        let stats = Self::get_stats(pool, church_id, congregation_id).await.ok();

        Ok(CongregationDetail {
            congregation,
            leader_name,
            stats,
        })
    }

    /// Validate and return congregation name for active context
    pub async fn validate_active_congregation(
        pool: &PgPool,
        church_id: Uuid,
        congregation_id: Uuid,
    ) -> Result<String, AppError> {
        let cong = Self::get_by_id(pool, church_id, congregation_id).await?;
        Ok(cong.name)
    }

    /// Compare congregations by metric
    pub async fn compare(
        pool: &PgPool,
        church_id: Uuid,
        filter: &CongregationCompareFilter,
    ) -> Result<CongregationCompareReport, AppError> {
        let metric = filter.metric.as_deref().unwrap_or("members");

        // Parse congregation_ids if provided (comma-separated)
        let congregation_ids: Option<Vec<Uuid>> = filter.congregation_ids.as_ref().and_then(|ids| {
            let parsed: Vec<Uuid> = ids
                .split(',')
                .filter_map(|s| s.trim().parse::<Uuid>().ok())
                .collect();
            if parsed.is_empty() { None } else { Some(parsed) }
        });

        let items = match metric {
            "members" => Self::compare_members(pool, church_id, &congregation_ids).await?,
            "financial" => Self::compare_financial(pool, church_id, &congregation_ids, &filter.period_start, &filter.period_end).await?,
            "ebd" => Self::compare_ebd(pool, church_id, &congregation_ids).await?,
            "assets" => Self::compare_assets(pool, church_id, &congregation_ids).await?,
            _ => return Err(AppError::validation("Métrica inválida. Use: members, financial, ebd ou assets")),
        };

        Ok(CongregationCompareReport {
            metric: metric.to_string(),
            period_start: filter.period_start.clone(),
            period_end: filter.period_end.clone(),
            congregations: items,
        })
    }

    async fn compare_members(
        pool: &PgPool,
        church_id: Uuid,
        congregation_ids: &Option<Vec<Uuid>>,
    ) -> Result<Vec<CongregationCompareItem>, AppError> {
        let filter_clause = if let Some(ids) = congregation_ids {
            let id_list: Vec<String> = ids.iter().map(|id| format!("'{}'", id)).collect();
            format!("AND c.id IN ({})", id_list.join(","))
        } else {
            String::new()
        };

        let sql = format!(
            r#"
            SELECT c.id, c.name, c.type,
                (SELECT COUNT(*)::float8 FROM members m WHERE m.congregation_id = c.id AND m.status = 'ativo' AND m.deleted_at IS NULL) AS value_1,
                (SELECT COUNT(*)::float8 FROM members m WHERE m.congregation_id = c.id AND m.deleted_at IS NULL) AS value_2,
                (SELECT COUNT(*)::float8 FROM members m WHERE m.congregation_id = c.id AND m.deleted_at IS NULL AND m.created_at >= DATE_TRUNC('month', NOW())) AS value_3,
                'Membros Ativos'::text AS label_1,
                'Total Membros'::text AS label_2,
                'Novos no Mês'::text AS label_3
            FROM congregations c
            WHERE c.church_id = $1 AND c.is_active = TRUE {filter_clause}
            ORDER BY value_1 DESC NULLS LAST
            "#
        );

        let items = sqlx::query_as::<_, CongregationCompareItem>(&sql)
            .bind(church_id)
            .fetch_all(pool)
            .await?;

        Ok(items)
    }

    async fn compare_financial(
        pool: &PgPool,
        church_id: Uuid,
        congregation_ids: &Option<Vec<Uuid>>,
        period_start: &Option<String>,
        period_end: &Option<String>,
    ) -> Result<Vec<CongregationCompareItem>, AppError> {
        let filter_clause = if let Some(ids) = congregation_ids {
            let id_list: Vec<String> = ids.iter().map(|id| format!("'{}'", id)).collect();
            format!("AND c.id IN ({})", id_list.join(","))
        } else {
            String::new()
        };

        let date_filter = match (period_start, period_end) {
            (Some(start), Some(end)) => format!(
                "AND fe.entry_date >= '{start}' AND fe.entry_date <= '{end}'"
            ),
            (Some(start), None) => format!("AND fe.entry_date >= '{start}'"),
            (None, Some(end)) => format!("AND fe.entry_date <= '{end}'"),
            _ => "AND fe.entry_date >= DATE_TRUNC('month', NOW())".to_string(),
        };

        let sql = format!(
            r#"
            SELECT c.id, c.name, c.type,
                (SELECT COALESCE(SUM(fe.amount::float8), 0.0) FROM financial_entries fe 
                 WHERE fe.congregation_id = c.id AND fe.type = 'receita' AND fe.status = 'confirmado' 
                 {date_filter} AND fe.deleted_at IS NULL) AS value_1,
                (SELECT COALESCE(SUM(fe.amount::float8), 0.0) FROM financial_entries fe 
                 WHERE fe.congregation_id = c.id AND fe.type = 'despesa' AND fe.status = 'confirmado' 
                 {date_filter} AND fe.deleted_at IS NULL) AS value_2,
                (SELECT COALESCE(SUM(CASE WHEN fe.type = 'receita' THEN fe.amount ELSE -fe.amount END)::float8, 0.0) FROM financial_entries fe 
                 WHERE fe.congregation_id = c.id AND fe.status = 'confirmado' 
                 {date_filter} AND fe.deleted_at IS NULL) AS value_3,
                'Receitas'::text AS label_1,
                'Despesas'::text AS label_2,
                'Saldo'::text AS label_3
            FROM congregations c
            WHERE c.church_id = $1 AND c.is_active = TRUE {filter_clause}
            ORDER BY value_3 DESC NULLS LAST
            "#
        );

        let items = sqlx::query_as::<_, CongregationCompareItem>(&sql)
            .bind(church_id)
            .fetch_all(pool)
            .await?;

        Ok(items)
    }

    async fn compare_ebd(
        pool: &PgPool,
        church_id: Uuid,
        congregation_ids: &Option<Vec<Uuid>>,
    ) -> Result<Vec<CongregationCompareItem>, AppError> {
        let filter_clause = if let Some(ids) = congregation_ids {
            let id_list: Vec<String> = ids.iter().map(|id| format!("'{}'", id)).collect();
            format!("AND c.id IN ({})", id_list.join(","))
        } else {
            String::new()
        };

        let sql = format!(
            r#"
            SELECT c.id, c.name, c.type,
                (SELECT COUNT(*)::float8 FROM ebd_classes ec WHERE ec.congregation_id = c.id AND ec.is_active = TRUE) AS value_1,
                (SELECT COUNT(DISTINCT ee.member_id)::float8 FROM ebd_enrollments ee
                 JOIN ebd_classes ec2 ON ec2.id = ee.class_id
                 WHERE ec2.congregation_id = c.id AND ee.is_active = TRUE) AS value_2,
                (SELECT COALESCE(AVG(CASE WHEN ea.status = 'presente' THEN 100.0 ELSE 0.0 END), 0.0) FROM ebd_attendances ea
                 JOIN ebd_lessons el ON el.id = ea.lesson_id
                 JOIN ebd_classes ec3 ON ec3.id = el.class_id
                 WHERE ec3.congregation_id = c.id) AS value_3,
                'Turmas Ativas'::text AS label_1,
                'Alunos Matriculados'::text AS label_2,
                'Frequência Média (%)'::text AS label_3
            FROM congregations c
            WHERE c.church_id = $1 AND c.is_active = TRUE {filter_clause}
            ORDER BY value_3 DESC NULLS LAST
            "#
        );

        let items = sqlx::query_as::<_, CongregationCompareItem>(&sql)
            .bind(church_id)
            .fetch_all(pool)
            .await?;

        Ok(items)
    }

    async fn compare_assets(
        pool: &PgPool,
        church_id: Uuid,
        congregation_ids: &Option<Vec<Uuid>>,
    ) -> Result<Vec<CongregationCompareItem>, AppError> {
        let filter_clause = if let Some(ids) = congregation_ids {
            let id_list: Vec<String> = ids.iter().map(|id| format!("'{}'", id)).collect();
            format!("AND c.id IN ({})", id_list.join(","))
        } else {
            String::new()
        };

        let sql = format!(
            r#"
            SELECT c.id, c.name, c.type,
                (SELECT COUNT(*)::float8 FROM assets a WHERE a.congregation_id = c.id AND a.deleted_at IS NULL) AS value_1,
                (SELECT COALESCE(SUM(a.acquisition_value::float8), 0.0) FROM assets a 
                 WHERE a.congregation_id = c.id AND a.deleted_at IS NULL) AS value_2,
                (SELECT COUNT(*)::float8 FROM assets a WHERE a.congregation_id = c.id AND a.status = 'em_uso' AND a.deleted_at IS NULL) AS value_3,
                'Total Bens'::text AS label_1,
                'Valor Total'::text AS label_2,
                'Em Uso'::text AS label_3
            FROM congregations c
            WHERE c.church_id = $1 AND c.is_active = TRUE {filter_clause}
            ORDER BY value_2 DESC NULLS LAST
            "#
        );

        let items = sqlx::query_as::<_, CongregationCompareItem>(&sql)
            .bind(church_id)
            .fetch_all(pool)
            .await?;

        Ok(items)
    }
}
