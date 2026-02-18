import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event_state.dart';
import 'features/auth/data/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository);
    _appRouter = AppRouter(authBloc: _authBloc);

    // Check authentication on startup
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.apiClient),
        RepositoryProvider.value(value: widget.authRepository),
      ],
      child: BlocProvider.value(
        value: _authBloc,
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
