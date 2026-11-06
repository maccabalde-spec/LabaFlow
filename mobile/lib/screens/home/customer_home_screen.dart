import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../booking/booking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Laundry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _supabase.auth.signOut(),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Realtime stream of the current customer's orders
        stream: _supabase
            .from('laundry_orders')
            .stream(primaryKey: ['id'])
            .eq('customer_id', userId)
            .order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book Laundry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_laundry_service, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No active laundry orders.', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor;
    switch (order['status']) {
      case 'Pending': statusColor = Colors.orange; break;
      case 'Received': statusColor = Colors.blue; break;
      case 'In Progress': statusColor = AppColors.primary; break;
      case 'Ready for Pick-up': statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order['order_reference'] ?? 'Pending Ref', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.scale, size: 16, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text(order['weight_kg'] != null ? '${order['weight_kg']} kg' : 'Awaiting weighing', style: const TextStyle(color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text('Payment: ${order['payment_status']}', style: const TextStyle(color: AppColors.textLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}