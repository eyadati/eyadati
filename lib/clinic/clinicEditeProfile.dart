import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:eyadati/utils/network_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ================ PROVIDER ================

class ClinicEditProfileProvider extends ChangeNotifier {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  ClinicEditProfileProvider({required this.auth, required this.firestore}) {
    _loadClinicData();
  }

  // Form key
  final formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final clinicNameController = TextEditingController();
  final specialtyController = TextEditingController();
  final durationController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final mapsLinkController = TextEditingController();

  // State
  String? selectedCity;
  List<int> workingDays = [];
  int? openingMinutes;
  int? closingMinutes;
  int? breakStartMinutes;
  int? breakEndMinutes;
  File? pickedImage;
  String? picUrl;
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  // Dropdown data
  final List<String> algerianCities = [
    'Algiers', 'Oran', 'Constantine', 'Annaba', 'Blida', 'Batna', 'Djelfa', 'Sétif',
    'Sidi Bel Abbès', 'Biskra', 'Tébessa', 'Skikda', 'Tiaret', 'Béjaïa', 'Tlemcen',
    'Béchar', 'Mostaganem', 'Bordj Bou Arreridj', 'Chlef', 'Souk Ahras', 'El Eulma',
    'Médéa', 'Tizi Ouzou', 'Jijel', 'Laghouat', 'El Oued', 'Ouargla', 'M\'Sila',
    'Relizane', 'Saïda', 'Bou Saâda', 'Guelma', 'Aïn Beïda', 'Maghnia', 'Mascara',
    'Khenchela', 'Barika', 'Messaad', 'Aflou', 'Aïn Oussara', 'Adrar', 'Aïn Defla',

    'Aïn Fakroun', 'Aïn Oulmene', 'Aïn M\'lila', 'Aïn Sefra', 'Aïn Témouchent',
    'Aïn Touta', 'Akbou', 'Azzaba', 'Berrouaghia', 'Bir el-Ater', 'Boufarik',
    'Bouira', 'Chelghoum Laid', 'Cheria', 'Chettia', 'El Bayadh', 'El Guerrara',
    'El-Khroub', 'Frenda', 'Ferdjioua', 'Ghardaïa', 'Hassi Bahbah', 'Khemis Miliana',
    'Ksar Chellala', 'Ksar Boukhari', 'Lakhdaria', 'Larbaâ',
  ];

  final List<String> specialties = [
    'General Medicine'.tr(), 'Pediatrics'.tr(), 'Gynecology'.tr(), 'Dermatology'.tr(),
    'Dentistry'.tr(), 'Orthopedics'.tr(), 'Ophthalmology'.tr(), 'ENT (Ear, Nose, Throat)'.tr(),
    'Cardiology'.tr(), 'Psychiatry'.tr(), 'Psychology'.tr(), 'Physiotherapy'.tr(),
    'Nutrition'.tr(), 'Neurology'.tr(), 'Gastroenterology'.tr(), 'Urology'.tr(),
    'Pulmonology'.tr(), 'Endocrinology'.tr(), 'Rheumatology'.tr(), 'Oncology'.tr(),
    'Surgery'.tr(), 'Radiology'.tr(), 'Laboratory Services'.tr(), 'Nephrology'.tr(),
  ];

  void onSpecialtyChange(String? value) {
    specialtyController.text = value ?? '';
    notifyListeners();
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      pickedImage = File(image.path);
      notifyListeners();
    }
  }

  Future<void> _loadClinicData() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        error = "no_user_found".tr();
        isLoading = false;
        notifyListeners();
        return;
      }

      final doc = await firestore.collection("clinics").doc(user.uid).get(GetOptions(source: Source.cache));
      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        clinicNameController.text = data['clinicName'] ?? '';
        specialtyController.text = data['specialty'] ?? '';
        durationController.text = data['Duration']?.toString() ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone'] ?? '';
        mapsLinkController.text = data['mapsLink'] ?? '';
        picUrl = data['picUrl'];

        selectedCity = data['city'] != null
            ? algerianCities.firstWhere((c) => c == data['city'], orElse: () => algerianCities[0])
            : null;

        workingDays = List<int>.from(data['workingDays'] ?? []);
        openingMinutes = data['openingAt'];
        closingMinutes = data['closingAt'];
        breakStartMinutes = data['breakStart'];
        breakEndMinutes = data['breakEnd'];
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _uploadImage() async {
    if (pickedImage == null) return null;

    final file = pickedImage!;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await Supabase.instance.client.storage.from('eyadati').upload(fileName, file);
      final urlResponse = Supabase.instance.client.storage.from('eyadati').getPublicUrl(fileName);
      return urlResponse;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProfile(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCity == null) {
      error = "city_required".tr();
      notifyListeners();
      return;
    }

    if (!await NetworkHelper.checkInternetConnectivity(context)) {
      isSaving = false; // Reset saving state
      notifyListeners();
      return;
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final user = auth.currentUser;
      if (user == null) throw Exception("no user found".tr());

      String? newPicUrl;
      if (pickedImage != null) {
        newPicUrl = await _uploadImage();
      }

      await firestore.collection("clinics").doc(user.uid).update({
        "name": nameController.text.trim(),
        "clinicName": clinicNameController.text.trim(),
        "specialty": specialtyController.text,
        "Duration": int.tryParse(durationController.text) ?? 60,
        "city": selectedCity,
        "address": addressController.text.trim(),
        "phone": phoneController.text.trim(),
        "mapsLink": mapsLinkController.text.trim(),
        "workingDays": workingDays,
        "openingAt": openingMinutes,
        "closingAt": closingMinutes,
        "breakStart": breakStartMinutes,
        "breakEnd": breakEndMinutes,
        "picUrl": newPicUrl ?? picUrl,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile updated success'.tr())));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      error = e.toString();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void selectCity(String? city) {
    selectedCity = city;
    notifyListeners();
  }

  void toggleWorkingDay(int dayIndex, bool selected) {
    selected ? workingDays.add(dayIndex) : workingDays.remove(dayIndex);
    notifyListeners();
  }

  void setTime(String type, TimeOfDay pickedTime) {
    final minutes = pickedTime.hour * 60 + pickedTime.minute;
    switch (type) {
      case 'opening':
        openingMinutes = minutes;
        break;
      case 'closing':
        closingMinutes = minutes;
        break;
      case 'breakStart':
        breakStartMinutes = minutes;
        break;
      case 'breakEnd':
        breakEndMinutes = minutes;
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    clinicNameController.dispose();
    specialtyController.dispose();
    durationController.dispose();
    addressController.dispose();
    phoneController.dispose();
    mapsLinkController.dispose();
    super.dispose();
  }
}

// ================ UI PAGE ================

class ClinicEditProfilePage extends StatelessWidget {
  const ClinicEditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClinicEditProfileProvider(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
      child: const _ClinicEditProfileContent(),
    );
  }
}

class _ClinicEditProfileContent extends StatelessWidget {
  const _ClinicEditProfileContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_clinic_profile'.tr()),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<ClinicEditProfileProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return _buildErrorState(context, provider);
            }

            return Form(
              key: provider.formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'clinic information'.tr()),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.clinicNameController,
                      "clinic_name".tr(),
                      provider,
                    ),
                    const SizedBox(height: 16),
                    _buildSpecialtyDropdown(context, provider),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.durationController,
                      "Appointmnent duration(minutes)".tr(),
                      provider,
                      inputType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(context, 'owner information'.tr()),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.nameController,
                      "owner_name".tr(),
                      provider,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.emailController,
                      "email".tr(),
                      provider,
                      readOnly: true,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(context, 'contact details'.tr()),
                    const SizedBox(height: 16),
                    _buildCityDropdown(context, provider),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.addressController,
                      "address".tr(),
                      provider,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.mapsLinkController,
                      "maps_link".tr(),
                      provider,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      provider.phoneController,
                      "phone_number".tr(),
                      provider,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(context, 'working hours'.tr()),
                    const SizedBox(height: 16),
                    _buildTimePickerRow(
                      context,
                      "opening".tr(),
                      'opening',
                      provider,
                    ),
                    const SizedBox(height: 12),
                    _buildTimePickerRow(
                      context,
                      "closing".tr(),
                      'closing',
                      provider,
                    ),
                    const SizedBox(height: 12),
                    _buildTimePickerRow(
                      context,
                      "break_start".tr(),
                      'breakStart',
                      provider,
                    ),
                    const SizedBox(height: 12),
                    _buildTimePickerRow(
                      context,
                      "break_end".tr(),
                      'breakEnd',
                      provider,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      context,
                      'working days'.tr(),
                      isSmall: true,
                    ),
                    _buildWorkingDaysChips(context, provider),
                    const SizedBox(height: 32),

                    _buildSectionTitle(context, 'clinic avatar'.tr()),
                    _buildAvatarPicker(context, provider),
                    const SizedBox(height: 32),

                    if (provider.error != null) ...[
                      Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isSaving
                            ? null
                            : () => provider.saveProfile(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: provider.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "save changes".tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ClinicEditProfileProvider provider,
  ) {
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
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider._loadClinicData(),
            icon: const Icon(LucideIcons.refreshCcw),
            label: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: isSmall
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    ClinicEditProfileProvider provider, {
    bool obscureText = false,
    TextInputType? inputType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType ?? TextInputType.text,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'required field'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildCityDropdown(
    BuildContext context,
    ClinicEditProfileProvider provider,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedCity,
      decoration: InputDecoration(
        labelText: "city".tr(),
        prefixIcon: const Icon(LucideIcons.mapPin),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      hint: Text("select city".tr()),
      items: provider.algerianCities.map((city) {
        return DropdownMenuItem(value: city, child: Text(city));
      }).toList(),
      onChanged: provider.selectCity,
      validator: (value) {
        if (value == null) {
          return 'city required'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildSpecialtyDropdown(
    BuildContext context,
    ClinicEditProfileProvider provider,
  ) {
    return DropdownButtonFormField<String>(
      initialValue:
          provider.specialties.contains(provider.specialtyController.text)
          ? provider.specialtyController.text
          : null,
      decoration: InputDecoration(
        labelText: "specialty".tr(),
        prefixIcon: const Icon(LucideIcons.stethoscope),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      hint: Text("select specialty".tr()),
      items: provider.specialties.map((specialty) {
        return DropdownMenuItem(value: specialty, child: Text(specialty));
      }).toList(),
      onChanged: (value) {
        provider.onSpecialtyChange(value);
      },
      validator: (value) {
        if (value == null) {
          return 'specialty required'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildTimePickerRow(
    BuildContext context,
    String label,
    String type,
    ClinicEditProfileProvider provider,
  ) {
    String? timeText;
    int? minutes;

    switch (type) {
      case 'opening':
        minutes = provider.openingMinutes;
        break;
      case 'closing':
        minutes = provider.closingMinutes;
        break;
      case 'breakStart':
        minutes = provider.breakStartMinutes;
        break;
      case 'breakEnd':
        minutes = provider.breakEndMinutes;
        break;
    }

    if (minutes != null) {
      timeText =
          "${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}";
    }

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton.icon(
          icon: const Icon(LucideIcons.clock),
          label: Text(timeText ?? "select time".tr()),
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              provider.setTime(type, picked);
            }
          },
        ),
      ],
    );
  }

  Widget _buildWorkingDaysChips(
    BuildContext context,
    ClinicEditProfileProvider provider,
  ) {
    final dayNames = [
      "monday".tr(),
      "tuesday".tr(),
      "wednesday".tr(),
      "thursday".tr(),
      "friday".tr(),
      "saturday".tr(),
      "sunday".tr(),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        return FilterChip(
          label: Text(dayNames[i]),
          selected: provider.workingDays.contains(i),
          onSelected: (val) => provider.toggleWorkingDay(i, val),
        );
      }),
    );
  }

  Widget _buildAvatarPicker(
    BuildContext context,
    ClinicEditProfileProvider provider,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () {
          provider.pickImage();
        },
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          backgroundImage: provider.pickedImage != null
              ? FileImage(provider.pickedImage!)
              : (provider.picUrl != null && provider.picUrl!.startsWith('http')
                  ? NetworkImage(provider.picUrl!)
                  : (provider.picUrl != null
                      ? AssetImage(provider.picUrl!)
                      : null)) as ImageProvider?,
          child: provider.pickedImage == null && provider.picUrl == null
              ? const Icon(Icons.add_a_photo, size: 50)
              : null,
        ),
      ),
    );
  }
}
