import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/FCM/notificationsService.dart';
import 'package:eyadati/clinic/clinic_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1️⃣ PROVIDER CLASS: Handles ALL business logic and lifecycle
// ─────────────────────────────────────────────────────────────────────────────
class ClinicAppointmentProvider extends ChangeNotifier {
  final String clinicId;
  DateTime selectedDate;

  // Streams: heatmap never changes, appointments changes with date
  late final Stream<QuerySnapshot> heatMapStream;
  Stream<QuerySnapshot>? _appointmentsStream;
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;

  ClinicAppointmentProvider({required this.clinicId, DateTime? initialDate})
    : selectedDate = initialDate ?? DateTime.now() {
    // Initialize streams once
    heatMapStream = _createHeatMapStream();
    _appointmentsStream = _createAppointmentsStream();
  }

  Stream<QuerySnapshot> _createHeatMapStream() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    return FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
        .snapshots();
  }

  Stream<QuerySnapshot> _createAppointmentsStream() {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('date', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('date')
        .snapshots();
  }

  // 📅 Called when user taps a date in heatmap
  void updateSelectedDate(DateTime date) {
    selectedDate = date;
    _appointmentsSubscription?.cancel(); // Cancel old listener
    _appointmentsStream = _createAppointmentsStream(); // Create new one
    notifyListeners(); // Rebuild only widgets that listen
  }

  // 🔥 Process raw Firestore data into heatmap format
  Map<DateTime, int> getHeatMapData(List<QueryDocumentSnapshot> docs) {
    final Map<DateTime, int> heatMapData = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentDate = (data['date'] as Timestamp).toDate();
      final dateOnly = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
      heatMapData[dateOnly] = (heatMapData[dateOnly] ?? 0) + 1;
    }
    return heatMapData;
  }

  // ❌ Cancel appointment + notify user
  Future<void> cancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointmentData,
    BuildContext context,
  ) async {
    await ClinicFirestore().cancelAppointment(appointmentId, clinicId, context);

    await NotificationService().sendDirectNotification(
      fcmToken: appointmentData['FCM'],
      title: 'appointment cancelled'.tr(),
      body: 'your appointment at ${appointmentData['date']} got cancelled'.tr(),
    );
  }

  // 🧹 Provider automatically calls this when widget is removed
  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2️⃣ UI LAYER: Pure, stateless, and simple
// ─────────────────────────────────────────────────────────────────────────────
class ClinicAppointments extends StatelessWidget {
  final String clinicId;

  const ClinicAppointments({super.key, required this.clinicId});

  @override
  Widget build(BuildContext context) {
    // Create provider at the top of the widget tree
    return ChangeNotifierProvider(
      create: (_) => ClinicAppointmentProvider(clinicId: clinicId),
      child: const _ClinicAppointmentsView(),
    );
  }
}

// Inner view - has access to provider but doesn't manage any state
class _ClinicAppointmentsView extends StatelessWidget {
  const _ClinicAppointmentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        minHeight: MediaQuery.of(context).size.height * 0.4,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        panel: const Padding(
          padding: EdgeInsets.all(8.0),
          child: _AppointmentsPanel(),
        ),
        body: Column(
          children: [
            SizedBox(height: 10),
            //  SegmentedButtons(),
            //SizedBox(height: 5,),
            const _HeatMap(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }
}

// Heatmap widget - reads from provider
class _HeatMap extends StatelessWidget {
  const _HeatMap();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicAppointmentProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: provider.heatMapStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final heatMapData = provider.getHeatMapData(snapshot.data!.docs);
        final Color baseColor = Color(0xFF223A5E);
        final colorsets = {
          1: baseColor.withOpacity( 0.3),
          2: baseColor.withOpacity( 0.5),
          3: baseColor.withOpacity (0.7),
          5: baseColor,
        };

        return Center(
          child: HeatMapCalendar(
            colorsets: colorsets,
            onClick: (date) {
              provider.updateSelectedDate(date); // Delegate to provider
            },
            size: 45,
            datasets: heatMapData,
            showColorTip: false,
            weekFontSize: 13,
            textColor: Colors.black,
            weekTextColor: Colors.black,
            monthFontSize: 18,
            fontSize: 15,
          ),
        );
      },
    );
  }
}

// Appointments list widget - reads from provider
class _AppointmentsPanel extends StatelessWidget {
  const _AppointmentsPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicAppointmentProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 6,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: provider._appointmentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No appointments for this day'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              final appointments = snapshot.data!.docs;

              return ListView.builder(
                itemCount: appointments.length,
                key: PageStorageKey(
                  'appointments_${provider.selectedDate.toIso8601String()}',
                ),
                itemBuilder: (context, index) {
                  final doc = appointments[index];
                  final appointment = doc.data() as Map<String, dynamic>;
                  final appointmentId = doc.id;

                  final slot = (appointment['date'] as Timestamp).toDate();
                  final timeFormatted = DateFormat('HH:mm').format(slot);
                  final name = appointment['userName'] ?? 'Unknown';
                  final phone = appointment['phone'] ?? 'No phone';

                  return Slidable(
                    key: ValueKey(appointmentId),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        Container(
                          height: 80,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () async {
                                await provider.cancelAppointment(
                                  appointmentId,
                                  appointment,
                                  context,
                                );
                              },
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    child: Container(
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                timeFormatted,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                phone,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
