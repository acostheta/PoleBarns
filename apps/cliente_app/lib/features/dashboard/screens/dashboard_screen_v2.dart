import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../project_tracking/providers/project_providers.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../accounts_payable/providers/accounts_payable_provider.dart';
import '../../project_tracking/models/project_models.dart';
import '../../invoices/models/invoice_models.dart';
import '../../accounts_payable/models/account_payable_model.dart';
import '../../../config/ui_helpers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _primaryColor = Color(0xFF173124);
  static const _secondaryColor = Color(0xFF7C580F);
  static const _surfaceContainer = Color(0xFFEDEEEB);
  static const _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const _surfaceContainerHigh = Color(0xFFE7E8E6);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _secondaryFixed = Color(0xFFFFDEAC);
  static const _errorColor = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final invoicesAsync = ref.watch(invoicesStreamProvider);
    final accountsAsync = ref.watch(accountsPayableListProvider);
    final clientsAsync = ref.watch(clientListProvider);

    

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectListProvider);
          ref.invalidate(invoicesStreamProvider);
          ref.invalidate(accountsPayableListProvider);
          ref.invalidate(clientListProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildKPIGrid(projectsAsync, clientsAsync, invoicesAsync, accountsAsync),
              const SizedBox(height: 48),
              _buildContentColumns(context, projectsAsync, clientsAsync, invoicesAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: _primaryColor,
            letterSpacing: -1,
          ),
        ),
        Row(
          children: [
            Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: _secondaryFixed,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Resumen General',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF727973),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIGrid(
    AsyncValue<List<ProjectModel>> projectsAsync,
    AsyncValue<List<ClientSimpleModel>> clientsAsync,
    AsyncValue<List<InvoiceModel>> invoicesAsync,
    AsyncValue<List<AccountPayableModel>> accountsAsync,
  ) {
    final activeProjects = projectsAsync.valueOrNull
            ?.where((p) => p.estatus == 'En Progreso' || p.estatus == 'In Progress' || p.estatus == 'Activo')
            .length ?? 0;
    final totalClients = clientsAsync.valueOrNull?.length ?? 0;
    final porCobrar = invoicesAsync.valueOrNull?.fold(0.0, (sum, inv) => sum + inv.saldo) ?? 0.0;
    final porPagar = accountsAsync.valueOrNull?.fold(0.0, (sum, ap) => sum + ap.currentBalance) ?? 0.0;

    final currencyFormat = NumberFormat.simpleCurrency();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _buildKPICard(
                title: 'Proyectos Activos',
                value: activeProjects.toString(),
                subtitle: 'Active',
                icon: Icons.architecture,
                iconColor: _primaryColor,
                iconBg: const Color(0xFFCCEAD6),
              ),
              const SizedBox(height: 24),
              _buildKPICard(
                title: 'Clientes',
                value: totalClients.toString(),
                subtitle: 'Growth',
                icon: Icons.group,
                iconColor: _secondaryColor,
                iconBg: const Color(0xFFFEF3C7),
              ),
              const SizedBox(height: 24),
              _buildKPICard(
                title: 'Por Cobrar',
                value: currencyFormat.format(porCobrar),
                subtitle: '+12.5%',
                icon: Icons.payments,
                iconColor: const Color(0xFF3B4D14),
                iconBg: const Color(0xFFD4ECA2),
              ),
              const SizedBox(height: 24),
              _buildKPICard(
                title: 'Por Pagar',
                value: currencyFormat.format(porPagar),
                subtitle: 'Current',
                icon: Icons.account_balance_wallet,
                iconColor: _errorColor,
                iconBg: const Color(0xFFFFDAD6),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildKPICard(
              title: 'Proyectos Activos',
              value: activeProjects.toString(),
              subtitle: 'Active',
              icon: Icons.architecture,
              iconColor: _primaryColor,
              iconBg: const Color(0xFFCCEAD6),
            )),
            const SizedBox(width: 24),
            Expanded(child: _buildKPICard(
              title: 'Clientes',
              value: totalClients.toString(),
              subtitle: 'Growth',
              icon: Icons.group,
              iconColor: _secondaryColor,
              iconBg: const Color(0xFFFEF3C7),
            )),
            const SizedBox(width: 24),
            Expanded(child: _buildKPICard(
              title: 'Por Cobrar',
              value: currencyFormat.format(porCobrar),
              subtitle: '+12.5%',
              icon: Icons.payments,
              iconColor: const Color(0xFF3B4D14),
              iconBg: const Color(0xFFD4ECA2),
            )),
            const SizedBox(width: 24),
            Expanded(child: _buildKPICard(
              title: 'Por Pagar',
              value: currencyFormat.format(porPagar),
              subtitle: 'Current',
              icon: Icons.account_balance_wallet,
              iconColor: _errorColor,
              iconBg: const Color(0xFFFFDAD6),
            )),
          ],
        );
      },
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2C8C2).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF727973),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF727973),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentColumns(
    BuildContext context,
    AsyncValue<List<ProjectModel>> projectsAsync,
    AsyncValue<List<ClientSimpleModel>> clientsAsync,
    AsyncValue<List<InvoiceModel>> invoicesAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _buildRecentProjectsSection(context, projectsAsync, clientsAsync),
              const SizedBox(height: 32),
              _buildRecentInvoicesSection(context, invoicesAsync, clientsAsync),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildRecentProjectsSection(context, projectsAsync, clientsAsync),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _buildRecentInvoicesSection(context, invoicesAsync, clientsAsync),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentProjectsSection(
    BuildContext context,
    AsyncValue<List<ProjectModel>> projectsAsync,
    AsyncValue<List<ClientSimpleModel>> clientsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proyectos Recientes',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/projects'),
                child: const Row(
                  children: [
                    Text(
                      'Ver Todo',
                      style: TextStyle(
                        color: _secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14, color: _secondaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          projectsAsync.when(
            data: (projects) {
              if (projects.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Sin proyectos recientes.', style: TextStyle(color: Color(0xFF727973))),
                );
              }
              final sorted = List<ProjectModel>.from(projects)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final recent = sorted.take(5).toList();

              return Column(
                children: recent.map((project) {
                  final client = clientsAsync.valueOrNull?.firstWhere(
                    (c) => c.id == project.refCliente,
                    orElse: () => ClientSimpleModel(id: '', firstName: '', lastName: 'Unknown'),
                  );

                  final clientName = client != null ? '${client.firstName} ${client.lastName}' : 'Unknown';
                  final stage = project.estatus ?? 'Planning';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => context.go('/projects/${project.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.folder_outlined, color: Color(0xFF496455), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pole Barn Construction • Stage: $stage',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: Color(0xFF727973),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFFD9DAD8)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error cargando proyectos'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoicesSection(
    BuildContext context,
    AsyncValue<List<InvoiceModel>> invoicesAsync,
    AsyncValue<List<ClientSimpleModel>> clientsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Facturas Recientes',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/invoices'),
                child: const Row(
                  children: [
                    Text(
                      'Ver Todo',
                      style: TextStyle(
                        color: _secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 14, color: _secondaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          invoicesAsync.when(
            data: (invoices) {
              if (invoices.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Sin facturas recientes.', style: TextStyle(color: Color(0xFF727973))),
                );
              }
              final sorted = List<InvoiceModel>.from(invoices)
                ..sort((a, b) => b.date.compareTo(a.date));
              final recent = sorted.take(5).toList();
              final currencyFormat = NumberFormat.simpleCurrency();

              return Column(
                children: recent.map((invoice) {
                  final client = clientsAsync.valueOrNull?.firstWhere(
                    (c) => c.id == invoice.idCliente,
                    orElse: () => ClientSimpleModel(id: '', firstName: '', lastName: 'Unknown'),
                  );
                  final clientName = client != null ? '${client.firstName} ${client.lastName}' : (invoice.clientName ?? 'Unknown');
                  
                  String statusLabel;
                  Color statusBg;
                  Color statusText;
                  
                  if (invoice.saldo <= 0) {
                    statusLabel = 'Paid';
                    statusBg = const Color(0xFFDCFCE7);
                    statusText = const Color(0xFF16A34A);
                  } else if (invoice.status == 'Sent' || invoice.status == 'Enviada') {
                    statusLabel = 'Sent';
                    statusBg = const Color(0xFFFEF3C7);
                    statusText = _secondaryColor;
                  } else if (invoice.status == 'Vencida' || invoice.status == 'Overdue') {
                    statusLabel = 'Overdue';
                    statusBg = const Color(0xFFFEE2E2);
                    statusText = _errorColor;
                  } else {
                    statusLabel = 'Pending';
                    statusBg = const Color(0xFFFEF3C7);
                    statusText = _secondaryColor;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => context.go('/invoices/${invoice.id}/edit'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.receipt, color: _secondaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'REF: ${invoice.id}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF727973),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(invoice.totalVenta),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: statusText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error cargando facturas'),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add, color: _primaryColor),
              title: const Text('Nuevo Cliente'),
              onTap: () {
                Navigator.pop(context);
                context.go('/clients/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: _primaryColor),
              title: const Text('Nuevo Proyecto'),
              onTap: () {
                Navigator.pop(context);
                context.go('/projects/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: _primaryColor),
              title: const Text('Nueva Factura'),
              onTap: () {
                Navigator.pop(context);
                context.go('/invoices/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt, color: _primaryColor),
              title: const Text('Nuevo Usuario'),
              onTap: () {
                Navigator.pop(context);
                context.go('/users/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}