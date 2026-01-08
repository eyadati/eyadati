import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ClinicSearchProvider extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  List<Map<String, dynamic>> _currentClinics = [];
  bool _isLoading = false;
  String? _error;
  String? _userCity;

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

  // Static data
  static const List<String> specialtiesList = [
    'General Medicine',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Dentistry',
    'Orthopedics',
    'Ophthalmology',
    'ENT (Ear, Nose, Throat)',
    'Cardiology',
    'Psychiatry',
    'Psychology',
    'Physiotherapy',
    'Nutrition',
    'Neurology',
    'Gastroenterology',
    'Urology',
    'Pulmonology',
    'Endocrinology',
    'Rheumatology',
    'Oncology',
    'Surgery',
    'Radiology',
    'Laboratory Services',
    'Nephrology',
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

      final doc = await firestore.collection("users").doc(user.uid).get();
      _userCity = doc.data()?["city"]?.toString();

      if (_userCity != null) {
        await fetchClinics();
        debugPrint(_userCity);
      }
    } catch (e) {
      debugPrint("Error initializing: $e");
    }
  }

  List<Map<String, dynamic>> get filteredClinics {
    return _currentClinics.where((clinic) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (clinic["clinicName"] ?? "").toString().contains(_searchQuery);

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
      // Use cache if querying user's own city, server otherwise
      final useServer = _selectedCity != null && _selectedCity != _userCity;
      final source = useServer ? Source.serverAndCache : Source.cache;

      final querySnapshot = await firestore
          .collection("clinics")
          .where("city", isEqualTo: cityToQuery)
          .limit(50)
          .get(GetOptions(source: source));

      // If cache returns empty and we're using cache, retry with server
      if (querySnapshot.docs.isEmpty && !useServer) {
        final serverSnapshot = await firestore
            .collection("clinics")
            .where("city", isEqualTo: cityToQuery)
            .limit(50)
            .get(GetOptions(source: Source.server));
        _currentClinics = serverSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      } else {
        _currentClinics = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class ClinicFilterBottomSheet extends StatelessWidget {
  static void show(BuildContext context) {
    showMaterialModalBottomSheet(
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
            return Column(
              children: [
                _buildHeader(context, provider),
                Expanded(child: _buildClinicList(provider, scrollController)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ClinicSearchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showFilterDialog(context, provider),
            icon: const Icon(Icons.filter_list, size: 20),
            label: Text('Filter'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 14),
            ),
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
                        ),
                        onDeleted: () => provider.applyFilters(specialty: null),
                      ),
                    ),
                  if (provider.selectedCity != null &&
                      provider.selectedCity != provider.userCity)
                    Chip(
                      label: Text(provider.selectedCity!),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(provider.error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchClinics(),
              icon: const Icon(Icons.refresh),
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
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No clinics found".tr(),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: clinics.length,
      itemBuilder: (context, index) => _ClinicCard(clinic: clinics[index]),
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
        prefixIcon: const Icon(Icons.location_city),
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
        prefixIcon: const Icon(Icons.medical_services),
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

  const _ClinicCard({required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
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
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clinic["address"] ?? clinic["city"] ?? "",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
              onTap: () => SlotsUi.showModalSheet(context, clinic),
              titleAlignment: ListTileTitleAlignment.center,
              title: Center(
                child: Text("book_appointment".tr(),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              trailing: Icon(Icons.chevron_right),
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
