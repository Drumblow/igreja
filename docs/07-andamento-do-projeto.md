# 📊 Andamento do Projeto — Igreja Manager

> **Última atualização:** 20 de fevereiro de 2026  
> **Versão do documento:** 1.16  
> **Status geral do projeto:** Em Desenvolvimento Ativo (~99.8% concluído)

---

## 1. Visão Geral do Progresso

O **Igreja Manager** é uma plataforma de gestão para igrejas composta por **6 módulos principais**: Autenticação, Membros, Financeiro, Patrimônio, EBD (Escola Bíblica Dominical) e Congregações. A stack tecnológica definida é **Rust (Actix-Web)** no backend, **PostgreSQL 16** como banco de dados, **Redis 7** para cache e **Flutter 3.38** no frontend (Web, Android, iOS).

### Resumo Executivo por Área

| Área | Progresso | Status |
|------|:---------:|--------|
| Documentação Técnica | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Concluído |
| Banco de Dados (Schema) | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Concluído |
| Infraestrutura (Docker) | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Docker + Redis cache + SMTP config + Oracle Cloud deploy + Cloudinary |
| Backend — Autenticação | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Completo (login/refresh/logout/me/forgot/reset) |
| Backend — Igrejas | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ CRUD completo (5 endpoints) + Audit Log |
| Backend — Usuários/Papéis | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ CRUD completo (5 endpoints) + Audit Log |
| Backend — Membros | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Famílias + Ministérios + Histórico + Cache + Audit |
| Backend — Financeiro | ![95%](https://img.shields.io/badge/95%25-green) | 🟢 CRUD completo (5 sub-módulos, 18 endpoints) + Audit Log |
| Backend — Patrimônio | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ CRUD + Stats + Cache + Audit (5 sub-módulos, 18 endpoints) |
| Backend — EBD | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ CRUD + Stats + Cache + Audit + Reports (10 sub-módulos, 48+ endpoints) — Evolução E1-E7 + F1 |
| Backend — Swagger UI | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Montado em `/swagger-ui/` |
| Frontend — Design System | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Concluído |
| Frontend — Autenticação | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Login + Forgot Password + Reset Password completos |
| Frontend — Dashboard | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Stats wired (4 módulos) + Quick Actions (6) + Pull-to-refresh + Relatórios |
| Frontend — Membros | ![98%](https://img.shields.io/badge/98%25-brightgreen) | ✅ CRUD completo + Histórico + Paginação + Edit navigation fix |
| Frontend — Famílias | ![98%](https://img.shields.io/badge/98%25-brightgreen) | ✅ CRUD completo + Paginação + Edit navigation fix |
| Frontend — Ministérios | ![98%](https://img.shields.io/badge/98%25-brightgreen) | ✅ CRUD + Paginação + Edit fix + Adicionar membro (dialog) + Campo líder (form) |
| Frontend — Financeiro | ![95%](https://img.shields.io/badge/95%25-green) | 🟢 7 telas + BLoC + Paginação + Filtro data + Swipe-to-delete + Fechamento Mensal |
| Frontend — Patrimônio | ![95%](https://img.shields.io/badge/95%25-green) | 🟢 12 telas + BLoC + Paginação + Filtro categoria + Edit navigation fix |
| Frontend — EBD | ![98%](https://img.shields.io/badge/98%25-brightgreen) | ✅ Overview + 10 telas + BLoC + Relatórios + Paginação (E1–E7 + F1) |
| Frontend — Relatórios | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Tela central + métricas (4 módulos) + Gráficos fl_chart (pie + bar) + aniversariantes |
| Backend — Congregações | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ NOVO — CRUD + Stats + Users + Assign Members + Overview (12 endpoints) |
| Frontend — Congregações | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ NOVO — 5 telas + BLoC + Context Cubit + Selector Widget |
| Frontend — Configurações | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ NOVO — Igrejas + Usuários/Papéis + Congregações (3 telas + BLoC + Repositório) |

---

## 2. Documentação Técnica — ✅ 100% Concluída

Toda a documentação de especificação foi finalizada, totalizando **~6.600 linhas** distribuídas em 9 documentos:

| Documento | Linhas | Conteúdo |
|-----------|:------:|----------|
| `01-requisitos-funcionais.md` | 528 | 40+ requisitos funcionais detalhados para os 5 módulos |
| `02-arquitetura.md` | 686 | Arquitetura Clean Architecture, diagramas Mermaid, estratégias de deploy |
| `03-banco-de-dados.md` | 1.106 | 24+ tabelas documentadas campo a campo, diagrama ER |
| `04-api-rest.md` | 1.226 | 60+ endpoints REST com exemplos de request/response |
| `05-frontend-flutter.md` | 1.107 | Design system, BLoC pattern, go_router, wireframes, responsividade |
| `06-regras-de-negocio.md` | 399 | 40+ regras de negócio por módulo |
| `08-inline-create-ux.md` | — | UX patterns para criação inline |
| `09-ebd-evolucao-modulo.md` | ~1.470 | Evolução do módulo EBD — especificação E1-E7 + F1 + registro de implementação |
| `10-modulo-congregacoes.md` | ~1.544 | Módulo de Congregações — modelo de dados, regras de negócio, API, frontend, plano de implementação |

**Documento adicional:**
- `SKILL.md` (`.github/skills/frontend/SKILL.md`) — Guia de estética: "Sacred Geometry meets Modern Editorial" (DM Serif Display + Source Sans 3, paleta navy #0D1B2A + gold #D4A843)

---

## 3. Banco de Dados — ✅ 100% do Schema Definido

### 3.1 Infraestrutura

| Componente | Versão | Status |
|------------|--------|--------|
| PostgreSQL | 16-alpine | ✅ Configurado via `docker-compose.yml` |
| Redis | 7-alpine | ✅ Configurado via `docker-compose.yml` |
| Extensões | uuid-ossp, pgcrypto, unaccent | ✅ Ativadas no `init.sql` |

### 3.2 Tabelas Criadas (Migrations: `initial.sql` + `password_reset_tokens.sql` + `ebd_evolution.sql` + `congregations.sql`)

**Total: 31 tabelas, 6 views, 25+ triggers, 3 extensões**

#### Módulo Sistema (5 tabelas)

| Tabela | Campos | Seeds | Utilizada no Backend? |
|--------|:------:|:-----:|:---------------------:|
| `churches` | 22 | — | ✅ Sim (entity definida) |
| `roles` | 8 | 7 papéis padrão | ✅ Sim (consultada no login) |
| `users` | 14 | — | ✅ Sim (autenticação) |
| `refresh_tokens` | 6 | — | ✅ Sim (refresh flow) |
| `audit_logs` | 9 | — | ✅ Escrita via AuditService (Members, Assets, Financial, Churches, Users) |

**Papéis pré-definidos (seeds):**
1. `super_admin` — Administrador Geral do Sistema
2. `admin` — Administrador da Igreja
3. `pastor` — Pastor
4. `secretary` — Secretário(a)
5. `treasurer` — Tesoureiro(a)
6. `teacher` — Professor(a) EBD
7. `member` — Membro

#### Módulo Membros (6 tabelas)

| Tabela | Campos | Utilizada no Backend? | Utilizada no Frontend? |
|--------|:------:|:---------------------:|:----------------------:|
| `members` | 35+ | ✅ CRUD completo | ✅ Lista + Detalhe + Form |
| `families` | 5 | ✅ CRUD completo | ✅ Lista + Detalhe + Form |
| `family_relationships` | 5 | ✅ Add/Remove | ✅ Add/Remove na UI |
| `ministries` | 7 | ✅ CRUD completo | ✅ Lista + Detalhe + Form |
| `member_ministries` | 5 | ✅ Add/Remove | ✅ Add/Remove na UI |
| `member_history` | 6 | ✅ List/Create | ✅ Timeline + Criar evento |

#### Módulo Financeiro (5 tabelas)

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `account_plans` | 8 | ✅ CRUD (list/create/update) | ✅ Lista + criação |
| `bank_accounts` | 10 | ✅ CRUD (list/create/update) | ✅ Lista + criação |
| `campaigns` | 10 | ✅ CRUD (list/get/create/update) | ✅ Lista + criação + progresso |
| `financial_entries` | 15 | ✅ CRUD completo + relatório de saldo | ✅ Lista + filtros + formulário |
| `monthly_closings` | 10 | ✅ List + fechamento mensal | ✅ Lista + criação |

#### Módulo Patrimônio (7 tabelas)

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `asset_categories` | 5 | ✅ CRUD (list/create/update) | ✅ Lista + criação |
| `assets` | 20 | ✅ CRUD completo (list/get/create/update/delete) | ✅ Overview + Lista + Detalhe + Form |
| `asset_photos` | 6 | ❌ Entity existe, sem upload | ❌ |
| `maintenances` | 10 | ✅ CRUD (list/create/update) | ✅ Lista + filtros + criação |
| `inventories` | 7 | ✅ CRUD (list/get/create/update_item/close) | ✅ Lista + criar + fechar |
| `inventory_items` | 7 | ✅ Auto-populado + atualização | ✅ (via inventário) |
| `asset_loans` | 8 | ✅ CRUD (list/create/return) | ✅ Lista + registro + devolução |

#### Módulo EBD (10 tabelas + 1 view) — ✅ Evolução E1-E7 implementada

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `ebd_terms` | 7 | ✅ CRUD (list/get/create/update) | ✅ Lista + criação |
| `ebd_classes` | 8 | ✅ CRUD (list/get/create/update) + clone | ✅ Lista + Detalhe + matrículas |
| `ebd_enrollments` | 5 | ✅ List/Create/Remove | ✅ Matricular/Remover na UI |
| `ebd_lessons` | 10 | ✅ CRUD completo (list/get/create/update/delete) | ✅ Lista + criação |
| `ebd_attendances` | 7 | ✅ Record batch (com notes)/get by lesson/report | ✅ Tela de frequência (P/A/J) |
| `ebd_lesson_contents` | 10 | ✅ CRUD + reorder (5 endpoints) — **NOVO E1** | ✅ Aba "Conteúdo" no detalhe da lição |
| `ebd_lesson_activities` | 10 | ✅ CRUD (4 endpoints) — **NOVO E2** | ✅ Aba "Atividades" + Respostas |
| `ebd_activity_responses` | 7 | ✅ List/Record/Update (3 endpoints) — **NOVO E2** | ✅ Tela de respostas |
| `ebd_lesson_materials` | 8 | ✅ List/Create/Delete (3 endpoints) — **NOVO E4** | ✅ Aba "Materiais" |
| `ebd_student_notes` | 8 | ✅ CRUD (4 endpoints) — **NOVO E5** | ✅ Seção no perfil + edição |

#### Módulo Congregações (2 tabelas + 2 views) — ✅ NOVO

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `congregations` | 17 | ✅ CRUD + Stats + Assign Members | ✅ Lista + Detalhe + Form |
| `user_congregations` | 5 | ✅ Add/Remove/List users | ✅ Lista na tela de detalhe |

**Alterações em tabelas existentes:** coluna `congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL` adicionada em 11 tabelas: `members`, `financial_entries`, `bank_accounts`, `campaigns`, `monthly_closings`, `account_plans`, `ebd_terms`, `ebd_classes`, `assets`, `inventories`, `ministries`.

#### Views e Triggers

| View | Propósito |
|------|-----------|
| `vw_member_stats` | Estatísticas de membros por status/gênero por igreja |
| `vw_account_balances` | Saldos correntes de contas bancárias |
| `vw_ebd_class_attendance` | Frequência de alunos por turma/aula |
| `vw_ebd_student_profile` | Perfil unificado do aluno EBD (histórico + frequência acumulada) — **NOVO E3** |
| `vw_congregation_member_stats` | Estatísticas de membros por congregação (ativos, visitantes, congregados, total) — **NOVO** |
| `vw_congregation_financial_summary` | Resumo financeiro por congregação (receita, despesa, saldo por mês) — **NOVO** |

- **18 triggers** `update_updated_at` em tabelas com coluna `updated_at`
- **1 trigger** `update_campaign_balance` para atualizar saldo de campanhas
- **1 trigger** `generate_asset_code` para gerar código sequencial de patrimônio

---

## 4. Backend (Rust/Actix-Web) — Detalhamento

### 4.1 Configuração do Projeto

| Item | Valor |
|------|-------|
| Rust Edition | 2024 |
| Rust Version | 1.85+ |
| Framework | Actix-Web 4.13 |
| ORM | SQLx 0.8 (runtime queries) |
| Build Status | ✅ **Compila com sucesso** (0 errors, 0 warnings) |

#### Dependências Principais (`Cargo.toml`)

| Categoria | Crate | Versão | Status |
|-----------|-------|--------|--------|
| Web | `actix-web` | 4.13 | ✅ Em uso |
| Web | `actix-cors` | 0.7 | ✅ Em uso |
| Web | `actix-multipart` | 0.7 | ⚠️ Importado, não utilizado |
| Async | `tokio` | 1.49 | ✅ Em uso |
| Serialização | `serde` / `serde_json` | 1.0 | ✅ Em uso |
| Banco | `sqlx` | 0.8 | ✅ Em uso |
| Auth | `jsonwebtoken` | 10.3 | ✅ Em uso |
| Auth | `argon2` | 0.5 | ✅ Em uso |
| Cache | `redis` | 1.0 | ✅ Em uso — CacheService integrado em stats + write handlers |
| Email | `lettre` | 0.11 | ✅ Em uso — Forgot/Reset password via SMTP |
| Docs | `utoipa` / `utoipa-swagger-ui` | 5.4 / 9.0 | ✅ Swagger UI montado em `/swagger-ui/` |
| Validação | `validator` | 0.20 | ✅ Em uso |
| Tipos | `uuid`, `chrono`, `rust_decimal` | Latest | ✅ Em uso |

### 4.2 Arquitetura de Camadas

```
backend/src/
├── main.rs              ← Entry point: Actix-Web server, CORS, routes
├── config/mod.rs        ← AppConfig (env vars)
├── errors.rs            ← AppError enum com ResponseError
├── api/
│   ├── response.rs      ← ApiResponse<T>, PaginationMeta
│   ├── middleware.rs     ← JWT auth middleware
│   └── handlers/
│       ├── health_handler.rs
│       ├── auth_handler.rs
│       ├── church_handler.rs     ← CRUD igrejas (5 endpoints)
│       ├── user_handler.rs       ← CRUD usuários + roles (5 endpoints)
│       ├── member_handler.rs
│       ├── family_handler.rs
│       ├── ministry_handler.rs
│       ├── member_history_handler.rs
│       ├── financial_handler.rs
│       ├── asset_handler.rs
│       ├── ebd_handler.rs       ← 48+ endpoints (Evolução E1-E7 + F1 + Reports)
│       └── congregation_handler.rs ← NOVO — 12 endpoints (CRUD + Stats + Users + Assign + Reports)
├── application/
│   ├── dto/
│   │   ├── auth_dto.rs      ← LoginRequest, Claims, etc.
│   │   ├── church_dto.rs    ← CreateChurchRequest, UpdateChurchRequest
│   │   ├── user_dto.rs      ← CreateUserRequest, UpdateUserRequest
│   │   ├── member_dto.rs    ← CreateMemberRequest, MemberFilter, etc.
│   │   ├── member_history_dto.rs ← CreateMemberHistoryRequest
│   │   ├── family_dto.rs    ← CreateFamilyRequest, AddFamilyMemberRequest
│   │   ├── ministry_dto.rs  ← CreateMinistryRequest, AddMinistryMemberRequest
│   │   ├── financial_dto.rs ← CreateFinancialEntryRequest, etc.
│   │   ├── asset_dto.rs     ← CreateAssetRequest, AssetFilter, etc.
│   │   ├── ebd_dto.rs       ← 30+ DTOs: Terms, Classes, Lessons, Contents, Activities, Responses, Materials, Students, Notes, Clone, Reports
│   │   └── congregation_dto.rs ← NOVO — CreateCongregationRequest, UpdateCongregationRequest, AssignMembersRequest, etc.
│   └── services/
│       ├── auth_service.rs   ← Hashing, JWT, login flow
│       ├── audit_service.rs  ← AuditService::log() integrado em 6 módulos (Members, Assets, Financial, Churches, Users, EBD)
│       ├── church_service.rs ← CRUD igrejas
│       ├── user_service.rs   ← CRUD usuários + roles
│       ├── member_service.rs ← CRUD completo + stats + histórico
│       ├── member_history_service.rs ← Histórico de eventos do membro
│       ├── family_service.rs ← CRUD famílias + membros
│       ├── ministry_service.rs ← CRUD ministérios + membros
│       ├── account_plan_service.rs ← CRUD plano de contas
│       ├── bank_account_service.rs ← CRUD contas bancárias
│       ├── campaign_service.rs ← CRUD campanhas financeiras
│       ├── financial_service.rs ← Lançamentos + Fechamento mensal + Relatórios
│       ├── asset_category_service.rs ← CRUD categorias patrimônio
│       ├── asset_service.rs  ← CRUD bens patrimoniais
│       ├── asset_loan_service.rs ← Empréstimos de bens
│       ├── maintenance_service.rs ← Manutenções
│       ├── inventory_service.rs ← Inventários
│       ├── ebd_term_service.rs ← CRUD períodos EBD
│       ├── ebd_class_service.rs ← CRUD turmas + matrículas + clone (E7)
│       ├── ebd_lesson_service.rs ← CRUD aulas (com update/delete — F1.2)
│       ├── ebd_attendance_service.rs ← Frequência + relatórios (com notes — F1.5)
│       ├── ebd_lesson_content_service.rs ← Conteúdo enriquecido de lições (E1)
│       ├── ebd_lesson_activity_service.rs ← Atividades + respostas (E2)
│       ├── ebd_lesson_material_service.rs ← Materiais e recursos (E4)
│       ├── ebd_student_note_service.rs ← Anotações do professor (E5)
│       ├── ebd_student_service.rs ← Perfil unificado do aluno (E3)
│       ├── ebd_report_service.rs ← Relatórios avançados (E6)
│       └── congregation_service.rs ← NOVO — CRUD + Stats + Users + Assign Members + Overview (~450 linhas)
├── domain/entities/
│   ├── church.rs
│   ├── user.rs              ← User, Role, RefreshToken
│   ├── member.rs            ← Member (62 campos), MemberSummary
│   ├── member_history.rs    ← MemberHistory
│   ├── family.rs            ← Family, FamilyDetail, FamilyMemberInfo
│   ├── ministry.rs          ← Ministry, MinistrySummary, MinistryMemberInfo
│   ├── account_plan.rs      ← AccountPlan, AccountPlanSummary
│   ├── bank_account.rs      ← BankAccount
│   ├── campaign.rs          ← Campaign, CampaignSummary
│   ├── financial_entry.rs   ← FinancialEntry, FinancialEntrySummary, FinancialBalance
│   ├── monthly_closing.rs   ← MonthlyClosing, MonthlyClosingSummary
│   ├── asset.rs              ← Asset, AssetSummary, AssetPhoto
│   ├── asset_category.rs    ← AssetCategory, AssetCategorySummary
│   ├── asset_loan.rs        ← AssetLoan, AssetLoanSummary
│   ├── inventory.rs          ← Inventory, InventoryItem, InventoryItemDetail
│   ├── maintenance.rs        ← Maintenance, MaintenanceSummary
│   ├── ebd_term.rs           ← EbdTerm
│   ├── ebd_class.rs          ← EbdClass, EbdClassSummary
│   ├── ebd_enrollment.rs     ← EbdEnrollment, EbdEnrollmentDetail
│   ├── ebd_lesson.rs         ← EbdLesson, EbdLessonSummary
│   ├── ebd_attendance.rs     ← EbdAttendance, EbdAttendanceDetail (com notes)
│   ├── ebd_lesson_content.rs ← EbdLessonContent (E1)
│   ├── ebd_lesson_activity.rs ← EbdLessonActivity (E2)
│   ├── ebd_activity_response.rs ← EbdActivityResponse (E2)
│   ├── ebd_lesson_material.rs ← EbdLessonMaterial (E4)
│   ├── ebd_student_note.rs   ← EbdStudentNote (E5)
│   └── ebd_student_profile.rs ← EbdStudentProfile (E3 — view)
│   └── congregation.rs       ← NOVO — Congregation, CongregationSummary, CongregationStats, UserCongregation, AssignMembersResult, CongregationsOverview
└── infrastructure/
    ├── database.rs          ← Pool de conexões PG
    └── cache.rs             ← CacheService (get/set/del/del_pattern)
```

### 4.3 Endpoints Implementados

#### Saúde

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| `GET` | `/api/health` | Health check com verificação do banco | ✅ Completo |

#### Igrejas (5 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/churches` | ✅ `super_admin` | Listar todas as igrejas | ✅ Completo |
| `GET` | `/api/v1/churches/me` | ✅ JWT | Dados da igreja do usuário logado | ✅ Completo |
| `GET` | `/api/v1/churches/{id}` | ✅ JWT | Detalhes da igreja | ✅ Completo |
| `POST` | `/api/v1/churches` | ✅ `super_admin` | Criar nova igreja | ✅ Completo |
| `PUT` | `/api/v1/churches/{id}` | ✅ `settings:write` | Atualizar igreja | ✅ Completo |

#### Usuários & Papéis (5 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/users` | ✅ `settings:read` | Listar usuários da igreja | ✅ Completo |
| `GET` | `/api/v1/users/{id}` | ✅ `settings:read` | Detalhes do usuário | ✅ Completo |
| `POST` | `/api/v1/users` | ✅ `settings:write` | Criar novo usuário | ✅ Completo |
| `PUT` | `/api/v1/users/{id}` | ✅ `settings:write` | Atualizar usuário | ✅ Completo |
| `GET` | `/api/v1/roles` | ✅ `settings:read` | Listar papéis disponíveis | ✅ Completo |

#### Autenticação (6 endpoints)

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| `POST` | `/api/v1/auth/login` | Login com email/senha | ✅ Completo |
| `POST` | `/api/v1/auth/refresh` | Renovação de token | ✅ Completo |
| `POST` | `/api/v1/auth/logout` | Logout (revoga tokens) | ✅ Completo |
| `GET` | `/api/v1/auth/me` | Perfil do usuário autenticado | ✅ Completo |
| `POST` | `/api/v1/auth/forgot-password` | Solicitar redefinição de senha (envia token por e-mail) | ✅ Completo |
| `POST` | `/api/v1/auth/reset-password` | Redefinir senha com token | ✅ Completo |

**Funcionalidades de segurança implementadas:**
- Hash de senha com Argon2
- JWT com claims (sub, church_id, role, permissions, exp, iat)
- Refresh token (random base64, armazenado no banco)
- Bloqueio de conta após 5 tentativas falhas (15 min de lock)
- Rastreamento de `failed_attempts` e `locked_until`
- Reset de senha com token de 6 caracteres (30 min de expiração)
- Proteção contra enumeração de e-mails (sempre retorna sucesso)
- Revogação de todos os refresh tokens ao redefinir senha

#### Membros (8 endpoints)

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/members` | ✅ JWT | Listar com paginação | ✅ Funcional |
| `GET` | `/api/v1/members/stats` | ✅ JWT | Estatísticas dos membros | ✅ Completo |
| `GET` | `/api/v1/members/{id}` | ✅ JWT | Buscar por ID | ✅ Completo |
| `POST` | `/api/v1/members` | ✅ `members:create` | Criar membro (35 campos) | ✅ Completo |
| `PUT` | `/api/v1/members/{id}` | ✅ `members:update` | Atualizar membro (campos dinâmicos) | ✅ Completo |
| `DELETE` | `/api/v1/members/{id}` | ✅ `members:delete` | Soft delete | ✅ Completo |
| `GET` | `/api/v1/members/{id}/history` | ✅ JWT | Histórico de eventos do membro | ✅ Completo |
| `POST` | `/api/v1/members/{id}/history` | ✅ `members:write` | Registrar evento no histórico | ✅ Completo |

#### Famílias (7 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/families` | ✅ JWT | Listar famílias com paginação | ✅ Completo |
| `GET` | `/api/v1/families/{id}` | ✅ JWT | Detalhes da família com membros | ✅ Completo |
| `POST` | `/api/v1/families` | ✅ `members:write` | Criar família (com membros opcionais) | ✅ Completo |
| `PUT` | `/api/v1/families/{id}` | ✅ `members:write` | Atualizar família | ✅ Completo |
| `DELETE` | `/api/v1/families/{id}` | ✅ `members:delete` | Remover família (desvincula membros) | ✅ Completo |
| `POST` | `/api/v1/families/{id}/members` | ✅ `members:write` | Adicionar membro à família | ✅ Completo |
| `DELETE` | `/api/v1/families/{fid}/members/{mid}` | ✅ `members:write` | Remover membro da família | ✅ Completo |

#### Ministérios (8 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ministries` | ✅ JWT | Listar ministérios (com contagem de membros) | ✅ Completo |
| `GET` | `/api/v1/ministries/{id}` | ✅ JWT | Detalhes do ministério | ✅ Completo |
| `POST` | `/api/v1/ministries` | ✅ `members:write` | Criar ministério | ✅ Completo |
| `PUT` | `/api/v1/ministries/{id}` | ✅ `members:write` | Atualizar ministério | ✅ Completo |
| `DELETE` | `/api/v1/ministries/{id}` | ✅ `members:delete` | Remover ministério | ✅ Completo |
| `GET` | `/api/v1/ministries/{id}/members` | ✅ JWT | Listar membros do ministério | ✅ Completo |
| `POST` | `/api/v1/ministries/{id}/members` | ✅ `members:write` | Adicionar membro ao ministério | ✅ Completo |
| `DELETE` | `/api/v1/ministries/{mid}/members/{id}` | ✅ `members:write` | Remover membro do ministério | ✅ Completo |

#### Financeiro (18 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/financial/account-plans` | ✅ `financial:read` | Listar plano de contas | ✅ Completo |
| `POST` | `/api/v1/financial/account-plans` | ✅ `financial:write` | Criar categoria | ✅ Completo |
| `PUT` | `/api/v1/financial/account-plans/{id}` | ✅ `financial:write` | Atualizar categoria | ✅ Completo |
| `GET` | `/api/v1/financial/bank-accounts` | ✅ `financial:read` | Listar contas bancárias | ✅ Completo |
| `POST` | `/api/v1/financial/bank-accounts` | ✅ `financial:write` | Criar conta bancária | ✅ Completo |
| `PUT` | `/api/v1/financial/bank-accounts/{id}` | ✅ `financial:write` | Atualizar conta bancária | ✅ Completo |
| `GET` | `/api/v1/financial/campaigns` | ✅ `financial:read` | Listar campanhas | ✅ Completo |
| `GET` | `/api/v1/financial/campaigns/{id}` | ✅ `financial:read` | Detalhes da campanha | ✅ Completo |
| `POST` | `/api/v1/financial/campaigns` | ✅ `financial:write` | Criar campanha | ✅ Completo |
| `PUT` | `/api/v1/financial/campaigns/{id}` | ✅ `financial:write` | Atualizar campanha | ✅ Completo |
| `GET` | `/api/v1/financial/entries` | ✅ `financial:read` | Listar lançamentos (9 filtros) | ✅ Completo |
| `GET` | `/api/v1/financial/entries/{id}` | ✅ `financial:read` | Detalhes do lançamento | ✅ Completo |
| `POST` | `/api/v1/financial/entries` | ✅ `financial:write` | Criar lançamento (atualiza saldo) | ✅ Completo |
| `PUT` | `/api/v1/financial/entries/{id}` | ✅ `financial:write` | Atualizar lançamento (controle de fechamento) | ✅ Completo |
| `DELETE` | `/api/v1/financial/entries/{id}` | ✅ `financial:write` | Cancelar lançamento (soft delete + estorno) | ✅ Completo |
| `GET` | `/api/v1/financial/reports/balance` | ✅ `financial:read` | Balancete por período (receitas/despesas por categoria) | ✅ Completo |
| `GET` | `/api/v1/financial/monthly-closings` | ✅ `financial:read` | Listar fechamentos mensais | ✅ Completo |
| `POST` | `/api/v1/financial/monthly-closings` | ✅ `financial:close` | Realizar fechamento mensal (snapshot + lock) | ✅ Completo |

#### Patrimônio (17 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/assets/categories` | ✅ `assets:read` | Listar categorias de patrimônio | ✅ Completo |
| `POST` | `/api/v1/assets/categories` | ✅ `assets:write` | Criar categoria | ✅ Completo |
| `PUT` | `/api/v1/assets/categories/{id}` | ✅ `assets:write` | Atualizar categoria | ✅ Completo |
| `GET` | `/api/v1/assets` | ✅ `assets:read` | Listar bens (4 filtros + busca) | ✅ Completo |
| `GET` | `/api/v1/assets/{id}` | ✅ `assets:read` | Detalhes do bem | ✅ Completo |
| `POST` | `/api/v1/assets` | ✅ `assets:write` | Cadastrar bem (17 campos) | ✅ Completo |
| `PUT` | `/api/v1/assets/{id}` | ✅ `assets:write` | Atualizar bem (17 campos dinâmicos) | ✅ Completo |
| `DELETE` | `/api/v1/assets/{id}` | ✅ `assets:delete` | Baixa de bem (soft delete + motivo) | ✅ Completo |
| `GET` | `/api/v1/assets/maintenances` | ✅ `assets:read` | Listar manutenções (filtros: asset, status, tipo) | ✅ Completo |
| `POST` | `/api/v1/assets/maintenances` | ✅ `assets:write` | Registrar manutenção (altera status do bem) | ✅ Completo |
| `PUT` | `/api/v1/assets/maintenances/{id}` | ✅ `assets:write` | Atualizar manutenção (retorna bem ao ativo) | ✅ Completo |
| `GET` | `/api/v1/assets/inventories` | ✅ `assets:read` | Listar inventários | ✅ Completo |
| `GET` | `/api/v1/assets/inventories/{id}` | ✅ `assets:read` | Detalhes do inventário + itens | ✅ Completo |
| `POST` | `/api/v1/assets/inventories` | ✅ `assets:write` | Criar inventário (auto-popula itens) | ✅ Completo |
| `PUT` | `/api/v1/assets/inventories/{inv_id}/items/{item_id}` | ✅ `assets:write` | Atualizar item do inventário | ✅ Completo |
| `POST` | `/api/v1/assets/inventories/{id}/close` | ✅ `assets:write` | Fechar inventário (valida pendências) | ✅ Completo |
| `GET` | `/api/v1/assets/loans` | ✅ `assets:read` | Listar empréstimos (filtro: status) | ✅ Completo |
| `POST` | `/api/v1/assets/loans` | ✅ `assets:write` | Registrar empréstimo (valida disponibilidade) | ✅ Completo |
| `PUT` | `/api/v1/assets/loans/{id}/return` | ✅ `assets:write` | Devolver bem emprestado | ✅ Completo |
| `GET` | `/api/v1/assets/stats` | ✅ `assets:read` | Estatísticas de patrimônio (dashboard) | ✅ Completo |

#### EBD — Escola Bíblica Dominical (44 endpoints) — ✅ Evolução E1-E7 + F1

##### Períodos (4 endpoints)

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/terms` | ✅ `ebd:read` | Listar períodos/trimestres | ✅ Completo |
| `GET` | `/api/v1/ebd/terms/{id}` | ✅ `ebd:read` | Detalhes do período | ✅ Completo |
| `POST` | `/api/v1/ebd/terms` | ✅ `ebd:write` | Criar período (desativa anteriores — RN-EBD-001) | ✅ Completo |
| `PUT` | `/api/v1/ebd/terms/{id}` | ✅ `ebd:write` | Atualizar período | ✅ Completo |

##### Turmas (4 endpoints)

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/classes` | ✅ `ebd:read` | Listar turmas (filtros: term, teacher, status) | ✅ Completo |
| `GET` | `/api/v1/ebd/classes/{id}` | ✅ `ebd:read` | Detalhes da turma | ✅ Completo |
| `POST` | `/api/v1/ebd/classes` | ✅ `ebd:write` | Criar turma | ✅ Completo |
| `PUT` | `/api/v1/ebd/classes/{id}` | ✅ `ebd:write` | Atualizar turma | ✅ Completo |

##### Matrículas (3 endpoints)

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/classes/{id}/enrollments` | ✅ `ebd:read` | Listar matrículas da turma | ✅ Completo |
| `POST` | `/api/v1/ebd/classes/{id}/enrollments` | ✅ `ebd:write` | Matricular membro (RN-EBD-003: 1 por turma/período) | ✅ Completo |
| `DELETE` | `/api/v1/ebd/classes/{id}/enrollments/{eid}` | ✅ `ebd:write` | Remover matrícula | ✅ Completo |

##### Aulas (5 endpoints) — F1.2: update/delete adicionados

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/lessons` | ✅ `ebd:read` | Listar aulas (filtros: class, date range) | ✅ Completo |
| `GET` | `/api/v1/ebd/lessons/{id}` | ✅ `ebd:read` | Detalhes da aula | ✅ Completo |
| `POST` | `/api/v1/ebd/lessons` | ✅ `ebd:write` | Criar aula | ✅ Completo |
| `PUT` | `/api/v1/ebd/lessons/{id}` | ✅ `ebd:write` | Atualizar aula — **NOVO F1.2** | ✅ Completo |
| `DELETE` | `/api/v1/ebd/lessons/{id}` | ✅ `ebd:write` | Excluir aula — **NOVO F1.2** | ✅ Completo |

##### Frequência + Relatório + Stats (4 endpoints) — F1.5: notes em attendance

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `POST` | `/api/v1/ebd/lessons/{id}/attendance` | ✅ `ebd:write` | Registrar frequência em lote (RN-EBD-004: 7 dias) + campo notes | ✅ Completo |
| `GET` | `/api/v1/ebd/lessons/{id}/attendance` | ✅ `ebd:read` | Listar frequência da aula | ✅ Completo |
| `GET` | `/api/v1/ebd/classes/{id}/report` | ✅ `ebd:read` | Relatório de frequência da turma | ✅ Completo |
| `GET` | `/api/v1/ebd/stats` | ✅ `ebd:read` | Estatísticas da EBD (dashboard, cached) | ✅ Completo |

##### Conteúdo Enriquecido de Lições (5 endpoints) — NOVO E1

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/lessons/{id}/contents` | ✅ `ebd:read` | Listar blocos de conteúdo (ordenados) | ✅ Completo |
| `POST` | `/api/v1/ebd/lessons/{id}/contents` | ✅ `ebd:write` | Criar bloco de conteúdo (text/image/bible_ref/note) | ✅ Completo |
| `PUT` | `/api/v1/ebd/lessons/{lid}/contents/{cid}` | ✅ `ebd:write` | Atualizar bloco de conteúdo | ✅ Completo |
| `DELETE` | `/api/v1/ebd/lessons/{lid}/contents/{cid}` | ✅ `ebd:write` | Remover bloco de conteúdo | ✅ Completo |
| `PUT` | `/api/v1/ebd/lessons/{id}/contents/reorder` | ✅ `ebd:write` | Reordenar blocos | ✅ Completo |

##### Atividades por Lição (4 endpoints) — NOVO E2

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/lessons/{id}/activities` | ✅ `ebd:read` | Listar atividades da lição | ✅ Completo |
| `POST` | `/api/v1/ebd/lessons/{id}/activities` | ✅ `ebd:write` | Criar atividade (question/multiple_choice/homework/etc.) | ✅ Completo |
| `PUT` | `/api/v1/ebd/lessons/{lid}/activities/{aid}` | ✅ `ebd:write` | Atualizar atividade | ✅ Completo |
| `DELETE` | `/api/v1/ebd/lessons/{lid}/activities/{aid}` | ✅ `ebd:write` | Remover atividade | ✅ Completo |

##### Respostas de Atividades (3 endpoints) — NOVO E2

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/activities/{aid}/responses` | ✅ `ebd:read` | Listar respostas de uma atividade | ✅ Completo |
| `POST` | `/api/v1/ebd/activities/{aid}/responses` | ✅ `ebd:write` | Registrar respostas em lote | ✅ Completo |
| `PUT` | `/api/v1/ebd/activities/{aid}/responses/{rid}` | ✅ `ebd:write` | Atualizar resposta individual | ✅ Completo |

##### Materiais e Recursos (3 endpoints) — NOVO E4

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/lessons/{id}/materials` | ✅ `ebd:read` | Listar materiais da lição | ✅ Completo |
| `POST` | `/api/v1/ebd/lessons/{id}/materials` | ✅ `ebd:write` | Adicionar material (link/document/video/image/audio/other) | ✅ Completo |
| `DELETE` | `/api/v1/ebd/lessons/{lid}/materials/{mid}` | ✅ `ebd:write` | Remover material | ✅ Completo |

##### Perfil Unificado do Aluno EBD (4 endpoints) — NOVO E3

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/students` | ✅ `ebd:read` | Listar alunos EBD (com filtros: class, term, search) | ✅ Completo |
| `GET` | `/api/v1/ebd/students/{mid}/profile` | ✅ `ebd:read` | Perfil unificado do aluno (frequência acumulada, turmas, etc.) | ✅ Completo |
| `GET` | `/api/v1/ebd/students/{mid}/history` | ✅ `ebd:read` | Histórico de turmas do aluno | ✅ Completo |
| `GET` | `/api/v1/ebd/students/{mid}/activities` | ✅ `ebd:read` | Atividades e respostas do aluno | ✅ Completo |

##### Anotações do Professor por Aluno (4 endpoints) — NOVO E5

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/students/{mid}/notes` | ✅ `ebd:read` | Listar anotações do professor sobre o aluno | ✅ Completo |
| `POST` | `/api/v1/ebd/students/{mid}/notes` | ✅ `ebd:write` | Criar anotação (observation/concern/praise/follow_up/other) | ✅ Completo |
| `PUT` | `/api/v1/ebd/students/{mid}/notes/{nid}` | ✅ `ebd:write` | Atualizar anotação | ✅ Completo |
| `DELETE` | `/api/v1/ebd/students/{mid}/notes/{nid}` | ✅ `ebd:write` | Remover anotação | ✅ Completo |

##### Clonagem de Turmas (1 endpoint) — NOVO E7

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `POST` | `/api/v1/ebd/terms/{id}/clone-classes` | ✅ `ebd:write` | Clonar turmas de outro período (com matrículas opcionais) | ✅ Completo |

##### Relatórios Avançados (4 endpoints) — NOVO E6

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/ebd/reports/term/{id}` | ✅ `ebd:read` | Relatório resumo do trimestre (total aulas, frequência média, etc.) | ✅ Completo |
| `GET` | `/api/v1/ebd/reports/term/{id}/ranking` | ✅ `ebd:read` | Ranking de alunos por frequência no trimestre | ✅ Completo |
| `GET` | `/api/v1/ebd/reports/comparison` | ✅ `ebd:read` | Comparativo de frequência entre trimestres | ✅ Completo |
| `GET` | `/api/v1/ebd/reports/absent-students` | ✅ `ebd:read` | Alunos com maior número de faltas consecutivas | ✅ Completo |

##### Exclusão de Termos e Turmas (2 endpoints) — NOVO F1.10

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `DELETE` | `/api/v1/ebd/terms/{id}` | ✅ `ebd:write` | Excluir trimestre (transacional: aulas → turmas → notas → período) | ✅ Completo |
| `DELETE` | `/api/v1/ebd/classes/{id}` | ✅ `ebd:write` | Excluir turma (transacional: aulas → turma) | ✅ Completo |

#### Congregações (12 endpoints) — ✅ NOVO

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/congregations` | ✅ JWT | Listar congregações (filtros: is_active, type) | ✅ Completo |
| `GET` | `/api/v1/congregations/{id}` | ✅ JWT | Detalhes da congregação | ✅ Completo |
| `POST` | `/api/v1/congregations` | ✅ `settings:write` | Criar congregação (RN-CONG-001 sede única, RN-CONG-002 líder ativo) | ✅ Completo |
| `PUT` | `/api/v1/congregations/{id}` | ✅ `settings:write` | Atualizar congregação (campos dinâmicos) | ✅ Completo |
| `DELETE` | `/api/v1/congregations/{id}` | ✅ `settings:write` | Desativar congregação (sede não pode ser desativada) | ✅ Completo |
| `GET` | `/api/v1/congregations/{id}/stats` | ✅ JWT | Estatísticas da congregação (membros + financeiro) | ✅ Completo |
| `GET` | `/api/v1/congregations/{id}/users` | ✅ JWT | Listar usuários da congregação | ✅ Completo |
| `POST` | `/api/v1/congregations/{id}/users` | ✅ `settings:write` | Adicionar usuário à congregação (com role) | ✅ Completo |
| `DELETE` | `/api/v1/congregations/{cid}/users/{uid}` | ✅ `settings:write` | Remover usuário da congregação | ✅ Completo |
| `POST` | `/api/v1/congregations/{id}/assign-members` | ✅ `settings:write` | Associar membros em lote (com overwrite opcional) | ✅ Completo |
| `POST` | `/api/v1/user/active-congregation` | ✅ JWT | Definir congregação ativa do usuário logado | ✅ Completo |
| `GET` | `/api/v1/reports/congregations/overview` | ✅ JWT | Relatório visão geral de todas as congregações | ✅ Completo |

### 4.4 O que Falta no Backend

#### Prioridade Alta

| Item | Descrição | Complexidade |
|------|-----------|:------------:|
| `PUT /api/v1/members/{id}` | Atualização de membro — DTO já existe (`UpdateMemberRequest`) | ~~Média~~ ✅ **Concluído** |
| Filtros dinâmicos em `list()` | SQL dinâmico com BindValue enum (11 parâmetros) | ~~Baixa~~ ✅ **Concluído** |
| Swagger UI montado | ~~Anotações `utoipa` existem, falta montar o endpoint `/swagger-ui`~~ ✅ **Concluído** — Swagger UI montado em `/swagger-ui/` | ~~Baixa~~ ✅ |
| `POST /api/v1/auth/forgot-password` | ~~Recuperação de senha — SMTP já nas dependências~~ ✅ **Concluído** — Forgot + Reset password (token 6 chars, 30min TTL, envio via lettre SMTP) | ~~Média~~ ✅ |
| CRUD de Igrejas | ~~Entity `Church` existe, sem handler/service~~ ✅ **Concluído** — 5 endpoints (list/get/get-me/create/update) | ~~Média~~ ✅ |
| CRUD de Usuários/Papéis | ~~Tabelas existem, sem API~~ ✅ **Concluído** — 5 endpoints (list/get/create/update users + list roles) | ~~Média~~ ✅ |

#### Prioridade Média

| Item | Descrição | Complexidade |
|------|-----------|:------------:|
| Módulo Financeiro completo | ~~5 tabelas prontas, 11 endpoints documentados~~ ✅ **Backend completo (18 endpoints)** | ~~Alta~~ ✅ |
| Módulo EBD completo | ~~5 tabelas prontas, 7 endpoints documentados~~ ✅ **Backend completo (48+ endpoints com stats + reports) — Evolução E1-E7 + F1** | ~~Alta~~ ✅ |
| Módulo Patrimônio completo | ~~7 tabelas prontas, 7 endpoints documentados~~ ✅ **Backend completo (18 endpoints com stats)** | ~~Alta~~ ✅ |
| Famílias e Ministérios | ~~Tabelas prontas, endpoints documentados~~ ✅ **Backend + Frontend completos** | ~~Média~~ ✅ |
| Audit Log (escrita) | ~~Tabela existe, falta interceptar ações~~ ✅ **Concluído** — `AuditService::log()` + `log_action()`, integrado em Members, Assets, Financial, Churches, Users e **EBD** (13 handlers) | ~~Média~~ ✅ |
| Cache Redis | ~~Crate importado, não configurado~~ ✅ **Concluído** — `CacheService` (get/set/del/del_pattern), integrado em stats endpoints (Members, Assets, EBD) + cache invalidation em write handlers | ~~Média~~ ✅ |

#### Prioridade Baixa

| Item | Descrição |
|------|-----------|
| Upload de arquivos (fotos) | ✅ **Concluído** — Cloudinary integration (backend `CloudinaryService` + upload handler) + Flutter `ImageUploadService` com compressão |
| Upload de imagens em Lesson Contents (E1) | ✅ **Concluído** — Endpoint `POST /api/v1/upload/image` + `DELETE /api/v1/upload/image` via Cloudinary |
| Repository traits (Clean Arch.) | Documentado mas usando queries diretas nos services |
| Domain enums tipados | Usando strings raw em vez de enums Rust |
| Exportação PDF/Excel | Não iniciado |
| Testes automatizados | Nenhum teste escrito |

---

## 5. Frontend (Flutter) — Detalhamento

### 5.1 Configuração do Projeto

| Item | Valor |
|------|-------|
| Flutter | 3.38.7 |
| Dart | 3.10.7 |
| Plataformas | Web, Android, iOS |
| Análise Estática | ✅ **Zero issues** (`flutter analyze` limpo) |
| Design System | "Sacred Geometry meets Modern Editorial" |

### 5.2 Estrutura de Arquivos Implementados

```
frontend/lib/
├── main.dart                              ✅ Wired (BlocProvider + MaterialApp.router)
├── core/
│   ├── network/
│   │   └── api_client.dart                ✅ Dio + JWT interceptor + auto-refresh
│   ├── router/
│   │   └── app_router.dart                ✅ GoRouter com auth guard + rotas famílias/ministérios/financeiro
│   ├── shell/
│   │   └── app_shell.dart                 ✅ Sidebar (5 itens) + BottomNav (mobile)
│   └── theme/
│       ├── app_colors.dart                ✅ Paleta completa (navy + gold + parchment)
│       ├── app_typography.dart            ✅ 17 estilos (3 fontes: DM Serif, Source Sans 3, JetBrains Mono)
│       ├── app_spacing.dart               ✅ Escala 4px (12 níveis) + radius + padding
│       └── app_theme.dart                 ✅ ThemeData Material 3 completo
│
└── features/
    ├── auth/
    │   ├── bloc/
    │   │   ├── auth_bloc.dart             ✅ Login, logout, check
    │   │   └── auth_event_state.dart      ✅ 3 events, 5 states
    │   ├── data/
    │   │   ├── auth_repository.dart       ✅ login, logout, getProfile, isAuthenticated
    │   │   └── models/
    │   │       └── auth_models.dart       ✅ AuthUser, LoginResponse
    │   └── presentation/
    │       └── login_screen.dart          ✅ Split-panel + Sacred Geometry + animação
    │
    ├── dashboard/
    │   └── presentation/
    │       └── dashboard_screen.dart      ✅ Stats (membros + financeiro + patrimônio + EBD wired)
    │
    ├── families/                           ✅ NOVO — CRUD completo
    │   ├── bloc/
    │   │   ├── family_bloc.dart           ✅ 6 event handlers
    │   │   └── family_event_state.dart    ✅ 6 events, 6 states
    │   ├── data/
    │   │   ├── family_repository.dart     ✅ 7 métodos (CRUD + add/remove member)
    │   │   └── models/
    │   │       └── family_models.dart     ✅ Family (15+ campos) + FamilyMember
    │   └── presentation/
    │       ├── family_list_screen.dart    ✅ Busca, lista, FAB, empty/error state
    │       ├── family_detail_screen.dart  ✅ Info + endereço + membros + ações
    │       └── family_form_screen.dart    ✅ Nome + endereço + notas, responsivo
    │
    ├── members/
    │   ├── bloc/
    │   │   ├── member_bloc.dart           ✅ Load + Delete + Create + Update handlers
    │   │   └── member_event_state.dart    ✅ 5 events, 6 states
    │   ├── data/
    │   │   ├── member_repository.dart     ✅ 8 métodos (list, get, create, update, delete, stats, getHistory, createHistory)
    │   │   └── models/
    │   │       └── member_models.dart     ✅ Member (35+ campos), MemberStats (4 campos), MemberHistory (10 campos)
    │   └── presentation/
    │       ├── member_list_screen.dart    ✅ Busca, filtro, lista paginada, FAB → criar
    │       ├── member_detail_screen.dart  ✅ Perfil completo (5 seções, histórico/edit/delete)
    │       ├── member_form_screen.dart    ✅ Formulário criar/editar (5 seções, 35+ campos)
    │       └── member_history_screen.dart ✅ NOVO — Timeline + dialog para criar eventos
    │
    ├── ministries/                         ✅ CRUD completo
    │   ├── bloc/
    │   │   ├── ministry_bloc.dart         ✅ 6 event handlers
    │   │   └── ministry_event_state.dart  ✅ 6 events, 6 states
    │   ├── data/
    │   │   ├── ministry_repository.dart   ✅ 7 métodos (CRUD + members + add/remove)
    │   │   └── models/
    │   │       └── ministry_models.dart   ✅ Ministry + MinistryMember
    │   └── presentation/
    │       ├── ministry_list_screen.dart  ✅ Busca, lista, FAB, status badges
    │       ├── ministry_detail_screen.dart ✅ Info + membros + ações edit/delete
    │       └── ministry_form_screen.dart  ✅ Nome + descrição + status toggle
    │
    └── financial/                           ✅ NOVO — 7 telas + BLoC + Repositório
        ├── bloc/
        │   ├── financial_bloc.dart         ✅ 13 event handlers
        │   └── financial_event_state.dart  ✅ 13 events, 11 states
        ├── data/
        │   ├── financial_repository.dart   ✅ 18 métodos (5 sub-módulos)
        │   └── models/
        │       └── financial_models.dart   ✅ 7 models (AccountPlan, BankAccount, Campaign, Entry, Balance, etc.)
        └── presentation/
            ├── format_utils.dart           ✅ formatCurrency() helper (BRL)
            ├── financial_overview_screen.dart  ✅ Dashboard financeiro + quick actions
            ├── financial_entry_list_screen.dart ✅ Lista com busca + filtros (tipo/status)
            ├── financial_entry_form_screen.dart ✅ Formulário receita/despesa (10+ campos) + edição
            ├── account_plan_list_screen.dart   ✅ Lista agrupada + criação
            ├── bank_account_list_screen.dart   ✅ Lista com saldo + criação
            ├── campaign_list_screen.dart       ✅ Lista com progresso + criação
            └── monthly_closing_list_screen.dart ✅ Lista + fechamento mensal (diálogo)
│
└── reports/                             ✅ NOVO — Tela central de relatórios
    └── presentation/
        └── reports_screen.dart          ✅ Métricas agregadas (4 módulos) + aniversariantes + navegação
│
└── settings/                            ✅ NOVO — Gestão de Igrejas + Usuários + Congregações
    ├── bloc/
    │   ├── settings_bloc.dart           ✅ 8 event handlers (Church + User CRUD)
    │   └── settings_event_state.dart    ✅ 8 events, 7 states
    ├── data/
    │   ├── settings_repository.dart     ✅ 9 métodos (churches + users + roles)
    │   └── models/
    │       └── settings_models.dart     ✅ Church (22 campos), AppUser, AppRole
    └── presentation/
        ├── settings_overview_screen.dart ✅ Overview com 4 cards de navegação (Igrejas, Usuários, Congregações, Relatórios)
        ├── church_settings_screen.dart  ✅ Perfil da igreja (info/endereço/contato) + edição
        └── user_management_screen.dart  ✅ Lista de usuários + criar/editar + roles
│
└── congregations/                       ✅ NOVO — CRUD completo + Context Cubit + Selector
    ├── bloc/
    │   ├── congregation_bloc.dart       ✅ 5 event handlers (load, create, update, deactivate, assign)
    │   ├── congregation_event_state.dart ✅ 5 events, 7 states
    │   └── congregation_context_cubit.dart ✅ Global context cubit (seletor de congregação ativa)
    ├── data/
    │   ├── congregation_repository.dart ✅ 12 métodos (CRUD + stats + users + assign + overview)
    │   └── models/
    │       └── congregation_models.dart ✅ Congregation (17+ campos), CongregationStats, CongregationUser, AssignMembersResult, CongregationsOverview
    └── presentation/
        ├── widgets/
        │   └── congregation_selector.dart ✅ Widget AppBar dropdown + BottomSheet (seleção de congregação ativa)
        └── pages/
            ├── congregation_list_page.dart ✅ Lista com filter chips (Todas/Sede/Congregações/Pontos) + busca
            ├── congregation_detail_page.dart ✅ Header + Stats grid + Info + Endereço + Usuários + Ações
            ├── congregation_form_page.dart ✅ Criar/editar (3 seções: básico, contato, endereço) + responsivo
            └── congregation_assign_members_page.dart ✅ Associação em lote com busca + seleção + overwrite
```

### 5.3 Design System — Tokens Implementados

#### Paleta de Cores

| Token | Cor | Hex | Uso |
|-------|-----|-----|-----|
| `primary` | 🟦 Deep Navy | `#0D1B2A` | Background de hero, sidebar, AppBar |
| `accent` | 🟨 Warm Gold | `#D4A843` | Botões, links, ícones de destaque |
| `background` | 🟫 Warm Parchment | `#F7F5F0` | Background geral |
| `surface` | ⬜ White | `#FFFFFF` | Cards, surfaces |
| `textPrimary` | ⬛ Navy | `#0D1B2A` | Texto principal |
| `textSecondary` | 🔘 Slate | `#5A6577` | Texto secundário |
| `success` | 🟩 Forest Green | `#2E7D5B` | Status ativo |
| `error` | 🟥 Vermillion | `#C44536` | Erros, status desligado |
| `info` | 🔷 Steel Blue | `#3A7CA5` | Info, status transferido |

#### Tipografia

| Estilo | Fonte | Tamanho | Uso |
|--------|-------|---------|-----|
| `displayLarge` | DM Serif Display | 40px | Títulos de hero |
| `displaySmall` | DM Serif Display | 28px | Títulos de seção |
| `headingLarge` | Source Sans 3 | 24px | Títulos de página |
| `headingSmall` | Source Sans 3 | 18px | Subtítulos |
| `bodyLarge` | Source Sans 3 | 16px | Texto principal |
| `bodyMedium` | Source Sans 3 | 14px | Texto geral |
| `bodySmall` | Source Sans 3 | 12px | Labels, captions |
| `monoMedium` | JetBrains Mono | 14px | Dados financeiros |
| `buttonLarge` | Source Sans 3 | 16px | Botões |

### 5.4 Telas Implementadas

#### Tela de Login (`login_screen.dart` — 463 linhas)

**Status: ✅ Completa**

| Componente | Descrição |
|------------|-----------|
| Layout | Split-panel: Hero (desktop) + Form (sempre visível) |
| Hero Panel | Gradient navy, `_SacredGeometryPainter` com círculos/linhas/diamante |
| Animação | FadeIn + SlideUp com `AnimationController` (1200ms) |
| Formulário | Email + Senha com validação (vazio, formato, mínimo 8 chars) |
| Toggle Senha | Botão para mostrar/ocultar senha |
| Loading State | `CircularProgressIndicator` no botão durante autenticação |
| Erro | SnackBar flutuante com mensagem do backend |
| Responsivo | Hero oculto em telas < 800px; logo "IM" aparece no mobile |

**Pendente:** ~~Botão "Esqueceu a senha?" existe mas com `// TODO`.~~ ✅ **Concluído** — Navega para `ForgotPasswordScreen` com fluxo completo (enviar e-mail + token + nova senha).

#### Dashboard (`dashboard_screen.dart`)

**Status: ✅ Stats wired (4 módulos) + Quick Actions completos**

| Componente | Descrição | Status |
|------------|-----------|--------|
| Header | Saudação + avatar com popup menu (logout) | ✅ Funcional |
| Stat Cards | 4 cards grid: Membros, Saldo Financeiro, Patrimônio, EBD | ✅ Todos wired via API |
| Quick Actions | 4 botões: Novo Membro, Nova Família, Novo Ministério, Relatórios | ✅ Todos navegam |
| Responsivo | Grid adaptativo (2–4 colunas conforme largura) | ✅ Funcional |

#### Lista de Membros (`member_list_screen.dart` — 398 linhas)

**Status: ✅ Completa (integrada com API)**

| Componente | Descrição |
|------------|-----------|
| Header | Título "Membros" + contagem dinâmica |
| Busca | TextField com ícone de busca, limpar, submit |
| Filtro Status | Dropdown: Todos, Ativo, Inativo, Transferido, Desligado |
| Lista | `ListView.separated` com `_MemberTile` cards |
| Tile | Avatar (iniciais), nome, telefone/email, badge de status |
| Empty State | Ícone + mensagem "Nenhum membro encontrado" |
| Error State | Ícone + mensagem + botão "Tentar novamente" |
| Loading | `CircularProgressIndicator` centralizado |
| FAB | "Novo Membro" (⚠️ TODO: sem navegação para criação) |

#### Detalhe do Membro (`member_detail_screen.dart` — 545 linhas)

**Status: ✅ Completa — Todos os campos, ações editar/excluir**

| Seção | Campos Exibidos |
|-------|-----------------|
| Card de Perfil | Avatar (iniciais), nome completo, nome social, badge de status, cargo |
| Informações Pessoais | Email, telefone primário/secundário, nascimento, sexo, estado civil, CPF, RG, tipo sanguíneo |
| Endereço | Logradouro completo, bairro, cidade/UF, CEP |
| Informações Adicionais | Profissão, local de trabalho, naturalidade, nacionalidade, escolaridade |
| Informações Eclesiásticas | Conversão, batismo águas, batismo espírito, igreja origem, ingresso (data/forma), cargo, consagração |
| Observações | Texto livre |
| Metadata | Datas de criação e atualização |

**Ações:** Histórico (→ `/members/:id/history`), Editar (→ `/members/:id/edit`), Excluir (com confirmação)

#### Formulário de Membro (`member_form_screen.dart` — 808 linhas)

**Status: ✅ Completa — Criar e Editar membro**

| Seção | Campos |
|-------|--------|
| Dados Pessoais | Nome completo*, nome social, nascimento, sexo*, estado civil, CPF, RG, email, telefones |
| Endereço | CEP, logradouro, número, complemento, bairro, cidade, UF |
| Informações Adicionais | Profissão, local de trabalho, naturalidade (cidade/estado), nacionalidade, escolaridade, tipo sanguíneo |
| Informações Eclesiásticas | Conversão, batismo águas, batismo espírito, igreja origem, ingresso (data/tipo), cargo/função, consagração, status |
| Observações | Campo de texto multilinha |

**Features:** Layout responsivo (2 colunas em desktop, 1 em mobile), validação de campos obrigatórios, date pickers, dropdowns com valores tipados, BLoC integration, navegação pós-save

### 5.5 Navegação (GoRouter)

| Rota | Tela | Guarda |
|------|------|--------|
| `/login` | `LoginScreen` | Redireciona p/ `/` se autenticado |
| `/` | `DashboardScreen` (dentro de `AppShell`) | Redireciona p/ `/login` se não autenticado |
| `/members` | `MemberListScreen` (dentro de `AppShell`) | Protegida |
| `/members/new` | `MemberFormScreen` (dentro de `AppShell`) | Protegida |
| `/members/:id` | `MemberDetailScreen` (dentro de `AppShell`) | Protegida |
| `/members/:id/edit` | `MemberFormScreen` (dentro de `AppShell`) | Protegida |
| `/members/:id/history` | `MemberHistoryScreen` (dentro de `AppShell`) | Protegida |
| `/families` | `FamilyListScreen` (dentro de `AppShell`) | Protegida |
| `/families/new` | `FamilyFormScreen` (dentro de `AppShell`) | Protegida |
| `/families/:id` | `FamilyDetailScreen` (dentro de `AppShell`) | Protegida |
| `/families/:id/edit` | `FamilyFormScreen` (dentro de `AppShell`) | Protegida |
| `/ministries` | `MinistryListScreen` (dentro de `AppShell`) | Protegida |
| `/ministries/new` | `MinistryFormScreen` (dentro de `AppShell`) | Protegida |
| `/ministries/:id` | `MinistryDetailScreen` (dentro de `AppShell`) | Protegida |
| `/ministries/:id/edit` | `MinistryFormScreen` (dentro de `AppShell`) | Protegida |
| `/financial` | `FinancialOverviewScreen` (dentro de `AppShell`) | Protegida |
| `/financial/entries` | `FinancialEntryListScreen` (dentro de `AppShell`) | Protegida |
| `/financial/entries/new` | `FinancialEntryFormScreen` (dentro de `AppShell`) | Protegida |
| `/financial/entries/:id` | `FinancialEntryFormScreen` (dentro de `AppShell`) | Protegida |
| `/financial/account-plans` | `AccountPlanListScreen` (dentro de `AppShell`) | Protegida |
| `/financial/bank-accounts` | `BankAccountListScreen` (dentro de `AppShell`) | Protegida |
| `/financial/campaigns` | `CampaignListScreen` (dentro de `AppShell`) | Protegida |

| `/financial/monthly-closings` | `MonthlyClosingListScreen` (dentro de `AppShell`) | Protegida |
| `/reports` | `ReportsScreen` (dentro de `AppShell`) | Protegida |\n| `/settings` | `SettingsOverviewScreen` (dentro de `AppShell`) | Protegida |\n| `/settings/church` | `ChurchSettingsScreen` (dentro de `AppShell`) | Protegida |\n| `/settings/users` | `UserManagementScreen` (dentro de `AppShell`) | Protegida |
| `/settings/congregations` | `CongregationListPage` (dentro de `AppShell`) | Protegida |
| `/settings/congregations/new` | `CongregationFormPage` (dentro de `AppShell`) | Protegida |
| `/settings/congregations/:id` | `CongregationDetailPage` (dentro de `AppShell`) | Protegida |
| `/settings/congregations/:id/edit` | `CongregationFormPage` (dentro de `AppShell`) | Protegida |
| `/settings/congregations/:id/assign-members` | `CongregationAssignMembersPage` (dentro de `AppShell`) | Protegida |

**Shell responsivo:**
- Desktop (≥ 900px): Sidebar navy com itens: Dashboard, Membros, Famílias, Ministérios, Financeiro, Patrimônio, EBD, Configurações
- Mobile (< 900px): `NavigationBar` inferior com os mesmos itens

---

## 6. TODOs Identificados no Código

| Arquivo | Linha | TODO |
|---------|:-----:|------|
| ~~`login_screen.dart`~~ | ~~348~~ | ~~`// TODO: Forgot password flow`~~ ✅ Resolvido — Navega para `ForgotPasswordScreen` |
| ~~`dashboard_screen.dart`~~ | ~~124~~ | ~~`// TODO: Navigate to reports`~~ ✅ Resolvido — Navega para `/reports` |

---

## 7. Problemas Resolvidos Durante o Desenvolvimento

| # | Problema | Solução |
|---|----------|---------|
| 1 | Macro `query!` do SQLx exige banco de dados ativo em tempo de compilação | Convertido para `query`/`query_as` runtime com structs `FromRow` explícitas |
| 2 | Rust edition 2024 não permite `ref` em match patterns implicitamente borrowing | Removido `ref` de `if let Some(ref search_term)` |
| 3 | `FieldError` sem `Clone` causava erro em `.clone()` no match | Adicionado `#[derive(Clone)]` |
| 4 | `Claims` sem `Clone` no middleware | Adicionado `Clone` ao derive |
| 5 | Inferência de tipo falha em match arm com tupla | Adicionada anotação explícita do tipo da tupla |
| 6 | `ServiceRequest` não importado/usado | Removida importação, middleware simplificado |
| 7 | Delimitadores desbalanceados no handler `me()` | Corrigido — adicionado `)` faltante |
| 8 | Versões de pacotes Flutter incompatíveis | Downgrade: `flutter_bloc ^9.1.1`, `phosphor_flutter ^2.1.0`, `url_launcher ^6.3.1` |
| 10 | Generic trait methods tornam traits non-dyn-compatible (`Box<dyn DynBind>`) | Substituído por `enum BindValue { Text, Int, Date }` + `build_arguments()` |
| 11 | `Arguments::add()` retorna `Result<(), Box<dyn Error>>`, não `()` | Adicionado `.unwrap()` nas chamadas |
| 12 | `DropdownButtonFormField.value` deprecated no Flutter 3.38 | Substituído por `initialValue` |
| 13 | Sem usuários de teste para login manual | Criado `seed_test_data()` em `main.rs` com 3 usuários: `admin@igreja.com`/`admin123` (super_admin), `secretaria@igreja.com`/`secret123` (secretary), `tesoureiro@igreja.com`/`tesour123` (treasurer) + igreja exemplo |
| 14 | Funções privadas `_formatCurrency` não exportáveis entre arquivos Dart | Extraído para `format_utils.dart` como função pública `formatCurrency()` |
| 15 | Dashboard sem dados financeiros (stats hardcoded "—") | Wired `FinancialRepository.getBalanceReport()` paralelo ao load de membros |
| 16 | Rota `/financial/entries/:id` sem tela de edição | Rota agora aponta para `FinancialEntryFormScreen(entryId:)` com modo edição |
| 17 | Fechamento mensal sem tela no frontend | Criada `MonthlyClosingListScreen` com lista + diálogo de criação |
| 18 | Dashboard com stat card duplicado (EBD aparecia 2 vezes) | Removido o 5º card estático que era cópia hardcoded do 4º |
| 19 | Histórico de membro sem UI no frontend | Criada `MemberHistoryScreen` com timeline visual + diálogo para registrar novos eventos |
| 20 | Quick Action "Relatórios" no dashboard sem navegação (`// TODO`) | Criada `ReportsScreen` em `/reports` com métricas agregadas, aniversariantes do mês e navegação por módulo |
| 21 | EBD Overview: botão "Frequência" navegava para `/ebd/attendance` sem `lessonId` → 404 | Removido card de navegação quebrado; frequência acessada via lista de aulas |
| 22 | EBD Overview: estatísticas eram placeholders estáticos | Wired para `/v1/ebd/stats` API com loading state e RefreshIndicator |
| 23 | Reports screen incompleta (só Membros + Financeiro) | Adicionadas seções de Patrimônio (5 métricas) e EBD (4 métricas) via API |
| 24 | Sem frontend para gestão de Igrejas e Usuários (APIs existiam sem UI) | Criado módulo `settings/` completo: 3 telas + BLoC + Repositório + Models |
| 25 | Redis cache conectado mas nunca utilizado (`#[allow(dead_code)]`) | Integrado em `member_stats`, `ebd_stats`, `asset_stats` + cache invalidation em write handlers |
| 26 | Audit logging apenas no módulo de Membros | Expandido para Financial (entries), Assets (CRUD), Churches (create/update), Users (create/update), **EBD** (13 write handlers) |
| 27 | EBD: sem update/delete de aulas, notas em attendance não salvas, módulo limitado a fluxo básico | Implementada **Evolução EBD** (doc 09): migration `20250219100000_ebd_evolution.sql` (5 tabelas + 1 view), 6 entities, 6 services, 16 DTOs, 28 novos endpoints (E1-E7 + F1.2 + F1.5 + F1.10 + E6) — total EBD: 48+ endpoints. Frontend: 10 telas, paginação, relatórios, audit logging |
| 28 | Sem módulo de Congregações (subdivisions dentro da Church) | Implementado **Módulo Congregações** (doc 10): migration `20260220100000_congregations.sql` (2 tabelas + 2 views + ALTER em 11 tabelas), entity + service + handler (12 endpoints), frontend completo (5 telas + BLoC + Context Cubit + Selector Widget) |
| 29 | Rust: `null as Option<String>` no `serde_json::json!` macro não compila | Substituído por `serde_json::Value::Null` no service de congregações |
| 30 | Flutter: `DropdownButtonFormField.value` deprecated no Flutter 3.38 | Substituído por `initialValue` no formulário de congregações |

---

## 8. Dependências e Bibliotecas Não Utilizadas

Crates/packages importados mas ainda sem uso no código — preparados para fases futuras:

| Dependência | Plataforma | Finalidade Planejada |
|-------------|:----------:|----------------------|
| ~~`redis` 1.0~~ | Backend | ✅ **Integrado** — CacheService em stats + invalidation |
| ~~`lettre` 0.11~~ | Backend | ✅ **Integrado** — Forgot/Reset password via SMTP |
| `actix-multipart` 0.7 | Backend | Upload de fotos de membros e patrimônio |
| ~~`utoipa-swagger-ui` 9.0~~ | Backend | ✅ **Integrado** — Swagger UI montado em `/swagger-ui/` |
| `rust_decimal` 1.0 | Backend | Cálculos financeiros precisos |
| `retrofit` / `retrofit_generator` | Frontend | Geração automática de clientes HTTP (usando Dio manual por ora) |
| `reactive_forms` 18.0.2 | Frontend | Formulários reativos complexos (cadastro de membro) |
| `shimmer` 3.0.0 | Frontend | Loading skeletons |
| `cached_network_image` 3.4.1 | Frontend | Cache de imagens (fotos de membros) |
| `flutter_svg` 2.1.0 | Frontend | Ícones SVG customizados |
| `mask_text_input_formatter` 2.9.0 | Frontend | Máscaras de CPF, telefone, CEP |
| `phosphor_flutter` 2.1.0 | Frontend | Biblioteca de ícones alternativa |

---

## 9. Próximos Passos Sugeridos

### Fase 2 — Completar Módulo de Membros (Prioridade: 🔴 Alta)

| # | Tarefa | Backend | Frontend | Complexidade |
|---|--------|:-------:|:--------:|:------------:|
| 2.1 | `PUT /members/{id}` — Atualização de membro | ✅ Completo | ✅ Form wired | ~~Média~~ ✅ |
| 2.2 | Formulário de criação de membro | ✅ Endpoint existe | ✅ Form completo | ~~Alta~~ ✅ |
| 2.3 | Filtros dinâmicos na listagem | ✅ BindValue enum | ✅ Dropdown wired | ~~Baixa~~ ✅ |
| 2.4 | Detalhe completo do membro (todos os campos) | ✅ Endpoint existe | ✅ 5 seções + ações | ~~Média~~ ✅ |
| 2.5 | CRUD de Famílias | ✅ 7 endpoints | ✅ Lista + Detalhe + Form | ~~Média~~ ✅ |
| 2.6 | CRUD de Ministérios | ✅ 8 endpoints | ✅ Lista + Detalhe + Form | ~~Média~~ ✅ |
| 2.7 | Histórico de alterações | ✅ 2 endpoints | Nova tela | ~~Média~~ ✅ |

### Fase 3 — Módulo Financeiro (Prioridade: 🟡 Média)

| # | Tarefa | Descrição |
|---|--------|-----------|
| 3.1 | Plano de Contas | ~~CRUD de categorias de receita/despesa~~ ✅ **Backend completo** |
| 3.2 | Contas Bancárias | ~~Cadastro com saldo inicial~~ ✅ **Backend completo** |
| 3.3 | Lançamentos | ~~Entrada de dízimos, ofertas, despesas com comprovante~~ ✅ **Backend completo** |
| 3.4 | Campanhas | ~~Campanhas especiais com meta e progresso~~ ✅ **Backend completo** |
| 3.5 | Fechamento Mensal | ~~Conciliação e snapshot financeiro~~ ✅ **Backend completo** |
| 3.6 | Dashboard Financeiro | ✅ **Overview com saldo + 7 quick actions** |
| 3.7 | Telas de CRUD Financeiro | ✅ **Lista + Form de lançamentos (criar/editar), plano de contas, contas bancárias, campanhas, fechamento mensal** |
| 3.8 | Relatórios gráficos | 🟡 Repositório implementado, gráficos pendentes |

### Fase 4 — Módulo EBD (Prioridade: 🟡 Média)

| # | Tarefa | Descrição |
|---|--------|:-----------:|
| 4.1 | Períodos Letivos | ✅ **Frontend: tela de lista + criação, BLoC + Repositório** |
| 4.2 | Turmas | ✅ **Frontend: lista + detalhe com matrículas** |
| 4.3 | Matrículas | ✅ **Frontend: matricular/remover alunos na tela de detalhe** |
| 4.4 | Aulas | ✅ **Frontend: lista + criação de aulas** |
| 4.5 | Chamada | ✅ **Frontend: tela de frequência com P/A/J + Bíblia/Revista** |
| 4.6 | Relatórios EBD | ✅ **Frontend: tela de relatórios com 3 abas (Resumo/Ranking/Ausentes) + 4 endpoints backend** |

### Fase 4.1 — Evolução EBD (doc 09-ebd-evolucao-modulo.md)

| # | Tarefa | Backend | Frontend | Descrição |
|---|--------|:-------:|:--------:|:-----------:|
| 4.1.1 | [F1.2] Update/Delete de Aulas | ✅ | ✅ Completo | PUT/DELETE em `/ebd/lessons/{id}` |
| 4.1.2 | [F1.5] Notes em Attendance | ✅ | ✅ Completo | Campo `notes` agora exposto e salvo |
| 4.1.3 | [E1] Conteúdo Enriquecido de Lições | ✅ 5 endpoints | ✅ Aba no detalhe | Blocos de conteúdo ordenáveis (text/image/bible_ref/note) |
| 4.1.4 | [E2] Atividades por Lição | ✅ 7 endpoints | ✅ Aba + Respostas | Atividades + respostas dos alunos |
| 4.1.5 | [E3] Perfil Unificado do Aluno EBD | ✅ 4 endpoints | ✅ Lista + Perfil | View + historico + atividades do aluno |
| 4.1.6 | [E4] Materiais e Recursos | ✅ 3 endpoints | ✅ Aba no detalhe | Links/documentos/vídeos por lição |
| 4.1.7 | [E5] Anotações do Professor | ✅ 4 endpoints | ✅ Seção + edição | Notas por aluno (observation/concern/praise/follow_up) |
| 4.1.8 | [E6] Relatórios Avançados | ✅ 4 endpoints | ✅ 3 abas | Frequência por período, comparativos, progresso individual |
| 4.1.9 | [E7] Clonagem de Turmas | ✅ 1 endpoint | ✅ Botão + dialog | Clonar turmas entre trimestres (com matrículas opcionais) |
| 4.1.10 | [F1.7] Audit Logging EBD | ✅ 13 handlers | — | AuditService integrado em todos os write handlers |
| 4.1.11 | [F1.8] Paginação | — | ✅ Load more | Botão "Carregar mais" em turmas, aulas, alunos |
| 4.1.12 | [F1.10] Delete Termos/Turmas | ✅ 2 endpoints | ✅ Botões + dialogs | DELETE transacional + confirmação na UI |

### Fase 5 — Módulo Patrimônio (Prioridade: 🟡 Média)

| # | Tarefa | Descrição |
|---|--------|:-----------:|
| 5.1 | Categorias de Bens | ✅ **Frontend: lista + criação (dialog)** |
| 5.2 | Cadastro de Bens | ✅ **Frontend: overview + lista + detalhe + formulário (criar/editar)** |
| 5.3 | Manutenções | ✅ **Frontend: lista com filtro + criação (dialog)** |
| 5.4 | Inventário | ✅ **Frontend: lista + criar + fechar inventário** |
| 5.5 | Empréstimos | ✅ **Frontend: lista + registro + devolução** |

### Fase 5.1 — Módulo Congregações (Prioridade: 🟡 Média) — ✅ CONCLUÍDO

| # | Tarefa | Backend | Frontend | Status |
|---|--------|:-------:|:--------:|:------:|
| 5.1.1 | Migration (tabelas + views + ALTER) | ✅ | — | ✅ Completo |
| 5.1.2 | Entity + DTOs | ✅ 9 structs + 5 DTOs | — | ✅ Completo |
| 5.1.3 | Service (CRUD + Stats + Users + Assign) | ✅ 12 métodos | — | ✅ Completo |
| 5.1.4 | Handler (12 endpoints + OpenAPI) | ✅ | — | ✅ Completo |
| 5.1.5 | Models + Repository | — | ✅ 5 models + 12 métodos | ✅ Completo |
| 5.1.6 | BLoC + Context Cubit | — | ✅ 5 events + cubit global | ✅ Completo |
| 5.1.7 | Tela de lista (filter chips) | — | ✅ | ✅ Completo |
| 5.1.8 | Tela de detalhe (stats + info) | — | ✅ | ✅ Completo |
| 5.1.9 | Formulário criar/editar (responsivo) | — | ✅ | ✅ Completo |
| 5.1.10 | Associar membros em lote | — | ✅ | ✅ Completo |
| 5.1.11 | Selector widget (AppBar) | — | ✅ | ✅ Completo |
| 5.1.12 | Rotas + Navegação | — | ✅ 5 rotas | ✅ Completo |

### Fase 6 — Infraestrutura e Qualidade

| # | Tarefa | Descrição |
|---|--------|-----------|
| 6.1 | Testes unitários (Backend) | Services, handlers, middleware |
| 6.2 | Testes de widget (Frontend) | Telas principais, BLoC tests |
| 6.3 | CI/CD Pipeline | GitHub Actions: build, test, deploy |
| 6.4 | Swagger UI funcional | ~~Montar `/swagger-ui`~~ ✅ **Concluído** |
| 6.5 | Cache Redis | ~~Implementar caching de consultas frequentes~~ ✅ **Concluído** — `CacheService` (get/set/del/del_pattern), integrado em member_stats, ebd_stats, asset_stats + invalidation em write handlers |
| 6.6 | Audit Log funcional | ~~Interceptar e registrar ações~~ ✅ **Concluído** — `AuditService` integrado em Members, Assets, Financial, Churches, Users e EBD (create/update/delete) |
| 6.7 | Upload de arquivos | ✅ **Concluído** — Cloudinary (backend + Flutter image compression + upload widget) |
| 6.8 | Envio de emails | ~~Recuperação de senha, notificações~~ ✅ **Concluído** — lettre SMTP + forgot/reset password |
| 6.9 | Deploy Oracle Cloud | ✅ **Concluído** — Docker Compose production + deployment scripts (IP: 147.15.109.89) |

---

## 9.1 Changelog — Sessão v1.16 (20/02/2026)

Melhorias implementadas nesta sessão:

### Módulo de Congregações — Implementação Completa (doc 10)

#### Backend (Rust/Actix-Web)
- **Migration `20260220100000_congregations.sql`** — Tabela `congregations` (17 campos, UNIQUE church_id+name), tabela `user_congregations` (5 campos), ALTER TABLE em 11 tabelas existentes adicionando `congregation_id`, 2 views consolidadas (`vw_congregation_member_stats`, `vw_congregation_financial_summary`), índices e triggers.
- **Entity `congregation.rs`** — 9 structs: Congregation, CongregationSummary, CongregationStats, UserCongregation, CongregationUserInfo, AssignMembersResult, SkippedMember, CongregationsOverview, CongregationOverviewItem.
- **DTO `congregation_dto.rs`** — 5 DTOs com validação: CreateCongregationRequest, UpdateCongregationRequest, AssignMembersRequest, AddUserToCongregationRequest, SetActiveCongregationRequest.
- **Service `congregation_service.rs`** (~450 linhas) — 12 métodos: list, get_by_id, create (RN-CONG-001 sede única, RN-CONG-002 líder ativo), update (dynamic SET), deactivate (protege sede), get_stats, list_users, add_user, remove_user, assign_members (batch com overwrite), get_overview.
- **Handler `congregation_handler.rs`** (~400 linhas) — 12 handlers com anotações utoipa/OpenAPI. Todos os endpoints registrados em `main.rs`.

#### Frontend (Flutter/BLoC)
- **Models `congregation_models.dart`** (346 linhas) — Congregation (Equatable, fromJson, toCreateJson, copyWith, displayName, typeLabel, typeIcon, addressShort), CongregationStats, CongregationUser, AssignMembersResult, CongregationsOverview.
- **Repository `congregation_repository.dart`** — 12 métodos para todos os endpoints da API.
- **BLoC `congregation_bloc.dart`** + **Events/States** — 5 events (Load, Create, Update, Deactivate, AssignMembers), 7 states. Handler para cada event.
- **Context Cubit `congregation_context_cubit.dart`** — Cubit global (provido no `main.dart`) para gerenciar a congregação ativa. Métodos: loadCongregations(), selectCongregation(), clear(). Auto-carrega no login, limpa no logout.
- **Selector Widget `congregation_selector.dart`** (198 linhas) — Widget para AppBar com dropdown/BottomSheet para selecionar congregação ativa ("Todas (Geral)" ou específica).
- **5 telas de apresentação:**
  - `congregation_list_page.dart` (405 linhas) — Lista com filter chips (Todas/Sede/Congregações/Pontos), cards com tipo, líder, contagem de membros, endereço.
  - `congregation_detail_page.dart` — Header card + grid de stats + seções de info/endereço/usuários + ações (adicionar usuário, associar membros, editar, desativar).
  - `congregation_form_page.dart` (829 linhas) — Formulário criar/editar com 3 seções (básico, contato, endereço), dropdown de tipo, dialog de busca de líder, layout responsivo (2 colunas ≥ 800px).
  - `congregation_assign_members_page.dart` — Associação de membros em lote com busca, chips de seleção, toggle de overwrite, resultado com contagem.

#### Integração
- **Rotas** — 5 novas rotas em `app_router.dart`: `/settings/congregations`, `/new`, `/:id`, `/:id/edit`, `/:id/assign-members`.
- **Navegação** — Card "Congregações" adicionado em `settings_overview_screen.dart`.
- **Global Provider** — `CongregationContextCubit` integrado como `BlocProvider` global em `main.dart`.

### Arquivos Criados (15 arquivos)
- `backend/migrations/20260220100000_congregations.sql`
- `backend/src/domain/entities/congregation.rs`
- `backend/src/application/dto/congregation_dto.rs`
- `backend/src/application/services/congregation_service.rs`
- `backend/src/api/handlers/congregation_handler.rs`
- `frontend/lib/features/congregations/data/models/congregation_models.dart`
- `frontend/lib/features/congregations/data/congregation_repository.dart`
- `frontend/lib/features/congregations/bloc/congregation_event_state.dart`
- `frontend/lib/features/congregations/bloc/congregation_bloc.dart`
- `frontend/lib/features/congregations/bloc/congregation_context_cubit.dart`
- `frontend/lib/features/congregations/presentation/widgets/congregation_selector.dart`
- `frontend/lib/features/congregations/presentation/pages/congregation_list_page.dart`
- `frontend/lib/features/congregations/presentation/pages/congregation_detail_page.dart`
- `frontend/lib/features/congregations/presentation/pages/congregation_form_page.dart`
- `frontend/lib/features/congregations/presentation/pages/congregation_assign_members_page.dart`

### Arquivos Modificados (4 arquivos)
- `backend/src/main.rs` — Importação + 12 rotas + OpenAPI paths/tags
- `frontend/lib/core/router/app_router.dart` — 4 imports + 5 rotas de congregações
- `frontend/lib/features/settings/presentation/settings_overview_screen.dart` — Card de navegação para Congregações
- `frontend/lib/main.dart` — CongregationContextCubit como BlocProvider global

---

## 9.2 Changelog — Sessão v1.15 (19/02/2026)

Melhorias implementadas nesta sessão:

### Cloudinary — Upload de Imagens
- **Backend `CloudinaryService`** — Novo service em `infrastructure/cloudinary.rs` com upload/delete via API Cloudinary (SHA-1 signed requests).
- **Backend `upload_handler`** — Novos endpoints:
  - `POST /api/v1/upload/image` — Upload multipart com validação de tipo (JPEG/PNG/GIF/WebP) e tamanho.
  - `DELETE /api/v1/upload/image` — Exclusão por `public_id`.
- **Flutter `ImageCompressService`** — Compressão progressiva (JPEG, começa em 85% quality, reduz até caber em 500KB). Evita consumir cota gratuita do Cloudinary.
- **Flutter `ImageUploadService`** — Integra `ImagePicker` + compressão + upload multipart via backend.
- **Flutter `ImageUploadWidget`** — Widget reutilizável com preview, seleção galeria/câmera, indicador de loading.
- **Config** — Novas env vars: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.
- **Dependencies** — Backend: `reqwest`, `sha1`, `futures-util`. Flutter: `image_picker`, `flutter_image_compress`, `path_provider`, `path`, `mime`, `http_parser`.

### Deploy — Oracle Cloud Free Tier
- **Backend Dockerfile** — Multi-stage build (Rust 1.85 builder → Debian slim runtime).
- **Frontend Dockerfile** — Multi-stage build (Flutter builder → Nginx Alpine) com API_URL configurable via `--dart-define`.
- **Nginx config** — SPA routing + reverse proxy para /api e /swagger-ui + gzip + cache headers.
- **`docker-compose.prod.yml`** — Compose completo com 4 services (postgres, redis, backend, frontend) + env vars.
- **`deploy/setup-server.sh`** — Script de setup do servidor (Docker, firewall, swap 2GB para compilação Rust).
- **`deploy/deploy.sh`** — Script de deploy automatizado (tar + scp + docker compose build + up).
- **`ApiClient`** — Base URL agora configurável via `--dart-define=API_URL=...` (usa `/api` em produção via nginx proxy).

### Arquivos Criados/Modificados
- `backend/src/infrastructure/cloudinary.rs` — CloudinaryService (upload/delete)
- `backend/src/api/handlers/upload_handler.rs` — Upload/delete endpoints
- `backend/Cargo.toml` — +reqwest, sha1, futures-util
- `backend/src/config/mod.rs` — +Cloudinary config
- `backend/Dockerfile` — Multi-stage Rust build
- `backend/.dockerignore`
- `frontend/lib/core/services/image_compress_service.dart`
- `frontend/lib/core/services/image_upload_service.dart`
- `frontend/lib/core/widgets/image_upload_widget.dart`
- `frontend/lib/core/network/api_client.dart` — Configurable base URL
- `frontend/pubspec.yaml` — +image_picker, flutter_image_compress, etc.
- `frontend/Dockerfile` — Multi-stage Flutter web build
- `frontend/nginx.conf` — Nginx reverse proxy config
- `frontend/.dockerignore`
- `docker-compose.prod.yml` — Production compose
- `deploy/.env.production`
- `deploy/setup-server.sh`
- `deploy/deploy.sh`

---

## 9.3 Changelog — Sessão v1.14 (20/02/2026)

Melhorias implementadas nesta sessão para aumentar completude do frontend:

### Correções
- **Edit Navigation Fix** — Corrigido bug em que telas de edição de Membros, Famílias, Ministérios e Patrimônio abriam em modo criação ao invés de edição. Adicionado `entityId` + `FutureBuilder` fallback para deep links.

### Novas Funcionalidades
- **Paginação** — Botão "Carregar mais" em 5 telas de lista: Membros, Famílias, Ministérios, Financeiro e Patrimônio. BLoC com append mode (page > 1 concatena resultados).
- **Dashboard Pull-to-Refresh** — `RefreshIndicator` com `AlwaysScrollableScrollPhysics` para atualizar stats.
- **Dashboard Quick Actions** — Adicionados "Novo Lançamento" e "EBD" (+2 ações rápidas, total: 6).
- **Ministérios — Adicionar Membro** — Dialog de busca de membro com campo de função, integrado ao endpoint `POST /ministries/:id/members`.
- **Ministérios — Campo Líder** — Field "Líder do Ministério" no formulário, com dialog de busca e envio de `leader_id` no request.
- **Financeiro — Filtro por Data** — DatePicker para filtrar lançamentos por data inicial/final (`dateFrom`/`dateTo`).
- **Financeiro — Swipe-to-Delete** — `Dismissible` com confirmação para excluir lançamentos via `FinancialEntryDeleteRequested`.
- **Patrimônio — Filtro por Categoria** — Dropdown carregado dinamicamente via `getCategories()`, filtra por `categoryId`.
- **Gráficos fl_chart** — Dependência `fl_chart: ^0.70.2` adicionada. Pie charts (membros ativos/inativos, receita/despesa) + bar chart (despesas por categoria) na tela de Relatórios.

### Arquivos Modificados (21 arquivos)
- `pubspec.yaml` — Adicionado fl_chart
- `core/router/app_router.dart` — 4 edit routes com entityId fallback
- `features/members/` — bloc, event_state, form_screen, detail_screen, list_screen
- `features/families/` — bloc, event_state, form_screen, detail_screen, list_screen
- `features/ministries/` — bloc, event_state, form_screen, detail_screen, list_screen
- `features/financial/` — bloc, event_state, entry_list_screen
- `features/assets/` — bloc, event_state, form_screen, list_screen
- `features/dashboard/` — dashboard_screen
- `features/reports/` — reports_screen

---

## 10. Métricas do Projeto

### Contagem de Código

| Componente | Arquivos | Linhas Estimadas |
|------------|:--------:|:----------------:|
| Documentação (docs/) | 10 | ~8.100 |
| Backend (Rust) | 94 .rs | ~15.400 |
| Migrations (SQL) | 4 | ~1.050 |
| Frontend (Dart) | 96 .dart | ~27.500 |
| Configuração | 5 | ~200 |
| **Total** | **205** | **~49.500** |

### Status de Compilação

| Componente | Comando | Resultado |
|------------|---------|-----------|
| Backend Rust | `SQLX_OFFLINE=true cargo check` | ✅ Compila (0 errors, 2 warnings dead_code) |
| Frontend Flutter | `flutter analyze` | ✅ 64 info issues (zero errors, zero warnings) |

---

> **Nota:** Este documento deve ser atualizado ao final de cada sprint ou semana de desenvolvimento para manter visibilidade do progresso real do projeto.
