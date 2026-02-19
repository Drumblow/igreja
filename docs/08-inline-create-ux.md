# 08 - UX: Criação Inline de Entidades Dependentes

> **Data:** 19/02/2026  
> **Objetivo:** Melhorar a experiência do usuário permitindo criar entidades dependentes sem sair do formulário atual.

---

## 1. Visão Geral

Diversos formulários do sistema exigem a seleção de uma entidade relacionada (categoria, trimestre, turma, conta bancária, etc.). Quando essa entidade ainda não existe, o usuário é obrigado a **sair do formulário**, ir até outra tela, cadastrar a entidade, e depois voltar — perdendo os dados já preenchidos.

**Proposta:** Adicionar um botão "+" (ou "Criar novo...") ao lado de cada campo que referencia outra entidade, abrindo um **mini-dialog inline** para cadastro rápido. Após salvar, o novo item é automaticamente selecionado no dropdown.

---

## 2. Mapeamento Completo dos Campos

### Legenda de Prioridade
- 🔴 **Crítico** — Campo usa UUID manual (TextField), inutilizável para usuário final
- 🟡 **Importante** — Dropdown existe mas sem opção de criação inline
- 🟢 **Desejável** — Campo opcional, melhoria de conveniência

---

### 2.1 Módulo EBD

| # | Tela / Dialog | Arquivo | Campo | Entidade Requerida | Situação Atual | Prioridade |
|---|--------------|---------|-------|--------------------|----------------|------------|
| 1 | Nova Turma | `ebd_class_list_screen.dart` | Trimestre * | **EBD Term** | Dropdown com FutureBuilder. Se vazio, mostra texto de erro | 🟡 Importante |
| 2 | Nova Aula | `ebd_lesson_list_screen.dart` | Turma * | **EBD Class** | Dropdown com FutureBuilder. Se vazio, mostra texto de erro | 🟡 Importante |
| 3 | Registrar Frequência | `ebd_attendance_screen.dart` | ID do Membro * | **Member** | TextField para digitar UUID manualmente | 🔴 Crítico |
| 4 | Matricular Aluno | `ebd_class_detail_screen.dart` | ID do Membro * | **Member** | TextField para digitar UUID manualmente | 🔴 Crítico |

**Ações necessárias:**
- **#1:** Adicionar botão "+" ao lado do dropdown de Trimestre → abre mini-dialog para criar trimestre (nome, datas, tema)
- **#2:** Adicionar botão "+" ao lado do dropdown de Turma → abre mini-dialog para criar turma (que por sua vez precisa de trimestre — ver cadeia abaixo)
- **#3 e #4:** Substituir TextField de UUID por um **dropdown pesquisável** com lista de membros, com busca por nome

---

### 2.2 Módulo Patrimônio

| # | Tela / Dialog | Arquivo | Campo | Entidade Requerida | Situação Atual | Prioridade |
|---|--------------|---------|-------|--------------------|----------------|------------|
| 5 | Novo Bem (Asset) | `asset_form_screen.dart` | Categoria * | **Asset Category** | Dropdown carregado via `_loadCategories()`. Se vazio, dropdown fica sem opções e sem feedback | 🟡 Importante |
| 6 | Novo Empréstimo | `asset_loan_list_screen.dart` | ID do Bem * | **Asset** | TextField para digitar UUID manualmente | 🔴 Crítico |
| 7 | Novo Empréstimo | `asset_loan_list_screen.dart` | ID do Membro * | **Member** | TextField para digitar UUID manualmente | 🔴 Crítico |
| 8 | Nova Manutenção | `maintenance_list_screen.dart` | ID do Bem * | **Asset** | TextField para digitar UUID manualmente | 🔴 Crítico |

**Ações necessárias:**
- **#5:** Adicionar botão "+" ao lado do dropdown de Categoria → abre mini-dialog para criar categoria (nome)
- **#6:** Substituir TextField por dropdown pesquisável de bens (com nome/código patrimonial)
- **#7:** Substituir TextField por dropdown pesquisável de membros
- **#8:** Substituir TextField por dropdown pesquisável de bens

---

### 2.3 Módulo Financeiro

| # | Tela / Dialog | Arquivo | Campo | Entidade Requerida | Situação Atual | Prioridade |
|---|--------------|---------|-------|--------------------|----------------|------------|
| 9 | Novo Lançamento | `financial_entry_form_screen.dart` | Plano de Contas * | **Account Plan** | Dropdown carregado via `_loadOptions()`. Se vazio, sem opções | 🟡 Importante |
| 10 | Novo Lançamento | `financial_entry_form_screen.dart` | Conta Bancária * | **Bank Account** | Dropdown carregado via `_loadOptions()`. Se vazio, sem opções | 🟡 Importante |
| 11 | Novo Lançamento | `financial_entry_form_screen.dart` | Campanha | **Campaign** | Dropdown opcional. Mostra "Nenhuma" se vazio | 🟢 Desejável |

**Ações necessárias:**
- **#9:** Adicionar botão "+" ao lado do dropdown de Plano de Contas → abre mini-dialog (código, nome, tipo receita/despesa)
- **#10:** Adicionar botão "+" ao lado do dropdown de Conta Bancária → abre mini-dialog (nome, banco, agência, conta)
- **#11:** Adicionar botão "+" ao lado do dropdown de Campanha → abre mini-dialog (nome, datas, meta)

---

### 2.4 Módulos sem dependências (Membros, Famílias, Ministérios)

| Módulo | Formulário | Dependências Externas |
|--------|-----------|----------------------|
| Membros | `member_form_screen.dart` | Nenhuma — todos os campos são autônomos (texto, datas, enums) |
| Famílias | `family_form_screen.dart` | Nenhuma — nome, endereço, notas. Membros adicionados na tela de detalhe |
| Ministérios | `ministry_form_screen.dart` | Nenhuma — nome, descrição, ativo. Membros adicionados na tela de detalhe |

✅ Esses módulos não precisam de alteração.

---

## 3. Padrão de Implementação Proposto

### 3.1 Componente Reutilizável: `InlineCreateDropdown`

Criar um widget genérico que encapsula o padrão:

```
┌─────────────────────────────────────────┐
│  Categoria *                        [+] │
│  ┌───────────────────────────────┐      │
│  │  ▼ Selecione...               │      │
│  └───────────────────────────────┘      │
└─────────────────────────────────────────┘
```

**Props do widget:**
```dart
class InlineCreateDropdown<T> extends StatefulWidget {
  final String label;
  final bool required;
  final Future<List<T>> Function() loadItems;
  final String Function(T) displayName;
  final String Function(T) getValue;
  final Widget Function(BuildContext, Function(T)) inlineCreateBuilder;
  final ValueChanged<String?> onChanged;
  final String? initialValue;
}
```

**Comportamento:**
1. Carrega itens via `loadItems()`
2. Mostra dropdown com os itens
3. Botão "+" à direita abre um `showDialog` com o formulário de criação inline
4. Após criar, recarrega a lista e auto-seleciona o novo item
5. Se a lista estiver vazia, mostra mensagem + botão de criação destacado

---

### 3.2 Componente Reutilizável: `SearchableEntityDropdown`

Para campos que referenciam **Membros** ou **Bens** (entidades com muitos registros), usar um dropdown pesquisável:

```
┌─────────────────────────────────────────┐
│  Membro *                               │
│  ┌───────────────────────────────┐      │
│  │  🔍 Buscar por nome...        │      │
│  │  ─────────────────────────────│      │
│  │  João da Silva                 │      │
│  │  Maria dos Santos              │      │
│  │  Pedro Oliveira                │      │
│  └───────────────────────────────┘      │
└─────────────────────────────────────────┘
```

**Props do widget:**
```dart
class SearchableEntityDropdown extends StatefulWidget {
  final String label;
  final bool required;
  final Future<List<Map<String, dynamic>>> Function(String query) searchFn;
  final String displayField; // ex: 'full_name'
  final String valueField;   // ex: 'id'
  final ValueChanged<String?> onChanged;
  final String? initialValue;
}
```

**Comportamento:**
1. Campo de texto com ícone de busca
2. Ao digitar (debounce 300ms), chama a API de busca
3. Mostra resultados em lista dropdown
4. Ao selecionar, preenche o campo com o nome e armazena o ID

---

## 4. Ordem de Implementação Sugerida

### Fase 1 — Componentes Base (Prioridade Máxima)
| Tarefa | Estimativa |
|--------|-----------|
| Criar widget `InlineCreateDropdown<T>` | 2h |
| Criar widget `SearchableEntityDropdown` | 2h |
| Criar endpoint de busca de membros (`GET /v1/members?search=...` — já existe) | — |
| Criar endpoint de busca de bens (`GET /v1/assets?search=...` — verificar) | 30min |

### Fase 2 — Campos Críticos 🔴 (UUID → Dropdown Pesquisável)
| # | Tela | Campo | Substituir por |
|---|------|-------|---------------|
| 3 | EBD Frequência | ID do Membro | `SearchableEntityDropdown` (membros) |
| 4 | EBD Matrícula | ID do Membro | `SearchableEntityDropdown` (membros) |
| 6 | Empréstimo Patrimônio | ID do Bem | `SearchableEntityDropdown` (bens) |
| 7 | Empréstimo Patrimônio | ID do Membro | `SearchableEntityDropdown` (membros) |
| 8 | Manutenção | ID do Bem | `SearchableEntityDropdown` (bens) |

**Estimativa:** ~4h (5 substituições usando o componente pronto)

### Fase 3 — Dropdowns com Criação Inline 🟡
| # | Tela | Campo | Mini-dialog a criar |
|---|------|-------|-------------------|
| 1 | EBD Nova Turma | Trimestre | Criar Trimestre (nome, data início, data fim) |
| 2 | EBD Nova Aula | Turma | Criar Turma (nome, trimestre com cascata) |
| 5 | Novo Bem | Categoria | Criar Categoria (nome) |
| 9 | Novo Lançamento | Plano de Contas | Criar Plano (código, nome, tipo) |
| 10 | Novo Lançamento | Conta Bancária | Criar Conta (nome, banco, agência, conta) |

**Estimativa:** ~5h (5 mini-dialogs + integração com `InlineCreateDropdown`)

### Fase 4 — Melhorias de Conveniência 🟢
| # | Tela | Campo | Mini-dialog a criar |
|---|------|-------|-------------------|
| 11 | Novo Lançamento | Campanha | Criar Campanha (nome, datas, meta) |

**Estimativa:** ~1h

---

## 5. Dependências em Cascata

Alguns formulários têm dependências encadeadas que precisam ser tratadas:

```
Aula EBD
 └── requer Turma EBD
      └── requer Trimestre EBD
           └── (autônomo ✅)

Empréstimo Patrimônio
 └── requer Bem (Asset)
      └── requer Categoria (Asset Category)
           └── (autônomo ✅)
 └── requer Membro
      └── (autônomo ✅)

Lançamento Financeiro
 └── requer Plano de Contas (autônomo ✅)
 └── requer Conta Bancária (autônomo ✅)
 └── requer Campanha (opcional, autônomo ✅)
```

**Regra:** Quando o mini-dialog de criação inline **também** depende de outra entidade, permitir criação inline recursiva (no máximo 2 níveis para não complicar a UX).

---

## 6. Status da Implementação

> **Atualizado em:** 19/02/2026

| Fase | Item | Status |
|------|------|--------|
| **Base** | Widget `SearchableEntityDropdown` | ✅ Implementado (`core/widgets/searchable_entity_dropdown.dart`) |
| **Base** | Widget `InlineCreateDropdown<T>` | ✅ Implementado (`core/widgets/inline_create_dropdown.dart`) |
| **Fase 2** | #3 EBD Frequência → member dropdown | ✅ Implementado |
| **Fase 2** | #4 EBD Matrícula → member dropdown | ✅ Implementado |
| **Fase 2** | #6 Empréstimo → asset dropdown | ✅ Implementado |
| **Fase 2** | #7 Empréstimo → member dropdown | ✅ Implementado |
| **Fase 2** | #8 Manutenção → asset dropdown | ✅ Implementado |
| **Fase 3** | #5 Novo Bem → "+" criar categoria | ✅ Implementado |
| **Fase 3** | #9 Lançamento → "+" criar plano de contas | ✅ Implementado |
| **Fase 3** | #10 Lançamento → "+" criar conta bancária | ✅ Implementado |
| **Fase 4** | #11 Lançamento → "+" criar campanha | ✅ Implementado |
| **Fase 3** | #1 EBD Nova Turma → "+" criar trimestre | ✅ Implementado |
| **Fase 3** | #2 EBD Nova Aula → "+" ir para turmas | ✅ Implementado |

---

## 7. Resumo Executivo

| Métrica | Valor |
|---------|-------|
| Total de campos com dependência externa | **11** |
| Campos com UUID manual (inutilizáveis) 🔴 | **5** |
| Dropdowns sem criação inline 🟡 | **5** |
| Campos opcionais sem criação inline 🟢 | **1** |
| Componentes reutilizáveis a criar | **2** (`InlineCreateDropdown`, `SearchableEntityDropdown`) |
| Estimativa total de implementação | **~14h** |
| Módulos afetados | **3** (EBD, Patrimônio, Financeiro) |
| Módulos sem alteração necessária | **3** (Membros, Famílias, Ministérios) |
