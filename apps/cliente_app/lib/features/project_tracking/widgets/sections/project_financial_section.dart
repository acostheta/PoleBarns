import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/project_models.dart';
import '../../providers/project_providers.dart';
import '../../../accounts_payable/widgets/add_account_dialog.dart';
import '../../../invoices/providers/invoice_providers.dart';
import '../../../invoices/widgets/add_payment_dialog.dart';

class ProjectFinancialSection extends ConsumerWidget {
  final ProjectModel project;

  const ProjectFinancialSection({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(projectInvoiceBalanceProvider(project.id));
    final apTotalAsync =
        ref.watch(projectAccountsPayableTotalProvider(project.id));
    final incomesAsync = ref.watch(projectIncomesProvider(project.id));
    final clientBalanceAsync =
        ref.watch(projectClientBalanceProvider(project.id));
    final invoiceAsync = ref.watch(invoiceByProjectProvider(project.id));
    final currency = NumberFormat.simpleCurrency();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
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
                'Costos del Proyecto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: invoiceAsync.when(
                      data: (invoice) => invoice == null
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (_) => AddPaymentDialog(
                                  invoiceId: invoice.id,
                                  onAdded: () {
                                    ref.invalidate(invoicesStreamProvider);
                                  },
                                ),
                              );
                            },
                      loading: () => null,
                      error: (_, __) => null,
                    ),
                    icon: const Icon(Icons.account_balance_wallet, size: 20),
                    label: const Text('Añadir Ingreso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AddAccountDialog(initialProjectId: project.id),
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Añadir Costo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _FinancialCard(
                label: 'Venta Total',
                amount: currency.format(project.ventaTotal),
                bg: const Color(0xFFFAFAF9), // Stone-50
                borderColor: const Color(0xFFD6D3D1),
                textColor: const Color(0xFF1F2937),
              ),
              _FinancialCard(
                label: 'Ingresos del proyecto',
                amount: incomesAsync.when(
                  data: (val) => currency.format(val),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                bg: const Color(0xFFEFF6FF), // Blue-50
                borderColor: const Color(0xFFBFDBFE), // Blue-200
                textColor: const Color(0xFF1E40AF), // Blue-800
              ),
              _FinancialCard(
                label: 'Saldo Cliente',
                amount: clientBalanceAsync.when(
                  data: (val) => currency.format(val),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                bg: const Color(0xFFFEFCE8), // Yellow-50
                borderColor: const Color(0xFFFEF08A), // Yellow-200
                textColor: const Color(0xFF854D0E), // Yellow-800
                tooltip:
                    'Venta Total - Ingresos (cuánto le falta al cliente por pagar)',
              ),
              _FinancialCard(
                label: 'Costo Total',
                amount: apTotalAsync.when(
                  data: (val) => currency.format(val),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                bg: const Color(0xFFFAFAF9), // Stone-50
                borderColor: const Color(0xFFD6D3D1),
                textColor: const Color(0xFF1F2937),
              ),
              _FinancialCard(
                label: 'Balance',
                amount: balanceAsync.when(
                  data: (val) => currency.format(val),
                  loading: () => '...',
                  error: (_, __) => 'Error',
                ),
                bg: const Color(0xFFF0FDF4), // Green-50
                borderColor: const Color(0xFF86EFAC), // Green-300
                textColor: const Color(0xFF15803D), // Green-700
                isBold: true,
                tooltip:
                    'Venta Total - Costo total (cuánto se ha gastado vs. lo estimado)',
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color bg;
  final Color borderColor;
  final Color textColor;
  final bool isBold;
  final String? tooltip;

  const _FinancialCard({
    required this.label,
    required this.amount,
    required this.bg,
    required this.borderColor,
    required this.textColor,
    this.isBold = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700])),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: false,
        child: content,
      );
    }

    return content;
  }
}
