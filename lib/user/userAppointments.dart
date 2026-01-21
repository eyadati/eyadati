import 'package:eyadati/user/userSettingsPage.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class UserAppointments extends StatefulWidget {
  const UserAppointments({super.key});

  @override
  State<UserAppointments> createState() => _UserAppointmentsState();
}

class _UserAppointmentsState extends State<UserAppointments> {
  @override
  Widget build(BuildContext context) {
    return Provider<UserAppointmentsProvider>(
      create: (_) => UserAppointmentsProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset('assets/logo.png', height: 40),
          centerTitle: true,
          leading: GestureDetector(
            child: Icon(LucideIcons.settings),
            onTap: () => showMaterialModalBottomSheet(
              context: context,
              builder: (context) {
                return UserSettings();
              },
            ),
          ),
          actionsPadding: EdgeInsets.all(15),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            GestureDetector(
              onTap: () async {
                await ClinicFilterBottomSheet.show(context);
                // The stream will automatically update, no need to do anything here
              },
              child: Icon(LucideIcons.plus, size: 30),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 50),
              Expanded(child: Appointmentslistview()),
            ],
          ),
        ),
      ),
    );
  }
}
