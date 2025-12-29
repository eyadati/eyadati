import 'package:eyadati/clinic/clinicSettingsPage.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Clinichome extends StatefulWidget {
  const Clinichome({super.key});

  @override
  State<Clinichome> createState() => _ClinichomeState();
}

class _ClinichomeState extends State<Clinichome> {
  final clinicUid = FirebaseAuth.instance.currentUser!.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("Hello Oussama!", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) {
                
                return SizedBox(
                  height: MediaQuery.of(context).size.height*0.9,
                  child: Clinicsettings());
                
              },
            ),
            icon: Icon(Icons.settings,color: Theme.of(context).colorScheme.inversePrimary,),
          ),
        ],
      ),
      body: Center(child: ClinicAppointments(clinicId: clinicUid,)),
    );
  }
}
