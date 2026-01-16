import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class UserFirestore {
  final user = FirebaseAuth.instance.currentUser;
  final collection = FirebaseFirestore.instance.collection("users");
  Future<void> addUser(String name, String phone, String city) async {
    final fcm = await FirebaseMessaging.instance.getToken();
    collection.doc(user?.uid).set({
      "name": name,
      "phone": phone,
      "uid": user?.uid,
      "city": city,
      "fcm": fcm,
    });
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
    });
  }

  Future<void> cancelAppointment(
    String appointmentId,
    String userUid,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cancel_appointment'.tr()),
        content: Text('are_you_sure_to_cancel_appointment'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('no'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'yes'.tr(),
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
          .collection('users')
          .doc(userUid)
          .collection('appointments')
          .doc(appointmentId)
          .get(GetOptions(source: Source.cache));

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
