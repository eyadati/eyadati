import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:eyadati/NavBarUi/appointments_management.dart';
import 'package:eyadati/NavBarUi/clinic_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:eyadati/clinic/clinic_settings_page.dart';

class ClinicWebUI extends StatelessWidget {
  const ClinicWebUI({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<CliniNavBarProvider>();
    final clinicUid = navProvider.clinicUid;
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 120),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clinics')
              .doc(clinicUid)
              .collection('appointments')
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isRead'] == false || !data.containsKey('isRead');
              }).length;
            }

            return IconButton(
              onPressed: () {
                showMaterialModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: navProvider,
                    child: NotificationCenter(clinicUid: clinicUid),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.bell,
                    color: Theme.of(context).colorScheme.primary,
                    size: 25,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => showMaterialModalBottomSheet(
              context: context,
              builder: (context) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: const Clinicsettings(),
                );
              },
            ),
            icon: Icon(
              LucideIcons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Online Appointment (Home UI in phone version)
          Expanded(
            flex: 1,
            child: ClinicAppointments(clinicId: clinicUid, showAppBar: false),
          ),
          // Right Side: Management Side (Management UI in phone version)
          Expanded(
            flex: 1,
            child: ManagementScreen(clinicUid: clinicUid),
          ),
        ],
      ),
    );
  }
}
