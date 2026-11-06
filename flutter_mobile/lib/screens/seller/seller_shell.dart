import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/pricing_service.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  SELLER SHELL
// ═══════════════════════════════════════════════════════════

class SellerShell extends StatefulWidget {
  const SellerShell({super.key});
  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _navIdx = 0;
  bool _notifOpen = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    (Icons.receipt_long_outlined, 'Orders'),
    (Icons.inventory_2_outlined, 'Inventory'),
    (Icons.bar_chart_outlined, 'Reports'),
    (Icons.chat_bubble_outline, 'Messages'),
    (Icons.nfc_outlined, 'RFID Tags'),
  ];

  Widget _page(AppProvider p) {
    switch (_navIdx) {
      case 0:
        return SellerOrdersPage(provider: p);
      case 1:
        return SellerInventoryPage(provider: p);
      case 2:
        return SellerReportsPage(provider: p);
      case 3:
        return SellerMessagesPage(provider: p);
      case 4:
        return SellerRfidPage(provider: p);
      default:
        return SellerOrdersPage(provider: p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width >= 900;
    final user = provider.currentUser;

    final sidebar = _SellerSidebar(
      navIdx: _navIdx,
      navItems: _navItems,
      user: user,
      onNav: (i) {
        setState(() => _navIdx = i);
        if (!isWide) Navigator.pop(context);
      },
      onSignOut: () async {
        final ok = await showConfirmDialog(
          context,
          title: 'Sign Out',
          message: 'Sign out of your account?',
        );
        if (ok && mounted) {
          await provider.doLogout();
          if (mounted) context.go('/');
        }
      },
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 226, child: sidebar),
            Expanded(
              child: Column(
                children: [
                  _SellerTopBar(
                    title: _navItems[_navIdx].$2,
                    provider: provider,
                    onNotif: () => setState(() => _notifOpen = !_notifOpen),
                    isWide: true,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(child: OceanicBubbleBackground()),
                        _page(provider),
                        if (_notifOpen)
                          _SellerNotifPanel(
                            provider: provider,
                            onClose: () => setState(() => _notifOpen = false),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _navItems[_navIdx].$2,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: provider.unreadCount() > 0,
              label: Text('${provider.unreadCount()}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => setState(() => _notifOpen = !_notifOpen),
          ),
        ],
      ),
      drawer: Drawer(child: sidebar),
      body: Stack(
        children: [
          const Positioned.fill(child: OceanicBubbleBackground()),
          _page(provider),
          if (_notifOpen)
            _SellerNotifPanel(
              provider: provider,
              onClose: () => setState(() => _notifOpen = false),
            ),
        ],
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────

class _SellerSidebar extends StatelessWidget {
  final int navIdx;
  final List<(IconData, String)> navItems;
  final AppUser? user;
  final ValueChanged<int> onNav;
  final VoidCallback onSignOut;
  const _SellerSidebar({
    required this.navIdx,
    required this.navItems,
    required this.user,
    required this.onNav,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightSidebar,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lightBtn,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LabaFlow',
                  style: TextStyle(
                    color: AppColors.lightText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.lightBorder, height: 1),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _SInitialsAvatar(name: user!.name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user!.name,
                          style: const TextStyle(
                            color: AppColors.lightText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Seller',
                          style: TextStyle(
                            color: AppColors.lightMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Divider(color: AppColors.lightBorder, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: navItems.length,
              itemBuilder: (ctx, i) {
                final item = navItems[i];
                final active = i == navIdx;
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.lightBtn.withOpacity(0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: active
                        ? const Border(
                            left: BorderSide(
                              color: AppColors.lightAccent2,
                              width: 3,
                            ),
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.$1,
                      color: active
                          ? AppColors.lightAccent2
                          : AppColors.lightMuted,
                      size: 20,
                    ),
                    title: Text(
                      item.$2,
                      style: TextStyle(
                        color: active
                            ? AppColors.lightAccent2
                            : AppColors.lightMuted,
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => onNav(i),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(color: AppColors.lightBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerTopBar extends StatelessWidget {
  final String title;
  final AppProvider provider;
  final bool isWide;
  final VoidCallback onNotif;
  const _SellerTopBar({
    required this.title,
    required this.provider,
    required this.isWide,
    required this.onNotif,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        border: const Border(bottom: BorderSide(color: AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('EEE, MMM d').format(DateTime.now()),
            style: theme.textTheme.bodySmall,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: provider.unreadCount() > 0,
              label: Text(
                '${provider.unreadCount()}',
                style: const TextStyle(fontSize: 9),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            onPressed: onNotif,
          ),
        ],
      ),
    );
  }
}

class _SellerNotifPanel extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback onClose;
  const _SellerNotifPanel({required this.provider, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final notifs = provider.myNotifs();
    const panelBg = AppColors.lightCard;
    const border = AppColors.lightBorder;
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: onClose,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: panelBg,
                  border: Border(left: BorderSide(color: border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => provider.markAllNotifsRead(),
                            child: const Text(
                              'Mark all read',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: border),
                    Expanded(
                      child: notifs.isEmpty
                          ? const Center(child: Text('No notifications'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: notifs.length,
                              itemBuilder: (_, i) {
                                final n = notifs[i];
                                return ListTile(
                                  dense: true,
                                  leading: Text(
                                    n.icon,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  title: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: n.read
                                          ? FontWeight.normal
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    n.msg,
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => provider.markNotifRead(n.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: ORDERS
// ═══════════════════════════════════════════════════════════

class SellerOrdersPage extends StatefulWidget {
  final AppProvider provider;
  const SellerOrdersPage({super.key, required this.provider});
  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  String _filter = 'ALL';
  final _searchC = TextEditingController();
  String _search = '';
  bool _showSuggestions = false;

  static const _filters = [
    'ALL',
    'PENDING',
    'RECEIVED',
    'PROCESSING',
    'READY',
    'RELEASED',
  ];

  List<Order> get _filtered {
    var list = widget.provider.orders;
    if (_filter != 'ALL')
      list = list.where((o) => o.status.key == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (o) =>
                o.num.toLowerCase().contains(q) ||
                o.custName.toLowerCase().contains(q) ||
                o.status.key.toLowerCase().contains(q),
          )
          .toList();
    }
    return [...list]..sort((a, b) => b.created.compareTo(a.created));
  }

  void _openNewOrder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewOrderSheet(provider: widget.provider),
    );
  }

  void _openPayment([Order? order]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _RecordPaymentSheet(provider: widget.provider, preselected: order),
    );
  }

  void _openDetail(Order o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(provider: widget.provider, order: o),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = _filtered;
    final allOrders = widget.provider.orders;
    final waiting = allOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final inProgress = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.received ||
              o.status == OrderStatus.processing,
        )
        .length;
    final ready = allOrders.where((o) => o.status == OrderStatus.ready).length;
    final released = allOrders
        .where((o) => o.status == OrderStatus.released)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Order overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SellerOrderMetric(
                'Total orders',
                '${allOrders.length}',
                Icons.receipt_long_outlined,
                AppColors.lightAccent,
              ),
              _SellerOrderMetric(
                'Pending',
                '$waiting',
                Icons.schedule_outlined,
                AppColors.statusPending,
              ),
              _SellerOrderMetric(
                'In progress',
                '$inProgress',
                Icons.local_laundry_service_outlined,
                AppColors.statusReceived,
              ),
              _SellerOrderMetric(
                'Ready',
                '$ready',
                Icons.check_circle_outline,
                AppColors.statusReady,
              ),
              _SellerOrderMetric(
                'Released',
                '$released',
                Icons.task_alt,
                AppColors.statusReleased,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Toolbar
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    TextField(
                      controller: _searchC,
                      decoration: InputDecoration(
                        hintText: 'Search orders, customers...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() {
                        _search = v;
                        _showSuggestions = v.isNotEmpty;
                      }),
                      onTap: () {
                        if (_searchC.text.isNotEmpty)
                          setState(() => _showSuggestions = true);
                      },
                    ),
                    if (_showSuggestions)
                      Positioned(
                        top: 46,
                        left: 0,
                        right: 0,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          color: theme.cardColor,
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            children: widget.provider.orders
                                .where((o) {
                                  final q = _searchC.text.toLowerCase();
                                  return o.num.toLowerCase().contains(q) ||
                                      o.custName.toLowerCase().contains(q) ||
                                      o.status.key.toLowerCase().contains(q);
                                })
                                .take(6)
                                .map(
                                  (o) => ListTile(
                                    dense: true,
                                    leading: StatusBadge(o.status),
                                    title: Text(
                                      o.num,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    subtitle: Text(
                                      o.custName,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _searchC.text = o.num;
                                        _search = o.num;
                                        _showSuggestions = false;
                                      });
                                      _openDetail(o);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _openNewOrder,
                icon: const Icon(Icons.add, size: 15),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _filter == f ? Colors.white : null,
                          ),
                        ),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.lightBtn,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: _filter == f
                              ? AppColors.lightBtn
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Orders table
          AppCard(
            title: 'Orders (${orders.length})',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 34,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 56,
                headingTextStyle: theme.textTheme.labelSmall,
                columns: const [
                  DataColumn(label: Text('ORDER')),
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('KG/QTY')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('PRICE')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: orders
                    .map(
                      (o) => DataRow(
                        cells: [
                          DataCell(
                            GestureDetector(
                              onTap: () => _openDetail(o),
                              child: Text(
                                o.num,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.lightAccent2,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              o.custName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              o.type.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(() {
                              if (o.type == OrderType.comforter)
                                return '${o.comQty ?? 1} pc';
                              return o.kg != null ? '${o.kg} kg' : '—';
                            }(), style: const TextStyle(fontSize: 11)),
                          ),
                          DataCell(StatusBadge(o.status)),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₱${o.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (o.status == OrderStatus.ready &&
                                    !widget.provider.orderIsPaid(o.id))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warn.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'UNPAID',
                                      style: TextStyle(
                                        color: AppColors.warn,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat('MMM d').format(o.created),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (o.status == OrderStatus.ready &&
                                    !widget.provider.orderIsPaid(o.id))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.payment,
                                      size: 16,
                                      color: AppColors.warn,
                                    ),
                                    tooltip: 'Record Payment',
                                    onPressed: () => _openPayment(o),
                                  ),
                                if (o.status.next != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: AppColors.lightAccent2,
                                    ),
                                    tooltip: 'Advance Status',
                                    onPressed: () async {
                                      if (o.tagId == null &&
                                          o.status == OrderStatus.pending) {
                                        await showErrorDialog(
                                          context,
                                          'Assign an RFID tag before advancing this order.',
                                        );
                                        return;
                                      }
                                      await widget.provider.advanceOrder(o.id);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Order Bottom Sheet ─────────────────────────────────────

class _NewOrderSheet extends StatefulWidget {
  final AppProvider provider;
  const _NewOrderSheet({required this.provider});
  @override
  State<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<_NewOrderSheet> {
  OrderType _type = OrderType.clothes;
  ColorDist _colorDist = ColorDist.mixed;
  double? _kg;
  int? _comQty;
  String _promoCode = '';
  String _promoMsg = '';
  double _discount = 0;
  String _notes = '';
  AppUser? _customer;
  bool _loading = false;

  final _kgC = TextEditingController();
  final _comC = TextEditingController();
  final _promoC = TextEditingController();
  final _notesC = TextEditingController();

  PriceResult get _priceResult => PricingService.calcPrice(_type, _kg, _comQty);

  void _calcPromo() {
    if (_promoC.text.trim().isEmpty) {
      setState(() {
        _promoMsg = '';
        _discount = 0;
        _promoCode = '';
      });
      return;
    }
    final r = widget.provider.applyPromo(
      _promoC.text.trim(),
      _priceResult.price,
    );
    setState(() {
      _promoMsg = r.promoMsg;
      _discount = r.discount;
      _promoCode = _promoC.text.trim().toUpperCase();
    });
  }

  Future<void> _submit() async {
    final cust = _customer;
    if (cust == null) {
      await showErrorDialog(context, 'Select a customer.');
      return;
    }
    final pr = _priceResult;
    if (pr.price <= 0) {
      await showErrorDialog(context, 'Enter valid weight or quantity.');
      return;
    }
    setState(() => _loading = true);
    await widget.provider.createOrder(
      custId: cust.id,
      custName: cust.name,
      type: _type,
      kg: _kg,
      comQty: _comQty,
      colorDist: _colorDist,
      notes: _notes,
      price: pr.price,
      breakdown: pr.breakdown,
      discount: _discount,
      promoCode: _promoCode,
    );
    if (mounted) Navigator.pop(context);
    if (mounted)
      await showSuccessDialog(
        context,
        'Order Created!',
        'Order placed for ${cust.name}.',
      );
  }

  @override
  void dispose() {
    for (final c in [_kgC, _comC, _promoC, _notesC]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.lightCard;
    final pr = _priceResult;
    final finalPrice = pr.price - _discount;
    final customers = widget.provider.users
        .where((u) => u.role == UserRole.customer)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'New Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Customer selector
            const Text(
              'CUSTOMER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lightMuted,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<AppUser>(
              value: _customer,
              hint: const Text('Select customer'),
              items: customers
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                  .toList(),
              onChanged: (v) => setState(() => _customer = v),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Type selector
            const Text(
              'SERVICE TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lightMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OrderType.values
                  .map(
                    (t) => ChoiceChip(
                      label: Text(
                        t.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _type == t,
                      onSelected: (_) => setState(() {
                        _type = t;
                        _kg = null;
                        _comQty = null;
                        _kgC.clear();
                        _comC.clear();
                      }),
                      selectedColor: AppColors.lightBtn,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Weight / quantity
            if (_type == OrderType.clothes ||
                _type == OrderType.bedsheet ||
                _type == OrderType.washOnly ||
                _type == OrderType.dryOnly)
              _SField(
                controller: _kgC,
                label: 'WEIGHT (KG)',
                hint: 'e.g. 7.5',
                type: TextInputType.number,
                onChanged: (v) => setState(() => _kg = double.tryParse(v)),
              )
            else if (_type == OrderType.comforter)
              _SField(
                controller: _comC,
                label: 'QUANTITY (PCS)',
                hint: 'e.g. 2',
                type: TextInputType.number,
                onChanged: (v) => setState(() => _comQty = int.tryParse(v)),
              ),
            if (_type == OrderType.clothes) ...[
              const SizedBox(height: 12),
              const Text(
                'COLOR SEPARATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ColorDist.values
                    .map(
                      (c) => ChoiceChip(
                        label: Text(
                          c.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _colorDist == c,
                        onSelected: (_) => setState(() => _colorDist = c),
                        selectedColor: AppColors.lightBtn,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            // Promo
            Row(
              children: [
                Expanded(
                  child: _SField(
                    controller: _promoC,
                    label: 'PROMO CODE',
                    hint: 'e.g. LABA20',
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: ElevatedButton(
                    onPressed: _calcPromo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            if (_promoMsg.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _promoMsg,
                style: TextStyle(
                  fontSize: 12,
                  color: _discount > 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SField(
              controller: _notesC,
              label: 'SPECIAL INSTRUCTIONS',
              hint: 'Any notes...',
              onChanged: (v) => setState(() => _notes = v),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Price breakdown
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBtn.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBtn.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  if (pr.breakdown.isNotEmpty)
                    Row(
                      children: [
                        const Text(
                          'Breakdown:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            pr.breakdown,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Price:', style: TextStyle(fontSize: 13)),
                      Text(
                        '₱${pr.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (_discount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount:',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '-₱${_discount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '₱${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.lightBtn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryBtn(
              label: 'Create Order',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType type;
  final ValueChanged<String> onChanged;
  final int maxLines;
  const _SField({
    required this.controller,
    required this.label,
    required this.hint,
    this.type = TextInputType.text,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.lightMuted,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
      ],
    );
  }
}

// ── Record Payment Bottom Sheet ────────────────────────────────

class _RecordPaymentSheet extends StatefulWidget {
  final AppProvider provider;
  final Order? preselected;
  const _RecordPaymentSheet({required this.provider, this.preselected});
  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  Order? _order;
  PaymentChannel _channel = PaymentChannel.cash;
  final _amtC = TextEditingController();
  final _refC = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.preselected;
    if (_order != null) _amtC.text = _order!.price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amtC.dispose();
    _refC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final o = _order;
    if (o == null) {
      await showErrorDialog(context, 'Select an order.');
      return;
    }
    final amt = double.tryParse(_amtC.text.trim());
    if (amt == null || amt <= 0) {
      await showErrorDialog(context, 'Enter a valid amount.');
      return;
    }
    if (_channel == PaymentChannel.gcash && _refC.text.trim().length < 8) {
      await showErrorDialog(
        context,
        'GCash reference must be at least 8 characters.',
      );
      return;
    }
    setState(() => _loading = true);
    await widget.provider.recordPayment(
      ordId: o.id,
      amount: amt,
      channel: _channel,
      gcashRef: _refC.text.trim(),
    );
    if (mounted) Navigator.pop(context);
    if (mounted)
      await showSuccessDialog(
        context,
        'Payment Recorded!',
        '₱${amt.toStringAsFixed(2)} recorded for ${o.num}.',
      );
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.lightCard;
    final readyOrders = widget.provider.orders
        .where(
          (o) =>
              o.status == OrderStatus.ready &&
              !widget.provider.orderIsPaid(o.id),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Record Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'ORDER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lightMuted,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<Order>(
              value: _order,
              hint: const Text('Select order to pay'),
              items: readyOrders
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        '${o.num} — ${o.custName} (₱${o.price.toStringAsFixed(2)})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _order = v;
                if (v != null) _amtC.text = v.price.toStringAsFixed(2);
              }),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SField(
              controller: _amtC,
              label: 'AMOUNT (₱)',
              hint: '0.00',
              type: TextInputType.number,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            const Text(
              'PAYMENT CHANNEL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lightMuted,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _channel = PaymentChannel.cash),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _channel == PaymentChannel.cash
                            ? AppColors.success.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: _channel == PaymentChannel.cash
                              ? AppColors.success
                              : AppColors.lightBorder,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Text('💵', style: TextStyle(fontSize: 24)),
                          SizedBox(height: 4),
                          Text(
                            'Cash',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _channel = PaymentChannel.gcash),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _channel == PaymentChannel.gcash
                            ? AppColors.lightAccent2.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: _channel == PaymentChannel.gcash
                              ? AppColors.lightAccent2
                              : AppColors.lightBorder,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Text('📱', style: TextStyle(fontSize: 24)),
                          SizedBox(height: 4),
                          Text(
                            'GCash',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_channel == PaymentChannel.gcash) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightAccent2.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.lightAccent2.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.lightAccent2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Scan QR code to pay via GCash\nAccount: 09XX XXX XXXX\nLab-a-Day Laundry',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SField(
                controller: _refC,
                label: 'GCASH REFERENCE NUMBER *',
                hint: 'Min 8 characters',
                onChanged: (_) {},
              ),
            ],
            const SizedBox(height: 20),
            PrimaryBtn(
              label: 'Record Payment',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Detail Bottom Sheet ────────────────────────────────

class _OrderDetailSheet extends StatelessWidget {
  final AppProvider provider;
  final Order order;
  const _OrderDetailSheet({required this.provider, required this.order});

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.lightCard;
    final isPaid = provider.orderIsPaid(order.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  order.num,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                StatusBadge(order.status),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline
                  OrderTimeline(currentStatus: order.status),
                  const SizedBox(height: 20),
                  // Details grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _DetailChip('Customer', order.custName),
                      _DetailChip('Type', order.type.label),
                      if (order.kg != null)
                        _DetailChip('Weight', '${order.kg} kg'),
                      if (order.comQty != null)
                        _DetailChip('Qty', '${order.comQty} pc(s)'),
                      if (order.type == OrderType.clothes)
                        _DetailChip('Color', order.colorDist.label),
                      _DetailChip(
                        'Price',
                        '₱${order.price.toStringAsFixed(2)}',
                      ),
                      if (order.discount > 0)
                        _DetailChip(
                          'Discount',
                          '-₱${order.discount.toStringAsFixed(2)}',
                        ),
                      if (order.promoCode.isNotEmpty)
                        _DetailChip('Promo', order.promoCode),
                      if (order.dropOff != null)
                        _DetailChip(
                          'Drop Off',
                          DateFormat('MMM d HH:mm').format(order.dropOff!),
                        ),
                      if (order.ready != null)
                        _DetailChip(
                          'Ready At',
                          DateFormat('MMM d HH:mm').format(order.ready!),
                        ),
                      if (order.pickup != null)
                        _DetailChip(
                          'Picked Up',
                          DateFormat('MMM d HH:mm').format(order.pickup!),
                        ),
                      if (order.tagId != null)
                        _DetailChip('RFID Tag', '#${order.tagId}'),
                    ],
                  ),
                  if (order.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailChip('Notes', order.notes),
                  ],
                  const SizedBox(height: 20),
                  if (order.breakdown.isNotEmpty)
                    NoticeBanner(text: 'Breakdown: ${order.breakdown}'),
                  // Actions
                  if (order.status == OrderStatus.ready && !isPaid) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _RecordPaymentSheet(
                              provider: provider,
                              preselected: order,
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Record Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warn,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  if (order.status.next != null &&
                      !(order.status == OrderStatus.ready && !isPaid)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (order.tagId == null) {
                            await showErrorDialog(
                              context,
                              'Assign RFID tag first.',
                            );
                            return;
                          }
                          if (order.status == OrderStatus.ready && !isPaid) {
                            await showErrorDialog(
                              context,
                              'Record payment before releasing.',
                            );
                            return;
                          }
                          await provider.advanceOrder(order.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'Advance to ${order.status.next?.key ?? ''}',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label, value;
  const _DetailChip(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.lightMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SellerOrderMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SellerOrderMetric(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 132),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.lightBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.lightMuted),
            ),
          ],
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  PAGE: INVENTORY
// ═══════════════════════════════════════════════════════════

class SellerInventoryPage extends StatefulWidget {
  final AppProvider provider;
  const SellerInventoryPage({super.key, required this.provider});
  @override
  State<SellerInventoryPage> createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage> {
  final _searchC = TextEditingController();
  String _query = '';
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.provider.reloadAll();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Inventory refreshed.')));
    } catch (error) {
      if (mounted)
        await showErrorDialog(context, 'Could not refresh inventory: $error');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _openRestock(InventoryItem item) {
    final _qtyC = TextEditingController();
    final _costC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 80, 0, 0),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restock ${item.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _qtyC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity to add (${item.unit})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _costC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cost per unit (optional)',
                    prefixText: '₱',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryBtn(
                  label: 'Add Stock',
                  onPressed: () async {
                    final qty = double.tryParse(_qtyC.text);
                    if (qty == null || qty <= 0) {
                      await showErrorDialog(context, 'Enter a valid quantity.');
                      return;
                    }
                    final cost = double.tryParse(_costC.text);
                    await widget.provider.restockItem(
                      item.id,
                      qty,
                      costPerUnit: cost,
                    );
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted)
                      await showSuccessDialog(
                        context,
                        'Restocked!',
                        '${item.name} updated.',
                      );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventory = widget.provider.inventory;
    final filtered = inventory
        .where(
          (item) => '${item.name} ${item.cat.key}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    final lowCount = inventory.where((item) => item.isLow).length;
    final outCount = inventory.where((item) => item.qty <= 0).length;
    final categoryCount = inventory.map((item) => item.cat).toSet().length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InventorySummary(
                label: 'Inventory items',
                value: '${inventory.length}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.lightAccent,
              ),
              _InventorySummary(
                label: 'Low stock',
                value: '$lowCount',
                icon: Icons.warning_amber_rounded,
                color: lowCount > 0 ? AppColors.warn : AppColors.success,
              ),
              _InventorySummary(
                label: 'Out of stock',
                value: '$outCount',
                icon: Icons.remove_shopping_cart_outlined,
                color: outCount > 0 ? AppColors.danger : AppColors.success,
              ),
              _InventorySummary(
                label: 'Categories',
                value: '$categoryCount',
                icon: Icons.category_outlined,
                color: AppColors.lightAccent2,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            title: 'Inventory',
            trailing: IconButton(
              tooltip: 'Refresh inventory',
              onPressed: _refreshing ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchC,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search item or category',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      inventory.isEmpty
                          ? 'No inventory items are available.'
                          : 'No inventory items match your search.',
                      style: const TextStyle(color: AppColors.lightMuted),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowHeight: 34,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 56,
                      headingTextStyle: theme.textTheme.labelSmall,
                      columns: const [
                        DataColumn(label: Text('ITEM')),
                        DataColumn(label: Text('QTY')),
                        DataColumn(label: Text('THRESHOLD')),
                        DataColumn(label: Text('LEVEL')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: filtered
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    item.isLiquid
                                        ? '${item.qtyMl} mL'
                                        : '${item.qty} ${item.unit}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${item.thresh} ${item.unit}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 110,
                                    child: LevelBar(pct: item.pct),
                                  ),
                                ),
                                DataCell(
                                  item.isLow
                                      ? const Text(
                                          '⚠ LOW',
                                          style: TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : const Text(
                                          'OK',
                                          style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 11,
                                          ),
                                        ),
                                ),
                                DataCell(
                                  ElevatedButton.icon(
                                    onPressed: () => _openRestock(item),
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text(
                                      'Restock',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InventorySummary({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 145),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.lightBorder),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.lightMuted),
            ),
          ],
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  PAGE: REPORTS
// ═══════════════════════════════════════════════════════════

class SellerReportsPage extends StatelessWidget {
  final AppProvider provider;
  const SellerReportsPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final txns = provider.transactions;

    final todayTxns = txns
        .where(
          (t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .toList();
    final monthTxns = txns
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    final completedOrders = provider.orders
        .where((o) => o.status == OrderStatus.released)
        .length;

    final todayRev = todayTxns.fold<double>(0, (s, t) => s + t.amount);
    final monthRev = monthTxns.fold<double>(0, (s, t) => s + t.amount);

    final todayCash = todayTxns
        .where((t) => t.channel == PaymentChannel.cash)
        .fold<double>(0, (s, t) => s + t.amount);
    final todayGcash = todayTxns
        .where((t) => t.channel == PaymentChannel.gcash)
        .fold<double>(0, (s, t) => s + t.amount);

    // Revenue by service type
    final byService = <String, double>{};
    for (final o in provider.orders.where(
      (o) => o.status == OrderStatus.released,
    )) {
      final key = o.type.label;
      byService[key] = (byService[key] ?? 0) + o.price;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (_, c) {
              final cols = c.maxWidth > 600 ? 3 : 1;
              return _SReportCards(
                cols: cols,
                children: [
                  _WhiteStatCard(
                    "Today's Revenue",
                    '₱${NumberFormat('#,##0.00').format(todayRev)}',
                    AppColors.success,
                  ),
                  _WhiteStatCard(
                    "This Month",
                    '₱${NumberFormat('#,##0.00').format(monthRev)}',
                    AppColors.lightAccent2,
                  ),
                  _WhiteStatCard(
                    "Completed Orders",
                    '$completedOrders',
                    Colors.white,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, c) {
              if (c.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TodayChannels(cash: todayCash, gcash: todayGcash),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: _ByServiceCard(data: byService)),
                  ],
                );
              }
              return Column(
                children: [
                  _TodayChannels(cash: todayCash, gcash: todayGcash),
                  const SizedBox(height: 14),
                  _ByServiceCard(data: byService),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _ReportsTransTable(txns: txns),
        ],
      ),
    );
  }
}

class _SReportCards extends StatelessWidget {
  final int cols;
  final List<Widget> children;
  const _SReportCards({required this.cols, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += cols) {
      final row = children.skip(i).take(cols).toList();
      rows.add(
        Row(
          children: row
              .asMap()
              .entries
              .map(
                (e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: e.key < row.length - 1 ? 8 : 0,
                    ),
                    child: e.value,
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (i + cols < children.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

class _WhiteStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _WhiteStatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        border: Border.all(color: AppColors.lightBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.lightMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayChannels extends StatelessWidget {
  final double cash, gcash;
  const _TodayChannels({required this.cash, required this.gcash});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: "Today's Revenue by Channel",
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('💵 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Cash',
                    style: TextStyle(
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '₱${NumberFormat('#,##0.00').format(cash)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📱 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'GCash',
                    style: TextStyle(
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '₱${NumberFormat('#,##0.00').format(gcash)}',
                style: const TextStyle(
                  color: AppColors.lightAccent2,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ByServiceCard extends StatelessWidget {
  final Map<String, double> data;
  const _ByServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'All-Time Revenue by Service',
      child: data.isEmpty
          ? const Text(
              'No completed orders yet.',
              style: TextStyle(color: AppColors.lightMuted),
            )
          : Column(
              children: data.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                color: AppColors.lightText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '₱${NumberFormat('#,##0.00').format(e.value)}',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ReportsTransTable extends StatelessWidget {
  final List<Transaction> txns;
  const _ReportsTransTable({required this.txns});

  @override
  Widget build(BuildContext context) {
    final sorted = [...txns]..sort((a, b) => b.date.compareTo(a.date));
    return AppCard(
      title: 'Transaction History',
      child: sorted.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: AppColors.lightMuted),
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 14,
                headingRowHeight: 32,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 44,
                headingTextStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightMuted,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.lightText,
                ),
                columns: const [
                  DataColumn(label: Text('TXN #')),
                  DataColumn(label: Text('ORDER')),
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('CHANNEL')),
                  DataColumn(label: Text('DATE')),
                ],
                rows: sorted
                    .map(
                      (t) => DataRow(
                        cells: [
                          DataCell(Text(t.num)),
                          DataCell(Text(t.orderNum)),
                          DataCell(Text(t.custName)),
                          DataCell(
                            Text(
                              '₱${t.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              t.channel == PaymentChannel.gcash
                                  ? 'GCash'
                                  : 'Cash',
                            ),
                          ),
                          DataCell(
                            Text(DateFormat('MMM d HH:mm').format(t.date)),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: MESSAGES
// ═══════════════════════════════════════════════════════════

class SellerMessagesPage extends StatefulWidget {
  final AppProvider provider;
  const SellerMessagesPage({super.key, required this.provider});
  @override
  State<SellerMessagesPage> createState() => _SellerMessagesPageState();
}

class _SellerMessagesPageState extends State<SellerMessagesPage> {
  AppUser? _selected;
  final _msgC = TextEditingController();
  final _messagesScroll = ScrollController();
  bool _sending = false;
  bool _callActive = false;
  bool _callVideo = false;

  List<AppUser> get _customers =>
      widget.provider.users.where((u) => u.role == UserRole.customer).toList();

  List<Message> _convo(AppUser u) {
    final myId = widget.provider.currentUser?.id ?? 0;
    return widget.provider.messages
        .where(
          (m) =>
              (m.fromId == myId && m.toId == u.id) ||
              (m.fromId == u.id && m.toId == myId),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _send() async {
    final sel = _selected;
    final text = _msgC.text.trim();
    if (sel == null || text.isEmpty || _sending) return;
    final myId = widget.provider.currentUser?.id ?? 0;
    setState(() => _sending = true);
    try {
      await widget.provider.sendMessage(fromId: myId, toId: sel.id, text: text);
      if (mounted) {
        _msgC.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messagesScroll.hasClients) {
            _messagesScroll.animateTo(
              _messagesScroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message could not be sent. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _msgC.dispose();
    _messagesScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    if (isWide) {
      return Row(
        children: [
          Container(
            width: 220,
            decoration: BoxDecoration(
              border: const Border(
                right: BorderSide(color: AppColors.lightBorder),
              ),
            ),
            child: _CustomerList(
              customers: _customers,
              selected: _selected,
              provider: widget.provider,
              onSelect: (u) => setState(() => _selected = u),
            ),
          ),
          Expanded(
            child: _ChatPane(
              selected: _selected,
              convo: _selected != null ? _convo(_selected!) : [],
              msgC: _msgC,
              onSend: _send,
              sending: _sending,
              scrollController: _messagesScroll,
              myId: widget.provider.currentUser?.id ?? 0,
              callActive: _callActive,
              callVideo: _callVideo,
              onCall: (video) => setState(() {
                _callActive = true;
                _callVideo = video;
              }),
              onEndCall: () => setState(() => _callActive = false),
            ),
          ),
        ],
      );
    }

    if (_selected == null) {
      return _CustomerList(
        customers: _customers,
        selected: null,
        provider: widget.provider,
        onSelect: (u) => setState(() => _selected = u),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selected = null),
              ),
              Text(
                _selected!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ChatPane(
            selected: _selected,
            convo: _convo(_selected!),
            msgC: _msgC,
            onSend: _send,
            sending: _sending,
            scrollController: _messagesScroll,
            myId: widget.provider.currentUser?.id ?? 0,
            callActive: _callActive,
            callVideo: _callVideo,
            onCall: (video) => setState(() {
              _callActive = true;
              _callVideo = video;
            }),
            onEndCall: () => setState(() => _callActive = false),
          ),
        ),
      ],
    );
  }
}

class _CustomerList extends StatelessWidget {
  final List<AppUser> customers;
  final AppUser? selected;
  final AppProvider provider;
  final ValueChanged<AppUser> onSelect;
  const _CustomerList({
    required this.customers,
    required this.selected,
    required this.provider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Messages',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (_, i) {
              final u = customers[i];
              final myId = provider.currentUser?.id ?? 0;
              final unread = provider.messages
                  .where((m) => m.fromId == u.id && m.toId == myId && !m.read)
                  .length;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightBtn.withOpacity(0.2),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.lightAccent2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  u.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(u.email, style: const TextStyle(fontSize: 11)),
                selected: selected?.id == u.id,
                trailing: unread > 0
                    ? Badge(
                        label: Text('$unread'),
                        child: const SizedBox.shrink(),
                      )
                    : null,
                onTap: () => onSelect(u),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatPane extends StatelessWidget {
  final AppUser? selected;
  final List<Message> convo;
  final TextEditingController msgC;
  final VoidCallback onSend;
  final bool sending;
  final ScrollController scrollController;
  final int myId;
  final bool callActive, callVideo;
  final ValueChanged<bool> onCall;
  final VoidCallback onEndCall;

  const _ChatPane({
    required this.selected,
    required this.convo,
    required this.msgC,
    required this.onSend,
    required this.sending,
    required this.myId,
    required this.scrollController,
    required this.callActive,
    required this.callVideo,
    required this.onCall,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return const Center(
        child: Text(
          'Select a customer to start messaging',
          style: TextStyle(color: AppColors.lightMuted),
        ),
      );
    }
    if (callActive) {
      return _CallOverlay(
        name: selected!.name,
        video: callVideo,
        onEnd: onEndCall,
      );
    }
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.lightBorder)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.lightBtn.withOpacity(0.2),
                radius: 16,
                child: Text(
                  selected!.name.isNotEmpty
                      ? selected!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.lightAccent2,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.phone,
                  size: 20,
                  color: AppColors.success,
                ),
                tooltip: 'Audio call',
                onPressed: () => onCall(false),
              ),
              IconButton(
                icon: const Icon(
                  Icons.videocam,
                  size: 20,
                  color: AppColors.lightAccent2,
                ),
                tooltip: 'Video call',
                onPressed: () => onCall(true),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: convo.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet. Say hi!',
                    style: TextStyle(color: AppColors.lightMuted),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: convo.length,
                  itemBuilder: (_, i) {
                    final m = convo[i];
                    final isMe = m.fromId == myId;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.bubbleMe
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.text,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : AppColors.lightText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm').format(m.date),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white.withOpacity(0.75)
                                    : AppColors.lightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgC,
                  enabled: !sending,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: sending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CallOverlay extends StatelessWidget {
  final String name;
  final bool video;
  final VoidCallback onEnd;
  const _CallOverlay({
    required this.name,
    required this.video,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              video ? Icons.videocam : Icons.phone,
              size: 64,
              color: AppColors.lightAccent2,
            ),
            const SizedBox(height: 20),
            Text(
              video ? 'Video Call' : 'Audio Call',
              style: const TextStyle(color: AppColors.lightMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calling...',
              style: TextStyle(color: AppColors.lightMuted),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.call_end, size: 18),
              label: const Text('End Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: RFID TAGS
// ═══════════════════════════════════════════════════════════

class SellerRfidPage extends StatefulWidget {
  final AppProvider provider;
  const SellerRfidPage({super.key, required this.provider});
  @override
  State<SellerRfidPage> createState() => _SellerRfidPageState();
}

class _SellerRfidPageState extends State<SellerRfidPage> {
  final _uidC = TextEditingController();

  @override
  void dispose() {
    _uidC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_uidC.text.trim().isEmpty) {
      await showErrorDialog(context, 'UID is required.');
      return;
    }
    if (widget.provider.rfidTags.any((t) => t.uid == _uidC.text.trim())) {
      await showErrorDialog(context, 'This UID is already registered.');
      return;
    }
    await widget.provider.registerTag(_uidC.text.trim());
    _uidC.clear();
    if (mounted)
      await showSuccessDialog(
        context,
        'Tag Registered!',
        'RFID tag added successfully.',
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = widget.provider.rfidTags;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Register form
          AppCard(
            title: 'Register New Tag',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _uidC,
                    decoration: InputDecoration(
                      hintText: 'Enter RFID UID (e.g. A3F1B2C4)',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Tags table
          AppCard(
            title: 'RFID Tags (${tags.length})',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 34,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 52,
                headingTextStyle: theme.textTheme.labelSmall,
                columns: const [
                  DataColumn(label: Text('TAG ID')),
                  DataColumn(label: Text('UID')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ORDER')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: tags
                    .map(
                      (t) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${t.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              t.uid,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: t.available
                                    ? AppColors.success.withOpacity(0.15)
                                    : AppColors.warn.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.available ? 'Available' : 'In Use',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: t.available
                                      ? AppColors.success
                                      : AppColors.warn,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              t.orderId != null
                                  ? 'ORD-${t.orderId.toString().padLeft(3, '0')}'
                                  : '—',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            !t.available
                                ? ElevatedButton(
                                    onPressed: () async {
                                      final ok = await showConfirmDialog(
                                        context,
                                        title: 'Release Tag',
                                        message: 'Release tag ${t.uid}?',
                                        confirmText: 'Release',
                                      );
                                      if (ok)
                                        await widget.provider.releaseTag(t.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warn,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),
                                    child: const Text('Release'),
                                  )
                                : const Text('—'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small initials avatar ─────────────────────────────────────
class _SInitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _SInitialsAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0] : '')
              .join()
              .toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.lightBtn.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.lightAccent2,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
