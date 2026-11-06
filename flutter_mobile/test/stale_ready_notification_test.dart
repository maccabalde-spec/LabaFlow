import 'package:flutter_test/flutter_test.dart';
import 'package:labaflow_mobile/models/models.dart';
import 'package:labaflow_mobile/providers/app_provider.dart';

void main() {
  late AppProvider provider;
  late AppUser customer;

  setUp(() {
    provider = AppProvider();
    customer = AppUser(
      id: 8,
      authUid: 'customer-uid',
      name: 'Customer',
      email: 'customer@example.com',
      phone: '',
      role: UserRole.customer,
    );
    provider.currentUser = customer;
    provider.notifs = [
      Notif(
        id: 1,
        toId: customer.id,
        type: 'READY',
        title: 'Order ORD-014 is READY!',
        msg: 'Your laundry is ready for pickup.',
        icon: '✓',
        date: DateTime(2026, 10, 18),
      ),
      Notif(
        id: 2,
        toId: customer.id,
        type: 'ORDER_PLACED',
        title: 'Order ORD-014 placed',
        msg: 'Your order has been received.',
        icon: '✓',
        date: DateTime(2026, 10, 18),
      ),
    ];
  });

  tearDown(() => provider.dispose());

  test('hides a READY notification when the customer has no orders', () {
    expect(provider.myNotifs().map((notification) => notification.type).toList(), ['ORDER_PLACED']);
    expect(provider.unreadCount(), 1);
  });

  test('keeps a READY notification only for its matching ready order', () {
    provider.orders = [_order(number: 'ORD-014', status: OrderStatus.ready)];
    expect(provider.myNotifs().map((notification) => notification.type).toList(), ['ORDER_PLACED', 'READY']);
  });

  test('hides a READY notification after its order is released', () {
    provider.orders = [_order(number: 'ORD-014', status: OrderStatus.released)];
    expect(provider.myNotifs().map((notification) => notification.type).toList(), ['ORDER_PLACED']);
  });

  test('does not show a READY notice for a different ready order', () {
    provider.orders = [_order(number: 'ORD-015', status: OrderStatus.ready)];
    expect(provider.myNotifs().map((notification) => notification.type).toList(), ['ORDER_PLACED']);
  });
}

Order _order({required String number, required OrderStatus status}) => Order(
      id: 14,
      num: number,
      custId: 8,
      custName: 'Customer',
      type: OrderType.clothes,
      status: status,
      price: 180,
      breakdown: '',
      created: DateTime(2026, 10, 18),
    );
