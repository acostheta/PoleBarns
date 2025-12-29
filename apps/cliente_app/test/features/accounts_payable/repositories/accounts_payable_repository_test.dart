import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cliente_app/features/accounts_payable/repositories/accounts_payable_repository.dart';
import 'package:cliente_app/features/accounts_payable/models/account_payable_model.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Specific Mocks for different return types
class MockSelectBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class MockInsertBuilder extends Mock
    implements
        PostgrestFilterBuilder<
            void> {} // Standard insert returns void (or null) logic usually

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockSelectBuilder mockSelectBuilder;
  late MockInsertBuilder mockInsertBuilder;
  late AccountsPayableRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSelectBuilder = MockSelectBuilder();
    mockInsertBuilder = MockInsertBuilder();
    repository = AccountsPayableRepository(mockSupabaseClient);

    registerFallbackValue(Map<String, dynamic>);

    // Default chain
    when(() => mockSupabaseClient.from(any())).thenReturn(mockQueryBuilder);

    // Mock Future behavior for Insert (void/null)
    when(() => mockInsertBuilder.then(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0];
      return Future.value(callback(null));
    });

    // Mock Future behavior for Select (List)
    when(() => mockSelectBuilder.then(any(), onError: any(named: 'onError')))
        .thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0];
      return Future.value(callback([])); // Default empty list
    });
  });

  group('AccountsPayableRepository', () {
    final validDate = DateTime(2023, 10, 1);
    final accountJson = {
      'id': 'ap-1',
      'provider_id': 'prov-1',
      'invoice_date': validDate.toIso8601String(),
      'total_amount': 100.0,
      'total_paid': 0.0,
      'current_balance': 100.0,
      'providers': {'id': 'p1', 'name': 'Provider 1', 'address': 'Addr 1'}
    };

    test('getAccounts returns list of AccountPayableModel', () async {
      when(() => mockQueryBuilder.select(any())).thenReturn(mockSelectBuilder);
      when(() => mockSelectBuilder.order(any(),
          ascending: any(named: 'ascending'))).thenReturn(mockSelectBuilder);

      // Override default behavior to return data
      when(() => mockSelectBuilder.then(any(), onError: any(named: 'onError')))
          .thenAnswer((invocation) {
        final callback = invocation.positionalArguments[0];
        return Future.value(callback([accountJson]));
      });

      final result = await repository.getAccounts();

      expect(result, isA<List<AccountPayableModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'ap-1');
      verify(() => mockSupabaseClient.from('vw_accounts_payable_summary'))
          .called(1);
    });

    test('createAccount calls insert with correct data', () async {
      when(() => mockQueryBuilder.insert(any())).thenReturn(mockInsertBuilder);

      await repository.createAccount(
        providerId: 'prov-1',
        invoiceDate: validDate,
        totalAmount: 150.0,
      );

      verify(() => mockSupabaseClient.from('accounts_payable')).called(1);
      verify(() => mockQueryBuilder.insert({
            'provider_id': 'prov-1',
            'invoice_date': validDate.toIso8601String(),
            'total_amount': 150.0,
            'invoice_intern_ref': null,
          })).called(1);
    });

    test('addPayment calls insert with correct data', () async {
      when(() => mockQueryBuilder.insert(any())).thenReturn(mockInsertBuilder);

      await repository.addPayment(
        apId: 'ap-1',
        date: validDate,
        amount: 50.0,
        notes: 'Test payment',
      );

      verify(() => mockSupabaseClient.from('ap_payments')).called(1);
      verify(() => mockQueryBuilder.insert({
            'ap_id': 'ap-1',
            'date': validDate.toIso8601String(),
            'amount': 50.0,
            'payment_method_id': null,
            'notes': 'Test payment',
          })).called(1);
    });
  });
}
