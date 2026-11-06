import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  ADMIN SHELL
// ═══════════════════════════════════════════════════════════

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIdx = 0;
  bool _notifOpen = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.bar_chart_outlined, 'Financial Analytics'),
    (Icons.inventory_2_outlined, 'Inventory Monitor'),
    (Icons.local_offer_outlined, 'Promo Codes'),
    (Icons.group_outlined, 'User Accounts'),
  ];

  Widget _page(AppProvider p) {
    switch (_navIdx) {
      case 0:
        return AdminDashboardPage(
          provider: p,
          onNavigate: (i) {
            if (mounted) setState(() => _navIdx = i);
          },
        );
      case 1:
        return AdminFinancialPage(provider: p);
      case 2:
        return AdminInventoryPage(provider: p);
      case 3:
        return AdminPromoPage(provider: p);
      case 4:
        return AdminUsersPage(provider: p);
      default:
        return AdminDashboardPage(
          provider: p,
          onNavigate: (i) {
            if (mounted) setState(() => _navIdx = i);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isWide = MediaQuery.of(context).size.width >= 900;
    final user = provider.currentUser;

    final sidebar = _AdminSidebar(
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
          message: 'Are you sure you want to sign out?',
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
                  _TopBar(
                    title: _navItems[_navIdx].$2,
                    provider: provider,
                    onNotif: () => setState(() => _notifOpen = !_notifOpen),
                    isWide: true,
                    onMenu: null,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(child: OceanicBubbleBackground()),
                        _page(provider),
                        if (_notifOpen)
                          _NotifPanel(
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
            _NotifPanel(
              provider: provider,
              onClose: () => setState(() => _notifOpen = false),
            ),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  final int navIdx;
  final List<(IconData, String)> navItems;
  final AppUser? user;
  final ValueChanged<int> onNav;
  final VoidCallback onSignOut;

  const _AdminSidebar({
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
          // Logo
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
          // User info
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _InitialsAvatar(name: user!.name, size: 36),
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
                          'Administrator',
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
          // Nav items
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
                        ? Border(
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
          // Footer
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

// ── Top Bar ──────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final AppProvider provider;
  final bool isWide;
  final VoidCallback onNotif;
  final VoidCallback? onMenu;

  const _TopBar({
    required this.title,
    required this.provider,
    required this.isWide,
    required this.onNotif,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowStock = provider.lowStockItems.length;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        border: const Border(bottom: BorderSide(color: AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          if (!isWide && onMenu != null) ...[
            IconButton(
              icon: const Icon(Icons.menu, size: 20),
              onPressed: onMenu,
            ),
            const SizedBox(width: 4),
          ],
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
          if (lowStock > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: AppColors.danger, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '$lowStock low stock',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
            onPressed: onNotif,
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

// ── Notification Panel ────────────────────────────────────────

class _NotifPanel extends StatelessWidget {
  final AppProvider provider;
  final VoidCallback onClose;
  const _NotifPanel({required this.provider, required this.onClose});

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
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 320,
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
                            ? const Center(
                                child: Text(
                                  'No notifications',
                                  style: TextStyle(color: AppColors.lightMuted),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: notifs.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: border),
                                itemBuilder: (_, i) {
                                  final n = notifs[i];
                                  return ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: n.read
                                            ? Colors.transparent
                                            : AppColors.lightBtn.withOpacity(
                                                0.15,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          n.icon,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: DASHBOARD
// ═══════════════════════════════════════════════════════════

class AdminDashboardPage extends StatelessWidget {
  final AppProvider provider;
  final ValueChanged<int> onNavigate;
  const AdminDashboardPage({
    super.key,
    required this.provider,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final orders = provider.orders;
    final revenue = provider.transactions.fold<double>(
      0,
      (s, t) => s + t.amount,
    );

    // Status counts
    int pending = 0, received = 0, processing = 0, ready = 0, released = 0;
    for (final o in orders) {
      switch (o.status) {
        case OrderStatus.pending:
          pending++;
          break;
        case OrderStatus.received:
          received++;
          break;
        case OrderStatus.processing:
          processing++;
          break;
        case OrderStatus.ready:
          ready++;
          break;
        case OrderStatus.released:
          released++;
          break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Track today’s laundry activity and take action quickly.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => onNavigate(2),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Inventory monitor'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(4),
                icon: const Icon(Icons.group_outlined),
                label: const Text('User accounts'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigate(1),
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Financial analytics'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Status stat cards
          LayoutBuilder(
            builder: (ctx, c) {
              final cols = c.maxWidth > 900
                  ? 5
                  : c.maxWidth > 600
                  ? 3
                  : 2;
              return _GridCards(
                cols: cols,
                children: [
                  StatCard(
                    value: '$pending',
                    label: 'PENDING',
                    valueColor: AppColors.statusPending,
                  ),
                  StatCard(
                    value: '$received',
                    label: 'RECEIVED',
                    valueColor: AppColors.statusReceived,
                  ),
                  StatCard(
                    value: '$processing',
                    label: 'PROCESSING',
                    valueColor: AppColors.statusProcessing,
                  ),
                  StatCard(
                    value: '$ready',
                    label: 'READY',
                    valueColor: AppColors.statusReady,
                  ),
                  StatCard(
                    value: '$released',
                    label: 'RELEASED',
                    valueColor: AppColors.statusReleased,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          // Revenue card
          AppCard(
            title: 'Total Revenue',
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '₱${NumberFormat('#,##0.00').format(revenue)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'from ${provider.transactions.length} transactions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Row: Chart + Inventory
          LayoutBuilder(
            builder: (ctx, c) {
              if (c.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _OrdersTrendChart(provider: provider),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _InventorySnapshot(provider: provider),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _OrdersTrendChart(provider: provider),
                  _InventorySnapshot(provider: provider),
                ],
              );
            },
          ),
          // Busiest days
          _BusiestDays(provider: provider),
          const SizedBox(height: 14),
          // Recent orders
          _RecentOrdersTable(provider: provider),
        ],
      ),
    );
  }
}

class _GridCards extends StatelessWidget {
  final int cols;
  final List<Widget> children;
  const _GridCards({required this.cols, required this.children});

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

class _OrdersTrendChart extends StatelessWidget {
  final AppProvider provider;
  const _OrdersTrendChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Group orders by day of week (0=Mon..6=Sun)
    final counts = List<double>.filled(7, 0);
    for (final o in provider.orders) {
      final dow = o.created.weekday - 1; // Mon=0..Sun=6
      counts[dow]++;
    }
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AppCard(
      title: 'Orders Trend (by Day of Week)',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (counts.reduce((a, b) => a > b ? a : b) + 2).clamp(
              5,
              double.infinity,
            ),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(
                    days[v.toInt()],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.lightMuted,
                    ),
                  ),
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: AppColors.lightBorder, strokeWidth: 0.5),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              7,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: counts[i],
                    color: AppColors.lightBtn,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventorySnapshot extends StatelessWidget {
  final AppProvider provider;
  const _InventorySnapshot({required this.provider});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Inventory Snapshot',
      child: Column(
        children: provider.inventory
            .take(5)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          item.isLiquid
                              ? '${item.qtyMl} mL'
                              : '${item.qty} ${item.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            color: item.isLow
                                ? AppColors.danger
                                : AppColors.lightMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LevelBar(pct: item.pct),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BusiestDays extends StatelessWidget {
  final AppProvider provider;
  const _BusiestDays({required this.provider});

  @override
  Widget build(BuildContext context) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final counts = List<int>.filled(7, 0);
    for (final o in provider.orders) counts[o.created.weekday - 1]++;
    final sorted = List.generate(7, (i) => (days[i], counts[i]))
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return AppCard(
      title: 'Busiest Days',
      child: Column(
        children: sorted
            .take(5)
            .map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(d.$1, style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: sorted.first.$2 > 0 ? d.$2 / sorted.first.$2 : 0,
                        backgroundColor: AppColors.lightBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.lightBtn,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${d.$2}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

class _RecentOrdersTable extends StatelessWidget {
  final AppProvider provider;
  const _RecentOrdersTable({required this.provider});

  @override
  Widget build(BuildContext context) {
    final recent = [...provider.orders]
      ..sort((a, b) => b.created.compareTo(a.created));
    final show = recent.take(10).toList();
    final theme = Theme.of(context);

    return AppCard(
      title: 'Recent Orders',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowHeight: 34,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          headingTextStyle: theme.textTheme.labelSmall,
          columns: const [
            DataColumn(label: Text('ORDER')),
            DataColumn(label: Text('CUSTOMER')),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('PRICE')),
            DataColumn(label: Text('DATE')),
          ],
          rows: show
              .map(
                (o) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        o.num,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(o.custName, style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(
                      Text(o.type.label, style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(StatusBadge(o.status)),
                    DataCell(
                      Text(
                        '₱${o.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat('MMM d').format(o.created),
                        style: const TextStyle(fontSize: 11),
                      ),
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
//  PAGE: FINANCIAL ANALYTICS
// ═══════════════════════════════════════════════════════════

class AdminFinancialPage extends StatelessWidget {
  final AppProvider provider;
  const AdminFinancialPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final txns = provider.transactions;
    final total = txns.fold<double>(0, (s, t) => s + t.amount);
    final cash = txns
        .where((t) => t.channel == PaymentChannel.cash)
        .fold<double>(0, (s, t) => s + t.amount);
    final gcash = txns
        .where((t) => t.channel == PaymentChannel.gcash)
        .fold<double>(0, (s, t) => s + t.amount);
    final today = txns
        .where((t) {
          final n = DateTime.now();
          return t.date.year == n.year &&
              t.date.month == n.month &&
              t.date.day == n.day;
        })
        .fold<double>(0, (s, t) => s + t.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (_, c) {
              final cols = c.maxWidth > 700 ? 4 : 2;
              return _GridCards(
                cols: cols,
                children: [
                  StatCard(
                    value: '₱${NumberFormat('#,##0').format(total)}',
                    label: "Total Revenue",
                    valueColor: AppColors.success,
                  ),
                  StatCard(value: '${txns.length}', label: 'Transactions'),
                  StatCard(
                    value: '₱${NumberFormat('#,##0').format(today)}',
                    label: "Today's Revenue",
                    valueColor: AppColors.warn,
                  ),
                  StatCard(
                    value: txns.isNotEmpty
                        ? '₱${NumberFormat('#,##0').format(total / txns.length)}'
                        : '₱0',
                    label: 'Avg Transaction',
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
                  children: [
                    Expanded(
                      child: _ChannelCard(
                        '💵 Cash',
                        '₱${NumberFormat('#,##0.00').format(cash)}',
                        txns
                            .where((t) => t.channel == PaymentChannel.cash)
                            .length,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ChannelCard(
                        '📱 GCash',
                        '₱${NumberFormat('#,##0.00').format(gcash)}',
                        txns
                            .where((t) => t.channel == PaymentChannel.gcash)
                            .length,
                        AppColors.lightAccent2,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _ChannelCard(
                    '💵 Cash',
                    '₱${NumberFormat('#,##0.00').format(cash)}',
                    txns.where((t) => t.channel == PaymentChannel.cash).length,
                    AppColors.success,
                  ),
                  const SizedBox(height: 14),
                  _ChannelCard(
                    '📱 GCash',
                    '₱${NumberFormat('#,##0.00').format(gcash)}',
                    txns.where((t) => t.channel == PaymentChannel.gcash).length,
                    AppColors.lightAccent2,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _TransactionsTable(txns: txns),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final String label, amount;
  final int count;
  final Color color;
  const _ChannelCard(this.label, this.amount, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            '$count transactions',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TransactionsTable extends StatelessWidget {
  final List<Transaction> txns;
  const _TransactionsTable({required this.txns});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...txns]..sort((a, b) => b.date.compareTo(a.date));
    return AppCard(
      title: 'Transactions',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 34,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          headingTextStyle: theme.textTheme.labelSmall,
          columns: const [
            DataColumn(label: Text('TXN #')),
            DataColumn(label: Text('ORDER')),
            DataColumn(label: Text('CUSTOMER')),
            DataColumn(label: Text('AMOUNT')),
            DataColumn(label: Text('CHANNEL')),
            DataColumn(label: Text('GCASH REF')),
            DataColumn(label: Text('PROMO')),
            DataColumn(label: Text('DATE')),
          ],
          rows: sorted
              .map(
                (t) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        t.num,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(t.orderNum, style: const TextStyle(fontSize: 11)),
                    ),
                    DataCell(
                      Text(t.custName, style: const TextStyle(fontSize: 11)),
                    ),
                    DataCell(
                      Text(
                        '₱${t.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
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
                          color: t.channel == PaymentChannel.gcash
                              ? AppColors.lightAccent2.withOpacity(0.15)
                              : AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.channel == PaymentChannel.gcash ? 'GCash' : 'Cash',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: t.channel == PaymentChannel.gcash
                                ? AppColors.lightAccent2
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        t.gcashRef.isNotEmpty ? t.gcashRef : '—',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      t.promoCode.isNotEmpty
                          ? PromoTag(t.promoCode)
                          : const Text('—', style: TextStyle(fontSize: 11)),
                    ),
                    DataCell(
                      Text(
                        DateFormat('MMM d, HH:mm').format(t.date),
                        style: const TextStyle(fontSize: 11),
                      ),
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
//  PAGE: INVENTORY MONITOR
// ═══════════════════════════════════════════════════════════

class AdminInventoryPage extends StatefulWidget {
  final AppProvider provider;
  const AdminInventoryPage({super.key, required this.provider});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
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

  @override
  Widget build(BuildContext context) {
    final inventory = widget.provider.inventory;
    final low = inventory.where((item) => item.isLow).length;
    final out = inventory.where((item) => item.qty <= 0).length;
    final categories = inventory.map((item) => item.cat).toSet().length;
    final filtered = inventory
        .where(
          (item) => '${item.name} ${item.cat.key}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AdminInventorySummary(
                label: 'Inventory items',
                value: '${inventory.length}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.lightAccent,
              ),
              _AdminInventorySummary(
                label: 'Low stock',
                value: '$low',
                icon: Icons.warning_amber_rounded,
                color: low > 0 ? AppColors.warn : AppColors.success,
              ),
              _AdminInventorySummary(
                label: 'Out of stock',
                value: '$out',
                icon: Icons.remove_shopping_cart_outlined,
                color: out > 0 ? AppColors.danger : AppColors.success,
              ),
              _AdminInventorySummary(
                label: 'Categories',
                value: '$categories',
                icon: Icons.category_outlined,
                color: AppColors.lightAccent2,
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _refreshing ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Refresh inventory'),
            ),
          ),
          if (filtered.isEmpty)
            AppCard(
              title: 'Inventory Levels',
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  inventory.isEmpty
                      ? 'No inventory items are available.'
                      : 'No inventory items match your search.',
                  style: const TextStyle(color: AppColors.lightMuted),
                ),
              ),
            )
          else
            _InventoryTable(provider: widget.provider, items: filtered),
          const SizedBox(height: 14),
          _RestockLogTable(provider: widget.provider),
        ],
      ),
    );
  }
}

class _InventoryTable extends StatelessWidget {
  final AppProvider provider;
  final List<InventoryItem> items;
  const _InventoryTable({required this.provider, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      title: 'Inventory Levels',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 34,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 52,
          headingTextStyle: theme.textTheme.labelSmall,
          columns: const [
            DataColumn(label: Text('ITEM')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('QUANTITY')),
            DataColumn(label: Text('THRESHOLD')),
            DataColumn(label: Text('LEVEL')),
            DataColumn(label: Text('STATUS')),
          ],
          rows: items
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
                      Text(item.cat.key, style: const TextStyle(fontSize: 11)),
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
                      SizedBox(width: 120, child: LevelBar(pct: item.pct)),
                    ),
                    DataCell(
                      item.isLow
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LOW',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const Text(
                              'OK',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

class _AdminInventorySummary extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AdminInventorySummary({
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

class _RestockLogTable extends StatelessWidget {
  final AppProvider provider;
  const _RestockLogTable({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...provider.restockLog]
      ..sort((a, b) => b.date.compareTo(a.date));
    return AppCard(
      title: 'Restock Log',
      child: sorted.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No restocks yet'),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 34,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                headingTextStyle: theme.textTheme.labelSmall,
                columns: const [
                  DataColumn(label: Text('ITEM')),
                  DataColumn(label: Text('QTY')),
                  DataColumn(label: Text('BEFORE')),
                  DataColumn(label: Text('AFTER')),
                  DataColumn(label: Text('COST')),
                  DataColumn(label: Text('BY')),
                  DataColumn(label: Text('DATE')),
                ],
                rows: sorted
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              r.itemName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              '+${r.qty} ${r.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${r.before}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${r.after}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.totalCost != null
                                  ? '₱${r.totalCost!.toStringAsFixed(2)}'
                                  : '—',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            Text(r.by, style: const TextStyle(fontSize: 11)),
                          ),
                          DataCell(
                            Text(
                              DateFormat('MMM d, HH:mm').format(r.date),
                              style: const TextStyle(fontSize: 11),
                            ),
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
//  PAGE: PROMO CODES
// ═══════════════════════════════════════════════════════════

class AdminPromoPage extends StatefulWidget {
  final AppProvider provider;
  const AdminPromoPage({super.key, required this.provider});
  @override
  State<AdminPromoPage> createState() => _AdminPromoPageState();
}

class _AdminPromoPageState extends State<AdminPromoPage> {
  void _openForm([PromoCode? pc]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PromoBottomSheet(provider: widget.provider, existing: pc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promos = widget.provider.promoCodes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        title: 'Promo Codes',
        trailing: ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 15),
          label: const Text('Add Promo'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowHeight: 34,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 52,
            headingTextStyle: theme.textTheme.labelSmall,
            columns: const [
              DataColumn(label: Text('CODE')),
              DataColumn(label: Text('DISCOUNT')),
              DataColumn(label: Text('USES')),
              DataColumn(label: Text('MAX')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('DESCRIPTION')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: promos
                .map(
                  (p) => DataRow(
                    cells: [
                      DataCell(PromoTag(p.code)),
                      DataCell(
                        Text(
                          '${p.disc}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text('${p.uses}', style: const TextStyle(fontSize: 12)),
                      ),
                      DataCell(
                        Text(
                          '${p.maxUses}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Switch(
                          value: p.active,
                          activeColor: AppColors.success,
                          onChanged: (v) {
                            final updated = PromoCode(
                              id: p.id,
                              code: p.code,
                              disc: p.disc,
                              maxUses: p.maxUses,
                              uses: p.uses,
                              desc: p.desc,
                              active: v,
                            );
                            widget.provider.savePromoCode(updated);
                          },
                        ),
                      ),
                      DataCell(
                        Text(p.desc, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.lightAccent2,
                              ),
                              onPressed: () => _openForm(p),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 16,
                                color: AppColors.danger,
                              ),
                              onPressed: () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Delete Promo',
                                  message: 'Delete code ${p.code}?',
                                  confirmText: 'Delete',
                                );
                                if (ok) widget.provider.deletePromoCode(p.id);
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
    );
  }
}

class _PromoBottomSheet extends StatefulWidget {
  final AppProvider provider;
  final PromoCode? existing;
  const _PromoBottomSheet({required this.provider, this.existing});
  @override
  State<_PromoBottomSheet> createState() => _PromoBottomSheetState();
}

class _PromoBottomSheetState extends State<_PromoBottomSheet> {
  late final _codeC = TextEditingController(text: widget.existing?.code ?? '');
  late final _descC = TextEditingController(text: widget.existing?.desc ?? '');
  late int _disc = widget.existing?.disc ?? 10;
  late int _maxUses = widget.existing?.maxUses ?? 100;
  late bool _active = widget.existing?.active ?? true;

  @override
  void dispose() {
    _codeC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_codeC.text.trim().isEmpty) {
      await showErrorDialog(context, 'Promo code is required.');
      return;
    }
    final p = widget.existing;
    final id =
        p?.id ??
        (widget.provider.promoCodes.isEmpty
            ? 1
            : widget.provider.promoCodes
                      .map((x) => x.id)
                      .reduce((a, b) => a > b ? a : b) +
                  1);
    await widget.provider.savePromoCode(
      PromoCode(
        id: id,
        code: _codeC.text.trim().toUpperCase(),
        disc: _disc,
        maxUses: _maxUses,
        uses: p?.uses ?? 0,
        desc: _descC.text.trim(),
        active: _active,
      ),
    );
    if (mounted) Navigator.pop(context);
    if (mounted)
      await showSuccessDialog(
        context,
        'Saved!',
        'Promo code saved successfully.',
      );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
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
                Text(
                  widget.existing == null
                      ? 'Add Promo Code'
                      : 'Edit Promo Code',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SheetField(controller: _codeC, label: 'CODE', hint: 'e.g. LABA20'),
            const SizedBox(height: 12),
            _SheetField(
              controller: _descC,
              label: 'DESCRIPTION',
              hint: 'What this promo is for',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISCOUNT %',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: _disc,
                        items: [5, 10, 15, 20, 25, 30, 50]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text('$v%'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _disc = v!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MAX USES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: '$_maxUses',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _maxUses = int.tryParse(v) ?? 100,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Active', style: TextStyle(fontSize: 13)),
                const Spacer(),
                Switch(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  activeColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryBtn(
              label: widget.existing == null ? 'Create Promo' : 'Save Changes',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGE: USER ACCOUNTS
// ═══════════════════════════════════════════════════════════

class AdminUsersPage extends StatefulWidget {
  final AppProvider provider;
  const AdminUsersPage({super.key, required this.provider});
  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchC = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _openForm([AppUser? u]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserBottomSheet(provider: widget.provider, existing: u),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = widget.provider.users
        .where(
          (u) => '${u.name} ${u.email} ${u.phone} ${u.role.name}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        title: 'User Accounts',
        trailing: ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.person_add, size: 15),
          label: const Text('Add User'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchC,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name, email, phone or role',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 34,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 56,
                headingTextStyle: theme.textTheme.labelSmall,
                columns: const [
                  DataColumn(label: Text('AVATAR')),
                  DataColumn(label: Text('NAME')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('PHONE')),
                  DataColumn(label: Text('ROLE')),
                  DataColumn(label: Text('TIER')),
                  DataColumn(label: Text('POINTS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: users.map((u) {
                  final tier = getTier(u.points);
                  return DataRow(
                    cells: [
                      DataCell(_InitialsAvatar(name: u.name, size: 32)),
                      DataCell(
                        Text(
                          u.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(u.email, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text(
                          u.phone.isNotEmpty ? u.phone : '—',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(RoleBadge(u.role)),
                      DataCell(TierBadge(tier)),
                      DataCell(
                        Text(
                          '${u.points} pts',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.lightAccent2,
                              ),
                              onPressed: () => _openForm(u),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 16,
                                color: AppColors.danger,
                              ),
                              onPressed: () async {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Delete User',
                                  message: 'Delete ${u.name}?',
                                  confirmText: 'Delete',
                                );
                                if (ok) widget.provider.deleteUser(u.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBottomSheet extends StatefulWidget {
  final AppProvider provider;
  final AppUser? existing;
  const _UserBottomSheet({required this.provider, this.existing});
  @override
  State<_UserBottomSheet> createState() => _UserBottomSheetState();
}

class _UserBottomSheetState extends State<_UserBottomSheet> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _emailC = TextEditingController(
    text: widget.existing?.email ?? '',
  );
  late final _phoneC = TextEditingController(
    text: widget.existing?.phone ?? '',
  );
  late final _passC = TextEditingController();
  UserRole _role = UserRole.customer;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) _role = widget.existing!.role;
  }

  @override
  void dispose() {
    for (final c in [_nameC, _emailC, _phoneC, _passC]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty || _emailC.text.trim().isEmpty) {
      await showErrorDialog(context, 'Name and email are required.');
      return;
    }
    final ex = widget.existing;
    if (ex == null && _passC.text.length < 12) {
      await showErrorDialog(
        context,
        'Use a temporary password with at least 12 characters.',
      );
      return;
    }
    final u = AppUser(
      id: ex?.id ?? 0,
      authUid: ex?.authUid ?? '',
      name: _nameC.text.trim(),
      email: _emailC.text.trim().toLowerCase(),
      phone: _phoneC.text.trim(),
      role: _role,
      points: ex?.points ?? 0,
      pic: ex?.pic,
    );
    try {
      await widget.provider.saveUser(
        u,
        password: _passC.text.isEmpty ? null : _passC.text,
      );
    } catch (error) {
      if (mounted) await showErrorDialog(context, error.toString());
      return;
    }
    if (mounted) Navigator.pop(context);
    if (mounted)
      await showSuccessDialog(context, 'Saved!', 'User saved successfully.');
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.white;
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
                Text(
                  widget.existing == null ? 'Add User' : 'Edit User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SheetField(
              controller: _nameC,
              label: 'FULL NAME',
              hint: 'Juan dela Cruz',
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: _emailC,
              label: 'EMAIL',
              hint: 'email@example.com',
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: _phoneC,
              label: 'PHONE',
              hint: '09XX XXX XXXX',
              type: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: _passC,
              label: widget.existing == null
                  ? 'TEMPORARY PASSWORD'
                  : 'NEW ACCOUNT PASSWORD (handled in Supabase Auth)',
              hint: 'At least 12 characters',
              obscure: true,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightMuted,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  items: UserRole.values
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _role = v!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryBtn(
              label: widget.existing == null ? 'Create User' : 'Save Changes',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared form field for bottom sheets ──────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  final TextInputType type;
  const _SheetField({
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
          ),
        ),
        const SizedBox(height: 4),
        obscure
            ? PasswordInputField(
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              )
            : TextField(
                controller: controller,
                keyboardType: type,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Initials Avatar ───────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _InitialsAvatar({required this.name, required this.size});

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
