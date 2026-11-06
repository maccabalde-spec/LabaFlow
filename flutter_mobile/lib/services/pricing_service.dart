import '../models/models.dart';

// ═══════════════════════════════════════════════════════════
//  PRICING ENGINE
//  Direct port of the JS pricing functions
// ═══════════════════════════════════════════════════════════

class PricingService {
  static PriceResult calcClothesPrice(double kg) {
    if (kg <= 0) return const PriceResult(0, '');
    if (kg >= 10) {
      int sets = (kg / 9).ceil();
      double total = 0;
      List<String> bds = [];
      double remaining = kg;
      for (int s = 0; s < sets; s++) {
        double setKg = remaining < 9 ? remaining : 9;
        double extra = (setKg - 7).clamp(0, double.infinity);
        double setPrice = 180 + extra * 25;
        total += setPrice;
        bds.add('Set ${s + 1}: ${setKg}kg = ₱${setPrice.toStringAsFixed(0)}');
        remaining -= setKg;
      }
      return PriceResult(total, bds.join(' | '));
    }
    double extra = (kg - 7).clamp(0, double.infinity);
    double price = 180 + extra * 25;
    String bd = '₱180 base (7kg)';
    if (extra > 0) bd += ' + ${extra}kg × ₱25';
    return PriceResult(price, bd);
  }

  static PriceResult calcBedsheetPrice(double kg) {
    if (kg <= 0) return const PriceResult(0, '');
    double extra = (kg - 5).clamp(0, double.infinity);
    double price = 190 + extra * 38;
    String bd = '₱190 base (5kg)';
    if (extra > 0) bd += ' + ${extra}kg × ₱38';
    return PriceResult(price, bd);
  }

  static PriceResult calcComforterPrice(int qty) {
    if (qty <= 0) return const PriceResult(0, '');
    return PriceResult(qty * 200.0, '$qty comforter${qty > 1 ? 's' : ''} × ₱200');
  }

  static PriceResult calcPrice(OrderType type, double? kg, int? comQty) {
    switch (type) {
      case OrderType.clothes:
        return calcClothesPrice(kg ?? 0);
      case OrderType.bedsheet:
        return calcBedsheetPrice(kg ?? 0);
      case OrderType.comforter:
        return calcComforterPrice(comQty ?? 0);
      case OrderType.washOnly:
        return const PriceResult(100, 'Wash Only — flat ₱100');
      case OrderType.dryOnly:
        return const PriceResult(100, 'Dry Only — flat ₱100');
    }
  }

  static PromoResult applyPromo(String code, double basePrice, List<PromoCode> promoCodes) {
    if (code.isEmpty) return PromoResult(0, basePrice, '');
    final pc = promoCodes.where((p) =>
      p.code.toUpperCase() == code.toUpperCase() &&
      p.active &&
      p.uses < p.maxUses
    ).firstOrNull;
    if (pc == null) {
      return PromoResult(0, basePrice, '❌ Invalid or expired promo code');
    }
    double disc = double.parse(((pc.disc / 100) * basePrice).toStringAsFixed(2));
    double final_ = double.parse((basePrice - disc).toStringAsFixed(2));
    return PromoResult(disc, final_, '✅ ${pc.code}: ${pc.disc}% off — saves ₱${disc.toStringAsFixed(2)}');
  }

  static int calcLoads(OrderType type, double? kg, int? comQty) {
    final kgNum = kg ?? 0;
    switch (type) {
      case OrderType.clothes:
        return kgNum >= 10 ? (kgNum / 9).ceil() : 1;
      case OrderType.bedsheet:
        return ((kgNum / 5).ceil()).clamp(1, 999);
      case OrderType.comforter:
        return comQty ?? 1;
      default:
        return 1;
    }
  }
}
