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
        .select('*, providers!inner(*)') // Inner join on providers
        .order('invoice_date', ascending: false);

    return (response as List)
        .map((e) => AccountPayableModel.fromJson(e))
        .toList();
  }

  Future<void> createAccount({
    required String providerId,
    required DateTime invoiceDate,
    required double totalAmount,
    String? invoiceInternRef,
  }) async {
    await _supabase.from('accounts_payable').insert({
      'provider_id': providerId,
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
