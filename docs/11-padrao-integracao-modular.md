# 🔗 Padrão de Integração Modular — Igreja Manager

> **Data de criação:** 21 de fevereiro de 2026  
> **Versão do documento:** 1.0  
> **Status:** 📐 Padrão arquitetural (normativo)  
> **Módulo afetado:** Todos (Transversal)

---

## 1. Objetivo

Este documento define o **padrão obrigatório** para integração entre módulos do Igreja Manager, garantindo:

1. **Consistência**: todo módulo novo ou existente segue as mesmas convenções
2. **Modularidade**: cada módulo funciona **de forma independente** — habilitado/desabilitado por configuração
3. **Extensibilidade**: o módulo de Congregações (e futuros módulos transversais) se conecta a qualquer módulo sem alterar a lógica interna dele
4. **Comercialização**: a igreja paga por módulos isolados (ex: só Membros + Financeiro, sem EBD) — e cada módulo funciona perfeitamente sozinho

---

## 2. Princípios Fundamentais

### PF-001: Dependências Sempre Opcionais (Soft Dependencies)

Todo campo que referencia outra tabela de **outro módulo** deve ser:
- **Nullable** no banco de dados (`UUID NULL REFERENCES ...`)
- **`Option<Uuid>`** no Rust (entity + DTO)
- **Nullable** no Flutter (`String?` / `Uuid?`)
- **`ON DELETE SET NULL`** na FK do banco

> **Exceção única**: `church_id` — é a âncora de multi-tenancy e é **sempre obrigatório** em toda tabela.

```sql
-- ✅ CORRETO: FK soft entre módulos
ALTER TABLE financial_entries 
    ADD COLUMN member_id UUID REFERENCES members(id) ON DELETE SET NULL;

-- ❌ ERRADO: FK hard entre módulos
ALTER TABLE financial_entries 
    ADD COLUMN member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE;
```

**Justificativa**: Se a igreja não tem o módulo de Membros ativo, lançamentos financeiros continuam funcionando — `member_id` fica `NULL`.

### PF-002: Módulo Autossuficiente

Cada módulo deve poder operar **sem nenhum outro módulo instalado/ativo**, exceto o módulo Core (auth, churches, users). Isso significa:

| Cenário | Comportamento Esperado |
|---------|----------------------|
| Só Membros ativo | CRUD de membros funciona. `congregation_id` fica NULL se Congregações não está ativo. |
| Só Financeiro ativo | Lançamentos funcionam. `member_id` fica NULL (não vincula a membro). |
| Só EBD ativo | Turmas e aulas funcionam. `teacher_id` fica NULL se Membros não está ativo. Alunos podem ser cadastrados como "visitante" (sem `member_id`). |
| Só Patrimônio ativo | Bens funcionam. `donor_member_id` e `borrower_member_id` ficam NULL. Empréstimos externos usam campo `borrower_name` (texto). |
| Membros + Congregações | Membros ganham campo `congregation_id`. Listagem filtra por congregação. |
| Todos ativos | Experiência completa com todas as integrações. |

### PF-003: Congregações como Camada Transversal

O módulo de Congregações é um **filtro transversal** que não modifica a lógica de negócio dos módulos — apenas adiciona um **eixo de segmentação**:

```
Sem Congregações:           Com Congregações:
┌────────────────┐          ┌────────────────┐
│   church_id    │          │   church_id    │
│  (tenant)      │          │  (tenant)      │
│                │          │  ┌──────────┐  │
│  [todos os     │          │  │congreg_id│  │
│   dados]       │          │  │ (filtro) │  │
│                │          │  └──────────┘  │
└────────────────┘          └────────────────┘
```

- `congregation_id = NULL` → **Sede / Geral** (comportamento padrão, retrocompatível)
- `congregation_id = UUID` → Dado pertence àquela congregação
- Consultas **sem filtro de congregação** retornam tudo (visão consolidada)

### PF-004: Nomenclatura Unificada

Toda coluna de referência a congregação segue o mesmo padrão em **todas** as tabelas:

| Camada | Nome | Tipo |
|--------|------|------|
| Banco de Dados | `congregation_id` | `UUID NULL REFERENCES congregations(id) ON DELETE SET NULL` |
| Rust Entity | `congregation_id: Option<Uuid>` | Campo na struct |
| Rust DTO (Create) | `congregation_id: Option<Uuid>` | Sem `#[validate]` |
| Rust DTO (Update) | `congregation_id: Option<Option<Uuid>>` | `None` = não alterar, `Some(None)` = remover, `Some(uuid)` = definir |
| Rust DTO (Filter) | `congregation_id: Option<Uuid>` | Query parameter opcional |
| Flutter Model | `String? congregationId` | Campo no model com `@JsonKey(name: 'congregation_id')` |
| Flutter Filter | `String? congregationId` | Query param no repository |

### PF-005: Feature Flags por Módulo

O sistema deve suportar ativação/desativação de módulos por tenant (`church`):

```sql
-- Tabela de feature flags (futuro — pode ser implementada depois)
CREATE TABLE IF NOT EXISTS church_modules (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id   UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
    module_key  VARCHAR(50) NOT NULL,  -- 'members', 'financial', 'assets', 'ebd', 'ministries', 'congregations'
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    activated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at  TIMESTAMPTZ,           -- NULL = sem expiração
    UNIQUE(church_id, module_key)
);
```

Enquanto a tabela não existe, **todos os módulos são considerados ativos** para manter retrocompatibilidade.

---

## 3. Mapa de Dependências Entre Módulos

### 3.1 Diagrama de Dependências

```
                    ┌─────────────────────┐
                    │       CORE          │
                    │  (churches, users,  │
                    │   roles, auth)      │
                    │   SEMPRE ATIVO      │
                    └────────┬────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────┐  ┌────────────┐  ┌─────────────┐
    │  MEMBROS    │  │CONGREGAÇÕES│  │  RELATÓRIOS  │
    │             │  │(transversal│  │  (agregador) │
    │  Funciona   │  │  opcional) │  │              │
    │  sozinho    │  │            │  │  Lê todos os │
    │             │  │  Adiciona  │  │  módulos     │
    └──┬──┬──┬───┘  │  filtro a  │  │  ativos      │
       │  │  │      │  TODOS os  │  └──────────────┘
       │  │  │      │  módulos   │
       │  │  │      └──────┬─────┘
       │  │  │             │ congregation_id (SOFT, nullable)
       │  │  │             │ em todas as tabelas de dados
       │  │  │             │
  ┌────┘  │  └──────┐     │
  │       │         │     │
  ▼       ▼         ▼     │
┌─────┐ ┌─────┐ ┌──────┐ │
│FIN. │ │ EBD │ │PATRI.│ │
│     │ │     │ │MÔNIO │ │
│ ref:│ │ ref:│ │      │ │
│ mem-│ │ mem-│ │ ref:  │ │
│ ber │ │ ber │ │ mem-  │ │
│ _id │ │ _id │ │ ber   │ │
│(soft│ │(soft│ │ _id   │ │
│ )   │ │ )   │ │(soft) │ │
└─────┘ └─────┘ └──────┘ │
  ▲       ▲       ▲       │
  └───────┴───────┴───────┘
      congregation_id
      adicionado se
      Congregações ativo
```

### 3.2 Classificação de Dependências

| Módulo Origem | Módulo Destino | Tipo | Campo FK | Permite NULL? | Sem o Destino... |
|---------------|---------------|------|----------|:------------:|------------------|
| **Financeiro** | Membros | Soft | `member_id` | Sim | Lançamentos sem vínculo a membro |
| **Financeiro** | Congregações | Soft | `congregation_id` | Sim | Lançamentos sem segregação |
| **EBD** | Membros | Soft* | `teacher_id`, `member_id` | Sim/Sim | Professores como texto; alunos como visitantes |
| **Patrimônio** | Membros | Soft | `donor_member_id` | Sim | Doação sem vínculo a membro |
| **Patrimônio** | Membros | Soft** | `borrower_member_id` | Sim | Empréstimo usa `borrower_name` (texto) |
| **Ministérios** | Membros | Soft | `leader_id` | Sim | Ministério sem líder definido |
| **Famílias** | Membros | Soft | `head_id` | Sim | Família sem chefe definido |
| **Congregações** | Membros | Soft | `leader_id` | Sim | Congregação sem dirigente definido |
| **Dashboard** | Todos | Soft (leitura) | — | — | Mostra stats apenas dos módulos ativos |
| **Relatórios** | Todos | Soft (leitura) | — | — | Gera relatórios apenas dos módulos ativos |

> \* `ebd_enrollments.member_id` hoje é NOT NULL no banco. Para modularidade plena, deveria ser nullable com um campo alternativo `visitor_name`. **Pendência de migração.**
>
> \** `asset_loans.borrower_member_id` hoje é NOT NULL. Para modularidade plena, deveria ser nullable com campo alternativo `borrower_name`. **Pendência de migração.**

### 3.3 Módulos e Suas Tabelas

| Módulo | Tabelas Próprias | Tabelas de Junção |
|--------|-----------------|-------------------|
| **Core** | `churches`, `users`, `roles`, `permissions`, `audit_logs`, `password_reset_tokens` | `user_permissions` |
| **Membros** | `members`, `member_history` | — |
| **Famílias** | `families`, `family_relationships` | — |
| **Ministérios** | `ministries` | `member_ministries` |
| **Financeiro** | `financial_entries`, `account_plans`, `bank_accounts`, `campaigns`, `monthly_closings` | — |
| **Patrimônio** | `assets`, `asset_categories`, `asset_loans`, `maintenances`, `inventories`, `inventory_items` | — |
| **EBD** | `ebd_terms`, `ebd_classes`, `ebd_enrollments`, `ebd_lessons`, `ebd_attendances`, `ebd_lesson_contents`, `ebd_lesson_activities`, `ebd_activity_responses`, `ebd_lesson_materials`, `ebd_student_notes`, `ebd_student_profiles` | — |
| **Congregações** | `congregations` | `user_congregations` |

---

## 4. Padrão de Implementação — Backend (Rust)

### 4.1 Anatomia de um Módulo Padrão

Todo módulo deve implementar as seguintes camadas:

```
backend/src/
├── domain/entities/
│   └── {modulo}.rs              # Struct com FromRow + Serialize
├── application/
│   ├── dto/
│   │   └── {modulo}_dto.rs      # CreateRequest, UpdateRequest, Filter, Response
│   └── services/
│       └── {modulo}_service.rs  # Lógica de negócio + queries SQL
└── api/handlers/
    └── {modulo}_handler.rs      # Endpoints HTTP (actix-web)
```

### 4.2 Entity — Campos Obrigatórios

Toda entity principal de um módulo **deve** incluir:

```rust
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MinhaEntidade {
    // === Campos do sistema (OBRIGATÓRIOS em toda entity) ===
    pub id: Uuid,
    pub church_id: Uuid,
    
    // === Campo de congregação (OBRIGATÓRIO em toda entity de dados) ===
    pub congregation_id: Option<Uuid>,
    
    // === Campos do módulo (específicos) ===
    pub name: String,
    // ... outros campos do módulo ...
    
    // === Campos de auditoria (OBRIGATÓRIOS) ===
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}
```

**Regras:**
- `id`, `church_id`, `created_at`, `updated_at` → sempre presentes
- `congregation_id: Option<Uuid>` → sempre presente em tabelas de dados (nullable)
- `deleted_at: Option<DateTime<Utc>>` → presente se a entidade usa soft delete
- A entity deve mapear **todos os campos da tabela** (incluindo os de referência cross-módulo)

### 4.3 DTO — Padrão para Referências Cross-Módulo

```rust
// ===========================
// CREATE REQUEST
// ===========================
#[derive(Debug, Deserialize, Validate)]
pub struct CreateMinhaEntidadeRequest {
    // Campos obrigatórios do módulo
    #[validate(length(min = 2, max = 200))]
    pub name: String,
    
    // Referência transversal (congregação) — sempre Option
    pub congregation_id: Option<Uuid>,
    
    // Referências cross-módulo — sempre Option
    pub member_id: Option<Uuid>,       // Soft dep → Membros
    pub category_id: Option<Uuid>,     // Se intra-módulo, pode ser required
}

// ===========================
// UPDATE REQUEST
// ===========================
#[derive(Debug, Deserialize, Validate)]
pub struct UpdateMinhaEntidadeRequest {
    #[validate(length(min = 2, max = 200))]
    pub name: Option<String>,
    
    // Para campos Option que podem ser "removidos", usar Option<Option<Uuid>>
    // None = não alterar | Some(None) = remover | Some(Some(uuid)) = definir
    pub congregation_id: Option<Option<Uuid>>,
    pub member_id: Option<Option<Uuid>>,
}

// ===========================
// FILTER (Query Params)
// ===========================
#[derive(Debug, Deserialize)]
pub struct MinhaEntidadeFilter {
    pub search: Option<String>,
    pub is_active: Option<bool>,
    
    // Filtro por congregação — OBRIGATÓRIO em todo Filter
    pub congregation_id: Option<Uuid>,
    
    // Paginação
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}
```

### 4.4 Service — Padrão de Queries com Congregação

Todo service de listagem deve implementar o filtro de congregação de forma **condicional**:

```rust
impl MinhaEntidadeService {
    pub async fn list(
        pool: &PgPool,
        church_id: Uuid,
        filter: MinhaEntidadeFilter,
    ) -> Result<Vec<MinhaEntidade>, AppError> {
        let mut query = String::from(
            "SELECT * FROM minha_tabela WHERE church_id = $1 AND deleted_at IS NULL"
        );
        let mut param_count = 1;

        // === FILTRO DE CONGREGAÇÃO (padrão obrigatório) ===
        if let Some(congregation_id) = &filter.congregation_id {
            param_count += 1;
            query.push_str(&format!(" AND congregation_id = ${}", param_count));
        }

        // === Filtros específicos do módulo ===
        if let Some(search) = &filter.search {
            param_count += 1;
            query.push_str(&format!(" AND name ILIKE ${}", param_count));
        }

        // ... monta e executa query com sqlx::query_as ...
    }

    pub async fn create(
        pool: &PgPool,
        church_id: Uuid,
        req: CreateMinhaEntidadeRequest,
    ) -> Result<MinhaEntidade, AppError> {
        // congregation_id é incluído no INSERT mesmo se NULL
        let entity = sqlx::query_as::<_, MinhaEntidade>(
            "INSERT INTO minha_tabela (id, church_id, congregation_id, name, ...)
             VALUES ($1, $2, $3, $4, ...)
             RETURNING *"
        )
        .bind(Uuid::new_v4())
        .bind(church_id)
        .bind(req.congregation_id)  // Option<Uuid> — binds NULL if None
        .bind(&req.name)
        .fetch_one(pool)
        .await?;

        Ok(entity)
    }
}
```

### 4.5 Handler — Padrão de Endpoint com Congregação

```rust
// Listagem com filtro de congregação via query params
#[utoipa::path(
    get,
    path = "/api/v1/minha-entidade",
    params(
        ("congregation_id" = Option<Uuid>, Query, description = "Filtrar por congregação"),
        ("search" = Option<String>, Query, description = "Busca por nome"),
    ),
)]
pub async fn list(
    pool: web::Data<PgPool>,
    claims: Claims,
    query: web::Query<MinhaEntidadeFilter>,
) -> Result<HttpResponse, AppError> {
    let church_id = claims.church_id()?;
    let items = MinhaEntidadeService::list(&pool, church_id, query.into_inner()).await?;
    Ok(HttpResponse::Ok().json(ApiResponse::success(items)))
}

// Criação com congregation_id no body
pub async fn create(
    pool: web::Data<PgPool>,
    claims: Claims,
    body: web::Json<CreateMinhaEntidadeRequest>,
) -> Result<HttpResponse, AppError> {
    body.validate()?;
    let church_id = claims.church_id()?;
    // congregation_id vem no body (pode ser null)
    let entity = MinhaEntidadeService::create(&pool, church_id, body.into_inner()).await?;
    Ok(HttpResponse::Created().json(ApiResponse::success(entity)))
}
```

### 4.6 Padrão de Resposta — Incluir Nome da Congregação

Para listagens que retornam dados ao frontend, o backend deve incluir o **nome da congregação** via LEFT JOIN quando o campo `congregation_id` não é NULL:

```rust
// Na struct Summary (usada para listagem)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MinhaEntidadeSummary {
    pub id: Uuid,
    pub name: String,
    pub congregation_id: Option<Uuid>,
    pub congregation_name: Option<String>,  // via LEFT JOIN
    // ... outros campos resumidos ...
}

// Na query de listagem
let query = "
    SELECT 
        e.*,
        cg.name AS congregation_name
    FROM minha_tabela e
    LEFT JOIN congregations cg ON cg.id = e.congregation_id
    WHERE e.church_id = $1 AND e.deleted_at IS NULL
";
```

---

## 5. Padrão de Implementação — Frontend (Flutter)

### 5.1 Anatomia de um Módulo Padrão

```
frontend/lib/features/{modulo}/
├── bloc/
│   ├── {modulo}_bloc.dart         # BLoC principal
│   └── {modulo}_event_state.dart  # Events + States
├── data/
│   ├── models/
│   │   └── {modulo}_models.dart   # Model classes (JSON serialization)
│   └── repositories/
│       └── {modulo}_repository.dart # API calls via Dio
└── presentation/
    ├── pages/
    │   ├── {modulo}_list_page.dart
    │   ├── {modulo}_form_page.dart
    │   └── {modulo}_detail_page.dart
    └── widgets/
        └── {modulo}_card.dart     # Widgets reutilizáveis
```

### 5.2 Model — Campos Obrigatórios

```dart
class MinhaEntidade {
  final String id;
  final String churchId;
  
  // === Campo de congregação (OBRIGATÓRIO em todo model de dados) ===
  final String? congregationId;
  final String? congregationName;  // vem do LEFT JOIN no backend
  
  // === Campos do módulo ===
  final String name;
  // ... outros campos ...
  
  // === Campos de auditoria ===
  final DateTime createdAt;
  final DateTime updatedAt;

  MinhaEntidade({
    required this.id,
    required this.churchId,
    this.congregationId,
    this.congregationName,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MinhaEntidade.fromJson(Map<String, dynamic> json) => MinhaEntidade(
    id: json['id'],
    churchId: json['church_id'],
    congregationId: json['congregation_id'],
    congregationName: json['congregation_name'],
    name: json['name'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'congregation_id': congregationId,  // Inclui mesmo se null
    // ... outros campos ...
  };
}
```

### 5.3 Repository — Padrão de Filtro por Congregação

```dart
class MinhaEntidadeRepository {
  final ApiClient _apiClient;
  
  MinhaEntidadeRepository(this._apiClient);

  Future<List<MinhaEntidade>> list({
    String? congregationId,   // OBRIGATÓRIO como parâmetro opcional
    String? search,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    
    // === Filtro de congregação (padrão obrigatório) ===
    if (congregationId != null) {
      queryParams['congregation_id'] = congregationId;
    }
    
    if (search != null) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    final response = await _apiClient.dio.get(
      '/v1/minha-entidade',
      queryParameters: queryParams,
    );
    
    final list = (response.data['data'] as List)
        .map((e) => MinhaEntidade.fromJson(e))
        .toList();
    return list;
  }
}
```

### 5.4 BLoC — Integração com CongregationContextCubit

Todo BLoC de módulo que exibe listagens **deve**:

1. Receber o `CongregationContextCubit` como dependência
2. Escutar mudanças de congregação ativa
3. Recarregar dados automaticamente ao trocar congregação
4. Passar `congregation_id` nas chamadas ao repository

```dart
class MinhaEntidadeBloc extends Bloc<MinhaEntidadeEvent, MinhaEntidadeState> {
  final MinhaEntidadeRepository _repository;
  final CongregationContextCubit _congregationContext;
  StreamSubscription? _congregationSubscription;

  MinhaEntidadeBloc({
    required MinhaEntidadeRepository repository,
    required CongregationContextCubit congregationContext,
  })  : _repository = repository,
        _congregationContext = congregationContext,
        super(MinhaEntidadeInitial()) {
    
    on<MinhaEntidadeLoadRequested>(_onLoadRequested);
    on<MinhaEntidadeCongregationChanged>(_onCongregationChanged);

    // === Escuta mudanças de congregação (OBRIGATÓRIO) ===
    _congregationSubscription = _congregationContext.stream.listen((state) {
      if (state.hasLoaded) {
        add(MinhaEntidadeCongregationChanged(state.activeCongregationId));
      }
    });
  }

  Future<void> _onLoadRequested(
    MinhaEntidadeLoadRequested event,
    Emitter<MinhaEntidadeState> emit,
  ) async {
    emit(MinhaEntidadeLoading());
    try {
      final items = await _repository.list(
        congregationId: _congregationContext.activeCongregationId,
        search: event.search,
      );
      emit(MinhaEntidadeLoaded(
        items: items,
        activeCongregationId: _congregationContext.activeCongregationId,
      ));
    } catch (e) {
      emit(MinhaEntidadeError(e.toString()));
    }
  }

  Future<void> _onCongregationChanged(
    MinhaEntidadeCongregationChanged event,
    Emitter<MinhaEntidadeState> emit,
  ) async {
    // Recarrega com a nova congregação
    add(MinhaEntidadeLoadRequested());
  }

  @override
  Future<void> close() {
    _congregationSubscription?.cancel();
    return super.close();
  }
}
```

### 5.5 Formulário — Dropdown de Congregação

Todo formulário de criação/edição **deve** incluir o seletor de congregação quando o módulo de congregações está ativo:

```dart
// No build() do FormScreen:
Widget _buildCongregationField(BuildContext context) {
  final congregationContext = context.read<CongregationContextCubit>();
  
  // Se não há congregações cadastradas, não mostra o campo
  if (!congregationContext.state.hasCongregations) {
    return const SizedBox.shrink();
  }

  return DropdownButtonFormField<String?>(
    decoration: const InputDecoration(
      labelText: 'Congregação',
      prefixIcon: Icon(PhosphorIcons.church),
    ),
    value: _selectedCongregationId,
    items: [
      const DropdownMenuItem(
        value: null,
        child: Text('Sede / Geral'),
      ),
      ...congregationContext.state.availableCongregations.map(
        (c) => DropdownMenuItem(
          value: c.id,
          child: Text(c.shortName ?? c.name),
        ),
      ),
    ],
    onChanged: (value) {
      setState(() => _selectedCongregationId = value);
    },
  );
}
```

**Comportamento esperado:**
- Se há congregação ativa no contexto global → pré-seleciona no dropdown
- Se o usuário é dirigente → mostra apenas a(s) congregação(ões) que ele tem acesso
- Se não há congregações cadastradas → campo não aparece
- O campo sempre vem **abaixo** dos campos obrigatórios do módulo

### 5.6 Card / ListTile — Exibir Congregação

Todo item de lista deve mostrar a congregação a qual pertence (quando aplicável):

```dart
// No card/tile do item na listagem:
if (item.congregationName != null)
  Text(
    item.congregationName!,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    ),
  ),
```

Quando a visão é "Todas (Geral)", cada item mostra um badge/label com o nome da congregação, facilitando a identificação visual.

### 5.7 Dashboard — Padrão de Carregamento por Congregação

```dart
// No DashboardScreen — todos os carregamentos de stats passam congregationId:
void _loadStats() {
  final congregationId = context.read<CongregationContextCubit>().activeCongregationId;
  
  _loadMemberStats(congregationId);     // ✅ Implementado
  _loadFinancialStats(congregationId);  // ✅ Implementado
  _loadAssetStats(congregationId);      // ✅ Implementado
  _loadEbdStats(congregationId);        // ✅ Implementado
}
```

---

## 6. Padrão de Implementação — Banco de Dados

### 6.1 Migração para Adicionar Congregação a um Módulo

Ao criar uma nova tabela que pertence a um módulo de dados:

```sql
CREATE TABLE IF NOT EXISTS nova_tabela (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    church_id       UUID NOT NULL REFERENCES churches(id) ON DELETE CASCADE,
    congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL,
    
    -- campos do módulo
    name            VARCHAR(200) NOT NULL,
    -- ...
    
    -- auditoria
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    
    UNIQUE(church_id, name)
);

-- Índice para filtro por congregação (OBRIGATÓRIO)
CREATE INDEX IF NOT EXISTS idx_nova_tabela_congregation 
    ON nova_tabela(congregation_id) WHERE congregation_id IS NOT NULL;

-- Índice de tenant (OBRIGATÓRIO)
CREATE INDEX IF NOT EXISTS idx_nova_tabela_church 
    ON nova_tabela(church_id);
```

### 6.2 Migração para Módulo Já Existente

Ao integrar congregação em tabela que já existe:

```sql
-- Adiciona coluna
ALTER TABLE tabela_existente 
    ADD COLUMN IF NOT EXISTS congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL;

-- Adiciona índice
CREATE INDEX IF NOT EXISTS idx_tabela_existente_congregation 
    ON tabela_existente(congregation_id) WHERE congregation_id IS NOT NULL;
```

> **Nota**: Dados existentes ficarão com `congregation_id = NULL`, que é tratado como "Sede/Geral". Usar o endpoint de **atribuição em lote** para associar retroativamente.

---

## 7. Padrão de Permissões e Acesso por Congregação

### 7.1 Regras de Acesso

| Papel | Visão | Pode trocar contexto? | Registro em `user_congregations`? |
|-------|-------|:--------------------:|:-------------------------------:|
| **Super Admin** | Todas as congregações | Sim (qualquer uma + "Geral") | Não necessário |
| **Pastor/Admin** | Todas as congregações | Sim (qualquer uma + "Geral") | Não necessário |
| **Dirigente** | Sua(s) congregação(ões) | Sim (entre as suas) | Sim — `role = 'dirigente'` |
| **Secretário local** | Sua congregação | Não (contexto fixo) | Sim — `role = 'secretario'` |
| **Tesoureiro local** | Sua congregação (só financeiro) | Não | Sim — `role = 'tesoureiro'` |
| **Professor EBD** | Sua congregação (só EBD) | Não | Sim — `role = 'professor'` |

### 7.2 Middleware de Congregação (Backend)

O middleware deve ser implementado como uma **função auxiliar** chamada nos handlers, não como um middleware global:

```rust
/// Determina o congregation_id efetivo para o usuário logado.
/// 
/// Lógica:
/// 1. Se o usuário é admin/pastor → usa o congregation_id do request (ou None = tudo)
/// 2. Se o usuário tem congregações atribuídas → valida se o congregation_id do request
///    está entre as congregações permitidas
/// 3. Se não passou congregation_id → usa a congregação primária do usuário
pub async fn resolve_congregation_access(
    pool: &PgPool,
    user_id: Uuid,
    user_role: &str,
    requested_congregation_id: Option<Uuid>,
) -> Result<Option<Uuid>, AppError> {
    // Admin/Pastor: acesso irrestrito
    if matches!(user_role, "super_admin" | "pastor" | "admin") {
        return Ok(requested_congregation_id);
    }
    
    // Buscar congregações do usuário
    let user_congregations = sqlx::query_scalar::<_, Uuid>(
        "SELECT congregation_id FROM user_congregations 
         WHERE user_id = $1"
    )
    .bind(user_id)
    .fetch_all(pool)
    .await?;
    
    if user_congregations.is_empty() {
        // Usuário sem congregação atribuída → acesso geral (retrocompat)
        return Ok(requested_congregation_id);
    }
    
    match requested_congregation_id {
        Some(id) => {
            if user_congregations.contains(&id) {
                Ok(Some(id))
            } else {
                Err(AppError::forbidden("Sem acesso a esta congregação"))
            }
        }
        None => {
            // Sem filtro solicitado → força a congregação primária
            let primary = sqlx::query_scalar::<_, Uuid>(
                "SELECT congregation_id FROM user_congregations 
                 WHERE user_id = $1 AND is_primary = true
                 LIMIT 1"
            )
            .bind(user_id)
            .fetch_optional(pool)
            .await?;
            
            Ok(primary.or(user_congregations.first().copied()))
        }
    }
}
```

### 7.3 Frontend — Restrição do Seletor

O `CongregationContextCubit` deve filtrar as congregações disponíveis com base no papel do usuário:

```dart
Future<void> loadCongregations() async {
  try {
    emit(state.copyWith(isLoading: true));
    
    // O backend já retorna apenas as congregações que o usuário pode acessar
    final congregations = await _repository.listCongregations();
    
    // Para admin/pastor: "Todas" disponível
    // Para outros: apenas suas congregações
    final canSeeAll = _authBloc.state is AuthAuthenticated &&
        ['super_admin', 'pastor', 'admin'].contains(
            (_authBloc.state as AuthAuthenticated).user.role);
    
    emit(state.copyWith(
      availableCongregations: congregations,
      canSeeAll: canSeeAll,
      isLoading: false,
      hasLoaded: true,
    ));
    
    // Se não pode ver "Todas" e tem congregação primária, auto-seleciona
    if (!canSeeAll && congregations.isNotEmpty) {
      final primary = congregations.firstWhere(
        (c) => c.isPrimary, 
        orElse: () => congregations.first,
      );
      selectCongregation(primary.id);
    }
  } catch (e) {
    emit(state.copyWith(isLoading: false, error: e.toString()));
  }
}
```

---

## 8. Padrão de Relatórios com Congregação

### 8.1 Todo Relatório Existente Recebe Filtro

```
GET /api/v1/reports/{tipo}?congregation_id={uuid}
```

| Parâmetro | Comportamento |
|-----------|---------------|
| Omitido | Dados consolidados (todas as congregações) |
| `congregation_id=uuid` | Dados apenas daquela congregação |
| `congregation_id=null` (explícito) | Dados sem congregação (Sede/Geral) |

### 8.2 Frontend — Filtro de Congregação nos Relatórios

O relatório geral (`ReportsScreen`) deve exibir os dados da congregação ativa:

```dart
void _loadReportData() {
  final congregationId = context.read<CongregationContextCubit>().activeCongregationId;
  
  // Passa para todos os carregamentos de relatório
  _memberRepo.getStats(congregationId: congregationId);
  _financialRepo.getBalanceReport(congregationId: congregationId);
  _assetRepo.getStats(congregationId: congregationId);
  _ebdRepo.getStats(congregationId: congregationId);
}
```

### 8.3 Relatórios Comparativos (Congregações)

O módulo de congregações oferece relatórios **comparativos** que cruzam dados de todos os módulos:

| Relatório | Endpoint | Módulos Consultados |
|-----------|----------|-------------------|
| Visão Geral | `GET /reports/congregations/overview` | Membros + Financeiro + EBD + Patrimônio |
| Comparativo | `GET /reports/congregations/compare?metric=financial` | O módulo indicado no `metric` |

Estes relatórios são **exclusivos do módulo Congregações** e só aparecem quando ele está ativo.

---

## 9. Checklist de Integração — Por Módulo

### 9.1 Status Atual

Use esta tabela para acompanhar a integração de cada módulo com o padrão:

| # | Tarefa | Membros | Financeiro | Patrimônio | EBD | Ministérios |
|:-:|--------|:-------:|:----------:|:----------:|:---:|:-----------:|
| 1 | `congregation_id` na tabela (DB) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2 | `congregation_id` na Entity (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | `congregation_id` no CreateDTO (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 4 | `congregation_id` no UpdateDTO (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 5 | `congregation_id` no FilterDTO (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 6 | Filtro no Service `list()` (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 7 | Bind no Service `create()` (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 8 | Bind no Service `update()` (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 9 | `congregation_name` via LEFT JOIN (Rust) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 10 | `congregationId` no Model (Flutter) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 11 | `congregationId` no Repository (Flutter) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 12 | BLoC escuta `CongregationContextCubit` | ✅ | ✅ | ✅ | ✅ | ✅ |
| 13 | Dropdown de congregação no Form (Flutter) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 14 | Badge de congregação na lista (Flutter) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 15 | Relatórios filtram por congregação | ✅ | ✅ | ✅ | ✅ | — |
| 16 | Dashboard filtra por congregação | ✅ | ✅ | ✅ | ✅ | — |

> ✅ = Implementado | 🔴 = Pendente

### 9.2 Checklist para Novos Módulos

Ao criar um **novo módulo**, verifique cada item:

- [ ] **DB**: Tabela tem `congregation_id UUID REFERENCES congregations(id) ON DELETE SET NULL`
- [ ] **DB**: Índice `idx_{tabela}_congregation` criado
- [ ] **Rust Entity**: Struct tem `pub congregation_id: Option<Uuid>`
- [ ] **Rust Summary**: Struct de listagem tem `congregation_id` + `congregation_name`
- [ ] **Rust CreateDTO**: Tem `pub congregation_id: Option<Uuid>`
- [ ] **Rust UpdateDTO**: Tem `pub congregation_id: Option<Option<Uuid>>`
- [ ] **Rust FilterDTO**: Tem `pub congregation_id: Option<Uuid>`
- [ ] **Rust Service list()**: Filtra por `congregation_id` quando presente
- [ ] **Rust Service create()**: Faz bind de `congregation_id`
- [ ] **Rust Service update()**: Atualiza `congregation_id` quando presente
- [ ] **Rust Handler**: Endpoints de lista aceitam `congregation_id` como query param
- [ ] **Flutter Model**: Tem `String? congregationId` + `String? congregationName`
- [ ] **Flutter Model toCreateJson()**: Inclui `congregation_id`
- [ ] **Flutter Repository**: Métodos de lista aceitam `congregationId` param
- [ ] **Flutter BLoC**: Recebe `CongregationContextCubit` e escuta mudanças
- [ ] **Flutter Form**: Inclui dropdown de congregação (condicional)
- [ ] **Flutter List**: Exibe badge de congregação quando em visão "Todas"
- [ ] **Flutter Dashboard**: Stats passam `congregationId`
- [ ] **Referências cross-módulo**: Todas as FKs para outros módulos são `NULLABLE` + `ON DELETE SET NULL`

---

## 10. Ordem de Implementação Recomendada

### Fase 1 — Corrigir Membros (prioridade alta)
1. Adicionar `congregation_id` e `congregation_name` na entity `Member` e `MemberSummary` no Rust
2. Incluir `congregation_name` via LEFT JOIN nas queries de listagem
3. Adicionar dropdown de congregação no formulário de Membros (Flutter)
4. Adicionar badge de congregação nos cards de membros

### Fase 2 — Financeiro (prioridade alta)
1. Adicionar `congregation_id` na entity `FinancialEntry` e `FinancialEntrySummary`
2. Adicionar nos DTOs (Create, Update, Filter)
3. Implementar filtro e bind no Service
4. Integrar no Flutter (Model, Repository, BLoC, Form, Lista)

### Fase 3 — Patrimônio (prioridade média)
1. Mesma sequência do Financeiro para `Asset`, `AssetLoan`, `Inventory`

### Fase 4 — EBD (prioridade média)
1. Mesma sequência para `EbdTerm`, `EbdClass`
2. Classes já filtram indiretamente (aluno → congregação do membro), mas a turma precisa do campo direto

### Fase 5 — Ministérios (prioridade baixa)
1. Mesma sequência para `Ministry`

### Fase 6 — Relatórios e Dashboard (prioridade alta — depois de Fases 1-2)
1. Passar `congregationId` em todos os carregamentos do Dashboard
2. Passar `congregationId` em todos os relatórios gerais
3. Garantir que os relatórios comparativos de congregação refletem dados corretos

### Fase 7 — Permissões (prioridade alta)
1. Implementar `resolve_congregation_access()` no backend
2. Chamar em todos os handlers de listagem
3. Restringir seletor no frontend com base no papel do usuário
4. Testar com usuário dirigente (acesso limitado a sua congregação)

### Fase 8 — Feature Flags (prioridade baixa — futuro)
1. Criar tabela `church_modules`
2. Implementar middleware de verificação de módulo ativo
3. Condicionar menus e rotas no frontend

---

## 11. Regras de Integridade Cross-Módulo

### RI-001: Soft Delete Protege Referências
- Ao desativar/excluir (soft) um registro referenciado por outro módulo, o registro original é preservado
- Ex: deletar um membro **não** exclui seus lançamentos financeiros — mantém `member_id` referenciando o membro soft-deleted

### RI-002: Congregação Removida → SET NULL
- Ao desativar uma congregação, todos os registros vinculados (`congregation_id`) ficam NULL
- Isso é garantido pela FK `ON DELETE SET NULL` — mas a desativação é soft delete (`is_active = false`), então os registros mantêm o vínculo
- Apenas se a congregação for fisicamente deletada (o que não deve ocorrer) o SET NULL seria acionado

### RI-003: FKs Cross-Módulo Nunca CASCADE
- Nenhuma FK entre módulos diferentes deve usar `ON DELETE CASCADE`
- Cascade é permitido **apenas** intra-módulo (ex: `inventory_items` → `inventories`)

### RI-004: Texto Alternativo para Módulos Ausentes
- Se um módulo referencia outro que pode estar desabilitado, deve existir um **campo de texto alternativo**:
  - `financial_entries.member_id` (FK) + `financial_entries.payer_name` (texto fallback)
  - `ebd_classes.teacher_id` (FK) + `ebd_classes.teacher_name` (texto fallback)
  - `asset_loans.borrower_member_id` (FK) + `asset_loans.borrower_name` (texto fallback)

> **Nota:** Estes campos de fallback são uma **futura melhoria** para quando o sistema for realmente modular. Atualmente, todos os módulos estão ativos.

### RI-005: Validação Condicional
- Regras de negócio que cruzam módulos devem verificar se o módulo dependente está ativo
- Ex: RN-FIN-002 ("dízimo deve ter member_id") só se aplica se o módulo de Membros está ativo
- Se o módulo de Membros não está ativo, o dízimo pode ser registrado sem `member_id`

---

## 12. Glossário

| Termo | Definição |
|-------|-----------|
| **Módulo** | Conjunto funcional completo (entity + DTO + service + handler + BLoC + UI) |
| **Módulo Core** | Auth, Churches, Users, Roles — sempre ativo, não pode ser desabilitado |
| **Módulo Transversal** | Módulo que adiciona funcionalidade a todos os outros (ex: Congregações) |
| **Dependência Hard** | FK NOT NULL — o registro não existe sem o módulo dependente |
| **Dependência Soft** | FK nullable — o registro funciona sem o módulo dependente |
| **Tenant** | Uma `church` no sistema — isolamento total de dados |
| **Contexto Ativo** | A congregação selecionada no seletor global (pode ser "Todas") |
| **Feature Flag** | Configuração que habilita/desabilita um módulo por tenant |
| **Filtro Transversal** | `congregation_id` como filtro que se aplica a todos os módulos |

---

## 13. Referências

| Documento | Relação |
|-----------|---------|
| [02-arquitetura.md](02-arquitetura.md) | Arquitetura base do sistema |
| [03-banco-de-dados.md](03-banco-de-dados.md) | Schema do banco de dados |
| [04-api-rest.md](04-api-rest.md) | Padrão de endpoints REST |
| [06-regras-de-negocio.md](06-regras-de-negocio.md) | Regras INT-001 a INT-005 (cross-módulo) |
| [10-modulo-congregacoes.md](10-modulo-congregacoes.md) | Especificação do módulo de Congregações |
