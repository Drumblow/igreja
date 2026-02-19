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
import '../../features/members/presentation/member_history_screen.dart';
import '../../features/ministries/presentation/ministry_list_screen.dart';
import '../../features/ministries/presentation/ministry_detail_screen.dart';
import '../../features/ministries/presentation/ministry_form_screen.dart';
import '../../features/financial/presentation/financial_overview_screen.dart';
import '../../features/financial/presentation/financial_entry_list_screen.dart';
import '../../features/financial/presentation/financial_entry_form_screen.dart';
import '../../features/financial/presentation/account_plan_list_screen.dart';
import '../../features/financial/presentation/bank_account_list_screen.dart';
import '../../features/financial/presentation/campaign_list_screen.dart';
import '../../features/financial/presentation/monthly_closing_list_screen.dart';
import '../../features/assets/presentation/asset_overview_screen.dart';
import '../../features/assets/presentation/asset_list_screen.dart';
import '../../features/assets/presentation/asset_detail_screen.dart';
import '../../features/assets/presentation/asset_form_screen.dart';
import '../../features/assets/presentation/asset_category_list_screen.dart';
import '../../features/assets/presentation/maintenance_list_screen.dart';
import '../../features/assets/presentation/inventory_list_screen.dart';
import '../../features/assets/presentation/asset_loan_list_screen.dart';
import '../../features/ebd/presentation/ebd_overview_screen.dart';
import '../../features/ebd/presentation/ebd_term_list_screen.dart';
import '../../features/ebd/presentation/ebd_class_list_screen.dart';
import '../../features/ebd/presentation/ebd_class_detail_screen.dart';
import '../../features/ebd/presentation/ebd_lesson_list_screen.dart';
import '../../features/ebd/presentation/ebd_attendance_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_overview_screen.dart';
import '../../features/settings/presentation/church_settings_screen.dart';
import '../../features/settings/presentation/user_management_screen.dart';
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
                  GoRoute(
                    path: 'history',
                    name: 'member-history',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final name = state.uri.queryParameters['name'] ?? '';
                      return MemberHistoryScreen(
                        memberId: id,
                        memberName: name,
                      );
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

          // ── Reports ──
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
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
                      final id = state.pathParameters['id']!;
                      return FinancialEntryFormScreen(entryId: id);
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
              GoRoute(
                path: 'monthly-closings',
                name: 'monthly-closings',
                builder: (context, state) => const MonthlyClosingListScreen(),
              ),
            ],
          ),

          // ── Assets (Patrimônio) ──
          GoRoute(
            path: '/assets',
            name: 'assets',
            builder: (context, state) => const AssetOverviewScreen(),
            routes: [
              GoRoute(
                path: 'items',
                name: 'asset-items',
                builder: (context, state) => const AssetListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'asset-create',
                    builder: (context, state) => const AssetFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'asset-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AssetDetailScreen(assetId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'asset-edit',
                        builder: (context, state) {
                          final asset = state.extra as dynamic;
                          return AssetFormScreen(existingAsset: asset);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'categories',
                name: 'asset-categories',
                builder: (context, state) => const AssetCategoryListScreen(),
              ),
              GoRoute(
                path: 'maintenances',
                name: 'asset-maintenances',
                builder: (context, state) => const MaintenanceListScreen(),
              ),
              GoRoute(
                path: 'inventories',
                name: 'asset-inventories',
                builder: (context, state) => const InventoryListScreen(),
              ),
              GoRoute(
                path: 'loans',
                name: 'asset-loans',
                builder: (context, state) => const AssetLoanListScreen(),
              ),
            ],
          ),

          // ── EBD (Escola Bíblica Dominical) ──
          GoRoute(
            path: '/ebd',
            name: 'ebd',
            builder: (context, state) => const EbdOverviewScreen(),
            routes: [
              GoRoute(
                path: 'terms',
                name: 'ebd-terms',
                builder: (context, state) => const EbdTermListScreen(),
              ),
              GoRoute(
                path: 'classes',
                name: 'ebd-classes',
                builder: (context, state) => const EbdClassListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'ebd-class-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return EbdClassDetailScreen(classId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'lessons',
                name: 'ebd-lessons',
                builder: (context, state) => const EbdLessonListScreen(),
              ),
              GoRoute(
                path: 'attendance/:lessonId',
                name: 'ebd-attendance',
                builder: (context, state) {
                  final lessonId = state.pathParameters['lessonId']!;
                  return EbdAttendanceScreen(lessonId: lessonId);
                },
              ),
            ],
          ),

          // ── Settings ──
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsOverviewScreen(),
            routes: [
              GoRoute(
                path: 'church',
                name: 'settings-church',
                builder: (context, state) => const ChurchSettingsScreen(),
              ),
              GoRoute(
                path: 'users',
                name: 'settings-users',
                builder: (context, state) => const UserManagementScreen(),
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
