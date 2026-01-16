import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/chargili/paiment.dart';
import 'package:eyadati/clinic/clinicSettingsPage.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart'; // flutter pub add flutter_floating_bottom_bar
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/NavBarUi/AppoitmentsManagment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deferred_indexed_stack/deferred_indexed_stack.dart'; // flutter pub add deferred_indexed_stack
import 'package:lucide_icons/lucide_icons.dart';

class CliniNavBarProvider extends ChangeNotifier {
  String _selected = "1";
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('clinic_data_not_found'.tr()));
        }

        final clinicData = snapshot.data!.data() as Map<String, dynamic>;
        final bool isPaused = clinicData['paused'] ?? false;
        final Timestamp? subscriptionEndDateTimestamp =
            clinicData['subscriptionEndDate'] as Timestamp?;

        final bool isSubscriptionEnded =
            subscriptionEndDateTimestamp != null &&
            subscriptionEndDateTimestamp.toDate().isBefore(DateTime.now());

        if (isPaused) {
          return _buildOverlayMessage(
            context,
            'clinic_paused_title'.tr(),
            'clinic_paused_message'.tr(),
            LucideIcons.pauseCircle,
          );
        }

        if (isSubscriptionEnded) {
          return _buildOverlayMessage(
            context,
            'subscription_ended_title'.tr(),
            'subscription_ended_message'.tr(),
            LucideIcons.alertTriangle,
          );
        }

        return BottomBar(
          borderRadius: BorderRadius.circular(25),
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate,
          showIcon: false, // Hide center icon for cleaner nav bar
          width: MediaQuery.of(context).size.width * 0.9, // Floating effect
          barColor: Theme.of(context).cardColor,
          barAlignment: Alignment.bottomCenter,

          // Main content area with lazy loading
          body: (context, controller) {
            // 'controller' is for scroll-to-hide functionality
            // Not used here since IndexedStack handles page switching
            return DeferredIndexedStack(
              index: selectedIndex,
              children: [
                DeferredTab(
                  id: "1",
                  child: ClinicAppointments(clinicId: clinicUid),
                ),
                DeferredTab(
                  id: "2",
                  child: ManagementScreen(clinicUid: clinicUid),
                ),
                DeferredTab(id: "3", child: Clinicsettings()),
              ],
            );
          },

          // Floating navigation bar items
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, LucideIcons.home, "home".tr(), "1"),
                _buildNavItem(
                  context,
                  LucideIcons.calendar,
                  "managment".tr(),
                  "2",
                ),
                _buildNavItem(
                  context,
                  LucideIcons.settings,
                  "settings".tr(),
                  "3",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayMessage(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return SubscribeScreen();
                      },
                    );
                  },
                  icon: const Icon(LucideIcons.refreshCcw),
                  label: Text('take_action'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
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
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

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
