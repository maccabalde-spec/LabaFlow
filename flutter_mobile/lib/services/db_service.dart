import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../supabase_options.dart';
import 'pricing_service.dart';

// ═══════════════════════════════════════════════════════════
//  DB SERVICE — localStorage equivalent using SharedPreferences
//  All keys prefixed 'lf3_' to match the HTML app, with
//  automatic real-time synchronization via Supabase.
// ═══════════════════════════════════════════════════════════

class DBService {
  static SharedPreferences? _prefs;
  static bool _suppressRemote = false;

  static const Set<String> syncKeys = {
    'inventory',
    'rfidTags',
    'orders',
    'transactions',
    'messages',
    'restockLog',
    'promoCodes',
    'reviews',
    'rfidScanLogs',
    'statusHistory',
  };

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Old releases stored plaintext passwords and sessions here. Remove them
    // during this upgrade; Supabase Auth is the credential store now.
    await prefs.remove('lf3_users');
    await prefs.remove('lf3_cu');
    _suppressRemote = true;
    try {
      await _seed();
      await _migrate();
    } finally {
      _suppressRemote = false;
    }
  }

  static SharedPreferences get prefs {
    assert(_prefs != null, 'DBService.init() must be called first');
    return _prefs!;
  }

  // ── Raw access ──────────────────────────────────────────

  static String? rawGet(String key) => prefs.getString('lf3_$key');

  static Future<void> rawSet(String key, String value) =>
    prefs.setString('lf3_$key', value);

  static bool has(String key) => prefs.containsKey('lf3_$key');

  // ── Typed list access ───────────────────────────────────

  static List<Map<String, dynamic>> getList(String key) {
    final raw = rawGet(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) return List<Map<String, dynamic>>.from(parsed);
    } catch (_) {}
    return [];
  }

  static Future<void> setList(
    String key,
    List<Map<String, dynamic>> value, {
    bool skipRemote = false,
  }) async {
    final encoded = jsonEncode(value);
    final prev = rawGet(key);
    await rawSet(key, encoded);
    if (!_suppressRemote &&
        !skipRemote &&
        prev != encoded &&
        syncKeys.contains(key) &&
        LabaFlowSupabaseOptions.isConfigured) {
      try {
        final client = Supabase.instance.client;
        if (client.auth.currentSession != null) {
          await client.from('app_collections').upsert({
            'key': key,
            'items': value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'key');
        }
      } catch (_) {}
    }
  }

  static Future<bool> applyRemoteRows(List<Map<String, dynamic>> rows) async {
    var changed = false;
    for (final row in rows) {
      final key = row['key'] as String?;
      final items = row['items'];
      if (key == null || !syncKeys.contains(key) || items is! List) continue;
      final encoded = jsonEncode(items);
      final current = rawGet(key);
      if (current != encoded) {
        if (items.isEmpty && current != null && current != '[]') {
          try {
            final client = Supabase.instance.client;
            if (client.auth.currentSession != null) {
              await client.from('app_collections').upsert({
                'key': key,
                'items': getList(key),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }, onConflict: 'key');
            }
          } catch (_) {}
        } else {
          await rawSet(key, encoded);
          changed = true;
        }
      }
    }
    return changed;
  }

  static Future<bool> pullRemoteCollections() async {
    if (!LabaFlowSupabaseOptions.isConfigured) return false;
    try {
      final rows = await Supabase.instance.client
          .from('app_collections')
          .select('key, items, updated_at');
      return applyRemoteRows(
        (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    } catch (_) {
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> watchRemoteCollections() {
    if (!LabaFlowSupabaseOptions.isConfigured) {
      return const Stream.empty();
    }
    return Supabase.instance.client
        .from('app_collections')
        .stream(primaryKey: ['key'])
        .map(
          (rows) => rows
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
  }

  static int nextId(String key) {
    final list = getList(key);
    if (list.isEmpty) return 1;
    return list.map((e) => e['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  // ── Specific getters/setters ─────────────────────────────

  static List<InventoryItem> getInventory()   => getList('inventory')  .map((e) => InventoryItem.fromJson(e)).toList();
  static List<RfidTag>       getRfidTags()    => getList('rfidTags')   .map((e) => RfidTag.fromJson(e)).toList();
  static List<Order>         getOrders()      => getList('orders')     .map((e) => Order.fromJson(e)).toList();
  static List<Transaction>   getTransactions()=> getList('transactions').map((e) => Transaction.fromJson(e)).toList();
  static List<Message>       getMessages()    => getList('messages')   .map((e) => Message.fromJson(e)).toList();
  static List<RestockLog>    getRestockLog()  => getList('restockLog') .map((e) => RestockLog.fromJson(e)).toList();
  static List<PromoCode>     getPromoCodes()  => getList('promoCodes') .map((e) => PromoCode.fromJson(e)).toList();
  static List<Review>        getReviews()     => getList('reviews')    .map((e) => Review.fromJson(e)).toList();

  static Future<void> saveInventory(List<InventoryItem> v)   => setList('inventory',    v.map((e)=>e.toJson()).toList());
  static Future<void> saveRfidTags(List<RfidTag> v)          => setList('rfidTags',     v.map((e)=>e.toJson()).toList());
  static Future<void> saveOrders(List<Order> v)              => setList('orders',       v.map((e)=>e.toJson()).toList());
  static Future<void> saveTransactions(List<Transaction> v)  => setList('transactions', v.map((e)=>e.toJson()).toList());
  static Future<void> saveMessages(List<Message> v)          => setList('messages',     v.map((e)=>e.toJson()).toList());
  static Future<void> saveRestockLog(List<RestockLog> v)     => setList('restockLog',   v.map((e)=>e.toJson()).toList());
  static Future<void> savePromoCodes(List<PromoCode> v)      => setList('promoCodes',   v.map((e)=>e.toJson()).toList());
  static Future<void> saveReviews(List<Review> v)            => setList('reviews',      v.map((e)=>e.toJson()).toList());

  // ── Seed (runs once when no data exists) ────────────────

  static Future<void> _seed() async {
    // Inventory
    if (!has('inventory') || getInventory().isEmpty) {
      await saveInventory([
        InventoryItem(id:1, name:'Surf Liquid Detergent',   cat:InventoryCat.detergent, unit:'L', qty:12.5, thresh:1.0,  packSize:2.5, packQty:5, perLoad:0.1),
        InventoryItem(id:2, name:'Surf Fabric Conditioner', cat:InventoryCat.softener,  unit:'L', qty:8.0,  thresh:0.8,  packSize:1.6, packQty:5, perLoad:0.1),
        InventoryItem(id:3, name:'Zonrox Color Safe',       cat:InventoryCat.bleach,    unit:'L', qty:4.5,  thresh:0.45, packSize:0.9, packQty:5, perLoad:0.01),
      ]);
      await prefs.setInt('lf3_inv_ver', 4);
    }

    // RFID Tags
    if (!has('rfidTags') || getRfidTags().isEmpty) {
      final tags = List.generate(10, (i) => RfidTag(id: i+1, uid: 'TAG-${(i+1).toString().padLeft(3,'0')}'));
      await saveRfidTags(tags);
    }

    if (!has('orders')) await saveOrders([]);

    if (!has('transactions'))  await setList('transactions', []);
    if (!has('messages'))      await setList('messages', []);
    if (!has('restockLog'))    await setList('restockLog', []);
    if (!has('reviews'))       await setList('reviews', []);
    if (!has('promoCodes')) {
      await savePromoCodes([
        PromoCode(id:1, code:'WELCOME', disc:10, maxUses:100, desc:'Welcome discount for new customers'),
        PromoCode(id:2, code:'LABA20',  disc:20, maxUses:30,  desc:'Special promo - limited time'),
      ]);
    }
  }

  // ── Migration ────────────────────────────────────────────

  static Future<void> _migrate() async {
    final ver = prefs.getInt('lf3_inv_ver') ?? 0;
    if (ver >= 4) return;
    final inv = getInventory();
    if (inv.isNotEmpty) {
      // Patch: ensure perLoad exists (already guaranteed in model but re-save)
      await saveInventory(inv);
    }
    await prefs.setInt('lf3_inv_ver', 4);
  }

  // ── Deduct inventory on order ────────────────────────────

  static Future<List<InventoryItem>> deductInventory(
    OrderType type, double? kg, int? comQty,
  ) async {
    const deductByCat = {
      'DETERGENT': 0.1,
      'SOFTENER':  0.1,
      'BLEACH':    0.01,
    };
    final loads = PricingService.calcLoads(type, kg, comQty);
    final inv = getInventory();
    for (final item in inv) {
      final rate = item.perLoad > 0 ? item.perLoad : (deductByCat[item.cat.key] ?? 0.0);
      if (rate > 0) {
        final deduct = double.parse((rate * loads).toStringAsFixed(4));
        item.qty = double.parse(((item.qty - deduct).clamp(0, double.infinity)).toStringAsFixed(4));
      }
    }
    await saveInventory(inv);
    return inv;
  }

}

