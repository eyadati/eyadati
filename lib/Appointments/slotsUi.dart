import 'package:eyadati/user/user_appointments.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';

// ================ PROVIDER ================
class SlotInfo {
  final DateTime time;
  final bool isAvailable;
  final int currentBookings;
  final int duration;

  SlotInfo({
    required this.duration,
    required this.time,
    required this.isAvailable,
    required this.currentBookings,
  });
}

class SlotsUiProvider extends ChangeNotifier {
  final Map<String, dynamic> clinic;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  late final int duration;

  SlotsUiProvider({
    required this.clinic,
    required this.firestore,
    FirebaseAuth? auth,
  }) : auth = auth ?? FirebaseAuth.instance {
    _initializeData();
  }

  // Calendar state moved to provider
  DateTime focusedDay = DateTime.now();
  // State
  DateTime selectedDate = DateTime.now();
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

  void updateSelectedDate(DateTime date) {
    selectedDate = date;
    focusedDay = date;
    debugPrint(selectedDate.toString());
    debugPrint(focusedDay.toString());
    notifyListeners();
  }

  /// Updates calendar focus day
  void updateFocusedDay(DateTime day) {
    focusedDay = day;
    notifyListeners();
  }

  Future<void> _loadStaffCount() async {
    final clinicDoc = await firestore
        .collection('clinics')
        .doc(clinic['uid'])
        .get();
    if (clinicDoc.exists) {
      staffCount = clinicDoc.data()?['staff'] ?? 1;
    }
    debugPrint('Clinic doc: $clinicDoc');
  }

  Future<void> _loadSlots() async {
    allSlots = []; // Clear first

    // Get appointments for the day
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await firestore
        .collection('clinics')
        .doc(clinic['uid'])
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // Count bookings per EXACT slot start time
    final bookingCounts = <DateTime, int>{};
    for (var doc in snapshot.docs) {
      final appointmentTime = (doc.data()['date'] as Timestamp).toDate();
      // ✅ Use the exact appointment time as key
      final slotKey = DateTime(
        appointmentTime.year,
        appointmentTime.month,
        appointmentTime.day,
        appointmentTime.hour,
        appointmentTime.minute,
      );
      bookingCounts[slotKey] = (bookingCounts[slotKey] ?? 0) + 1;
    }

    // Fetch clinic configuration
    final clinicData = await firestore
        .collection('clinics')
        .doc(clinic['uid'])
        .get();
    if (!clinicData.exists) return;

    final data = clinicData.data()!;
    final opening = data['openingAt'] as int;
    final closing = data['closingAt'] as int;
    final breakStart = data['breakStart'] as int?;
    final breakEnd = data['breakEnd'] as int?;
    final duration = data['duration'] as int?;
    final workingDays = List<int>.from(data['workingDays'] ?? []);

    // Check if clinic is open
    if (!workingDays.contains(selectedDate.weekday)) {
      return;
    }

    DateTime currentSlot = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      opening ~/ 60,
      opening % 60,
    );

    final closingTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      closing ~/ 60,
      closing % 60,
    );

    final slotDuration = duration ?? 60;

    // ✅ Efficient generation loop
    while (currentSlot.isBefore(closingTime)) {
      final slotEnd = currentSlot.add(Duration(minutes: slotDuration));

      // ✅ Correct break overlap check (ANY overlap)
      if (breakStart != null && breakEnd != null) {
        final breakStartTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          breakStart ~/ 60,
          breakStart % 60,
        );
        final breakEndTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          breakEnd ~/ 60,
          breakEnd % 60,
        );

        // Skip if slot overlaps with break (any overlap)
        if (currentSlot.isBefore(breakEndTime) &&
            slotEnd.isAfter(breakStartTime)) {
          currentSlot = slotEnd;
          continue;
        }
      }

      // ✅ Match bookings by exact slot time
      final bookings = bookingCounts[currentSlot] ?? 0;
      final isAvailable = bookings < (data['staff'] as int? ?? 1);

      allSlots.add(
        SlotInfo(
          time: currentSlot,
          duration: slotDuration,
          isAvailable: isAvailable,
          currentBookings: bookings,
        ),
      );

      currentSlot = slotEnd;
    }
  }

  Future<void> changeDate(BuildContext context, DateTime picked) async {
    selectedDate = DateTime(picked.year, picked.month, picked.day);
    selectedSlot = null;
    focusedDay = DateTime(picked.year, picked.month, picked.day);
    allSlots = []; // Clear old slots
    await _loadSlots(); // Regenerate for new date
    notifyListeners();
  }

  void selectSlot(DateTime slot) {
    // Only allow selecting available slots
    final slotInfo = allSlots.firstWhere(
      (s) => s.time == slot,
      orElse: () => SlotInfo(
        time: slot,
        isAvailable: false,
        currentBookings: 0,
        duration: duration,
      ),
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
          'booking_details'.tr(
            args: [
              DateFormat('yyyy-MM-dd').format(selectedDate),
              '${selectedSlot!.hour}:${selectedSlot!.minute.toString().padLeft(2, '0')}',
            ],
          ),
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
        // Get the actual slot duration
        final slotInfo = allSlots.firstWhere((s) => s.time == selectedSlot);

        // Check availability
        final slotStart = Timestamp.fromDate(selectedSlot!);
        final slotEnd = Timestamp.fromDate(
          selectedSlot!.add(Duration(minutes: slotInfo.duration)),
        );

        final querySnapshot = await firestore
            .collection('clinics')
            .doc(clinic['uid'])
            .collection('appointments')
            .where('date', isGreaterThanOrEqualTo: slotStart)
            .where('date', isLessThan: slotEnd)
            .get();

        if (querySnapshot.docs.length >= staffCount) {
          throw Exception('slot is full'.tr());
        }

        // Book the slot
        final appointmentId =
            "${clinic['uid']}_${auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}";
        final appointmentData = {
          "clinicUid": clinic['uid'],
          "userUid": auth.currentUser!.uid,
          "date": slotStart, // Already a Timestamp
          "createdAt": FieldValue.serverTimestamp(),
        };

        transaction.set(
          firestore
              .collection('clinics')
              .doc(clinic['uid'])
              .collection('appointments')
              .doc(appointmentId),
          appointmentData,
        );
        transaction.set(
          firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('appointments')
              .doc(appointmentId),
          appointmentData,
        );

        // ✅ Remove this from transaction - put it outside
        // await context.read<UserAppointmentsProvider>().loadAppointments();
      });

      // ✅ Refresh data AFTER transaction completes
      if (context.mounted) {
        await context.read<UserAppointmentsProvider>().loadAppointments();

        // Refresh current slots view
        await _loadSlots();
        notifyListeners();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('booking success'.tr())));

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('booking failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }
}

// ================ UI DIALOG ================

class SlotsUi {
  static Future<bool?> showModalSheet(
    BuildContext context,
    Map<String, dynamic> clinic,
  ) {
    return showMaterialModalBottomSheet(
      expand: true,

      context: context,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => SlotsUiProvider(
          clinic: clinic,
          firestore: FirebaseFirestore.instance,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: const _SlotsDialog(),
          ),
        ),
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

    return SizedBox(
      width: double.maxFinite,

      child: Column(
        children: [
          _ClinicInfoCard(clinic: clinic),
          const SizedBox(height: 10),
          _DatePickerRow(),
          Flexible(child: _SlotsGrid()),

          Container(
            margin: EdgeInsets.all(12),
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => provider.bookSelectedSlot(context),
              child: Text("Book Appointment"),
            ),
          ),
        ],
      ),
    );
  }
}

/*TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: provider.selectedSlot == null
              ? null
              : () => provider.bookSelectedSlot(context),
          child: Text('book'.tr()),
        ),*/
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
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                child: Image.asset("assets/avatars/${clinic["avatar"]}.png"),
              ),
            ),
            SizedBox(height: 20),
            Text(
              clinic['clinicName'] ?? 'clinic unnamed'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  '  ${clinic['specialty']}  ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text('${clinic['address'] ?? ""}'),
            const SizedBox(height: 4),
            Text(
              workingDays
                  .where((d) => d >= 1 && d <= 7)
                  .map((d) => dayNames[d - 1])
                  .join(', ')
                  .tr(),
            ),

            const SizedBox(height: 4),
            Text(
              '${_formatTime(clinic['openingAt'])} - ${_formatTime(clinic['closingAt'])}   ',
              style: TextStyle(fontWeight: FontWeight.w700),
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

    return SizedBox(
      height: 140,
      child: TableCalendar(
        selectedDayPredicate: (day) => isSameDay(provider.selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(provider.selectedDate, selectedDay)) {
            provider.changeDate(context, selectedDay);
          }
        },
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
        ),
        calendarStyle: CalendarStyle(
          markersMaxCount: 5,
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        focusedDay: provider.focusedDay,
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(Duration(days: 14)),
        calendarFormat: CalendarFormat.week,
      ),
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
      return Center(
        child: Text(
          provider.errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
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
    final slotEndString = DateFormat(
      'HH:mm',
    ).format(slotInfo.time.add(Duration(minutes: slotInfo.duration)));
    final isFull = !slotInfo.isAvailable;

    return GestureDetector(
      onTap: isFull ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.black),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : isFull
              ? Colors.grey.shade300.withOpacity(0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              timeString,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isFull
                    ? Colors.grey.shade300
                    : isSelected
                    ? Colors.white
                    : isFull
                    ? Colors.grey.shade300.withOpacity(0.5)
                    : Colors.black,
                fontSize: 12,
              ),
            ),
            if (isFull) ...[] else if (!isSelected) ...[],
          ],
        ),
      ),
    );
  }
}
