import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/project_providers.dart';
import '../../accounts_payable/widgets/add_account_dialog.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../invoices/widgets/add_payment_dialog.dart';

class CostsTab extends ConsumerWidget {
  final String projectId;

  const CostsTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apListAsync =
        ref.watch(projectAccountsPayableListProvider(projectId));
    final balanceAsync = ref.watch(projectInvoiceBalanceProvider(projectId));
    final apTotalAsync =
        ref.watch(projectAccountsPayableTotalProvider(projectId));
    final incomesAsync = ref.watch(projectIncomesProvider(projectId));
    final clientBalanceAsync =
        ref.watch(projectClientBalanceProvider(projectId));
    final invoiceAsync = ref.watch(invoiceByProjectProvider(projectId));

    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      body: Column(
        children: [
          // Financial Summary Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Panel Financiero',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: invoiceAsync.when(
                            data: (invoice) => invoice == null
                                ? null
                                : () => _showAddPaymentDialog(
                                    context, invoice.id, ref),
                            loading: () => null,
                            error: (_, __) => null,
                          ),
                          icon:
                              const Icon(Icons.account_balance_wallet_outlined),
                          tooltip: 'Añadir Ingreso',
                          color: Colors.blue[700],
                        ),
                        IconButton(
                          onPressed: () => _showAddAccountDialog(context),
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Añadir Costo',
                          color: Colors.orange[800],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing between header and stats
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatItem(
                        'Balance',
                        balanceAsync.when(
                          data: (v) => currency.format(v),
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        ),
                        Colors.green,
                        tooltip:
                            'Venta Total - Costo total (cuánto se ha gastado vs. lo estimado)',
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        'Ingresos',
                        incomesAsync.when(
                          data: (v) => currency.format(v),
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        ),
                        Colors.blue,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        'Saldo',
                        clientBalanceAsync.when(
                          data: (v) => currency.format(v),
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        ),
                        Colors.yellow.shade900,
                        tooltip:
                            'Venta Total - Ingresos (cuánto le falta al cliente por pagar)',
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        'Costo Total',
                        apTotalAsync.when(
                          data: (v) => currency.format(v),
                          loading: () => '...',
                          error: (_, __) => 'Error',
                        ),
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: apListAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(
                      child: Text('No hay costos registrados.'));
                }
                return ListView.builder(
                  itemCount: accounts.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Card(
                      key: ValueKey(account.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.receipt_outlined,
                              color: Colors.orange.shade800),
                        ),
                        title: Text(account.provider?.name ?? 'S/N'),
                        subtitle: Text(
                            'Ref: ${account.invoiceInternRef ?? 'Sin ref.'} | ${DateFormat('MM/dd/yyyy').format(account.invoiceDate)}'),
                        trailing: Text(
                          currency.format(account.totalAmount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context),
        label: const Text('Añadir Costo'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange[800],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildStatItem(String label, String value, Color color,
      {String? tooltip}) {
    Widget content = Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 12, color: Colors.grey[400]),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        child: content,
      );
    }

    return content;
  }

  void _showAddPaymentDialog(
      BuildContext context, int invoiceId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(
        invoiceId: invoiceId,
        onAdded: () {
          ref.invalidate(invoicesStreamProvider);
        },
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddAccountDialog(initialProjectId: projectId),
    );
  }
}
