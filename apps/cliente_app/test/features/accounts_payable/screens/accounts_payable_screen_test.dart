import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_app/features/accounts_payable/screens/accounts_payable_screen.dart';
import 'package:cliente_app/features/accounts_payable/providers/accounts_payable_provider.dart';
import 'package:cliente_app/features/accounts_payable/repositories/accounts_payable_repository.dart';
import 'package:cliente_app/features/accounts_payable/models/account_payable_model.dart';
import 'package:cliente_app/features/settings/models/provider_model.dart';
import 'package:cliente_app/features/settings/models/payment_method_model.dart';
import 'package:cliente_app/features/settings/repositories/settings_repository.dart';

// Mocks
class MockAccountsPayableRepository extends Mock
    implements AccountsPayableRepository {}
// Removed unused SettingsRepository mock

void main() {
  late MockAccountsPayableRepository mockAPRepository;

  final testProvider =
      ProviderModel(id: 'p1', name: 'Test Provider', address: 'Address');
  final testAccount = AccountPayableModel(
    id: 'ap1',
    providerId: 'p1',
    invoiceDate: DateTime(2023, 10, 1),
    totalAmount: 100.0,
    currentBalance: 60.0,
    provider: testProvider,
  );

  final testPaymentMethod = PaymentMethodModel(id: 'pm1', name: 'Cash');

  setUp(() {
    mockAPRepository = MockAccountsPayableRepository();

    // specific stubs
    when(() => mockAPRepository.getAccounts())
        .thenAnswer((_) async => [testAccount]);
    when(() => mockAPRepository.getPayments(any())).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        // Override repository
        accountsPayableRepositoryProvider.overrideWithValue(mockAPRepository),
        // Override payment methods for the dialog
        paymentMethodsListProvider.overrideWith((ref) => [testPaymentMethod]),
      ],
      child: const MaterialApp(
        home: AccountsPayableScreen(),
      ),
    );
  }

  testWidgets('Dashboard displays correct calculated totals', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify stats from testAccount
    // Total Debt: 100
    // Pending: 60
    // Paid: 100 - 60 = 40

    // Using contains to match formatted strings partially or finding by key if available
    expect(find.text('100.00'), findsOneWidget); // Total
    expect(find.text('60.00'), findsOneWidget); // Pending
    expect(find.text('40.00'), findsOneWidget); // Paid
  });

  testWidgets('List item displays account details', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Test Provider'), findsOneWidget);
    expect(find.text('PENDIENTE'), findsOneWidget);
    expect(find.text('01/10/2023'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Abonado'), findsOneWidget); // New field check
  });

  testWidgets('Payment dialog validates amount', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    expect(find.text('Abonar'), findsOneWidget);

    // Try submit empty
    await tester.tap(find.text('Abonar'));
    await tester.pump();
    expect(find.text('Requerido'), findsOneWidget); // Validator error

    // Try submit amount > balance (60)
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto a Abonar'), '70');
    await tester.tap(find.text('Abonar'));
    await tester.pump();
    // Validator or logic error
    expect(find.text('Excede el saldo'), findsOneWidget);
  });

  testWidgets('Payment submission calls repository', (tester) async {
    when(() => mockAPRepository.addPayment(
          apId: any(named: 'apId'),
          date: any(named: 'date'),
          amount: any(named: 'amount'),
          paymentMethodId: any(named: 'paymentMethodId'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    // Select Method
    // Use predicate finder or type without generic to be safe
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Tap the item 'Cash'
    // There might be two 'Cash' texts (one in dropdown button if selected, one in menu).
    // Initially none selected.
    // In menu, it should be visible.
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();

    // Enter valid amount
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto a Abonar'), '50');
    await tester.pumpAndSettle(); // Ensure text is updated

    // Submit
    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Abonar')); // More specific finder
    await tester.pumpAndSettle(); // Wait for async addPayment

    verify(() => mockAPRepository.addPayment(
          apId: 'ap1',
          date: any(named: 'date'),
          amount: 50.0,
          paymentMethodId: 'pm1',
          notes: any(named: 'notes'),
        )).called(1);
  });

  testWidgets('Payment submission error shows snackbar', (tester) async {
    when(() => mockAPRepository.addPayment(
          apId: any(named: 'apId'),
          date: any(named: 'date'),
          amount: any(named: 'amount'),
          paymentMethodId: any(named: 'paymentMethodId'),
          notes: any(named: 'notes'),
        )).thenThrow(Exception('Simulated API Error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    // Select Method
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Tap the item 'Cash'
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();

    // Enter valid amount
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Monto a Abonar'), '50');
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abonar'));
    await tester.pumpAndSettle();

    // Expect Error Snackbar
    expect(find.text('Error al abonar: Exception: Simulated API Error'),
        findsOneWidget);
  });
}
