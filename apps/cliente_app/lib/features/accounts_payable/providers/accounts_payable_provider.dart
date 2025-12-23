import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/accounts_payable_repository.dart';
import '../models/account_payable_model.dart';
import '../models/ap_payment_model.dart';

// Repository Provider
final accountsPayableRepositoryProvider =
    Provider<AccountsPayableRepository>((ref) {
  return AccountsPayableRepository(Supabase.instance.client);
});

// List of Accounts Provider (AsyncNotifier to handle loading/error states and refresh)
final accountsPayableListProvider = StateNotifierProvider<
    AccountsPayableNotifier, AsyncValue<List<AccountPayableModel>>>((ref) {
  return AccountsPayableNotifier(ref.watch(accountsPayableRepositoryProvider));
});

class AccountsPayableNotifier
    extends StateNotifier<AsyncValue<List<AccountPayableModel>>> {
  final AccountsPayableRepository _repository;

  AccountsPayableNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      state = const AsyncValue.loading();
      final accounts = await _repository.getAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAccount({
    required String providerId,
    required DateTime invoiceDate,
    required double totalAmount,
    String? invoiceInternRef,
  }) async {
    await _repository.createAccount(
      providerId: providerId,
      invoiceDate: invoiceDate,
      totalAmount: totalAmount,
      invoiceInternRef: invoiceInternRef,
    );
    // Refresh list
    await loadAccounts();
  }
}

// Payments List Family Provider (autoDispose to clean up when dialog closes)
final paymentsListProvider = FutureProvider.family
    .autoDispose<List<APPaymentModel>, String>((ref, apId) async {
  final repository = ref.watch(accountsPayableRepositoryProvider);
  return repository.getPayments(apId);
});

// Dashboard Statistics Provider
final dashboardStatsProvider = Provider<Map<String, double>>((ref) {
  final accountsState = ref.watch(accountsPayableListProvider);

  return accountsState.maybeWhen(
    data: (accounts) {
      double totalDebt = 0;
      double totalPaid = 0;
      double pendingBalance = 0;

      for (var account in accounts) {
        totalDebt += account.totalAmount;
        totalPaid += account.totalPaid;
        pendingBalance += account.currentBalance;
      }

      return {
        'totalDebt': totalDebt,
        'totalPaid': totalPaid,
        'pendingBalance': pendingBalance,
      };
    },
    orElse: () => {
      'totalDebt': 0.0,
      'totalPaid': 0.0,
      'pendingBalance': 0.0,
    },
  );
});
