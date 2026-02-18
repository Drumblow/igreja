# 🏗️ Arquitetura do Sistema — Igreja Manager

## 1. Visão Geral da Arquitetura

O Igreja Manager segue uma arquitetura **cliente-servidor** com separação clara entre frontend e backend, comunicando-se através de uma API REST.

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTES                                  │
│                                                                  │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│   │ Flutter   │    │ Flutter  │    │ Flutter  │                  │
│   │   Web     │    │ Android  │    │   iOS    │                  │
│   └────┬─────┘    └────┬─────┘    └────┬─────┘                  │
│        │               │               │                         │
└────────┼───────────────┼───────────────┼─────────────────────────┘
         │               │               │
         └───────────────┼───────────────┘
                         │ HTTPS / REST API
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY / PROXY                          │
│                    (Nginx / Traefik)                             │
│                   Rate Limiting, TLS, CORS                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (Rust / Actix-Web)                    │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │Middleware │  │ Handlers │  │ Services │  │  Repos   │        │
│  │  (Auth,   │→ │(Controllers│→│ (Business│→ │(Database │        │
│  │  Logging) │  │  / Routes)│  │  Logic)  │  │  Access) │        │
│  └──────────┘  └──────────┘  └──────────┘  └────┬─────┘        │
│                                                   │              │
└───────────────────────────────────────────────────┼──────────────┘
                                                    │
                         ┌──────────────────────────┼──────┐
                         │                          ▼      │
                         │  ┌──────────────────────────┐   │
                         │  │    PostgreSQL 15+         │   │
                         │  │                           │   │
                         │  │  ┌────────┐ ┌──────────┐ │   │
                         │  │  │Schemas │ │  Views   │ │   │
                         │  │  │& Tables│ │& Indexes │ │   │
                         │  │  └────────┘ └──────────┘ │   │
                         │  └──────────────────────────┘   │
                         │                                  │
                         │  ┌──────────────────────────┐   │
                         │  │   Redis (Cache/Session)   │   │
                         │  └──────────────────────────┘   │
                         │                                  │
                         │       CAMADA DE DADOS            │
                         └─────────────────────────────────┘
```

---

## 2. Arquitetura do Backend (Rust)

### 2.1 Padrão Arquitetural: Clean Architecture

O backend segue os princípios da **Clean Architecture**, garantindo separação de responsabilidades e testabilidade.

```
┌─────────────────────────────────────────────────┐
│              Frameworks & Drivers                │
│  ┌───────────────────────────────────────────┐  │
│  │           Interface Adapters               │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │         Application Layer            │  │  │
│  │  │  ┌───────────────────────────────┐  │  │  │
│  │  │  │      Domain / Entities         │  │  │  │
│  │  │  └───────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 2.2 Estrutura de Camadas

```
backend/src/
├── main.rs                    # Ponto de entrada da aplicação
├── lib.rs                     # Configuração e bootstrap
│
├── config/                    # Configurações
│   ├── mod.rs
│   ├── app.rs                 # Configurações gerais da aplicação
│   ├── database.rs            # Configuração de conexão com o banco
│   └── auth.rs                # Configuração de JWT e autenticação
│
├── domain/                    # Camada de Domínio (Entidades + Traits)
│   ├── mod.rs
│   ├── entities/              # Entidades de domínio
│   │   ├── mod.rs
│   │   ├── member.rs
│   │   ├── family.rs
│   │   ├── financial_entry.rs
│   │   ├── account_plan.rs
│   │   ├── campaign.rs
│   │   ├── asset.rs
│   │   ├── maintenance.rs
│   │   ├── ebd_class.rs
│   │   ├── ebd_attendance.rs
│   │   ├── user.rs
│   │   └── church.rs
│   ├── enums/                 # Enumerações do domínio
│   │   ├── mod.rs
│   │   ├── member_status.rs
│   │   ├── gender.rs
│   │   ├── marital_status.rs
│   │   ├── entry_type.rs
│   │   ├── payment_method.rs
│   │   ├── asset_status.rs
│   │   └── role.rs
│   └── repositories/         # Traits (interfaces) dos repositórios
│       ├── mod.rs
│       ├── member_repository.rs
│       ├── financial_repository.rs
│       ├── asset_repository.rs
│       └── ebd_repository.rs
│
├── application/               # Camada de Aplicação (Use Cases / Services)
│   ├── mod.rs
│   ├── services/
│   │   ├── mod.rs
│   │   ├── member_service.rs
│   │   ├── family_service.rs
│   │   ├── financial_service.rs
│   │   ├── tithe_service.rs
│   │   ├── campaign_service.rs
│   │   ├── asset_service.rs
│   │   ├── maintenance_service.rs
│   │   ├── inventory_service.rs
│   │   ├── ebd_service.rs
│   │   ├── attendance_service.rs
│   │   ├── auth_service.rs
│   │   ├── report_service.rs
│   │   └── dashboard_service.rs
│   ├── dto/                   # Data Transfer Objects
│   │   ├── mod.rs
│   │   ├── member_dto.rs
│   │   ├── financial_dto.rs
│   │   ├── asset_dto.rs
│   │   ├── ebd_dto.rs
│   │   └── auth_dto.rs
│   └── validators/            # Validações de entrada
│       ├── mod.rs
│       └── ...
│
├── infrastructure/            # Camada de Infraestrutura
│   ├── mod.rs
│   ├── database/
│   │   ├── mod.rs
│   │   ├── connection.rs      # Pool de conexões (sqlx)
│   │   └── migrations.rs      # Controle de migrações
│   ├── repositories/          # Implementações dos repositórios
│   │   ├── mod.rs
│   │   ├── pg_member_repository.rs
│   │   ├── pg_financial_repository.rs
│   │   ├── pg_asset_repository.rs
│   │   └── pg_ebd_repository.rs
│   ├── cache/
│   │   ├── mod.rs
│   │   └── redis_cache.rs
│   └── storage/
│       ├── mod.rs
│       └── file_storage.rs    # Upload de arquivos
│
├── api/                       # Camada de Interface (HTTP)
│   ├── mod.rs
│   ├── handlers/              # Handlers das rotas
│   │   ├── mod.rs
│   │   ├── member_handler.rs
│   │   ├── family_handler.rs
│   │   ├── financial_handler.rs
│   │   ├── tithe_handler.rs
│   │   ├── campaign_handler.rs
│   │   ├── asset_handler.rs
│   │   ├── maintenance_handler.rs
│   │   ├── inventory_handler.rs
│   │   ├── ebd_handler.rs
│   │   ├── attendance_handler.rs
│   │   ├── auth_handler.rs
│   │   ├── dashboard_handler.rs
│   │   ├── report_handler.rs
│   │   └── health_handler.rs
│   ├── routes/                # Definição de rotas
│   │   ├── mod.rs
│   │   └── v1.rs
│   ├── middleware/            # Middlewares HTTP
│   │   ├── mod.rs
│   │   ├── auth_middleware.rs
│   │   ├── tenant_middleware.rs   # Multi-tenancy
│   │   ├── logging_middleware.rs
│   │   └── rate_limit_middleware.rs
│   └── responses/             # Padronização de respostas
│       ├── mod.rs
│       ├── api_response.rs
│       └── error_response.rs
│
└── errors/                    # Tratamento de erros
    ├── mod.rs
    └── app_error.rs
```

### 2.3 Crates Rust Principais

| Crate | Propósito | Versão |
|-------|-----------|--------|
| **actix-web** | Framework HTTP | 4.x |
| **sqlx** | Acesso ao PostgreSQL (async, compile-time checked) | 0.7.x |
| **serde** / **serde_json** | Serialização/Deserialização | 1.x |
| **jsonwebtoken** | Geração e validação de JWT | 9.x |
| **argon2** | Hash de senhas | 0.5.x |
| **uuid** | Geração de UUIDs | 1.x |
| **chrono** | Manipulação de datas | 0.4.x |
| **validator** | Validação de DTOs | 0.18.x |
| **tracing** / **tracing-subscriber** | Logging estruturado | 0.1.x |
| **dotenv** | Variáveis de ambiente | 0.15.x |
| **tokio** | Runtime assíncrono | 1.x |
| **redis** | Cliente Redis | 0.25.x |
| **lettre** | Envio de e-mails | 0.11.x |
| **utoipa** | Documentação OpenAPI/Swagger | 4.x |

### 2.4 Cargo.toml Base

```toml
[package]
name = "igreja-manager-api"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"

[dependencies]
actix-web = "4"
actix-cors = "0.7"
actix-multipart = "0.7"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
sqlx = { version = "0.7", features = ["runtime-tokio", "postgres", "chrono", "uuid", "migrate"] }
jsonwebtoken = "9"
argon2 = "0.5"
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
validator = { version = "0.18", features = ["derive"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
tracing-actix-web = "0.7"
dotenvy = "0.15"
tokio = { version = "1", features = ["full"] }
redis = { version = "0.25", features = ["tokio-comp"] }
lettre = { version = "0.11", features = ["tokio1-native-tls"] }
utoipa = { version = "4", features = ["actix_extras", "chrono", "uuid"] }
utoipa-swagger-ui = { version = "7", features = ["actix-web"] }
thiserror = "1"
anyhow = "1"

[dev-dependencies]
actix-rt = "2"
reqwest = { version = "0.12", features = ["json"] }
fake = { version = "2", features = ["derive"] }
```

---

## 3. Arquitetura do Frontend (Flutter)

### 3.1 Padrão Arquitetural: Feature-First + Clean Architecture

```
frontend/lib/
├── main.dart                  # Ponto de entrada
├── app.dart                   # Configuração do MaterialApp
│
├── core/                      # Código compartilhado (core)
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_typography.dart
│   ├── network/
│   │   ├── api_client.dart        # Cliente HTTP (Dio)
│   │   ├── api_interceptors.dart  # Interceptors (auth, logging)
│   │   ├── api_response.dart
│   │   └── api_exceptions.dart
│   ├── storage/
│   │   ├── local_storage.dart     # SharedPreferences / Hive
│   │   └── secure_storage.dart    # FlutterSecureStorage
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── light_theme.dart
│   │   └── dark_theme.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── currency_utils.dart
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── di/
│       └── injection_container.dart  # Dependency Injection (get_it)
│
├── shared/                    # Widgets e componentes reutilizáveis
│   ├── widgets/
│   │   ├── custom_app_bar.dart
│   │   ├── custom_drawer.dart
│   │   ├── custom_text_field.dart
│   │   ├── custom_button.dart
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   ├── empty_state_widget.dart
│   │   ├── confirmation_dialog.dart
│   │   ├── search_bar_widget.dart
│   │   ├── pagination_widget.dart
│   │   ├── chart_widget.dart
│   │   └── pdf_viewer_widget.dart
│   └── models/
│       ├── paginated_response.dart
│       └── filter_params.dart
│
├── features/                  # Módulos por funcionalidade
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/              # ou provider/cubit
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── dashboard/
│   │   └── ... (mesma estrutura)
│   │
│   ├── members/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── member_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── member_model.dart
│   │   │   └── repositories/
│   │   │       └── member_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── member.dart
│   │   │   ├── repositories/
│   │   │   │   └── member_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_members.dart
│   │   │       ├── create_member.dart
│   │   │       ├── update_member.dart
│   │   │       └── delete_member.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── member_bloc.dart
│   │       │   ├── member_event.dart
│   │       │   └── member_state.dart
│   │       ├── pages/
│   │       │   ├── members_list_page.dart
│   │       │   ├── member_detail_page.dart
│   │       │   └── member_form_page.dart
│   │       └── widgets/
│   │           ├── member_card.dart
│   │           ├── member_filter_panel.dart
│   │           └── member_stats_card.dart
│   │
│   ├── financial/
│   │   └── ... (mesma estrutura)
│   │
│   ├── assets/                # Patrimônio
│   │   └── ... (mesma estrutura)
│   │
│   ├── ebd/
│   │   └── ... (mesma estrutura)
│   │
│   └── settings/
│       └── ... (mesma estrutura)
│
└── routes/
    ├── app_router.dart        # Definição de rotas (go_router)
    └── route_guards.dart      # Guards de autenticação
```

### 3.2 Packages Flutter Principais

| Package | Propósito |
|---------|-----------|
| **flutter_bloc** | Gerenciamento de estado |
| **dio** | Cliente HTTP |
| **go_router** | Navegação/Roteamento |
| **get_it** + **injectable** | Injeção de dependência |
| **freezed** + **json_serializable** | Imutabilidade e serialização |
| **flutter_secure_storage** | Armazenamento seguro (tokens) |
| **hive** | Banco local (cache offline) |
| **fl_chart** | Gráficos |
| **pdf** | Geração de PDFs |
| **printing** | Impressão de relatórios |
| **image_picker** | Seleção de fotos |
| **cached_network_image** | Cache de imagens |
| **intl** | Internacionalização e formatação |
| **mask_text_input_formatter** | Máscaras de entrada |
| **table_calendar** | Widget de calendário |
| **shimmer** | Loading skeleton |

---

## 4. Banco de Dados

### 4.1 Estratégia de Multi-Tenancy

Utilizaremos **Schema-based multi-tenancy** no PostgreSQL:

```
PostgreSQL
├── public schema          # Tabelas compartilhadas (churches, users, global configs)
├── church_<uuid> schema   # Dados isolados por igreja
│   ├── members
│   ├── families
│   ├── financial_entries
│   ├── assets
│   ├── ebd_classes
│   └── ...
```

**Alternativa simplificada** (para fase inicial): coluna `church_id` em todas as tabelas com Row Level Security (RLS) do PostgreSQL.

### 4.2 Migrações

Utilizaremos o **sqlx-cli** para gerenciar migrações:

```bash
# Instalar
cargo install sqlx-cli --features postgres

# Criar migração
sqlx migrate add create_members_table

# Executar migrações
sqlx migrate run

# Reverter última migração
sqlx migrate revert
```

---

## 5. Infraestrutura e Deploy

### 5.1 Ambiente de Desenvolvimento (Docker Compose)

```yaml
# docker-compose.yml
version: "3.8"

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: igreja_manager
      POSTGRES_USER: igreja_user
      POSTGRES_PASSWORD: igreja_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgres://igreja_user:igreja_pass@postgres:5432/igreja_manager
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET}
      RUST_LOG: info
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  redis_data:
```

### 5.2 Diagrama de Deploy (Produção)

```
┌──────────────────────────────────────────────────┐
│                   CDN (Cloudflare)                │
│              (Assets estáticos Flutter Web)        │
└──────────────────────┬───────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────┐
│              Load Balancer / Proxy                │
│                 (Nginx / Traefik)                 │
│          TLS Termination, Rate Limiting           │
└──────────────────────┬───────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
┌──────────────┐┌──────────────┐┌──────────────┐
│  API Rust    ││  API Rust    ││  API Rust    │
│  Instance 1  ││  Instance 2  ││  Instance N  │
└──────┬───────┘└──────┬───────┘└──────┬───────┘
       │               │               │
       └───────────────┼───────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼                           ▼
┌──────────────────┐     ┌──────────────────┐
│   PostgreSQL     │     │     Redis        │
│  (Primary +      │     │   (Cache +       │
│   Read Replica)  │     │    Sessions)     │
└──────────────────┘     └──────────────────┘
```

### 5.3 Opções de Hospedagem

| Opção | Prós | Contras |
|-------|------|---------|
| **VPS (Hetzner/DigitalOcean)** | Custo baixo, controle total | Gerenciamento manual |
| **Railway / Fly.io** | Deploy simples, escala automática | Custo médio |
| **AWS (ECS/Fargate)** | Escala, serviços gerenciados | Complexidade, custo |

---

## 6. Padrões e Convenções

### 6.1 Padrão de Resposta da API

```json
{
  "success": true,
  "data": { ... },
  "message": "Operação realizada com sucesso",
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

### 6.2 Padrão de Erro da API

```json
{
  "success": false,
  "error": {
    "code": "MEMBER_NOT_FOUND",
    "message": "Membro não encontrado",
    "details": null
  }
}
```

### 6.3 Versionamento da API

- Versionamento via URL: `/api/v1/...`
- Novas versões mantêm retrocompatibilidade quando possível
- Deprecação com aviso prévio de pelo menos 1 versão

### 6.4 Nomenclatura

| Contexto | Convenção | Exemplo |
|----------|-----------|---------|
| Tabelas SQL | snake_case, plural | `members`, `financial_entries` |
| Colunas SQL | snake_case | `first_name`, `created_at` |
| Endpoints API | kebab-case, plural | `/api/v1/members`, `/api/v1/financial-entries` |
| Structs Rust | PascalCase | `Member`, `FinancialEntry` |
| Funções Rust | snake_case | `get_member_by_id` |
| Classes Dart | PascalCase | `MemberBloc`, `MemberModel` |
| Arquivos Dart | snake_case | `member_bloc.dart` |

---

## 7. Fluxo de Autenticação

```
┌────────┐                    ┌─────────┐                  ┌──────────┐
│ Client │                    │   API   │                  │ Database │
└───┬────┘                    └────┬────┘                  └────┬─────┘
    │                              │                            │
    │  POST /api/v1/auth/login     │                            │
    │  {email, password}           │                            │
    │─────────────────────────────▶│                            │
    │                              │  SELECT user WHERE email   │
    │                              │───────────────────────────▶│
    │                              │  User data                 │
    │                              │◀───────────────────────────│
    │                              │                            │
    │                              │  Verify password (argon2)  │
    │                              │  Generate JWT tokens       │
    │                              │                            │
    │  {access_token, refresh_token}│                           │
    │◀─────────────────────────────│                            │
    │                              │                            │
    │  GET /api/v1/members         │                            │
    │  Authorization: Bearer <jwt> │                            │
    │─────────────────────────────▶│                            │
    │                              │  Validate JWT              │
    │                              │  Extract church_id + role  │
    │                              │  Check permissions         │
    │                              │                            │
    │                              │  SELECT ... WHERE church_id│
    │                              │───────────────────────────▶│
    │                              │  Results                   │
    │                              │◀───────────────────────────│
    │  {data: [...members]}        │                            │
    │◀─────────────────────────────│                            │
```

### Tokens JWT

- **Access Token**: Vida curta (15 minutos), usado em cada requisição
- **Refresh Token**: Vida longa (7 dias), usado para renovar o access token
- **Claims do token:**
  ```json
  {
    "sub": "user_uuid",
    "church_id": "church_uuid",
    "role": "secretary",
    "permissions": ["members:read", "members:write", "ebd:read", "ebd:write"],
    "exp": 1708300000,
    "iat": 1708299100
  }
  ```

---

## 8. Estratégia de Testes

### Backend (Rust)

| Tipo | Ferramenta | Cobertura Alvo |
|------|------------|----------------|
| Unitários | `cargo test` (built-in) | Services, validators, utils |
| Integração | `sqlx` + testcontainers | Repositories, handlers |
| E2E | `reqwest` + test server | Fluxos completos da API |

### Frontend (Flutter)

| Tipo | Ferramenta | Cobertura Alvo |
|------|------------|----------------|
| Unitários | `flutter_test` | BLoCs, use cases, models |
| Widget | `flutter_test` | Componentes isolados |
| Integração | `integration_test` | Fluxos de tela completos |

---

## 9. Observabilidade

### Logging
- **Backend**: `tracing` com output em JSON estruturado
- **Frontend**: Logger customizado com níveis (debug, info, warn, error)

### Métricas
- Tempo de resposta por endpoint
- Taxa de erros
- Número de requisições por segundo
- Uso de memória e CPU

### Health Check
- Endpoint `/api/v1/health` retorna status do sistema
- Verifica conectividade com PostgreSQL e Redis

---

*Documento de referência técnica — atualizado conforme decisões arquiteturais evoluem.*
