import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_models.dart';
import '../services/invoice_service.dart';

final invoiceServiceProvider = Provider((ref) => InvoiceService());

final invoicesListProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  return ref.watch(invoiceServiceProvider).getInvoices();
});

final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel, int>((ref, id) async {
  return ref.watch(invoiceServiceProvider).getInvoice(id);
});

final relatedProductsProvider =
    FutureProvider.family<List<RelatedProductModel>, int>((ref, id) async {
  return ref.watch(invoiceServiceProvider).getRelatedProducts(id);
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
