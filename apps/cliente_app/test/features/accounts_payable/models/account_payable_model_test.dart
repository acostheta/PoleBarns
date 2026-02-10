import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_app/features/accounts_payable/models/account_payable_model.dart';

void main() {
  group('AccountPayableModel', () {
    final validDate = DateTime(2023, 10, 1);

    final validJson = {
      'id': 'ap-123',
      'provider_id': 'provider-123',
      'invoice_date': validDate.toIso8601String(),
      'invoice_intern_ref': 'REF-001',
      'total_amount': 100.0,
      'total_paid': 50.0,
      'current_balance': 50.0,
      'created_at': validDate.toIso8601String(),
      'providers': {
        'id': 'provider-123',
        'name': 'Test Provider',
        'address': '123 Test St',
      },
    };

    test('fromJson creates a valid instance', () {
      final model = AccountPayableModel.fromJson(validJson);

      expect(model.id, 'ap-123');
      expect(model.providerId, 'provider-123');
      expect(model.invoiceDate, validDate);
      expect(model.invoiceInternRef, 'REF-001');
      expect(model.totalAmount, 100.0);
      expect(model.totalPaid, 50.0);
      expect(model.currentBalance, 50.0);
      expect(model.provider, isNotNull);
      expect(model.provider!.name, 'Test Provider');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ap-123',
        'provider_id': 'provider-123',
        'invoice_date': validDate.toIso8601String(),
        'total_amount': 100.0,
        // Missing optionals
      };

      final model = AccountPayableModel.fromJson(json);

      expect(model.invoiceInternRef, isNull);
      expect(model.totalPaid, 0.0); // Default
      expect(model.currentBalance, 0.0); // Default
      expect(model.provider, isNull);
    });

    test('toJson returns detailed map', () {
      final model = AccountPayableModel(
        id: 'ap-123',
        providerId: 'provider-123',
        invoiceDate: validDate,
        invoiceInternRef: 'REF-001',
        totalAmount: 100.0,
      );

      final json = model.toJson();

      expect(json['id'], 'ap-123');
      expect(json['provider_id'], 'provider-123');
      expect(json['invoice_date'], validDate.toIso8601String());
      expect(json['invoice_intern_ref'], 'REF-001');
      expect(json['total_amount'], 100.0);
      // Computed fields like total_paid are usually not in toJson for writes,
      // but verifying based on current model implementation
    });
  });
}
