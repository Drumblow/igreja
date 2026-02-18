use crate::application::dto::{
    AddFamilyMemberRequest, CreateFamilyRequest, FamilyMemberInput, UpdateFamilyRequest,
};
use crate::domain::entities::{Family, FamilyDetail, FamilyMemberInfo, FamilyRelationship};
use crate::errors::AppError;
use sqlx::PgPool;
use uuid::Uuid;

pub struct FamilyService;

impl FamilyService {
    /// List all families for a church with pagination
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        search: &Option<String>,
        limit: i64,
        offset: i64,
    ) -> Result<(Vec<Family>, i64), AppError> {
        let (families, total) = if let Some(term) = search {
            let pattern = format!("%{term}%");
            let total = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM families WHERE church_id = $1 AND unaccent(name) ILIKE '%' || unaccent($2) || '%'",
            )
            .bind(church_id)
            .bind(&pattern)
            .fetch_one(pool)
            .await?;

            let families = sqlx::query_as::<_, Family>(
                "SELECT * FROM families WHERE church_id = $1 AND unaccent(name) ILIKE '%' || unaccent($2) || '%' \
                 ORDER BY name ASC LIMIT $3 OFFSET $4",
            )
            .bind(church_id)
            .bind(&pattern)
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await?;

            (families, total)
        } else {
            let total = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM families WHERE church_id = $1",
            )
            .bind(church_id)
            .fetch_one(pool)
            .await?;

            let families = sqlx::query_as::<_, Family>(
                "SELECT * FROM families WHERE church_id = $1 ORDER BY name ASC LIMIT $2 OFFSET $3",
            )
            .bind(church_id)
            .bind(limit)
            .bind(offset)
            .fetch_all(pool)
            .await?;

            (families, total)
        };

        Ok((families, total))
    }

    /// Get family detail with all members
    pub async fn get_by_id(
        pool: &PgPool,
        church_id: Uuid,
        family_id: Uuid,
    ) -> Result<FamilyDetail, AppError> {
        let family = sqlx::query_as::<_, Family>(
            "SELECT * FROM families WHERE id = $1 AND church_id = $2",
        )
        .bind(family_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Família"))?;

        let members = sqlx::query_as::<_, FamilyMemberInfo>(
            r#"
            SELECT fr.member_id, m.full_name, fr.relationship,
                   m.phone_primary, m.email, m.birth_date
            FROM family_relationships fr
            JOIN members m ON m.id = fr.member_id AND m.deleted_at IS NULL
            WHERE fr.family_id = $1
            ORDER BY 
                CASE fr.relationship 
                    WHEN 'chefe' THEN 1 
                    WHEN 'conjuge' THEN 2 
                    ELSE 3 
                END, m.full_name
            "#,
        )
        .bind(family_id)
        .fetch_all(pool)
        .await?;

        Ok(FamilyDetail {
            id: family.id,
            church_id: family.church_id,
            name: family.name,
            head_id: family.head_id,
            zip_code: family.zip_code,
            street: family.street,
            number: family.number,
            complement: family.complement,
            neighborhood: family.neighborhood,
            city: family.city,
            state: family.state,
            notes: family.notes,
            created_at: family.created_at,
            updated_at: family.updated_at,
            members,
        })
    }

    /// Create a new family, optionally adding members
    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: &CreateFamilyRequest,
    ) -> Result<FamilyDetail, AppError> {
        let family = sqlx::query_as::<_, Family>(
            r#"
            INSERT INTO families (church_id, name, head_id, zip_code, street, number, complement, neighborhood, city, state, notes)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING *
            "#,
        )
        .bind(church_id)
        .bind(&req.name)
        .bind(req.head_id)
        .bind(&req.zip_code)
        .bind(&req.street)
        .bind(&req.number)
        .bind(&req.complement)
        .bind(&req.neighborhood)
        .bind(&req.city)
        .bind(&req.state)
        .bind(&req.notes)
        .fetch_one(pool)
        .await?;

        // Add members if provided
        if let Some(ref members) = req.members {
            for m in members {
                Self::add_member_internal(pool, family.id, &m.member_id, &m.relationship).await?;
                // Update member's family_id
                sqlx::query("UPDATE members SET family_id = $1 WHERE id = $2 AND church_id = $3 AND deleted_at IS NULL")
                    .bind(family.id)
                    .bind(m.member_id)
                    .bind(church_id)
                    .execute(pool)
                    .await?;
            }
        }

        Self::get_by_id(pool, church_id, family.id).await
    }

    /// Update a family
    pub async fn update(
        pool: &PgPool,
        church_id: Uuid,
        family_id: Uuid,
        req: &UpdateFamilyRequest,
    ) -> Result<FamilyDetail, AppError> {
        // Verify exists
        let _existing = sqlx::query_as::<_, Family>(
            "SELECT * FROM families WHERE id = $1 AND church_id = $2",
        )
        .bind(family_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Família"))?;

        let mut set_clauses: Vec<String> = Vec::new();
        let mut param_index = 3u32; // $1 = family_id, $2 = church_id

        macro_rules! set_field {
            ($field:ident, $val:expr) => {
                if $val.is_some() {
                    set_clauses.push(format!("{} = ${}", stringify!($field), param_index));
                    param_index += 1;
                }
            };
        }

        set_field!(name, &req.name);
        set_field!(head_id, &req.head_id);
        set_field!(zip_code, &req.zip_code);
        set_field!(street, &req.street);
        set_field!(number, &req.number);
        set_field!(complement, &req.complement);
        set_field!(neighborhood, &req.neighborhood);
        set_field!(city, &req.city);
        set_field!(state, &req.state);
        set_field!(notes, &req.notes);

        let _ = param_index;

        if set_clauses.is_empty() {
            return Self::get_by_id(pool, church_id, family_id).await;
        }

        let sql = format!(
            "UPDATE families SET {} WHERE id = $1 AND church_id = $2 RETURNING *",
            set_clauses.join(", ")
        );

        // Build args manually
        let mut args = sqlx::postgres::PgArguments::default();
        sqlx::Arguments::add(&mut args, family_id).unwrap();
        sqlx::Arguments::add(&mut args, church_id).unwrap();
        if let Some(ref v) = req.name { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(v) = req.head_id { sqlx::Arguments::add(&mut args, v).unwrap(); }
        if let Some(ref v) = req.zip_code { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.street { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.number { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.complement { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.neighborhood { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.city { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.state { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }
        if let Some(ref v) = req.notes { sqlx::Arguments::add(&mut args, v.as_str()).unwrap(); }

        let _family = sqlx::query_as_with::<_, Family, _>(&sql, args)
            .fetch_one(pool)
            .await?;

        Self::get_by_id(pool, church_id, family_id).await
    }

    /// Delete a family (unlinks members but doesn't delete them)
    pub async fn delete(pool: &PgPool, church_id: Uuid, family_id: Uuid) -> Result<(), AppError> {
        // Unlink all members
        sqlx::query("UPDATE members SET family_id = NULL WHERE family_id = $1 AND church_id = $2")
            .bind(family_id)
            .bind(church_id)
            .execute(pool)
            .await?;

        // Delete relationships
        sqlx::query("DELETE FROM family_relationships WHERE family_id = $1")
            .bind(family_id)
            .execute(pool)
            .await?;

        // Delete the family
        let result = sqlx::query("DELETE FROM families WHERE id = $1 AND church_id = $2")
            .bind(family_id)
            .bind(church_id)
            .execute(pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Família"));
        }

        Ok(())
    }

    /// Add a member to a family
    pub async fn add_member(
        pool: &PgPool,
        church_id: Uuid,
        family_id: Uuid,
        req: &AddFamilyMemberRequest,
    ) -> Result<FamilyRelationship, AppError> {
        // Verify family exists
        let _family = sqlx::query_as::<_, Family>(
            "SELECT * FROM families WHERE id = $1 AND church_id = $2",
        )
        .bind(family_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Família"))?;

        // Verify member exists
        let _member = sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM members WHERE id = $1 AND church_id = $2 AND deleted_at IS NULL",
        )
        .bind(req.member_id)
        .bind(church_id)
        .fetch_optional(pool)
        .await?
        .ok_or_else(|| AppError::not_found("Membro"))?;

        // Check if member is already in another family
        let existing_family = sqlx::query_scalar::<_, Option<Uuid>>(
            "SELECT family_id FROM members WHERE id = $1 AND family_id IS NOT NULL AND family_id != $2",
        )
        .bind(req.member_id)
        .bind(family_id)
        .fetch_optional(pool)
        .await?;

        if let Some(Some(_)) = existing_family {
            return Err(AppError::Conflict(
                "Membro já pertence a outra família. Remova-o primeiro.".into(),
            ));
        }

        let rel = Self::add_member_internal(pool, family_id, &req.member_id, &req.relationship).await?;

        // Update member's family_id
        sqlx::query("UPDATE members SET family_id = $1 WHERE id = $2 AND church_id = $3")
            .bind(family_id)
            .bind(req.member_id)
            .bind(church_id)
            .execute(pool)
            .await?;

        Ok(rel)
    }

    /// Remove a member from a family
    pub async fn remove_member(
        pool: &PgPool,
        church_id: Uuid,
        family_id: Uuid,
        member_id: Uuid,
    ) -> Result<(), AppError> {
        // Delete the relationship
        let result = sqlx::query(
            "DELETE FROM family_relationships WHERE family_id = $1 AND member_id = $2",
        )
        .bind(family_id)
        .bind(member_id)
        .execute(pool)
        .await?;

        if result.rows_affected() == 0 {
            return Err(AppError::not_found("Relacionamento familiar"));
        }

        // Clear the member's family_id
        sqlx::query("UPDATE members SET family_id = NULL WHERE id = $1 AND church_id = $2")
            .bind(member_id)
            .bind(church_id)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// Internal helper to insert a family_relationships row
    async fn add_member_internal(
        pool: &PgPool,
        family_id: Uuid,
        member_id: &Uuid,
        relationship: &str,
    ) -> Result<FamilyRelationship, AppError> {
        let rel = sqlx::query_as::<_, FamilyRelationship>(
            r#"
            INSERT INTO family_relationships (family_id, member_id, relationship)
            VALUES ($1, $2, $3)
            ON CONFLICT (family_id, member_id) DO UPDATE SET relationship = $3
            RETURNING *
            "#,
        )
        .bind(family_id)
        .bind(member_id)
        .bind(relationship)
        .fetch_one(pool)
        .await?;

        Ok(rel)
    }
}
