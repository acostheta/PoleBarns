import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_payable_model.dart';
import '../models/ap_payment_model.dart';

class AccountsPayableRepository {
  final SupabaseClient _supabase;

  AccountsPayableRepository(this._supabase);

  // Fetch accounts from the VIEW to get calculated balances
  Future<List<AccountPayableModel>> getAccounts() async {
    final response = await _supabase
        .from('vw_accounts_payable_summary')
        .select(
            '*, providers!inner(*), projects(id, address)') // Joining with providers and projects
        .order('invoice_date', ascending: false);

    // Note: projects(id, name) would be better but your project model might use different field for display.
    // In projects table, we have 'address' or 'responsable'. Let's check which field to use for "Proyecto".
    // Usually 'address' or a custom name. Let's look at the projects table.
    return (response as List).map((e) {
      final json = Map<String, dynamic>.from(e);
      // Add a display name if projects join succeeded
      if (json['projects'] != null) {
        json['project_name'] = json['projects']['address'] ?? 'Proyecto';
      }
      return AccountPayableModel.fromJson(json);
    }).toList();
  }

  Future<void> createAccount({
    required String providerId,
    required DateTime invoiceDate,
    required double totalAmount,
    String? projectId,
    String? invoiceInternRef,
  }) async {
    await _supabase.from('accounts_payable').insert({
      'provider_id': providerId,
      'project_id': projectId,
      'invoice_date': invoiceDate.toIso8601String(),
      'total_amount': totalAmount,
      'invoice_intern_ref': invoiceInternRef,
    });
  }

  Future<List<APPaymentModel>> getPayments(String apId) async {
    final response = await _supabase
        .from('ap_payments')
        .select('*, payment_methods(*)')
        .eq('ap_id', apId)
        .order('date', ascending: false);

    return (response as List).map((e) => APPaymentModel.fromJson(e)).toList();
  }

  Future<void> addPayment({
    required String apId,
    required DateTime date,
    required double amount,
    String? paymentMethodId,
    String? notes,
  }) async {
    await _supabase.from('ap_payments').insert({
      'ap_id': apId,
      'date': date.toIso8601String(),
      'amount': amount,
      'payment_method_id': paymentMethodId,
      'notes': notes,
    });
  }

  Future<void> deletePayment(String paymentId) async {
    await _supabase.from('ap_payments').delete().eq('id', paymentId);
  }
}
