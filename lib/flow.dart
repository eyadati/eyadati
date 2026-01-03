import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/clinic/clinicRegisterUi.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/userRegistrationUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<Widget> decidePage() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return intro();
  } else {
    try {
      // Check both collections at once (faster)
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .get(),
        FirebaseFirestore.instance
            .collection("clinics")
            .doc(currentUser.uid)
            .get(),
      ]);

      final checkUser = results[0];
      final checkClinics = results[1];

      if (checkUser.exists) return Userhome();
      if (checkClinics.exists) return Clinichome();
    } catch (e) {
      // If Firestore fails, just show intro
      return intro();
    }
  }
  return intro();
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
              onTap: () => showModalBottomSheet(
                isScrollControlled: true,
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


