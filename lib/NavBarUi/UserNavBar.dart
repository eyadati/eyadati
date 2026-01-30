import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:eyadati/user/userAppointments.dart';

import 'package:eyadati/utils/connectivity_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eyadati/user/userQrScannerPage.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart'; // flutter pub add flutter_floating_bottom_bar
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deferred_indexed_stack/deferred_indexed_stack.dart'; // flutter pub add deferred_indexed_stack
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:marquee/marquee.dart';
import 'package:eyadati/utils/skeletons.dart';

class UserNavBarProvider extends ChangeNotifier {
  String _selected = "1";
  String get selected => _selected;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  late Stream<List<Map<String, dynamic>>> favoriteClinicsStream;

  UserNavBarProvider() {
    _initFavoriteClinicsStream();
  }

  void _initFavoriteClinicsStream() {
    final user = auth.currentUser;
    if (user == null) {
      favoriteClinicsStream = Stream.value([]);
      return;
    }

    favoriteClinicsStream = firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
          final clinics = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'clinicName': data['clinicName'],
              'address': data['address'],
              'specialty': data['specialty'],
              'picUrl': data['picUrl'],
              'favoritedTimestamp': data['timestamp'],
            };
          }).toList();

          // Sort by favorited timestamp
          clinics.sort((a, b) {
            final Timestamp? timestampA = a['favoritedTimestamp'];
            final Timestamp? timestampB = b['favoritedTimestamp'];

            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) return 1;
            if (timestampB == null) return -1;

            return timestampB.compareTo(timestampA); // Newest first
          });

          return clinics;
        });
  }

  Future<void> toggleFavorite(String clinicUid) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final favoriteDoc = firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(clinicUid);

    final docSnapshot = await favoriteDoc.get();

    if (docSnapshot.exists) {
      await favoriteDoc.delete();
    } else {
      final clinicDoc = await firestore
          .collection('clinics')
          .doc(clinicUid)
          .get();
      if (clinicDoc.exists) {
        final clinicData = clinicDoc.data()!;
        await favoriteDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'clinicName': clinicData['clinicName'],
          'address': clinicData['address'],
          'specialty': clinicData['specialty'],
          'picUrl': clinicData['picUrl'],
        });
      }
    }
  }

  void select(String value) {
    _selected = value;
    notifyListeners();
  }
}

// ✅ Using StatefulWidget to persist provider instance
class UserFloatingBottomNavBar extends StatefulWidget {
  const UserFloatingBottomNavBar({super.key});
  @override
  State<UserFloatingBottomNavBar> createState() =>
      _UserFloatingBottomNavBarState();
}

class _UserFloatingBottomNavBarState extends State<UserFloatingBottomNavBar> {
  final _provider = UserNavBarProvider(); // Created once, lives with widget

  @override
  Widget build(BuildContext context) {
    // Removed the unused clinicUid variable and its initialization
    return ChangeNotifierProvider.value(
      value: _provider,
      child: _BottomNavContent(),
    );
  }
}

class _BottomNavContent extends StatelessWidget {
  // Removed the unused clinicUid parameter
  const _BottomNavContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserNavBarProvider>();
    final connectivity = context.watch<ConnectivityService>();
    final selectedIndex = int.parse(provider.selected) - 1;

    return BottomBar(
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      showIcon: false, // Hide center icon for cleaner nav bar
      width: MediaQuery.of(context).size.width * 0.9, // Floating effect
      barColor: Theme.of(context).colorScheme.onSecondary,
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
                  DeferredTab(id: "1", child: UserAppointments()),
                  DeferredTab(id: "2", child: FavoritScreen()),
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
            _buildNavItem(context, LucideIcons.heart, "favorites".tr(), "2"),
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
    final provider = context.watch<UserNavBarProvider>();
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
            LucideAnimatedIcon(
              icon: value == "1" ? home : heart,
              onTap: () => provider.select(value),
              trigger: isSelected ? AnimationTrigger.loop : AnimationTrigger.onTap,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(label.tr(), style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
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

class FavoritScreen extends StatelessWidget {
  const FavoritScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserNavBarProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 120),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.qrCode),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<UserNavBarProvider>(),
                    child: const UserQrScannerPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: provider.favoriteClinicsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => const ClinicCardSkeleton(),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('something_went_wrong'.tr()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.heart,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_favorite_clinics'.tr(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'add_clinics_to_see_them_here'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final favClinics = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: favClinics.length + 1, // Add 1 for the SizedBox
              itemBuilder: (context, index) {
                if (index == favClinics.length) {
                  return SizedBox(
                    height: 92 + MediaQuery.of(context).padding.bottom,
                  ); // Adjust height to account for floating nav bar
                }
                final clinic = favClinics[index];
                const isFav = true;

                return _ClinicCard(
                  clinic: clinic,
                  showFavoriteButton: true,
                  isFav: isFav,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final Map<String, dynamic> clinic;
  final bool showFavoriteButton;
  final bool isFav;

  const _ClinicCard({
    required this.clinic,
    required this.showFavoriteButton,
    required this.isFav,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserNavBarProvider>();
    final picUrl = clinic['picUrl'] as String?;

    ImageProvider? backgroundImage;
    if (picUrl != null) {
      if (picUrl.startsWith('http')) {
        backgroundImage = CachedNetworkImageProvider(picUrl);
      } else {
        backgroundImage = AssetImage(picUrl);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Stack(
        children: [
          Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 45,
                  backgroundImage: backgroundImage,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha((255 * 0.1).round()),
                  child: picUrl == null
                      ? Icon(LucideIcons.home) // Placeholder icon
                      : null,
                ),
                title: SizedBox(
                  height: 25,
                  child: Marquee(
                    text: clinic["clinicName"] ?? "unnamed_clinic".tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: const Duration(seconds: 2),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (clinic["specialty"] as String?)?.tr() ??
                            "general".tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SizedBox(
                              height: 20,
                              child: Marquee(
                                text: clinic["address"] ?? clinic["city"] ?? "",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                blankSpace: 20.0,
                                velocity: 25.0,
                                pauseAfterRound: const Duration(seconds: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: ListTile(
                  onTap: () => SlotsUi.showModalSheet(context, clinic),
                  titleAlignment: ListTileTitleAlignment.center,
                  title: Center(
                    child: Text(
                      "book_appointment".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (showFavoriteButton)
            Positioned(
              top: 8,
              right: 8,
              child: LucideAnimatedIcon(
                icon: heart,
                trigger: isFav ? AnimationTrigger.loop : AnimationTrigger.onTap,
                color: isFav
                    ? Theme.of(context).colorScheme.error
                    : Colors.grey.withAlpha((255 * 0.4).round()),
                onTap: () async {
                  try {
                    await provider.toggleFavorite(clinic['uid']);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFav
                              ? 'removed_from_favorites'.tr()
                              : 'added_to_favorites'.tr(),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('error_generic'.tr())),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
