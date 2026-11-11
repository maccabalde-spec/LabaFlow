// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:labaflow_mobile/models/models.dart';
import 'package:labaflow_mobile/providers/app_provider.dart';
import 'package:labaflow_mobile/services/pricing_service.dart';

void main() {
  // ══════════════════════════════════════════════════════════════
  //  INPUT VALIDATION — Phone & Email
  // ══════════════════════════════════════════════════════════════
  group('Phone validation', () {
    test('accepts standard 09XXXXXXXXX', () {
      expect(AppProvider.isValidPhone('09171234567'), isTrue);
      expect(AppProvider.isValidPhone('09611308218'), isTrue);
    });

    test('normalizes +63 prefix to 09', () {
      expect(AppProvider.normalizePhone('+639171234567'), '09171234567');
    });

    test('normalizes 63 prefix to 09', () {
      expect(AppProvider.normalizePhone('639171234567'), '09171234567');
    });

    test('rejects 8-digit landline', () {
      expect(AppProvider.isValidPhone('87654321'), isFalse);
    });

    test('rejects number with letters', () {
      expect(AppProvider.isValidPhone('0917-abc-567'), isFalse);
    });

    test('rejects short number', () {
      expect(AppProvider.isValidPhone('0917'), isFalse);
    });

    test('rejects empty string', () {
      expect(AppProvider.isValidPhone(''), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  PRICING ENGINE — Clothes
  // ══════════════════════════════════════════════════════════════
  group('Clothes pricing', () {
    test('base price ₱180 for exactly 7 kg', () {
      expect(PricingService.calcClothesPrice(7).price, 180);
    });

    test('no extra charge under 7 kg', () {
      expect(PricingService.calcClothesPrice(5).price, 180);
    });

    test('extra ₱25 per kg above 7', () {
      // 8 kg = 180 + 1×25 = 205
      expect(PricingService.calcClothesPrice(8).price, 205);
      // 9 kg = 180 + 2×25 = 230
      expect(PricingService.calcClothesPrice(9).price, 230);
    });

    test('splits into 2 sets at 10 kg', () {
      // 10 kg → set1: 9kg = 230, set2: 1kg = 180 → total 410
      final result = PricingService.calcClothesPrice(10);
      expect(result.price, 410);
    });

    test('zero kg returns ₱0', () {
      expect(PricingService.calcClothesPrice(0).price, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  PRICING ENGINE — Other types
  // ══════════════════════════════════════════════════════════════
  group('Bedsheet pricing', () {
    test('base price ₱190 for 5 kg', () {
      expect(PricingService.calcBedsheetPrice(5).price, 190);
    });

    test('extra ₱38 per kg above 5', () {
      // 6 kg = 190 + 38 = 228
      expect(PricingService.calcBedsheetPrice(6).price, 228);
    });
  });

  group('Comforter pricing', () {
    test('₱200 per comforter', () {
      expect(PricingService.calcComforterPrice(1).price, 200);
      expect(PricingService.calcComforterPrice(3).price, 600);
    });

    test('zero comforters returns ₱0', () {
      expect(PricingService.calcComforterPrice(0).price, 0);
    });
  });

  group('Flat rates', () {
    test('Wash Only is ₱100 flat', () {
      expect(PricingService.calcPrice(OrderType.washOnly, null, null).price, 100);
    });

    test('Dry Only is ₱100 flat', () {
      expect(PricingService.calcPrice(OrderType.dryOnly, null, null).price, 100);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  PROMO CODE ENGINE
  // ══════════════════════════════════════════════════════════════
  group('Promo codes', () {
    final promoCodes = [
      PromoCode(id: 1, code: 'LABA10', disc: 10, maxUses: 50, uses: 0, active: true, desc: '10% off'),
      PromoCode(id: 2, code: 'EXPIRED', disc: 20, maxUses: 10, uses: 10, active: true, desc: 'Used up'),
      PromoCode(id: 3, code: 'INACTIVE', disc: 15, maxUses: 100, uses: 0, active: false, desc: 'Disabled'),
    ];

    test('applies 10% discount correctly', () {
      final result = PricingService.applyPromo('LABA10', 180, promoCodes);
      expect(result.discount, 18);
      expect(result.finalAfterPromo, 162);
    });

    test('is case-insensitive', () {
      final result = PricingService.applyPromo('laba10', 180, promoCodes);
      expect(result.discount, 18);
    });

    test('rejects fully used promo code', () {
      final result = PricingService.applyPromo('EXPIRED', 180, promoCodes);
      expect(result.discount, 0);
      expect(result.finalAfterPromo, 180);
    });

    test('rejects inactive promo code', () {
      final result = PricingService.applyPromo('INACTIVE', 180, promoCodes);
      expect(result.discount, 0);
    });

    test('rejects unknown code', () {
      final result = PricingService.applyPromo('FAKECODE', 180, promoCodes);
      expect(result.discount, 0);
      expect(result.finalAfterPromo, 180);
    });

    test('empty code returns no discount', () {
      final result = PricingService.applyPromo('', 180, promoCodes);
      expect(result.discount, 0);
      expect(result.finalAfterPromo, 180);
    });
  });

  // ══════════════════════════════════════════════════════════════
  //  ORDER STATUS TRANSITIONS
  // ══════════════════════════════════════════════════════════════
  group('OrderStatus next-stage transitions', () {
    test('PENDING → RECEIVED', () {
      expect(OrderStatus.pending.next, OrderStatus.received);
    });

    test('RECEIVED → WASHING', () {
      expect(OrderStatus.received.next, OrderStatus.washing);
    });

    test('WASHING → DRYING', () {
      expect(OrderStatus.washing.next, OrderStatus.drying);
    });

    test('DRYING → FOLDING', () {
      expect(OrderStatus.drying.next, OrderStatus.folding);
    });

    test('FOLDING → READY', () {
      expect(OrderStatus.folding.next, OrderStatus.ready);
    });

    test('READY → RELEASED', () {
      expect(OrderStatus.ready.next, OrderStatus.released);
    });

    test('RELEASED has no next stage', () {
      expect(OrderStatus.released.next, isNull);
    });

    test('PROCESSING normalises to WASHING', () {
      // PROCESSING is a legacy alias for WASHING in the transition chain
      expect(OrderStatus.processing.next, OrderStatus.drying);
    });
  });
}
