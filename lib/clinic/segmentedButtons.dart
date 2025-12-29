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
    
    // Pages created fresh each build, but IndexedStack keeps them alive efficiently
    final pages = [
      ClinicAppointments(clinicId: clinicUid),
      const _ManagementScreen(),
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
          segments: const [
            ButtonSegment(value: "1", label: Text("Appointments")),
            ButtonSegment(value: "2", label: Text("Management")),
            ButtonSegment(value: "3", label: Text("Dashboard")),
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

// Placeholder screens (make them const for zero rebuild cost)
class _ManagementScreen extends StatelessWidget {
  const _ManagementScreen();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Management'));
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Dashboard'));
}