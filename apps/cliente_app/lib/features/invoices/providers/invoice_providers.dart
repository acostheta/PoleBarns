import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_models.dart';
import '../services/invoice_service.dart';
import '../../project_tracking/providers/project_providers.dart';

final invoiceServiceProvider = Provider((ref) => InvoiceService());

final selectedInvoiceIdProvider = StateProvider<int?>((ref) => null);

final invoicesListProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  return ref.watch(invoiceServiceProvider).getInvoices();
});

final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel, int>((ref, id) async {
  return ref.watch(invoiceServiceProvider).getInvoice(id);
});

final relatedProductsProvider =
    StreamProvider.family<List<RelatedProductModel>, int>((ref, invoiceId) {
  final invoiceAsync = ref.watch(invoiceStreamProvider(invoiceId));

  // If we don't have the invoice yet, return an empty stream or wait
  return invoiceAsync.when(
    data: (invoice) {
      if (invoice.idProyecto == null) {
        return Stream.value(<RelatedProductModel>[]);
      }

      // 1. Watch Project Pole Barns (The source of truth for WHAT products exist)
      final projectBarnsAsync =
          ref.watch(projectPoleBarnsStreamProvider(invoice.idProyecto!));

      // 2. Watch Invoice Related Products (The source of truth for their STATUS in this invoice)
      final invoiceProductsStream =
          ref.watch(invoiceServiceProvider).watchRelatedProducts(invoiceId);

      // 3. Combine them
      return invoiceProductsStream.map((invoiceProducts) {
        final projectBarns = projectBarnsAsync.value ?? [];

        return projectBarns.map((pb) {
          // Find if there's an existing record in Related Products for this pole barn
          // We match by idPoleBarns.
          final existing = invoiceProducts
              .where((ip) => ip.idPoleBarns == pb.poleBarnId)
              .firstOrNull;

          final qty = existing?.cantidad ?? 1.0;
          final unitPrice = pb.salePrice;
          final tax = existing?.tax ?? 0.0;
          final total = (qty * unitPrice) * (1 + (tax / 100));

          return RelatedProductModel(
            id: existing?.id ?? 0,
            idInvoice: invoiceId,
            idProyecto: invoice.idProyecto,
            idPoleBarns: pb.poleBarnId,
            estatus: existing?.estatus ?? 'Pendiente',
            cantidad: qty,
            precioPorUnidad: unitPrice, // Price from project
            tax: tax,
            totalPrice: total,
            createdAt: pb.createdAt,
            poleBarnName: pb.poleBarnName,
          );
        }).toList();
      });
    },
    loading: () => Stream.value(<RelatedProductModel>[]),
    error: (_, __) => Stream.value(<RelatedProductModel>[]),
  );
});

final invoicePaymentsProvider =
    FutureProvider.family<List<InvoicePaymentModel>, int>((ref, id) async {
  return ref.watch(invoiceServiceProvider).getInvoicePayments(id);
});

// Stream providers for real-time
final invoicesStreamProvider = StreamProvider<List<InvoiceModel>>((ref) {
  return ref.watch(invoiceServiceProvider).watchInvoices();
});

final invoiceStreamProvider =
    StreamProvider.family<InvoiceModel, int>((ref, id) {
  return ref.watch(invoiceServiceProvider).watchInvoice(id);
});

final invoiceByProjectProvider =
    FutureProvider.family<InvoiceModel?, String>((ref, projectId) async {
  final invoices = await ref.watch(invoiceServiceProvider).getInvoices();
  try {
    return invoices.firstWhere((inv) => inv.idProyecto == projectId);
  } catch (_) {
    return null;
  }
});
