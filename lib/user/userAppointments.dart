import 'package:eyadati/NavBarUi/user_nav_bar_provider.dart';
import 'package:eyadati/user/userSettingsPage.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:eyadati/utils/connectivity_service.dart';
import 'package:eyadati/webUI/web_ui_helper.dart';
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
    return ChangeNotifierProvider<UserAppointmentsProvider>(
      create: (context) => UserAppointmentsProvider(
        connectivityService: Provider.of<ConnectivityService>(
          context,
          listen: false,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset('assets/logo.png', height: 120),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => showMaterialModalBottomSheet(
              context: context,
              builder: (context) => const UserSettings(),
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            IconButton(
              onPressed: () async {
                final userNavBarProvider = context.read<UserNavBarProvider>();
                await ClinicFilterBottomSheet.show(context, userNavBarProvider);
              },
              icon: const Icon(LucideIcons.plus, size: 30),
            ),
          ],
        ),
        body: const SafeArea(
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
