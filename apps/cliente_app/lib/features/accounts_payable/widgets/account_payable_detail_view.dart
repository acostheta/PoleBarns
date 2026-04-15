import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/app_styles.dart';
import '../providers/accounts_payable_provider.dart';
import '../models/account_payable_model.dart';
import '../models/ap_payment_model.dart';
import '../widgets/register_payment_dialog.dart';
import '../widgets/edit_account_dialog.dart';
import '../widgets/edit_payment_dialog.dart';

class AccountPayableDetailView extends ConsumerWidget {
  final String accountId;

  const AccountPayableDetailView({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountPayableDetailProvider(accountId));
    final paymentsAsync = ref.watch(accountPaymentsProvider(accountId));
    final currency = NumberFormat.simpleCurrency();

    return accountAsync.when(
      data: (account) => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.provider?.name ?? 'Proveedor',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Factura: ${account.invoiceInternRef ?? "Sin referencia"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _showEditAccountDialog(context, ref, account),
                      tooltip: 'Editar Cuenta',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _confirmDeleteAccount(context, ref, account),
                      tooltip: 'Eliminar Cuenta',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final cards = [
                  _buildStatCard(
                    'Total Factura',
                    currency.format(account.totalAmount),
                    Icons.receipt_long_outlined,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Total Pagado',
                    currency.format(account.totalPaid),
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Saldo Pendiente',
                    currency.format(account.currentBalance),
                    Icons.warning_amber_outlined,
                    account.currentBalance > 0 ? Colors.orange : Colors.green,
                  ),
                ];

                if (isMobile) {
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 16),
                      cards[1],
                      const SizedBox(height: 16),
                      cards[2],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[2]),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Account Details
            _buildDetailsSection(account),

            const SizedBox(height: 32),

            // Payments Section
            _buildPaymentsSection(context, ref, account, paymentsAsync),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
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
  }

  Widget _buildDetailsSection(AccountPayableModel account) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la Cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Proveedor', account.provider?.name ?? 'N/A'),
          _buildDetailRow('Dirección', account.provider?.address ?? 'N/A'),
          _buildDetailRow('Fecha de Factura',
              DateFormat('dd/MM/yyyy').format(account.invoiceDate)),
          if (account.projectName != null)
            _buildDetailRow('Proyecto', account.projectName!),
          if (account.invoiceInternRef != null)
            _buildDetailRow('Referencia Interna', account.invoiceInternRef!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection(
    BuildContext context,
    WidgetRef ref,
    AccountPayableModel account,
    AsyncValue<List<APPaymentModel>> paymentsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pagos Realizados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPaymentDialog(context, ref, account),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Registrar Pago'),
                style: AppStyles.primaryButtonStyle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.payment_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No hay pagos registrados',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: payments.map((payment) {
                  return _buildPaymentItem(context, ref, payment);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: $error',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
      BuildContext context, WidgetRef ref, APPaymentModel payment) {
    final currency = NumberFormat.simpleCurrency();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency.format(payment.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(payment.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (payment.paymentMethod != null)
                  Text(
                    'Método: ${payment.paymentMethod!.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: Colors.blue,
            onPressed: () => _showEditPaymentDialog(context, ref, payment),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: () => _confirmDeletePayment(context, ref, payment),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(
      BuildContext context, WidgetRef ref, AccountPayableModel account) {
    showDialog(
      context: context,
      builder: (context) => EditAccountDialog(account: account),
    );
  }

  void _showAddPaymentDialog(
      BuildContext context, WidgetRef ref, AccountPayableModel account) {
    showDialog(
      context: context,
      builder: (context) => RegisterPaymentDialog(account: account),
    );
  }

  void _showEditPaymentDialog(
      BuildContext context, WidgetRef ref, APPaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => EditPaymentDialog(payment: payment),
    );
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref, AccountPayableModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text(
          '¿Está seguro de que desea eliminar esta cuenta por pagar de ${account.provider?.name ?? "este proveedor"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(accountsPayableRepositoryProvider)
            .deleteAccount(account.id);
        ref.read(selectedAccountPayableIdProvider.notifier).state = null;
        ref.invalidate(accountsPayableListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta eliminada exitosamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeletePayment(
      BuildContext context, WidgetRef ref, APPaymentModel payment) async {
    final currency = NumberFormat.simpleCurrency();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Pago'),
        content: Text(
          '¿Está seguro de que desea eliminar este pago de ${currency.format(payment.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(accountsPayableRepositoryProvider)
            .deletePayment(payment.id);
        ref.invalidate(accountPaymentsProvider(accountId));
        ref.invalidate(accountPayableDetailProvider(accountId));
        ref.invalidate(accountsPayableListProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }
}
