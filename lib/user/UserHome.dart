import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/user/userSettingsPage.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ClinicSearchProvider(firestore: firestore, auth: auth),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text("Hello Oussama"),
          actions: [
            IconButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (Context) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: UserSettings(),
                  );
                },
              ),
              icon: Icon(Icons.settings),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => ClinicFilterBottomSheet.show(context),
        ),

        body: Center(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Expanded(child: Appointmentslistview()),
            ],
          ),
        ),
      ),
    );
  }
}



