import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import '../providers/navigation_providers.dart';

import '../features/settings/screens/settings_screen.dart';
import '../features/accounts_payable/screens/accounts_payable_screen.dart';
import '../features/project_tracking/screens/project_dashboard_screen.dart';
import '../features/pole_barns/screens/pole_barns_list_screen.dart';
import '../features/invoices/screens/invoices_dashboard_screen.dart';
import '../features/payroll/screens/payroll_dashboard_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isMenuOpen = true;

  // Indices are now in DashboardIndices

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    // We watch the profile to know the role
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : const AsyncValue.loading();
    final userRole = profileAsync.asData?.value?['role'];
    final isAdmin = userRole == 'Administrador' || userRole == 'Admin';

    // Define titles and actions based on index
    String title = 'Inicio';
    List<Widget>? actions;

    Widget bodyContent = const Center(child: Text('Bienvenido'));

    final selectedIndex = ref.watch(dashboardIndexProvider);

    if (selectedIndex == DashboardIndices.profile) {
      title = 'Mi Perfil';
      bodyContent = const ProfileScreen();
    } else if (selectedIndex == DashboardIndices.settings) {
      title = 'Configuración';
      bodyContent = const SettingsScreen();
    } else if (selectedIndex == DashboardIndices.accountsPayable) {
      title = 'Cuentas por Pagar';
      bodyContent = const AccountsPayableScreen();
    } else if (selectedIndex == DashboardIndices.projectTracking) {
      title = 'Proyectos';
      bodyContent = const ProjectDashboardScreen();
    } else if (selectedIndex == DashboardIndices.poleBarns) {
      title = 'Productos';
      bodyContent = const PoleBarnsListScreen();
    } else if (selectedIndex == DashboardIndices.invoices) {
      title = 'Gestión de Facturas (Invoices)';
      bodyContent = const InvoicesDashboardScreen();
    } else if (selectedIndex == DashboardIndices.payroll) {
      title = 'Gestión de Nómina';
      bodyContent = const PayrollDashboardScreen();
    } else {
      // Home
      title = 'App Gilbert';
      bodyContent = const Center(
          child:
              Text('Bienvenido a App Gilbert', style: TextStyle(fontSize: 24)));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isMenuOpen = !_isMenuOpen;
            });
          },
        ),
        title: Text(title),
        actions: actions,
      ),
      body: Row(
        children: [
          // Persistent Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isMenuOpen ? 280 : 0,
            color: Theme.of(context).cardColor,
            child: _isMenuOpen
                ? Column(
                    children: [
                      // User Info Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.05),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              backgroundImage: profileAsync
                                          .asData?.value?['picture'] !=
                                      null
                                  ? NetworkImage(
                                      profileAsync.asData!.value!['picture'])
                                  : null,
                              child:
                                  profileAsync.asData?.value?['picture'] == null
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileAsync.asData?.value?['name'] ??
                                        'Usuario',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildMenuItem(
                              icon: Icons.home,
                              title: 'Inicio',
                              index: DashboardIndices.home,
                            ),
                            _buildMenuItem(
                              icon: Icons.person,
                              title: 'Mi Perfil',
                              index: DashboardIndices.profile,
                            ),
                            if (isAdmin) ...[
                              const Divider(),
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
                              _buildMenuItem(
                                icon: Icons.construction,
                                title: 'Proyectos',
                                index: DashboardIndices.projectTracking,
                              ),
                              _buildMenuItem(
                                icon: Icons.architecture,
                                title: 'Productos',
                                index: DashboardIndices.poleBarns,
                              ),
                              _buildMenuItem(
                                icon: Icons.receipt_long,
                                title: 'Invoices',
                                index: DashboardIndices.invoices,
                              ),
                              _buildMenuItem(
                                icon: Icons.payments,
                                title: 'Nómina',
                                index: DashboardIndices.payroll,
                              ),
                              _buildMenuItem(
                                icon: Icons.attach_money,
                                title: 'Cuentas por Pagar',
                                index: DashboardIndices.accountsPayable,
                              ),
                              _buildMenuItem(
                                icon: Icons.settings,
                                title: 'Configuración',
                                index: DashboardIndices.settings,
                              ),
                            ],
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              child: ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: const Icon(Icons.logout,
                                    color: Color(0xFF64748B), size: 22),
                                title: const Text(
                                  'Cerrar Sesión',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () async {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .signOut();
                                  // Router handles redirect to login
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          // Divider between sidebar and body
          if (_isMenuOpen)
            VerticalDivider(width: 1, color: Theme.of(context).dividerColor),

          // Main Body
          Expanded(
            child: bodyContent,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon, required String title, required int index}) {
    final selectedIndex = ref.watch(dashboardIndexProvider);
    final isSelected = selectedIndex == index;
    final activeColor = const Color(0xFF92400E); // Dark amber/brown
    final activeBgColor = const Color(0xFFFEF3C7); // Light amber
    final inactiveColor = const Color(0xFF64748B); // Slate/Grey

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isSelected ? activeBgColor : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? activeColor : inactiveColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : inactiveColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          ref.read(dashboardIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
