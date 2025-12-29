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

/// Manages clinic appointment state with optimized Firestore queries
/// and proper lifecycle management to prevent memory leaks.
class ClinicAppointmentProvider extends ChangeNotifier {
  final String clinicId;
  DateTime selectedDate;
  
  late final Stream<QuerySnapshot> _appointmentsStream;
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;

  ClinicAppointmentProvider({
    required this.clinicId,
    DateTime? initialDate,
  }) : selectedDate = (initialDate ?? DateTime.now()).toUtc() {
    _appointmentsStream = _createAppointmentsStream();
  }

  /// Creates a stream for the selected day's appointments
  Stream<QuerySnapshot> _createAppointmentsStream() {
    final dayStart = DateTime.utc(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .where('date', isGreaterThan: Timestamp.fromDate(DateTime.now().toUtc()))
        .orderBy('date')
        .snapshots();
  }

  /// Fetches heatmap data once (static monthly data)
  Future<Map<DateTime, int>> getHeatMapData() async {
    final now = DateTime.now().toUtc();
    final firstDay = DateTime.utc(now.year, now.month, 1);
    final lastDay = DateTime.utc(now.year, now.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('appointments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
        .get();

    final heatMapData = <DateTime, int>{};
    for (var doc in snapshot.docs) {
      final appointmentDate = (doc.data()['date'] as Timestamp).toDate().toUtc();
      final dateKey = DateTime.utc(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
      heatMapData[dateKey] = (heatMapData[dateKey] ?? 0) + 1;
    }
    return heatMapData;
  }

  /// Updates the selected date and refreshes appointment stream
  void updateSelectedDate(DateTime date) {
    selectedDate = date.toUtc();
    _appointmentsSubscription?.cancel();
    _appointmentsStream = _createAppointmentsStream();
    notifyListeners();
  }

  /// Cancels an appointment and sends notification
  Future<void> cancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointmentData,
    BuildContext context,
  ) async {
    await ClinicFirestore().cancelAppointment(appointmentId, clinicId, context);

    if (appointmentData['FCM'] != null) {
      await NotificationService().sendDirectNotification(
        fcmToken: appointmentData['FCM'],
        title: 'appointment cancelled'.tr(),
        body: 'your appointment at ${appointmentData['date']} got cancelled'.tr(),
      );
    }
  }

  /// Cleans up stream subscription to prevent memory leaks
  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  // Getter for stream access
  Stream<QuerySnapshot> get appointmentsStream => _appointmentsStream;
}

/// Main widget that provides the appointment management state
class ClinicAppointments extends StatelessWidget {
  final String clinicId;

  const ClinicAppointments({super.key, required this.clinicId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClinicAppointmentProvider(clinicId: clinicId),
      child: const _ClinicAppointmentsView(),
    );
  }
}

/// Main view with sliding panel layout
class _ClinicAppointmentsView extends StatelessWidget {
  const _ClinicAppointmentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        minHeight: MediaQuery.of(context).size.height * 0.4,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        panel: const _AppointmentsPanel(),
        body: Column(
          children: [
            const SizedBox(height: 10),
            const _HeatMap(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.5),
          ],
        ),
      ),
    );
  }
}

/// Monthly appointment heatmap with one-time data fetch
class _HeatMap extends StatelessWidget {
  const _HeatMap();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ClinicAppointmentProvider>();

    return FutureBuilder<Map<DateTime, int>>(
      future: provider.getHeatMapData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Heatmap error: ${snapshot.error}');
          return const Center(child: Icon(Icons.error_outline, color: Colors.red));
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final baseColor = const Color(0xFF223A5E);
        final colorsets = {
          1: baseColor.withOpacity(0.3),
          2: baseColor.withOpacity(0.5),
          3: baseColor.withOpacity(0.7),
          5: baseColor,
        };

        return Center(
          child: HeatMapCalendar(
            colorsets: colorsets,
            onClick: provider.updateSelectedDate,
            size: 45,
            datasets: snapshot.data!,
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

/// Daily appointments list with swipe-to-cancel
class _AppointmentsPanel extends StatelessWidget {
  const _AppointmentsPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDragHandle(context),
        Expanded(
          child: Selector<ClinicAppointmentProvider, DateTime>(
            selector: (_, provider) => provider.selectedDate,
            builder: (_, __, ___) {
              final provider = context.read<ClinicAppointmentProvider>();
              
              return StreamBuilder<QuerySnapshot>(
                stream: provider.appointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('Appointments error: ${snapshot.error}');
                    return Center(
                      child: Text('Error loading appointments'.tr()),
                    );
                  }

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
                          extentRatio: 0.2,
                          children: [
                            IconButton(
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
                          ],
                        ),
                        child: Container(
                          height: 80,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 6,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}