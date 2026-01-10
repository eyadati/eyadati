import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/clinic/clinicRegisterUi_widgets.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/userRegistrationUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<Widget> decidePage(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    if (!context.mounted) return const SizedBox.shrink();
    return intro(context);
  } else {
    try {
      // ✅ Cache the role check first
      final isClinic = await _isClinicRole(currentUser.uid);

      if (isClinic) return Clinichome();
      return Userhome();
    } catch (e) {
      debugPrint("Role check error: $e");
      if (!context.mounted) return const SizedBox.shrink();
      return intro(context);
    }
  }
}

Future<bool> _isClinicRole(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('clinics')
      .doc(uid)
      .get(GetOptions(source: Source.cache));
  return doc.exists;
}

Widget intro(BuildContext context) {
  return Builder(
    builder: (BuildContext builderContext) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'welcome_to_eyadati'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'are_you_a_clinic_or_a_user'.tr(),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildChoiceCard(
                      context: builderContext, // Use builderContext
                      imagePath: 'assets/doctors.png',
                      label: 'im_a_clinic'.tr(),
                      onTap: () => Navigator.pushAndRemoveUntil(
                        builderContext, // Use builderContext
                        MaterialPageRoute(
                          builder: (_) => const ClinicOnboardingPages(),
                        ),
                        (route) => false,
                      ),
                    ),
                    _buildChoiceCard(
                      context: builderContext, // Use builderContext
                      imagePath: 'assets/family.png',
                      label: 'im_a_user'.tr(),
                      onTap: () => Navigator.pushReplacement(
                        builderContext, // Use builderContext
                        MaterialPageRoute(
                          builder: (_) => const UserOnboardingPages(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildChoiceCard({
  required BuildContext context,
  required String imagePath,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                imagePath,
                height: MediaQuery.of(context).size.width * 0.4,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
