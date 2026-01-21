import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/FCM/notificationsService.dart';
import 'package:eyadati/user/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Represents a combined appointment and its associated clinic data
class AppointmentWithClinic {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> clinic;

  AppointmentWithClinic({required this.appointment, required this.clinic});
}

/// Manages user appointments with batched clinic data fetching.
class UserAppointmentsProvider extends ChangeNotifier {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final UserFirestore _userFirestore;
  final NotificationService _notificationService;

  StreamSubscription? _appointmentsSubscription;

  List<AppointmentWithClinic> _appointments = [];
  List<AppointmentWithClinic> get appointments => _appointments;

  final Map<String, Map<String, dynamic>> _clinicCache = {};
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  UserAppointmentsProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    UserFirestore? userFirestore,
    NotificationService? notificationService,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance,
        _userFirestore = userFirestore ?? UserFirestore(),
        _notificationService = notificationService ?? NotificationService() {
    _initAppointmentsStream();
  }

  void _initAppointmentsStream() {
    _isLoading = true;
    notifyListeners();

    _appointmentsSubscription?.cancel();

    final userId = auth.currentUser?.uid;
    if (userId == null) {
      _isLoading = false;
      _appointments = [];
      notifyListeners();
      return;
    }

    final stream = firestore
        .collection("users")
        .doc(userId)
        .collection("appointments")
        .where("date", isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy("date")
        .limit(15)
        .snapshots();

    _appointmentsSubscription = stream.listen((snapshot) async {
      final appointmentDocs = snapshot.docs;
      if (appointmentDocs.isEmpty) {
        _appointments = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final clinicUids = appointmentDocs
          .map((doc) => doc.data()['clinicUid'] as String)
          .toSet();

      // Fetch clinic data for UIDs not already in cache
      final uidsToFetch =
          clinicUids.where((uid) => !_clinicCache.containsKey(uid)).toList();
      if (uidsToFetch.isNotEmpty) {
        // Firestore 'in' query is limited to 30 elements per query.
        for (var i = 0; i < uidsToFetch.length; i += 30) {
          final batchUids =
              uidsToFetch.skip(i).take(30).toList();
          final clinicsSnapshot = await firestore
              .collection('clinics')
              .where(FieldPath.documentId, whereIn: batchUids)
              .get();
          for (var doc in clinicsSnapshot.docs) {
            _clinicCache[doc.id] = doc.data();
          }
        }
      }

      // Combine appointments with cached clinic data
      final newAppointments = <AppointmentWithClinic>[];
      for (var doc in appointmentDocs) {
        final appointmentData = doc.data();
        appointmentData['id'] = doc.id; // Add document ID to map
        final clinicData = _clinicCache[appointmentData['clinicUid']];
        if (clinicData != null) {
          newAppointments.add(AppointmentWithClinic(
            appointment: appointmentData,
            clinic: clinicData,
          ));
        }
      }

      _appointments = newAppointments;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> cancelAppointment(
    String appointmentId,
    String clinicUid,
    Map<String, dynamic> clinicData,
    BuildContext context,
  ) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;

    await _userFirestore.cancelAppointment(appointmentId, userId, context);

    if (clinicData['FCM'] != null) {
      await _notificationService.sendDirectNotification(
        fcmToken: clinicData['FCM'],
        title: 'appointment_cancelled'.tr(),
        body: 'the_appointment_got_cancelled'.tr(),
      );
    }
    // The stream will update the list automatically, no need for notifyListeners()
  }

  Future<void> refresh() async {
    _initAppointmentsStream();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }
}

/// Main entry widget for user appointments list
class Appointmentslistview extends StatelessWidget {
  const Appointmentslistview({super.key});

  @override
  Widget build(BuildContext context) {
    // The provider is created in `userAppointments.dart`
    return const _AppointmentsListView();
  }
}

class _AppointmentsListView extends StatelessWidget {
  const _AppointmentsListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAppointmentsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.appointments.isEmpty) {
          return Center(child: Text('no_appointments'.tr()));
        }

        final appointments = provider.appointments;

        return ListView.builder(
          itemCount: appointments.length + 1, // Add 1 for the SizedBox
          itemBuilder: (context, index) {
            if (index == appointments.length) {
              return SizedBox(
                height: 92 + MediaQuery.of(context).padding.bottom,
              ); // Adjust height for floating nav bar
            }
            final appointmentWithClinic = appointments[index];
            final slot =
                appointmentWithClinic.appointment["date"] as Timestamp?;

            if (slot == null) return const SizedBox.shrink();

            return _AppointmentCard(
              appointment: appointmentWithClinic.appointment,
              clinicData: appointmentWithClinic.clinic,
              slot: slot,
            );
          },
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> clinicData;
  final Timestamp slot;

  const _AppointmentCard({
    required this.appointment,
    required this.clinicData,
    required this.slot,
  });

  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
    final weekday = DateFormat('EEEE').format(date);
    final formatted = DateFormat('M/d/yyyy').format(date);
    return "$weekday $formatted";
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final appointmentId = appointment["id"] as String;
    final clinicUid = appointment["clinicUid"] as String;
    final shopName = clinicData["name"] ?? "unknown_shop".tr();
    final address = clinicData["address"] ?? "unknown_address".tr();
    final mapsLink = clinicData["mapsLink"] as String?;

    return Slidable(
      key: ValueKey(appointmentId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.2,
        children: [
          IconButton(
            onPressed: () async {
              await context.read<UserAppointmentsProvider>().cancelAppointment(
                    appointmentId,
                    clinicUid,
                    clinicData,
                    context,
                  );
            },
            icon: Icon(
              LucideIcons.xCircle,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          title: _buildMarqueeRow("clinic".tr(), shopName, isTitle: true),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMarqueeRow("address".tr(), address),
              const SizedBox(height: 4),
              Text(_formatDate(slot), style: const TextStyle(fontSize: 14)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(slot),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (mapsLink != null && mapsLink.isNotEmpty)
                    IconButton(
                      onPressed: () async {
                        await launchUrl(
                          mode: LaunchMode.platformDefault,
                          Uri.parse(mapsLink),
                        );
                      },
                      icon: const Icon(
                        LucideIcons.mapPin,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarqueeRow(String label, String value, {bool isTitle = false}) {
    return SizedBox(
      height: isTitle ? 35 : 30,
      child: Row(
        children: [
          Text("$label: "),
          Expanded(
            child: Marquee(
              text: value,
              style: TextStyle(
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
                fontSize: isTitle ? 16 : 14,
              ),
              velocity: isTitle ? 25 : 15,
              blankSpace: isTitle ? 50 : 40,
              pauseAfterRound: const Duration(seconds: 1),
            ),
          ),
        ],
      ),
    );
  }
}
