# 🔌 API REST — Igreja Manager

## 1. Informações Gerais

| Item | Valor |
|------|-------|
| **Base URL** | `https://api.igrejamanager.com/api/v1` |
| **Formato** | JSON |
| **Autenticação** | Bearer Token (JWT) |
| **Content-Type** | `application/json` |
| **Versionamento** | Via URL (`/api/v1/...`) |
| **Documentação Interativa** | Swagger UI em `/swagger-ui/` |

---

## 2. Autenticação

Todas as rotas (exceto login, registro e health check) requerem o header:

```
Authorization: Bearer <access_token>
```

### Headers Obrigatórios

| Header | Descrição |
|--------|-----------|
| `Authorization` | `Bearer <jwt_token>` |
| `Content-Type` | `application/json` |
| `X-Church-Id` | UUID da igreja (inferido do token, mas pode ser explícito para super admins) |

---

## 3. Padrões de Resposta

### Sucesso (com dados)

```json
{
  "success": true,
  "data": { ... },
  "message": "Operação realizada com sucesso"
}
```

### Sucesso (listagem paginada)

```json
{
  "success": true,
  "data": [ ... ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

### Erro

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dados inválidos",
    "details": [
      { "field": "email", "message": "E-mail inválido" },
      { "field": "phone_primary", "message": "Campo obrigatório" }
    ]
  }
}
```

### Códigos de Erro Padrão

| Código | HTTP Status | Descrição |
|--------|-------------|-----------|
| `VALIDATION_ERROR` | 400 | Dados de entrada inválidos |
| `UNAUTHORIZED` | 401 | Token ausente ou inválido |
| `FORBIDDEN` | 403 | Sem permissão para a ação |
| `NOT_FOUND` | 404 | Recurso não encontrado |
| `CONFLICT` | 409 | Conflito (ex: e-mail já cadastrado) |
| `RATE_LIMITED` | 429 | Muitas requisições |
| `INTERNAL_ERROR` | 500 | Erro interno do servidor |

---

## 4. Parâmetros de Paginação e Ordenação

Disponíveis em todos os endpoints de listagem:

| Parâmetro | Tipo | Default | Descrição |
|-----------|------|---------|-----------|
| `page` | int | 1 | Número da página |
| `per_page` | int | 20 | Itens por página (máx: 100) |
| `sort_by` | string | `created_at` | Campo para ordenação |
| `sort_order` | string | `desc` | `asc` ou `desc` |
| `search` | string | — | Busca textual geral |

---

## 5. Endpoints

### 5.1 Autenticação (`/auth`)

#### `POST /auth/login`
Autenticar usuário e obter tokens.

**Permissão:** Pública

**Request:**
```json
{
  "email": "admin@igreja.com",
  "password": "minhasenha123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": {
      "id": "uuid",
      "email": "admin@igreja.com",
      "role": "pastor",
      "church_id": "uuid",
      "church_name": "Igreja Exemplo"
    }
  }
}
```

---

#### `POST /auth/refresh`
Renovar access token usando refresh token.

**Permissão:** Pública (com refresh token válido)

**Request:**
```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_in": 900
  }
}
```

---

#### `POST /auth/logout`
Revogar refresh token.

**Permissão:** Autenticado

**Request:**
```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logout realizado com sucesso"
}
```

---

#### `POST /auth/forgot-password`
Solicitar reset de senha.

**Permissão:** Pública

**Request:**
```json
{
  "email": "admin@igreja.com"
}
```

**Response (200):** (sempre retorna sucesso por segurança)
```json
{
  "success": true,
  "message": "Se o e-mail existir, um link de recuperação será enviado"
}
```

---

#### `POST /auth/reset-password`
Resetar senha com token recebido por e-mail.

**Permissão:** Pública (com token válido)

**Request:**
```json
{
  "token": "reset_token_received_by_email",
  "new_password": "novaSenha123!",
  "confirm_password": "novaSenha123!"
}
```

---

#### `GET /auth/me`
Obter dados do usuário autenticado.

**Permissão:** Autenticado

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "admin@igreja.com",
    "role": {
      "name": "pastor",
      "display_name": "Pastor/Líder",
      "permissions": ["members:*", "financial:read", "..."]
    },
    "church": {
      "id": "uuid",
      "name": "Igreja Exemplo"
    },
    "member": {
      "id": "uuid",
      "full_name": "João Silva"
    },
    "last_login_at": "2026-02-18T10:30:00Z"
  }
}
```

---

### 5.2 Membros (`/members`)

#### `GET /members`
Listar membros com filtros e paginação.

**Permissão:** `members:read`

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `status` | string | Filtrar por status (`ativo`, `inativo`, etc.) |
| `gender` | string | Filtrar por sexo |
| `marital_status` | string | Filtrar por estado civil |
| `role_position` | string | Filtrar por cargo |
| `ministry_id` | UUID | Filtrar por ministério |
| `birth_month` | int | Aniversariantes do mês (1-12) |
| `age_min` | int | Idade mínima |
| `age_max` | int | Idade máxima |
| `neighborhood` | string | Filtrar por bairro |
| `entry_date_from` | date | Data de ingresso a partir de |
| `entry_date_to` | date | Data de ingresso até |

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "full_name": "Maria Silva Santos",
      "birth_date": "1990-05-15",
      "gender": "feminino",
      "phone_primary": "(11) 99999-8888",
      "email": "maria@email.com",
      "status": "ativo",
      "role_position": "membro",
      "photo_url": "https://...",
      "entry_date": "2020-03-10",
      "created_at": "2024-01-15T10:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 350,
    "total_pages": 18
  }
}
```

---

#### `GET /members/:id`
Obter detalhes completos de um membro.

**Permissão:** `members:read`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "full_name": "Maria Silva Santos",
    "social_name": null,
    "birth_date": "1990-05-15",
    "gender": "feminino",
    "marital_status": "casado",
    "cpf": "123.456.789-00",
    "rg": "12.345.678-9",
    "email": "maria@email.com",
    "phone_primary": "(11) 99999-8888",
    "phone_secondary": null,
    "photo_url": "https://...",
    
    "address": {
      "zip_code": "01234-567",
      "street": "Rua das Flores",
      "number": "123",
      "complement": "Apto 45",
      "neighborhood": "Centro",
      "city": "São Paulo",
      "state": "SP"
    },
    
    "profession": "Professora",
    "workplace": "Escola Municipal",
    "education_level": "superior_completo",
    "blood_type": "O+",
    
    "ecclesiastical": {
      "conversion_date": "2010-06-20",
      "water_baptism_date": "2010-12-15",
      "spirit_baptism_date": "2011-03-10",
      "origin_church": null,
      "entry_date": "2010-12-15",
      "entry_type": "batismo",
      "role_position": "membro",
      "ordination_date": null
    },
    
    "status": "ativo",
    "family": {
      "id": "uuid",
      "name": "Família Santos",
      "relationship": "conjuge"
    },
    "ministries": [
      {
        "id": "uuid",
        "name": "Louvor",
        "role_in_ministry": "membro",
        "joined_at": "2015-01-01"
      }
    ],
    
    "notes": "Observações...",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2026-02-01T14:30:00Z"
  }
}
```

---

#### `POST /members`
Cadastrar novo membro.

**Permissão:** `members:write`

**Request:**
```json
{
  "full_name": "João Pedro Oliveira",
  "birth_date": "1985-08-22",
  "gender": "masculino",
  "marital_status": "casado",
  "phone_primary": "(11) 98765-4321",
  "email": "joao@email.com",
  
  "address": {
    "zip_code": "01234-567",
    "street": "Rua das Flores",
    "number": "456",
    "neighborhood": "Centro",
    "city": "São Paulo",
    "state": "SP"
  },
  
  "entry_date": "2026-02-18",
  "entry_type": "transferencia",
  "origin_church": "Igreja Origem",
  "role_position": "membro",
  "status": "ativo"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": { "id": "uuid", "...": "..." },
  "message": "Membro cadastrado com sucesso"
}
```

---

#### `PUT /members/:id`
Atualizar dados de um membro.

**Permissão:** `members:write`

**Request:** Mesma estrutura do POST (campos opcionais são atualizados apenas se enviados)

**Response (200):**
```json
{
  "success": true,
  "data": { "...": "..." },
  "message": "Membro atualizado com sucesso"
}
```

---

#### `DELETE /members/:id`
Excluir membro (soft delete).

**Permissão:** `members:delete`

**Response (200):**
```json
{
  "success": true,
  "message": "Membro removido com sucesso"
}
```

---

#### `GET /members/:id/history`
Obter histórico de eventos do membro.

**Permissão:** `members:read`

---

#### `POST /members/:id/history`
Registrar evento no histórico do membro.

**Permissão:** `members:write`

**Request:**
```json
{
  "event_type": "mudanca_cargo",
  "event_date": "2026-02-18",
  "description": "Consagrado a diácono",
  "previous_value": "cooperador",
  "new_value": "diacono"
}
```

---

#### `GET /members/birthdays`
Listar aniversariantes.

**Permissão:** `members:read`

**Query Parameters:**

| Parâmetro | Tipo | Default | Descrição |
|-----------|------|---------|-----------|
| `month` | int | mês atual | Mês (1-12) |
| `week` | bool | false | Apenas da semana atual |

---

#### `GET /members/statistics`
Obter estatísticas demográficas dos membros.

**Permissão:** `members:read`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_active": 350,
    "total_inactive": 25,
    "by_gender": { "masculino": 160, "feminino": 190 },
    "by_marital_status": { "solteiro": 120, "casado": 180, "...": "..." },
    "by_role_position": { "pastor": 1, "presbitero": 3, "diacono": 8, "...": "..." },
    "by_age_range": {
      "0-12": 45, "13-17": 30, "18-25": 55,
      "26-35": 80, "36-50": 85, "51+": 55
    },
    "new_members_this_month": 5,
    "new_members_this_year": 42
  }
}
```

---

### 5.3 Famílias (`/families`)

#### `GET /families`
Listar famílias.

**Permissão:** `members:read`

#### `POST /families`
Criar família.

**Permissão:** `members:write`

**Request:**
```json
{
  "name": "Família Oliveira",
  "head_id": "member_uuid",
  "address": { "...": "..." },
  "members": [
    { "member_id": "uuid", "relationship": "chefe" },
    { "member_id": "uuid", "relationship": "conjuge" },
    { "member_id": "uuid", "relationship": "filho" }
  ]
}
```

#### `GET /families/:id`
Detalhes da família com todos os membros.

#### `PUT /families/:id`
Atualizar família.

#### `POST /families/:id/members`
Adicionar membro à família.

#### `DELETE /families/:id/members/:member_id`
Remover membro da família.

---

### 5.4 Ministérios (`/ministries`)

#### `GET /ministries` — Listar ministérios
#### `POST /ministries` — Criar ministério
#### `PUT /ministries/:id` — Atualizar ministério
#### `DELETE /ministries/:id` — Excluir ministério
#### `GET /ministries/:id/members` — Listar membros do ministério
#### `POST /ministries/:id/members` — Adicionar membro ao ministério
#### `DELETE /ministries/:id/members/:member_id` — Remover membro do ministério

---

### 5.5 Financeiro (`/financial`)

#### `GET /financial/entries`
Listar lançamentos financeiros.

**Permissão:** `financial:read`

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `type` | string | `receita` ou `despesa` |
| `account_plan_id` | UUID | Filtrar por categoria |
| `bank_account_id` | UUID | Filtrar por conta |
| `status` | string | `pendente`, `confirmado`, `cancelado` |
| `date_from` | date | Data início |
| `date_to` | date | Data fim |
| `member_id` | UUID | Filtrar por membro (dízimos) |
| `campaign_id` | UUID | Filtrar por campanha |
| `payment_method` | string | Filtrar por forma de pagamento |

---

#### `POST /financial/entries`
Criar lançamento financeiro.

**Permissão:** `financial:write`

**Request:**
```json
{
  "type": "receita",
  "account_plan_id": "uuid",
  "bank_account_id": "uuid",
  "amount": 500.00,
  "entry_date": "2026-02-18",
  "payment_date": "2026-02-18",
  "description": "Dízimo - João Oliveira",
  "payment_method": "pix",
  "member_id": "uuid",
  "status": "confirmado"
}
```

---

#### `GET /financial/entries/:id`
Detalhes do lançamento.

#### `PUT /financial/entries/:id`
Atualizar lançamento (somente se não estiver fechado).

#### `DELETE /financial/entries/:id`
Cancelar/estornar lançamento.

---

#### `GET /financial/account-plans`
Listar plano de contas.

#### `POST /financial/account-plans`
Criar categoria no plano de contas.

#### `PUT /financial/account-plans/:id`
Atualizar categoria.

---

#### `GET /financial/bank-accounts`
Listar contas bancárias e saldos.

#### `POST /financial/bank-accounts`
Criar conta bancária.

#### `PUT /financial/bank-accounts/:id`
Atualizar conta bancária.

---

#### `GET /financial/tithes`
Listar dízimos com detalhes.

**Permissão:** `financial:tithes` (acesso restrito)

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `member_id` | UUID | Dízimos de um membro específico |
| `date_from` | date | Data início |
| `date_to` | date | Data fim |

---

#### `GET /financial/tithes/members/:member_id/statement`
Declaração anual de dízimos de um membro (PDF).

**Permissão:** `financial:tithes`

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `year` | int | Ano da declaração |

**Response:** `application/pdf`

---

#### `GET /financial/campaigns`
Listar campanhas.

#### `POST /financial/campaigns`
Criar campanha.

#### `PUT /financial/campaigns/:id`
Atualizar campanha.

#### `GET /financial/campaigns/:id`
Detalhes da campanha com progresso.

---

#### `POST /financial/monthly-closing`
Realizar fechamento mensal.

**Permissão:** `financial:close`

**Request:**
```json
{
  "reference_month": "2026-02-01",
  "notes": "Fechamento do mês de fevereiro"
}
```

---

#### `GET /financial/reports/balance`
Balancete do período.

**Permissão:** `financial:read`

**Query Parameters:** `date_from`, `date_to`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-02-01", "to": "2026-02-28" },
    "previous_balance": 15000.00,
    "total_income": 25000.00,
    "total_expense": 18000.00,
    "balance": 7000.00,
    "accumulated_balance": 22000.00,
    "income_by_category": [
      { "category": "Dízimos", "amount": 18000.00, "percentage": 72 },
      { "category": "Ofertas", "amount": 5000.00, "percentage": 20 },
      { "category": "Outras Receitas", "amount": 2000.00, "percentage": 8 }
    ],
    "expense_by_category": [
      { "category": "Pessoal", "amount": 8000.00, "percentage": 44 },
      { "category": "Infraestrutura", "amount": 5000.00, "percentage": 28 },
      { "...": "..." }
    ]
  }
}
```

---

#### `GET /financial/reports/cash-flow`
Fluxo de caixa.

**Query Parameters:** `date_from`, `date_to`, `group_by` (`day`, `week`, `month`)

---

### 5.6 Patrimônio (`/assets`)

#### `GET /assets`
Listar bens patrimoniais.

**Permissão:** `assets:read`

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `category_id` | UUID | Filtrar por categoria |
| `status` | string | `ativo`, `em_manutencao`, `baixado`, etc. |
| `condition` | string | `novo`, `bom`, `regular`, `ruim` |
| `location` | string | Filtrar por localização |

---

#### `POST /assets`
Cadastrar bem patrimonial.

**Permissão:** `assets:write`

**Request:**
```json
{
  "category_id": "uuid",
  "description": "Mesa de Som Behringer X32",
  "brand": "Behringer",
  "model": "X32",
  "serial_number": "SN123456",
  "acquisition_date": "2025-06-15",
  "acquisition_value": 12000.00,
  "acquisition_type": "compra",
  "location": "Salão Principal - Sonoplastia",
  "condition": "novo",
  "notes": "Adquirida para o novo templo"
}
```

---

#### `GET /assets/:id`
Detalhes do bem com fotos e histórico de manutenções.

#### `PUT /assets/:id`
Atualizar bem.

#### `DELETE /assets/:id`
Baixar bem (soft delete com registro do motivo).

---

#### `POST /assets/:id/photos`
Upload de fotos do bem.

**Content-Type:** `multipart/form-data`

#### `DELETE /assets/:id/photos/:photo_id`
Remover foto.

---

#### `GET /assets/categories`
Listar categorias de bens.

#### `POST /assets/categories`
Criar categoria.

---

#### `GET /assets/maintenances`
Listar manutenções.

#### `POST /assets/maintenances`
Registrar manutenção.

#### `PUT /assets/maintenances/:id`
Atualizar manutenção.

---

#### `POST /assets/inventories`
Criar inventário.

#### `GET /assets/inventories/:id`
Detalhes do inventário com checklist.

#### `PUT /assets/inventories/:id/items/:item_id`
Atualizar item do inventário (conferência).

#### `POST /assets/inventories/:id/close`
Finalizar inventário.

---

#### `GET /assets/loans`
Listar empréstimos.

#### `POST /assets/loans`
Registrar empréstimo.

#### `PUT /assets/loans/:id/return`
Registrar devolução.

---

### 5.7 EBD (`/ebd`)

#### `GET /ebd/terms`
Listar períodos/trimestres.

#### `POST /ebd/terms`
Criar período.

#### `PUT /ebd/terms/:id`
Atualizar período.

---

#### `GET /ebd/classes`
Listar turmas.

**Permissão:** `ebd:read`

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `term_id` | UUID | Filtrar por trimestre |
| `is_active` | bool | Apenas turmas ativas |
| `teacher_id` | UUID | Turmas de um professor |

---

#### `POST /ebd/classes`
Criar turma.

**Permissão:** `ebd:write`

**Request:**
```json
{
  "term_id": "uuid",
  "name": "Jovens e Adolescentes",
  "age_range_start": 13,
  "age_range_end": 25,
  "room": "Sala 3",
  "max_capacity": 30,
  "teacher_id": "member_uuid",
  "aux_teacher_id": "member_uuid"
}
```

---

#### `GET /ebd/classes/:id`
Detalhes da turma com alunos matriculados.

#### `PUT /ebd/classes/:id`
Atualizar turma.

---

#### `POST /ebd/classes/:id/enrollments`
Matricular aluno na turma.

**Request:**
```json
{
  "member_id": "uuid"
}
```

#### `DELETE /ebd/classes/:id/enrollments/:enrollment_id`
Cancelar matrícula.

#### `GET /ebd/classes/:id/enrollments`
Listar alunos matriculados na turma.

---

#### `POST /ebd/lessons`
Registrar aula/lição.

**Permissão:** `ebd:write` ou `ebd:attendance`

**Request:**
```json
{
  "class_id": "uuid",
  "lesson_date": "2026-02-15",
  "lesson_number": 7,
  "title": "A Oração do Justo",
  "bible_text": "Tiago 5:13-20",
  "summary": "Estudo sobre o poder da oração...",
  "teacher_id": "member_uuid"
}
```

---

#### `GET /ebd/lessons`
Listar aulas.

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `class_id` | UUID | Filtrar por turma |
| `date_from` | date | Data início |
| `date_to` | date | Data fim |

---

#### `POST /ebd/lessons/:lesson_id/attendance`
Registrar chamada (frequência) da aula.

**Permissão:** `ebd:attendance`

**Request:**
```json
{
  "attendances": [
    {
      "member_id": "uuid",
      "status": "presente",
      "brought_bible": true,
      "brought_magazine": true,
      "offering_amount": 5.00
    },
    {
      "member_id": "uuid",
      "status": "ausente",
      "brought_bible": false,
      "brought_magazine": false,
      "offering_amount": 0
    },
    {
      "is_visitor": true,
      "visitor_name": "Carlos Visitante",
      "status": "presente",
      "brought_bible": false,
      "brought_magazine": false,
      "offering_amount": 2.00
    }
  ]
}
```

---

#### `GET /ebd/lessons/:lesson_id/attendance`
Obter chamada de uma aula.

---

#### `GET /ebd/reports/attendance`
Relatório de frequência.

**Query Parameters:**

| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `class_id` | UUID | Filtrar por turma |
| `term_id` | UUID | Filtrar por trimestre |
| `date_from` | date | Data início |
| `date_to` | date | Data fim |

**Response (200):**
```json
{
  "success": true,
  "data": {
    "period": { "from": "2026-01-01", "to": "2026-03-31" },
    "summary": {
      "total_classes": 8,
      "total_lessons": 96,
      "average_attendance": 245,
      "total_bibles": 180,
      "total_magazines": 160,
      "total_offerings": 1250.00
    },
    "by_class": [
      {
        "class_id": "uuid",
        "class_name": "Adultos",
        "teacher": "Prof. Maria",
        "enrolled": 35,
        "avg_present": 28,
        "attendance_rate": 80.0,
        "total_offering": 450.00
      }
    ]
  }
}
```

---

### 5.8 Dashboard (`/dashboard`)

#### `GET /dashboard`
Obter indicadores do dashboard.

**Permissão:** Autenticado (dados filtrados pela role)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "members": {
      "total_active": 350,
      "new_this_month": 5,
      "birthdays_this_week": [
        { "id": "uuid", "name": "João Silva", "birth_date": "1990-02-20" }
      ]
    },
    "financial": {
      "current_balance": 22000.00,
      "income_this_month": 25000.00,
      "expense_this_month": 18000.00,
      "pending_expenses": 3,
      "pending_amount": 5000.00
    },
    "ebd": {
      "last_sunday_attendance": 245,
      "average_attendance_month": 238,
      "active_classes": 8
    },
    "assets": {
      "total_active": 156,
      "pending_maintenances": 2,
      "overdue_loans": 1
    },
    "alerts": [
      {
        "type": "expense_due",
        "message": "Conta de energia vence em 3 dias",
        "severity": "warning"
      },
      {
        "type": "maintenance_scheduled",
        "message": "Manutenção do ar-condicionado agendada para amanhã",
        "severity": "info"
      }
    ]
  }
}
```

---

### 5.9 Relatórios (`/reports`)

#### `GET /reports/members`
Relatório de membros (PDF/CSV).

**Query Parameters:** mesmos filtros de `/members` + `format` (`pdf`, `csv`, `xlsx`)

#### `GET /reports/financial/balance`
Balancete para prestação de contas (PDF).

#### `GET /reports/financial/tithes/:member_id`
Declaração de dízimos do membro (PDF).

#### `GET /reports/ebd/quarterly`
Relatório trimestral da EBD (PDF).

#### `GET /reports/assets/inventory`
Inventário geral de patrimônio (PDF).

---

### 5.10 Configurações (`/settings`)

#### `GET /settings/church`
Obter configurações da igreja.

#### `PUT /settings/church`
Atualizar configurações da igreja.

#### `GET /settings/users`
Listar usuários do sistema.

#### `POST /settings/users`
Criar usuário.

#### `PUT /settings/users/:id`
Atualizar usuário.

#### `DELETE /settings/users/:id`
Desativar usuário.

#### `GET /settings/audit-logs`
Consultar logs de auditoria.

---

### 5.11 Health Check

#### `GET /health`
Verificar saúde do sistema.

**Permissão:** Pública

**Response (200):**
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "uptime_seconds": 86400,
  "checks": {
    "database": "ok",
    "redis": "ok"
  }
}
```

---

## 6. Rate Limiting

| Tipo | Limite |
|------|--------|
| Global | 100 requisições/minuto por IP |
| Login | 5 tentativas/minuto por IP |
| Upload de arquivos | 10 por minuto |
| Relatórios (PDF) | 5 por minuto |

Headers de resposta:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1708300000
```

---

## 7. Upload de Arquivos

**Endpoint genérico:** `POST /uploads`

**Content-Type:** `multipart/form-data`

**Restrições:**
- Tamanho máximo: 10 MB
- Tipos aceitos: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`

**Response:**
```json
{
  "success": true,
  "data": {
    "url": "https://storage.igrejamanager.com/uploads/church_uuid/abc123.jpg",
    "filename": "abc123.jpg",
    "size": 245000,
    "content_type": "image/jpeg"
  }
}
```

---

*Documentação da API — referência completa para implementação do backend e consumo pelo frontend.*
