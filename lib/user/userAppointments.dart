import 'package:eyadati/clinic/clinicSettingsPage.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
          leading: GestureDetector(
            child: Icon(LucideIcons.settings),
            onTap: () => showMaterialModalBottomSheet(
              context: context,
              builder: (context) {
                return Clinicsettings();
              },
            ),
          ),
          actionsPadding: EdgeInsets.all(15),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            GestureDetector(
              onTap: () async {
                final booked = await ClinicFilterBottomSheet.show(context);
                if (booked == true && context.mounted) {
                  context.read<UserAppointmentsProvider>().refresh();
                }
              },
              child: Icon(LucideIcons.plus, size: 30),
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
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Expanded(child: Appointmentslistview()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
