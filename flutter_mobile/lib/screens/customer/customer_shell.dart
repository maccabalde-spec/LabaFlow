import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/pricing_service.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  CUSTOMER SHELL
// ═══════════════════════════════════════════════════════════

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _tabIdx = 0;
  bool _notifOpen = false;
  bool _passwordPromptShown = false;

  static const _tabs = [
    (Icons.receipt_long_outlined, 'My Orders'),
    (Icons.local_laundry_service, 'Book Service'),
    (Icons.chat_bubble_outline, 'Messages'),
    (Icons.star_outline, 'LabaPoints'),
    (Icons.person_outline, 'Profile'),
  ];

  void _maybePromptPassword(AppProvider p) {
    if (_passwordPromptShown) return;
    if (p.needsPasswordSetup) {
      _passwordPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSetPasswordDialog());
    }
  }

  void _showSetPasswordDialog() {
    final passC = TextEditingController();
    final pass2C = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('🔑 Set a Password'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You signed in with Google. Set a password so you can also '
                  'sign in with your email and password next time.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Min 8 chars, letters + numbers',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pass2C,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () async {
                final pass = passC.text;
                final pass2 = pass2C.text;
                if (pass.isEmpty) {
                  setState(() => errorText = 'Enter a password.');
                  return;
                }
                if (pass.length < 8) {
                  setState(() => errorText = 'Password must be at least 8 characters.');
                  return;
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(pass) ||
                    !RegExp(r'\d').hasMatch(pass)) {
                  setState(() => errorText = 'Password must include letters and numbers.');
                  return;
                }
                if (pass != pass2) {
                  setState(() => errorText = 'Passwords do not match.');
                  return;
                }
                final provider = context.mounted
                    ? context.read<AppProvider>()
                    : ctx.read<AppProvider>();
                final err = await provider.setGoogleUserPassword(pass);
                if (err != null) {
                  setState(() => errorText = err);
                } else {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Set Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(AppProvider p) {
    _maybePromptPassword(p);
    switch (_tabIdx) {
      case 0:
        return CustOrdersPage(
          provider: p,
          onBook: () => setState(() => _tabIdx = 1),
        );
      case 1:
        return CustBookPage(provider: p);
      case 2:
        return CustMessagesPage(provider: p);
      case 3:
        return CustPointsPage(provider: p);
      case 4:
        return CustProfilePage(provider: p);
      default:
        return CustOrdersPage(
          provider: p,
          onBook: () => setState(() => _tabIdx = 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final isWide = MediaQuery.of(context).size.width >= 800;
    final tier = user != null ? getTier(user.points) : kTiers.first;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightText,
                ),
                children: [
                  const TextSpan(text: 'Laba'),
                  TextSpan(
                    text: 'Flow',
                    style: TextStyle(color: AppColors.lightAccent),
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 24),
              ..._tabs.asMap().entries.map(
                (e) => _TopTab(
                  icon: e.value.$1,
                  label: e.value.$2,
                  active: _tabIdx == e.key,
                  onTap: () => setState(() => _tabIdx = e.key),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(tier.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.loyalty_outlined,
                      size: 14,
                      color: Color(tier.color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.points} pts · ${tier.name}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(tier.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: Badge(
              isLabelVisible: provider.unreadCount() > 0,
              label: Text(
                '${provider.unreadCount()}',
                style: const TextStyle(fontSize: 9),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            onPressed: () => setState(() => _notifOpen = !_notifOpen),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18),
            onPressed: () async {
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
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: OceanicBubbleBackground()),
          _page(provider),
          if (_notifOpen)
            _CustNotifPanel(
              provider: provider,
              onClose: () => setState(() => _notifOpen = false),
            ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _tabIdx,
              onTap: (i) => setState(() => _tabIdx = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.lightAccent,
              unselectedItemColor: AppColors.lightDim,
              backgroundColor: Colors.white,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: _tabs
                  .map(
                    (t) => BottomNavigationBarItem(
                      icon: Icon(t.$1, size: 22),
                      label: t.$2,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TopTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.lightAccent : AppColors.lightMuted;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

// ── Notification Panel ─────────────────────────────────────────

class _CustNotifPanel extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback onClose;
  const _CustNotifPanel({required this.provider, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final notifs = provider.myNotifs();
    const panelBg = Colors.white;
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
                            style: TextStyle(fontWeight: FontWeight.w700),
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
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.msg,
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMM d HH:mm',
                                        ).format(n.date),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.lightDim,
                                        ),
                                      ),
                                    ],
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
//  PAGE: MY ORDERS
// ═══════════════════════════════════════════════════════════

class CustOrdersPage extends StatefulWidget {
  final AppProvider provider;
  final VoidCallback onBook;
  const CustOrdersPage({
    super.key,
    required this.provider,
    required this.onBook,
  });

  @override
  State<CustOrdersPage> createState() => _CustOrdersPageState();
}

class _CustOrdersPageState extends State<CustOrdersPage> {
  final _searchC = TextEditingController();
  String _query = '';
  String _filter = 'All';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.provider.currentUser?.id ?? 0;
    final allOrders = widget.provider.ordersForCustomer(uid);
    final pending = allOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final active = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.received ||
              o.status == OrderStatus.processing ||
              o.status == OrderStatus.washing ||
              o.status == OrderStatus.drying ||
              o.status == OrderStatus.folding,
        )
        .length;
    final ready = allOrders.where((o) => o.status == OrderStatus.ready).length;
    final completed = allOrders
        .where((o) => o.status == OrderStatus.released)
        .length;
    final orders = allOrders.where((o) {
      final matchesQuery = '${o.num} ${o.type.label} ${o.status.key}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      final matchesFilter =
          _filter == 'All' ||
          (_filter == 'Active' &&
              (o.status == OrderStatus.pending ||
                  o.status == OrderStatus.received ||
                  o.status == OrderStatus.processing ||
                  o.status == OrderStatus.washing ||
                  o.status == OrderStatus.drying ||
                  o.status == OrderStatus.folding)) ||
          (_filter == 'Ready' && o.status == OrderStatus.ready) ||
          (_filter == 'Completed' && o.status == OrderStatus.released);
      return matchesQuery && matchesFilter;
    }).toList()..sort((a, b) => b.created.compareTo(a.created));

    if (allOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_laundry_service_outlined,
              size: 56,
              color: AppColors.lightAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book your first laundry service!',
              style: TextStyle(color: AppColors.lightMuted),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.onBook,
              icon: const Icon(Icons.add),
              label: const Text('Book a service'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(
          'Hello, ${widget.provider.currentUser?.name ?? 'there'}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.lightText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your laundry, tracked from drop-off to pickup.',
          style: TextStyle(color: AppColors.lightMuted),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: widget.onBook,
            icon: const Icon(Icons.add),
            label: const Text('Book a service'),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CustomerOrderMetric(
              'All orders',
              '${allOrders.length}',
              Icons.receipt_long_outlined,
              AppColors.lightAccent,
            ),
            _CustomerOrderMetric(
              'Pending',
              '$pending',
              Icons.schedule_outlined,
              AppColors.statusPending,
            ),
            _CustomerOrderMetric(
              'In progress',
              '$active',
              Icons.local_laundry_service_outlined,
              AppColors.statusReceived,
            ),
            _CustomerOrderMetric(
              'Ready',
              '$ready',
              Icons.check_circle_outline,
              AppColors.statusReady,
            ),
            _CustomerOrderMetric(
              'Completed',
              '$completed',
              Icons.task_alt,
              AppColors.statusReleased,
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchC,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search order or service',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Active', 'Ready', 'Completed']
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('No orders match your search.')),
          ),
        ...orders.map(
          (order) => _OrderCard(order: order, provider: widget.provider),
        ),
      ],
    );
  }
}

class _CustomerOrderMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _CustomerOrderMetric(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 118),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.lightBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
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

class _OrderCard extends StatelessWidget {
  final Order order;
  final AppProvider provider;
  const _OrderCard({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    const border = AppColors.lightBorder;
    const surface = Colors.white;
    final tag = order.tagId != null
        ? provider.rfidTags.where((t) => t.id == order.tagId).firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                order.num,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(order.status),
              if (tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightAccent2.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.nfc_outlined,
                        size: 12,
                        color: AppColors.lightAccent2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag.uid,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightAccent2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // QR button
              IconButton(
                icon: const Icon(
                  Icons.qr_code,
                  size: 20,
                  color: AppColors.lightMuted,
                ),
                tooltip: 'Show QR',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order.num,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data:
                                '${order.num}|${order.custId}|${order.status.key}',
                            size: 200,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan at the shop',
                            style: TextStyle(
                              color: AppColors.lightMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Timeline
          OrderTimeline(currentStatus: order.status),
          const SizedBox(height: 12),
          // Info
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _InfoChip(Icons.local_laundry_service, order.type.label),
              if (order.kg != null) _InfoChip(Icons.scale, '${order.kg} kg'),
              if (order.comQty != null)
                _InfoChip(Icons.king_bed, '${order.comQty} pc(s)'),
              _InfoChip(
                Icons.attach_money,
                '₱${order.price.toStringAsFixed(2)}',
              ),
              if (order.discount > 0)
                _InfoChip(
                  Icons.discount,
                  '-₱${order.discount.toStringAsFixed(2)}',
                ),
              if (order.promoCode.isNotEmpty)
                _InfoChip(Icons.local_offer, order.promoCode),
            ],
          ),
          if (order.dropOff != null || order.ready != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                if (order.dropOff != null)
                  _InfoChip(
                    Icons.login,
                    'Drop: ${DateFormat('MMM d HH:mm').format(order.dropOff!)}',
                  ),
                if (order.ready != null)
                  _InfoChip(
                    Icons.check_circle,
                    'Ready: ${DateFormat('MMM d HH:mm').format(order.ready!)}',
                  ),
                if (order.pickup != null)
                  _InfoChip(
                    Icons.logout,
                    'Pickup: ${DateFormat('MMM d HH:mm').format(order.pickup!)}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.lightMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.lightMuted),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: BOOK SERVICE
// ═══════════════════════════════════════════════════════════

class CustBookPage extends StatefulWidget {
  final AppProvider provider;
  const CustBookPage({super.key, required this.provider});
  @override
  State<CustBookPage> createState() => _CustBookPageState();
}

class _CustBookPageState extends State<CustBookPage> {
  OrderType _type = OrderType.clothes;
  ColorDist _colorDist = ColorDist.mixed;
  double? _kg;
  int? _comQty;
  String _promoCode = '';
  String _promoMsg = '';
  double _discount = 0;
  String _notes = '';
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
    final user = widget.provider.currentUser;
    if (user != null) {
      final tier = getTier(user.points);
      // Loyalty discount
      if (tier.disc > 0 && _discount == 0) {
        final loyDisc = (_priceResult.price * tier.disc / 100);
        setState(() {
          _promoMsg =
              '${r.promoMsg}\n⭐ ${tier.name} loyalty: ${tier.disc}% off applied';
          _discount = r.discount + loyDisc;
          _promoCode = _promoC.text.trim().toUpperCase();
        });
        return;
      }
    }
    setState(() {
      _promoMsg = r.promoMsg;
      _discount = r.discount;
      _promoCode = _promoC.text.trim().toUpperCase();
    });
  }

  Future<void> _submit() async {
    final user = widget.provider.currentUser;
    if (user == null) return;
    final pr = _priceResult;
    if (pr.price <= 0) {
      await showErrorDialog(context, 'Enter valid weight or quantity.');
      return;
    }
    setState(() => _loading = true);
    await widget.provider.createOrder(
      custId: user.id,
      custName: user.name,
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
    if (!mounted) return;
    setState(() {
      _loading = false;
      _kgC.clear();
      _comC.clear();
      _promoC.clear();
      _notesC.clear();
      _kg = null;
      _comQty = null;
      _discount = 0;
      _promoCode = '';
      _promoMsg = '';
    });
    await showSuccessDialog(
      context,
      'Booking Submitted!',
      'Your order has been placed. Please drop off your laundry at the shop.',
    );
  }

  @override
  void dispose() {
    for (final c in [_kgC, _comC, _promoC, _notesC]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pr = _priceResult;
    final user = widget.provider.currentUser;
    final tier = user != null ? getTier(user.points) : kTiers.first;
    final loyaltyDisc = (pr.price * tier.disc / 100);
    final totalDisc = _discount > 0 ? _discount : loyaltyDisc;
    final finalPrice = pr.price - totalDisc;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book a Service',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in the details below and drop off your laundry.',
                style: TextStyle(fontSize: 13, color: AppColors.lightMuted),
              ),
              const SizedBox(height: 20),
              // Service type
              const Text(
                'SERVICE TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
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
                        labelStyle: TextStyle(
                          color: _type == t ? Colors.white : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Weight / qty
              if (_type == OrderType.clothes ||
                  _type == OrderType.bedsheet ||
                  _type == OrderType.washOnly ||
                  _type == OrderType.dryOnly)
                _BookField(
                  controller: _kgC,
                  label: 'WEIGHT (KG)',
                  hint: 'e.g. 7',
                  type: TextInputType.number,
                  onChanged: (v) => setState(() => _kg = double.tryParse(v)),
                )
              else if (_type == OrderType.comforter)
                _BookField(
                  controller: _comC,
                  label: 'QUANTITY (PCS)',
                  hint: 'e.g. 1',
                  type: TextInputType.number,
                  onChanged: (v) => setState(() => _comQty = int.tryParse(v)),
                ),
              if (_type == OrderType.clothes) ...[
                const SizedBox(height: 16),
                const Text(
                  'COLOR SEPARATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                          labelStyle: TextStyle(
                            color: _colorDist == c ? Colors.white : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              // Promo
              Row(
                children: [
                  Expanded(
                    child: _BookField(
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
              const SizedBox(height: 16),
              _BookField(
                controller: _notesC,
                label: 'SPECIAL INSTRUCTIONS',
                hint: 'Any notes for the staff...',
                onChanged: (v) => setState(() => _notes = v),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // Price display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBtn.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.lightBtn.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    if (pr.breakdown.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          pr.breakdown,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightMuted,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Price:'),
                        Text(
                          '₱${pr.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (tier.disc > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${tier.name} Loyalty (${tier.disc}%):'),
                          Text(
                            '-₱${loyaltyDisc.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.success),
                          ),
                        ],
                      ),
                    if (_discount > loyaltyDisc)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Promo:'),
                          Text(
                            '-₱${(_discount - loyaltyDisc).toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.success),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '₱${finalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
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
                label: 'Submit Booking',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType type;
  final ValueChanged<String> onChanged;
  final int maxLines;
  const _BookField({
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
            letterSpacing: 0.5,
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: MESSAGES
// ═══════════════════════════════════════════════════════════

class CustMessagesPage extends StatefulWidget {
  final AppProvider provider;
  const CustMessagesPage({super.key, required this.provider});
  @override
  State<CustMessagesPage> createState() => _CustMessagesPageState();
}

class _CustMessagesPageState extends State<CustMessagesPage> {
  final _msgC = TextEditingController();
  final _messagesScroll = ScrollController();
  bool _sending = false;
  bool _callActive = false;
  bool _callVideo = false;

  @override
  void dispose() {
    _msgC.dispose();
    _messagesScroll.dispose();
    super.dispose();
  }

  // Staff: find sellers/admins
  List<AppUser> get _staff => widget.provider.users
      .where((u) => u.role == UserRole.seller || u.role == UserRole.admin)
      .toList();

  // Conversation with first available staff
  List<Message> get _convo {
    final myId = widget.provider.currentUser?.id ?? 0;
    final staffIds = _staff.map((s) => s.id).toSet();
    return widget.provider.messages
        .where(
          (m) =>
              (m.fromId == myId && staffIds.contains(m.toId)) ||
              (m.toId == myId && staffIds.contains(m.fromId)),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty || _sending) return;
    final myId = widget.provider.currentUser?.id ?? 0;
    final seller = _staff.firstOrNull;
    if (seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The shop support team is unavailable. Please try again later.',
          ),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.provider.sendMessage(
        fromId: myId,
        toId: seller.id,
        text: text,
      );
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
  Widget build(BuildContext context) {
    final myId = widget.provider.currentUser?.id ?? 0;
    final convo = _convo;

    if (_callActive) {
      return _CustCallOverlay(
        video: _callVideo,
        onEnd: () => setState(() => _callActive = false),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.lightBorder)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.lightBtn,
                radius: 16,
                child: Icon(
                  Icons.water_drop_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lab-a-Day Support',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Laundry shop staff',
                      style: TextStyle(
                        color: AppColors.lightMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.phone,
                  size: 20,
                  color: AppColors.success,
                ),
                onPressed: () => setState(() {
                  _callActive = true;
                  _callVideo = false;
                }),
                tooltip: 'Audio call',
              ),
              IconButton(
                icon: const Icon(
                  Icons.videocam,
                  size: 20,
                  color: AppColors.lightAccent2,
                ),
                onPressed: () => setState(() {
                  _callActive = true;
                  _callVideo = true;
                }),
                tooltip: 'Video call',
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: convo.isEmpty
              ? const Center(
                  child: Text(
                    'Send a message to the shop!',
                    style: TextStyle(color: AppColors.lightMuted),
                  ),
                )
              : ListView.builder(
                  controller: _messagesScroll,
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
                  controller: _msgC,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    hintText: 'Message the shop...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: _sending
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

class _CustCallOverlay extends StatelessWidget {
  final bool video;
  final VoidCallback onEnd;
  const _CustCallOverlay({required this.video, required this.onEnd});

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
            const Text(
              'Lab-a-Day Support',
              style: TextStyle(
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
//  PAGE: LABAPOINTS
// ═══════════════════════════════════════════════════════════

class CustPointsPage extends StatelessWidget {
  final AppProvider provider;
  const CustPointsPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final user = provider.currentUser;
    if (user == null) return const SizedBox.shrink();

    final pts = user.points;
    final tier = getTier(pts);
    final next = getNextTier(pts);
    final pct = next != null
        ? ((pts - tier.minPts) / (next.minPts - tier.minPts)).clamp(0.0, 1.0)
        : 1.0;

    final completedOrders = provider.orders
        .where((o) => o.custId == user.id && o.status == OrderStatus.released)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Loyalty card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: AppElevation.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LabaPoints Card',
                                style: TextStyle(
                                  color: AppColors.lightMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: AppColors.lightText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                tier.name.toUpperCase(),
                                style: TextStyle(
                                  color: Color(tier.color),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Text(
                                'TIER',
                                style: TextStyle(
                                  color: AppColors.lightMuted,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$pts',
                      style: const TextStyle(
                        color: AppColors.lightAccent2,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'LabaPoints',
                      style: TextStyle(
                        color: AppColors.lightMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (next != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tier.name,
                            style: const TextStyle(
                              color: AppColors.lightMuted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${next.name} in ${next.minPts - pts} pts',
                            style: const TextStyle(
                              color: AppColors.lightMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.lightBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.lightAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tier benefits
              AppCard(
                title: 'Tier Benefits',
                child: Column(
                  children: kTiers.map((t) {
                    final isCurrent = t.name == tier.name;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Color(t.color).withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isCurrent
                              ? Color(t.color)
                              : AppColors.lightBorder,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Color(t.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              t.name,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                                color: isCurrent ? Color(t.color) : null,
                              ),
                            ),
                          ),
                          Text(
                            '${t.minPts}+ pts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.lightMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.disc > 0 ? '${t.disc}% off' : 'No discount',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: t.disc > 0
                                  ? AppColors.success
                                  : AppColors.lightDim,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(t.color),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOUR TIER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              // Completed orders
              AppCard(
                title: 'Completed Orders',
                child: completedOrders.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No completed orders yet.'),
                        ),
                      )
                    : Column(
                        children: completedOrders
                            .map(
                              (o) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        o.num,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      o.type.label,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.lightMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '+${(o.price / 10).round()} pts',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('MMM d').format(o.created),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.lightDim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: PROFILE
// ═══════════════════════════════════════════════════════════

class CustProfilePage extends StatefulWidget {
  final AppProvider provider;
  const CustProfilePage({super.key, required this.provider});
  @override
  State<CustProfilePage> createState() => _CustProfilePageState();
}

class _CustProfilePageState extends State<CustProfilePage> {
  late final _nameC = TextEditingController(
    text: widget.provider.currentUser?.name ?? '',
  );
  late final _emailC = TextEditingController(
    text: widget.provider.currentUser?.email ?? '',
  );
  late final _phoneC = TextEditingController(
    text: widget.provider.currentUser?.phone ?? '',
  );
  final _passC = TextEditingController();
  final _pass2C = TextEditingController();
  bool _loading = false;
  String? _error;

  ImageProvider? _profileImage(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }
    final data = value.contains(',')
        ? value.substring(value.indexOf(',') + 1)
        : value;
    try {
      return MemoryImage(base64Decode(data));
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final c in [_nameC, _emailC, _phoneC, _passC, _pass2C]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passC.text.isNotEmpty && _passC.text != _pass2C.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.provider.saveProfile(
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      pass: _passC.text.isNotEmpty ? _passC.text : null,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) {
      final pendingEmail =
          _emailC.text.trim().toLowerCase() !=
          widget.provider.currentUser?.email;
      await showSuccessDialog(
        context,
        'Profile Updated!',
        pendingEmail
            ? 'Your profile has been saved. Verify the link sent to your new email address before signing in with it.'
            : 'Your profile has been saved.',
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final base64 = base64Encode(bytes);
      await widget.provider.saveProfile(
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
        phone: _phoneC.text.trim(),
        pic: 'data:image/jpeg;base64,$base64',
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) await showErrorDialog(context, 'Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.provider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Profile picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.lightBtn.withOpacity(0.2),
                      backgroundImage: _profileImage(user.pic),
                      child: _profileImage(user.pic) == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.lightAccent2,
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.lightBtn,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap to change photo',
                style: TextStyle(fontSize: 11, color: AppColors.lightMuted),
              ),
              if (user.googleConnected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Google account connected',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _ProfileField(
                controller: _nameC,
                label: 'FULL NAME',
                hint: 'Your name',
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: _emailC,
                label: 'EMAIL',
                hint: 'email@example.com',
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: _phoneC,
                label: 'PHONE',
                hint: '09XX XXX XXXX',
                type: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _passC,
                label: 'NEW PASSWORD',
                hint: 'Leave blank to keep current',
                obscure: true,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _pass2C,
                label: 'CONFIRM PASSWORD',
                hint: 'Repeat new password',
                obscure: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                NoticeBanner(text: _error!, type: NoticeType.error),
              ],
              const SizedBox(height: 20),
              PrimaryBtn(
                label: 'Save Changes',
                loading: _loading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  final TextInputType type;
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.type = TextInputType.text,
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
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        obscure
            ? PasswordInputField(
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            : TextField(
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ],
    );
  }
}
