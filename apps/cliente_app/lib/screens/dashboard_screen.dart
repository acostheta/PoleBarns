import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import '../providers/navigation_providers.dart';

import '../features/settings/screens/settings_screen.dart';
import '../features/accounts_payable/screens/accounts_payable_dashboard.dart';
import '../features/project_tracking/screens/project_dashboard_screen.dart';
import '../features/pole_barns/screens/pole_barns_dashboard_screen.dart';
import '../features/invoices/screens/invoices_dashboard_screen.dart';
import '../features/payroll/screens/payroll_dashboard_screen.dart';
import 'package:users/users.dart';
import 'package:clients/clients.dart';
import '../features/project_tracking/widgets/project_create_dialog.dart';
import '../features/project_tracking/providers/project_providers.dart';
import '../config/ui_helpers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = user != null
        ? ref.watch(userProfileProvider(user.id))
        : const AsyncValue<Map<String, dynamic>>.loading();

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
      bodyContent = const AccountsPayableDashboard();
    } else if (selectedIndex == DashboardIndices.projectTracking) {
      title = 'Proyectos';
      bodyContent = const ProjectDashboardScreen();
    } else if (selectedIndex == DashboardIndices.poleBarns) {
      title = 'Productos';
      bodyContent = const PoleBarnsDashboardScreen();
    } else if (selectedIndex == DashboardIndices.invoices) {
      title = 'Gestión de Facturas (Invoices)';
      bodyContent = const InvoicesDashboardScreen();
    } else if (selectedIndex == DashboardIndices.payroll) {
      title = 'Gestión de Nómina';
      bodyContent = const PayrollDashboardScreen();
    } else if (selectedIndex == DashboardIndices.users) {
      title = 'Usuarios';
      bodyContent = const UsersListScreen();
    } else if (selectedIndex == DashboardIndices.clients) {
      title = 'Clientes';
      bodyContent = ClientsListScreen(
        onCreateEstimate: (clientId, _) {
          AppBottomSheet.show(
            context: context,
            child: ProjectCreateDialog(initialClientId: clientId),
          ).then((success) {
            if (success == true) {
              ref.invalidate(projectListProvider);
              ref.read(dashboardIndexProvider.notifier).state =
                  DashboardIndices.projectTracking;
            }
          });
        },
      );
    } else {
      title = 'J&P Pole Barns LLC';
      bodyContent = const Center(
          child:
              Text('Bienvenido a J&P Pole Barns LLC', style: TextStyle(fontSize: 24)));
    }

    final isMenuOpen = ref.watch(sidebarExpandedProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            ref.read(sidebarExpandedProvider.notifier).state = !isMenuOpen;
          },
        ),
        title: Text(title),
        actions: actions,
      ),
      body: Row(
        children: [
          // Persistent Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isMenuOpen ? 280 : 72,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // User Info Header
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: isMenuOpen ? 24 : 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage:
                            profileAsync.asData?.value?['picture'] != null
                                ? NetworkImage(
                                    profileAsync.asData!.value!['picture'])
                                : null,
                        child: profileAsync.asData?.value?['picture'] == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isMenuOpen ? 1.0 : 0.0,
                          curve: Curves.easeInOut,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                              ],
                            ),
                          ),
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
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isMenuOpen ? 1.0 : 0.0,
                        child: isMenuOpen
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    indent: 12,
                                    endIndent: 12,
                                    color: Colors.grey[300],
                                    height: 1),
                              ),
                      ),
                      _buildMenuItem(
                        icon: Icons.person_add,
                        title: 'Clientes',
                        index: DashboardIndices.clients,
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
                        icon: Icons.group,
                        title: 'Usuarios',
                        index: DashboardIndices.users,
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        title: 'Configuración',
                        index: DashboardIndices.settings,
                      ),
                      Divider(color: Colors.grey[300], height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: InkWell(
                          onTap: () async {
                            await ref.read(authRepositoryProvider).signOut();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                const Icon(Icons.logout,
                                    color: Color(0xFF64748B), size: 22),
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
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
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
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey[300], height: 1),
                ListTile(
                  dense: true,
                  leading: Icon(
                    isMenuOpen ? Icons.chevron_left : Icons.chevron_right,
                    color: const Color(0xFF64748B),
                  ),
                  title: isMenuOpen
                      ? const Text(
                          'Contraer Menú',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                  onTap: () {
                    ref.read(sidebarExpandedProvider.notifier).state =
                        !isMenuOpen;
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon, required String title, required int index}) {
    final isMenuOpen = ref.watch(sidebarExpandedProvider);
    final selectedIndex = ref.watch(dashboardIndexProvider);
    final isSelected = selectedIndex == index;
    const activeColor = Color(0xFF92400E);
    const activeBgColor = Color(0xFFFEF3C7);
    const inactiveColor = Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => ref.read(dashboardIndexProvider.notifier).state = index,
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
