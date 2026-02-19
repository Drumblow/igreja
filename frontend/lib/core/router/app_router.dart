import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/families/presentation/family_list_screen.dart';
import '../../features/families/presentation/family_detail_screen.dart';
import '../../features/families/presentation/family_form_screen.dart';
import '../../features/members/presentation/member_list_screen.dart';
import '../../features/members/presentation/member_detail_screen.dart';
import '../../features/members/presentation/member_form_screen.dart';
import '../../features/ministries/presentation/ministry_list_screen.dart';
import '../../features/ministries/presentation/ministry_detail_screen.dart';
import '../../features/ministries/presentation/ministry_form_screen.dart';
import '../../features/financial/presentation/financial_overview_screen.dart';
import '../../features/financial/presentation/financial_entry_list_screen.dart';
import '../../features/financial/presentation/financial_entry_form_screen.dart';
import '../../features/financial/presentation/account_plan_list_screen.dart';
import '../../features/financial/presentation/bank_account_list_screen.dart';
import '../../features/financial/presentation/campaign_list_screen.dart';
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

          // ── Families ──
          GoRoute(
            path: '/families',
            name: 'families',
            builder: (context, state) => const FamilyListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'family-create',
                builder: (context, state) => const FamilyFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'family-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return FamilyDetailScreen(familyId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'family-edit',
                    builder: (context, state) {
                      final family = state.extra as dynamic;
                      return FamilyFormScreen(existingFamily: family);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Ministries ──
          GoRoute(
            path: '/ministries',
            name: 'ministries',
            builder: (context, state) => const MinistryListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'ministry-create',
                builder: (context, state) => const MinistryFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'ministry-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MinistryDetailScreen(ministryId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'ministry-edit',
                    builder: (context, state) {
                      final ministry = state.extra as dynamic;
                      return MinistryFormScreen(existingMinistry: ministry);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Financial ──
          GoRoute(
            path: '/financial',
            name: 'financial',
            builder: (context, state) => const FinancialOverviewScreen(),
            routes: [
              GoRoute(
                path: 'entries',
                name: 'financial-entries',
                builder: (context, state) => const FinancialEntryListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'financial-entry-create',
                    builder: (context, state) {
                      final type = state.uri.queryParameters['type'];
                      return FinancialEntryFormScreen(initialType: type);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'financial-entry-detail',
                    builder: (context, state) {
                      // For now, redirect to entries list (detail screen TBD)
                      return const FinancialEntryListScreen();
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'account-plans',
                name: 'account-plans',
                builder: (context, state) => const AccountPlanListScreen(),
              ),
              GoRoute(
                path: 'bank-accounts',
                name: 'bank-accounts',
                builder: (context, state) => const BankAccountListScreen(),
              ),
              GoRoute(
                path: 'campaigns',
                name: 'campaigns',
                builder: (context, state) => const CampaignListScreen(),
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
