import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/pricing_service.dart';
import '../supabase_options.dart';
import '../services/supabase_auth_service.dart';
import '../services/push_notification_service.dart';

// ═══════════════════════════════════════════════════════════
//  APP STATE PROVIDER
//  Central state management for LabaFlow
// ═══════════════════════════════════════════════════════════

class AppProvider extends ChangeNotifier {
  StreamSubscription<List<Notif>>? _notificationSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _collectionsSubscription;
  Timer? _syncTimer;
  // ── Current user ────────────────────────────────────────
  AppUser? currentUser;

  // The application uses one fixed light theme.

  // ── Loading ──────────────────────────────────────────────
  bool isLoading = false;
  String loadingMsg = '';

  // ── Data caches (reload from DB on demand) ───────────────
  List<AppUser> users = [];
  List<InventoryItem> inventory = [];
  List<RfidTag> rfidTags = [];
  List<Order> orders = [];
  List<Transaction> transactions = [];
  List<Message> messages = [];
  List<RestockLog> restockLog = [];
  List<PromoCode> promoCodes = [];
  List<Notif> notifs = [];
  List<Review> reviews = [];

  // ── Init ────────────────────────────────────────────────

  Future<void> init() async {
    await DBService.init();
    if (LabaFlowSupabaseOptions.isConfigured) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
            final user = state.session?.user;
            final providers =
                user?.appMetadata['providers'] as List? ?? const [];
            final googleLogin =
                user?.appMetadata['provider'] == 'google' ||
                providers.contains('google');
            if (state.event == AuthChangeEvent.signedIn &&
                user != null &&
                googleLogin) {
              _acceptOAuthUser(user);
            }
          });
      try {
        currentUser = await SupabaseAuthService.instance.restoreSession();
        if (currentUser != null) {
          await PushNotificationService.instance.initializeForUser(
            currentUser!,
          );
          _watchNotifications();
        }
      } catch (_) {
        currentUser = null;
      }
      _watchCollections();
    }
    try {
      await reloadAll();
    } catch (_) {
      // A cached Supabase session remains usable for the local workflows
      // while the network is unavailable.
      if (currentUser != null) users = [currentUser!];
    }
    notifyListeners();
  }

  void _watchCollections() {
    _collectionsSubscription?.cancel();
    _collectionsSubscription = DBService.watchRemoteCollections().listen((
      rows,
    ) async {
      final changed = await DBService.applyRemoteRows(rows);
      if (changed) {
        _refreshLocalLists();
        notifyListeners();
      }
    }, onError: (_) {});

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      final changed = await DBService.pullRemoteCollections();
      if (changed) {
        _refreshLocalLists();
        notifyListeners();
      }
    });
  }

  void _refreshLocalLists() {
    inventory = DBService.getInventory();
    rfidTags = DBService.getRfidTags();
    orders = DBService.getOrders();
    transactions = DBService.getTransactions();
    messages = DBService.getMessages();
    restockLog = DBService.getRestockLog();
    promoCodes = DBService.getPromoCodes();
    reviews = DBService.getReviews();
  }

  Future<void> _acceptOAuthUser(User user) async {
    try {
      currentUser = await SupabaseAuthService.instance.restoreSession();
      if (currentUser == null || currentUser!.authUid != user.id) return;
      await PushNotificationService.instance.initializeForUser(currentUser!);
      _watchNotifications();
      await reloadAll();
      notifyListeners();
    } catch (_) {
      currentUser = null;
      notifyListeners();
    }
  }

  void _watchNotifications() {
    _notificationSubscription?.cancel();
    final user = currentUser;
    if (user == null) return;
    _notificationSubscription = PushNotificationService.instance
        .watchNotifications(user)
        .listen((items) {
          notifs = items;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _authSubscription?.cancel();
    _collectionsSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> reloadAll() async {
    await DBService.pullRemoteCollections();
    if (currentUser == null) {
      users = [];
    } else if (currentUser!.role == UserRole.customer) {
      try {
        final refreshed = await SupabaseAuthService.instance.restoreSession();
        if (refreshed != null) currentUser = refreshed;
      } catch (_) {}
      users = [currentUser!];
    } else {
      try {
        users = await SupabaseAuthService.instance.listUsers();
      } catch (_) {
        users = [currentUser!];
      }
    }
    _refreshLocalLists();
    if (currentUser == null) notifs = [];
  }

  // ── Auth ─────────────────────────────────────────────────

  Future<String?> doLogin(String email, String pass) async {
    if (!LabaFlowSupabaseOptions.isConfigured) {
      return LabaFlowSupabaseOptions.setupMessage;
    }
    try {
      currentUser = await SupabaseAuthService.instance.signIn(email, pass);
      await PushNotificationService.instance.initializeForUser(currentUser!);
      _watchNotifications();
      await reloadAll();
      notifyListeners();
      return null;
    } catch (error) {
      return _friendlySupabaseError(error);
    }
  }

  Future<String?> doGoogleSignIn() async {
    if (!LabaFlowSupabaseOptions.isConfigured) {
      return LabaFlowSupabaseOptions.setupMessage;
    }
    try {
      await SupabaseAuthService.instance.signInWithGoogle();
      return null;
    } catch (error) {
      return _friendlySupabaseError(error);
    }
  }

  Future<String?> doRegister({
    required String name,
    required String email,
    required String phone,
    required String pass,
    required String pass2,
  }) async {
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      return 'Name, email and password required.';
    }
    if (pass.length < 6) return 'Password must be at least 6 characters.';
    if (pass != pass2) return 'Passwords do not match.';
    if (!LabaFlowSupabaseOptions.isConfigured) {
      return LabaFlowSupabaseOptions.setupMessage;
    }
    try {
      currentUser = await SupabaseAuthService.instance.register(
        name: name,
        email: email,
        phone: phone,
        password: pass,
      );
      await PushNotificationService.instance.initializeForUser(currentUser!);
      _watchNotifications();
      await reloadAll();
      notifyListeners();
      return null;
    } catch (error) {
      return _friendlySupabaseError(error);
    }
  }

  Future<void> doLogout() async {
    final user = currentUser;
    if (user != null && LabaFlowSupabaseOptions.isConfigured) {
      try {
        await PushNotificationService.instance.removeCurrentDevice(user);
      } catch (_) {}
      await PushNotificationService.instance.stopListening();
      await SupabaseAuthService.instance.signOut();
    }
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    currentUser = null;
    notifs = [];
    notifyListeners();
  }

  String _friendlySupabaseError(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials'))
      return 'Incorrect email or password.';
    if (lower.contains('user already registered') ||
        lower.contains('already been registered'))
      return 'Email already registered.';
    if (lower.contains('password should be') || lower.contains('weak password'))
      return 'Choose a stronger password.';
    if (lower.contains('email not confirmed'))
      return 'Confirm your email, then sign in.';
    if (message.contains('permission-denied'))
      return 'This account does not have access to that action.';
    if (message.contains('unavailable') || message.contains('network'))
      return 'The service is unavailable. Check your connection and retry.';
    if (message.contains('Supabase is not configured'))
      return LabaFlowSupabaseOptions.setupMessage;
    if (error is AuthException) return error.message;
    if (error is StateError) return error.message;
    return 'Supabase request failed. Please try again.';
  }

  // ── Loading indicator ────────────────────────────────────

  void showLoader(String msg) {
    isLoading = true;
    loadingMsg = msg;
    notifyListeners();
  }

  void hideLoader() {
    isLoading = false;
    loadingMsg = '';
    notifyListeners();
  }

  // ── Notifications ────────────────────────────────────────

  List<Notif> myNotifs([AppUser? user]) {
    final u = user ?? currentUser;
    if (u == null) return [];
    return notifs
        .where((n) => n.toId == u.id && _notificationIsCurrent(n, u))
        .toList()
        .reversed
        .toList();
  }

  bool _notificationIsCurrent(Notif notification, AppUser user) {
    if (user.role != UserRole.customer ||
        notification.type.toUpperCase() != 'READY') {
      return true;
    }

    // READY messages are actionable only while their exact order is still
    // waiting for pickup. Orders currently live in the app's order store,
    // while notification history lives in Supabase, so old messages can outlive
    // the order's READY state.
    final readyOrders = orders.where(
      (order) => order.custId == user.id && order.status == OrderStatus.ready,
    );
    final mentionsOrderNumber = RegExp(r'ORD-[A-Z0-9-]+', caseSensitive: false);
    final mentioned = mentionsOrderNumber
        .allMatches('${notification.title} ${notification.msg}')
        .map((match) => match.group(0)!.toUpperCase())
        .toSet();
    if (mentioned.isEmpty) return readyOrders.isNotEmpty;
    return readyOrders.any(
      (order) => mentioned.contains(order.num.toUpperCase()),
    );
  }

  int unreadCount([AppUser? user]) {
    return myNotifs(user).where((n) => !n.read).length;
  }

  Future<void> pushNotif({
    required int toId,
    required String type,
    required String title,
    required String msg,
    String icon = '🔔',
  }) async {
    final target =
        users.where((u) => u.id == toId).firstOrNull ??
        (currentUser?.id == toId ? currentUser : null);
    if (target == null || target.authUid.isEmpty) return;
    await PushNotificationService.instance.notifyUser(
      recipientUid: target.authUid,
      type: type,
      title: title,
      body: msg,
      icon: icon,
    );
  }

  Future<void> markNotifRead(int id) async {
    final user = currentUser;
    final item = notifs.where((n) => n.id == id).firstOrNull;
    if (user != null && item != null)
      await PushNotificationService.instance.markRead(user, item);
  }

  Future<void> markAllNotifsRead() async {
    final user = currentUser;
    if (user != null) await PushNotificationService.instance.markAllRead(user);
  }

  // ── Orders ───────────────────────────────────────────────

  List<Order> ordersForCustomer(int custId) =>
      orders.where((o) => o.custId == custId).toList().reversed.toList();

  Future<Order> createOrder({
    required int custId,
    required String custName,
    required OrderType type,
    double? kg,
    int? comQty,
    ColorDist colorDist = ColorDist.mixed,
    String notes = '',
    required double price,
    required String breakdown,
    double discount = 0,
    String promoCode = '',
  }) async {
    await reloadAll();
    final id = orders.isEmpty
        ? 1
        : orders.map((o) => o.id).reduce((a, b) => a > b ? a : b) + 1;
    final num = 'ORD-${id.toString().padLeft(3, '0')}';
    final order = Order(
      id: id,
      num: num,
      custId: custId,
      custName: custName,
      type: type,
      kg: kg,
      comQty: comQty,
      colorDist: colorDist,
      notes: notes,
      price: price,
      breakdown: breakdown,
      discount: discount,
      promoCode: promoCode,
      created: DateTime.now(),
    );
    orders.add(order);
    await DBService.saveOrders(orders);
    // Deduct inventory on order creation
    final updatedInv = await DBService.deductInventory(type, kg, comQty);
    inventory = updatedInv;
    // Promo uses
    if (promoCode.isNotEmpty) {
      final pi = promoCodes.indexWhere(
        (p) => p.code.toUpperCase() == promoCode && p.active,
      );
      if (pi >= 0) {
        promoCodes[pi].uses++;
        await DBService.savePromoCodes(promoCodes);
      }
    }
    await pushNotif(
      toId: custId,
      type: 'ORDER_PLACED',
      title: 'Order $num placed',
      msg: 'Your ${type.label} order has been received. Drop off at the shop.',
      icon: '🧺',
    );
    notifyListeners();
    return order;
  }

  Future<void> assignRfid(int ordId, int tagId) async {
    await reloadAll();
    final oi = orders.indexWhere((o) => o.id == ordId);
    final ti = rfidTags.indexWhere((t) => t.id == tagId);
    if (oi < 0 || ti < 0) return;
    orders[oi].tagId = tagId;
    orders[oi].status = OrderStatus.received;
    orders[oi].dropOff = DateTime.now();
    rfidTags[ti] = RfidTag(
      id: tagId,
      uid: rfidTags[ti].uid,
      available: false,
      orderId: ordId,
    );
    await DBService.saveOrders(orders);
    await DBService.saveRfidTags(rfidTags);
    notifyListeners();
  }

  bool orderIsPaid(int ordId) => transactions.any((t) => t.orderId == ordId);

  Future<void> advanceOrder(int ordId) async {
    await reloadAll();
    final oi = orders.indexWhere((o) => o.id == ordId);
    if (oi < 0) return;
    final o = orders[oi];
    final next = o.status.next;
    if (next == null || o.tagId == null) return;
    o.status = next;
    if (next == OrderStatus.received) o.dropOff = DateTime.now();
    if (next == OrderStatus.processing) {
      inventory = await DBService.deductInventory(o.type, o.kg, o.comQty);
    }
    if (next == OrderStatus.ready) o.ready = DateTime.now();
    if (next == OrderStatus.released) {
      o.pickup = DateTime.now();
      o.finalPrice = o.price;
      final ti = rfidTags.indexWhere((t) => t.id == o.tagId);
      if (ti >= 0)
        rfidTags[ti] = RfidTag(
          id: rfidTags[ti].id,
          uid: rfidTags[ti].uid,
          available: true,
          orderId: null,
        );
      await DBService.saveRfidTags(rfidTags);
      final pts = await SupabaseAuthService.instance.addLoyaltyPoints(
        o.custId,
        o.price,
      );
      users = await SupabaseAuthService.instance.listUsers();
      await pushNotif(
        toId: o.custId,
        type: 'RELEASED',
        title: 'Order ${o.num} released',
        msg: 'Order complete. +$pts LabaPoints earned!',
        icon: '🎉',
      );
    }
    await DBService.saveOrders(orders);

    // Notif map
    const notifMap = {
      'RECEIVED': ('📡', 'has been received and tagged with RFID.'),
      'PROCESSING': ('🫧', 'is currently being washed and dried.'),
      'READY': ('✅', 'is READY for pickup. Please proceed to the shop.'),
    };
    final entry = notifMap[next.key];
    if (entry != null) {
      await pushNotif(
        toId: o.custId,
        type: next.key,
        title: 'Order ${o.num} ${next.key.toLowerCase()}',
        msg: 'Your ${o.type.label} order ${entry.$2}',
        icon: entry.$1,
      );
    }
    notifyListeners();
  }

  Future<void> recordPayment({
    required int ordId,
    required double amount,
    required PaymentChannel channel,
    String gcashRef = '',
  }) async {
    await reloadAll();
    final oi = orders.indexWhere((o) => o.id == ordId);
    if (oi < 0) return;
    final o = orders[oi];
    final id = transactions.isEmpty
        ? 1
        : transactions.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    final txn = Transaction(
      id: id,
      num: 'TXN-${id.toString().padLeft(4, '0')}',
      orderId: ordId,
      orderNum: o.num,
      custName: o.custName,
      amount: amount,
      channel: channel,
      gcashRef: gcashRef,
      promoCode: o.promoCode,
      rcpt: 'RCP-$ordId-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
    );
    transactions.add(txn);
    o.finalPrice = amount;
    if (o.status == OrderStatus.ready) {
      o.status = OrderStatus.released;
      o.pickup = DateTime.now();
      final ti = rfidTags.indexWhere((t) => t.id == o.tagId);
      if (ti >= 0)
        rfidTags[ti] = RfidTag(
          id: rfidTags[ti].id,
          uid: rfidTags[ti].uid,
          available: true,
          orderId: null,
        );
      await DBService.saveRfidTags(rfidTags);
      final pts = await SupabaseAuthService.instance.addLoyaltyPoints(
        o.custId,
        amount,
      );
      users = await SupabaseAuthService.instance.listUsers();
      await pushNotif(
        toId: o.custId,
        type: 'RELEASED',
        title: 'Order ${o.num} released',
        msg: 'Paid ${_peso(amount)}. +$pts LabaPoints earned!',
        icon: '✅',
      );
    }
    await DBService.saveTransactions(transactions);
    await DBService.saveOrders(orders);
    notifyListeners();
  }

  // ── Inventory ────────────────────────────────────────────

  Future<void> restockItem(
    int itemId,
    double qty, {
    double? costPerUnit,
  }) async {
    await reloadAll();
    final ii = inventory.indexWhere((i) => i.id == itemId);
    if (ii < 0) return;
    final before = inventory[ii].qty;
    inventory[ii].qty = double.parse(
      (inventory[ii].qty + qty).toStringAsFixed(4),
    );
    await DBService.saveInventory(inventory);
    final log = restockLog;
    final id = log.isEmpty
        ? 1
        : log.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    log.add(
      RestockLog(
        id: id,
        itemId: itemId,
        itemName: inventory[ii].name,
        unit: inventory[ii].unit,
        qty: qty,
        before: before,
        after: inventory[ii].qty,
        costPerUnit: costPerUnit,
        totalCost: costPerUnit != null ? costPerUnit * qty : null,
        date: DateTime.now(),
        by: currentUser?.name ?? '—',
      ),
    );
    await DBService.saveRestockLog(log);
    restockLog = log;
    notifyListeners();
  }

  // ── Messages ─────────────────────────────────────────────

  Future<void> sendMessage({
    required int fromId,
    required int toId,
    required String text,
  }) async {
    await reloadAll();
    final id = messages.isEmpty
        ? 1
        : messages.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
    messages.add(
      Message(
        id: id,
        fromId: fromId,
        toId: toId,
        text: text,
        date: DateTime.now(),
      ),
    );
    await DBService.saveMessages(messages);
    notifyListeners();
  }

  Future<void> markMessagesRead(int fromId) async {
    bool changed = false;
    for (final m in messages) {
      if (m.fromId == fromId && !m.read) {
        m.read = true;
        changed = true;
      }
    }
    if (changed) await DBService.saveMessages(messages);
    notifyListeners();
  }

  // ── Profile ──────────────────────────────────────────────

  Future<String?> saveProfile({
    required String name,
    required String email,
    required String phone,
    String? pass,
    String? pic,
  }) async {
    if (name.isEmpty || email.isEmpty) return 'Name and email are required.';
    final user = currentUser;
    if (user == null) return 'Sign in again to update your profile.';
    if (pass != null && pass.isNotEmpty && pass.length < 6) {
      return 'New password must be at least 6 characters.';
    }
    try {
      currentUser = await SupabaseAuthService.instance.updateProfile(
        current: user,
        name: name,
        email: email,
        phone: phone,
        password: pass,
        photoUrl: pic,
      );
      users = users
          .map((u) => u.authUid == currentUser!.authUid ? currentUser! : u)
          .toList();
      notifyListeners();
      return null;
    } catch (error) {
      return _friendlySupabaseError(error);
    }
  }

  // ── Reviews ──────────────────────────────────────────────

  Future<void> addReview({
    required String name,
    required String service,
    required String text,
    required int rating,
  }) async {
    await reloadAll();
    final id = reviews.isEmpty
        ? 1
        : reviews.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    reviews.add(
      Review(
        id: id,
        name: name,
        service: service,
        text: text,
        rating: rating,
        date: DateTime.now(),
      ),
    );
    await DBService.saveReviews(reviews);
    notifyListeners();
  }

  double get avgRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;
  }

  // ── Promo codes (Admin) ──────────────────────────────────

  Future<void> savePromoCode(PromoCode pc) async {
    await reloadAll();
    final idx = promoCodes.indexWhere((p) => p.id == pc.id);
    if (idx >= 0)
      promoCodes[idx] = pc;
    else
      promoCodes.add(pc);
    await DBService.savePromoCodes(promoCodes);
    notifyListeners();
  }

  Future<void> deletePromoCode(int id) async {
    promoCodes.removeWhere((p) => p.id == id);
    await DBService.savePromoCodes(promoCodes);
    notifyListeners();
  }

  // ── User management (Admin) ──────────────────────────────

  Future<void> saveUser(AppUser u, {String? password}) async {
    final idx = users.indexWhere((x) => x.id == u.id);
    final saved = await SupabaseAuthService.instance.saveUserProfile(
      u,
      invitePassword: password,
    );
    if (idx >= 0)
      users[idx] = saved;
    else
      users.add(saved);
    notifyListeners();
  }

  Future<void> deleteUser(int id) async {
    final user = users.where((u) => u.id == id).firstOrNull;
    if (user == null) return;
    await SupabaseAuthService.instance.deleteUserProfile(user);
    users.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  // ── RFID (Seller) ────────────────────────────────────────

  Future<void> registerTag(String uid) async {
    await reloadAll();
    final id = rfidTags.isEmpty
        ? 1
        : rfidTags.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    rfidTags.add(RfidTag(id: id, uid: uid));
    await DBService.saveRfidTags(rfidTags);
    notifyListeners();
  }

  Future<void> releaseTag(int tagId) async {
    final ti = rfidTags.indexWhere((t) => t.id == tagId);
    if (ti < 0) return;
    rfidTags[ti] = RfidTag(
      id: rfidTags[ti].id,
      uid: rfidTags[ti].uid,
      available: true,
      orderId: null,
    );
    await DBService.saveRfidTags(rfidTags);
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────

  List<InventoryItem> get lowStockItems =>
      inventory.where((i) => i.qty <= i.thresh).toList();

  PromoResult applyPromo(String code, double basePrice) =>
      PricingService.applyPromo(code, basePrice, promoCodes);

  String _peso(double n) => '₱${n.toStringAsFixed(2)}';
}
