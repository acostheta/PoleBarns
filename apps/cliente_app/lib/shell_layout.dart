import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import 'providers/navigation_providers.dart';
import 'features/settings/repositories/rbac_repository.dart';

const _primaryColor = Color(0xFF173124);
const _secondaryColor = Color(0xFF7C580F);
const _onPrimary = Color(0xFFFFFFFF);
const _errorColor = Color(0xFFBA1A1A);

class ShellLayout extends ConsumerStatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : const AsyncValue<Map<String, dynamic>>.loading();

    final accessAsync = ref.watch(currentUserAccessProvider);
    final accessMap = accessAsync.valueOrNull ?? {};

    // Check admin status from profile directly to show menu early
    final profile = profileAsync.valueOrNull;
    final isAdmin = profile?['role'] == 'Administrador';

    bool canView(String key) {
      if (isAdmin) return true;
      if (accessMap['*'] == true) return true;
      return accessMap[key] == true;
    }

    // Determine title based on current route
    final String location = GoRouterState.of(context).uri.toString();
    String title = 'J&P Pole Barns LLC';
    if (location.startsWith('/profile')) {
      title = 'Mi Perfil';
    } else if (location.startsWith('/settings')) {
      title = 'Configuración';
    } else if (location.startsWith('/accounts-payable')) {
      title = 'Cuentas por Pagar';
    } else if (location.startsWith('/projects')) {
      title = 'Proyectos';
    } else if (location.startsWith('/pole-barns')) {
      title = 'Productos';
    } else if (location.startsWith('/invoices')) {
      title = 'Gestión de Facturas';
    } else if (location.startsWith('/payroll')) {
      title = 'Gestión de Nómina';
    } else if (location.startsWith('/users')) {
      title = 'Usuarios';
    } else if (location.startsWith('/clients')) {
      title = 'Clientes';
    } else if (location == '/dashboard') {
      title = 'Inicio';
    }

    final isMenuOpen = ref.watch(sidebarExpandedProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final effectiveIsMenuOpen = isMobile ? true : isMenuOpen;

    Widget sidebarContent = Column(
      children: [
        const SizedBox(height: 32),
        _buildBrandHeader(effectiveIsMenuOpen),
        const SizedBox(height: 32),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildMenuItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                path: '/dashboard',
                location: location,
                isMenuOpen: effectiveIsMenuOpen,
              ),
              if (canView('clients'))
                _buildMenuItem(
                  icon: Icons.group_outlined,
                  title: 'Clientes',
                  path: '/clients',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('invoices'))
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Invoices',
                  path: '/invoices',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('projects'))
                _buildMenuItem(
                  icon: Icons.architecture_outlined,
                  title: 'Proyectos',
                  path: '/projects',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('inventory'))
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Productos',
                  path: '/pole-barns',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('payroll'))
                _buildMenuItem(
                  icon: Icons.payments_outlined,
                  title: 'Nómina',
                  path: '/payroll',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('accounts_payable'))
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Cuentas por Pagar',
                  path: '/accounts-payable',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('users') || isAdmin)
                _buildMenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Usuarios',
                  path: '/users',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFC2C8C2), height: 1),
        if (canView('settings') || isAdmin)
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Ajustes',
            path: '/settings',
            location: location,
            isMenuOpen: effectiveIsMenuOpen,
          ),
        _buildLogoutItem(effectiveIsMenuOpen),
        const SizedBox(height: 16),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAF7),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: _primaryColor),
            onPressed: () {
              if (isMobile) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                ref.read(sidebarExpandedProvider.notifier).state = !isMenuOpen;
              }
            },
          ),
        ),
        title: Text(title, style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
      ),
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: Container(
                  color: Theme.of(context).cardColor,
                  child: sidebarContent,
                ),
              ),
            )
          : null,
      backgroundColor: const Color(0xFFF9FAF7),
      body: Row(
        children: [
          if (!isMobile) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: effectiveIsMenuOpen ? 256 : 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 32,
                    offset: const Offset(12, 0),
                  ),
                ],
              ),
              child: sidebarContent,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFC2C8C2)),
          ],
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAF7),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(bool isMenuOpen) {
    if (!isMenuOpen) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, Color(0xFF2D4739)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.architecture, color: _onPrimary, size: 24),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, Color(0xFF2D4739)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.architecture, color: _onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'J&P Pole Barns LLC',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String path,
    required String location,
    required bool isMenuOpen,
  }) {
    final isSelected = path == '/dashboard'
        ? location == '/dashboard'
        : location.startsWith(path);

    const activeColor = _primaryColor;
    const activeBgColor = Color(0xFFFEF3C7);
    const inactiveColor = Color(0xFF727973);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          final isMobile = MediaQuery.of(context).size.width < 800;
          if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
            _scaffoldKey.currentState?.closeDrawer();
          }
          context.go(path);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isMenuOpen ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? activeColor : inactiveColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(bool isMenuOpen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () async {
          await ref.read(authRepositoryProvider).signOut();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.logout,
                color: _errorColor,
                size: 22,
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isMenuOpen ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: _errorColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
