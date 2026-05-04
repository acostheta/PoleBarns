import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_bar_portal.dart';
import '../../../config/app_styles.dart';

// Providers
import '../../project_tracking/providers/project_providers.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../accounts_payable/providers/accounts_payable_provider.dart';

// Models
import '../../project_tracking/models/project_models.dart';
import '../../invoices/models/invoice_models.dart';
import '../../accounts_payable/models/account_payable_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final invoicesAsync = ref.watch(invoicesStreamProvider);
    final accountsAsync = ref.watch(accountsPayableListProvider);
    final clientsAsync = ref.watch(clientListProvider);

    return Scaffold(
      backgroundColor: AppStyles.stoneWhite,
      body: Column(
        children: [
          const AppBarPortal(
            title: 'Dashboard',
            actions: [],
          ),
          Expanded(
            child: RefreshIndicator(
        onRefresh: () async {
          // Invalidate providers to force refresh
          ref.invalidate(projectListProvider);
          ref.invalidate(invoicesStreamProvider);
          ref.invalidate(accountsPayableListProvider);
          ref.invalidate(clientListProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              const Text(
                'Resumen General',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              _buildStatsGrid(
                  projectsAsync, invoicesAsync, accountsAsync, clientsAsync),

              const SizedBox(height: 32),

              // Recent Activity Sections
              MediaQuery.of(context).size.width < 800
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSection(
                          title: 'Proyectos Recientes',
                          icon: Icons.assignment_outlined,
                          color: Colors.blue,
                          child: _buildRecentProjectsList(
                              context, projectsAsync, clientsAsync),
                          onViewAll: () => context.go('/projects'),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Facturas Recientes',
                          icon: Icons.receipt_long_outlined,
                          color: Colors.orange,
                          child:
                              _buildRecentInvoicesList(context, invoicesAsync),
                          onViewAll: () => context.go('/invoices'),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recent Projects
                        Expanded(
                          child: _buildSection(
                            title: 'Proyectos Recientes',
                            icon: Icons.assignment_outlined,
                            color: Colors.blue,
                            child: _buildRecentProjectsList(
                                context, projectsAsync, clientsAsync),
                            onViewAll: () => context.go('/projects'),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Pending Invoices or Recent Invoices
                        Expanded(
                          child: _buildSection(
                            title: 'Facturas Recientes',
                            icon: Icons.receipt_long_outlined,
                            color: Colors.orange,
                            child: _buildRecentInvoicesList(
                                context, invoicesAsync),
                            onViewAll: () => context.go('/invoices'),
                          ),
                        ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildStatsGrid(
    AsyncValue<List<ProjectModel>> projectsAsync,
    AsyncValue<List<InvoiceModel>> invoicesAsync,
    AsyncValue<List<AccountPayableModel>> accountsAsync,
    AsyncValue<List<ClientSimpleModel>> clientsAsync,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      // Prepare Data
      final activeProjectsCount = projectsAsync.valueOrNull
              ?.where((p) =>
                  p.estatus == 'En Progreso' ||
                  p.estatus == 'In Progress' ||
                  p.estatus == 'Activo') // Adjust based on actual status values
              .length ??
          0;

      final totalClientsCount = clientsAsync.valueOrNull?.length ?? 0;

      final pendingInvoicesBalance =
          invoicesAsync.valueOrNull?.fold(0.0, (sum, inv) => sum + inv.saldo) ??
              0.0;

      final pendingAPBalance = accountsAsync.valueOrNull
              ?.fold(0.0, (sum, ap) => sum + ap.currentBalance) ??
          0.0;

      final width = MediaQuery.of(context).size.width;

      if (width < 600) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                title: 'Proyectos Activos',
                value: activeProjectsCount.toString(),
                icon: Icons.construction,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                title: 'Clientes',
                value: totalClientsCount.toString(),
                icon: Icons.people_outline,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                title: 'Por Cobrar',
                value: NumberFormat.simpleCurrency()
                    .format(pendingInvoicesBalance),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                title: 'Por Pagar',
                value: NumberFormat.simpleCurrency().format(pendingAPBalance),
                icon: Icons.money_off,
                color: Colors.redAccent,
              ),
            ),
          ],
        );
      } else if (width < 1200) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Proyectos Activos',
                    value: activeProjectsCount.toString(),
                    icon: Icons.construction,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Clientes',
                    value: totalClientsCount.toString(),
                    icon: Icons.people_outline,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Por Cobrar',
                    value: NumberFormat.simpleCurrency()
                        .format(pendingInvoicesBalance),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Por Pagar',
                    value:
                        NumberFormat.simpleCurrency().format(pendingAPBalance),
                    icon: Icons.money_off,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
              child: _StatCard(
            title: 'Proyectos Activos',
            value: activeProjectsCount.toString(),
            icon: Icons.construction,
            color: Colors.blue,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _StatCard(
            title: 'Clientes',
            value: totalClientsCount.toString(),
            icon: Icons.people_outline,
            color: Colors.purple,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _StatCard(
            title: 'Por Cobrar',
            value: NumberFormat.simpleCurrency().format(pendingInvoicesBalance),
            icon: Icons.attach_money,
            color: Colors.green,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _StatCard(
            title: 'Por Pagar',
            value: NumberFormat.simpleCurrency().format(pendingAPBalance),
            icon: Icons.money_off,
            color: Colors.redAccent,
          )),
        ],
      );
    });
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    required VoidCallback onViewAll,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('Ver Todo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRecentProjectsList(
      BuildContext context,
      AsyncValue<List<ProjectModel>> projectsAsync,
      AsyncValue<List<ClientSimpleModel>> clientsAsync) {
    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) return const Text('Sin proyectos recientes.');

        // Sort by created_at descending and take 5
        final sorted = List<ProjectModel>.from(projects)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recent = sorted.take(5).toList();

        return Column(
          children: recent.map((p) {
            final client = clientsAsync.valueOrNull?.firstWhere(
                (c) => c.id == p.refCliente,
                orElse: () => ClientSimpleModel(
                    id: '', firstName: '', lastName: 'Unknown'));

            final displayAddress =
                (p.direccion != null && p.direccion!.isNotEmpty)
                    ? p.direccion!
                    : (client?.address ?? (p.address ?? 'Sin dirección'));

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2FE),
                child:
                    Icon(Icons.folder_outlined, color: Colors.blue, size: 20),
              ),
              title: Text(p.address ?? 'Proyecto',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${client?.fullName ?? "N/A"} - $displayAddress',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing:
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              onTap: () => context.go('/projects/${p.id}'),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error cargando proyectos'),
    );
  }

  Widget _buildRecentInvoicesList(
      BuildContext context, AsyncValue<List<InvoiceModel>> invoicesAsync) {
    return invoicesAsync.when(
      data: (invoices) {
        if (invoices.isEmpty) return const Text('Sin facturas recientes.');

        // Sort by date descending and take 5
        final sorted = List<InvoiceModel>.from(invoices)
          ..sort((a, b) => b.date.compareTo(a.date));
        final recent = sorted.take(5).toList();
        final currency = NumberFormat.simpleCurrency();

        return Column(
          children: recent
              .map((inv) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: (inv.saldo > 0)
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDCFCE7),
                      child: Icon(
                          (inv.saldo > 0) ? Icons.pending_actions : Icons.check,
                          color: (inv.saldo > 0) ? Colors.red : Colors.green,
                          size: 20),
                    ),
                    title: Text(inv.clientName ?? 'Cliente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      'Factura #${inv.id} - ${DateFormat('MM/dd').format(inv.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currency.format(inv.totalVenta),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    onTap: () {
                      // Navigation logic might differ, assuming invoices detail route exists or edit
                      context.go(
                          '/invoices/${inv.id}/edit'); // Using edit route as detail for now
                    },
                  ))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error cargando facturas'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
