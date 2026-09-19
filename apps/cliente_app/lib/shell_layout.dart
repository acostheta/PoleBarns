import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import 'providers/navigation_providers.dart';
import 'features/settings/repositories/rbac_repository.dart';

const _primaryColor = Color(0xFF173124);
const _secondaryColor = Color(0xFF7C580F);

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
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    // 1. Datos de Acceso Dinámico (RBAC basado en capacidades)
    final accessAsync = ref.watch(currentUserAccessProvider);
    final accessMap = accessAsync.valueOrNull ?? {};

    // 2. Perfil para el menú de usuario
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : const AsyncValue<Map<String, dynamic>>.loading();

    // Ayudantes de permisos
    bool can(String permission) {
      if (accessMap['*'] == true) return true;
      return accessMap[permission] == true;
    }

    bool canView(String module) => can('view_${module.toLowerCase()}');
    
    final location = GoRouterState.of(context).uri.toString();
    String title = 'PoleBarns';
    if (location.startsWith('/profile')) {
      title = 'Mi Perfil';
    } else if (location.startsWith('/settings')) {
      title = 'Configuración';
    } else if (location.startsWith('/accounts-payable')) {
      title = 'Cuentas por Pagar';
    } else if (location.startsWith('/projects') || location.startsWith('/jobs')) {
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
    final appBarActions = ref.watch(appBarActionsProvider);
    final customTitle = ref.watch(appBarTitleProvider);
    
    final effectiveIsMenuOpen = isMobile ? true : isMenuOpen;

    Widget sidebarContent = Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildMenuItem(
                icon: Icons.dashboard_outlined,
                title: 'Inicio',
                path: '/dashboard',
                location: location,
                isMenuOpen: effectiveIsMenuOpen,
              ),

              // --- Módulos Administrativos (Ordenados según solicitud) ---
              if (accessAsync.isLoading && accessMap.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _secondaryColor,
                      ),
                    ),
                  ),
                )
              else if (accessAsync.hasError && accessMap.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(height: 8),
                      Text(
                        'Error de permisos',
                        style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (canView('clients') || canView('invoices') || canView('projects') || canView('pole_barns') || canView('payroll') || canView('accounts_payable') || canView('users')) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Divider(color: Color(0xFFC2C8C2), height: 1),
                ),
                if (canView('clients'))
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    title: 'Clientes',
                    path: '/clients',
                    location: location,
                    isMenuOpen: effectiveIsMenuOpen,
                  ),
                if (canView('invoices'))
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Facturación',
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
                if (canView('pole_barns'))
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
                if (canView('users'))
                  _buildMenuItem(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Usuarios',
                    path: '/users',
                    location: location,
                    isMenuOpen: effectiveIsMenuOpen,
                  ),
              ],

            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              if (isMobile) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                ref.read(sidebarExpandedProvider.notifier).state = !isMenuOpen;
              }
            },
          ),
        ),
        title: Row(
          children: [

            const Flexible(
              child: Text(
                'PoleBarns',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  fontFamily: 'Manrope',
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (customTitle != null ||
                (title != 'Inicio' && title != 'PoleBarns')) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              Expanded(
                child: Text(
                  (customTitle ?? title).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    fontFamily: 'Manrope',
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          ...appBarActions,
          const SizedBox(width: 8),
          _buildUserMenu(profileAsync.valueOrNull),
          const SizedBox(width: 16),
        ],
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

  void _onRouteSelected(String path) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    
    context.go(path);
  }

  Widget _buildUserMenu(Map<String, dynamic>? profile) {
    final name = profile?['full_name'] ?? profile?['nombre'] ?? 'Usuario';
    final photoUrl = profile?['avatar_url'] ?? profile?['photo_url'];

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              if (MediaQuery.of(context).size.width > 700) ...[
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          context.go('/profile');
        } else if (value == 'settings') {
          context.go('/settings');
        } else if (value == 'logout') {
          ref.read(authRepositoryProvider).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile?['role']?.toString().toUpperCase() ?? 'COLABORADOR',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  color: _secondaryColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline,
                  size: 20, color: Colors.black.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              const Text('Mi Perfil',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined,
                  size: 20, color: Colors.black.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              const Text('Ajustes',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: Colors.redAccent),
              const SizedBox(width: 12),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
        onTap: () => _onRouteSelected(path),
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

}
