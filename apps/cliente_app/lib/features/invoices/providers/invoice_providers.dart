import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_models.dart';
import '../services/invoice_service.dart';

final invoiceServiceProvider = Provider((ref) => InvoiceService());

final selectedInvoiceIdProvider = StateProvider<int?>((ref) => null);

// Deprecated: use invoicesStreamProvider instead
final invoicesListProvider = invoicesStreamProvider;

final invoiceDetailProvider = invoiceStreamProvider;

final relatedProductsProvider =
    StreamProvider.family<List<RelatedProductModel>, int>((ref, invoiceId) {
  return ref.watch(invoiceServiceProvider).watchRelatedProducts(invoiceId);
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

final invoicesByClientStreamProvider =
    StreamProvider.family<List<InvoiceModel>, String>((ref, clientId) {
  return ref.watch(invoiceServiceProvider).watchInvoicesByClient(clientId);
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
