import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eyadati/utils/connectivity_service.dart'; // Import ConnectivityService
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class UserFirestore {
  final user = FirebaseAuth.instance.currentUser;
  final collection = FirebaseFirestore.instance.collection("users");
  final ConnectivityService? _connectivityService; // Add ConnectivityService

  UserFirestore({ConnectivityService? connectivityService})
    : _connectivityService = connectivityService; // Initialize it

  Future<DateTime?> getLastSyncTimestamp(String userUid) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString('last_sync_user_$userUid');
    if (timestampString != null) {
      return DateTime.parse(timestampString);
    }
    return null;
  }

  Future<void> addUser(String name, String phone, String city) async {
    final fcm = await FirebaseMessaging.instance.getToken();
    collection.doc(user?.uid).set({
      "name": name,
      "phone": phone,
      "uid": user?.uid,
      "city": city,
      "fcm": fcm,
    }, SetOptions(merge: true));
  }

  Future<void> addToFavorites(String clinicUid) async {
    final user = FirebaseAuth.instance;

    if (user.currentUser != null) {}
  }

  Future<void> updateUser(String name, String phone, String city) async {
    final fcm = await FirebaseMessaging.instance.getToken();
    collection.doc(user?.uid).set({
      "name": name,
      "phone": phone,
      "uid": user?.uid,
      "city": city,
      "fcm": fcm,
    }, SetOptions(merge: true));
  }

  Future<void> cancelAppointment(String appointmentId, String userUid) async {
    try {
      // Check network connectivity before forcing server read
      if (!(_connectivityService?.isOnline == true)) {
        throw Exception('no_internet_connection'.tr());
      }

      // Get appointment to find clinic UID - FORCE SERVER READ
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('appointments')
          .doc(appointmentId)
          .get(GetOptions(source: Source.server)); // Changed to Source.server

      if (!appointmentDoc.exists) {
        throw Exception('appointment_not_found'.tr());
      }

      final appointmentData = appointmentDoc.data()!;
      final clinicUid = appointmentData['clinicUid'] as String;

      // Delete from both collections
      final batch = FirebaseFirestore.instance.batch();

      batch.delete(
        FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicUid)
            .collection('appointments')
            .doc(appointmentId),
      );

      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .collection('appointments')
            .doc(appointmentId),
      );

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
