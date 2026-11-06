import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order, Transaction;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'pricing_service.dart';

// ═══════════════════════════════════════════════════════════
//  FIRESTORE SERVICE
//  Replaces DBService — all data stored in Firestore so
//  the web app (LabaFlow.html) and Flutter mobile share
//  the same live database with real-time sync.
//
//  Firestore path: labaflow/data/{collection}/{docId}
//  Each document uses the integer 'id' field as its docId
//  so it stays compatible with the HTML app's data format.
// ═══════════════════════════════════════════════════════════

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static SharedPreferences? _prefs;

  // ── Init ────────────────────────────────────────────────

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seed();
  }

  // ── Collection reference helper ──────────────────────────

  static CollectionReference<Map<String, dynamic>> col(String name) =>
      _db.collection('labaflow').doc('data').collection(name);

  // ── Read all docs (sorted by id) ─────────────────────────

  static Future<List<Map<String, dynamic>>> getAll(String name) async {
    try {
      // No orderBy — avoids needing Firestore indexes
      final snap = await col(name).get();
      final docs = snap.docs.map((d) => d.data()).toList();
      // Sort in Dart by 'id' field
      docs.sort((a, b) {
        final ai = (a['id'] as num?)?.toInt() ?? 0;
        final bi = (b['id'] as num?)?.toInt() ?? 0;
        return ai.compareTo(bi);
      });
      return docs;
    } catch (e) {
      return [];
    }
  }

  // ── Save entire list (delete-then-rewrite via batch) ─────

  static Future<void> saveAll(
      String name, List<Map<String, dynamic>> items) async {
    final ref      = col(name);
    final existing = await ref.get();

    // Split into chunks of 500 (Firestore batch limit)
    final allOps = <Future<void>>[];

    // Delete existing
    for (var i = 0; i < existing.docs.length; i += 400) {
      final batch = _db.batch();
      final chunk = existing.docs.sublist(
          i, (i + 400).clamp(0, existing.docs.length));
      for (final doc in chunk) batch.delete(doc.reference);
      allOps.add(batch.commit());
    }
    await Future.wait(allOps);

    // Write new items
    final writeOps = <Future<void>>[];
    for (var i = 0; i < items.length; i += 400) {
      final batch = _db.batch();
      final chunk = items.sublist(i, (i + 400).clamp(0, items.length));
      for (final item in chunk) {
        batch.set(ref.doc(item['id'].toString()), item);
      }
      writeOps.add(batch.commit());
    }
    await Future.wait(writeOps);
  }

  // ── Upsert single document (faster for one-item updates) ─

  static Future<void> upsertDoc(
          String name, Map<String, dynamic> data) =>
      col(name).doc(data['id'].toString()).set(data, SetOptions(merge: true));

  // ── Delete single document ────────────────────────────────

  static Future<void> deleteDoc(String name, int id) =>
      col(name).doc(id.toString()).delete();

  // ── Next auto-increment id ────────────────────────────────

  static Future<int> nextId(String name) async {
    try {
      final snap = await col(name).get();
      if (snap.docs.isEmpty) return 1;
      int maxId = 0;
      for (final doc in snap.docs) {
        final id = (doc.data()['id'] as num?)?.toInt() ?? 0;
        if (id > maxId) maxId = id;
      }
      return maxId + 1;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch % 100000 + 1;
    }
  }

  // ── Typed getters ─────────────────────────────────────────

  static Future<List<AppUser>> getUsers() async =>
      (await getAll('users')).map((e) => AppUser.fromJson(e)).toList();

  static Future<List<InventoryItem>> getInventory() async =>
      (await getAll('inventory')).map((e) => InventoryItem.fromJson(e)).toList();

  static Future<List<RfidTag>> getRfidTags() async =>
      (await getAll('rfidTags')).map((e) => RfidTag.fromJson(e)).toList();

  static Future<List<Order>> getOrders() async =>
      (await getAll('orders')).map((e) => Order.fromJson(e)).toList();

  static Future<List<Transaction>> getTransactions() async =>
      (await getAll('transactions')).map((e) => Transaction.fromJson(e)).toList();

  static Future<List<Message>> getMessages() async =>
      (await getAll('messages')).map((e) => Message.fromJson(e)).toList();

  static Future<List<RestockLog>> getRestockLog() async =>
      (await getAll('restockLog')).map((e) => RestockLog.fromJson(e)).toList();

  static Future<List<PromoCode>> getPromoCodes() async =>
      (await getAll('promoCodes')).map((e) => PromoCode.fromJson(e)).toList();

  static Future<List<Notif>> getNotifs() async =>
      (await getAll('notifs')).map((e) => Notif.fromJson(e)).toList();

  static Future<List<Review>> getReviews() async =>
      (await getAll('reviews')).map((e) => Review.fromJson(e)).toList();

  // ── Typed savers ──────────────────────────────────────────

  static Future<void> saveUsers(List<AppUser> v) =>
      saveAll('users', v.map((e) => e.toJson()).toList());

  static Future<void> saveInventory(List<InventoryItem> v) =>
      saveAll('inventory', v.map((e) => e.toJson()).toList());

  static Future<void> saveRfidTags(List<RfidTag> v) =>
      saveAll('rfidTags', v.map((e) => e.toJson()).toList());

  static Future<void> saveOrders(List<Order> v) =>
      saveAll('orders', v.map((e) => e.toJson()).toList().cast<Map<String,dynamic>>());

  static Future<void> saveTransactions(List<Transaction> v) =>
      saveAll('transactions', v.map((e) => e.toJson()).toList().cast<Map<String,dynamic>>());

  static Future<void> saveMessages(List<Message> v) =>
      saveAll('messages', v.map((e) => e.toJson()).toList());

  static Future<void> saveRestockLog(List<RestockLog> v) =>
      saveAll('restockLog', v.map((e) => e.toJson()).toList());

  static Future<void> savePromoCodes(List<PromoCode> v) =>
      saveAll('promoCodes', v.map((e) => e.toJson()).toList());

  static Future<void> saveNotifs(List<Notif> v) =>
      saveAll('notifs', v.map((e) => e.toJson()).toList());

  static Future<void> saveReviews(List<Review> v) =>
      saveAll('reviews', v.map((e) => e.toJson()).toList());

  // ── Real-time streams ─────────────────────────────────────

  /// Live stream of all messages (for messaging feature)
  static Stream<List<Message>> messagesStream() =>
      col('messages')
          .snapshots()
          .map((s) => s.docs
              .map((d) => Message.fromJson(d.data()))
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id)));

  /// Live stream of all users (so new accounts appear in real-time)
  static Stream<List<AppUser>> usersStream() =>
      col('users')
          .snapshots()
          .map((s) {
            final docs = s.docs.map((d) => d.data()).toList();
            docs.sort((a, b) {
              final ai = (a['id'] as num?)?.toInt() ?? 0;
              final bi = (b['id'] as num?)?.toInt() ?? 0;
              return ai.compareTo(bi);
            });
            return docs.map((e) => AppUser.fromJson(e)).toList();
          });

  /// Live stream of notifications for a specific user
  static Stream<List<Notif>> notifsStream(int userId) =>
      col('notifs')
          .where('toId', isEqualTo: userId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => Notif.fromJson(d.data()))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)));

  /// Live stream of all orders (for admin/seller dashboard)
  static Stream<List<Order>> ordersStream() =>
      col('orders')
          .snapshots()
          .map((s) => s.docs
              .map((d) => Order.fromJson(d.data()))
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id)));

  // ── Session user (local device only — who is logged in) ──

  static AppUser? get sessionUser {
    final raw = _prefs?.getString('lf3_cu');
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setSessionUser(AppUser? u) async {
    if (u == null) {
      await _prefs?.remove('lf3_cu');
    } else {
      await _prefs?.setString('lf3_cu', jsonEncode(u.toJson()));
    }
  }

  // ── Theme preference (local device only) ─────────────────

  static String get landingTheme =>
      _prefs?.getString('lf_landing_theme') ?? 'light';
  static Future<void> setLandingTheme(String t) async =>
      _prefs?.setString('lf_landing_theme', t);

  static String get appTheme =>
      _prefs?.getString('lf_app_theme') ?? 'dark';
  static Future<void> setAppTheme(String t) async =>
      _prefs?.setString('lf_app_theme', t);

  // ── GCash number (from Firestore settings) ────────────────

  static Future<String> getGcashNumber() async {
    try {
      final doc = await col('settings').doc('gcashNumber').get();
      if (doc.exists) {
        return (doc.data()?['val'] as String?) ?? '09611308218';
      }
    } catch (_) {}
    return '09611308218';
  }

  static Future<void> setGcashNumber(String number) async {
    await col('settings').doc('gcashNumber').set({'key': 'gcashNumber', 'val': number});
  }

  // ── FCM device tokens ─────────────────────────────────────

  /// Save the FCM token for a device so Cloud Functions can send targeted pushes.
  /// Path: labaflow/data/fcmTokens/{userId}
  static Future<void> saveFcmToken(int userId, String token) async {
    await col('fcmTokens').doc(userId.toString()).set({
      'userId':    userId,
      'token':     token,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // ── Deduct inventory ──────────────────────────────────────

  static Future<List<InventoryItem>> deductInventory(
      OrderType type, double? kg, int? comQty) async {
    const deductByCat = {
      'DETERGENT': 0.1,
      'SOFTENER':  0.1,
      'BLEACH':    0.01,
    };
    final loads = PricingService.calcLoads(type, kg, comQty);
    final inv   = await getInventory();
    for (final item in inv) {
      final rate = item.perLoad > 0
          ? item.perLoad
          : (deductByCat[item.cat.key] ?? 0.0);
      if (rate > 0) {
        final deduct =
            double.parse((rate * loads).toStringAsFixed(4));
        item.qty = double.parse(
            ((item.qty - deduct).clamp(0, double.infinity))
                .toStringAsFixed(4));
      }
    }
    await saveInventory(inv);
    return inv;
  }

  // ── Loyalty points ────────────────────────────────────────

  static Future<int> addPoints(int userId, double amount) async {
    final pts   = amount.floor();
    final users = await getUsers();
    final idx   = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      users[idx].points += pts;
      await upsertDoc('users', users[idx].toJson());
    }
    return pts;
  }

  // ── Push notification ─────────────────────────────────────

  static Future<void> pushNotif({
    required int toId,
    required String type,
    required String title,
    required String msg,
    String icon = '🔔',
  }) async {
    final id = await nextId('notifs');
    final notif = Notif(
      id:    id,
      toId:  toId,
      type:  type,
      title: title,
      msg:   msg,
      icon:  icon,
      date:  DateTime.now(),
    );
    await upsertDoc('notifs', notif.toJson());
  }

  // ── Seed (runs only when Firestore is empty) ──────────────

  static Future<void> _seed() async {
    // Check if already seeded
    final check = await col('users').limit(1).get();
    if (check.docs.isNotEmpty) return;

    final now = DateTime.now();

    await saveUsers([
      AppUser(id:1, name:'Administrator',  email:'admin@labaday.com',  phone:'09171234567', role:UserRole.admin,    pass:'password123', points:0),
      AppUser(id:2, name:'Seller Staff',   email:'seller@labaday.com', phone:'09181234567', role:UserRole.seller,   pass:'password123', points:0),
      AppUser(id:3, name:'Juan dela Cruz', email:'juan@gmail.com',     phone:'09191234567', role:UserRole.customer, pass:'password123', points:370),
      AppUser(id:4, name:'Maria Santos',   email:'maria@gmail.com',    phone:'09201234567', role:UserRole.customer, pass:'password123', points:590),
    ]);

    await saveInventory([
      InventoryItem(id:1, name:'Surf Liquid Detergent',   cat:InventoryCat.detergent, unit:'L', qty:12.5, thresh:1.0,  packSize:2.5, packQty:5, perLoad:0.1),
      InventoryItem(id:2, name:'Surf Fabric Conditioner', cat:InventoryCat.softener,  unit:'L', qty:8.0,  thresh:0.8,  packSize:1.6, packQty:5, perLoad:0.1),
      InventoryItem(id:3, name:'Zonrox Color Safe',       cat:InventoryCat.bleach,    unit:'L', qty:4.5,  thresh:0.45, packSize:0.9, packQty:5, perLoad:0.01),
    ]);

    await saveRfidTags(List.generate(
        10, (i) => RfidTag(id: i + 1, uid: 'TAG-${(i + 1).toString().padLeft(3, '0')}')));

    await saveOrders([
      Order(id:1, num:'ORD-001', custId:3, custName:'Juan dela Cruz', type:OrderType.clothes,   kg:5,     status:OrderStatus.pending,    price:180, breakdown:'₱180 base (7kg)',        created:now.subtract(const Duration(days:3))),
      Order(id:2, num:'ORD-002', custId:4, custName:'Maria Santos',   type:OrderType.bedsheet,  kg:5,     status:OrderStatus.received,   price:190, breakdown:'₱190 base (5kg)',        tagId:2, dropOff:now.subtract(const Duration(days:2)), created:now.subtract(const Duration(days:2))),
      Order(id:3, num:'ORD-003', custId:3, custName:'Juan dela Cruz', type:OrderType.clothes,   kg:8,     status:OrderStatus.processing, price:255, breakdown:'₱180 + 3kg extra × ₱25', tagId:3, notes:'Separate whites', dropOff:now.subtract(const Duration(days:1)), created:now.subtract(const Duration(days:1))),
      Order(id:4, num:'ORD-004', custId:4, custName:'Maria Santos',   type:OrderType.comforter, comQty:2, status:OrderStatus.ready,      price:400, breakdown:'2 comforters × ₱200',    tagId:4, finalPrice:400, dropOff:now.subtract(const Duration(days:1)), ready:now, created:now.subtract(const Duration(days:1))),
    ]);

    // Link RFID tags to orders
    final tags = await getRfidTags();
    await saveRfidTags(tags.map((t) {
      if (t.id == 2) return RfidTag(id:t.id, uid:t.uid, available:false, orderId:2);
      if (t.id == 3) return RfidTag(id:t.id, uid:t.uid, available:false, orderId:3);
      if (t.id == 4) return RfidTag(id:t.id, uid:t.uid, available:false, orderId:4);
      return t;
    }).toList());

    await savePromoCodes([
      PromoCode(id:1, code:'WELCOME', disc:10, maxUses:100, desc:'Welcome discount for new customers'),
      PromoCode(id:2, code:'LABA20',  disc:20, maxUses:30,  desc:'Special promo - limited time'),
    ]);

    // GCash settings
    await col('settings').doc('gcashNumber').set({'key':'gcashNumber','val':'09611308218'});

    // Empty collections (creates the collection so Firestore rules apply)
    for (final name in ['transactions','messages','restockLog','notifs','reviews']) {
      await col(name).doc('_init').set({'_init': true});
      await col(name).doc('_init').delete();
    }
  }
}
