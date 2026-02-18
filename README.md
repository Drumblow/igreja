# 🏛️ Igreja Manager — Sistema de Gestão para Igrejas

## Visão Geral

O **Igreja Manager** é um sistema completo de gestão eclesiástica, projetado para atender as necessidades administrativas de igrejas de todos os portes. O sistema oferece módulos integrados para cadastro de membros, controle financeiro, gestão de patrimônio e gerenciamento da Escola Bíblica Dominical (EBD).

## Stack Tecnológica

| Camada       | Tecnologia     | Versão Mínima |
|--------------|----------------|---------------|
| **Backend**  | Rust (Actix-Web) | 1.75+       |
| **Banco de Dados** | PostgreSQL | 15+        |
| **Frontend** | Flutter (Dart) | 3.19+        |
| **Plataformas** | Web, Android, iOS | —       |

## Módulos Principais

### 1. 👥 Cadastro de Membros
- Registro completo de membros e visitantes
- Histórico de participação e frequência
- Gestão de famílias e grupos familiares
- Controle de cargos e ministérios
- Registro de batismos, transferências e desligamentos

### 2. 💰 Controle Financeiro
- Registro de dízimos e ofertas
- Gestão de receitas e despesas
- Plano de contas personalizado
- Relatórios financeiros (mensal, trimestral, anual)
- Controle de campanhas e projetos específicos
- Prestação de contas transparente

### 3. 🏗️ Gestão de Patrimônio
- Cadastro de bens móveis e imóveis
- Controle de depreciação
- Registro de manutenções e reparos
- Inventário detalhado
- Controle de empréstimo de equipamentos
- Documentação e fotos dos ativos

### 4. 📖 Escola Bíblica Dominical (EBD)
- Cadastro de turmas e professores
- Controle de frequência por aula
- Registro de lições e conteúdos
- Relatórios de presença e desempenho
- Gestão de materiais didáticos
- Calendário de aulas

## Estrutura do Projeto

```
igreja/
├── docs/                        # Documentação completa
│   ├── 01-requisitos-funcionais.md
│   ├── 02-arquitetura.md
│   ├── 03-banco-de-dados.md
│   ├── 04-api-rest.md
│   ├── 05-frontend-flutter.md
│   └── 06-regras-de-negocio.md
├── backend/                     # API REST em Rust
│   ├── src/
│   │   ├── main.rs
│   │   ├── config/
│   │   ├── models/
│   │   ├── handlers/
│   │   ├── services/
│   │   ├── repositories/
│   │   ├── middleware/
│   │   └── errors/
│   ├── migrations/
│   ├── Cargo.toml
│   └── .env.example
├── frontend/                    # App Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   ├── features/
│   │   ├── shared/
│   │   └── routes/
│   ├── pubspec.yaml
│   └── test/
├── database/                    # Scripts SQL
│   ├── init.sql
│   └── seeds/
├── docker-compose.yml
├── README.md
└── SKILL.md
```

## Requisitos para Desenvolvimento

### Backend (Rust)
- Rust 1.75+ com Cargo
- PostgreSQL 15+
- Docker (opcional, para ambiente local)

### Frontend (Flutter)
- Flutter SDK 3.19+
- Dart SDK 3.3+
- Android Studio ou VS Code com extensões Flutter
- Xcode (para builds iOS, apenas macOS)

## Como Executar

### 1. Banco de Dados
```bash
# Com Docker
docker-compose up -d postgres

# Ou instalar PostgreSQL localmente e criar o banco
createdb igreja_manager
```

### 2. Backend
```bash
cd backend
cp .env.example .env
# Editar .env com as credenciais do banco
cargo run
```

### 3. Frontend
```bash
cd frontend
flutter pub get
flutter run           # Mobile
flutter run -d chrome # Web
```

## Documentação

Toda a documentação detalhada está na pasta [`docs/`](docs/):

| Documento | Descrição |
|-----------|-----------|
| [Requisitos Funcionais](docs/01-requisitos-funcionais.md) | Detalhamento de todos os requisitos por módulo |
| [Arquitetura](docs/02-arquitetura.md) | Arquitetura do sistema, padrões e decisões técnicas |
| [Banco de Dados](docs/03-banco-de-dados.md) | Modelagem, schemas e migrações |
| [API REST](docs/04-api-rest.md) | Endpoints, autenticação e contratos |
| [Frontend Flutter](docs/05-frontend-flutter.md) | Estrutura, componentes e fluxos de tela |
| [Regras de Negócio](docs/06-regras-de-negocio.md) | Regras, validações e fluxos de processo |

## Licença

Projeto privado — todos os direitos reservados.

---

*Documentação criada em Fevereiro/2026*
