import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../../invoices/screens/invoice_detail_screen.dart';
import '../models/project_models.dart';

class FinancialTab extends ConsumerWidget {
  final ProjectModel project;

  const FinancialTab({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: ProjectModel usage here assumes it's updated in real-time by the parent watching the stream provider.
    // If specific fields need faster updates than the list, we might need a dedicated stream.
    // Given the architecture, the parent ProjectDetailScreen watches the list provider which is a stream, so it should update.

    final currency = NumberFormat.simpleCurrency();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FinancialCard(
            title: 'Profit (Ganancia)',
            amount: project.profit,
            color: project.profit >= 0 ? Colors.green : Colors.red,
            isLarge: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FinancialCard(
                  title: 'Venta Total',
                  amount: project.ventaTotal,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FinancialCard(
                  title: 'Costos Totales',
                  amount: project.costosTotales,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ref.watch(invoiceByProjectProvider(project.id)).when(
                data: (invoice) => invoice != null
                    ? ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InvoiceDetailScreen(invoiceId: invoice.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Ver Factura (Invoice)'),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                            'Aún no se ha generado factura para este proyecto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                loading: () => const LinearProgressIndicator(),
                error: (e, __) => Text('Error al buscar factura: $e'),
              ),
          // TODO: Add graphs here in future
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final bool isLarge;

  const _FinancialCard({
    required this.title,
    required this.amount,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();

    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isLarge ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isLarge ? 8 : 4),
          Text(
            currency.format(amount),
            style: TextStyle(
              color: color,
              fontSize: isLarge ? 32 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
