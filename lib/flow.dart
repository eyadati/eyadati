import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/clinic/clinic_auth_selection.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/user_auth_selection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<Widget> decidePage(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    if (!context.mounted) return const SizedBox.shrink();
    return intro(context);
  } else {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // Offline
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      if (role == 'clinic') {
        return Clinichome();
      } else {
        return Userhome();
      }
    } else {
      // Online
      try {
        final isClinic = await _isClinicRole(currentUser.uid);
        if (isClinic) {
          return Clinichome();
        } else {
          return Userhome();
        }
      } catch (e) {
        debugPrint("Role check error: $e");
        if (!context.mounted) return const SizedBox.shrink();
        return intro(context);
      }
    }
  }
}

Future<bool> _isClinicRole(String uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('clinics')
      .doc(uid)
      .get(GetOptions(source: Source.serverAndCache));
  return doc.exists;
}

Widget intro(BuildContext context) {
  return Builder(
    builder: (BuildContext builderContext) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(builderContext).scaffoldBackgroundColor,
          actions: [
            IconButton(
              icon: Icon(Icons.language, size: 30),
              onPressed: () {
                showDialog(
                  context: builderContext,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("language".tr()),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                                                                  Locale selectedLocale = context.locale;                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                                                                                                                                                                                  // ignore: deprecated_member_use
                                                                                                                                                                                                  RadioListTile<Locale>(
                                                                                                                                                                                                    title: const Text('English'),
                                                                                                                                                                                                    value: const Locale('en'),
                                                                                                                                                                                                    // ignore: deprecated_member_use
                                                                                                                                                                                                    groupValue: selectedLocale,
                                                                                                                                                                                                    // ignore: deprecated_member_use
                                                                                                                                                                                                    onChanged: (Locale? value) async {
                                                                                                                                                                if (value != null) {
                                                                                                                                                                  setState(() {
                                                                                                                                                                    selectedLocale = value;
                                                                                                                                                                  });
                                                                                                                                                                  await context.setLocale(value);
                                                                                                                                                                  if (!context.mounted) return;
                                                                                                                                                                  Navigator.pop(context);
                                                                                                                                                                }
                                                                                                                                                              },
                                                                                                                                                            ),                              // ignore: deprecated_member_use
                              RadioListTile<Locale>(
                                title: const Text('Français'),
                                value: const Locale('fr'),
                                // ignore: deprecated_member_use
                                groupValue: selectedLocale,
                                // ignore: deprecated_member_use
                                onChanged: (Locale? value) async {
                                  if (value != null) {
                                    setState(() {
                                      selectedLocale = value;
                                    });
                                    await context.setLocale(value);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              // ignore: deprecated_member_use
                              RadioListTile<Locale>(
                                title: const Text('العربية'),
                                value: const Locale('ar'),
                                // ignore: deprecated_member_use
                                groupValue: selectedLocale,
                                // ignore: deprecated_member_use
                                onChanged: (Locale? value) async {
                                  if (value != null) {
                                    setState(() {
                                      selectedLocale = value;
                                    });
                                    await context.setLocale(value);
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('close'.tr()),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 150, // Adjust height as needed
                ),
                const SizedBox(height: 30),

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
                          builder: (_) => const ClinicAuthSelectionScreen(),
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
                          builder: (_) => const UserAuthSelectionScreen(),
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
                height:
                    MediaQuery.of(context).size.width *
                    0.6, // Increased from 0.4
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
