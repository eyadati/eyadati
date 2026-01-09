import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eyadati/utils/network_helper.dart';

/// Handles appointment booking logic with optimized Firestore operations
/// and thread-safe slot booking via transactions.
class BookingLogic extends ChangeNotifier {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  // In-memory cache for clinic data
  final Map<String, Map<String, dynamic>> _clinicCache = {};

  BookingLogic({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : auth = auth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches clinics by city with basic error handling
  Future<List<Map<String, dynamic>>> cityClinics(String city) async {
    try {
      final snapshot = await firestore
          .collection("clinics")
          .where("city", isEqualTo: city)
          .get(const GetOptions(source: Source.cache));

      return snapshot.docs
          .map((doc) => {"uid": doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint("Error fetching clinics: $e".tr());
      return [];
    }
  }

  /// Generates hourly slots for a specific day using a single Firestore query
  /// and in-memory processing for optimal performance
  Future<List<DateTime>> generateSlots(DateTime day, String clinicUid) async {
    try {
      // Fetch and cache clinic data
      final clinicData = await _getCachedClinicData(clinicUid);
      if (clinicData == null) return [];

      // SAFE PARSING HELPER
      int parseInt(dynamic value, int defaultValue) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      final staffCount = parseInt(clinicData["staff"], 1);

      final workingDays =
          (clinicData["workingDays"] as List?)
              ?.map((e) => parseInt(e, 0))
              .toList() ??
          [];

      final openingMinutes = parseInt(clinicData["openingAt"], 0);
      final closingMinutes = parseInt(clinicData["closingAt"], 0);
      final breakStartMinutes = parseInt(clinicData["breakStart"], 0);
      final breakEndMinutes = parseInt(clinicData["breakEnd"], 0);

      // Check if clinic is open
      if (!workingDays.contains(day.weekday)) return [];

      // Use UTC for consistent timezone handling
      final utcDay = DateTime(day.year, day.month, day.day);

      // Generate time boundaries
      final openingTime = utcDay.add(Duration(minutes: openingMinutes));
      final closingTime = utcDay.add(Duration(minutes: closingMinutes));
      final breakStart = utcDay.add(Duration(minutes: breakStartMinutes));
      final breakEnd = utcDay.add(Duration(minutes: breakEndMinutes));

      // Fetch ALL appointments for the day in a single query
      final dayAppointments = await firestore
          .collection("clinics")
          .doc(clinicUid)
          .collection("appointments")
          .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(utcDay))
          .where(
            "date",
            isLessThan: Timestamp.fromDate(utcDay.add(const Duration(days: 1))),
          )
          .get();

      // Build slot occupancy map in memory
      final bookedSlots = <DateTime, int>{};
      for (var doc in dayAppointments.docs) {
        final appointmentTime = (doc.data()["date"] as Timestamp).toDate();
        final slotHour = DateTime(
          appointmentTime.year,
          appointmentTime.month,
          appointmentTime.day,
          appointmentTime.hour,
        );
        bookedSlots[slotHour] = (bookedSlots[slotHour] ?? 0) + 1;
      }

      // Generate available slots
      final availableSlots = <DateTime>[];
      DateTime slotStart = openingTime;

      while (slotStart.isBefore(closingTime)) {
        final slotEnd = slotStart.add(const Duration(hours: 1));

        if (slotEnd.isAfter(closingTime)) break;

        // Skip if overlaps with break
        if (slotStart.isBefore(breakEnd) && slotEnd.isAfter(breakStart)) {
          slotStart = slotEnd;
          continue;
        }

        // Check bookings from in-memory map
        final currentBookings = bookedSlots[slotStart] ?? 0;
        if (currentBookings < staffCount) {
          availableSlots.add(slotStart);
        }

        slotStart = slotEnd;
      }

      return availableSlots;
    } catch (e) {
      debugPrint("Slot generation error: $e".tr());
      return [];
    }
  }

  /// Books an appointment atomically using Firestore transactions
  /// to prevent race conditions and overbooking
  Future<void> bookAppointment(String clinicUid, DateTime slot, BuildContext context) async {
    if (!await NetworkHelper.checkInternetConnectivity(context)) {
      throw Exception("no_internet_connection".tr());
    }
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in".tr());

    final utcSlot = slot;
    final appointmentId =
        "${clinicUid}_${user.uid}_${utcSlot.millisecondsSinceEpoch}";
    // Count existing bookings for this slot
    final slotQuery = await firestore
        .collection('clinics')
        .doc(clinicUid)
        .collection("appointments")
        .where("date", isEqualTo: Timestamp.fromDate(utcSlot))
        .count()
        .get();

    await firestore.runTransaction((transaction) async {
      // Fetch clinic data
      final clinicDoc = await transaction.get(
        firestore.collection("clinics").doc(clinicUid),
      );
      if (!clinicDoc.exists) throw Exception("Clinic not found".tr());

      final clinicData = clinicDoc.data()!;

      // SAFE PARSING HELPER
      int parseInt(dynamic value, int defaultValue) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      final staffCount = parseInt(clinicData["staff"], 1);

      final currentBookings = slotQuery.count ?? 0;
      if (currentBookings >= staffCount) {
        throw Exception("Slot is now full.".tr());
      }

      // Fetch user data
      final userDoc = await transaction.get(
        firestore.collection("users").doc(user.uid),
      );

      // Create appointment
      final appointmentData = {
        "clinicUid": clinicUid,
        "userUid": user.uid,
        "date": Timestamp.fromDate(utcSlot),
        "userName": userDoc.data()?["name"] ?? "Unknown",
        "phone": userDoc.data()?["phone"] ?? "No phone",
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Atomic write to both locations
      transaction.set(
        firestore
            .collection('clinics')
            .doc(clinicUid)
            .collection("appointments")
            .doc(appointmentId),
        appointmentData,
      );
      transaction.set(
        firestore
            .collection('users')
            .doc(user.uid)
            .collection("appointments")
            .doc(appointmentId),
        appointmentData,
      );
    });
  }

  /// Gets cached clinic data or fetches from Firestore if not available
  Future<Map<String, dynamic>?> _getCachedClinicData(String clinicUid) async {
    if (_clinicCache.containsKey(clinicUid)) {
      return _clinicCache[clinicUid];
    }

    final doc = await firestore.collection("clinics").doc(clinicUid).get();
    if (doc.exists) {
      _clinicCache[clinicUid] = doc.data()!;
    }
    return doc.data();
  }
}
