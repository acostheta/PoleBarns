import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import 'providers/navigation_providers.dart';
import 'features/settings/repositories/rbac_repository.dart';

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
    final isAdmin = profile?['user_level'] == 'Administrador';

    bool canView(String key) {
      if (isAdmin) return true;
      if (accessMap['*'] == true) return true;
      return accessMap[key] == true;
    }

    // Determine title based on current route
    final String location = GoRouterState.of(context).uri.toString();
    String title = 'App Gilbert';
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
        // Logo section at the top
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/dashboard'),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 32,
                horizontal: effectiveIsMenuOpen ? 24 : 12,
              ),
              child: Row(
                mainAxisAlignment: effectiveIsMenuOpen
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/branding/logo.png',
                    height: effectiveIsMenuOpen ? 120 : 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business,
                        size: effectiveIsMenuOpen ? 120 : 40),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(
            color: Colors.grey[200], thickness: 1, indent: 16, endIndent: 16),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: effectiveIsMenuOpen ? 1.0 : 0.0,
                child: effectiveIsMenuOpen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: Colors.grey[300], height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'ADMINISTRACIÓN',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                            indent: 12,
                            endIndent: 12,
                            color: Colors.grey[300],
                            height: 1),
                      ),
              ),
              if (canView('clients'))
                _buildMenuItem(
                  icon: Icons.person_add,
                  title: 'Clientes',
                  path: '/clients',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('invoices'))
                _buildMenuItem(
                  icon: Icons.receipt_long,
                  title: 'Invoices',
                  path: '/invoices',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('projects'))
                _buildMenuItem(
                  icon: Icons.construction,
                  title: 'Proyectos',
                  path: '/projects',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('inventory'))
                _buildMenuItem(
                  icon: Icons.architecture,
                  title: 'Productos', // Mapped to inventory module
                  path: '/pole-barns',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('payroll'))
                _buildMenuItem(
                  icon: Icons.payments,
                  title: 'Nómina',
                  path: '/payroll',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('accounts_payable'))
                _buildMenuItem(
                  icon: Icons.attach_money,
                  title: 'Cuentas por Pagar',
                  path: '/accounts-payable',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('users') || isAdmin)
                _buildMenuItem(
                  icon: Icons.group,
                  title: 'Usuarios',
                  path: '/users',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
              if (canView('settings') || isAdmin)
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Configuración',
                  path: '/settings',
                  location: location,
                  isMenuOpen: effectiveIsMenuOpen,
                ),
            ],
          ),
        ),
        Divider(color: Colors.grey[300], height: 1),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
                _scaffoldKey.currentState?.closeDrawer();
              }
              context.go('/profile');
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: effectiveIsMenuOpen ? 24 : 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: profileAsync.asData?.value?['picture'] !=
                            null
                        ? NetworkImage(profileAsync.asData!.value!['picture'])
                        : null,
                    child: profileAsync.asData?.value?['picture'] == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: effectiveIsMenuOpen ? 1.0 : 0.0,
                      curve: Curves.easeInOut,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileAsync.asData?.value?['name'] ?? 'Usuario',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (effectiveIsMenuOpen)
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: Color(0xFF64748B), size: 20),
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                      },
                      tooltip: 'Cerrar Sesión',
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (isMobile) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                ref.read(sidebarExpandedProvider.notifier).state = !isMenuOpen;
              }
            },
          ),
        ),
        title: Text(title),
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
      body: Row(
        children: [
          if (!isMobile) ...[
            // Persistent Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: effectiveIsMenuOpen ? 280 : 72,
              color: Theme.of(context).cardColor,
              child: sidebarContent,
            ),
            VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
          ],
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
      required String title,
      required String path,
      required String location,
      required bool isMenuOpen}) {
    // final isMenuOpen = ref.watch(sidebarExpandedProvider); // passed directly now
    // Simple matching: exact match for dashboard, startsWith for others
    final isSelected = path == '/dashboard'
        ? location == '/dashboard'
        : location.startsWith(path);

    const activeColor = Color(0xFF92400E);
    const activeBgColor = Color(0xFFFEF3C7);
    const inactiveColor = Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () {
          final isMobile = MediaQuery.of(context).size.width < 800;
          if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
            _scaffoldKey.currentState?.closeDrawer();
          }
          context.go(path);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
}
