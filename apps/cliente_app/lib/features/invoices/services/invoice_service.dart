import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_models.dart';

class InvoiceService {
  final _supabase = Supabase.instance.client;

  Stream<List<InvoiceModel>> watchInvoices() {
    return _supabase
        .from('Invoices')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => InvoiceModel.fromJson(e)).toList());
  }

  // Realtime stream for a single invoice (for detail screen)
  Stream<InvoiceModel> watchInvoice(int id) {
    return _supabase
        .from('Invoices')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .limit(1)
        .map((data) => InvoiceModel.fromJson(data.first));
  }

  Future<List<InvoiceModel>> getInvoices() async {
    final response = await _supabase
        .from('Invoices')
        .select('*, clients(*), projects(*)')
        .order('created_at', ascending: false);

    return (response as List).map((e) => InvoiceModel.fromJson(e)).toList();
  }

  Future<InvoiceModel> getInvoice(int id) async {
    final response = await _supabase
        .from('Invoices')
        .select('*, clients(*), projects(*)')
        .eq('id', id)
        .single();

    return InvoiceModel.fromJson(response);
  }

  Future<List<RelatedProductModel>> getRelatedProducts(int invoiceId) async {
    final response = await _supabase
        .from('Related Products')
        .select('*, PoleBarns(*) ' // Added space to satisfy potential issues
            '')
        .eq('IdInvoice', invoiceId);

    return (response as List)
        .map((e) => RelatedProductModel.fromJson(e))
        .toList();
  }

  Stream<List<RelatedProductModel>> watchRelatedProducts(int invoiceId) {
    return _supabase
        .from('Related Products')
        .stream(primaryKey: ['id'])
        .eq('IdInvoice', invoiceId)
        .map((data) =>
            data.map((e) => RelatedProductModel.fromJson(e)).toList());
  }

  Future<List<InvoicePaymentModel>> getInvoicePayments(int invoiceId) async {
    final response = await _supabase
        .from('Invoice Payments')
        .select('*, payment_methods(*)')
        .eq('IdInvoice', invoiceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => InvoicePaymentModel.fromJson(e))
        .toList();
  }

  Future<int> createInvoice(
      InvoiceModel invoice, List<Map<String, dynamic>> products) async {
    // 1. Create Invoice
    final invoiceData = invoice.toJson();
    final res =
        await _supabase.from('Invoices').insert(invoiceData).select().single();
    final newId = res['id'] as int;

    // 2. Create Related Products
    if (products.isNotEmpty) {
      final productsToInsert = products.map((p) {
        p['IdInvoice'] = newId;
        return p;
      }).toList();
      await _supabase.from('Related Products').insert(productsToInsert);
    }

    return newId;
  }

  Future<void> updateRelatedProduct(int id, Map<String, dynamic> data) async {
    await _supabase.from('Related Products').update(data).eq('id', id);
  }

  Future<void> saveRelatedProduct(RelatedProductModel product) async {
    final data = product.toJson();
    if (product.id == 0) {
      // It's a new association from the project, not yet in Related Products
      await _supabase.from('Related Products').insert(data);
    } else {
      await _supabase
          .from('Related Products')
          .update(data)
          .eq('id', product.id);
    }
  }

  Future<void> addPayment(InvoicePaymentModel payment) async {
    await _supabase.from('Invoice Payments').insert(payment.toJson());
  }

  Future<void> updatePayment(int paymentId, Map<String, dynamic> data) async {
    await _supabase.from('Invoice Payments').update(data).eq('id', paymentId);
  }

  Future<void> deletePayment(int paymentId) async {
    await _supabase.from('Invoice Payments').delete().eq('id', paymentId);
  }

  Future<List<Map<String, dynamic>>> getProjectPoleBarns(
      String projectId) async {
    final response = await _supabase
        .from('project_pole_barns')
        .select('*, PoleBarns(*)')
        .eq('project_id', projectId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> sendInvoiceByEmail({
    required int invoiceId,
    required List<int> pdfBytes,
    required String clientEmail,
    required String clientName,
  }) async {
    final base64String = base64Encode(pdfBytes);

    await _supabase.functions.invoke(
      'send-invoice',
      body: {
        'invoiceId': invoiceId,
        'pdfBase64': base64String,
        'clientEmail': clientEmail,
        'clientName': clientName,
      },
    );
  }
}
