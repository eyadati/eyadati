import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/chargili/paiment.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart'; // flutter pub add flutter_floating_bottom_bar
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/NavBarUi/AppoitmentsManagment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eyadati/utils/connectivity_service.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deferred_indexed_stack/deferred_indexed_stack.dart'; // flutter pub add deferred_indexed_stack
import 'package:lucide_icons/lucide_icons.dart';

import 'package:eyadati/utils/appointment_simulator.dart';
import 'dart:async';

class CliniNavBarProvider extends ChangeNotifier {
  final String clinicUid;
  String _selected = "1";
  String get selected => _selected;
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  StreamSubscription? _notifSubscription;
  StreamSubscription? _clinicSubscription;

  Map<String, dynamic>? _clinicData;
  bool _isLoadingClinic = true;
  bool get isLoadingClinic => _isLoadingClinic;
  Map<String, dynamic>? get clinicData => _clinicData;

  CliniNavBarProvider(this.clinicUid) {
    // _startSimulation(clinicUid); // Disabled for release
    _listenForNotifications(clinicUid);
    _listenToClinicDoc();
  }

  void _listenToClinicDoc() {
    _clinicSubscription = FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicUid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            _clinicData = snapshot.data() as Map<String, dynamic>;
          }
          _isLoadingClinic = false;
          notifyListeners();
        });
  }



  void _listenForNotifications(String clinicUid) {
    _notifSubscription = FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicUid)
        .collection('appointments')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          _unreadCount = snapshot.docs.length;
          notifyListeners();
        });
  }

  void select(String value) {
    _selected = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _clinicSubscription?.cancel();
    AppointmentSimulator.stopSimulation();
    super.dispose();
  }
}

// ✅ Using StatefulWidget to persist provider instance
class FloatingBottomNavBar extends StatefulWidget {
  const FloatingBottomNavBar({super.key});
  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  CliniNavBarProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider == null) {
      final clinicUid = FirebaseAuth.instance.currentUser!.uid;
      _provider = CliniNavBarProvider(clinicUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicUid = FirebaseAuth.instance.currentUser!.uid;

    return ChangeNotifierProvider.value(
      value: _provider!,
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
    final connectivity = context.watch<ConnectivityService>();
    final selectedIndex = int.parse(provider.selected) - 1;

    if (provider.isLoadingClinic) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.clinicData == null) {
      return Scaffold(body: Center(child: Text('clinic_data_not_found'.tr())));
    }

    final clinicData = provider.clinicData!;
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
        return Column(
          children: [
            if (!connectivity.isOnline) const _OfflineBanner(),
            Expanded(
              child: DeferredIndexedStack(
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
                ],
              ),
            ),
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
            _buildNavItem(context, LucideIcons.calendar, "managment".tr(), "2"),
          ],
        ),
      ),
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
                        return const SubscribeScreen();
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

class NotificationCenter extends StatelessWidget {
  final String clinicUid;
  const NotificationCenter({super.key, required this.clinicUid});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'notifications'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _markAllAsRead(),
                      child: Text('mark_all_read'.tr()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('clinics')
                      .doc(clinicUid)
                      .collection('appointments')
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(child: Text('no_notifications'.tr()));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isRead = data['isRead'] ?? true;
                        final date = (data['date'] as Timestamp).toDate();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead
                                ? Colors.grey.shade200
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            child: Icon(
                              LucideIcons.calendar,
                              color: isRead
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            data['userName'] ?? 'Unknown Patient',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${'appointment'.tr()}: ${DateFormat.yMMMd(context.locale.toString()).add_Hm().format(date)}',
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () => _markAsRead(docs[index].id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicUid)
        .collection('appointments')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicUid)
        .collection('appointments')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.error,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'you_are_currently_offline'.tr(),
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onError),
      ),
    );
  }
}
