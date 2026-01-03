import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/SegmentedButtonsUi/AppoitmentsManagment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SegmentedButtonProvider extends ChangeNotifier {
  String _selected = "1";
  
  String get selected => _selected;
  
  void select(String value) {
    _selected = value;
    notifyListeners(); 
  }
}
class SegmentedButtons extends StatelessWidget {
  const SegmentedButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final clinicUid = FirebaseAuth.instance.currentUser!.uid;

    return ChangeNotifierProvider(
      create: (_) => SegmentedButtonProvider(),
      child: _SegmentedContent(clinicUid: clinicUid),
    );
  }
}

// Private widget that consumes the provider
class _SegmentedContent extends StatelessWidget {
  final String clinicUid;

  const _SegmentedContent({
    required this.clinicUid,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SegmentedButtonProvider>();
    
    final pages = [
      ClinicAppointments(clinicId: clinicUid),
       ManagementScreen(clinicUid: clinicUid,),
      const _DashboardScreen(),
    ];

    return Column(
      children: [
        SegmentedButton<String>(
          multiSelectionEnabled: false,
          emptySelectionAllowed: false,
          selected: {provider.selected},
          onSelectionChanged: (selected) {
            provider.select(selected.first); // Single line, no setState!
          },
          segments:  [
            ButtonSegment(value: "1", label: Text("Appointments".tr())),
            ButtonSegment(value: "2", label: Text("Management".tr())),
            ButtonSegment(value: "3", label: Text("Dashboard".tr())),
          ],
        ),
        Expanded(
          // ✅ IndexedStack is memory-safe: keeps widgets alive without recreating
          child: IndexedStack(
            index: int.parse(provider.selected) - 1,
            children: pages,
          ),
        ),
      ],
    );
  }
}



class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();
  @override
  Widget build(BuildContext context) =>  Center(child: Text('Coming soon'.tr()));
}