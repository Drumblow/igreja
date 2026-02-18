import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/presentation/member_list_screen.dart';
import '../../features/members/presentation/member_detail_screen.dart';
import '../../features/members/presentation/member_form_screen.dart';
import '../shell/app_shell.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterAuthRefreshStream(authBloc.stream),
    redirect: _guard,
    routes: [
      // ── Login ──
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── App Shell (sidebar + content) ──
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/members',
            name: 'members',
            builder: (context, state) => const MemberListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'member-create',
                builder: (context, state) => const MemberFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'member-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MemberDetailScreen(memberId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'member-edit',
                    builder: (context, state) {
                      final member = state.extra as dynamic;
                      return MemberFormScreen(existingMember: member);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final isAuthenticated = authBloc.state is AuthAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isAuthenticated && !isLoginRoute) {
      return '/login';
    }
    if (isAuthenticated && isLoginRoute) {
      return '/';
    }
    return null;
  }
}

/// Converts a [Stream] into a [Listenable] for GoRouter's refreshListenable.
class _GoRouterAuthRefreshStream extends ChangeNotifier {
  _GoRouterAuthRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
