import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicFirestore {
  final clinic = FirebaseAuth.instance.currentUser;
  final SupabaseClient client = Supabase.instance.client;
  final collection = FirebaseFirestore.instance.collection("clinics");
  Future<void> addClinic(
    String name, //1
    double? long,
    double? lat,
    String clinicName, //1
    int avatar, //5
    String city, //2
    List workingDays, //3
    String phone, //1
    String specialty, //4
    int sessionDuration, //4
    int openingAt, //3
    int closingAt, //3
    int breakStart, //3
    int breakTime, //3
    String adress, //2
  ) async {
    try {
      final fcm = await FirebaseMessaging.instance.getToken();

      await collection.doc(clinic?.uid).set({
        "uid": clinic!.uid,
        "email": clinic!.email,
        "name": name,
        "clinicName": clinicName,
        "FCM": fcm,
        "long": long,
        "lat": lat,
        "workingDays": workingDays,
        "freeTrial": 15,
        "phone": phone,
        "address": adress,
        "city": city,
        'avatar': avatar,
        "openingAt": openingAt,
        'closingAt': closingAt,
        'breakStart': breakStart,
        "break": breakTime,
        "specialty": specialty,
        'Duration': sessionDuration,
        'staff': 1.toInt(),
      });
    } catch (e) {
      debugPrint("Clinic creation error : $e");
      rethrow;
    }
  }

  Future<void> updateClinic(
    String name, //1
    String clinicName, //1
    String mapsLink, //2
    int avatar, //5
    String city, //2
    List workingDays, //3
    String phone, //1
    String specialty, //4
    String sessionDuration, //4
    int openingAt, //3
    int closingAt, //3
    int breakStart, //3
    int breakTime, //3
    String adress, //2
  ) async {
    try {
      final fcm = await FirebaseMessaging.instance.getToken();

      await collection.doc(clinic?.uid).update({
        "uid": clinic!.uid,
        "email": clinic!.email,
        "name": name,
        "clinicName": clinicName,
        "FCM": fcm,
        "mapsLink": mapsLink,
        "workingDays": workingDays,
        "freeTrial": 15,
        "phone": phone,
        "address": adress,
        "city": city,
        'avatar': avatar,
        "openingAt": openingAt,
        'closingAt': closingAt,
        'breakStart': breakStart,
        "break": breakTime,
        "specialty": specialty,
        'Duration': sessionDuration,
        'staff': 1.toInt(),
      });
    } catch (e) {
      debugPrint("Clinic creation error : $e");
      rethrow;
    }
  }

  Future<void> cancelAppointment(
    String appointmentId,
    String clinicId,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Appointment'.tr()),
        content: Text('Are you sure you want to cancel this appointment?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Yes'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get appointment to find user UID
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('appointments')
          .doc(appointmentId)
          .get(GetOptions(source: Source.cache));

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found'.tr());
      }

      final appointmentData = appointmentDoc.data()!;
      final userUid = appointmentData['userUid'] as String;

      // Delete from both collections
      final batch = FirebaseFirestore.instance.batch();

      batch.delete(
        FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
