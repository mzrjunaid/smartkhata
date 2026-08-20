import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartkhata/features/lender_dashboard/screens/lender_dashboard.dart';
import 'package:smartkhata/features/new_loan/screens/new_loan_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/loan_users/screens/loan_users_screen.dart';
import '../../features/loan_users/screens/borrower_profile_screen.dart';
import '../../features/repayments/screens/repayments_borrower_list_screen.dart';
import '../../features/repayments/screens/repayment_schedule_screen.dart';
import '../../features/repayments/screens/repayment_review_screen.dart';
import '../../features/repayments/screens/borrower_repayment_form_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/audit_logs/screens/audit_logs_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../widgets/app_shell.dart';
import '../../features/reminders/screens/reminders_screen.dart';

/// Converts a [Stream] into a [ChangeNotifier] so GoRouter
/// can re-evaluate its redirect whenever the stream emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // initial evaluation
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // 1. HOME
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const LenderDashboard(title: 'Lender Dashboard'),
                routes: [
                  GoRoute(
                    path: 'new-loan',
                    builder: (context, state) => const NewLoanScreen(),
                  ),
                  GoRoute(
                    path: 'borrower-profile/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return BorrowerProfileScreen(connectionId: id);
                    },
                  ),
                  GoRoute(
                    path: 'borrower-repayment-form',
                    builder: (context, state) {
                      final repaymentId = state.uri.queryParameters['repaymentId'];
                      final loanId = state.uri.queryParameters['loanId'];
                      return BorrowerRepaymentFormScreen(
                        repaymentId: repaymentId,
                        loanId: loanId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'repayments',
                    builder: (context, state) => const RepaymentsBorrowerListScreen(),
                    routes: [
                      GoRoute(
                        path: 'repayment-review/:repaymentId',
                        builder: (context, state) {
                          final repaymentId = state.pathParameters['repaymentId']!;
                          return RepaymentReviewScreen(repaymentId: repaymentId);
                        },
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return RepaymentScheduleScreen(connectionId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'audit-logs',
                    builder: (context, state) => const AuditLogsScreen(),
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const RemindersScreen(),
                  ),
                ],
              ),
            ],
          ),
          // 2. Loan Users
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/loan-users',
                builder: (context, state) => const LoanUsersScreen(),
              ),
            ],
          ),
          // 3. Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          // 4. Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final edit = extra?['edit'] as bool? ?? false;
                  return ProfileScreen(initialEditMode: edit);
                },
              ),
            ],
          ),
          // 5. Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
