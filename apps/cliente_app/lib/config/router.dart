import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import '../screens/dashboard_screen.dart';
import '../features/project_tracking/screens/project_dashboard_screen.dart';
import '../features/project_tracking/screens/project_detail_screen.dart';
import '../features/clients/screens/clients_list_screen.dart';
import '../features/clients/screens/client_detail_screen.dart';
import '../features/payroll/screens/payroll_dashboard_screen.dart';
import '../features/payroll/screens/pagos_diarios_screen.dart';
import '../features/payroll/screens/destajo_soldadores_screen.dart';
import '../features/payroll/screens/nomina_instalacion_screen.dart';
import '../features/payroll/screens/nomina_chofer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // ref.watch(authStateProvider);

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
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
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
        path: '/clients',
        builder: (context, state) => const ClientsListScreen(),
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
            builder: (context, state) => const DestajoSoldadoresScreen(),
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
