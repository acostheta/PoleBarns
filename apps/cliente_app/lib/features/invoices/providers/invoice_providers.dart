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

class InvoiceDraft {
  final String projectName;
  final String? clientId;
  final String address;
  final String comment;
  final String notes;
  final String status;
  final DateTime selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> items;

  InvoiceDraft({
    this.projectName = '',
    this.clientId,
    this.address = '',
    this.comment = '',
    this.notes = '1. Prices are based on the approximate square footage detailed above. Any variations will be adjusted accordingly during the project\'s development or upon completion.\n2. 50% of the invoice total is due upon delivery of the materials.\n3. All materials used for this project are the property of J&P Pole Barns LLC. Any remaining or unused materials will remain with the company.\n4. Any additional work requested by the client during the project will be documented, and corresponding budget adjustments will be provided.',
    this.status = 'Pendiente',
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
    this.items = const [],
  }) : selectedDate = selectedDate ?? DateTime.now(),
       startDate = startDate,
       endDate = endDate;

  InvoiceDraft copyWith({
    String? projectName,
    bool nullClientId = false,
    String? clientId,
    String? address,
    String? comment,
    String? notes,
    String? status,
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
    List<Map<String, dynamic>>? items,
  }) {
    return InvoiceDraft(
      projectName: projectName ?? this.projectName,
      clientId: nullClientId ? null : (clientId ?? this.clientId),
      address: address ?? this.address,
      comment: comment ?? this.comment,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
    );
  }
}

class InvoiceDraftNotifier extends StateNotifier<InvoiceDraft> {
  InvoiceDraftNotifier() : super(InvoiceDraft());

  void updateDraft(InvoiceDraft newDraft) {
    state = newDraft;
  }

  void clearDraft() {
    state = InvoiceDraft();
  }
}

final invoiceDraftProvider = StateNotifierProvider<InvoiceDraftNotifier, InvoiceDraft>((ref) {
  return InvoiceDraftNotifier();
});
