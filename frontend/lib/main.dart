import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event_state.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/congregations/bloc/congregation_context_cubit.dart';
import 'features/congregations/data/congregation_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(IgrejaManagerApp(
    authRepository: authRepository,
    apiClient: apiClient,
  ));
}

class IgrejaManagerApp extends StatefulWidget {
  final AuthRepository authRepository;
  final ApiClient apiClient;

  const IgrejaManagerApp({
    super.key,
    required this.authRepository,
    required this.apiClient,
  });

  @override
  State<IgrejaManagerApp> createState() => _IgrejaManagerAppState();
}

class _IgrejaManagerAppState extends State<IgrejaManagerApp> {
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;
  late final CongregationContextCubit _congregationContextCubit;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository);
    _appRouter = AppRouter(authBloc: _authBloc);
    _congregationContextCubit = CongregationContextCubit(
      repository: CongregationRepository(apiClient: widget.apiClient),
    );

    // Check authentication on startup
    _authBloc.add(const AuthCheckRequested());

    // Load congregations when user becomes authenticated
    _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _congregationContextCubit.loadCongregations();
      } else if (state is AuthUnauthenticated) {
        _congregationContextCubit.clear();
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _congregationContextCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.apiClient),
        RepositoryProvider.value(value: widget.authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _congregationContextCubit),
        ],
        child: MaterialApp.router(
          title: 'Igreja Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
