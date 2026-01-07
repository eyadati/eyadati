import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/clinic/clinicRegisterUi.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/userRegistrationUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Future<Widget> decidePage() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return intro();
  } else {
    try {
      // ✅ Cache the role check first
      final isClinic = await _isClinicRole(currentUser.uid);
      
      if (isClinic) return Clinichome();
      return Userhome();
    } catch (e) {
      debugPrint("Role check error: $e");
      return intro();
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

Widget intro() {
  return Builder(
    builder: (context) {
      // Make it fit small screens
      final containerSize = MediaQuery.of(context).size.width * 0.5;
      final containerHeight = MediaQuery.of(context).size.width * 0.3;
      return Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Better spacing
          children: [
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ClinicOnboardingPages(),
                ),
              ),
              child: Image.asset('assets/doctors2.png',height: containerHeight,width: containerSize,fit: BoxFit.fill,),
            ),
            GestureDetector(
              onTap: () => showMaterialModalBottomSheet(
             
                context: context,
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height*0.99,
                  child: UserOnboardingPages()),
              ),
              child: Image.asset('assets/doctors2.png',height: 300,width: containerSize,),
            ),
          ],
        ),
      );
    },
  );
}


