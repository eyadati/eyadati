import 'package:eyadati/clinic/clinicSettingsPage.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart'; // flutter pub add flutter_floating_bottom_bar
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/NavBarUi/AppoitmentsManagment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deferred_indexed_stack/deferred_indexed_stack.dart'; // flutter pub add deferred_indexed_stack

class CliniNavBarProvider extends ChangeNotifier {
  String _selected = "2";
  String get selected => _selected;
  void select(String value) {
    _selected = value;
    notifyListeners();
  }
}

// ✅ Using StatefulWidget to persist provider instance
class FloatingBottomNavBar extends StatefulWidget {
  const FloatingBottomNavBar({super.key});
  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  final _provider = CliniNavBarProvider(); // Created once, lives with widget

  @override
  Widget build(BuildContext context) {
    final clinicUid = FirebaseAuth.instance.currentUser!.uid;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: _BottomNavContent(clinicUid: clinicUid),
    );
  }
}

class _BottomNavContent extends StatelessWidget {
  final String clinicUid;
  const _BottomNavContent({required this.clinicUid});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CliniNavBarProvider>();
    final selectedIndex = int.parse(provider.selected) - 1;

    return BottomBar(
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      showIcon: false, // Hide center icon for cleaner nav bar
      width: MediaQuery.of(context).size.width * 0.9, // Floating effect
      barColor: Colors.white,
      barAlignment: Alignment.bottomCenter,

      // Main content area with lazy loading
      body: (context, controller) {
        // 'controller' is for scroll-to-hide functionality
        // Not used here since IndexedStack handles page switching
        return DeferredIndexedStack(
          index: selectedIndex,
          children: [
            DeferredTab(child: Clinicsettings()),
            DeferredTab(child: ClinicAppointments(clinicId: clinicUid)),
            DeferredTab(child: ManagementScreen(clinicUid: clinicUid)),
          ],
        );
      },

      // Floating navigation bar items
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.settings, "settings".tr(), "1"),
            _buildNavItem(context, Icons.home, "home".tr(), "2"),
            _buildNavItem(context, Icons.calendar_month, "managment".tr(), "3"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final provider = context.watch<CliniNavBarProvider>();
    final isSelected = provider.selected == value;
    final color = isSelected ? Colors.blue : Colors.black;

    return InkWell(
      onTap: () => provider.select(value),
      customBorder: const CircleBorder(), // Circular ripple effect
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Larger tap area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label.tr(), style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
