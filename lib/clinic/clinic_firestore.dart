import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/utils/network_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb_flutter;
import 'package:eyadati/utils/connectivity_service.dart'; // Import ConnectivityService
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class ClinicFirestore {
  final sb_flutter.SupabaseClient client = sb_flutter.Supabase.instance.client;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final CollectionReference<Map<String, dynamic>> collection;
  final User? clinic;
  final ConnectivityService? _connectivityService; // Add ConnectivityService

  ClinicFirestore({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    ConnectivityService? connectivityService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       collection = (firestore ?? FirebaseFirestore.instance).collection(
         "clinics",
       ),
       clinic = (firebaseAuth ?? FirebaseAuth.instance).currentUser,
       _connectivityService = connectivityService; // Initialize it
  Future<void> addClinic(
    String name,
    String mapsLink,
    String clinicName,
    String picUrl,
    String city,
    List workingDays,
    String phone,
    String specialty,
    int sessionDuration,
    int openingAt,
    int closingAt,
    int breakStart,
    int breakEnd,
    String adress,
    double? latitude,
    double? longitude,
  ) async {
    try {
      final fcm = await FirebaseMessaging.instance.getToken();

      GeoFirePoint? geoFirePoint;
      if (latitude != null && longitude != null) {
        geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
      }

      await collection.doc(clinic?.uid).set({
        "uid": clinic!.uid,
        "email": clinic!.email,
        "name": name,
        "clinicName": clinicName,
        "FCM": fcm,
        "mapsLink": mapsLink,
        "workingDays": workingDays,
        "subscriptionStartDate": DateTime.now(),
        "subscriptionEndDate": DateTime.now().add(Duration(days: 31)),
        "paused": false,
        "phone": phone,
        "address": adress,
        "city": city,
        'picUrl': picUrl,
        "openingAt": openingAt,
        'closingAt': closingAt,
        'breakStart': breakStart,
        "breakEnd": breakEnd,
        "specialty": specialty,
        'duration': sessionDuration,
        'staff': 1.toInt(),
        "position": geoFirePoint?.data, // Stores geohash and geopoint
      });
    } catch (e) {
      debugPrint("Clinic creation error : $e");
      rethrow;
    }
  }

  Future<void> updateClinic({
    required String name,
    required String clinicName,
    required String mapsLink,
    required String picUrl,
    required String city,
    required List workingDays,
    required String phone,
    required String specialty,
    required int sessionDuration,
    required int openingAt,
    required int closingAt,
    required int breakStart,
    required int breakEnd,
    required String address,
    required bool paused,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final fcm = await FirebaseMessaging.instance.getToken();

      GeoFirePoint? geoFirePoint;
      if (latitude != null && longitude != null) {
        geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));
      }

      final updateData = {
        "uid": clinic!.uid,
        "email": clinic!.email,
        "name": name,
        "clinicName": clinicName,
        "FCM": fcm,
        "mapsLink": mapsLink,
        "workingDays": workingDays,
        "phone": phone,
        "address": address,
        "city": city,
        'picUrl': picUrl,
        "openingAt": openingAt,
        'closingAt': closingAt,
        'breakStart': breakStart,
        "breakEnd": breakEnd,
        "specialty": specialty,
        'duration': sessionDuration,
        'staff': 1.toInt(),
        "paused": paused,
      };

      if (geoFirePoint != null) {
        updateData["position"] = geoFirePoint.data;
      }

      await collection.doc(clinic?.uid).update(updateData);
    } catch (e) {
      debugPrint("Clinic update error : $e");
      rethrow;
    }
  }

  Future<void> _saveLastSyncTimestamp(String clinicUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_sync_clinic_$clinicUid',
      DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastSyncTimestamp(String clinicUid) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampString = prefs.getString('last_sync_clinic_$clinicUid');
    if (timestampString != null) {
      return DateTime.parse(timestampString);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getClinicData(String clinicUid) async {
    try {
      // First, try to get data from cache
      DocumentSnapshot doc = await collection
          .doc(clinicUid)
          .get(GetOptions(source: Source.cache));

      // If data is not in cache AND device is online, try to get from server (and cache)
      if (!doc.exists && (_connectivityService?.isOnline == true)) {
        doc = await collection
            .doc(clinicUid)
            .get(GetOptions(source: Source.serverAndCache));
        if (doc.exists) {
          await _saveLastSyncTimestamp(
            clinicUid,
          ); // Save timestamp after successful server fetch
        }
      } else if (!doc.exists && (_connectivityService?.isOnline == false)) {
        // If offline and not in cache, we still don't have data, return null
        debugPrint("Clinic data not in cache and device is offline.");
        return null;
      }

      // If after all attempts, the document still doesn't exist, return null
      if (!doc.exists) {
        return null;
      }

      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint("Error getting clinic data: $e");
      return null;
    }
  }

  Future<void> updateClinicPauseStatus(String clinicUid, bool isPaused) async {
    try {
      await collection.doc(clinicUid).update({"paused": isPaused});
    } catch (e) {
      debugPrint("Error updating clinic pause status: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getAvailableClinics() {
    return collection
        .where('paused', isEqualTo: false)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          // Implement checks for metadata changes
          if (snapshot.metadata.isFromCache) {
            debugPrint("getAvailableClinics: Data from cache.");
          }
          if (snapshot.metadata.hasPendingWrites) {
            debugPrint(
              "getAvailableClinics: Data has pending writes (local changes).",
            );
          }
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  Future<void> deleteClinicAccount(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('no_user_logged_in'.tr());
      }

      // Reauthenticate user
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Best-effort client-side cleanup for orphaned data
      // Note: This is not as reliable as Cloud Functions.
      try {
        final appointmentsSnapshot = await collection
            .doc(user.uid)
            .collection('appointments')
            .get();

        final batch = _firestore.batch();
        for (var doc in appointmentsSnapshot.docs) {
          // Delete from clinic subcollection
          batch.delete(doc.reference);

          // Attempt to delete from user subcollection (requires knowing userUid)
          final data = doc.data();
          if (data['userUid'] != null) {
            batch.delete(
              _firestore
                  .collection('users')
                  .doc(data['userUid'])
                  .collection('appointments')
                  .doc(doc.id),
            );
          }
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Error performing client-side cleanup: $e");
        // Continue with account deletion even if cleanup fails partially
      }

      // 1. Delete clinic document from Firestore
      await collection.doc(user.uid).delete();

      // 2. Delete the Firebase Authentication user
      await user.delete();

      // Sign out after deletion
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelAppointment(String appointmentId, String clinicId) async {
    try {
      // Check network connectivity before forcing server read
      bool isOnline =
          _connectivityService?.isOnline ??
          await NetworkHelper.checkInternetConnectivity();
      if (!isOnline) {
        throw Exception('no_internet_connection'.tr());
      }

      // Get appointment to find user UID - FORCE SERVER READ
      final appointmentDoc = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('appointments')
          .doc(appointmentId)
          .get(GetOptions(source: Source.server));

      if (!appointmentDoc.exists) {
        throw Exception('appointment_not_found'.tr());
      }

      final appointmentData = appointmentDoc.data()!;
      final userUid = appointmentData['userUid'] as String;

      // Delete from both collections
      final batch = _firestore.batch();

      batch.delete(
        _firestore
            .collection('clinics')
            .doc(clinicId)
            .collection('appointments')
            .doc(appointmentId),
      );

      batch.delete(
        _firestore
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
