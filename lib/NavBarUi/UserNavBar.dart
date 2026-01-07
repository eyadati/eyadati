import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:eyadati/clinic/clinicSettingsPage.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/userAppointments.dart';
import 'package:eyadati/user/userSettingsPage.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart'; // flutter pub add flutter_floating_bottom_bar
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/NavBarUi/AppoitmentsManagment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:eyadati/clinic/clinic_appointments.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deferred_indexed_stack/deferred_indexed_stack.dart'; // flutter pub add deferred_indexed_stack

class UserNavBarProvider extends ChangeNotifier {
  List<Map<String, dynamic>> favClinics = [];
  String _selected = "2";
  String get selected => _selected;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<void> _initialize() async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final fetchFav = await firestore
          .collection("users")
          .doc(user.uid)
          .collection("favorites")
          .get(GetOptions(source: Source.cache));
      UserNavBarProvider().favClinics = fetchFav.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint("Error initializing: $e");
    }
  }
  // Add to UserNavBarProvider:

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
Future<void> toggleFavorite(String clinicUid, Map<String, dynamic> clinicData) async {
  final user = auth.currentUser;
  if (user == null) throw Exception('User not authenticated');

  final favoriteDoc = firestore
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .doc(clinicUid);

  try {
    final docSnapshot = await favoriteDoc.get(GetOptions(source: Source.cache));

    if (docSnapshot.exists) {
      await favoriteDoc.delete();
      favClinics.removeWhere((clinic) => clinic['uid'] == clinicUid);
      debugPrint("Removed clinic $clinicUid from favorites");
    } else {
      await favoriteDoc.set({
        ...clinicData,
        'addedAt': FieldValue.serverTimestamp(),
      });
      favClinics.add({'uid': clinicUid, ...clinicData});
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
  State<UserFloatingBottomNavBar> createState() => _UserFloatingBottomNavBarState();
}

class _UserFloatingBottomNavBarState extends State<UserFloatingBottomNavBar> {
  final _provider = UserNavBarProvider(); // Created once, lives with widget

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
    final provider = context.watch<UserNavBarProvider>();
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
            DeferredTab(child: UserSettings()),
            DeferredTab(child: UserAppointments()),
            DeferredTab(child: FavoritScreen()),
          ],
        );
      },

      // Floating navigation bar items
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.settings, "Settings".tr(), "1"),
            _buildNavItem(context, Icons.home, "Home".tr(), "2"),
            _buildNavItem(context, Icons.favorite, "Favorites".tr(), "3"),
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

class FavoritScreen extends StatelessWidget {
  const FavoritScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNavBarProvider>(
      builder: (context, provider, _) {
        if (provider.favClinics.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No favorite clinics'.tr(), style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Add clinics to see them here'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
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
                      await provider.toggleFavorite(clinic['uid'], clinic);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed from favorites'.tr())),
                      );
                    },
                    icon: const Icon(Icons.favorite, color: Colors.red, size: 40),
                  ),
                ],
              ),
              child: _ClinicCard(clinic: clinic),
            );
          },
        );
      },
    );
  }
}
class _ClinicCard extends StatelessWidget {
  final Map<String, dynamic> clinic;
  final bool showFavoriteButton;

  const _ClinicCard({
    required this.clinic,
    this.showFavoriteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserNavBarProvider>();
    final isFav = provider.favClinics.any((fav) => fav['uid'] == clinic['uid']);

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
                  backgroundImage: AssetImage(_getAvatarPath(clinic)),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                title: Text(
                  clinic["clinicName"] ?? "Unnamed Clinic".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clinic["specialty"] ?? "General".tr(),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clinic["address"] ?? clinic["city"] ?? "",
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
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
                      "Book appointment".tr(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  try {
                    await provider.toggleFavorite(clinic['uid'], clinic);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFav ? 'Removed from favorites'.tr() : 'Added to favorites'.tr(),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getAvatarPath(Map<String, dynamic> clinic) {
    return 'assets/avatars/${clinic['avatar']}.png';
  }
}
 
