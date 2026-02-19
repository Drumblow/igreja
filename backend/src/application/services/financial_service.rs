use crate::application::dto::{
    BalanceReportFilter, CreateFinancialEntryRequest, FinancialEntryFilter,
    MonthlyClosingRequest, UpdateFinancialEntryRequest,
};
use crate::domain::entities::{
    CategoryAmount, FinancialBalance, FinancialEntry, FinancialEntrySummary,
    MonthlyClosing, MonthlyClosingSummary,
};
use crate::errors::AppError;
use rust_decimal::Decimal;
use sqlx::PgPool;
use uuid::Uuid;

pub struct FinancialEntryService;

impl FinancialEntryService {
    /// List financial entries with filters
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &FinancialEntryFilter,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<FinancialEntrySummary>, i64), AppError> {
        let mut conditions = vec!["fe.church_id = $1".to_string(), "fe.deleted_at IS NULL".to_string()];
        let mut param_idx = 2u32;

        if filter.entry_type.is_some() {
            conditions.push(format!("fe.type = ${param_idx}"));
            param_idx += 1;
        }
        if filter.account_plan_id.is_some() {
            conditions.push(format!("fe.account_plan_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.bank_account_id.is_some() {
            conditions.push(format!("fe.bank_account_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.status.is_some() {
            conditions.push(format!("fe.status = ${param_idx}"));
            param_idx += 1;
        }
        if filter.date_from.is_some() {
            conditions.push(format!("fe.entry_date >= ${param_idx}"));
            param_idx += 1;
        }
        if filter.date_to.is_some() {
            conditions.push(format!("fe.entry_date <= ${param_idx}"));
            param_idx += 1;
        }
        if filter.member_id.is_some() {
            conditions.push(format!("fe.member_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.campaign_id.is_some() {
            conditions.push(format!("fe.campaign_id = ${param_idx}"));
            param_idx += 1;
        }
        if filter.payment_method.is_some() {
            conditions.push(format!("fe.payment_method = ${param_idx}"));
            param_idx += 1;
        }
        if search.is_some() {
            conditions.push(format!(
                "unaccent(fe.description) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let _ = param_idx;
        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM financial_entries fe WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT fe.id, fe.type, fe.amount, fe.entry_date, fe.due_date, fe.payment_date,
                   fe.description, fe.payment_method, fe.status, fe.is_closed,
                   ap.name AS account_plan_name,
                   ba.name AS bank_account_name,
                   m.full_name AS member_name,
                   ca.name AS campaign_name,
                   fe.supplier_name,
                   fe.created_at
            FROM financial_entries fe
            LEFT JOIN account_plans ap ON ap.id = fe.account_plan_id
            LEFT JOIN bank_accounts ba ON ba.id = fe.bank_account_id
            LEFT JOIN members m ON m.id = fe.member_id
            LEFT JOIN campaigns ca ON ca.id = fe.campaign_id
            WHERE {where_clause}
            ORDER BY fe.entry_date DESC, fe.created_at DESC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        // Helper macro pattern — bind all args in order
        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(ref et) = filter.entry_type {
            sqlx::Arguments::add(&mut count_args, et.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, et.as_str()).unwrap();
        }
        if let Some(ap_id) = filter.account_plan_id {
            sqlx::Arguments::add(&mut count_args, ap_id).unwrap();
            sqlx::Arguments::add(&mut data_args, ap_id).unwrap();
        }
        if let Some(ba_id) = filter.bank_account_id {
            sqlx::Arguments::add(&mut count_args, ba_id).unwrap();
            sqlx::Arguments::add(&mut data_args, ba_id).unwrap();
        }
        if let Some(ref status) = filter.status {
            sqlx::Arguments::add(&mut count_args, status.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, status.as_str()).unwrap();
        }
        if let Some(date_from) = filter.date_from {
            sqlx::Arguments::add(&mut count_args, date_from).unwrap();
            sqlx::Arguments::add(&mut data_args, date_from).unwrap();
        }
        if let Some(date_to) = filter.date_to {
            sqlx::Arguments::add(&mut count_args, date_to).unwrap();
            sqlx::Arguments::add(&mut data_args, date_to).unwrap();
        }
        if let Some(member_id) = filter.member_id {
            sqlx::Arguments::add(&mut count_args, member_id).unwrap();
            sqlx::Arguments::add(&mut data_args, member_id).unwrap();
        }
        if let Some(campaign_id) = filter.campaign_id {
            sqlx::Arguments::add(&mut count_args, campaign_id).unwrap();
            sqlx::Arguments::add(&mut data_args, campaign_id).unwrap();
        }
        if let Some(ref pm) = filter.payment_method {
            sqlx::Arguments::add(&mut count_args, pm.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, pm.as_str()).unwrap();
        }
        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let entries = sqlx::query_as_with::<_, FinancialEntrySummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((entries, total))
    }

    /// Get financial entry by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        entry_id: Uuid,
    ) -> Result<FinancialEntry, AppError> {
        sqlx::query_as::<_, FinancialEntry>(
            r#"SELECT id, church_id, type, account_plan_id, bank_account_id, campaign_id,
                      amount, entry_date, due_date, payment_date, description, payment_method,
                      member_id, supplier_name, receipt_url, status, is_recurring, recurring_id,
                      is_closed, closed_at, closed_by, registered_by, notes, created_at, updated_at, deleted_at
               FROM financial_entries WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL"#,
        )
        .bind(entry_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Lançamento financeiro"))
    }

    /// Create a new financial entry
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Uuid,
        req: &CreateFinancialEntryRequest,
    ) -> Result<FinancialEntry, AppError> {
        // Validate entry type
        if req.entry_type != "receita" && req.entry_type != "despesa" {
            return Err(AppError::validation("Tipo deve ser 'receita' ou 'despesa'"));
        }

        // Validate amount > 0
        if req.amount <= Decimal::ZERO {
            return Err(AppError::validation("Valor deve ser maior que zero"));
        }

        // Verify account_plan exists and belongs to church
        let _plan = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM account_plans WHERE id = $1 AND church_id = $2 AND is_active = TRUE",
        )
        .bind(req.account_plan_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::validation("Plano de contas não encontrado ou inativo"))?;

        // Verify bank_account exists and belongs to church
        let _account = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM bank_accounts WHERE id = $1 AND church_id = $2 AND is_active = TRUE",
        )
        .bind(req.bank_account_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::validation("Conta bancária não encontrada ou inativa"))?;

        // Verify campaign if provided
        if let Some(campaign_id) = req.campaign_id {
            let _campaign = sqlx::query_scalar::<_, Uuid>(
                "SELECT id FROM campaigns WHERE id = $1 AND church_id = $2",
            )
            .bind(campaign_id)
            .bind(church_id)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| AppError::validation("Campanha não encontrada"))?;
        }

        let status = req.status.as_deref().unwrap_or("confirmado");

        let entry = sqlx::query_as::<_, FinancialEntry>(
            r#"
            INSERT INTO financial_entries (
                church_id, type, account_plan_id, bank_account_id, campaign_id,
                amount, entry_date, due_date, payment_date, description,
                payment_method, member_id, supplier_name, receipt_url,
                status, registered_by, notes
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
            RETURNING id, church_id, type, account_plan_id, bank_account_id, campaign_id,
                      amount, entry_date, due_date, payment_date, description, payment_method,
                      member_id, supplier_name, receipt_url, status, is_recurring, recurring_id,
                      is_closed, closed_at, closed_by, registered_by, notes, created_at, updated_at, deleted_at
            "#,
        )
        .bind(church_id)
        .bind(&req.entry_type)
        .bind(req.account_plan_id)
        .bind(req.bank_account_id)
        .bind(req.campaign_id)
        .bind(req.amount)
        .bind(req.entry_date)
        .bind(req.due_date)
        .bind(req.payment_date)
        .bind(&req.description)
        .bind(&req.payment_method)
        .bind(req.member_id)
        .bind(&req.supplier_name)
        .bind(&req.receipt_url)
        .bind(status)
        .bind(user_id)
        .bind(&req.notes)
        .fetch_one(pool)
        .await?;

        // Update bank account balance if confirmed
        if status == "confirmado" {
            Self::update_bank_balance(pool, req.bank_account_id, req.amount, &req.entry_type).await?;
        }

        Ok(entry)
    }

    /// Update a financial entry (only if not closed)
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        entry_id: Uuid,
        req: &UpdateFinancialEntryRequest,
    ) -> Result<FinancialEntry, AppError> {
        let existing = Self::get_by_id(pool, church_id, entry_id).await?;

        if existing.is_closed {
            return Err(AppError::validation(
                "Não é possível alterar um lançamento já fechado",
            ));
        }

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32;

        sqlx::Arguments::add(&mut args, entry_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ap_id) = req.account_plan_id {
            set_clauses.push(format!("account_plan_id = ${param_index}"));
            sqlx::Arguments::add(&mut args, ap_id).unwrap();
            param_index += 1;
        }
        if let Some(ba_id) = req.bank_account_id {
            set_clauses.push(format!("bank_account_id = ${param_index}"));
            sqlx::Arguments::add(&mut args, ba_id).unwrap();
            param_index += 1;
        }
        if let Some(c_id) = req.campaign_id {
            set_clauses.push(format!("campaign_id = ${param_index}"));
            sqlx::Arguments::add(&mut args, c_id).unwrap();
            param_index += 1;
        }
        if let Some(amount) = req.amount {
            if amount <= Decimal::ZERO {
                return Err(AppError::validation("Valor deve ser maior que zero"));
            }
            // Reverse old balance effect and apply new
            if existing.status == "confirmado" {
                Self::reverse_bank_balance(pool, existing.bank_account_id, existing.amount, &existing.entry_type).await?;
                let target_bank = req.bank_account_id.unwrap_or(existing.bank_account_id);
                Self::update_bank_balance(pool, target_bank, amount, &existing.entry_type).await?;
            }
            set_clauses.push(format!("amount = ${param_index}"));
            sqlx::Arguments::add(&mut args, amount).unwrap();
            param_index += 1;
        }
        if let Some(entry_date) = req.entry_date {
            set_clauses.push(format!("entry_date = ${param_index}"));
            sqlx::Arguments::add(&mut args, entry_date).unwrap();
            param_index += 1;
        }
        if let Some(due_date) = req.due_date {
            set_clauses.push(format!("due_date = ${param_index}"));
            sqlx::Arguments::add(&mut args, due_date).unwrap();
            param_index += 1;
        }
        if let Some(payment_date) = req.payment_date {
            set_clauses.push(format!("payment_date = ${param_index}"));
            sqlx::Arguments::add(&mut args, payment_date).unwrap();
            param_index += 1;
        }
        if let Some(ref desc) = req.description {
            set_clauses.push(format!("description = ${param_index}"));
            sqlx::Arguments::add(&mut args, desc.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref pm) = req.payment_method {
            set_clauses.push(format!("payment_method = ${param_index}"));
            sqlx::Arguments::add(&mut args, pm.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(mid) = req.member_id {
            set_clauses.push(format!("member_id = ${param_index}"));
            sqlx::Arguments::add(&mut args, mid).unwrap();
            param_index += 1;
        }
        if let Some(ref sn) = req.supplier_name {
            set_clauses.push(format!("supplier_name = ${param_index}"));
            sqlx::Arguments::add(&mut args, sn.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref url) = req.receipt_url {
            set_clauses.push(format!("receipt_url = ${param_index}"));
            sqlx::Arguments::add(&mut args, url.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref status) = req.status {
            let valid = ["pendente", "confirmado", "cancelado", "estornado"];
            if !valid.contains(&status.as_str()) {
                return Err(AppError::validation(
                    "Status deve ser: pendente, confirmado, cancelado ou estornado",
                ));
            }
            // Handle balance changes on status transition
            if existing.status == "confirmado" && (status == "cancelado" || status == "estornado") {
                Self::reverse_bank_balance(pool, existing.bank_account_id, existing.amount, &existing.entry_type).await?;
            } else if existing.status == "pendente" && status == "confirmado" {
                Self::update_bank_balance(pool, existing.bank_account_id, existing.amount, &existing.entry_type).await?;
            }
            set_clauses.push(format!("status = ${param_index}"));
            sqlx::Arguments::add(&mut args, status.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref notes) = req.notes {
            set_clauses.push(format!("notes = ${param_index}"));
            sqlx::Arguments::add(&mut args, notes.as_str()).unwrap();
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, entry_id).await;
        }

        let sql = format!(
            r#"UPDATE financial_entries SET {}
               WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL
               RETURNING id, church_id, type, account_plan_id, bank_account_id, campaign_id,
                         amount, entry_date, due_date, payment_date, description, payment_method,
                         member_id, supplier_name, receipt_url, status, is_recurring, recurring_id,
                         is_closed, closed_at, closed_by, registered_by, notes, created_at, updated_at, deleted_at"#,
            set_clauses.join(", ")
        );

        let entry = sqlx::query_as_with::<_, FinancialEntry, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(entry)
    }

    /// Soft delete a financial entry
    pub async fn delete(
        pool: &PgPool,
        church_id: Uuid,
        entry_id: Uuid,
    ) -> Result<(), AppError> {
        let existing = Self::get_by_id(pool, church_id, entry_id).await?;

        if existing.is_closed {
            return Err(AppError::validation(
                "Não é possível excluir um lançamento já fechado",
            ));
        }

        // Reverse bank balance if was confirmed
        if existing.status == "confirmado" {
            Self::reverse_bank_balance(pool, existing.bank_account_id, existing.amount, &existing.entry_type).await?;
        }

        let result = sqlx::query(
            "UPDATE financial_entries SET deleted_at = NOW(), status = 'cancelado' WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(entry_id)
        .bind(church_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Lançamento financeiro"));
        }

        Ok(())
    }

    /// Get financial balance report
    pub async fn balance_report(
        pool: &PgPool,
        church_id: Uuid,
        filter: &BalanceReportFilter,
    ) -> Result<FinancialBalance, AppError> {
        let mut date_conditions = String::new();
        let mut has_from = false;
        let mut has_to = false;

        if filter.date_from.is_some() {
            date_conditions.push_str(" AND fe.entry_date >= $2");
            has_from = true;
        }
        if filter.date_to.is_some() {
            let idx = if has_from { 3 } else { 2 };
            date_conditions.push_str(&format!(" AND fe.entry_date <= ${idx}"));
            has_to = true;
        }

        // Total income
        let income_sql = format!(
            r#"SELECT COALESCE(SUM(fe.amount), 0) FROM financial_entries fe
               WHERE fe.church_id = $1 AND fe.type = 'receita' AND fe.status = 'confirmado' AND fe.deleted_at IS NULL{date_conditions}"#
        );

        let expense_sql = format!(
            r#"SELECT COALESCE(SUM(fe.amount), 0) FROM financial_entries fe
               WHERE fe.church_id = $1 AND fe.type = 'despesa' AND fe.status = 'confirmado' AND fe.deleted_at IS NULL{date_conditions}"#
        );

        let income_cat_sql = format!(
            r#"SELECT ap.name AS category_name, COALESCE(SUM(fe.amount), 0) AS amount, COUNT(*) AS count
               FROM financial_entries fe
               JOIN account_plans ap ON ap.id = fe.account_plan_id
               WHERE fe.church_id = $1 AND fe.type = 'receita' AND fe.status = 'confirmado' AND fe.deleted_at IS NULL{date_conditions}
               GROUP BY ap.name ORDER BY amount DESC"#
        );

        let expense_cat_sql = format!(
            r#"SELECT ap.name AS category_name, COALESCE(SUM(fe.amount), 0) AS amount, COUNT(*) AS count
               FROM financial_entries fe
               JOIN account_plans ap ON ap.id = fe.account_plan_id
               WHERE fe.church_id = $1 AND fe.type = 'despesa' AND fe.status = 'confirmado' AND fe.deleted_at IS NULL{date_conditions}
               GROUP BY ap.name ORDER BY amount DESC"#
        );

        // Build common args
        let build_args = |pool_ref: &PgPool| -> (sqlx::postgres::PgArguments, sqlx::postgres::PgArguments, sqlx::postgres::PgArguments, sqlx::postgres::PgArguments) {
            let _ = pool_ref;
            let mut a1 = sqlx::postgres::PgArguments::default();
            let mut a2 = sqlx::postgres::PgArguments::default();
            let mut a3 = sqlx::postgres::PgArguments::default();
            let mut a4 = sqlx::postgres::PgArguments::default();

            sqlx::Arguments::add(&mut a1, church_id).unwrap();
            sqlx::Arguments::add(&mut a2, church_id).unwrap();
            sqlx::Arguments::add(&mut a3, church_id).unwrap();
            sqlx::Arguments::add(&mut a4, church_id).unwrap();

            if let Some(df) = filter.date_from {
                sqlx::Arguments::add(&mut a1, df).unwrap();
                sqlx::Arguments::add(&mut a2, df).unwrap();
                sqlx::Arguments::add(&mut a3, df).unwrap();
                sqlx::Arguments::add(&mut a4, df).unwrap();
            }
            if let Some(dt) = filter.date_to {
                sqlx::Arguments::add(&mut a1, dt).unwrap();
                sqlx::Arguments::add(&mut a2, dt).unwrap();
                sqlx::Arguments::add(&mut a3, dt).unwrap();
                sqlx::Arguments::add(&mut a4, dt).unwrap();
            }

            (a1, a2, a3, a4)
        };

        let (a1, a2, a3, a4) = build_args(pool);
        let _ = (has_from, has_to);

        let total_income = sqlx::query_scalar_with::<_, Decimal, _>(&income_sql, a1)
            .fetch_one(pool)
            .await?;

        let total_expense = sqlx::query_scalar_with::<_, Decimal, _>(&expense_sql, a2)
            .fetch_one(pool)
            .await?;

        let income_by_category = sqlx::query_as_with::<_, CategoryAmount, _>(&income_cat_sql, a3)
            .fetch_all(pool)
            .await?;

        let expense_by_category = sqlx::query_as_with::<_, CategoryAmount, _>(&expense_cat_sql, a4)
            .fetch_all(pool)
            .await?;

        let balance = total_income - total_expense;

        Ok(FinancialBalance {
            total_income,
            total_expense,
            balance,
            income_by_category,
            expense_by_category,
        })
    }

    /// Update bank account balance (add for receita, subtract for despesa)
    async fn update_bank_balance(
        pool: &PgPool,
        bank_account_id: Uuid,
        amount: Decimal,
        entry_type: &str,
    ) -> Result<(), AppError> {
        let adjustment = if entry_type == "receita" { amount } else { -amount };

        sqlx::query(
            "UPDATE bank_accounts SET current_balance = current_balance + $1 WHERE id = $2",
        )
        .bind(adjustment)
        .bind(bank_account_id)
        .execute(pool)
        .await?;

        Ok(())
    }

    /// Reverse bank account balance
    async fn reverse_bank_balance(
        pool: &PgPool,
        bank_account_id: Uuid,
        amount: Decimal,
        entry_type: &str,
    ) -> Result<(), AppError> {
        let adjustment = if entry_type == "receita" { -amount } else { amount };

        sqlx::query(
            "UPDATE bank_accounts SET current_balance = current_balance + $1 WHERE id = $2",
        )
        .bind(adjustment)
        .bind(bank_account_id)
        .execute(pool)
        .await?;

        Ok(())
    }
}

pub struct MonthlyClosingService;

impl MonthlyClosingService {
    /// List monthly closings
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<MonthlyClosingSummary>, i64), AppError> {
        let total = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM monthly_closings WHERE church_id = $1",
        )
        .bind(church_id)
        .fetch_one(pool)
        .await?;

        let closings = sqlx::query_as::<_, MonthlyClosingSummary>(
            r#"
            SELECT mc.id, mc.reference_month, mc.total_income, mc.total_expense,
                   mc.balance, mc.previous_balance, mc.accumulated_balance,
                   u.email AS closed_by_name, mc.notes, mc.created_at
            FROM monthly_closings mc
            LEFT JOIN users u ON u.id = mc.closed_by
            WHERE mc.church_id = $1
            ORDER BY mc.reference_month DESC
            LIMIT $2 OFFSET $3
            "#,
        )
        .bind(church_id)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await?;

        Ok((closings, total))
    }

    /// Perform monthly closing
    pub async fn close_month(
        pool: &PgPool,
        church_id: Uuid,
        user_id: Uuid,
        req: &MonthlyClosingRequest,
    ) -> Result<MonthlyClosing, AppError> {
        // Check if already closed
        let existing = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM monthly_closings WHERE church_id = $1 AND reference_month = $2",
        )
        .bind(church_id)
        .bind(req.reference_month)
        .fetch_optional(pool)
        .await?;

        if existing.is_some() {
            return Err(AppError::Conflict(
                "Este mês já foi fechado".into(),
            ));
        }

        // Calculate totals for the month
        let month_start = req.reference_month;
        let month_end = month_start + chrono::Months::new(1) - chrono::Duration::days(1);

        let total_income = sqlx::query_scalar::<_, Decimal>(
            r#"SELECT COALESCE(SUM(amount), 0) FROM financial_entries
               WHERE church_id = $1 AND type = 'receita' AND status = 'confirmado'
               AND deleted_at IS NULL AND entry_date >= $2 AND entry_date <= $3"#,
        )
        .bind(church_id)
        .bind(month_start)
        .bind(month_end)
        .fetch_one(pool)
        .await?;

        let total_expense = sqlx::query_scalar::<_, Decimal>(
            r#"SELECT COALESCE(SUM(amount), 0) FROM financial_entries
               WHERE church_id = $1 AND type = 'despesa' AND status = 'confirmado'
               AND deleted_at IS NULL AND entry_date >= $2 AND entry_date <= $3"#,
        )
        .bind(church_id)
        .bind(month_start)
        .bind(month_end)
        .fetch_one(pool)
        .await?;

        let balance = total_income - total_expense;

        // Get previous month's accumulated balance
        let previous_balance = sqlx::query_scalar::<_, Decimal>(
            r#"SELECT COALESCE(accumulated_balance, 0) FROM monthly_closings
               WHERE church_id = $1 AND reference_month < $2
               ORDER BY reference_month DESC LIMIT 1"#,
        )
        .bind(church_id)
        .bind(req.reference_month)
        .fetch_optional(pool)
        .await?
        .unwrap_or(Decimal::ZERO);

        let accumulated_balance = previous_balance + balance;

        // Mark entries as closed
        sqlx::query(
            r#"UPDATE financial_entries SET is_closed = TRUE, closed_at = NOW(), closed_by = $1
               WHERE church_id = $2 AND entry_date >= $3 AND entry_date <= $4
               AND deleted_at IS NULL AND is_closed = FALSE"#,
        )
        .bind(user_id)
        .bind(church_id)
        .bind(month_start)
        .bind(month_end)
        .execute(pool)
        .await?;

        // Create closing record
        let closing = sqlx::query_as::<_, MonthlyClosing>(
            r#"
            INSERT INTO monthly_closings (church_id, reference_month, total_income, total_expense,
                                          balance, previous_balance, accumulated_balance, closed_by, notes)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(req.reference_month)
        .bind(total_income)
        .bind(total_expense)
        .bind(balance)
        .bind(previous_balance)
        .bind(accumulated_balance)
        .bind(user_id)
        .bind(&req.notes)
        .fetch_one(pool)
        .await?;

        Ok(closing)
    }
}
