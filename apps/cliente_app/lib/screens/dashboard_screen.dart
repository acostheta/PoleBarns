import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auth/auth.dart';
import 'package:users/users.dart';
import 'package:clients/clients.dart';
import 'package:measures/measures.dart';

import '../features/settings/screens/settings_screen.dart';
import '../features/accounts_payable/screens/accounts_payable_screen.dart';
import '../features/project_tracking/screens/project_dashboard_screen.dart';
import '../features/pole_barns/screens/pole_barns_list_screen.dart';
import '../features/invoices/screens/invoices_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isMenuOpen = true;

  // Pages
  static const int _homeIndex = 0;
  static const int _profileIndex = 1;
  static const int _usersIndex = 2;
  static const int _jobsIndex = 3;
  static const int _clientsIndex = 4;
  static const int _measuresIndex = 5;
  static const int _settingsIndex = 6;
  static const int _accountsPayableIndex = 7;
  static const int _projectTrackingIndex = 8;
  static const int _poleBarnsIndex = 9;
  static const int _invoicesIndex = 10;

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

    if (_selectedIndex == _profileIndex) {
      title = 'Mi Perfil';
      bodyContent = const ProfileScreen();
    } else if (_selectedIndex == _usersIndex) {
      title = 'Gestión de Usuarios';
      bodyContent = const UsersListScreen();
      actions = [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.refresh(allUsersProvider),
        ),
      ];
    } else if (_selectedIndex == _jobsIndex) {
      title = 'Puestos de Trabajo'; // Title: Job Positions
      bodyContent = const JobPositionsScreen();
    } else if (_selectedIndex == _clientsIndex) {
      title = 'Gestión de Clientes';
      bodyContent = const ClientsListScreen();
    } else if (_selectedIndex == _measuresIndex) {
      title = 'Unidades de Medida';
      bodyContent = const MeasuresScreen();
    } else if (_selectedIndex == _settingsIndex) {
      title = 'Configuración';
      bodyContent = const SettingsScreen();
    } else if (_selectedIndex == _accountsPayableIndex) {
      title = 'Cuentas por Pagar';
      bodyContent = const AccountsPayableScreen();
    } else if (_selectedIndex == _projectTrackingIndex) {
      title = 'Seguimiento de Obra';
      bodyContent = const ProjectDashboardScreen();
    } else if (_selectedIndex == _poleBarnsIndex) {
      title = 'Cotizador de Caballerizas (Pole Barns)';
      bodyContent = const PoleBarnsListScreen();
    } else if (_selectedIndex == _invoicesIndex) {
      title = 'Gestión de Facturas (Invoices)';
      bodyContent = const InvoicesListScreen();
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
                              index: _homeIndex,
                            ),
                            _buildMenuItem(
                              icon: Icons.person,
                              title: 'Mi Perfil',
                              index: _profileIndex,
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
                                icon: Icons.people,
                                title: 'Usuarios',
                                index: _usersIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.work,
                                title: 'Puestos de Trabajo',
                                index: _jobsIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.business,
                                title: 'Clientes',
                                index: _clientsIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.square_foot,
                                title: 'Medidas',
                                index: _measuresIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.settings,
                                title: 'Configuración',
                                index: _settingsIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.attach_money,
                                title: 'Cuentas por Pagar',
                                index: _accountsPayableIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.construction,
                                title: 'Seguimiento de Obra',
                                index: _projectTrackingIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.architecture,
                                title: 'Pole Barns',
                                index: _poleBarnsIndex,
                              ),
                              _buildMenuItem(
                                icon: Icons.receipt_long,
                                title: 'Invoices',
                                index: _invoicesIndex,
                              ),
                            ],
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('Cerrar Sesión'),
                              onTap: () async {
                                await ref
                                    .read(authRepositoryProvider)
                                    .signOut();
                                // Router handles redirect to login
                              },
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
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading:
          Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
      },
    );
  }
}
