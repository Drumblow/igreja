use crate::application::dto::{CreateMemberRequest, MemberFilter, UpdateMemberRequest};
use crate::domain::entities::{Member, MemberSummary};
use crate::errors::AppError;
use chrono::NaiveDate;
use sqlx::postgres::PgArguments;
use sqlx::{Arguments, PgPool};
use uuid::Uuid;

/// A dynamically-typed bind value for building SQL queries at runtime.
#[derive(Clone)]
enum BindValue {
    Text(String),
    Int(i32),
    Date(NaiveDate),
    Uuid(Uuid),
}

/// Helper: bind a list of dynamic values after church_id ($1).
fn build_arguments(church_id: Uuid, values: &[BindValue]) -> PgArguments {
    let mut args = PgArguments::default();
    args.add(church_id).unwrap();
    for v in values {
        match v {
            BindValue::Text(s) => args.add(s.as_str()).unwrap(),
            BindValue::Int(i) => args.add(*i).unwrap(),
            BindValue::Date(d) => args.add(*d).unwrap(),
            BindValue::Uuid(u) => args.add(*u).unwrap(),
        }
    }
    args
}

/// Helper for UPDATE: bind member_id ($1), church_id ($2), then values.
fn build_update_arguments(member_id: Uuid, church_id: Uuid, values: &[BindValue]) -> PgArguments {
    let mut args = PgArguments::default();
    args.add(member_id).unwrap();
    args.add(church_id).unwrap();
    for v in values {
        match v {
            BindValue::Text(s) => args.add(s.as_str()).unwrap(),
            BindValue::Int(i) => args.add(*i).unwrap(),
            BindValue::Date(d) => args.add(*d).unwrap(),
            BindValue::Uuid(u) => args.add(*u).unwrap(),
        }
    }
    args
}

pub struct MemberService;

impl MemberService {
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: &MemberFilter,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<MemberSummary>, i64), AppError> {
        // Build dynamic WHERE conditions
        let mut conditions: Vec<String> = vec![
            "m.church_id = $1".to_string(),
            "m.deleted_at IS NULL".to_string(),
        ];
        let mut bind_values: Vec<BindValue> = vec![];
        let mut param_index = 2u32;

        if let Some(ref status) = filter.status {
            conditions.push(format!("m.status = ${param_index}"));
            bind_values.push(BindValue::Text(status.clone()));
            param_index += 1;
        }
        if let Some(ref gender) = filter.gender {
            conditions.push(format!("m.gender = ${param_index}"));
            bind_values.push(BindValue::Text(gender.clone()));
            param_index += 1;
        }
        if let Some(ref marital_status) = filter.marital_status {
            conditions.push(format!("m.marital_status = ${param_index}"));
            bind_values.push(BindValue::Text(marital_status.clone()));
            param_index += 1;
        }
        if let Some(ref role_position) = filter.role_position {
            conditions.push(format!("m.role_position = ${param_index}"));
            bind_values.push(BindValue::Text(role_position.clone()));
            param_index += 1;
        }
        if let Some(ref neighborhood) = filter.neighborhood {
            conditions.push(format!(
                "unaccent(m.neighborhood) ILIKE '%' || unaccent(${param_index}) || '%'"
            ));
            bind_values.push(BindValue::Text(neighborhood.clone()));
            param_index += 1;
        }
        if let Some(search_term) = search {
            conditions.push(format!(
                "unaccent(m.full_name) ILIKE '%' || unaccent(${param_index}) || '%'"
            ));
            bind_values.push(BindValue::Text(search_term.clone()));
            param_index += 1;
        }
        if let Some(month) = filter.birth_month {
            conditions.push(format!(
                "EXTRACT(MONTH FROM m.birth_date) = ${param_index}"
            ));
            bind_values.push(BindValue::Int(month));
            param_index += 1;
        }
        if let Some(age_min) = filter.age_min {
            conditions.push(format!(
                "EXTRACT(YEAR FROM AGE(m.birth_date)) >= ${param_index}"
            ));
            bind_values.push(BindValue::Int(age_min));
            param_index += 1;
        }
        if let Some(age_max) = filter.age_max {
            conditions.push(format!(
                "EXTRACT(YEAR FROM AGE(m.birth_date)) <= ${param_index}"
            ));
            bind_values.push(BindValue::Int(age_max));
            param_index += 1;
        }
        if let Some(ref entry_from) = filter.entry_date_from {
            conditions.push(format!("m.entry_date >= ${param_index}"));
            bind_values.push(BindValue::Date(*entry_from));
            param_index += 1;
        }
        if let Some(ref entry_to) = filter.entry_date_to {
            conditions.push(format!("m.entry_date <= ${param_index}"));
            bind_values.push(BindValue::Date(*entry_to));
            param_index += 1;
        }
        if let Some(congregation_id) = filter.congregation_id {
            conditions.push(format!("m.congregation_id = ${param_index}"));
            bind_values.push(BindValue::Uuid(congregation_id));
            param_index += 1;
        }

        let _ = param_index;

        let where_clause = conditions.join(" AND ");

        let count_sql = format!("SELECT COUNT(*) FROM members m WHERE {where_clause}");
        let query_sql = format!(
            "SELECT m.id, m.full_name, m.birth_date, m.gender, m.phone_primary, m.email, m.status, \
             m.role_position, m.photo_url, m.entry_date, m.congregation_id, \
             cg.name AS congregation_name, m.created_at \
             FROM members m \
             LEFT JOIN congregations cg ON cg.id = m.congregation_id \
             WHERE {where_clause} \
             ORDER BY m.full_name ASC LIMIT {limit} OFFSET {offset}"
        );

        // Execute count query
        let count_args = build_arguments(church_id, &bind_values);
        let total = sqlx::query_scalar_with::<_, i64, _>(&count_sql, count_args)
            .fetch_one(pool)
            .await?;

        // Execute data query
        let data_args = build_arguments(church_id, &bind_values);
        let members = sqlx::query_as_with::<_, MemberSummary, _>(&query_sql, data_args)
            .fetch_all(pool)
            .await?;

        Ok((members, total))
    }

    pub async fn get_by_id(pool: &PgPool, church_id: Uuid, member_id: Uuid) -> Result<Member, AppError> {
        let member = sqlx::query_as::<_, Member>(
            "SELECT * FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Membro"))?;

        Ok(member)
    }

    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateMemberRequest,
    ) -> Result<Member, AppError> {
        let member = sqlx::query_as::<_, Member>(
            r#"
            INSERT INTO members (
                church_id, full_name, social_name, birth_date, gender, marital_status,
                cpf, email, phone_primary, phone_secondary,
                zip_code, street, number, complement, neighborhood, city, state,
                profession, workplace, birthplace_city, birthplace_state,
                nationality, education_level, blood_type,
                conversion_date, water_baptism_date, spirit_baptism_date,
                origin_church, entry_date, entry_type, role_position, ordination_date,
                marriage_date, status, notes, congregation_id
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
                $11, $12, $13, $14, $15, $16, $17,
                $18, $19, $20, $21, $22, $23, $24,
                $25, $26, $27, $28, $29, $30, $31, $32,
                $33, $34, $35, $36
            )
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&req.full_name)
        .bind(&req.social_name)
        .bind(req.birth_date)
        .bind(&req.gender)
        .bind(&req.marital_status)
        .bind(&req.cpf)
        .bind(&req.email)
        .bind(&req.phone_primary)
        .bind(&req.phone_secondary)
        .bind(&req.zip_code)
        .bind(&req.street)
        .bind(&req.number)
        .bind(&req.complement)
        .bind(&req.neighborhood)
        .bind(&req.city)
        .bind(&req.state)
        .bind(&req.profession)
        .bind(&req.workplace)
        .bind(&req.birthplace_city)
        .bind(&req.birthplace_state)
        .bind(&req.nationality)
        .bind(&req.education_level)
        .bind(&req.blood_type)
        .bind(req.conversion_date)
        .bind(req.water_baptism_date)
        .bind(req.spirit_baptism_date)
        .bind(&req.origin_church)
        .bind(req.entry_date)
        .bind(&req.entry_type)
        .bind(&req.role_position)
        .bind(req.ordination_date)
        .bind(req.marriage_date)
        .bind(req.status.as_deref().unwrap_or("ativo"))
        .bind(&req.notes)
        .bind(req.congregation_id)
        .fetch_one(pool)
        .await?;

        Ok(member)
    }

    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        member_id: Uuid,
        req: &UpdateMemberRequest,
    ) -> Result<Member, AppError> {
        // First verify the member exists
        let _existing = Self::get_by_id(pool, church_id, member_id).await?;

        // Build SET clauses dynamically — only update provided fields
        let mut set_clauses: Vec<String> = Vec::new();
        let mut bind_values: Vec<BindValue> = Vec::new();
        let mut param_index = 3u32; // $1 = member_id, $2 = church_id

        macro_rules! set_field_str {
            ($field:ident) => {
                if let Some(ref val) = req.$field {
                    set_clauses.push(format!("{} = ${}", stringify!($field), param_index));
                    bind_values.push(BindValue::Text(val.clone()));
                    param_index += 1;
                }
            };
        }

        macro_rules! set_field_date {
            ($field:ident) => {
                if let Some(val) = req.$field {
                    set_clauses.push(format!("{} = ${}", stringify!($field), param_index));
                    bind_values.push(BindValue::Date(val));
                    param_index += 1;
                }
            };
        }

        set_field_str!(full_name);
        set_field_str!(social_name);
        set_field_date!(birth_date);
        set_field_str!(gender);
        set_field_str!(marital_status);
        set_field_str!(cpf);
        set_field_str!(email);
        set_field_str!(phone_primary);
        set_field_str!(phone_secondary);
        set_field_str!(zip_code);
        set_field_str!(street);
        set_field_str!(number);
        set_field_str!(complement);
        set_field_str!(neighborhood);
        set_field_str!(city);
        set_field_str!(state);
        set_field_str!(profession);
        set_field_str!(workplace);
        set_field_str!(birthplace_city);
        set_field_str!(birthplace_state);
        set_field_str!(nationality);
        set_field_str!(education_level);
        set_field_str!(blood_type);
        set_field_date!(conversion_date);
        set_field_date!(water_baptism_date);
        set_field_date!(spirit_baptism_date);
        set_field_str!(origin_church);
        set_field_date!(entry_date);
        set_field_str!(entry_type);
        set_field_str!(role_position);
        set_field_date!(ordination_date);
        set_field_date!(marriage_date);
        set_field_str!(status);
        set_field_str!(status_reason);
        set_field_str!(notes);

        // Handle congregation_id (UUID field)
        if let Some(congregation_id) = req.congregation_id {
            set_clauses.push(format!("congregation_id = ${}", param_index));
            bind_values.push(BindValue::Uuid(congregation_id));
            param_index += 1;
        }

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, member_id).await;
        }

        // If status changed, update status_changed_at
        if req.status.is_some() {
            set_clauses.push("status_changed_at = NOW()".to_string());
        }

        let sql = format!(
            "UPDATE members SET {} WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL RETURNING *",
            set_clauses.join(", ")
        );

        let args = build_update_arguments(member_id, church_id, &bind_values);
        let member = sqlx::query_as_with::<_, Member, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Ok(member)
    }

    pub async fn delete(pool: &PgPool, church_id: Uuid, member_id: Uuid) -> Result<(), AppError> {
        let result = sqlx::query(
            "UPDATE members SET deleted_at = NOW() WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(member_id)
        .bind(church_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Membro"));
        }

        Ok(())
    }
}
