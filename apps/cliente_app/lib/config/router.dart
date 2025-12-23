import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import '../screens/dashboard_screen.dart';

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
