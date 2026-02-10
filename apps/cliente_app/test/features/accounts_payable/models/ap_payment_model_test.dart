import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_app/features/accounts_payable/models/ap_payment_model.dart';

void main() {
  group('APPaymentModel', () {
    final validDate = DateTime(2023, 10, 2);

    final validJson = {
      'id': 'pay-123',
      'ap_id': 'ap-123',
      'date': validDate.toIso8601String(),
      'amount': 50.0,
      'payment_method_id': 'pm-1',
      'notes': 'Partial payment',
      'created_at': validDate.toIso8601String(),
      'payment_methods': {
        'id': 'pm-1',
        'name': 'Cash',
      },
    };

    test('fromJson creates a valid instance', () {
      final model = APPaymentModel.fromJson(validJson);

      expect(model.id, 'pay-123');
      expect(model.apId, 'ap-123');
      expect(model.date, validDate);
      expect(model.amount, 50.0);
      expect(model.paymentMethodId, 'pm-1');
      expect(model.notes, 'Partial payment');
      expect(model.paymentMethod, isNotNull);
      expect(model.paymentMethod!.name, 'Cash');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'pay-123',
        'ap_id': 'ap-123',
        'date': validDate.toIso8601String(),
        'amount': 50.0,
      };

      final model = APPaymentModel.fromJson(json);

      expect(model.paymentMethodId, isNull);
      expect(model.notes, isNull);
      expect(model.paymentMethod, isNull);
    });

    test('toJson returns correct map', () {
      final model = APPaymentModel(
        id: 'pay-123',
        apId: 'ap-123',
        date: validDate,
        amount: 50.0,
        paymentMethodId: 'pm-1',
        notes: 'Test note',
      );

      final json = model.toJson();

      expect(json['id'], 'pay-123');
      expect(json['ap_id'], 'ap-123');
      expect(json['date'], validDate.toIso8601String());
      expect(json['amount'], 50.0);
      expect(json['payment_method_id'], 'pm-1');
      expect(json['notes'], 'Test note');
    });
  });
}
