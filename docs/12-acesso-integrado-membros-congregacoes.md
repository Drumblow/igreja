# 🔐 Acesso Integrado: Membros, Congregações e Controle de Acesso

> **Data de criação:** 21 de fevereiro de 2026  
> **Versão do documento:** 1.0  
> **Status:** 📋 Planejado  
> **Módulo afetado:** Core (Auth), Membros, Congregações, Todos os módulos  
> **Prioridade:** 🔴 Crítica  
> **Dependências:** Módulo de Congregações (✅ Implementado)

---

## Sumário

1. [Diagnóstico do Estado Atual](#1-diagnóstico-do-estado-atual)
2. [Visão Geral da Solução](#2-visão-geral-da-solução)
3. [Fase 1 — Correção do Bug de Wildcard nas Permissões](#3-fase-1--correção-do-bug-de-wildcard-nas-permissões)
4. [Fase 2 — Login Automático para Membros](#4-fase-2--login-automático-para-membros)
5. [Fase 3 — Controle de Acesso por Congregação (Server-Side)](#5-fase-3--controle-de-acesso-por-congregação-server-side)
6. [Fase 4 — Experiência de Login por Perfil](#6-fase-4--experiência-de-login-por-perfil)
7. [Fase 5 — UI de Permissões e Navegação por Role](#7-fase-5--ui-de-permissões-e-navegação-por-role)
8. [Fase 6 — Relatórios por Congregação](#8-fase-6--relatórios-por-congregação)
9. [Migrações de Banco de Dados](#9-migrações-de-banco-de-dados)
10. [Regras de Negócio](#10-regras-de-negócio)
11. [Testes e Validação](#11-testes-e-validação)
12. [Checklist de Implementação](#12-checklist-de-implementação)

---

## 1. Diagnóstico do Estado Atual

### 1.1 O que funciona

| Componente | Status | Detalhes |
|-----------|--------|----------|
| Tabela `users` com campo `member_id` | ✅ Existe | Nullable, permite vincular user→member |
| Tabela `user_congregations` | ✅ Existe | Mapeia user↔congregation com papel (`dirigente`, `secretario`, etc.) |
| `congregation_id` em 11 tabelas | ✅ Implementado | members, financial_entries, assets, ebd_classes, etc. |
| Seletor de congregação no frontend | ✅ Funciona | Filtra todos os módulos client-side |
| 7 roles de sistema (seed) | ✅ Existe | super_admin, pastor, secretary, treasurer, asset_manager, ebd_teacher, member |
| JWT com role e permissions | ✅ Funciona | Claims: sub, church_id, role, permissions, exp, iat |
| Relatórios overview/comparação | ✅ Implementados | 2 endpoints de relatório de congregações |

### 1.2 Problemas Críticos Identificados

#### 🔴 BUG-001: Wildcard de permissões não funciona

O `require_permission` faz comparação literal:
```rust
// ATUAL — BUG: "members:*" != "members:create"
claims.permissions.contains(&permission)
```

Roles como `secretary` (que tem `["members:*"]`) **falham** nos checks de `"members:create"`, `"members:update"`, `"members:delete"`. Apenas `super_admin` funciona corretamente (bypass por nome de role).

**Impacto:** Pastor, secretário, tesoureiro — todos os roles não-admin — **não conseguem executar operações de escrita** nos módulos que deveriam ter permissão.

#### 🔴 BUG-002: Controle de acesso por congregação inexistente no backend

A tabela `user_congregations` existe mas **nunca é consultada** durante queries de dados. Qualquer usuário autenticado pode acessar dados de qualquer congregação via API passando `congregation_id` diferente.

**Impacto:** Um dirigente de congregação consegue acessar dados financeiros, membros e patrimônio de TODAS as congregações. A segurança é 100% client-side.

#### 🟡 GAP-001: Membros não recebem login

Cadastrar um membro **não cria conta de usuário**. Os 210 membros cadastrados não têm acesso ao sistema. A criação de user é manual, separada, e feita apenas pelo super_admin.

#### 🟡 GAP-002: Frontend não esconde módulos por role

Todos os itens do menu aparecem para todos os usuários. Um tesoureiro vê "Membros", "EBD", "Patrimônio" no menu, mesmo sem permissão.

#### 🟡 GAP-003: Congregação ativa não persiste

Se o usuário recarrega a página, perde a seleção de congregação. O endpoint `POST /api/v1/user/active-congregation` valida mas **não salva** a preferência.

#### 🟡 GAP-004: Login não auto-seleciona congregação

Dirigentes deveriam iniciar já com sua congregação selecionada. Hoje todos começam com "Todas (Geral)".

---

## 2. Visão Geral da Solução

### 2.1 Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE ACESSO                         │
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌───────────────────┐     │
│  │  Member   │───▶│   User    │───▶│  JWT Claims       │     │
│  │ (pessoa)  │    │ (login)   │    │  + congregation   │     │
│  └──────────┘    └──────────┘    │    scope           │     │
│       │               │          └───────────────────┘     │
│       │               │                    │                │
│       ▼               ▼                    ▼                │
│  ┌──────────┐    ┌──────────┐    ┌───────────────────┐     │
│  │congregation│   │user_cong │    │  Middleware        │     │
│  │  _id      │    │regations │    │  enforce_scope()  │     │
│  └──────────┘    └──────────┘    └───────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Princípios de Design

| Princípio | Decisão |
|-----------|---------|
| **Geração de login** | Ao cadastrar membro com email, o sistema OPCIONALMENTE gera user vinculado |
| **Senha inicial** | Gerada automaticamente (8 chars alfanuméricos) ou definida pelo admin |
| **Role padrão** | Membro recebe role `member` (profile:read, profile:write) |
| **Promoção de acesso** | Admin pode promover membro a qualquer role (secretary, treasurer, etc.) |
| **Escopo de congregação** | Embutido no JWT e enforçado no middleware do backend |
| **Visão admin** | `super_admin` e `pastor` sempre veem TUDO, seletor de congregação é filtro opcional |
| **Visão líder** | `dirigente` de congregação vê APENAS sua congregação, sem opção "Todas" |
| **Visão membro** | `member` vê apenas seu perfil e dados da sua congregação (quando aplicável) |

### 2.3 Fases de Implementação

```
Fase 1: Correção do bug de wildcard ───────── 🔴 Crítico (pré-requisito)
    │
Fase 2: Login automático para membros ─────── 🔴 Crítico
    │
Fase 3: Controle de acesso por congregação ── 🔴 Crítico (segurança)
    │
Fase 4: Experiência de login por perfil ───── 🟡 Importante (UX)
    │
Fase 5: UI de permissões e navegação ──────── 🟡 Importante (UX)
    │
Fase 6: Relatórios por congregação ────────── 🟢 Melhoria
```

---

## 3. Fase 1 — Correção do Bug de Wildcard nas Permissões

### 3.1 Problema

```rust
// backend/src/api/middleware.rs — ATUAL
pub fn require_permission(claims: &Claims, permission: &str) -> Result<(), AppError> {
    if claims.role == "super_admin" || claims.permissions.contains(&permission.to_string()) {
        Ok(())
    } else {
        Err(AppError::forbidden("Sem permissão"))
    }
}
```

`"members:*".contains("members:create")` → `false` — wildcards não funcionam.

### 3.2 Solução

```rust
// backend/src/api/middleware.rs — CORRIGIDO
pub fn require_permission(claims: &Claims, permission: &str) -> Result<(), AppError> {
    // super_admin bypass total
    if claims.role == "super_admin" {
        return Ok(());
    }
    
    // Permissão global (raro, mas possível em roles customizados)
    if claims.permissions.contains(&"*".to_string()) {
        return Ok(());
    }
    
    // Verificação exata
    if claims.permissions.contains(&permission.to_string()) {
        return Ok(());
    }
    
    // Verificação de wildcard: "members:*" deve dar match em "members:create"
    let parts: Vec<&str> = permission.split(':').collect();
    if parts.len() == 2 {
        let wildcard = format!("{}:*", parts[0]);
        if claims.permissions.contains(&wildcard) {
            return Ok(());
        }
    }
    
    Err(AppError::forbidden("Sem permissão para esta operação"))
}
```

### 3.3 Testes necessários

| Cenário | Input | Esperado |
|---------|-------|----------|
| Admin bypass | role=super_admin, perm="anything" | ✅ Ok |
| Wildcard match | perms=["members:*"], check "members:create" | ✅ Ok |
| Wildcard match | perms=["members:*"], check "members:delete" | ✅ Ok |
| Exact match | perms=["financial:read"], check "financial:read" | ✅ Ok |
| Cross-module deny | perms=["members:*"], check "financial:read" | ❌ Denied |
| No permission | perms=["profile:read"], check "members:create" | ❌ Denied |

### 3.4 Arquivos a alterar

| Arquivo | Mudança |
|---------|---------|
| `backend/src/api/middleware.rs` | Reescrever `require_permission` com suporte a wildcard |

**Estimativa:** 30 minutos. Risco: baixo. Sem migração.

---

## 4. Fase 2 — Login Automático para Membros

### 4.1 Conceito

Quando um membro é cadastrado **com email**, o sistema oferece a opção de criar automaticamente uma conta de login. Para membros cadastrados **sem email**, o login pode ser criado depois.

### 4.2 Fluxo de Criação de Membro (novo)

```
┌─────────────────────────────────────────────────────┐
│ Formulário de Cadastro de Membro                    │
│                                                     │
│  Nome: [João da Silva        ]                      │
│  Email: [joao@email.com      ]                      │
│  ...                                                │
│  Congregação: [Paxicá        ▼]                     │
│                                                     │
│  ┌─────────────────────────────────────────┐        │
│  │ ☑ Criar login de acesso ao sistema      │        │
│  │                                         │        │
│  │  Senha inicial: [●●●●●●●●] 🔄 Gerar    │        │
│  │  ☐ Forçar troca de senha no 1º login    │        │
│  │  Role: [Membro           ▼]             │        │
│  └─────────────────────────────────────────┘        │
│                                                     │
│              [ Salvar Membro ]                      │
└─────────────────────────────────────────────────────┘
```

### 4.3 Regras de Negócio

| Regra | ID | Descrição |
|-------|--------|-----------|
| Pré-requisito | RN-LOGIN-001 | O membro **deve ter email** para criar login. Se não tiver, o checkbox fica desabilitado com tooltip "Informe o email do membro para criar login". |
| Unicidade | RN-LOGIN-002 | O email do membro deve ser único na church para criação de user. Se já existe user com esse email, exibir aviso "Este email já possui login" e oferecer vincular ao membro existente. |
| Senha | RN-LOGIN-003 | A senha pode ser informada manualmente (mín. 6 chars) ou gerada automaticamente (8 chars alfanuméricos). O botão 🔄 gera uma nova senha aleatória. |
| Exibição | RN-LOGIN-004 | Após criar, exibir a senha em um modal de confirmação com botão "Copiar" — esta é a ÚNICA vez que a senha é visível em texto claro. |
| Role padrão | RN-LOGIN-005 | Novos logins de membros recebem role `member` por padrão. O admin pode escolher outro role no momento da criação ou promover depois. |
| Vínculo | RN-LOGIN-006 | O `users.member_id` é preenchido automaticamente com o ID do membro. O frontend do membro mostrará seus dados de perfil baseado nesse vínculo. |
| Congregação | RN-LOGIN-007 | Se o membro pertence a uma congregação, ao criar o user, automaticamente insere registro em `user_congregations` com role `viewer` e `is_primary = true`. |
| Troca de senha | RN-LOGIN-008 | Campo `force_password_change` na tabela users (novo). Se true, após login o frontend redireciona para tela de troca de senha obrigatória. |
| Desvinculação | RN-LOGIN-009 | Desativar o membro (status → inativo/desligado) **não** desativa automaticamente o user. São ações independentes, mas o admin recebe notificação. |
| Lote | RN-LOGIN-010 | Deve existir ação em lote: "Criar login para membros selecionados" que gera users para múltiplos membros de uma vez, com senhas aleatórias, exibindo resultado em tabela com botão "Exportar senhas (CSV)". |

### 4.4 Mudanças no Backend

#### 4.4.1 Migração — Campo `force_password_change`

```sql
-- migration: 20260221000000_user_member_integration.sql

-- Campo para forçar troca de senha no primeiro login
ALTER TABLE users ADD COLUMN force_password_change BOOLEAN NOT NULL DEFAULT FALSE;

-- FK formal entre users e members (hoje o campo existe mas sem FK)
-- Nota: Não criar FK hard pois member pode ser deletado (soft delete)
-- Manter como está: campo nullable sem FK, com validação na aplicação

-- Índice para busca rápida de user por member_id
CREATE INDEX IF NOT EXISTS idx_users_member_id ON users(member_id) WHERE member_id IS NOT NULL;
```

#### 4.4.2 Novo DTO — `CreateMemberWithUserRequest`

```rust
// backend/src/application/dto/member_dto.rs — adicionar

#[derive(Debug, Deserialize, Validate)]
pub struct CreateUserForMemberRequest {
    pub password: Option<String>,           // None = gerar automaticamente
    pub role_id: Option<Uuid>,              // None = role "member"
    pub force_password_change: Option<bool>, // Default: true
}
```

#### 4.4.3 Modificar `CreateMemberRequest`

```rust
// Adicionar campo opcional ao CreateMemberRequest existente
pub struct CreateMemberRequest {
    // ... campos existentes ...
    
    /// Se presente, cria login automaticamente para o membro
    pub create_user: Option<CreateUserForMemberRequest>,
}
```

#### 4.4.4 Novo Endpoint — Criar login para membro existente

```
POST /api/v1/members/{member_id}/create-user
```

**Body:**
```json
{
    "password": "senhaOpcional",       // ou null para gerar
    "role_id": "uuid-do-role",         // ou null para role "member"
    "force_password_change": true
}
```

**Response (sucesso):**
```json
{
    "success": true,
    "data": {
        "user_id": "uuid",
        "email": "membro@email.com",
        "role": "member",
        "generated_password": "aB3x9Km2",  // só quando gerada automaticamente
        "force_password_change": true
    }
}
```

**Permissão:** `settings:write` ou `super_admin`

#### 4.4.5 Novo Endpoint — Criar login em lote

```
POST /api/v1/members/batch-create-users
```

**Body:**
```json
{
    "member_ids": ["uuid1", "uuid2", "uuid3"],
    "role_id": null,
    "force_password_change": true
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "created": [
            { "member_id": "uuid1", "email": "a@email.com", "password": "xK8mP2vQ" },
            { "member_id": "uuid2", "email": "b@email.com", "password": "nR4jL7wY" }
        ],
        "skipped": [
            { "member_id": "uuid3", "reason": "Membro não possui email" }
        ],
        "total_created": 2,
        "total_skipped": 1
    }
}
```

#### 4.4.6 Lógica do Service (member_service.rs + auth_service.rs)

```rust
// Pseudocódigo da criação de user para membro
async fn create_user_for_member(
    pool: &PgPool,
    church_id: Uuid,
    member_id: Uuid,
    request: CreateUserForMemberRequest,
) -> Result<CreateUserForMemberResponse, AppError> {
    
    // 1. Buscar membro
    let member = get_member(pool, member_id, church_id).await?;
    
    // 2. Validar email
    let email = member.email.ok_or(
        AppError::validation("Membro não possui email cadastrado")
    )?;
    
    // 3. Verificar se já existe user com este email na church
    let existing = find_user_by_email(pool, &email, church_id).await?;
    if let Some(user) = existing {
        if user.member_id == Some(member_id) {
            return Err(AppError::conflict("Membro já possui login"));
        }
        return Err(AppError::conflict(
            "Email já está em uso por outro usuário"
        ));
    }
    
    // 4. Verificar se membro já tem user vinculado
    let existing_link = find_user_by_member_id(pool, member_id).await?;
    if existing_link.is_some() {
        return Err(AppError::conflict("Membro já possui login vinculado"));
    }
    
    // 5. Resolver role (padrão: member)
    let role_id = match request.role_id {
        Some(id) => id,
        None => get_role_by_name(pool, "member").await?.id,
    };
    
    // 6. Gerar ou usar senha
    let (password, was_generated) = match request.password {
        Some(p) => (p, false),
        None => (generate_random_password(8), true),
    };
    
    // 7. Hash da senha
    let password_hash = hash_password(&password)?;
    
    // 8. Criar user (transação)
    let user_id = sqlx::query!(
        "INSERT INTO users (church_id, member_id, email, password_hash, role_id, 
                           is_active, email_verified, force_password_change)
         VALUES ($1, $2, $3, $4, $5, TRUE, FALSE, $6)
         RETURNING id",
        church_id, member_id, email, password_hash, role_id,
        request.force_password_change.unwrap_or(true)
    ).fetch_one(pool).await?.id;
    
    // 9. Se membro tem congregação, criar registro em user_congregations
    if let Some(cong_id) = member.congregation_id {
        sqlx::query!(
            "INSERT INTO user_congregations (user_id, congregation_id, role_in_congregation, is_primary)
             VALUES ($1, $2, 'viewer', TRUE)
             ON CONFLICT DO NOTHING",
            user_id, cong_id
        ).execute(pool).await?;
    }
    
    // 10. Retornar (inclui senha em claro APENAS se foi gerada)
    Ok(CreateUserForMemberResponse {
        user_id,
        email,
        role: "member".to_string(),
        generated_password: if was_generated { Some(password) } else { None },
        force_password_change: request.force_password_change.unwrap_or(true),
    })
}
```

### 4.5 Mudanças no Frontend

#### 4.5.1 Formulário de Membro — Seção "Acesso ao Sistema"

Adicionar ao final do formulário de criação/edição de membro uma seção colapsável:

```dart
// Dentro do MemberFormPage, após os campos existentes
ExpansionTile(
    title: Text('Acesso ao Sistema'),
    leading: Icon(Icons.login),
    children: [
        // Se membro já tem user vinculado
        if (existingUser != null) ...[
            ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Login ativo: ${existingUser.email}'),
                subtitle: Text('Role: ${existingUser.role}'),
                trailing: PopupMenuButton(/* alterar role, desativar */),
            ),
        ] else ...[
            // Checkbox para criar login
            SwitchListTile(
                title: Text('Criar login de acesso'),
                subtitle: Text(
                    hasEmail 
                        ? 'O membro poderá acessar o sistema' 
                        : 'Informe o email do membro primeiro'
                ),
                value: createLogin,
                onChanged: hasEmail ? (v) => setState(() => createLogin = v) : null,
            ),
            if (createLogin) ...[
                // Campo de senha
                TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Senha inicial',
                        suffixIcon: IconButton(
                            icon: Icon(Icons.refresh),
                            tooltip: 'Gerar senha aleatória',
                            onPressed: () => generatePassword(),
                        ),
                    ),
                ),
                // Checkbox forçar troca
                CheckboxListTile(
                    title: Text('Forçar troca de senha no primeiro login'),
                    value: forcePasswordChange,
                    onChanged: (v) => setState(() => forcePasswordChange = v!),
                ),
                // Dropdown de role
                DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Nível de acesso'),
                    value: selectedRole,
                    items: availableRoles.map((r) => DropdownMenuItem(
                        value: r.id, child: Text(r.displayName),
                    )).toList(),
                ),
            ],
        ],
    ],
)
```

#### 4.5.2 Lista de Membros — Ação em Lote

Na tela de listagem de membros, quando membros são selecionados (multi-select), adicionar ação:

```
[toolbar de seleção]
  ☑ 5 selecionados    [Criar Login] [Atribuir Congregação] [Excluir]
```

#### 4.5.3 Modal de Confirmação com Senhas

Após criar login(s), exibir modal:

```
┌────────────────────────────────────────────────┐
│ ✅ Login(s) criado(s) com sucesso!             │
│                                                │
│  Membro           Email              Senha     │
│  ─────────────────────────────────────────     │
│  João da Silva    joao@email.com     aB3x9Km2 │
│  Maria Santos     maria@email.com    nR4jL7wY │
│                                                │
│  ⚠️ Anote as senhas! Elas não serão exibidas   │
│  novamente.                                    │
│                                                │
│          [Copiar Tudo]  [Exportar CSV]  [OK]   │
└────────────────────────────────────────────────┘
```

#### 4.5.4 Tela de Troca de Senha Obrigatória

```dart
// Nova rota: /force-change-password
// Exibida automaticamente após login se user.force_password_change == true
// Campos: Nova senha + Confirmar nova senha
// Após sucesso: chama endpoint PUT /api/v1/auth/change-password
// Backend seta force_password_change = false
```

### 4.6 Arquivos a Alterar/Criar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `backend/migrations/20260221000000_user_member_integration.sql` | **CRIAR** | Campo `force_password_change`, índice `idx_users_member_id` |
| `backend/src/application/dto/member_dto.rs` | **ALTERAR** | Adicionar `CreateUserForMemberRequest`, `CreateUserForMemberResponse`, campo em `CreateMemberRequest` |
| `backend/src/application/dto/auth_dto.rs` | **ALTERAR** | Adicionar `ChangePasswordRequest`, `force_password_change` no LoginResponse user info |
| `backend/src/application/services/member_service.rs` | **ALTERAR** | Lógica de criação de user vinculado ao membro |
| `backend/src/application/services/auth_service.rs` | **ALTERAR** | Incluir `force_password_change` no login, endpoint de troca de senha |
| `backend/src/api/handlers/member_handler.rs` | **ALTERAR** | Novos endpoints: `create_user_for_member`, `batch_create_users` |
| `backend/src/api/handlers/auth_handler.rs` | **ALTERAR** | Endpoint `change_password` |
| `backend/src/main.rs` | **ALTERAR** | Registrar novas rotas |
| `frontend/lib/features/members/presentation/pages/member_form_page.dart` | **ALTERAR** | Seção "Acesso ao Sistema" |
| `frontend/lib/features/members/presentation/pages/member_list_page.dart` | **ALTERAR** | Ação em lote "Criar Login" |
| `frontend/lib/features/members/data/services/member_service.dart` | **ALTERAR** | Novos métodos de API |
| `frontend/lib/features/auth/presentation/force_change_password_screen.dart` | **CRIAR** | Tela de troca de senha obrigatória |
| `frontend/lib/features/auth/bloc/auth_bloc.dart` | **ALTERAR** | Detectar `force_password_change` e redirecionar |
| `frontend/lib/core/router/app_router.dart` | **ALTERAR** | Nova rota `/force-change-password` com guard |

**Estimativa:** 3-4 dias. Risco: médio. Requer migração.

---

## 5. Fase 3 — Controle de Acesso por Congregação (Server-Side)

### 5.1 Conceito

O controle de acesso por congregação funciona em **duas camadas**:

```
Camada 1: ROLE (O que o usuário pode fazer?)
    └── members:*, financial:read, etc.

Camada 2: SCOPE (Em qual congregação pode fazer?)
    └── congregation_ids + scope_type
```

### 5.2 Tipos de Escopo

| `scope_type` | Significado | Quem recebe |
|-------------|-------------|-------------|
| `global` | Acessa dados de **todas** as congregações | `super_admin`, `pastor` |
| `congregation` | Acessa dados **apenas** das congregações em `user_congregations` | `secretary`, `treasurer`, `asset_manager`, `ebd_teacher` com vínculo a congregação |
| `self` | Acessa **apenas** o próprio perfil | `member` |

### 5.3 Mudança no JWT Claims

```rust
// ANTES
pub struct Claims {
    pub sub: String,
    pub church_id: String,
    pub role: String,
    pub permissions: Vec<String>,
    pub exp: i64,
    pub iat: i64,
}

// DEPOIS
pub struct Claims {
    pub sub: String,
    pub church_id: String,
    pub role: String,
    pub permissions: Vec<String>,
    
    // NOVOS CAMPOS:
    pub scope_type: String,              // "global", "congregation", "self"
    pub congregation_ids: Vec<String>,   // UUIDs das congregações permitidas
    pub primary_congregation_id: Option<String>, // Congregação padrão (is_primary)
    pub member_id: Option<String>,       // ID do membro vinculado (para scope "self")
    
    pub exp: i64,
    pub iat: i64,
}
```

### 5.4 Lógica de Determinação de Escopo no Login

```rust
async fn determine_scope(pool: &PgPool, user: &User) -> ScopeInfo {
    // Regra 1: super_admin e pastor são SEMPRE global
    if user.role_name == "super_admin" || user.role_name == "pastor" {
        return ScopeInfo {
            scope_type: "global",
            congregation_ids: vec![],
            primary_congregation_id: None,
            member_id: user.member_id,
        };
    }
    
    // Regra 2: role "member" é SEMPRE self
    if user.role_name == "member" {
        let primary = get_primary_congregation(pool, user.id).await;
        return ScopeInfo {
            scope_type: "self",
            congregation_ids: primary.map(|c| vec![c.id]).unwrap_or_default(),
            primary_congregation_id: primary.map(|c| c.id),
            member_id: user.member_id,
        };
    }
    
    // Regra 3: Outros roles — verificar user_congregations
    let user_congs = get_user_congregations(pool, user.id).await;
    
    if user_congs.is_empty() {
        // Sem vínculo de congregação = global (legado, para não quebrar)
        return ScopeInfo {
            scope_type: "global",
            congregation_ids: vec![],
            primary_congregation_id: None,
            member_id: user.member_id,
        };
    }
    
    let primary = user_congs.iter().find(|c| c.is_primary);
    ScopeInfo {
        scope_type: "congregation",
        congregation_ids: user_congs.iter().map(|c| c.congregation_id).collect(),
        primary_congregation_id: primary.map(|c| c.congregation_id),
        member_id: user.member_id,
    }
}
```

### 5.5 Novo Middleware — `enforce_congregation_scope`

```rust
/// Middleware que FORÇAR filtragem por congregação baseado no escopo do JWT.
/// 
/// Deve ser chamado APÓS auth_middleware e ANTES da lógica de negócio.
/// Retorna a lista de congregation_ids permitidos, ou None se o escopo é global.
pub fn get_allowed_congregations(claims: &Claims) -> Option<Vec<Uuid>> {
    match claims.scope_type.as_str() {
        "global" => None,  // Sem restrição — administrador vê tudo
        "congregation" => {
            // Retorna apenas as congregações vinculadas
            Some(
                claims.congregation_ids
                    .iter()
                    .filter_map(|id| Uuid::parse_str(id).ok())
                    .collect()
            )
        },
        "self" => {
            // Para escopo "self", retorna a congregação primária
            // (membros veem dados da sua congregação, mas filtrado por member_id na camada de serviço)
            claims.primary_congregation_id
                .as_ref()
                .and_then(|id| Uuid::parse_str(id).ok())
                .map(|id| vec![id])
                .or(Some(vec![]))
        },
        _ => Some(vec![]),  // Escopo desconhecido = sem acesso
    }
}

/// Verifica se o usuário pode acessar uma congregação específica.
pub fn can_access_congregation(claims: &Claims, congregation_id: Option<Uuid>) -> bool {
    match claims.scope_type.as_str() {
        "global" => true,
        "congregation" => {
            match congregation_id {
                // congregation_id = NULL = Sede/Geral — negar para escopo congregation
                // (a menos que a sede esteja na lista de congregações do usuário)
                None => false,
                Some(cid) => claims.congregation_ids.contains(&cid.to_string()),
            }
        },
        "self" => {
            // Self pode acessar sua própria congregação
            match (congregation_id, &claims.primary_congregation_id) {
                (Some(cid), Some(pcid)) => cid.to_string() == *pcid,
                _ => false,
            }
        },
        _ => false,
    }
}
```

### 5.6 Aplicação nos Services

Cada service existente precisa receber e aplicar o escopo. Padrão:

```rust
// ANTES (member_service.rs — list_members)
pub async fn list_members(
    pool: &PgPool,
    church_id: Uuid,
    filters: MemberFilters,
) -> Result<Vec<MemberSummary>, AppError> {
    let mut query = "SELECT ... FROM members m WHERE m.church_id = $1 AND m.deleted_at IS NULL";
    // ... filtros opcionais, incluindo congregation_id do query param
}

// DEPOIS
pub async fn list_members(
    pool: &PgPool,
    church_id: Uuid,
    filters: MemberFilters,
    allowed_congregations: Option<Vec<Uuid>>,  // ← NOVO: do middleware
) -> Result<Vec<MemberSummary>, AppError> {
    let mut query = "SELECT ... FROM members m WHERE m.church_id = $1 AND m.deleted_at IS NULL";
    
    // Enforcement server-side: restringir às congregações permitidas
    if let Some(ref cong_ids) = allowed_congregations {
        if cong_ids.is_empty() {
            // Nenhuma congregação permitida = resultado vazio
            return Ok(vec![]);
        }
        query += " AND m.congregation_id = ANY($X)";
    }
    
    // O filtro de congregation_id do query param continua funcionando,
    // mas é INTERSECTADO com allowed_congregations (nunca expande o escopo)
    // ...
}
```

**Esse padrão se aplica a TODOS os serviços:**
- `member_service.rs` — list, get_by_id, create (só na sua congregação), update, delete
- `financial_service.rs` — list_entries, create_entry, balance, etc.
- `asset_service.rs` — list, create, update, delete
- `ebd_service.rs` — list_classes, create_class, list_terms, etc.
- `congregation_service.rs` — list (filtrado), stats (só da sua)

### 5.7 Regras Detalhadas por Escopo

#### Escopo `global` (super_admin, pastor)

| Operação | Comportamento |
|----------|--------------|
| Listar membros | Todos da church. Seletor de congregação é filtro OPCIONAL. |
| Criar membro | Pode atribuir a qualquer congregação |
| Ver financeiro | Consolidado ou por congregação (seletor) |
| Relatórios | Todos: overview, comparação, por congregação |
| Gerenciar usuários | Pode criar/editar/desativar qualquer usuário |
| Gerenciar congregações | CRUD completo |

#### Escopo `congregation` (secretary, treasurer, etc. vinculados)

| Operação | Comportamento |
|----------|--------------|
| Listar membros | **Apenas** membros da(s) sua(s) congregação(ões) |
| Criar membro | `congregation_id` é **pré-preenchido e fixo** na sua congregação |
| Ver financeiro | **Apenas** lançamentos da sua congregação |
| Criar lançamento | `congregation_id` da sua congregação é **obrigatório e imutável** |
| Ver patrimônio | **Apenas** bens da sua congregação |
| Ver EBD | **Apenas** turmas da sua congregação |
| Relatórios | Dados **apenas** da sua congregação |
| Seletor de congregação | **Escondido** (ou mostra apenas suas congregações se tiver mais de uma) |
| Gerenciar congregações | ❌ Sem acesso |
| Gerenciar usuários | ❌ Sem acesso |

#### Escopo `self` (member)

| Operação | Comportamento |
|----------|--------------|
| Ver perfil | Apenas o **próprio** registro de membro (via `users.member_id`) |
| Editar perfil | Campos limitados: telefone, endereço, foto. **Não** pode editar nome, status, dados eclesiásticos. |
| Ver EBD | Suas próprias aulas e presenças |
| Ver financeiro | ❌ Sem acesso |
| Ver patrimônio | ❌ Sem acesso |
| Relatórios | ❌ Sem acesso |

### 5.8 Persistência da Congregação Ativa

```sql
-- Na migração 20260221000000_user_member_integration.sql
ALTER TABLE users ADD COLUMN active_congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;
```

```rust
// POST /api/v1/user/active-congregation — ALTERAR para persistir
async fn set_active_congregation(
    pool: &PgPool,
    user_id: Uuid,
    congregation_id: Option<Uuid>,  // None = "Todas (Geral)"
) -> Result<(), AppError> {
    // Validar existência da congregação
    // Validar que está no escopo (se escopo != global)
    sqlx::query!(
        "UPDATE users SET active_congregation_id = $1, updated_at = NOW() WHERE id = $2",
        congregation_id, user_id
    ).execute(pool).await?;
    Ok(())
}
```

### 5.9 Arquivos a Alterar/Criar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `backend/migrations/20260221000000_user_member_integration.sql` | **ATUALIZAR** | Adicionar `active_congregation_id` à tabela users |
| `backend/src/application/dto/auth_dto.rs` | **ALTERAR** | Novos campos no Claims: scope_type, congregation_ids, primary_congregation_id, member_id |
| `backend/src/application/services/auth_service.rs` | **ALTERAR** | Lógica `determine_scope` no login, incluir campos no JWT |
| `backend/src/api/middleware.rs` | **ALTERAR** | Novas funções: `get_allowed_congregations`, `can_access_congregation` |
| `backend/src/application/services/member_service.rs` | **ALTERAR** | Receber e aplicar `allowed_congregations` |
| `backend/src/application/services/financial_service.rs` | **ALTERAR** | Receber e aplicar `allowed_congregations` |
| `backend/src/application/services/asset_service.rs` | **ALTERAR** | Receber e aplicar `allowed_congregations` |
| `backend/src/application/services/ebd_service.rs` | **ALTERAR** | Receber e aplicar `allowed_congregations` |
| `backend/src/application/services/congregation_service.rs` | **ALTERAR** | Filtrar listagem por escopo |
| `backend/src/api/handlers/member_handler.rs` | **ALTERAR** | Extrair escopo e passar ao service |
| `backend/src/api/handlers/financial_handler.rs` | **ALTERAR** | Idem |
| `backend/src/api/handlers/asset_handler.rs` | **ALTERAR** | Idem |
| `backend/src/api/handlers/ebd_handler.rs` | **ALTERAR** | Idem |
| `backend/src/api/handlers/congregation_handler.rs` | **ALTERAR** | Persistir congregação ativa |
| `frontend/lib/features/auth/data/models/auth_models.dart` | **ALTERAR** | Novos campos: scopeType, congregationIds, primaryCongregationId, memberId |
| `frontend/lib/features/congregations/bloc/congregation_context_cubit.dart` | **ALTERAR** | Inicializar baseado no scope do JWT |
| `frontend/lib/core/shell/app_shell.dart` | **ALTERAR** | Esconder/mostrar seletor baseado no scope |

**Estimativa:** 5-7 dias. Risco: alto (toca todos os módulos). Requer testes extensivos.

---

## 6. Fase 4 — Experiência de Login por Perfil

### 6.1 Fluxo de Login Atualizado

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────────┐
│  Login Form │────▶│  POST /login │────▶│  Avaliar resposta   │
│  email+pass │     │              │     │                     │
└─────────────┘     └──────────────┘     └──────────┬──────────┘
                                                     │
                              ┌───────────────────────┼────────────────────┐
                              │                       │                    │
                              ▼                       ▼                    ▼
                    ┌──────────────┐       ┌──────────────┐     ┌──────────────┐
                    │force_password│       │ scope=global  │     │scope=congreg.│
                    │  _change?    │       │               │     │              │
                    │  ───▶ redir  │       │ ───▶ Dashboard│     │ ───▶ Dashb.  │
                    │  /change-pwd │       │ (Todas/Geral) │     │ (Minha Cong.)│
                    └──────────────┘       └──────────────┘     └──────────────┘
```

### 6.2 LoginResponse Atualizado

```json
{
    "access_token": "eyJ...",
    "refresh_token": "...",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": {
        "id": "uuid",
        "email": "dirigente@email.com",
        "role": "secretary",
        "church_id": "uuid",
        "church_name": "AD Ministério de Tutóia",
        "member_id": "uuid-do-membro",
        "member_name": "Ernane Sousa do Nascimento",
        "scope_type": "congregation",
        "congregation_ids": ["uuid-paxica"],
        "primary_congregation_id": "uuid-paxica",
        "primary_congregation_name": "Paxicá",
        "force_password_change": false
    }
}
```

### 6.3 Comportamento do Frontend por Perfil

| Perfil | Ao logar | Seletor de Congregação | Dashboard |
|--------|----------|----------------------|-----------|
| **Admin** (admin@igreja.com) | Vai para Dashboard com "Todas (Geral)" | ✅ Visível com todas as opções | Stats consolidados |
| **Dirigente Paxicá** | Vai para Dashboard com "Paxicá" selecionado | ⚠️ Visível mas apenas "Paxicá" disponível | Stats do Paxicá |
| **Tesoureiro Sede** | Vai para Dashboard com "Sede" selecionado | ⚠️ Visível mas apenas "Sede" | Stats financeiros da Sede |
| **Membro comum** | Vai para "Meu Perfil" | ❌ Escondido | Apenas perfil pessoal |

### 6.4 Implementação no Frontend

```dart
// auth_bloc.dart — após login bem-sucedido
void _onLoginSuccess(AuthUser user) {
    if (user.forcePasswordChange) {
        // Redirecionar para troca de senha obrigatória
        emit(AuthMustChangePassword(user));
        return;
    }
    
    emit(AuthAuthenticated(user));
    
    // Inicializar contexto de congregação baseado no scope
    final congContext = context.read<CongregationContextCubit>();
    
    switch (user.scopeType) {
        case 'global':
            // Admin/pastor: carregar todas e ficar em "Todas (Geral)"
            congContext.loadCongregations();
            break;
            
        case 'congregation':
            // Líder/secretário: carregar só as suas e selecionar a primária
            congContext.loadCongregations(
                filterIds: user.congregationIds,
                autoSelect: user.primaryCongregationId,
            );
            break;
            
        case 'self':
            // Membro: selecionar silenciosamente a congregação do membro
            if (user.primaryCongregationId != null) {
                congContext.selectCongregation(user.primaryCongregationId!);
            }
            break;
    }
}
```

### 6.5 Arquivos a Alterar

| Arquivo | Mudança |
|---------|---------|
| `frontend/lib/features/auth/data/models/auth_models.dart` | Novos campos no AuthUser |
| `frontend/lib/features/auth/bloc/auth_bloc.dart` | Lógica de redirecionamento por perfil |
| `frontend/lib/features/auth/presentation/force_change_password_screen.dart` | Tela de troca obrigatória |
| `frontend/lib/features/congregations/bloc/congregation_context_cubit.dart` | `loadCongregations` com filtro e auto-select |
| `frontend/lib/core/router/app_router.dart` | Guard para forçar troca de senha, redirect por perfil |

**Estimativa:** 2-3 dias. Risco: médio.

---

## 7. Fase 5 — UI de Permissões e Navegação por Role

### 7.1 Sidebar/Menu por Role

O AppShell deve **esconder** itens de menu inacessíveis:

```dart
// app_shell.dart — drawer items condicionais
List<DrawerItem> getMenuItems(AuthUser user) {
    return [
        // Sempre visível para todos
        DrawerItem(icon: Icons.dashboard, label: 'Dashboard', route: '/'),
        
        // Membros
        if (user.hasAnyPermission(['members:*', 'members:read']))
            DrawerItem(icon: Icons.people, label: 'Membros', route: '/members'),
        
        // Financeiro
        if (user.hasAnyPermission(['financial:*', 'financial:read']))
            DrawerItem(icon: Icons.attach_money, label: 'Financeiro', route: '/financial'),
        
        // Patrimônio
        if (user.hasAnyPermission(['assets:*', 'assets:read']))
            DrawerItem(icon: Icons.business, label: 'Patrimônio', route: '/assets'),
        
        // EBD
        if (user.hasAnyPermission(['ebd:*', 'ebd:read', 'ebd:attendance']))
            DrawerItem(icon: Icons.school, label: 'EBD', route: '/ebd'),
        
        // Relatórios
        if (user.hasAnyPermission(['reports:*', 'reports:members', 'reports:financial', 'reports:assets', 'reports:ebd']))
            DrawerItem(icon: Icons.bar_chart, label: 'Relatórios', route: '/reports'),
        
        // Congregações (apenas global scope)
        if (user.scopeType == 'global')
            DrawerItem(icon: Icons.church, label: 'Congregações', route: '/congregations'),
        
        // Configurações (apenas admin)
        if (user.hasAnyPermission(['settings:*', 'settings:read']))
            DrawerItem(icon: Icons.settings, label: 'Configurações', route: '/settings'),
        
        // Meu Perfil (sempre visível)
        DrawerItem(icon: Icons.person, label: 'Meu Perfil', route: '/profile'),
    ];
}
```

### 7.2 Helper de Permissão no AuthUser

```dart
class AuthUser {
    // ... campos existentes ...
    
    bool hasPermission(String permission) {
        if (role == 'super_admin') return true;
        if (permissions.contains('*')) return true;
        if (permissions.contains(permission)) return true;
        
        // Wildcard matching
        final parts = permission.split(':');
        if (parts.length == 2) {
            return permissions.contains('${parts[0]}:*');
        }
        return false;
    }
    
    bool hasAnyPermission(List<String> perms) {
        return perms.any((p) => hasPermission(p));
    }
    
    bool get isGlobalScope => scopeType == 'global';
    bool get isCongregationScope => scopeType == 'congregation';
    bool get isSelfScope => scopeType == 'self';
}
```

### 7.3 Guards de Rota no Frontend

```dart
// app_router.dart — proteção por rota
GoRoute(
    path: '/members',
    redirect: (context, state) {
        final user = getCurrentUser(context);
        if (!user.hasAnyPermission(['members:*', 'members:read'])) {
            return '/'; // Redirecionar para dashboard
        }
        return null;
    },
    builder: (context, state) => MemberListPage(),
),
```

### 7.4 Dashboard Adaptativo

O Dashboard deve mostrar cards diferentes por perfil:

| Perfil | Cards visíveis |
|--------|---------------|
| **Admin/Pastor** | Membros, Financeiro, Patrimônio, EBD, Congregações (todos com dados consolidados ou filtrados) |
| **Secretário** | Membros, EBD (da sua congregação) |
| **Tesoureiro** | Financeiro (da sua congregação) |
| **Gestor Patrimônio** | Patrimônio (da sua congregação) |
| **Professor EBD** | EBD (turmas que ministra) |
| **Membro** | Meu Perfil (resumo), Próximas aulas EBD, Avisos |

### 7.5 Arquivos a Alterar

| Arquivo | Mudança |
|---------|---------|
| `frontend/lib/features/auth/data/models/auth_models.dart` | Métodos `hasPermission`, `hasAnyPermission` |
| `frontend/lib/core/shell/app_shell.dart` | Menu condicional por permissão |
| `frontend/lib/core/router/app_router.dart` | Guards de rota por permissão |
| `frontend/lib/features/dashboard/presentation/dashboard_page.dart` | Cards condicionais por perfil |
| `frontend/lib/features/members/presentation/pages/member_form_page.dart` | Campos readonly por escopo (membro editando perfil) |

**Estimativa:** 2-3 dias. Risco: baixo.

---

## 8. Fase 6 — Relatórios por Congregação

### 8.1 Relatórios Existentes (já implementados)

| Relatório | Endpoint | Status |
|-----------|----------|--------|
| Overview de Congregações | `GET /api/v1/reports/congregations/overview` | ✅ |
| Comparação entre Congregações | `GET /api/v1/reports/congregations/compare` | ✅ |

### 8.2 Relatórios a Adicionar

| Relatório | Endpoint | Descrição |
|-----------|----------|-----------|
| **Membros por Congregação** | `GET /api/v1/reports/members?congregation_id=X` | Lista de membros de uma congregação com totais por status |
| **Financeiro por Congregação** | `GET /api/v1/reports/financial?congregation_id=X` | Receitas, despesas, saldo, gráfico de evolução mensal |
| **Patrimônio por Congregação** | `GET /api/v1/reports/assets?congregation_id=X` | Bens por categoria, valor total, estado de conservação |
| **EBD por Congregação** | `GET /api/v1/reports/ebd?congregation_id=X` | Turmas, média de presença, professores |
| **Relatório Consolidado** | `GET /api/v1/reports/consolidated` | Todas as congregações + totais gerais (apenas escopo global) |
| **Ficha Completa de Congregação** | `GET /api/v1/reports/congregations/{id}/full` | Tudo sobre uma congregação: membros, finanças, bens, EBD |

### 8.3 Aplicação de Escopo nos Relatórios

```
Admin acessa /reports/members → Pode filtrar por qualquer congregação ou ver consolidado
Dirigente acessa /reports/members → Automaticamente filtrado pela sua congregação
Membro acessa /reports/members → ❌ Sem permissão (role não tem reports:members)
```

### 8.4 View de EBD (pendente de criação)

```sql
-- Na migração — criar view que faltou
CREATE OR REPLACE VIEW vw_congregation_ebd_stats AS
SELECT
    c.id AS congregation_id,
    c.name AS congregation_name,
    COUNT(DISTINCT ec.id) AS total_classes,
    COUNT(DISTINCT ee.id) AS total_enrolled,
    COUNT(DISTINCT CASE WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) 
                        THEN ea.id END) AS attendances_this_month,
    ROUND(
        CASE WHEN COUNT(DISTINCT CASE WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) 
                                      THEN ea.id END) > 0
        THEN COUNT(DISTINCT CASE WHEN ea.present = true 
                                 AND el.lesson_date >= date_trunc('month', CURRENT_DATE) 
                                 THEN ea.id END)::NUMERIC 
             / NULLIF(COUNT(DISTINCT CASE WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) 
                                         THEN ea.id END), 0) * 100
        ELSE 0 END, 1
    ) AS attendance_percentage_this_month
FROM congregations c
LEFT JOIN ebd_classes ec ON ec.congregation_id = c.id
LEFT JOIN ebd_enrollments ee ON ee.class_id = ec.id
LEFT JOIN ebd_lessons el ON el.class_id = ec.id
LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id
WHERE c.is_active = true
GROUP BY c.id, c.name;
```

### 8.5 Arquivos a Alterar/Criar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `backend/migrations/20260221000000_user_member_integration.sql` | **ATUALIZAR** | Incluir `vw_congregation_ebd_stats` |
| `backend/src/application/services/report_service.rs` | **ALTERAR** | Novos métodos para relatórios filtrados por congregação com escopo |
| `backend/src/api/handlers/report_handler.rs` | **ALTERAR** | Novos endpoints de relatórios |
| `frontend/lib/features/reports/` | **ALTERAR** | Novas telas de relatórios filtrados |

**Estimativa:** 3-4 dias. Risco: baixo.

---

## 9. Migrações de Banco de Dados

### 9.1 Migração Única Consolidada

Arquivo: `backend/migrations/20260221000000_user_member_integration.sql`

```sql
-- =================================================================
-- Migração: Integração User-Member + Controle de Acesso por Congregação
-- Data: 21 de fevereiro de 2026
-- Descrição: 
--   1. Campo force_password_change em users
--   2. Campo active_congregation_id em users
--   3. Índice para busca de user por member_id
--   4. Atualização de roles para incluir settings:write onde necessário
--   5. View de EBD por congregação
--   6. Tornando FKs cross-module nullable (ebd_enrollments, asset_loans)
-- =================================================================

-- 1. Novos campos na tabela users
ALTER TABLE users ADD COLUMN IF NOT EXISTS force_password_change BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS active_congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- 2. Índice para busca eficiente de user por member_id
CREATE INDEX IF NOT EXISTS idx_users_member_id ON users(member_id) WHERE member_id IS NOT NULL;

-- 3. Atualizar role "pastor" para incluir settings:write e congregations:*
UPDATE roles 
SET permissions = '["members:*", "financial:read", "financial:write", "assets:*", "ebd:*", "reports:*", "settings:read", "settings:write", "congregations:*"]'::jsonb,
    updated_at = NOW()
WHERE name = 'pastor';

-- 4. Novo role: congregation_leader (líder de congregação)
INSERT INTO roles (name, display_name, description, permissions, is_system)
VALUES (
    'congregation_leader',
    'Líder de Congregação',
    'Dirigente/responsável por uma congregação. Acesso completo dentro do escopo da sua congregação.',
    '["members:*", "financial:read", "financial:write", "assets:*", "ebd:*", "reports:*", "settings:read"]'::jsonb,
    TRUE
) ON CONFLICT (name) DO NOTHING;

-- 5. View de estatísticas EBD por congregação (faltava)
CREATE OR REPLACE VIEW vw_congregation_ebd_stats AS
SELECT
    c.id AS congregation_id,
    c.name AS congregation_name,
    COUNT(DISTINCT ec.id) AS total_classes,
    COUNT(DISTINCT ee.id) AS total_enrolled,
    COUNT(DISTINCT CASE 
        WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id 
    END) AS attendances_this_month,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT CASE 
                WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id 
            END) > 0
            THEN COUNT(DISTINCT CASE 
                WHEN ea.present = true AND el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id 
            END)::NUMERIC 
            / NULLIF(COUNT(DISTINCT CASE 
                WHEN el.lesson_date >= date_trunc('month', CURRENT_DATE) THEN ea.id 
            END), 0) * 100
            ELSE 0 
        END, 1
    ) AS attendance_percentage_this_month
FROM congregations c
LEFT JOIN ebd_classes ec ON ec.congregation_id = c.id
LEFT JOIN ebd_enrollments ee ON ee.class_id = ec.id
LEFT JOIN ebd_lessons el ON el.class_id = ec.id
LEFT JOIN ebd_attendances ea ON ea.lesson_id = el.id
WHERE c.is_active = true
GROUP BY c.id, c.name;

-- 6. Tornar FKs cross-module nullable (padrão modular PF-001)
-- ebd_enrollments.member_id: NOT NULL → NULL
ALTER TABLE ebd_enrollments ALTER COLUMN member_id DROP NOT NULL;

-- asset_loans.borrower_member_id: NOT NULL → NULL, adicionar campo texto alternativo
ALTER TABLE asset_loans ALTER COLUMN borrower_member_id DROP NOT NULL;
ALTER TABLE asset_loans ADD COLUMN IF NOT EXISTS borrower_name VARCHAR(200);
-- Se não tiver member_id, deve ter borrower_name
ALTER TABLE asset_loans ADD CONSTRAINT chk_borrower_identification 
    CHECK (borrower_member_id IS NOT NULL OR borrower_name IS NOT NULL);
```

---

## 10. Regras de Negócio

### 10.1 Regras de Criação de Login

| ID | Regra | Validação |
|----|-------|-----------|
| RN-LOGIN-001 | Membro deve ter email para criar login | Backend: rejeita com 422 se `member.email IS NULL` |
| RN-LOGIN-002 | Email do membro deve ser único na church para user | Backend: verifica `UNIQUE(email, church_id)` |
| RN-LOGIN-003 | Senha mínima: 6 caracteres | Backend: validação no DTO |
| RN-LOGIN-004 | Senha gerada automaticamente: 8 chars alfanuméricos (excluindo ambíguos: 0/O, 1/l/I) | Charset: `ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789` |
| RN-LOGIN-005 | Role padrão: `member` | Backend: default se não especificado |
| RN-LOGIN-006 | `users.member_id` preenchido automaticamente | Backend: set na criação |
| RN-LOGIN-007 | `user_congregations` criado se membro tem congregação | Backend: insert na transação |
| RN-LOGIN-008 | Senha em claro retornada APENAS quando gerada automaticamente | Backend: campo `generated_password` no response |
| RN-LOGIN-009 | Não é possível criar dois users para o mesmo member | Backend: verifica `users.member_id` existente |
| RN-LOGIN-010 | Desativar membro NÃO desativa user automaticamente | Ações independentes, admin deve gerenciar ambos |

### 10.2 Regras de Escopo de Congregação

| ID | Regra | Enforcement |
|----|-------|-------------|
| RN-SCOPE-001 | `super_admin` e `pastor` SEMPRE têm escopo `global` | Backend: hardcoded no login |
| RN-SCOPE-002 | `member` SEMPRE tem escopo `self` | Backend: hardcoded no login |
| RN-SCOPE-003 | Roles intermediários sem `user_congregations` = escopo `global` | Backend: fallback para retrocompatibilidade |
| RN-SCOPE-004 | Roles intermediários com `user_congregations` = escopo `congregation` | Backend: determinado no login |
| RN-SCOPE-005 | Escopo `congregation` restringe TODAS as queries (membros, financeiro, patrimônio, EBD, relatórios) | Backend: middleware em todos os services |
| RN-SCOPE-006 | Escopo `congregation` proíbe criar dados fora da(s) congregação(ões) do usuário | Backend: validação no create |
| RN-SCOPE-007 | Escopo `self` permite apenas leitura/edição parcial do próprio perfil | Backend: filtro por `users.member_id`, campos restritos no update |
| RN-SCOPE-008 | Congregação ativa é salva no banco (`users.active_congregation_id`) e restaurada no próximo login | Backend: persist no endpoint, load no login response |
| RN-SCOPE-009 | Seletor de congregação mostra APENAS congregações acessíveis ao escopo | Frontend: filtra opções baseado em `congregation_ids` |
| RN-SCOPE-010 | O filtro `congregation_id` do query param é INTERSECTADO com o escopo — nunca o expande | Backend: lógica AND nos services |

### 10.3 Regras de Troca de Senha

| ID | Regra | Enforcement |
|----|-------|-------------|
| RN-PWD-001 | Se `force_password_change = true`, frontend redireciona para `/force-change-password` antes de qualquer outra tela | Frontend: guard no router |
| RN-PWD-002 | A tela de troca de senha exige: nova senha + confirmação, mín. 6 chars | Frontend + Backend |
| RN-PWD-003 | Após troca completa, `force_password_change` é setado para `false` | Backend: UPDATE na operação |
| RN-PWD-004 | Todos os refresh tokens são revogados após troca de senha (forçar relogin em outros dispositivos) | Backend: revoke all |

### 10.4 Regras de Navegação por Role

| ID | Regra | Enforcement |
|----|-------|-------------|
| RN-NAV-001 | Menu do sidebar mostra apenas módulos acessíveis ao role do usuário | Frontend: condicional por permission |
| RN-NAV-002 | Rotas inacessíveis redirecionam para Dashboard (não exibem erro) | Frontend: redirect guard |
| RN-NAV-003 | Dashboard mostra cards apenas de módulos acessíveis | Frontend: condicional |
| RN-NAV-004 | Botões de ação (criar, editar, excluir) ficam ocultos quando o role não tem a permissão de escrita | Frontend: condicional |

---

## 11. Testes e Validação

### 11.1 Cenários de Teste Críticos

#### Cenário A: Admin (admin@igreja.com)
```
1. Login → Dashboard com "Todas (Geral)"
2. Ver membros → Todos os 210 membros
3. Filtrar por Paxicá → Apenas membros do Paxicá
4. Criar membro na Sede → ✅ Sucesso
5. Criar membro no Paxicá → ✅ Sucesso
6. Ver financeiro → Consolidado ou por congregação
7. Relatório comparativo → Todas as congregações
8. Gerenciar usuários → ✅ Acesso total
```

#### Cenário B: Dirigente do Paxicá (com role congregation_leader)
```
1. Login → Dashboard com "Paxicá" auto-selecionado
2. Seletor de congregação → Apenas "Paxicá" disponível
3. Ver membros → APENAS membros do Paxicá
4. Criar membro → congregation_id = Paxicá (fixo, não selecionável)
5. Tentar acessar via API membros da Sede → ❌ 403 Forbidden
6. Ver financeiro → APENAS lançamentos do Paxicá
7. Criar lançamento → congregation_id = Paxicá (fixo)
8. Ver patrimônio → APENAS bens do Paxicá
9. Relatórios → APENAS dados do Paxicá
10. Gerenciar congregações → ❌ Sem acesso
11. Gerenciar usuários → ❌ Sem acesso
```

#### Cenário C: Tesoureiro da Sede (com role treasurer + vinculado à Sede)
```
1. Login → Dashboard com stats financeiros da Sede
2. Ver membros → ❌ Sem acesso (role não tem members:*)
3. Ver financeiro → APENAS lançamentos da Sede
4. Criar lançamento → congregation_id = Sede (fixo)
5. Relatórios → APENAS relatório financeiro da Sede
6. Ver patrimônio → ❌ Sem acesso
```

#### Cenário D: Membro comum (com role member)
```
1. Login → Tela "Meu Perfil"
2. Ver próprio perfil → ✅ Dados pessoais
3. Editar perfil → ✅ Apenas telefone, endereço, foto
4. Tentar editar nome, status → ❌ Campos readonly
5. Ver membros da congregação → ❌ Sem acesso
6. Ver financeiro → ❌ Sem acesso
7. Menu lateral → Apenas "Dashboard" e "Meu Perfil"
```

#### Cenário E: Criação de login via membro
```
1. Admin cadastra membro "Maria Silva" com email maria@email.com
2. Marca "Criar login" com senha gerada
3. Sistema cria user + vincula member_id + cria user_congregations
4. Modal mostra: Maria Silva | maria@email.com | senha: xK8mP2vQ
5. Maria faz login → Redireciona para troca de senha
6. Maria troca senha → Acessa "Meu Perfil"
```

#### Cenário F: Criação em lote
```
1. Admin seleciona 10 membros na lista (todos com email)
2. Clica "Criar Login" na toolbar
3. Confirma: role = member, forçar troca = sim
4. Sistema cria 10 users, pula 2 que já tinham login
5. Modal mostra tabela com 8 senhas geradas + 2 pulados
6. Admin clica "Exportar CSV" → baixa arquivo com senhas
```

### 11.2 Testes de Segurança

| Teste | Descrição | Esperado |
|-------|-----------|----------|
| SEC-001 | Dirigente chama API de membros com `congregation_id` de outra congregação | 403 ou resultado vazio |
| SEC-002 | Membro tenta acessar `GET /api/v1/members` | 403 Forbidden |
| SEC-003 | Membro tenta `PUT /api/v1/members/:otherMemberId` | 403 Forbidden |
| SEC-004 | Membro tenta `GET /api/v1/financial/entries` | 403 Forbidden |
| SEC-005 | Token expirado + refresh → novos claims com escopo atualizado | Token renovado com escopo correto |
| SEC-006 | User desativado tenta login | "Conta desativada" |
| SEC-007 | Dirigente desvinculado da congregação tenta acessar | Próximo login terá escopo atualizado |

---

## 12. Checklist de Implementação

### Fase 1 — Wildcard de Permissões ⏱️ ~30min
- [ ] Reescrever `require_permission` em `middleware.rs`
- [ ] Testar com roles: pastor, secretary, treasurer, asset_manager, ebd_teacher
- [ ] Verificar que `members:*` permite `members:create`, `members:update`, `members:delete`

### Fase 2 — Login para Membros ⏱️ ~3-4 dias
- [ ] Migração: `force_password_change`, `idx_users_member_id`
- [ ] DTO: `CreateUserForMemberRequest`, `CreateUserForMemberResponse`
- [ ] Service: `create_user_for_member`, `batch_create_users_for_members`
- [ ] Handler: `POST /members/{id}/create-user`, `POST /members/batch-create-users`
- [ ] Service auth: troca de senha, setar `force_password_change = false`
- [ ] Handler auth: `PUT /auth/change-password`
- [ ] Registrar rotas em `main.rs`
- [ ] Frontend: seção "Acesso ao Sistema" no form de membro
- [ ] Frontend: ação em lote "Criar Login" na lista de membros
- [ ] Frontend: modal de confirmação com senhas
- [ ] Frontend: tela `/force-change-password`
- [ ] Frontend: guard de rota para troca obrigatória

### Fase 3 — Controle de Acesso por Congregação ⏱️ ~5-7 dias
- [ ] Migração: `active_congregation_id`, role `congregation_leader`
- [ ] DTO auth: novos campos no Claims (scope_type, congregation_ids, etc.)
- [ ] Service auth: `determine_scope` no login
- [ ] Middleware: `get_allowed_congregations`, `can_access_congregation`
- [ ] Service members: receber e aplicar `allowed_congregations`
- [ ] Service financial: idem
- [ ] Service assets: idem
- [ ] Service EBD: idem
- [ ] Service congregations: filtrar por escopo
- [ ] Handlers (todos): extrair escopo e passar ao service
- [ ] Handler congregations: persistir `active_congregation_id`
- [ ] Frontend auth models: novos campos
- [ ] Frontend CongregationContextCubit: inicializar por escopo
- [ ] Frontend AppShell: esconder/mostrar seletor por escopo

### Fase 4 — Login por Perfil ⏱️ ~2-3 dias
- [ ] Backend: login response com campos completos
- [ ] Frontend: AuthBloc — redirecionamento por perfil
- [ ] Frontend: auto-seleção de congregação por escopo
- [ ] Frontend: guard de forçar troca de senha

### Fase 5 — UI por Role ⏱️ ~2-3 dias
- [ ] Frontend: menu condicional por permissão
- [ ] Frontend: guards de rota por permissão
- [ ] Frontend: dashboard adaptativo por perfil
- [ ] Frontend: campos readonly no perfil do membro
- [ ] Frontend: botões de ação condicionais (criar/editar/excluir ocultos sem permissão)

### Fase 6 — Relatórios ⏱️ ~3-4 dias
- [ ] Migração: view `vw_congregation_ebd_stats`
- [ ] Backend: endpoints de relatórios por congregação (4 módulos)
- [ ] Backend: relatório consolidado (apenas global)
- [ ] Backend: ficha completa de congregação
- [ ] Frontend: telas de relatórios filtrados
- [ ] Aplicar escopo nos relatórios existentes

---

## Resumo de Esforço Total

| Fase | Esforço | Risco | Dependência |
|------|---------|-------|-------------|
| 1. Bug wildcard | ~30 min | 🟢 Baixo | Nenhuma |
| 2. Login para membros | ~3-4 dias | 🟡 Médio | Fase 1 |
| 3. Controle de acesso | ~5-7 dias | 🔴 Alto | Fases 1, 2 |
| 4. Login por perfil | ~2-3 dias | 🟡 Médio | Fase 3 |
| 5. UI por role | ~2-3 dias | 🟢 Baixo | Fases 3, 4 |
| 6. Relatórios | ~3-4 dias | 🟢 Baixo | Fase 3 |
| **Total** | **~16-22 dias** | | |

> **Nota:** As fases 4 e 5 podem ser desenvolvidas em paralelo. A fase 6 pode ser desenvolvida em paralelo com a fase 5. O caminho crítico é: 1 → 2 → 3 → (4 + 5 + 6).

---

## Referências Internas

- [doc 03 — Banco de Dados](03-banco-de-dados.md)
- [doc 06 — Regras de Negócio](06-regras-de-negocio.md)
- [doc 10 — Módulo Congregações](10-modulo-congregacoes.md)
- [doc 11 — Padrão de Integração Modular](11-padrao-integracao-modular.md)
