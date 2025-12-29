import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingLogic extends ChangeNotifier {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> shopsByCity = [];
  List workingdays = [];
  //function for getting clinics by city,
  Future<List<Map<String, dynamic>>> cityClinics(String city) async {
    try {
      // Query clinics in the specified city
      final querySnapshot = await firestore
          .collection("clinics")
          .where("city", isEqualTo: city.toLowerCase())
          .get();

      // Convert documents to a list of Maps
      return querySnapshot.docs.map((doc) {
        return {"uid": doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print("Error fetching clinics: $e");
      return []; // Return empty list on error
    }
  }

  //function to generate slots
  Future<List<DateTime>> generateSlots(DateTime day, String clinicUid) async {
    final firestore = FirebaseFirestore.instance;
    List<DateTime> availableSlots = [];

    try {
      final clinicDoc = await firestore
          .collection("clinics")
          .doc(clinicUid)
          .get();
      final clinicData = clinicDoc.data()!;

      // Get times as minutes from midnight (e.g., 570 = 9:30 AM)
      final staffCount = int.tryParse(clinicData["staff"].toString()) ?? 1;
      final workingDays =
          (clinicData["workingDays"] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [];
      final openingMinutes =
          int.tryParse(clinicData["openingAt"].toString()) ?? 0;
      final closingMinutes =
          int.tryParse(clinicData["closingAt"].toString()) ?? 0;
      final breakStartMinutes = clinicData["breakStart"] != null
          ? int.tryParse(clinicData["breakStart"].toString())
          : null;
      final breakEndMinutes = clinicData["breakEnd"] != null
          ? int.tryParse(clinicData["breakEnd"].toString())
          : null;

      // Check if clinic is open this day
      if (!workingDays.contains(day.weekday)) return [];

      // Convert minutes to DateTime
      final openingTime = DateTime(
        day.year,
        day.month,
        day.day,
        0,
        openingMinutes,
      );
      final closingTime = DateTime(
        day.year,
        day.month,
        day.day,
        0,
        closingMinutes,
      );

      // Generate hourly slots starting at opening time
      DateTime slotStart = openingTime;

      while (slotStart.isBefore(closingTime)) {
        final slotEnd = slotStart.add(const Duration(hours: 1));

        // Skip if slot goes past closing time
        if (slotEnd.isAfter(closingTime)) break;

        // Check if slot overlaps with break time
        if (breakStartMinutes != null && breakEndMinutes != null) {
          final breakStart = DateTime(
            day.year,
            day.month,
            day.day,
            0,
            breakStartMinutes,
          );
          final breakEnd = DateTime(
            day.year,
            day.month,
            day.day,
            0,
            breakEndMinutes,
          );

          // Skip slot if it overlaps with break
          if (slotStart.isBefore(breakEnd) && slotEnd.isAfter(breakStart)) {
            slotStart = slotEnd;
            continue;
          }
        }

        // Check bookings for this slot
        final appointmentsQuery = await firestore
            .collection("clinics")
            .doc(clinicUid)
            .collection("appointments")
            .where("date", isGreaterThanOrEqualTo: slotStart)
            .where("date", isLessThan: slotEnd)
            .get();

        final currentBookings = appointmentsQuery.docs.length;

        if (currentBookings < staffCount) {
          availableSlots.add(slotStart);
        }

        slotStart = slotEnd; // Move to next slot
      }
      print(availableSlots);
      return availableSlots;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  //function to save the appointment data that has(user name,number,uid,day,hour,fcm and clinic uid,fcm)
  Future<void> bookAppointment(String clinicUid, DateTime slot) async {
  final user = auth.currentUser;
  if (user == null) throw Exception("User not logged in");

  // Generate ID once
  final appointmentId = "${clinicUid}_${user.uid}_${slot.millisecondsSinceEpoch}";

  // Fetch clinic and user data IN PARALLEL
  final clinicDocFuture = firestore.collection("clinics").doc(clinicUid).get();
  final userDocFuture = firestore.collection("users").doc(user.uid).get();
  
  final results = await Future.wait([clinicDocFuture, userDocFuture]);
  final clinicDoc = results[0];
  final userDoc = results[1];

  if (!clinicDoc.exists) throw Exception("Clinic not found");

  // ✅ SAFE PARSING: Handle strings, nulls, and type mismatches
  final staffCount = int.tryParse(clinicDoc.data()!["staff"].toString()) ?? 1;
  
  // ✅ SAFE PARSING: Handle null or empty count
  final countSnapshot = await firestore
      .collection('clinics')
      .doc(clinicUid)
      .collection("appointments")
      .where("date", isEqualTo: Timestamp.fromDate(slot))
      .count()
      .get();
  
  final currentBookings = countSnapshot.count ?? 0;

  if (currentBookings >= staffCount) {
    throw Exception("Slot is now full.");
  }

  // Create appointment data
  final data = {
    "clinicUid": clinicUid,
    "userUid": user.uid,
    "date": Timestamp.fromDate(slot),
    "userName": userDoc.data()?["name"] ?? "Unknown",
    "phone": userDoc.data()?["phone"] ?? "No phone",
    "createdAt": FieldValue.serverTimestamp(),
  };

  // Batch write to both locations
  final batch = firestore.batch();
  batch.set(
    firestore.collection('clinics').doc(clinicUid).collection("appointments").doc(appointmentId),
    data,
  );
  batch.set(
    firestore.collection('users').doc(user.uid).collection("appointments").doc(appointmentId),
    data,
  );

  await batch.commit();
}
}
