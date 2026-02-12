import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import '../shell_layout.dart';

import '../features/project_tracking/screens/project_dashboard_screen.dart';
import '../features/project_tracking/screens/project_detail_screen.dart';
import '../features/clients/screens/clients_list_screen.dart';
import '../features/clients/screens/client_detail_screen.dart';
import '../features/payroll/screens/payroll_dashboard_screen.dart';
import '../features/payroll/screens/pagos_diarios_screen.dart';
import '../features/payroll/screens/pagos_soldadores_screen.dart';
import '../features/payroll/screens/nomina_instalacion_screen.dart';
import '../features/payroll/screens/nomina_chofer_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/accounts_payable/screens/accounts_payable_dashboard.dart';
import '../features/pole_barns/screens/pole_barns_dashboard_screen.dart';
import '../features/invoices/screens/invoices_dashboard_screen.dart';
import '../features/invoices/screens/create_invoice_screen.dart';
import 'package:users/users.dart';
import '../features/project_tracking/widgets/project_create_dialog.dart';
import '../features/project_tracking/providers/project_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: RouterNotifier(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Center(
              child: Text('Bienvenido a App Gilbert',
                  style: TextStyle(fontSize: 24)),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) {
              final tab =
                  int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
              return SettingsScreen(initialIndex: tab);
            },
          ),
          GoRoute(
            path: '/accounts-payable',
            builder: (context, state) => const AccountsPayableDashboard(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectDashboardScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ProjectDetailScreen(projectId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/pole-barns',
            builder: (context, state) => const PoleBarnsDashboardScreen(),
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoicesDashboardScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateInvoiceScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => CreateInvoiceScreen(
                  invoiceId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersListScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => ClientsListScreen(
              onCreateEstimate: (clientId, _) {
                showDialog(
                  context: context,
                  builder: (context) =>
                      ProjectCreateDialog(initialClientId: clientId),
                ).then((success) {
                  if (success == true) {
                    ref.invalidate(projectListProvider);
                    if (context.mounted) context.go('/projects');
                  }
                });
              },
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const ClientDetailScreen(clientId: 'new'),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ClientDetailScreen(clientId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/payroll',
            builder: (context, state) => const PayrollDashboardScreen(),
            routes: [
              GoRoute(
                path: 'daily',
                builder: (context, state) => const PagosDiariosScreen(),
              ),
              GoRoute(
                path: 'welders',
                builder: (context, state) => const PagosSoldadoresScreen(),
              ),
              GoRoute(
                path: 'installation',
                builder: (context, state) => const NominaInstalacionScreen(),
              ),
              GoRoute(
                path: 'drivers',
                builder: (context, state) => const NominaChoferScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final onLoginPage = state.uri.toString() == '/login';
      final onRegisterPage = state.uri.toString() == '/register';

      if (session == null && !onLoginPage && !onRegisterPage) return '/login';
      if (session != null && (onLoginPage || onRegisterPage)) {
        return '/dashboard';
      }
      return null;
    },
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
