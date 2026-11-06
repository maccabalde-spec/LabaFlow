import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _services = [];
  String? _selectedServiceId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    final data = await _supabase.from('services').select().eq('is_active', true);
    setState(() {
      _services = data;
      if (_services.isNotEmpty) _selectedServiceId = _services.first['id'];
      _isLoading = false;
    });
  }

  Future<void> _submitBooking() async {
    if (_selectedServiceId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      // RLS Policy ensures customers can only insert 'Pending' orders linked to their ID
      await _supabase.from('laundry_orders').insert({
        'customer_id': userId,
        'service_id': _selectedServiceId,
        'status': 'Pending',
        'payment_status': 'Unpaid',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking requested successfully! Drop off your laundry anytime.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select a Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedServiceId,
                  isExpanded: true,
                  items: _services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service['id'],
                      child: Text('${service['name']} - ₱${service['price_per_kg']}/kg'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedServiceId = val),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              '1. Submit your booking request.\n2. Bring your laundry to the shop.\n3. Staff will weigh your laundry, assign an RFID tag, and update your final total.\n4. Track your laundry progress live in the app.',
              style: TextStyle(color: AppColors.textLight, height: 1.5),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}