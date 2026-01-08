import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Appointments/booking_logic.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagementProvider extends ChangeNotifier {
  final String clinicUid;
  final FirebaseFirestore firestore;

  // In-memory manual appointments: key is "yyyy-MM-ddTHH:mm" in UTC
  final Map<String, int> _manualAppointments = {};

  // Real appointment counts from database
  final Map<String, int> _realAppointmentsCount = {};

  // Clinic configuration cache
  Map<String, dynamic>? _clinicData;

  // Slots for visible days only (excludes closed days)
  final List<List<DateTime>> _weekSlots = [];

  // The actual day DateTime objects for each page (in UTC)
  final List<DateTime> _visibleDays = [];

  bool _isLoading = true;
  String? _errorMessage;

  // SharedPreferences prefix for manual appointments (scoped per clinic)
  static const String _prefsPrefix = "manual_slot_";

  ManagementProvider({required this.clinicUid, FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance {
    _initializeData();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<List<DateTime>> get weekSlots => _weekSlots;
  List<DateTime> get visibleDays => _visibleDays;

  // Utility to parse integers safely
  int _parseInt(dynamic value, int defaultValue) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Checks if the clinic is open on a specific day (using UTC)
  bool isWorkingDay(DateTime day) {
    if (day.isUtc == false) day = day;
    if (_clinicData == null) return false;

    final workingDays =
        (_clinicData!["workingDays"] as List?)
            ?.map((e) => _parseInt(e, 0))
            .toList() ??
        [];

    return workingDays.contains(day.weekday);
  }

  Future<void> _initializeData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _fetchClinicData();
      await _loadManualAppointments(); // Load saved manual appointments first
      await _generateWeekSlots();
      if (_visibleDays.isNotEmpty) {
        await _fetchAllAppointments();
      }
    } catch (e) {
      debugPrint("ManagementProvider initialization error: $e");
      _errorMessage = "Failed to load appointment data. Pull to retry.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchClinicData() async {
    final doc = await firestore.collection("clinics").doc(clinicUid).get();
    if (doc.exists) {
      _clinicData = doc.data();
    } else {
      throw Exception("Clinic not found");
    }
  }

  Future<void> _loadManualAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefsPrefix));

      _manualAppointments.clear();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (String key in keys) {
        // Key format: "manual_slot_{clinicUid}_{slotKey}"
        final parts = key.split('_');
        if (parts.length >= 4 && parts[2] == clinicUid) {
          final slotKey = parts.sublist(3).join('_'); // Reconstruct slot key

          // Parse the date from slot key: "yyyy-MM-ddTHH:mm"
          final dateParts = slotKey.split('T');
          if (dateParts.length == 2) {
            final dateComponents = dateParts[0].split('-');
            if (dateComponents.length == 3) {
              final year = int.parse(dateComponents[0]);
              final month = int.parse(dateComponents[1]);
              final day = int.parse(dateComponents[2]);
              final slotDate = DateTime(year, month, day);

              // Only load if not in the past
              if (!slotDate.isBefore(today)) {
                final count = prefs.getInt(key) ?? 0;
                if (count > 0) {
                  _manualAppointments[slotKey] = count;
                }
              } else {
                // Clean up old entries automatically
                await prefs.remove(key);
              }
            }
          }
        }
      }
      debugPrint(
        "Loaded ${_manualAppointments.length} manual appointments for clinic $clinicUid",
      );
    } catch (e) {
      debugPrint("Error loading manual appointments: $e");
      // Continue without manual appointments if loading fails
    }
  }

  Future<void> _saveManualAppointment(String slotKey, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsKey = "$_prefsPrefix${clinicUid}_$slotKey";

      if (count > 0) {
        await prefs.setInt(prefsKey, count);
      } else {
        await prefs.remove(prefsKey);
      }
    } catch (e) {
      debugPrint("Error saving manual appointment: $e");
      // Fail silently - data will be in memory but not persisted
    }
  }

  Future<void> _generateWeekSlots() async {
    if (_clinicData == null) return;

    final bookingLogic = BookingLogic(firestore: firestore);
    final now = DateTime.now();
    _weekSlots.clear();
    _visibleDays.clear();

    // Check next 7 days, but only add working days
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));

      // Skip non-working days entirely
      if (!isWorkingDay(day)) {
        debugPrint("Skipping non-working day: $day");
        continue;
      }

      final slots = await bookingLogic.generateSlots(day, clinicUid);
      // Only show days that have at least one slot
      if (slots.isNotEmpty) {
        _weekSlots.add(slots);
        _visibleDays.add(day);
        debugPrint("Added day with ${slots.length} slots: $day");
      }
    }
  }

  Future<void> _fetchAllAppointments() async {
    if (_clinicData == null || _visibleDays.isEmpty) return;

    // Determine date range from first to last visible day
    final startDate = _visibleDays.first;
    final endDate = _visibleDays.last.add(const Duration(days: 1));

    final snapshot = await firestore
        .collection("clinics")
        .doc(clinicUid)
        .collection("appointments")
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where("date", isLessThan: Timestamp.fromDate(endDate))
        .get();

    _realAppointmentsCount.clear();
    for (var doc in snapshot.docs) {
      final appointmentTime = (doc.data()["date"] as Timestamp).toDate();
      final slotKey = _getSlotKey(appointmentTime);
      _realAppointmentsCount[slotKey] =
          (_realAppointmentsCount[slotKey] ?? 0) + 1;
    }
  }

  String _getSlotKey(DateTime slotTime) {
    // Ensure UTC consistency
    final utcTime = slotTime.isUtc ? slotTime : slotTime;
    return "${utcTime.year}-${_twoDigits(utcTime.month)}-${_twoDigits(utcTime.day)}T${_twoDigits(utcTime.hour)}:00";
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  int getRealAppointmentsForSlot(DateTime slot) {
    return _realAppointmentsCount[_getSlotKey(slot)] ?? 0;
  }

  int getManualAppointmentsForSlot(DateTime slot) {
    return _manualAppointments[_getSlotKey(slot)] ?? 0;
  }

  int getTotalAppointmentsForSlot(DateTime slot) {
    return getRealAppointmentsForSlot(slot) +
        getManualAppointmentsForSlot(slot);
  }

  int getStaffCount() {
    if (_clinicData == null) return 1;
    return _parseInt(_clinicData!["staff"], 1);
  }

  bool isSlotFull(DateTime slot) {
    return getTotalAppointmentsForSlot(slot) >= getStaffCount();
  }

  bool canDecreaseManual(DateTime slot) =>
      getManualAppointmentsForSlot(slot) > 0;
  bool canIncreaseManual(DateTime slot) => !isSlotFull(slot);

  void increaseManualAppointments(DateTime slot) {
    if (!canIncreaseManual(slot)) return;
    final key = _getSlotKey(slot);
    _manualAppointments[key] = (_manualAppointments[key] ?? 0) + 1;
    _saveManualAppointment(
      key,
      _manualAppointments[key]!,
    ); // Persist immediately
    notifyListeners();
  }

  void decreaseManualAppointments(DateTime slot) {
    if (!canDecreaseManual(slot)) return;
    final key = _getSlotKey(slot);
    _manualAppointments[key] = (_manualAppointments[key] ?? 0) - 1;
    if (_manualAppointments[key]! <= 0) {
      _manualAppointments.remove(key);
      _saveManualAppointment(key, 0); // Remove from persistence
    } else {
      _saveManualAppointment(
        key,
        _manualAppointments[key]!,
      ); // Update persistence
    }
    notifyListeners();
  }

  String getSlotDisplayText(DateTime slot) {
    final localSlot = slot.toLocal(); // Display in local time for user
    final endTime = localSlot.add(const Duration(hours: 1));
    return "${_twoDigits(localSlot.hour)}:${_twoDigits(localSlot.minute)} - ${_twoDigits(endTime.hour)}:${_twoDigits(endTime.minute)}";
  }

  Future<void> refreshData() async {
    await _initializeData();
  }
}

// ==================== UI SCREEN ====================

/// Main management screen with PageView for days and ListView for slots
class ManagementScreen extends StatelessWidget {
  final String clinicUid;

  const ManagementScreen({super.key, required this.clinicUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManagementProvider(clinicUid: clinicUid),
      child: Scaffold(
        body: SafeArea(
          child: Consumer<ManagementProvider>(
            builder: (_, provider, __) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null) {
                return _buildErrorState(context, provider);
              }

              if (provider.visibleDays.isEmpty) {
                return _buildNoWorkingDaysState();
              }

              return PageView.builder(
                itemCount: provider.visibleDays.length,
                itemBuilder: (context, dayIndex) {
                  final day = provider.visibleDays[dayIndex];
                  final slots = provider.weekSlots[dayIndex];

                  return Column(
                    children: [
                      // Day header
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Theme.of(context).colorScheme.primary,
                        child: Center(
                          child: Text(
                            DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(day.toLocal()),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: slots.isEmpty
                            ? _buildEmptyState(day, provider)
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: slots.length,
                                itemBuilder: (context, slotIndex) {
                                  return _buildSlotCard(
                                    context,
                                    provider,
                                    slots[slotIndex],
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ManagementProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.refreshData,
              icon: const Icon(Icons.refresh),
              label: Text("Retry".tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkingDaysState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "no_working_days_found".tr(),
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DateTime day, ManagementProvider provider) {
    final isWorkingDay = provider.isWorkingDay(day);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWorkingDay
                ? Icons.event_busy
                : Icons.store_mall_directory_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
                      Text(
                        isWorkingDay ? "no_slots_available_today".tr() : "clinic_is_closed".tr(),            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(
    BuildContext context,
    ManagementProvider provider,
    DateTime slot,
  ) {
    final manualCount = provider.getManualAppointmentsForSlot(slot);
    final totalCount = provider.getTotalAppointmentsForSlot(slot);
    final staffCount = provider.getStaffCount();
    final isFull = provider.isSlotFull(slot);
    final canDecrease = provider.canDecreaseManual(slot);
    final canIncrease = provider.canIncreaseManual(slot);
    final displayText = provider.getSlotDisplayText(slot);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFull
            ? BorderSide(color: Colors.red.shade200, width: 2)
            : BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time slot header
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: isFull ? Colors.red : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  displayText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFull ? Colors.red : null,
                  ),
                ),
                const Spacer(),
                if (isFull) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "full".tr(),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Appointments info and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Appointment counts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Appointments".tr(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$totalCount / $staffCount",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFull ? Colors.red : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (manualCount > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              "Manual: +$manualCount",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Counter buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCounterButton(
                      Icons.remove,
                      Colors.red,
                      canDecrease,
                      () => provider.decreaseManualAppointments(slot),
                    ),
                    const SizedBox(width: 8),
                    _buildCounterButton(
                      Icons.add,
                      Colors.green,
                      canIncrease,
                      () => provider.increaseManualAppointments(slot),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton(
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback? onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onTap,
        color: enabled ? color : Colors.grey,
        disabledColor: Colors.grey.shade300,
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
