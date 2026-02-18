# 📊 Andamento do Projeto — Igreja Manager

> **Última atualização:** 19 de fevereiro de 2026  
> **Versão do documento:** 1.1  
> **Status geral do projeto:** Em Desenvolvimento Ativo (~38% concluído)

---

## 1. Visão Geral do Progresso

O **Igreja Manager** é uma plataforma de gestão para igrejas composta por **5 módulos principais**: Autenticação, Membros, Financeiro, Patrimônio e EBD (Escola Bíblica Dominical). A stack tecnológica definida é **Rust (Actix-Web)** no backend, **PostgreSQL 16** como banco de dados, **Redis 7** para cache e **Flutter 3.38** no frontend (Web, Android, iOS).

### Resumo Executivo por Área

| Área | Progresso | Status |
|------|:---------:|--------|
| Documentação Técnica | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Concluído |
| Banco de Dados (Schema) | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Concluído |
| Infraestrutura (Docker) | ![90%](https://img.shields.io/badge/90%25-green) | ✅ Funcional |
| Backend — Autenticação | ![90%](https://img.shields.io/badge/90%25-green) | 🟢 Quase completo |
| Backend — Membros | ![85%](https://img.shields.io/badge/85%25-green) | 🟢 Quase completo |
| Backend — Financeiro | ![0%](https://img.shields.io/badge/0%25-red) | 🔴 Não iniciado |
| Backend — Patrimônio | ![0%](https://img.shields.io/badge/0%25-red) | 🔴 Não iniciado |
| Backend — EBD | ![0%](https://img.shields.io/badge/0%25-red) | 🔴 Não iniciado |
| Frontend — Design System | ![100%](https://img.shields.io/badge/100%25-brightgreen) | ✅ Concluído |
| Frontend — Autenticação | ![85%](https://img.shields.io/badge/85%25-green) | 🟢 Quase completo |
| Frontend — Dashboard | ![40%](https://img.shields.io/badge/40%25-orange) | 🟠 Quick actions wired |
| Frontend — Membros | ![80%](https://img.shields.io/badge/80%25-green) | 🟢 CRUD completo |
| Frontend — Financeiro | ![0%](https://img.shields.io/badge/0%25-red) | 🔴 Não iniciado |
| Frontend — Patrimônio | ![0%](https://img.shields.io/badge/0%25-red) | 🔴 Não iniciado |
| Frontend — EBD | ![0%](https://img.shields.io/badge/0%25-red) | 🔴 Não iniciado |

---

## 2. Documentação Técnica — ✅ 100% Concluída

Toda a documentação de especificação foi finalizada, totalizando **~5.052 linhas** distribuídas em 6 documentos:

| Documento | Linhas | Conteúdo |
|-----------|:------:|----------|
| `01-requisitos-funcionais.md` | 528 | 40+ requisitos funcionais detalhados para os 5 módulos |
| `02-arquitetura.md` | 686 | Arquitetura Clean Architecture, diagramas Mermaid, estratégias de deploy |
| `03-banco-de-dados.md` | 1.106 | 24+ tabelas documentadas campo a campo, diagrama ER |
| `04-api-rest.md` | 1.226 | 60+ endpoints REST com exemplos de request/response |
| `05-frontend-flutter.md` | 1.107 | Design system, BLoC pattern, go_router, wireframes, responsividade |
| `06-regras-de-negocio.md` | 399 | 40+ regras de negócio por módulo |

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

### 3.2 Tabelas Criadas (Migration `20250101000000_initial.sql` — 793 linhas)

**Total: 24 tabelas, 3 views, 20+ triggers, 3 extensões**

#### Módulo Sistema (5 tabelas)

| Tabela | Campos | Seeds | Utilizada no Backend? |
|--------|:------:|:-----:|:---------------------:|
| `churches` | 22 | — | ✅ Sim (entity definida) |
| `roles` | 8 | 7 papéis padrão | ✅ Sim (consultada no login) |
| `users` | 14 | — | ✅ Sim (autenticação) |
| `refresh_tokens` | 6 | — | ✅ Sim (refresh flow) |
| `audit_logs` | 9 | — | ❌ Tabela existe, sem escrita |

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
| `members` | 35+ | ✅ CRUD completo | ✅ Lista + Detalhe |
| `families` | 5 | ❌ Sem API | ❌ Sem UI |
| `family_relationships` | 5 | ❌ Sem API | ❌ Sem UI |
| `ministries` | 7 | ❌ Sem API | ❌ Sem UI |
| `member_ministries` | 5 | ❌ Sem API | ❌ Sem UI |
| `member_history` | 6 | ❌ Sem API | ❌ Sem UI |

#### Módulo Financeiro (5 tabelas)

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `account_plans` | 8 | ❌ Nenhum código | ❌ Nenhuma tela |
| `bank_accounts` | 10 | ❌ Nenhum código | ❌ Nenhuma tela |
| `campaigns` | 10 | ❌ Nenhum código | ❌ Nenhuma tela |
| `financial_entries` | 15 | ❌ Nenhum código | ❌ Nenhuma tela |
| `monthly_closings` | 10 | ❌ Nenhum código | ❌ Nenhuma tela |

#### Módulo Patrimônio (7 tabelas)

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `asset_categories` | 5 | ❌ | ❌ |
| `assets` | 20 | ❌ | ❌ |
| `asset_photos` | 6 | ❌ | ❌ |
| `maintenances` | 10 | ❌ | ❌ |
| `inventories` | 7 | ❌ | ❌ |
| `inventory_items` | 7 | ❌ | ❌ |
| `asset_loans` | 8 | ❌ | ❌ |

#### Módulo EBD (5 tabelas)

| Tabela | Campos | Backend | Frontend |
|--------|:------:|:-------:|:--------:|
| `ebd_terms` | 7 | ❌ | ❌ |
| `ebd_classes` | 8 | ❌ | ❌ |
| `ebd_enrollments` | 5 | ❌ | ❌ |
| `ebd_lessons` | 10 | ❌ | ❌ |
| `ebd_attendances` | 7 | ❌ | ❌ |

#### Views e Triggers

| View | Propósito |
|------|-----------|
| `vw_member_stats` | Estatísticas de membros por status/gênero por igreja |
| `vw_account_balances` | Saldos correntes de contas bancárias |
| `vw_ebd_class_attendance` | Frequência de alunos por turma/aula |

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
| Build Status | ✅ **Compila com sucesso** (apenas warnings) |

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
| Cache | `redis` | 1.0 | ⚠️ Importado, não utilizado |
| Email | `lettre` | 0.11 | ⚠️ Importado, não utilizado |
| Docs | `utoipa` / `utoipa-swagger-ui` | 5.4 / 9.0 | ⚠️ Anotações existem, Swagger não montado |
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
│       └── member_handler.rs
├── application/
│   ├── dto/
│   │   ├── auth_dto.rs      ← LoginRequest, Claims, etc.
│   │   └── member_dto.rs    ← CreateMemberRequest, MemberFilter, etc.
│   └── services/
│       ├── auth_service.rs   ← Hashing, JWT, login flow
│       └── member_service.rs ← CRUD básico
├── domain/entities/
│   ├── church.rs
│   ├── user.rs              ← User, Role, RefreshToken
│   └── member.rs            ← Member (62 campos), MemberSummary
└── infrastructure/
    └── database.rs          ← Pool de conexões PG
```

### 4.3 Endpoints Implementados

#### Saúde

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| `GET` | `/api/health` | Health check com verificação do banco | ✅ Completo |

#### Autenticação (4 endpoints)

| Método | Rota | Descrição | Status |
|--------|------|-----------|--------|
| `POST` | `/api/v1/auth/login` | Login com email/senha | ✅ Completo |
| `POST` | `/api/v1/auth/refresh` | Renovação de token | ✅ Completo |
| `POST` | `/api/v1/auth/logout` | Logout (revoga tokens) | ✅ Completo |
| `GET` | `/api/v1/auth/me` | Perfil do usuário autenticado | ✅ Completo |

**Funcionalidades de segurança implementadas:**
- Hash de senha com Argon2
- JWT com claims (sub, church_id, role, permissions, exp, iat)
- Refresh token (random base64, armazenado no banco)
- Bloqueio de conta após 5 tentativas falhas (15 min de lock)
- Rastreamento de `failed_attempts` e `locked_until`

#### Membros (6 endpoints)

| Método | Rota | Auth | Descrição | Status |
|--------|------|------|-----------|--------|
| `GET` | `/api/v1/members` | ✅ JWT | Listar com paginação | ✅ Funcional |
| `GET` | `/api/v1/members/stats` | ✅ JWT | Estatísticas dos membros | ✅ Completo |
| `GET` | `/api/v1/members/{id}` | ✅ JWT | Buscar por ID | ✅ Completo |
| `POST` | `/api/v1/members` | ✅ `members:create` | Criar membro (35 campos) | ✅ Completo |
| `PUT` | `/api/v1/members/{id}` | ✅ `members:update` | Atualizar membro (campos dinâmicos) | ✅ Completo |
| `DELETE` | `/api/v1/members/{id}` | ✅ `members:delete` | Soft delete | ✅ Completo |

### 4.4 O que Falta no Backend

#### Prioridade Alta

| Item | Descrição | Complexidade |
|------|-----------|:------------:|
| `PUT /api/v1/members/{id}` | Atualização de membro — DTO já existe (`UpdateMemberRequest`) | ~~Média~~ ✅ **Concluído** |
| Filtros dinâmicos em `list()` | SQL dinâmico com BindValue enum (11 parâmetros) | ~~Baixa~~ ✅ **Concluído** |
| Swagger UI montado | Anotações `utoipa` existem, falta montar o endpoint `/swagger-ui` | Baixa |
| `POST /api/v1/auth/forgot-password` | Recuperação de senha — SMTP já nas dependências | Média |
| CRUD de Igrejas | Entity `Church` existe, sem handler/service | Média |
| CRUD de Usuários/Papéis | Tabelas existem, sem API | Média |

#### Prioridade Média

| Item | Descrição | Complexidade |
|------|-----------|:------------:|
| Módulo Financeiro completo | 5 tabelas prontas, 11 endpoints documentados | Alta |
| Módulo EBD completo | 5 tabelas prontas, 7 endpoints documentados | Alta |
| Módulo Patrimônio completo | 7 tabelas prontas, 7 endpoints documentados | Alta |
| Famílias e Ministérios | Tabelas prontas, endpoints documentados | Média |
| Audit Log (escrita) | Tabela existe, falta interceptar ações | Média |
| Cache Redis | Crate importado, não configurado | Média |

#### Prioridade Baixa

| Item | Descrição |
|------|-----------|
| Upload de arquivos (fotos) | `actix-multipart` importado, não utilizado |
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
│   │   └── app_router.dart                ✅ GoRouter com auth guard
│   ├── shell/
│   │   └── app_shell.dart                 ✅ Sidebar (desktop) + BottomNav (mobile)
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
    │       └── dashboard_screen.dart      🟡 Shell com stats placeholder
    │
    └── members/
        ├── bloc/
        ├── member_bloc.dart           ✅ Load + Delete + Create + Update handlers
        │   └── member_event_state.dart    ✅ 5 events, 6 states
        ├── data/
        │   ├── member_repository.dart     ✅ 6 métodos (list, get, create, update, delete, stats)
        │   └── models/
        │       └── member_models.dart     ✅ Member (35+ campos), MemberStats (4 campos)
        └── presentation/
            ├── member_list_screen.dart    ✅ Busca, filtro, lista paginada, FAB → criar
            ├── member_detail_screen.dart  ✅ Perfil completo (5 seções, edit/delete)
            └── member_form_screen.dart    ✅ Formulário criar/editar (5 seções, 35+ campos)
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

**Pendente:** Botão "Esqueceu a senha?" existe mas com `// TODO`.

#### Dashboard (`dashboard_screen.dart` — 355 linhas)

**Status: 🟡 Shell criado, dados placeholder**

| Componente | Descrição | Status |
|------------|-----------|--------|
| Header | Saudação + avatar com popup menu (logout) | ✅ Funcional |
| Stat Cards | 4 cards grid: Membros, Entradas, Patrimônio, EBD | ⚠️ Todos mostram "—" |
| Quick Actions | 4 botões: Novo Membro, Lançamento, Chamada EBD, Relatórios | ⚠️ Todos com TODO |
| Responsivo | Grid adaptativo (2-4 colunas conforme largura) | ✅ Funcional |

**Pendente:** Integrar com endpoints de estatísticas reais. Wiring de navegação nos quick actions.

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

**Ações:** Editar (→ `/members/:id/edit`), Excluir (com confirmação)

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

**Shell responsivo:**
- Desktop (≥ 900px): Sidebar navy com itens: Dashboard, Membros
- Mobile (< 900px): `NavigationBar` inferior com os mesmos itens

---

## 6. TODOs Identificados no Código

| Arquivo | Linha | TODO |
|---------|:-----:|------|
| `login_screen.dart` | ~348 | `// TODO: Forgot password flow` |
| `dashboard_screen.dart` | ~110 | `// TODO: Navigate to financial entry` |
| `dashboard_screen.dart` | ~117 | `// TODO: Navigate to EBD attendance` |
| `dashboard_screen.dart` | ~124 | `// TODO: Navigate to reports` |

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

---

## 8. Dependências e Bibliotecas Não Utilizadas

Crates/packages importados mas ainda sem uso no código — preparados para fases futuras:

| Dependência | Plataforma | Finalidade Planejada |
|-------------|:----------:|----------------------|
| `redis` 1.0 | Backend | Cache de sessões e dados frequentes |
| `lettre` 0.11 | Backend | Envio de emails (recuperação de senha, notificações) |
| `actix-multipart` 0.7 | Backend | Upload de fotos de membros e patrimônio |
| `utoipa-swagger-ui` 9.0 | Backend | Interface Swagger (anotações já existem) |
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
| 2.5 | CRUD de Famílias | Tabela pronta | Nova tela | Média |
| 2.6 | CRUD de Ministérios | Tabela pronta | Nova tela | Média |
| 2.7 | Histórico de alterações | Tabela pronta | Nova tela | Média |

### Fase 3 — Módulo Financeiro (Prioridade: 🟡 Média)

| # | Tarefa | Descrição |
|---|--------|-----------|
| 3.1 | Plano de Contas | CRUD de categorias de receita/despesa |
| 3.2 | Contas Bancárias | Cadastro com saldo inicial |
| 3.3 | Lançamentos | Entrada de dízimos, ofertas, despesas com comprovante |
| 3.4 | Campanhas | Campanhas especiais com meta e progresso |
| 3.5 | Fechamento Mensal | Conciliação e snapshot financeiro |
| 3.6 | Dashboard Financeiro | Gráficos, saldos, comparativos |

### Fase 4 — Módulo EBD (Prioridade: 🟡 Média)

| # | Tarefa | Descrição |
|---|--------|-----------|
| 4.1 | Períodos Letivos | CRUD de semestres/trimestres |
| 4.2 | Turmas | Faixa etária, professor, sala |
| 4.3 | Matrículas | Vincular alunos a turmas |
| 4.4 | Aulas | Registrar tema, data, professor |
| 4.5 | Chamada | Lista de presença por aula |
| 4.6 | Relatórios EBD | Frequência, evolução |

### Fase 5 — Módulo Patrimônio (Prioridade: 🟡 Média)

| # | Tarefa | Descrição |
|---|--------|-----------|
| 5.1 | Categorias de Bens | CRUD com hierarquia |
| 5.2 | Cadastro de Bens | Código automático, fotos, localização |
| 5.3 | Manutenções | Registro de manutenções preventivas/corretivas |
| 5.4 | Inventário | Conferência periódica |
| 5.5 | Empréstimos | Controle de itens emprestados |

### Fase 6 — Infraestrutura e Qualidade

| # | Tarefa | Descrição |
|---|--------|-----------|
| 6.1 | Testes unitários (Backend) | Services, handlers, middleware |
| 6.2 | Testes de widget (Frontend) | Telas principais, BLoC tests |
| 6.3 | CI/CD Pipeline | GitHub Actions: build, test, deploy |
| 6.4 | Swagger UI funcional | Montar `/swagger-ui` |
| 6.5 | Cache Redis | Implementar caching de consultas frequentes |
| 6.6 | Audit Log funcional | Interceptar e registrar ações |
| 6.7 | Upload de arquivos | Fotos de membros e bens |
| 6.8 | Envio de emails | Recuperação de senha, notificações |

---

## 10. Métricas do Projeto

### Contagem de Código

| Componente | Arquivos | Linhas Estimadas |
|------------|:--------:|:----------------:|
| Documentação (docs/) | 7 | ~5.600 |
| Backend (Rust) | 16 .rs | ~3.000 |
| Migrations (SQL) | 1 | ~793 |
| Frontend (Dart) | 17 .dart | ~5.200 |
| Configuração | 5 | ~200 |
| **Total** | **46** | **~14.793** |

### Status de Compilação

| Componente | Comando | Resultado |
|------------|---------|-----------|
| Backend Rust | `SQLX_OFFLINE=true cargo check` | ✅ Compila (apenas warnings) |
| Frontend Flutter | `flutter analyze` | ✅ **No issues found** |

---

> **Nota:** Este documento deve ser atualizado ao final de cada sprint ou semana de desenvolvimento para manter visibilidade do progresso real do projeto.
