import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class UserAppointments extends StatefulWidget {
  const UserAppointments({super.key});

  @override
  State<UserAppointments> createState() => _UserAppointmentsState();
}

class _UserAppointmentsState extends State<UserAppointments> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              UserAppointmentsProvider()..loadAppointments(), // Load on start
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(GetOptions(source: Source.cache)),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return Text("hello".tr());
                  }
                  if (snapshot.connectionState == ConnectionState.done) {
                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return Text('hello ${data['name']}'.tr());
                  }
                  return Text("hello".tr());
                },
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final booked = await ClinicFilterBottomSheet.show(context);
                if (booked == true && context.mounted) {
                  context.read<UserAppointmentsProvider>().refresh();
                }
              },
              icon: Icon(LucideIcons.plus),
            ),
          ],
        ),
        body: Consumer<UserAppointmentsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.appointments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.appointments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.calendarX,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "no_appointments".tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: Appointmentslistview(),
            );
          },
        ),
      ),
    );
  }
}
