import 'package:eyadati/user/UserHome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eyadati/Appointments/booking_logic.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Manages slot selection and booking state
class SlotsUiProvider extends ChangeNotifier {
  final Map<String, dynamic> clinic;
  final BookingLogic bookingLogic;
  final FirebaseAuth auth;

  SlotsUiProvider({
    required this.clinic,
    BookingLogic? bookingLogic,
    FirebaseAuth? auth,
  }) : bookingLogic = bookingLogic ?? BookingLogic(),
       auth = auth ?? FirebaseAuth.instance;

  DateTime selectedDate = DateTime.now().toUtc();
  List<DateTime> availableSlots = [];
  bool isLoading = false;
  String errorMessage = '';

  static const _dateFormat = 'yyyy-MM-dd';

  /// Loads slots for the selected date
  Future<void> loadSlots() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final slots = await bookingLogic.generateSlots(
        selectedDate,
        clinic['uid'],
      );
      availableSlots = slots;
    } catch (e) {
      errorMessage = 'Failed to load slots: $e';
      debugPrint('Slot loading error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Shows date picker and updates selected date
  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != selectedDate) {
      selectedDate = picked.toUtc();
      await loadSlots();
    }
  }

  /// Books a slot and handles navigation
  Future<void> bookSlot(BuildContext context, DateTime slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Book appointment on ${DateFormat(_dateFormat).format(selectedDate)} '
          'at ${slot.hour}:${slot.minute.toString().padLeft(2, '0')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await bookingLogic.bookAppointment(clinic['uid'], slot);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Appointment booked!')),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Userhome()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Booking failed: $e')),
      );
    }
  }
}

/// UI for displaying and booking clinic slots
class SlotsUi extends StatelessWidget {
  final Map<String, dynamic> clinic;

  const SlotsUi({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SlotsUiProvider(clinic: clinic)..loadSlots(),
      child: const _SlotsUiView(),
    );
  }
}

class _SlotsUiView extends StatelessWidget {
  const _SlotsUiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<SlotsUiProvider>().clinic['name'] ?? 'Clinic Slots'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _DateHeader(),
          Expanded(child: _SlotsList()),
        ],
      ),
    );
  }
}

/// Date selection header
class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlotsUiProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date: ${DateFormat('yyyy-MM-dd').format(provider.selectedDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: () => provider.selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

/// Available slots list
class _SlotsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlotsUiProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          provider.errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (provider.availableSlots.isEmpty) {
      return const Center(child: Text('No available slots'));
    }

    return ListView.builder(
      itemCount: provider.availableSlots.length,
      itemBuilder: (context, index) {
        final slot = provider.availableSlots[index];
        final timeString = DateFormat('HH:mm').format(slot);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.access_time, size: 40, color: Colors.blue),
            title: Text(
              timeString,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              slot.hour < 12 ? 'Morning' : slot.hour < 17 ? 'Afternoon' : 'Evening',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => provider.bookSlot(context, slot),
          ),
        );
      },
    );
  }
}