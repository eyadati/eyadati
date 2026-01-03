
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

// ================ PROVIDER ================
 class SlotInfo {
    final DateTime time;
    final bool isAvailable;
    final int currentBookings;
    
    SlotInfo({required this.time, required this.isAvailable, required this.currentBookings});
  }
class SlotsUiProvider extends ChangeNotifier {
  final Map<String, dynamic> clinic;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SlotsUiProvider({
    required this.clinic,
    required this.firestore,
    FirebaseAuth? auth,
  }) : auth = auth ?? FirebaseAuth.instance {
    _initializeData();
  }

  // State
  DateTime selectedDate = DateTime.now().toUtc();
  List<SlotInfo> allSlots = [];
  DateTime? selectedSlot;
  bool isLoading = false;
  String errorMessage = '';
  int staffCount = 1;

  // Slot info with availability status
 

  Future<void> _initializeData() async {
    isLoading = true;
    notifyListeners();
    
    try {
      await _loadStaffCount();
      await _loadSlots();
    } catch (e) {
      errorMessage = 'failed_load_slots'.tr(args: [e.toString()]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStaffCount() async {
    final clinicDoc = await firestore.collection('clinics').doc(clinic['uid']).get();
    if (clinicDoc.exists) {
      staffCount = clinicDoc.data()?['staff'] ?? 1;
    }
  }

  Future<void> _loadSlots() async {
    // Get all appointments for selected date
    final startOfDay = DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await firestore
        .collection('clinics')
        .doc(clinic['uid'])
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // Count bookings per slot
    final bookingCounts = <DateTime, int>{};
    for (var doc in snapshot.docs) {
      final appointmentTime = (doc.data()['date'] as Timestamp).toDate().toUtc();
      final slotHour = DateTime.utc(
        appointmentTime.year,
        appointmentTime.month,
        appointmentTime.day,
        appointmentTime.hour,
      );
      bookingCounts[slotHour] = (bookingCounts[slotHour] ?? 0) + 1;
    }

    // Generate all slots based on clinic hours
    allSlots = [];
    final clinicData = await firestore.collection('clinics').doc(clinic['uid']).get();
    
    if (clinicData.exists) {
      final data = clinicData.data()!;
      final opening = data['openingAt'] ?? 480; // 8:00 AM default
      final closing = data['closingAt'] ?? 1080; // 6:00 PM default
      final breakStart = data['breakStart'];
      final breakEnd = data['breakEnd'];
      final workingDays = List<int>.from(data['workingDays'] ?? []);

      // Check if clinic is open on selected day
      if (!workingDays.contains(selectedDate.weekday)) {
        allSlots = []; // No slots on closed days
        return;
      }

      DateTime slotTime = DateTime.utc(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        opening ~/ 60,
        opening % 60,
      );

      final closingTime = DateTime.utc(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        closing ~/ 60,
        closing % 60,
      );

      while (slotTime.isBefore(closingTime)) {
        final slotEnd = slotTime.add(const Duration(hours: 1));
        
        // Skip if slot overlaps with break
        if (breakStart != null && breakEnd != null) {
          final breakStartTime = DateTime.utc(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            breakStart ~/ 60,
            breakStart % 60,
          );
          final breakEndTime = DateTime.utc(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            breakEnd ~/ 60,
            breakEnd % 60,
          );
          
          if (slotTime.isBefore(breakEndTime) && slotEnd.isAfter(breakStartTime)) {
            slotTime = slotEnd;
            continue;
          }
        }

        final bookings = bookingCounts[slotTime] ?? 0;
        final isAvailable = bookings < staffCount;
        
        allSlots.add(SlotInfo(
          time: slotTime,
          isAvailable: isAvailable,
          currentBookings: bookings,
        ));

        slotTime = slotEnd;
      }
    }
  }

  Future<void> changeDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != selectedDate) {
      selectedDate = picked.toUtc();
      selectedSlot = null;
      await _loadSlots();
      notifyListeners();
    }
  }

  void selectSlot(DateTime slot) {
    // Only allow selecting available slots
    final slotInfo = allSlots.firstWhere(
      (s) => s.time == slot,
      orElse: () => SlotInfo(time: slot, isAvailable: false, currentBookings: 0),
    );
    
    if (slotInfo.isAvailable) {
      selectedSlot = slot;
      notifyListeners();
    }
  }

  Future<bool> confirmBooking(BuildContext context) async {
    if (selectedSlot == null) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_booking'.tr()),
        content: Text(
          'booking_details'.tr(args: [
            DateFormat('yyyy-MM-dd').format(selectedDate),
            '${selectedSlot!.hour}:${selectedSlot!.minute.toString().padLeft(2, '0')}',
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> bookSelectedSlot(BuildContext context) async {
    if (selectedSlot == null) return;

    final confirmed = await confirmBooking(context);
    if (!confirmed || !context.mounted) return;

    try {
      await firestore.runTransaction((transaction) async {
        // Check slot availability again
        final startOfDay = DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day);
        final slotStart = selectedSlot!;
        final slotEnd = slotStart.add(const Duration(hours: 1));

        final querySnapshot = await firestore
            .collection('clinics')
            .doc(clinic['uid'])
            .collection('appointments')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(slotStart))
            .where('date', isLessThan: Timestamp.fromDate(slotEnd))
            .get();

        if (querySnapshot.docs.length >= staffCount) {
          throw Exception('slot is full'.tr());
        }

        // Book the slot
        final appointmentId = "${clinic['uid']}_${auth.currentUser!.uid}_${slotStart.millisecondsSinceEpoch}";
        final appointmentData = {
          "clinicUid": clinic['uid'],
          "userUid": auth.currentUser!.uid,
          "date": Timestamp.fromDate(slotStart),
          "createdAt": FieldValue.serverTimestamp(),
        };

        transaction.set(
          firestore.collection('clinics').doc(clinic['uid']).collection('appointments').doc(appointmentId),
          appointmentData,
        );
        transaction.set(
          firestore.collection('users').doc(auth.currentUser!.uid).collection('appointments').doc(appointmentId),
          appointmentData,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('booking success'.tr())),
      );
      
      Navigator.of(context).pop(true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('booking failed'.tr(args: [e.toString()]))),
      );
    }
  }
}

// ================ UI DIALOG ================

class SlotsUi {
  static Future<bool?> showSlotDialog(BuildContext context, Map<String, dynamic> clinic) {
    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => SlotsUiProvider(
          clinic: clinic,
          firestore: FirebaseFirestore.instance,
        ),
        child: const _SlotsDialog(),
      ),
    );
  }
}

class _SlotsDialog extends StatelessWidget {
  const _SlotsDialog();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlotsUiProvider>();
    final clinic = provider.clinic;

    return AlertDialog(
      title: Text('book appointment'.tr()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clinic Info Card
            _ClinicInfoCard(clinic: clinic),
            const SizedBox(height: 16),
            
            // Date Picker Row
            _DatePickerRow(),
            const SizedBox(height: 16),
            
            // Slots Grid
            Flexible(
              child: _SlotsGrid(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: provider.selectedSlot == null 
            ? null 
            : () => provider.bookSelectedSlot(context),
          child: Text('book'.tr()),
        ),
      ],
    );
  }
}

class _ClinicInfoCard extends StatelessWidget {
  final Map<String, dynamic> clinic;

  const _ClinicInfoCard({required this.clinic});

  @override
  Widget build(BuildContext context) {
    final workingDays = List<int>.from(clinic['workingDays'] ?? []);
    final dayNames = [
      'monday'.tr(),
      'tuesday'.tr(),
      'wednesday'.tr(),
      'thursday'.tr(),
      'friday'.tr(),
      'saturday'.tr(),
      'sunday'.tr(),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clinic['clinicName'] ?? 'clinic unnamed'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${'address'.tr()}: ${clinic['address'] ?? ""}'),
            const SizedBox(height: 4),
            Text('${'working_days'.tr()}: ${workingDays.map((d) => dayNames[d-1]).join(', ')}'),
            const SizedBox(height: 4),
            Text(
              '${'hours'.tr()}: ${_formatTime(clinic['openingAt'])} - ${_formatTime(clinic['closingAt'])}',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int? minutes) {
    if (minutes == null) return '--:--';
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }
}

class _DatePickerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlotsUiProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${'date'.tr()}: ${DateFormat('yyyy-MM-dd').format(provider.selectedDate)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => provider.changeDate(context),
          tooltip: 'change date'.tr(),
        ),
      ],
    );
  }
}

class _SlotsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SlotsUiProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(child: Text(provider.errorMessage, style: const TextStyle(color: Colors.red)));
    }

    if (provider.allSlots.isEmpty) {
      return Center(child: Text('no slots available'.tr()));
    }

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: provider.allSlots.length,
      itemBuilder: (context, index) {
        final slotInfo = provider.allSlots[index];
        final isSelected = provider.selectedSlot == slotInfo.time;
        
        return _SlotTile(
          slotInfo: slotInfo,
          isSelected: isSelected,
          onTap: () => provider.selectSlot(slotInfo.time),
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
   SlotInfo slotInfo;
  final bool isSelected;
  final VoidCallback onTap;

   _SlotTile({
    required this.slotInfo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(slotInfo.time);
    final isFull = !slotInfo.isAvailable;

    return GestureDetector(
      onTap: isFull ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.blue.shade300
            : isFull 
              ? Colors.grey.shade300.withOpacity(0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              timeString,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isFull ? Colors.grey.shade500 : Colors.black87,
                fontSize: 12,
              ),
            ),
            if (isFull) ...[
              const SizedBox(height: 2),
              Text(
                'full'.tr(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ] else if (!isSelected) ...[
              const SizedBox(height: 2),
              Text(
                '${slotInfo.currentBookings}/${context.read<SlotsUiProvider>().staffCount}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



