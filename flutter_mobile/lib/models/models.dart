import 'dart:core';
import 'dart:core' as core;

// ═══════════════════════════════════════════════════════════
//  LABAFLOW DATA MODELS
//  All fields mirror the JavaScript data structures exactly
// ═══════════════════════════════════════════════════════════

// ── Enums ──────────────────────────────────────────────────

enum UserRole { admin, seller, customer }

enum OrderType { clothes, bedsheet, comforter, washOnly, dryOnly }

enum OrderStatus { pending, received, washing, processing, drying, folding, ready, released, cancelled }

enum ColorDist { mixed, whites, colored }

enum InventoryCat { detergent, softener, bleach, other }

enum PaymentChannel { cash, gcash }

extension UserRoleExt on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:    return 'ADMIN';
      case UserRole.seller:   return 'SELLER';
      case UserRole.customer: return 'CUSTOMER';
    }
  }
  static UserRole fromString(String s) {
    switch (s.toUpperCase()) {
      case 'ADMIN':    return UserRole.admin;
      case 'SELLER':   return UserRole.seller;
      default:         return UserRole.customer;
    }
  }
}

extension OrderTypeExt on OrderType {
  String get key {
    switch (this) {
      case OrderType.clothes:   return 'CLOTHES';
      case OrderType.bedsheet:  return 'BEDSHEET';
      case OrderType.comforter: return 'COMFORTER';
      case OrderType.washOnly:  return 'WASH_ONLY';
      case OrderType.dryOnly:   return 'DRY_ONLY';
    }
  }
  String get label {
    switch (this) {
      case OrderType.clothes:   return 'Clothes (Full Wash)';
      case OrderType.bedsheet:  return 'Bedsheet';
      case OrderType.comforter: return 'Comforter';
      case OrderType.washOnly:  return 'Wash Only';
      case OrderType.dryOnly:   return 'Dry Only';
    }
  }
  static OrderType fromString(String s) {
    switch (s) {
      case 'BEDSHEET':  return OrderType.bedsheet;
      case 'COMFORTER': return OrderType.comforter;
      case 'WASH_ONLY': return OrderType.washOnly;
      case 'DRY_ONLY':  return OrderType.dryOnly;
      default:          return OrderType.clothes;
    }
  }
}

extension OrderStatusExt on OrderStatus {
  String get key {
    switch (this) {
      case OrderStatus.pending:    return 'PENDING';
      case OrderStatus.received:   return 'RECEIVED';
      case OrderStatus.washing:    return 'WASHING';
      case OrderStatus.processing: return 'PROCESSING';
      case OrderStatus.drying:     return 'DRYING';
      case OrderStatus.folding:    return 'FOLDING';
      case OrderStatus.ready:      return 'READY';
      case OrderStatus.released:   return 'RELEASED';
      case OrderStatus.cancelled:  return 'CANCELLED';
    }
  }
  static OrderStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'RECEIVED':   return OrderStatus.received;
      case 'WASHING':    return OrderStatus.washing;
      case 'PROCESSING': return OrderStatus.processing;
      case 'DRYING':     return OrderStatus.drying;
      case 'FOLDING':    return OrderStatus.folding;
      case 'READY':      return OrderStatus.ready;
      case 'RELEASED':   return OrderStatus.released;
      case 'CANCELLED':  return OrderStatus.cancelled;
      default:           return OrderStatus.pending;
    }
  }
  OrderStatus? get next {
    const flow = [
      OrderStatus.pending,
      OrderStatus.received,
      OrderStatus.washing,
      OrderStatus.drying,
      OrderStatus.folding,
      OrderStatus.ready,
      OrderStatus.released,
    ];
    final normalized = this == OrderStatus.processing ? OrderStatus.washing : this;
    final i = flow.indexOf(normalized);
    return (i >= 0 && i < flow.length - 1) ? flow[i + 1] : null;
  }
}

extension ColorDistExt on ColorDist {
  String get key {
    switch (this) {
      case ColorDist.whites:  return 'WHITES';
      case ColorDist.colored: return 'COLORED';
      default:                return 'MIXED';
    }
  }
  String get label {
    switch (this) {
      case ColorDist.whites:  return 'Whites Only';
      case ColorDist.colored: return 'Colored Only';
      default:                return 'Mixed / No Separation';
    }
  }
  static ColorDist fromString(String s) {
    switch (s) {
      case 'WHITES':  return ColorDist.whites;
      case 'COLORED': return ColorDist.colored;
      default:        return ColorDist.mixed;
    }
  }
}

extension InventoryCatExt on InventoryCat {
  String get key {
    switch (this) {
      case InventoryCat.detergent: return 'DETERGENT';
      case InventoryCat.softener:  return 'SOFTENER';
      case InventoryCat.bleach:    return 'BLEACH';
      default:                     return 'OTHER';
    }
  }
  static InventoryCat fromString(String s) {
    switch (s) {
      case 'DETERGENT': return InventoryCat.detergent;
      case 'SOFTENER':  return InventoryCat.softener;
      case 'BLEACH':    return InventoryCat.bleach;
      default:          return InventoryCat.other;
    }
  }
}

// ── Models ─────────────────────────────────────────────────

class AppUser {
  final int id;
  final String authUid;
  String name;
  String email;
  String phone;
  UserRole role;
  int points;
  String? pic; // base64 dataURL
  bool googleConnected;
  bool hasPassword;

  AppUser({
    required this.id,
    this.authUid = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.points = 0,
    this.pic,
    this.googleConnected = false,
    this.hasPassword = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id:     j['id']     as int,
    authUid: (j['authUid'] ?? '') as String,
    name:   j['name']   as String,
    email:  j['email']  as String,
    phone:  (j['phone'] ?? '') as String,
    role:   UserRoleExt.fromString(j['role'] as String),
    points: (j['points'] ?? 0) as int,
    pic:    j['pic']    as String?,
    googleConnected: j['googleConnected'] as bool? ?? false,
    hasPassword: j['hasPassword'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone,
    'role': role.name, 'points': points,
    if (authUid.isNotEmpty) 'authUid': authUid,
    if (pic != null) 'pic': pic,
    'googleConnected': googleConnected,
    'hasPassword': hasPassword,
  };

  AppUser copyWith({String? name, String? email, String? phone, int? points, String? pic, bool? googleConnected, bool? hasPassword}) => AppUser(
    id: id, authUid: authUid, name: name ?? this.name, email: email ?? this.email,
    phone: phone ?? this.phone, role: role,
    points: points ?? this.points, pic: pic ?? this.pic,
    googleConnected: googleConnected ?? this.googleConnected,
    hasPassword: hasPassword ?? this.hasPassword,
  );
}

class InventoryItem {
  final int id;
  String name;
  InventoryCat cat;
  String unit;
  double qty;
  double thresh;
  double? packSize;
  int? packQty;
  double perLoad;
  double perKg;

  InventoryItem({
    required this.id,
    required this.name,
    required this.cat,
    required this.unit,
    required this.qty,
    required this.thresh,
    this.packSize,
    this.packQty,
    required this.perLoad,
    this.perKg = 0,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
    id:       j['id']       as int,
    name:     j['name']     as String,
    cat:      InventoryCatExt.fromString(j['cat'] as String),
    unit:     j['unit']     as String,
    qty:      (j['qty']     as num).toDouble(),
    thresh:   (j['thresh']  as num).toDouble(),
    packSize: j['packSize'] != null ? (j['packSize'] as num).toDouble() : null,
    packQty:  j['packQty']  as int?,
    perLoad:  (j['perLoad'] as num? ?? 0).toDouble(),
    perKg:    (j['perKg']   as num? ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'cat': cat.key, 'unit': unit,
    'qty': qty, 'thresh': thresh, 'packSize': packSize, 'packQty': packQty,
    'perLoad': perLoad, 'perKg': perKg,
  };

  double get maxQty {
    if (packSize != null && packQty != null) return packSize! * packQty!;
    return (thresh * 4).clamp(1, double.infinity);
  }

  double get pct => ((qty / maxQty) * 100).clamp(0, 100);
  bool   get isLow => qty <= thresh;
  bool   get isLiquid => unit == 'L' || unit == 'ml' || unit == 'mL';
  int    get qtyMl => (qty * 1000).round();
}

class RfidTag {
  final int id;
  String uid;
  bool available;
  int? orderId;

  RfidTag({required this.id, required this.uid, this.available = true, this.orderId});

  factory RfidTag.fromJson(Map<String, dynamic> j) => RfidTag(
    id:        j['id']        as int,
    uid:       j['uid']       as String,
    available: j['available'] as bool,
    orderId:   j['orderId']   as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'uid': uid, 'available': available, 'orderId': orderId,
  };
}

class Order {
  final int id;
  String num;
  int custId;
  String custName;
  int? tagId;
  OrderType type;
  double? kg;
  int? comQty;
  ColorDist colorDist;
  OrderStatus status;
  String notes;
  double price;
  String breakdown;
  double discount;
  String promoCode;
  double? finalPrice;
  DateTime? dropOff;
  DateTime? ready;
  DateTime? pickup;
  DateTime created;

  Order({
    required this.id,
    required this.num,
    required this.custId,
    required this.custName,
    this.tagId,
    required this.type,
    this.kg,
    this.comQty,
    this.colorDist = ColorDist.mixed,
    this.status = OrderStatus.pending,
    this.notes = '',
    required this.price,
    required this.breakdown,
    this.discount = 0,
    this.promoCode = '',
    this.finalPrice,
    this.dropOff,
    this.ready,
    this.pickup,
    required this.created,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id:         j['id']        as int,
    num:        j['num']       as String,
    custId:     j['custId']    as int,
    custName:   j['custName']  as String,
    tagId:      j['tagId']     as int?,
    type:       OrderTypeExt.fromString(j['type'] as String),
    kg:         j['kg']        != null ? (j['kg'] as core.num).toDouble() : null,
    comQty:     j['comQty']    as int?,
    colorDist:  ColorDistExt.fromString((j['colorDist'] ?? 'MIXED') as String),
    status:     OrderStatusExt.fromString(j['status'] as String),
    notes:      (j['notes']    ?? '') as String,
    price:      (j['price']    as core.num).toDouble(),
    breakdown:  (j['breakdown']?? '') as String,
    discount:   (j['discount'] as core.num? ?? 0).toDouble(),
    promoCode:  (j['promoCode']?? '') as String,
    finalPrice: j['finalPrice'] != null ? (j['finalPrice'] as core.num).toDouble() : null,
    dropOff:    j['dropOff']  != null ? DateTime.tryParse(j['dropOff']  as String) : null,
    ready:      j['ready']    != null ? DateTime.tryParse(j['ready']    as String) : null,
    pickup:     j['pickup']   != null ? DateTime.tryParse(j['pickup']   as String) : null,
    created:    DateTime.parse(j['created'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'num': num, 'custId': custId, 'custName': custName,
    'tagId': tagId, 'type': type.key, 'kg': kg, 'comQty': comQty,
    'colorDist': colorDist.key, 'status': status.key, 'notes': notes,
    'price': price, 'breakdown': breakdown, 'discount': discount,
    'promoCode': promoCode, 'finalPrice': finalPrice,
    'dropOff': dropOff?.toIso8601String(),
    'ready':   ready?.toIso8601String(),
    'pickup':  pickup?.toIso8601String(),
    'created': created.toIso8601String(),
  };
}

class Transaction {
  final int id;
  String num;
  int orderId;
  String orderNum;
  String custName;
  double amount;
  PaymentChannel channel;
  String gcashRef;
  String promoCode;
  String rcpt;
  DateTime date;

  Transaction({
    required this.id,
    required this.num,
    required this.orderId,
    required this.orderNum,
    required this.custName,
    required this.amount,
    required this.channel,
    this.gcashRef = '',
    this.promoCode = '',
    required this.rcpt,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id:        j['id']       as int,
    num:       j['num']      as String,
    orderId:   j['orderId']  as int,
    orderNum:  j['orderNum'] as String,
    custName:  j['custName'] as String,
    amount:    (j['amount']  as core.num).toDouble(),
    channel:   (j['channel'] as String) == 'GCASH' ? PaymentChannel.gcash : PaymentChannel.cash,
    gcashRef:  (j['gcashRef']  ?? '') as String,
    promoCode: (j['promoCode'] ?? '') as String,
    rcpt:      (j['rcpt']      ?? '') as String,
    date:      DateTime.parse(j['date'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'num': num, 'orderId': orderId, 'orderNum': orderNum,
    'custName': custName, 'amount': amount,
    'channel': channel == PaymentChannel.gcash ? 'GCASH' : 'CASH',
    'gcashRef': gcashRef, 'promoCode': promoCode, 'rcpt': rcpt,
    'date': date.toIso8601String(), 'status': 'COMPLETED',
  };
}

class Message {
  final int id;
  int fromId;
  int toId;
  String text;
  DateTime date;
  bool read;

  Message({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.date,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id:     j['id']     as int,
    fromId: j['fromId'] as int,
    toId:   j['toId']   as int,
    text:   j['text']   as String,
    date:   DateTime.parse(j['date'] as String),
    read:   (j['read']  ?? false) as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'fromId': fromId, 'toId': toId,
    'text': text, 'date': date.toIso8601String(), 'read': read,
  };
}

class RestockLog {
  final int id;
  int itemId;
  String itemName;
  String unit;
  double qty;
  double before;
  double after;
  double? costPerUnit;
  double? totalCost;
  DateTime date;
  String by;

  RestockLog({
    required this.id, required this.itemId, required this.itemName,
    required this.unit, required this.qty, required this.before,
    required this.after, this.costPerUnit, this.totalCost,
    required this.date, required this.by,
  });

  factory RestockLog.fromJson(Map<String, dynamic> j) => RestockLog(
    id: j['id'] as int, itemId: j['itemId'] as int,
    itemName: j['itemName'] as String, unit: j['unit'] as String,
    qty:    (j['qty']    as num).toDouble(),
    before: (j['before'] as num).toDouble(),
    after:  (j['after']  as num).toDouble(),
    costPerUnit: j['costPerUnit'] != null ? (j['costPerUnit'] as num).toDouble() : null,
    totalCost:   j['totalCost']   != null ? (j['totalCost']   as num).toDouble() : null,
    date: DateTime.parse(j['date'] as String),
    by: (j['by'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'itemId': itemId, 'itemName': itemName, 'unit': unit,
    'qty': qty, 'before': before, 'after': after,
    'costPerUnit': costPerUnit, 'totalCost': totalCost,
    'date': date.toIso8601String(), 'by': by,
  };
}

class PromoCode {
  final int id;
  String code;
  int disc;
  int maxUses;
  int uses;
  String desc;
  bool active;

  PromoCode({
    required this.id, required this.code, required this.disc,
    required this.maxUses, this.uses = 0, required this.desc, this.active = true,
  });

  factory PromoCode.fromJson(Map<String, dynamic> j) => PromoCode(
    id:      j['id']      as int,
    code:    j['code']    as String,
    disc:    j['disc']    as int,
    maxUses: j['maxUses'] as int,
    uses:    (j['uses']   ?? 0) as int,
    desc:    (j['desc']   ?? '') as String,
    active:  (j['active'] ?? true) as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'code': code, 'disc': disc, 'maxUses': maxUses,
    'uses': uses, 'desc': desc, 'active': active,
  };
}

class Notif {
  final int id;
  final String docId;
  int toId;
  String type;
  String title;
  String msg;
  String icon;
  bool read;
  DateTime date;

  Notif({
    required this.id, required this.toId, required this.type,
    this.docId = '',
    required this.title, required this.msg, required this.icon,
    this.read = false, required this.date,
  });

  factory Notif.fromJson(Map<String, dynamic> j) => Notif(
    id:    j['id']    as int,
    docId: (j['docId'] ?? '') as String,
    toId:  j['toId']  as int,
    type:  j['type']  as String,
    title: j['title'] as String,
    msg:   j['msg']   as String,
    icon:  (j['icon'] ?? '🔔') as String,
    read:  (j['read'] ?? false) as bool,
    date:  DateTime.parse(j['date'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'docId': docId, 'toId': toId, 'type': type, 'title': title,
    'msg': msg, 'icon': icon, 'read': read, 'date': date.toIso8601String(),
  };
}

class Review {
  final int id;
  String name;
  String service;
  String text;
  int rating;
  DateTime date;

  Review({
    required this.id, required this.name, required this.service,
    required this.text, required this.rating, required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id:      j['id']      as int,
    name:    j['name']    as String,
    service: (j['service']?? 'Laundry Service') as String,
    text:    j['text']    as String,
    rating:  j['rating']  as int,
    date:    DateTime.parse(j['date'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'service': service,
    'text': text, 'rating': rating, 'date': date.toIso8601String(),
  };
}

// ── Loyalty Tier ────────────────────────────────────────────

class LoyaltyTier {
  final String name;
  final int minPts;
  final int disc;
  final int color;

  const LoyaltyTier({
    required this.name,
    required this.minPts,
    required this.disc,
    required this.color,
  });
}

const List<LoyaltyTier> kTiers = [
  LoyaltyTier(name: 'Bronze',   minPts:    0, disc:  0, color: 0xFFCD7F32),
  LoyaltyTier(name: 'Silver',   minPts:  500, disc:  5, color: 0xFF9CA3AF),
  LoyaltyTier(name: 'Gold',     minPts: 1000, disc: 10, color: 0xFFF59E0B),
  LoyaltyTier(name: 'Platinum', minPts: 2000, disc: 15, color: 0xFFA78BFA),
];

LoyaltyTier getTier(int pts) {
  LoyaltyTier t = kTiers.first;
  for (final tier in kTiers) {
    if (pts >= tier.minPts) t = tier;
  }
  return t;
}

LoyaltyTier? getNextTier(int pts) {
  for (final tier in kTiers) {
    if (tier.minPts > pts) return tier;
  }
  return null;
}

// ── Pricing Result ──────────────────────────────────────────

class PriceResult {
  final double price;
  final String breakdown;
  const PriceResult(this.price, this.breakdown);
}

class PromoResult {
  final double discount;
  final double finalAfterPromo;
  final String promoMsg;
  const PromoResult(this.discount, this.finalAfterPromo, this.promoMsg);
}
