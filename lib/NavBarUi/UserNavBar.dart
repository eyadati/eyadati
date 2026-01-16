import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:eyadati/user/userAppointments.dart';
import 'package:eyadati/user/userSettingsPage.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart'; // flutter pub add flutter_floating_bottom_bar
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deferred_indexed_stack/deferred_indexed_stack.dart'; // flutter pub add deferred_indexed_stack
import 'package:lucide_icons/lucide_icons.dart';

class UserNavBarProvider extends ChangeNotifier {
  List<Map<String, dynamic>> favClinics = [];
  String _selected = "1";
  String get selected => _selected;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  UserNavBarProvider() {
    _loadFavoriteClinics(); // Load favorites when provider is created
  }

  Future<void> _loadFavoriteClinics() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch the favorite clinic UIDs from the user's favorites subcollection
      final favoriteUidsSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get(GetOptions(source: Source.server)); // Always fetch from server

      final List<String> favoriteClinicIds = favoriteUidsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      // 2. Fetch full clinic details for each favorite clinic
      if (favoriteClinicIds.isNotEmpty) {
        final clinicsSnapshot = await firestore
            .collection('clinics')
            .where(FieldPath.documentId, whereIn: favoriteClinicIds)
            .get(GetOptions(source: Source.server)); // Always fetch from server

        favClinics = clinicsSnapshot.docs
            .map((doc) => {'uid': doc.id, ...doc.data()})
            .toList();
      } else {
        favClinics = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading favorite clinics: $e");
    }
  }

  /// Uses get() to check if clinic is favorited (saves reads vs snapshot)
  Future<bool> isFavorite(String clinicUid) async {
    final user = auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(clinicUid)
          .get(GetOptions(source: Source.cache));

      return doc.exists;
    } catch (e) {
      debugPrint("Error checking favorite: $e");
      return false;
    }
  }

  /// Toggles favorite status and updates local list
  Future<void> toggleFavorite(
    String clinicUid,
    // Removed clinicData from parameters as we will fetch full data
  ) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final favoriteDoc = firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(clinicUid);

    try {
      final docSnapshot = await favoriteDoc.get(
        GetOptions(
          source: Source.server,
        ), // Always check server for favorite status
      );

      if (docSnapshot.exists) {
        // If already favorited, remove it
        await favoriteDoc.delete();
        favClinics.removeWhere((clinic) => clinic['uid'] == clinicUid);
        debugPrint("Removed clinic $clinicUid from favorites");
      } else {
        // If not favorited, fetch full clinic data and add it
        final clinicDoc = await firestore
            .collection('clinics')
            .doc(clinicUid)
            .get(
              GetOptions(source: Source.server),
            ); // Fetch full clinic data from server

        if (!clinicDoc.exists) {
          throw Exception('Clinic not found');
        }
        final fullClinicData = clinicDoc.data()!;

        await favoriteDoc.set({
          ...fullClinicData, // Save full clinic data
          'addedAt': FieldValue.serverTimestamp(),
        });
        favClinics.add({'uid': clinicUid, ...fullClinicData});
        debugPrint("Added clinic $clinicUid to favorites");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      throw Exception('Failed to update favorites: $e');
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
        // 'controller' is for scroll-to-hide functionality
        // Not used here since IndexedStack handles page switching
        return DeferredIndexedStack(
          index: selectedIndex,
          children: [
            DeferredTab(id: "1", child: UserSettings()),
            DeferredTab(id: "2", child: UserAppointments()),
            DeferredTab(id: "3", child: FavoritScreen()),
          ],
        );
      },

      // Floating navigation bar items
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, LucideIcons.settings, "settings".tr(), "1"),
            _buildNavItem(context, LucideIcons.home, "home".tr(), "2"),
            _buildNavItem(context, LucideIcons.heart, "favorites".tr(), "3"),
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
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label.tr(), style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class FavoritScreen extends StatelessWidget {
  const FavoritScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<UserNavBarProvider>(
        builder: (context, provider, _) {
          if (provider.favClinics.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: provider.favClinics.length,
            itemBuilder: (context, index) {
              final clinic = provider.favClinics[index];
              return Slidable(
                key: ValueKey(clinic['uid']),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.2,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await provider.toggleFavorite(clinic['uid']);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('removed_from_favorites'.tr()),
                          ),
                        );
                      },
                      icon: Icon(
                        LucideIcons.heart,
                        color: Theme.of(context).colorScheme.error,
                        size: 40,
                      ),
                    ),
                  ],
                ),
                child: _ClinicCard(clinic: clinic, showFavoriteButton: false),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final Map<String, dynamic> clinic;
  final bool showFavoriteButton;

  const _ClinicCard({required this.clinic, required this.showFavoriteButton});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserNavBarProvider>();
    final isFav = provider.favClinics.any((fav) => fav['uid'] == clinic['uid']);
    final picUrl = clinic['picUrl'] as String?;

    ImageProvider? backgroundImage;
    if (picUrl != null) {
      if (picUrl.startsWith('http')) {
        backgroundImage = NetworkImage(picUrl);
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
                title: Text(
                  clinic["clinicName"] ?? "unnamed_clinic".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clinic["specialty"] ?? "general".tr(),
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
                            child: Text(
                              clinic["address"] ?? clinic["city"] ?? "",
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
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
              child: IconButton(
                icon: Icon(
                  isFav
                      ? LucideIcons.heart
                      : LucideIcons
                            .heart, // Changed to filled heart when favorite
                  color: isFav
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () async {
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
