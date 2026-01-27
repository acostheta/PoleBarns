import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invoice_providers.dart';
import 'invoices_list_screen.dart';
import 'invoice_detail_screen.dart';

class InvoicesDashboardScreen extends ConsumerWidget {
  const InvoicesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left Panel: Invoices List
        const SizedBox(
          width: 320,
          child: InvoicesListScreen(),
        ),

        // Vertical Divider
        VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),

        // Right Panel: Invoice Detail
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final selectedId = ref.watch(selectedInvoiceIdProvider);
              if (selectedId == null) {
                return const Center(
                  child: Text(
                    'Seleccione una factura para ver los detalles',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }
              return InvoiceDetailScreen(
                invoiceId: selectedId,
                showAppBar: false,
                key: ValueKey(selectedId),
              );
            },
          ),
        ),
      ],
    );
  }
}
