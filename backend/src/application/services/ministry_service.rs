use crate::application::dto::{AddMinistryMemberRequest, CreateMinistryRequest, UpdateMinistryRequest};
use crate::domain::entities::{MemberMinistry, Ministry, MinistryMemberInfo, MinistrySummary};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct MinistryService;

impl MinistryService {
    /// List ministries with leader name and member count
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        search: &Option<String>,
        is_active: Option<bool>,
        congregation_id: Option<Uuid>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<MinistrySummary>, i64), AppError> {
        let mut conditions = vec!["mi.church_id = $1".to_string()];
        let mut param_idx = 2u32;

        if is_active.is_some() {
            conditions.push(format!("mi.is_active = ${param_idx}"));
            param_idx += 1;
        }

        if congregation_id.is_some() {
            conditions.push(format!("mi.congregation_id = ${param_idx}"));
            param_idx += 1;
        }

        if search.is_some() {
            conditions.push(format!(
                "unaccent(mi.name) ILIKE '%' || unaccent(${param_idx}) || '%'"
            ));
            param_idx += 1;
        }

        let where_clause = conditions.join(" AND ");

        let count_sql = format!(
            "SELECT COUNT(*) FROM ministries mi WHERE {where_clause}"
        );

        let query_sql = format!(
            r#"
            SELECT mi.id, mi.name, mi.description, mi.leader_id,
                   m.full_name AS leader_name, mi.congregation_id,
                   cg.name AS congregation_name, mi.is_active,
                   (SELECT COUNT(*) FROM member_ministries mm WHERE mm.ministry_id = mi.id AND mm.is_active = TRUE) AS member_count,
                   mi.created_at
            FROM ministries mi
            LEFT JOIN members m ON m.id = mi.leader_id AND m.deleted_at IS NULL
            LEFT JOIN congregations cg ON cg.id = mi.congregation_id
            WHERE {where_clause}
            ORDER BY mi.name ASC
            LIMIT {limit} OFFSET {offset}
            "#
        );

        // Build arguments dynamically
        let mut count_args = sqlx::postgres::PgArguments::default();
        let mut data_args = sqlx::postgres::PgArguments::default();

        sqlx::Arguments::add(&mut count_args, church_id).unwrap();
        sqlx::Arguments::add(&mut data_args, church_id).unwrap();

        if let Some(active) = is_active {
            sqlx::Arguments::add(&mut count_args, active).unwrap();
            sqlx::Arguments::add(&mut data_args, active).unwrap();
        }

        if let Some(cid) = congregation_id {
            sqlx::Arguments::add(&mut count_args, cid).unwrap();
            sqlx::Arguments::add(&mut data_args, cid).unwrap();
        }

        if let Some(term) = search {
            sqlx::Arguments::add(&mut count_args, term.as_str()).unwrap();
            sqlx::Arguments::add(&mut data_args, term.as_str()).unwrap();
        }

        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        let ministries = sqlx::query_as_with::<_, MinistrySummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((ministries, total))
    }

    /// Get ministry by ID
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        ministry_id: Uuid,
    ) -> Result<Ministry, AppError> {
        sqlx::query_as::<_, Ministry>(
            "SELECT * FROM ministries WHERE id = $1 AND church_id = $2",
        )
        .bind(ministry_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Ministério"))
    }

    /// Create a new ministry
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateMinistryRequest,
    ) -> Result<Ministry, AppError> {
        let ministry = sqlx::query_as::<_, Ministry>(
            r#"
            INSERT INTO ministries (church_id, name, description, leader_id, congregation_id)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(&req.description)
        .bind(req.leader_id)
        .bind(req.congregation_id)
        .fetch_one(pool)
        .await?;

        Ok(ministry)
    }

    /// Update a ministry
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        ministry_id: Uuid,
        req: &UpdateMinistryRequest,
    ) -> Result<Ministry, AppError> {
        // Verify exists
        let _existing = Self::get_by_id(pool, church_id, ministry_id).await?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut args = sqlx::postgres::PgArguments::default();
        let mut param_index = 3u32; // $1 = ministry_id, $2 = church_id

        sqlx::Arguments::add(&mut args, ministry_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();

        if let Some(ref name) = req.name {
            set_clauses.push(format!("name = ${param_index}"));
            sqlx::Arguments::add(&mut args, name.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(ref desc) = req.description {
            set_clauses.push(format!("description = ${param_index}"));
            sqlx::Arguments::add(&mut args, desc.as_str()).unwrap();
            param_index += 1;
        }
        if let Some(leader_id) = req.leader_id {
            set_clauses.push(format!("leader_id = ${param_index}"));
            sqlx::Arguments::add(&mut args, leader_id).unwrap();
            param_index += 1;
        }
        if let Some(is_active) = req.is_active {
            set_clauses.push(format!("is_active = ${param_index}"));
            sqlx::Arguments::add(&mut args, is_active).unwrap();
            param_index += 1;
        }
        if let Some(ref congregation_id) = req.congregation_id {
            match congregation_id {
                Some(cid) => {
                    set_clauses.push(format!("congregation_id = ${param_index}"));
                    sqlx::Arguments::add(&mut args, *cid).unwrap();
                    param_index += 1;
                }
                None => {
                    set_clauses.push("congregation_id = NULL".to_string());
                }
            }
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, ministry_id).await;
        }

        let sql = format!(
            "UPDATE ministries SET {} WHERE id = $1 AND church_id = $2 RETURNING *",
            set_clauses.join(", ")
        );

        let ministry = sqlx::query_as_with::<_, Ministry, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(ministry)
    }

    /// Delete a ministry (removes member associations)
    pub async fn delete(pool: &PgPool, church_id: Uuid, ministry_id: Uuid) -> Result<(), AppError> {
        // Deactivate member associations
        sqlx::query(
            "UPDATE member_ministries SET is_active = FALSE, left_at = CURRENT_DATE WHERE ministry_id = $1 AND is_active = TRUE",
        )
        .bind(ministry_id)
        .execute(pool)
        .await?;

        let result = sqlx::query("DELETE FROM ministries WHERE id = $1 AND church_id = $2")
            .bind(ministry_id)
            .bind(church_id)
            .execute(pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Ministério"));
        }

        Ok(())
    }

    /// List members of a ministry
    pub async fn list_members(
        pool: &PgPool,
        church_id: Uuid,
        ministry_id: Uuid,
    ) -> Result<Vec<MinistryMemberInfo>, AppError> {
        // Verify ministry exists
        let _ministry = Self::get_by_id(pool, church_id, ministry_id).await?;

        let members = sqlx::query_as::<_, MinistryMemberInfo>(
            r#"
            SELECT mm.member_id, m.full_name, mm.role_in_ministry, mm.joined_at,
                   m.phone_primary, m.email
            FROM member_ministries mm
            JOIN members m ON m.id = mm.member_id AND m.deleted_at IS NULL
            WHERE mm.ministry_id = $1 AND mm.is_active = TRUE
            ORDER BY m.full_name ASC
            "#,
        )
        .bind(ministry_id)
        .fetch_all(pool)
        .await?;

        Ok(members)
    }

    /// Add a member to a ministry
    pub async fn add_member(
        pool: &PgPool,
        church_id: Uuid,
        ministry_id: Uuid,
        req: &AddMinistryMemberRequest,
    ) -> Result<MemberMinistry, AppError> {
        // Verify ministry exists
        let _ministry = Self::get_by_id(pool, church_id, ministry_id).await?;

        // Verify member exists
        let _member = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(req.member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Membro"))?;

        // Check if already active in this ministry
        let existing = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM member_ministries WHERE member_id = $1 AND ministry_id = $2 AND is_active = TRUE",
        )
        .bind(req.member_id)
        .bind(ministry_id)
        .fetch_optional(pool)
        .await?;

        if existing.is_some() {
            return Err(AppError::Conflict(
                "Membro já participa deste ministério".into(),
            ));
        }

        let mm = sqlx::query_as::<_, MemberMinistry>(
            r#"
            INSERT INTO member_ministries (member_id, ministry_id, role_in_ministry)
            VALUES ($1, $2, $3)
            RETURNING *
            "#,
        )
        .bind(req.member_id)
        .bind(ministry_id)
        .bind(&req.role_in_ministry)
        .fetch_one(pool)
        .await?;

        Ok(mm)
    }

    /// Remove a member from a ministry (soft: sets is_active = false, left_at = today)
    pub async fn remove_member(
        pool: &PgPool,
        church_id: Uuid,
        ministry_id: Uuid,
        member_id: Uuid,
    ) -> Result<(), AppError> {
        // Verify ministry exists
        let _ministry = Self::get_by_id(pool, church_id, ministry_id).await?;

        let result = sqlx::query(
            "UPDATE member_ministries SET is_active = FALSE, left_at = CURRENT_DATE \
             WHERE member_id = $1 AND ministry_id = $2 AND is_active = TRUE",
        )
        .bind(member_id)
        .bind(ministry_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Vínculo membro-ministério"));
        }

        Ok(())
    }
}
