import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:google_maps_url_extractor/url_extractor.dart'; // Import GoogleMapsUrlExtractor
import 'package:eyadati/utils/location_helper.dart'; // Import LocationHelper

class ClinicSearchProvider extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  List<Map<String, dynamic>> _currentClinics = [];
  bool _isLoading = false;
  String? _error;
  String? _userCity;
  Set<String> _favoriteClinics = {}; // New: Store UIDs of favorite clinics
  Position? _currentLocation; // New: Store user's current location

  // Filter states
  String _searchQuery = '';
  String? _selectedCity; // null means user's city
  String? _selectedSpecialty; // null means all specialties

  Timer? _debounceTimer;

  ClinicSearchProvider({required this.firestore, required this.auth}) {
    _initialize();
  }

  // Getters
  List<Map<String, dynamic>> get currentClinics => _currentClinics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userCity => _userCity;
  String? get selectedCity => _selectedCity;
  String? get selectedSpecialty => _selectedSpecialty;
  String get searchQuery => _searchQuery;
  Set<String> get favoriteClinics =>
      _favoriteClinics; // New getter for favorite clinics

  // Static data
  static const List<String> specialtiesList = [
    'general_medicine',
    'pediatrics',
    'gynecology',
    'dermatology',
    'dentistry',
    'orthopedics',
    'ophthalmology',
    'ent',
    'cardiology',
    'psychiatry',
    'psychology',
    'physiotherapy',
    'nutrition',
    'neurology',
    'gastroenterology',
    'urology',
    'pulmonology',
    'endocrinology',
    'rheumatology',
    'oncology',
    'surgery',
    'radiology',
    'laboratory_services',
    'nephrology',
  ];

  static const List<String> algerianCitiesList = [
    'Algiers',
    'Oran',
    'Constantine',
    'Annaba',
    'Blida',
    'Batna',
    'Djelfa',
    'Sétif',
    'Sidi Bel Abbès',
    'Biskra',
    'Tébessa',
    'Skikda',
    'Tiaret',
    'Béjaïa',
    'Tlemcen',
    'Béchar',
    'Mostaganem',
    'Bordj Bou Arreridj',
    'Chlef',
    'Souk Ahras',
    'El Eulma',
    'Médéa',
    'Tizi Ouzou',
    'Jijel',
    'Laghouat',
    'El Oued',
    'Ouargla',
    'M\'Sila',
    'Relizane',
    'Saïda',
    'Bou Saâda',
    'Guelma',
    'Aïn Beïda',
    'Maghnia',
    'Mascara',
    'Khenchela',
    'Barika',
    'Messaad',
    'Aflou',
    'Aïn Oussara',
    'Adrar',
    'Aïn Defla',
    'Aïn Fakroun',
    'Aïn Oulmene',
    'Aïn M\'lila',
    'Aïn Sefra',
    'Aïn Témouchent',
    'Aïn Touta',
    'Akbou',
    'Azzaba',
    'Berrouaghia',
    'Bir el-Ater',
    'Boufarik',
    'Bouira',
    'Chelghoum Laid',
    'Cheria',
    'Chettia',
    'El Bayadh',
    'El Guerrara',
    'El-Khroub',
    'Frenda',
    'Ferdjioua',
    'Ghardaïa',
    'Hassi Bahbah',
    'Khemis Miliana',
    'Ksar Chellala',
    'Ksar Boukhari',
    'Lakhdaria',
    'Larbaâ',
  ];

  Future<void> _initialize() async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      // Try to get current location
      try {
        _currentLocation = await LocationHelper.getCurrentLocation();
        debugPrint(
          "Current location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}",
        );
      } catch (e) {
        debugPrint("Error getting current location: $e");
        // Don't block if location fails, continue without it.
      }

      final doc = await firestore
          .collection("users")
          .doc(user.uid)
          .get(GetOptions(source: Source.cache));
      _userCity = doc.data()?["city"]?.toString();

      if (_userCity != null) {
        await fetchClinics();
        debugPrint(_userCity);
      }
      await _loadFavoriteClinics(); // Load favorite clinics
    } catch (e) {
      debugPrint("Error initializing: $e");
    }
  }

  Future<void> _loadFavoriteClinics() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final favoriteDocs = await firestore
          .collection("users")
          .doc(user.uid)
          .collection("favorites") // Corrected: access subcollection "favorites"
          .get(GetOptions(source: Source.server));
      _favoriteClinics = favoriteDocs.docs.map((doc) => doc.id).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading favorite clinics: $e");
    }
  }

  List<Map<String, dynamic>> get filteredClinics {
    return _currentClinics.where((clinic) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (clinic["clinicName"] ?? "").toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesSpecialty =
          _selectedSpecialty == null ||
          (clinic["specialty"] ?? "").toString() == _selectedSpecialty;

      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  Future<void> fetchClinics() async {
    if (_isLoading) return;

    final cityToQuery = _selectedCity ?? _userCity;
    if (cityToQuery == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> baseQuery = firestore
          .collection("clinics")
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (model, _) => model,
          )
          .where("city", isEqualTo: cityToQuery);

      if (_selectedSpecialty != null) {
        baseQuery = baseQuery.where("specialty", isEqualTo: _selectedSpecialty);
      }

      if (_searchQuery.isNotEmpty) {
        baseQuery = baseQuery
            .orderBy("clinicName")
            .startAt([_searchQuery])
            .endAt(['$_searchQuery\uf8ff']);
      }
      baseQuery = baseQuery.limit(50);

      // Always try cache first for clinic list
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await baseQuery.get(GetOptions(source: Source.cache));

      List<Map<String, dynamic>> fetchedClinics = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()}) // Removed !
          .toList();

      // If cache is empty, fetch from server
      if (fetchedClinics.isEmpty) {
        final QuerySnapshot<Map<String, dynamic>> serverSnapshot =
            await baseQuery.get(GetOptions(source: Source.server)); // Fetch from server
        fetchedClinics = serverSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()}) // Removed !
            .toList();
      }

      if (_currentLocation != null) {
        for (var clinic in fetchedClinics) {
          final mapsLink = clinic['mapsLink'] as String?;
          if (mapsLink != null && mapsLink.isNotEmpty) {
            final coordinates = GoogleMapsUrlExtractor.extractCoordinates(
              mapsLink,
            );
            if (coordinates != null) {
              final clinicLat = coordinates['latitude'];
              final clinicLon = coordinates['longitude'];
              if (clinicLat != null && clinicLon != null) {
                final distance = await LocationHelper.calculateDistance(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                  clinicLat,
                  clinicLon,
                );
                clinic['distance'] = distance; // Store distance in meters
              }
            }
          }
        }
        // Sort clinics by distance
        fetchedClinics.sort((a, b) {
          final distA = a['distance'] as double?;
          final distB = b['distance'] as double?;
          if (distA == null && distB == null) return 0;
          if (distA == null) return 1;
          if (distB == null) return -1;
          return distA.compareTo(distB);
        });
      }

      _currentClinics = fetchedClinics;
    } catch (e) {
      _error = "Failed to load clinics. Please try again.".tr();
      debugPrint("Firestore error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters({String? city, String? specialty}) async {
    _selectedCity = city;
    _selectedSpecialty = specialty;
    await fetchClinics();
  }

  void updateSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  void clearFilters() {
    _selectedCity = null;
    _selectedSpecialty = null;
    _searchQuery = '';
    fetchClinics();
  }

  Future<void> toggleFavorite(String clinicUid, bool isFavorite) async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final userFavoritesRef = firestore
          .collection("users")
          .doc(user.uid)
          .collection("favorites");

      if (isFavorite) {
        await userFavoritesRef.doc(clinicUid).delete();
        _favoriteClinics.remove(clinicUid);
      } else {
        await userFavoritesRef.doc(clinicUid).set({
          'addedAt': FieldValue.serverTimestamp(),
        });
        _favoriteClinics.add(clinicUid);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class ClinicFilterBottomSheet extends StatelessWidget {
  static Future<bool?> show(BuildContext context) {
    return showMaterialModalBottomSheet<bool>(
      context: context,

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ClinicSearchProvider(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
        child: const _ClinicBottomSheetContent(),
      ),
    );
  }

  const ClinicFilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ClinicBottomSheetContent extends StatelessWidget {
  const _ClinicBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicSearchProvider>(
      builder: (context, provider, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, provider),
                  Expanded(
                    child: _buildClinicList(
                      context,
                      provider,
                      scrollController,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ClinicSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

      child: Row(
        children: [
          IconButton(
            onPressed: () => _showFilterDialog(context, provider),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (provider.selectedSpecialty != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          provider.selectedSpecialty!.tr(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        onDeleted: () => provider.applyFilters(specialty: null),
                      ),
                    ),
                  if (provider.selectedCity != null &&
                      provider.selectedCity != provider.userCity)
                    Chip(
                      label: Text(provider.selectedCity!),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      onDeleted: () => provider.applyFilters(city: null),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicList(
    BuildContext context,
    ClinicSearchProvider provider,
    ScrollController scrollController,
  ) {
    if (provider.isLoading && provider.currentClinics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchClinics(),
              icon: const Icon(LucideIcons.refreshCcw),
              label: Text("Retry".tr()),
            ),
          ],
        ),
      );
    }

    final clinics = provider.filteredClinics;

    if (clinics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No clinics found".tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        0,
        12,
        0,
        0,
      ), // Remove bottom padding here
      itemCount: clinics.length + 1, // Add 1 for the SizedBox
      itemBuilder: (context, index) {
        if (index == clinics.length) {
          // This is the last item, add the SizedBox
          return SizedBox(height: 92 + MediaQuery.of(context).padding.bottom);
        }
        final clinicData = clinics[index];
        final distance = clinicData['distance'] as double?;
        return _ClinicCard(clinic: clinicData, distance: distance);
      },
    );
  }

  void _showFilterDialog(BuildContext context, ClinicSearchProvider provider) {
    String? tempCity = provider.selectedCity;
    String? tempSpecialty = provider.selectedSpecialty;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Filters'.tr()),
              contentPadding: const EdgeInsets.all(16),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCityDropdown(tempCity, (value) {
                      setState(() => tempCity = value);
                    }, provider),
                    const SizedBox(height: 16),
                    _buildSpecialtyDropdown(tempSpecialty, (value) {
                      setState(() => tempSpecialty = value);
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    provider.clearFilters();
                    Navigator.pop(context);
                  },
                  child: Text('Clear All'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    provider.applyFilters(
                      city: tempCity,
                      specialty: tempSpecialty,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Apply'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCityDropdown(
    String? currentValue,
    ValueChanged<String?> onChanged,
    ClinicSearchProvider provider,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "City".tr(),
        prefixIcon: const Icon(LucideIcons.mapPin),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('${provider.userCity} (Your City)'),
        ),
        ...ClinicSearchProvider.algerianCitiesList
            .where((city) => city != provider.userCity)
            .map((city) => DropdownMenuItem(value: city, child: Text(city))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSpecialtyDropdown(
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Specialty".tr(),
        prefixIcon: const Icon(LucideIcons.stethoscope),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('All Specialties'.tr(), overflow: TextOverflow.ellipsis),
        ),
        ...ClinicSearchProvider.specialtiesList.map((specialty) {
          return DropdownMenuItem(
            value: specialty,
            child: Text(specialty.tr(), overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final Map<String, dynamic> clinic;
  final double? distance; // New: Distance parameter

  const _ClinicCard({
    required this.clinic,
    this.distance,
  }); // Updated constructor

  @override
  Widget build(BuildContext context) {
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
      child: Column(
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
              clinic["clinicName"] ?? "Unnamed Clinic".tr(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Consumer<ClinicSearchProvider>(
              builder: (context, provider, child) {
                final isFavorite = provider.favoriteClinics.contains(
                  clinic['id'],
                );
                return IconButton(
                  icon: Icon(
                    isFavorite
                        ? LucideIcons.heart
                        : LucideIcons
                              .heart, // Changed to filled heart when favorite
                    color: isFavorite
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  onPressed: () {
                    provider.toggleFavorite(clinic['id'], isFavorite);
                  },
                );
              },
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    clinic["specialty"] ?? "General".tr(),
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
                  if (distance != null) // Display distance if available
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${(distance! / 1000).toStringAsFixed(1)} km', // Convert meters to km
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            /*if (booked == true && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Userhome()),
                  (route) => false,
                );
              }*/
          ),
          Container(
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: ListTile(
              onTap: () async {
                final booked = await SlotsUi.showModalSheet(context, clinic);
                if (booked == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
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
    );
  }
}
