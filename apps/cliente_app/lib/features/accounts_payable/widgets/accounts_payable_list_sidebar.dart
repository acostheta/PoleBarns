import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../providers/accounts_payable_provider.dart';
import '../models/account_payable_model.dart';
import '../widgets/add_account_dialog.dart';

class AccountsPayableListSidebar extends ConsumerWidget {
  const AccountsPayableListSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsPayableListProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final currency = NumberFormat.simpleCurrency();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cuentas por Pagar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppStyles.primaryOrange),
                      onPressed: () => _showAddAccountDialog(context, ref),
                      tooltip: 'Nueva Factura',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats Cards
                _buildStatCard(
                  'Total Deuda',
                  currency.format(stats['totalDebt'] ?? 0),
                  Icons.receipt_long_outlined,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Total Pagado',
                  currency.format(stats['totalPaid'] ?? 0),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildStatCard(
                  'Saldo Pendiente',
                  currency.format(stats['pendingBalance'] ?? 0),
                  Icons.warning_amber_outlined,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Accounts List
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay cuentas por pagar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _AccountListTile(account: account);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );
  }
}

class _AccountListTile extends ConsumerWidget {
  final AccountPayableModel account;

  const _AccountListTile({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedAccountPayableIdProvider);
    final isSelected = selectedId == account.id;
    final currency = NumberFormat.simpleCurrency();
    final isPaid = account.currentBalance <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppStyles.primaryOrange.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppStyles.primaryOrange : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          ref.read(selectedAccountPayableIdProvider.notifier).state =
              account.id;
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.pending_outlined,
            color: isPaid ? Colors.green : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          account.provider?.name ?? 'Proveedor',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (account.invoiceInternRef != null)
              Text(
                'Ref: ${account.invoiceInternRef}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            Text(
              DateFormat('dd/MM/yyyy').format(account.invoiceDate),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo:',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  currency.format(account.currentBalance),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
