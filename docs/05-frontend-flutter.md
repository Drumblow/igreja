# 📱 Frontend Flutter — Igreja Manager

## 1. Visão Geral

O frontend é construído em **Flutter 3.19+** com suporte a três plataformas: Web, Android e iOS. Utiliza **Flutter BLoC** para gerenciamento de estado e segue a arquitetura **Feature-First com Clean Architecture**.

---

## 2. Configuração do Projeto

### 2.1 pubspec.yaml

```yaml
name: igreja_manager
description: Sistema de Gestão para Igrejas
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Gerenciamento de estado
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5

  # Navegação
  go_router: ^14.0.0

  # Rede
  dio: ^5.4.0
  retrofit: ^4.1.0
  retrofit_generator: ^8.1.0

  # Serialização
  json_annotation: ^4.9.0
  freezed_annotation: ^2.4.1

  # Injeção de dependência
  get_it: ^7.6.7
  injectable: ^2.4.1

  # Armazenamento local
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI Components
  flutter_svg: ^2.0.10
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_spinkit: ^5.2.1
  
  # Formulários e validação
  reactive_forms: ^17.0.1
  mask_text_input_formatter: ^2.9.0

  # Gráficos
  fl_chart: ^0.68.0

  # PDF e impressão
  pdf: ^3.10.8
  printing: ^5.12.0

  # Calendário
  table_calendar: ^3.1.1

  # Imagem
  image_picker: ^1.0.7
  image_cropper: ^5.0.1

  # Utilitários
  intl: ^0.19.0
  url_launcher: ^6.2.5
  share_plus: ^7.2.2
  package_info_plus: ^8.0.0
  connectivity_plus: ^6.0.3
  logger: ^2.2.0

  # Ícones
  phosphor_flutter: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Geração de código
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.7.1
  injectable_generator: ^2.6.1
  hive_generator: ^2.0.1

  # Testes
  bloc_test: ^9.1.7
  mocktail: ^1.0.3

  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## 3. Mapa de Telas

### 3.1 Fluxo Geral de Navegação

```
App Launch
    │
    ├── Splash Screen
    │       │
    │       ├── [Token válido] ──► Dashboard
    │       └── [Sem token] ────► Login
    │
    ├── Login ──► Forgot Password
    │       │
    │       └── [Sucesso] ──► Dashboard
    │
    └── Dashboard (Shell com Drawer/Bottom Nav)
            │
            ├── 🏠 Home (Dashboard)
            │
            ├── 👥 Membros
            │   ├── Lista de Membros
            │   ├── Detalhes do Membro
            │   ├── Formulário (Criar/Editar)
            │   ├── Histórico do Membro
            │   ├── Famílias
            │   │   ├── Lista de Famílias
            │   │   └── Detalhes da Família
            │   ├── Ministérios
            │   │   ├── Lista de Ministérios
            │   │   └── Membros do Ministério
            │   ├── Aniversariantes
            │   └── Relatórios
            │
            ├── 💰 Financeiro
            │   ├── Painel Financeiro
            │   ├── Lançamentos
            │   │   ├── Lista
            │   │   └── Formulário (Criar/Editar)
            │   ├── Dízimos
            │   │   ├── Registro
            │   │   └── Histórico por Membro
            │   ├── Plano de Contas
            │   ├── Contas Bancárias
            │   ├── Campanhas
            │   │   ├── Lista
            │   │   └── Detalhes/Progresso
            │   ├── Fechamento Mensal
            │   └── Relatórios
            │       ├── Balancete
            │       ├── Fluxo de Caixa
            │       └── Demonstrativos
            │
            ├── 🏗️ Patrimônio
            │   ├── Lista de Bens
            │   ├── Detalhes do Bem
            │   ├── Formulário (Criar/Editar)
            │   ├── Categorias
            │   ├── Manutenções
            │   │   ├── Lista
            │   │   └── Formulário
            │   ├── Inventários
            │   │   ├── Lista
            │   │   └── Conferência
            │   ├── Empréstimos
            │   └── Relatórios
            │
            ├── 📖 EBD
            │   ├── Painel da EBD
            │   ├── Trimestres
            │   ├── Turmas
            │   │   ├── Lista
            │   │   ├── Detalhes (alunos, frequência)
            │   │   └── Matrícula
            │   ├── Chamada (Frequência)
            │   │   ├── Selecionar Turma/Data
            │   │   └── Registro de Presença
            │   ├── Aulas/Lições
            │   └── Relatórios
            │       ├── Frequência por Turma
            │       ├── Frequência por Aluno
            │       └── Consolidado Trimestral
            │
            └── ⚙️ Configurações
                ├── Dados da Igreja
                ├── Usuários
                ├── Perfil do Usuário
                ├── Tema (Claro/Escuro)
                └── Sobre
```

---

## 4. Design System

### 4.1 Cores

```dart
// lib/core/constants/app_colors.dart

abstract class AppColors {
  // Primária - Azul profundo (confiança, seriedade)
  static const primary = Color(0xFF1A3A5C);
  static const primaryLight = Color(0xFF2D5F8A);
  static const primaryDark = Color(0xFF0F2640);

  // Secundária - Dourado (espiritualidade, valor)
  static const secondary = Color(0xFFD4A843);
  static const secondaryLight = Color(0xFFE8C96E);
  static const secondaryDark = Color(0xFFB08930);

  // Sucesso
  static const success = Color(0xFF2D8A4E);
  static const successLight = Color(0xFFE8F5E9);

  // Alerta
  static const warning = Color(0xFFF5A623);
  static const warningLight = Color(0xFFFFF8E1);

  // Erro
  static const error = Color(0xFFD32F2F);
  static const errorLight = Color(0xFFFFEBEE);

  // Info
  static const info = Color(0xFF1976D2);
  static const infoLight = Color(0xFFE3F2FD);

  // Neutros
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFFBDBDBD);
  static const border = Color(0xFFE0E0E0);
  static const divider = Color(0xFFF0F0F0);

  // Dark theme
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2C2C2C);
}
```

### 4.2 Tipografia

```dart
// lib/core/constants/app_typography.dart

abstract class AppTypography {
  static const headingXL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const headingL = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const headingM = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const headingS = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const bodyL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.3,
  );
}
```

### 4.3 Espaçamento

```dart
// lib/core/constants/app_spacing.dart

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double borderRadius = 12;
  static const double borderRadiusSm = 8;
  static const double borderRadiusLg = 16;
}
```

---

## 5. Componentes Reutilizáveis

### 5.1 Catálogo de Widgets Compartilhados

| Widget | Descrição | Uso |
|--------|-----------|-----|
| `AppScaffold` | Scaffold padrão com drawer/bottom nav | Todas as telas |
| `AppTextField` | Campo de texto customizado com validação | Formulários |
| `AppButton` | Botão primário/secundário/outline | Ações |
| `AppCard` | Card com sombra e bordas padronizadas | Listas, resumos |
| `AppDialog` | Dialog de confirmação/informação | Ações críticas |
| `AppSearchBar` | Barra de busca com debounce | Listagens |
| `AppFilterChips` | Chips de filtro | Filtros de listagem |
| `AppEmptyState` | Ilustração + mensagem para listas vazias | Listagens |
| `AppErrorWidget` | Widget de erro com botão "Tentar novamente" | Erros de rede |
| `AppLoadingShimmer` | Skeleton loading | Carregamentos |
| `AppPagination` | Controle de paginação | Listagens |
| `AppStatsCard` | Card com ícone, título e valor numérico | Dashboard |
| `AppChart` | Wrapper para gráficos (fl_chart) | Relatórios |
| `MemberAvatar` | Avatar do membro (foto ou iniciais) | Listas de membros |
| `CurrencyText` | Texto formatado como moeda (R$) | Valores |
| `DateRangePicker` | Seletor de período | Filtros por data |
| `StatusBadge` | Badge colorido com status | Indicadores |

### 5.2 Exemplo: AppTextField

```dart
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 6. Gerenciamento de Estado (BLoC)

### 6.1 Padrão BLoC por Feature

Cada feature segue o padrão: **Event → BLoC → State**

```
┌─────────┐     ┌──────────┐     ┌─────────┐
│  Event   │────▶│   BLoC   │────▶│  State  │
│          │     │          │     │         │
│ LoadList │     │ map event│     │ Loading │
│ Create   │     │ to state │     │ Loaded  │
│ Update   │     │          │     │ Error   │
│ Delete   │     │ calls    │     │         │
│ Filter   │     │ use case │     │         │
└─────────┘     └──────────┘     └─────────┘
```

### 6.2 Exemplo: MemberBloc

```dart
// member_event.dart
abstract class MemberEvent extends Equatable {
  const MemberEvent();
  @override
  List<Object?> get props => [];
}

class LoadMembers extends MemberEvent {
  final MemberFilter? filter;
  final int page;
  const LoadMembers({this.filter, this.page = 1});
  @override
  List<Object?> get props => [filter, page];
}

class SearchMembers extends MemberEvent {
  final String query;
  const SearchMembers(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateMember extends MemberEvent {
  final CreateMemberDto dto;
  const CreateMember(this.dto);
  @override
  List<Object?> get props => [dto];
}

class UpdateMember extends MemberEvent {
  final String id;
  final UpdateMemberDto dto;
  const UpdateMember(this.id, this.dto);
  @override
  List<Object?> get props => [id, dto];
}

class DeleteMember extends MemberEvent {
  final String id;
  const DeleteMember(this.id);
  @override
  List<Object?> get props => [id];
}
```

```dart
// member_state.dart
abstract class MemberState extends Equatable {
  const MemberState();
  @override
  List<Object?> get props => [];
}

class MemberInitial extends MemberState {}

class MemberLoading extends MemberState {}

class MembersLoaded extends MemberState {
  final List<Member> members;
  final PaginationMeta meta;
  final MemberFilter? activeFilter;
  
  const MembersLoaded({
    required this.members,
    required this.meta,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [members, meta, activeFilter];
}

class MemberDetailLoaded extends MemberState {
  final MemberDetail member;
  const MemberDetailLoaded(this.member);
  @override
  List<Object?> get props => [member];
}

class MemberSaved extends MemberState {
  final String message;
  const MemberSaved(this.message);
  @override
  List<Object?> get props => [message];
}

class MemberError extends MemberState {
  final String message;
  const MemberError(this.message);
  @override
  List<Object?> get props => [message];
}
```

```dart
// member_bloc.dart
class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final GetMembers _getMembers;
  final CreateMemberUseCase _createMember;
  final UpdateMemberUseCase _updateMember;
  final DeleteMemberUseCase _deleteMember;

  MemberBloc({
    required GetMembers getMembers,
    required CreateMemberUseCase createMember,
    required UpdateMemberUseCase updateMember,
    required DeleteMemberUseCase deleteMember,
  })  : _getMembers = getMembers,
        _createMember = createMember,
        _updateMember = updateMember,
        _deleteMember = deleteMember,
        super(MemberInitial()) {
    on<LoadMembers>(_onLoadMembers);
    on<SearchMembers>(_onSearchMembers, transformer: debounce(300.ms));
    on<CreateMember>(_onCreateMember);
    on<UpdateMember>(_onUpdateMember);
    on<DeleteMember>(_onDeleteMember);
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    final result = await _getMembers(
      filter: event.filter,
      page: event.page,
    );
    result.fold(
      (failure) => emit(MemberError(failure.message)),
      (response) => emit(MembersLoaded(
        members: response.data,
        meta: response.meta,
        activeFilter: event.filter,
      )),
    );
  }

  // ... outros handlers
}
```

---

## 7. Navegação (go_router)

```dart
// lib/routes/app_router.dart

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuth = context.read<AuthBloc>().state is Authenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    
    if (!isAuth && !isAuthRoute && state.matchedLocation != '/splash') {
      return '/auth/login';
    }
    if (isAuth && isAuthRoute) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashPage(),
    ),
    
    // Auth routes
    GoRoute(
      path: '/auth/login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: '/auth/forgot-password',
      builder: (_, __) => const ForgotPasswordPage(),
    ),
    
    // Shell route (com drawer/navigation)
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardPage(),
        ),
        
        // Membros
        GoRoute(
          path: '/members',
          builder: (_, __) => const MembersListPage(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (_, __) => const MemberFormPage(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => MemberDetailPage(
                id: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, state) => MemberFormPage(
                    id: state.pathParameters['id'],
                  ),
                ),
                GoRoute(
                  path: 'history',
                  builder: (_, state) => MemberHistoryPage(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Famílias
        GoRoute(
          path: '/families',
          builder: (_, __) => const FamiliesListPage(),
        ),
        
        // Ministérios
        GoRoute(
          path: '/ministries',
          builder: (_, __) => const MinistriesListPage(),
        ),
        
        // Financeiro
        GoRoute(
          path: '/financial',
          builder: (_, __) => const FinancialDashboardPage(),
          routes: [
            GoRoute(
              path: 'entries',
              builder: (_, __) => const FinancialEntriesPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (_, __) => const FinancialEntryFormPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'tithes',
              builder: (_, __) => const TithesPage(),
            ),
            GoRoute(
              path: 'campaigns',
              builder: (_, __) => const CampaignsPage(),
            ),
            GoRoute(
              path: 'account-plans',
              builder: (_, __) => const AccountPlansPage(),
            ),
            GoRoute(
              path: 'bank-accounts',
              builder: (_, __) => const BankAccountsPage(),
            ),
            GoRoute(
              path: 'reports',
              builder: (_, __) => const FinancialReportsPage(),
            ),
          ],
        ),
        
        // Patrimônio
        GoRoute(
          path: '/assets',
          builder: (_, __) => const AssetsListPage(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (_, __) => const AssetFormPage(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => AssetDetailPage(
                id: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'maintenances',
              builder: (_, __) => const MaintenancesPage(),
            ),
            GoRoute(
              path: 'inventories',
              builder: (_, __) => const InventoriesPage(),
            ),
            GoRoute(
              path: 'loans',
              builder: (_, __) => const AssetLoansPage(),
            ),
          ],
        ),
        
        // EBD
        GoRoute(
          path: '/ebd',
          builder: (_, __) => const EbdDashboardPage(),
          routes: [
            GoRoute(
              path: 'classes',
              builder: (_, __) => const EbdClassesPage(),
            ),
            GoRoute(
              path: 'classes/:id',
              builder: (_, state) => EbdClassDetailPage(
                id: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'attendance',
              builder: (_, __) => const EbdAttendancePage(),
            ),
            GoRoute(
              path: 'lessons',
              builder: (_, __) => const EbdLessonsPage(),
            ),
            GoRoute(
              path: 'reports',
              builder: (_, __) => const EbdReportsPage(),
            ),
          ],
        ),
        
        // Configurações
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'church',
              builder: (_, __) => const ChurchSettingsPage(),
            ),
            GoRoute(
              path: 'users',
              builder: (_, __) => const UsersManagementPage(),
            ),
            GoRoute(
              path: 'profile',
              builder: (_, __) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

---

## 8. Layout Responsivo

### 8.1 Breakpoints

```dart
abstract class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile &&
      MediaQuery.sizeOf(context).width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}
```

### 8.2 Estratégia de Layout

| Plataforma | Navegação | Layout de Listagem | Formulários |
|------------|-----------|-------------------|-------------|
| **Mobile** | Bottom Navigation Bar (4 abas) + Drawer | Lista vertical (cards) | Tela cheia, scroll vertical |
| **Tablet** | Navigation Rail lateral | Lista + Detalhe (split view) | Modal lateral ou tela cheia |
| **Web/Desktop** | Drawer lateral expandido | Tabela com filtros laterais | Modal ou painel lateral |

### 8.3 Componente Responsivo

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
```

---

## 9. Wireframes das Telas Principais

### 9.1 Dashboard (Mobile)

```
┌─────────────────────────────┐
│  ☰  Igreja Manager    🔔   │  ← AppBar
├─────────────────────────────┤
│                             │
│  Olá, Pastor João! 👋       │
│                             │
│  ┌──────────┐ ┌──────────┐ │
│  │ 👥 350   │ │ 💰 R$22k │ │  ← Stats Cards
│  │ Membros  │ │ Saldo    │ │
│  └──────────┘ └──────────┘ │
│  ┌──────────┐ ┌──────────┐ │
│  │ 📖 245   │ │ 🏗️ 156  │ │
│  │ EBD Dom. │ │ Bens     │ │
│  └──────────┘ └──────────┘ │
│                             │
│  📊 Financeiro do Mês       │
│  ┌─────────────────────────┐│
│  │  ████████ R$ 25.000     ││  ← Gráfico receita
│  │  █████   R$ 18.000      ││  ← Gráfico despesa
│  │  Receitas  Despesas      ││
│  └─────────────────────────┘│
│                             │
│  🎂 Aniversariantes         │
│  ┌─────────────────────────┐│
│  │ 👤 Maria Silva  - 20/02 ││
│  │ 👤 João Santos  - 22/02 ││
│  └─────────────────────────┘│
│                             │
│  ⚠️ Alertas                 │
│  ┌─────────────────────────┐│
│  │ Conta de energia - 3d   ││
│  │ Manutenção AC - amanhã  ││
│  └─────────────────────────┘│
│                             │
├─────────────────────────────┤
│  🏠   👥   💰   📖   ⚙️    │  ← Bottom Nav
└─────────────────────────────┘
```

### 9.2 Lista de Membros (Mobile)

```
┌─────────────────────────────┐
│  ← Membros            🔍 + │
├─────────────────────────────┤
│  ┌─────────────────────────┐│
│  │ 🔍 Buscar membro...     ││
│  └─────────────────────────┘│
│                             │
│  [Todos] [Ativos] [Inativos]│  ← Filter chips
│                             │
│  ┌─────────────────────────┐│
│  │ 👤 Maria Silva Santos   ││
│  │    Membro • Ativa        ││  ← Member card
│  │    📞 (11) 99999-8888   ││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │ 👤 João Pedro Oliveira  ││
│  │    Diácono • Ativo       ││
│  │    📞 (11) 98765-4321   ││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │ 👤 Ana Costa Lima       ││
│  │    Membro • Ativa        ││
│  │    📞 (11) 91234-5678   ││
│  └─────────────────────────┘│
│                             │
│  Mostrando 1-20 de 350     │  ← Paginação
│  [◀ Anterior] [Próximo ▶]  │
│                             │
├─────────────────────────────┤
│  🏠   👥   💰   📖   ⚙️    │
└─────────────────────────────┘
```

### 9.3 Chamada EBD (Mobile)

```
┌─────────────────────────────┐
│  ← Chamada EBD       ✓ Salvar│
├─────────────────────────────┤
│                             │
│  📅 15/02/2026 (Domingo)    │
│  📖 Turma: Jovens e Adolesc.│
│  👨‍🏫 Prof: Maria Silva      │
│                             │
│  Lição 7: A Oração do Justo│
│  📜 Tiago 5:13-20           │
│                             │
├─────────────────────────────┤
│  Alunos matriculados (25)   │
│                             │
│  ┌─────────────────────────┐│
│  │ 👤 Ana Paula            ││
│  │ [✅ P] [❌ A] [⚠️ J]   ││
│  │ [📖 Bíblia] [📕 Revista]││
│  │ Oferta: R$ [____5,00]   ││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │ 👤 Carlos Eduardo       ││
│  │ [✅ P] [❌ A] [⚠️ J]   ││
│  │ [📖 Bíblia] [📕 Revista]││
│  │ Oferta: R$ [____0,00]   ││
│  └─────────────────────────┘│
│                             │
│  + Adicionar visitante      │
│                             │
│  ─── Resumo ───             │
│  Presentes: 20 | Ausentes: 5│
│  Bíblias: 18 | Revistas: 15│
│  Oferta total: R$ 45,00    │
│                             │
├─────────────────────────────┤
│  🏠   👥   💰   📖   ⚙️    │
└─────────────────────────────┘
```

---

## 10. Suporte Offline

### 10.1 Estratégia

| Funcionalidade | Offline? | Sincronização |
|----------------|----------|---------------|
| Chamada EBD | ✅ Sim | Ao reconectar, enviar chamadas pendentes |
| Consulta de membros | ✅ Sim (cache) | Cache local via Hive |
| Cadastro de membro | ❌ Não | Requer conexão |
| Lançamento financeiro | ❌ Não | Requer conexão |
| Dashboard | ✅ Parcial | Última versão cacheada |

### 10.2 Implementação

```dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged
          .map((result) => result != ConnectivityResult.none);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

// No BLoC, verificar conectividade antes de chamadas de rede
// e usar dados locais como fallback
```

---

## 11. Testes

### 11.1 Estrutura de Testes

```
frontend/test/
├── core/
│   ├── network/
│   │   └── api_client_test.dart
│   └── utils/
│       └── validators_test.dart
├── features/
│   ├── members/
│   │   ├── data/
│   │   │   └── member_model_test.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── get_members_test.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── member_bloc_test.dart
│   │       └── pages/
│   │           └── members_list_page_test.dart
│   └── ...
└── helpers/
    ├── mock_data.dart
    └── test_helpers.dart
```

### 11.2 Exemplo de Teste BLoC

```dart
void main() {
  late MemberBloc bloc;
  late MockGetMembers mockGetMembers;

  setUp(() {
    mockGetMembers = MockGetMembers();
    bloc = MemberBloc(getMembers: mockGetMembers, ...);
  });

  blocTest<MemberBloc, MemberState>(
    'emits [Loading, Loaded] when LoadMembers succeeds',
    build: () {
      when(() => mockGetMembers(any(), any())).thenAnswer(
        (_) async => Right(PaginatedResponse(data: [testMember], meta: testMeta)),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const LoadMembers()),
    expect: () => [
      isA<MemberLoading>(),
      isA<MembersLoaded>(),
    ],
  );
}
```

---

*Referência técnica do frontend — guia para implementação das interfaces e fluxos.*
