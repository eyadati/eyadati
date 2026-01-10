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

/// Manages user appointments with batched clinic data fetching and pagination
class UserAppointmentsProvider extends ChangeNotifier {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final UserFirestore _userFirestore;
  final NotificationService _notificationService;

  final List<Map<String, dynamic>> _appointments = [];
  final Map<String, Map<String, dynamic>> _clinicCache = {};

  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 20;
  DocumentSnapshot? _lastDocument;

  UserAppointmentsProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    UserFirestore? userFirestore,
    NotificationService? notificationService,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance,
        _userFirestore = userFirestore ?? UserFirestore(),
        _notificationService = notificationService ?? NotificationService();

  List<Map<String, dynamic>> get appointments => _appointments;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  /// Loads appointments with pagination and batch-fetches clinic data
  Future<void> loadAppointments() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query = firestore
          .collection("users")
          .doc(userId)
          .collection("appointments")
          .where("date", isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy("date", descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        _lastDocument = null; // Reset _lastDocument if no more documents
        notifyListeners(); // Notify listeners as state changes
        return;
      }

      _lastDocument = snapshot.docs.last;
      _hasMore = snapshot.docs.length == _pageSize; // Correctly set hasMore for pagination

      // Extract appointment data
      final newAppointments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {"id": doc.id, ...data};
      }).toList();

      // Batch fetch unique clinic IDs
      final clinicIds = newAppointments
          .map((a) => a["clinicUid"] as String?)
          .whereType<String>()
          .toSet()
          .where((id) => !_clinicCache.containsKey(id))
          .toList();

      await batchFetchClinics(clinicIds);

      _appointments.addAll(newAppointments);
    } catch (e) {
      debugPrint("Error loading appointments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches multiple clinics in parallel
  Future<void> batchFetchClinics(List<String> clinicIds) async {
    if (clinicIds.isEmpty) return;

    final futures = clinicIds
        .map(
          (id) => firestore
              .collection("clinics")
              .doc(id)
              .get(GetOptions(source: Source.cache)),
        )
        .toList();

    final snapshots = await Future.wait(futures);
    debugPrint("Batch fetched snapshots length: ${snapshots.length}");

    for (var i = 0; i < snapshots.length; i++) {
      final doc = snapshots[i];
      debugPrint("Processing doc ${clinicIds[i]}. RuntimeType: ${doc.runtimeType}. Exists: ${doc.exists}, Data: ${doc.data()}");
      if (doc.exists) {
        _clinicCache[clinicIds[i]] = doc.data()!;
      }
    }
  }

  /// Gets cached clinic data
  Map<String, dynamic>? getClinicData(String clinicId) =>
      _clinicCache[clinicId];

  /// Cancels appointment and removes from local list
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
        title: 'appointment cancelled'.tr(),
        body: 'the appointment got cancelled'.tr(),
      );
    }

    _appointments.removeWhere((a) => a["id"] == appointmentId);
    notifyListeners();
  }

  /// Resets and reloads appointments
  Future<void> refresh() async {
    _appointments.clear();
    _clinicCache.clear();
    _lastDocument = null;
    _hasMore = true;
    await loadAppointments();
  }
}

/// Main entry widget for user appointments list
class Appointmentslistview extends StatelessWidget {
  const Appointmentslistview({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppointmentsListView();
  }
}

class _AppointmentsListView extends StatelessWidget {
  const _AppointmentsListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAppointmentsProvider>(
      builder: (context, provider, _) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          return Center(child: Text("please_login".tr()));
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            itemCount:
                provider.appointments.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.appointments.length) {
                if (!provider.isLoading) {
                  provider.loadAppointments();
                }
                return const Center(child: CircularProgressIndicator());
              }

              final appointment = provider.appointments[index];
              final clinicUid = appointment["clinicUid"] as String? ?? "";
              final slot = appointment["date"] as Timestamp?;

              if (slot == null) return const SizedBox();

              final clinicData = provider.getClinicData(clinicUid);
              if (clinicData == null) {
                return ListTile(title: Text("Clinic data not found".tr()));
              }

              return _AppointmentCard(
                appointment: appointment,
                clinicData: clinicData,
                slot: slot,
              );
            },
          ),
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
                  IconButton(
                    onPressed: () async {
                      await launchUrl(
                        mode: LaunchMode.platformDefault,
                        Uri.parse("https://maps.app.goo.gl/rJq6C7XsEqevUUNg9"),
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