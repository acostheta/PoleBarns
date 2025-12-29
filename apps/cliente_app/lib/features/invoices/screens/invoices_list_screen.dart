import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/invoice_providers.dart';
import 'create_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoicesListScreen extends ConsumerWidget {
  const InvoicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider);
    final currency = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: invoicesAsync.when(
        data: (invoices) => invoices.isEmpty
            ? const Center(child: Text('No hay facturas registradas.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Invoice #${invoice.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dateFormat.format(invoice.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Cliente: ${invoice.clientName ?? "N/A"}'),
                          Text('Proyecto: ${invoice.address ?? "N/A"}'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    currency.format(invoice.totalVenta),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Saldo',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    currency.format(invoice.saldo),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: invoice.saldo > 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                InvoiceDetailScreen(invoiceId: invoice.id),
                          ),
                        ).then((_) => ref.refresh(invoicesListProvider));
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          ).then((_) => ref.refresh(invoicesListProvider));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Factura'),
      ),
    );
  }
}
