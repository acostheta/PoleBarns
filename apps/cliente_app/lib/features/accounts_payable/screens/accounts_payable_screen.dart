import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/accounts_payable_provider.dart';
import '../models/account_payable_model.dart';
import '../widgets/add_account_dialog.dart';
import '../widgets/register_payment_dialog.dart';

class AccountsPayableScreen extends ConsumerWidget {
  const AccountsPayableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsPayableListProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Pagar'),
      ),
      body: Column(
        children: [
          // Dashboard Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Total Deuda',
                  amount: stats['totalDebt']!,
                  color: Colors.orange,
                  isMoney: true,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  title: 'Total Pagado',
                  amount: stats['totalPaid']!,
                  color: Colors.green,
                  isMoney: true,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  title: 'Por Pagar',
                  amount: stats['pendingBalance']!,
                  color: Colors.redAccent,
                  isMoney: true,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: accountsState.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(
                      child: Text('No hay cuentas registradas'));
                }
                return ListView.builder(
                  itemCount: accounts.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _AccountListItem(account: account);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddAccountDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    bool isMoney = false,
  }) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              isMoney ? currencyFormat.format(amount) : amount.toString(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountListItem extends StatelessWidget {
  final AccountPayableModel account;

  const _AccountListItem({required this.account});

  @override
  Widget build(BuildContext context) {
    final isPaid = account.currentBalance <= 0;
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPaymentDialog(context, account),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    account.provider?.name ?? 'Proveedor Desconocido',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isPaid ? 'SALDADO' : 'PENDIENTE',
                      style: TextStyle(
                        color: isPaid ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${dateFormat.format(account.invoiceDate)}'),
              if (account.invoiceInternRef != null)
                Text('Ref: ${account.invoiceInternRef}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(currencyFormat.format(account.totalAmount)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Abonado',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(currencyFormat.format(account.totalPaid),
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Saldo',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        currencyFormat.format(account.currentBalance),
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, AccountPayableModel account) {
    if (account.currentBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta cuenta ya está saldada.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => RegisterPaymentDialog(account: account),
    );
  }
}
