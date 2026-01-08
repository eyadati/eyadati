
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/clinic/clinicAuth.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:eyadati/clinic/clinic_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_url_extractor/url_extractor.dart';
class ClinicOnboardingProvider extends ChangeNotifier {
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Focus nodes for keyboard navigation
  final focusNodes = List.generate(9, (_) => FocusNode());

  // Controllers
  final nameController = TextEditingController();
  final mapsLinkController = TextEditingController();
  final durationController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final clinicNameController = TextEditingController();

  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  // State
  double? extractedLatitude;
  int avatarNumber = 1;
  double? extractedLongitude;
  int? openingMinutes;
  int? closingMinutes;
  int? breakStartMinutes;
  int? breakEndMinutes;
  List<int> workingDays = [];
  String? selectedSpecialty;
  String? _selectedCity;
  String? get selectedCity => _selectedCity;
  int currentPage = 0;
  bool isSubmitting = false;

  // Specialties as getter for locale updates
  List<String> get specialties => [
    'General Medicine'.tr(),
    'Pediatrics'.tr(),
    'Gynecology'.tr(),
    'Dermatology'.tr(),
    'Dentistry'.tr(),
    'Orthopedics'.tr(),
    'Ophthalmology'.tr(),
    'ENT (Ear, Nose, Throat)'.tr(),
    'Cardiology'.tr(),
    'Psychiatry'.tr(),
    'Psychology'.tr(),
    'Physiotherapy'.tr(),
    'Nutrition'.tr(),
    'Neurology'.tr(),
    'Gastroenterology'.tr(),
    'Urology'.tr(),
    'Pulmonology'.tr(),
    'Endocrinology'.tr(),
    'Rheumatology'.tr(),
    'Oncology'.tr(),
    'Surgery'.tr(),
    'Radiology'.tr(),
    'Laboratory Services'.tr(),
    'Nephrology'.tr(),
  ];
  final List<String> algerianCities = [
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

  // ──────────────────────────────────────────────────────────────────────────
  // Public methods
  // ──────────────────────────────────────────────────────────────────────────
  void selectAvatar(int i) {
    avatarNumber = i;
    notifyListeners();
  }

  void selectCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  void goToFormPage() {
    currentPage = 1;
    notifyListeners();
  }

  void selectSpecialty(String? value) {
    selectedSpecialty = value;
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

  void extractCoordinates() {
    if (mapsLinkController.text.isNotEmpty) {
      final coordinates = GoogleMapsUrlExtractor.extractCoordinates(
        mapsLinkController.text,
      );
      if (coordinates != null) {
        extractedLatitude = coordinates['latitude'];
        extractedLongitude = coordinates['longitude'];
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Validation
  // ──────────────────────────────────────────────────────────────────────────
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required'.tr();
    final pattern = RegExp(r'^\S+@\S+\.\S+$');
    if (!pattern.hasMatch(value.trim())) return 'Invalid email'.tr();
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required'.tr();
    if (value.length < 6) return 'Password too short'.tr();
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required'.tr();
    final pattern = RegExp(r'^[0-9]+$');
    if (!pattern.hasMatch(value.trim())) return 'Invalid number'.tr();
    return null;
  }

  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required'.tr();
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Submission with safety checks - Returns success/failure
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> validateAndSubmit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields".tr())),
      );
      return false;
    }

    // Validate time logic
    if (openingMinutes == null || closingMinutes == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please set opening and closing times".tr())),
      );
      return false;
    }
    if (openingMinutes! >= closingMinutes!) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Closing time must be after opening time".tr())),
      );
      return false;
    }
    if (breakStartMinutes != null && breakEndMinutes != null) {
      if (!(openingMinutes! <= breakStartMinutes! &&
          breakStartMinutes! < breakEndMinutes! &&
          breakEndMinutes! <= closingMinutes!)) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Break time must be within working hours".tr()),
          ),
        );
        return false;
      }
    }
    if (workingDays.isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select at least one working day".tr())),
      );
      return false;
    }
  

    extractCoordinates();

    isSubmitting = true;
    notifyListeners();

    try {
      await Clinicauth().clinicAccount(
        emailController.text.trim(),
        passwordController.text,
      );

      await ClinicFirestore().addClinic(
        nameController.text.trim(),
        extractedLongitude,
        extractedLatitude,
        clinicNameController.text.trim(),
        1,
        _selectedCity!,
        workingDays,
        phoneController.text.trim(),
        selectedSpecialty!,
        int.tryParse(durationController.text) ?? 60,
        openingMinutes!,
        closingMinutes!,
        breakStartMinutes ?? 0,
        breakEndMinutes ?? 0,
        addressController.text.trim(),
      );

      isSubmitting = false;
      notifyListeners();
      return true; // ✅ Success
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      return false; // ✅ Failure
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
    nameController.dispose();
    mapsLinkController.dispose();
    durationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    clinicNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2️⃣ UI: Stateless widgets with bounded constraints
// ─────────────────────────────────────────────────────────────────────────────
class ClinicOnboardingPages extends StatelessWidget {
  const ClinicOnboardingPages({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClinicOnboardingProvider(),
      child: const _ClinicOnboardingView(),
    );
  }
}

class _ClinicOnboardingView extends StatelessWidget {
  const _ClinicOnboardingView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicOnboardingProvider>();

    // ✅ ROOT SCAFFOLD: Provides bounded constraints and material surface
    return Scaffold(
      resizeToAvoidBottomInset: true, // Avoid keyboard overlap
      body: SafeArea(
        child: provider.currentPage == 0
            ? const _IntroPage()
            : const _FormPage(),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              "Hello to Eyadati".tr(),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Let's set up your clinic profile to get started".tr(),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: context.read<ClinicOnboardingProvider>().goToFormPage,
              icon: const Icon(Icons.arrow_forward),
              label: Text("Get Started".tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 100),
            TextButton(
              onPressed: () => Clinicauth().ClinicLoginIn(context),
              child: Text("Already have an account? Login".tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormPage extends StatelessWidget {
  const _FormPage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicOnboardingProvider>();

    return Form(
      key: provider.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Account Information".tr()),
            _buildTextFormField(
              context,
              controller: provider.nameController,
              label: "Full Name".tr(),
              validator: provider.validateRequired,
              focusNode: provider.focusNodes[0],
              nextNode: provider.focusNodes[1],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              context,
              controller: provider.emailController,
              label: "Email".tr(),
              validator: provider.validateEmail,
              focusNode: provider.focusNodes[1],
              nextNode: provider.focusNodes[2],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              context,
              controller: provider.passwordController,
              label: "Password".tr(),
              obscureText: true,
              validator: provider.validatePassword,
              focusNode: provider.focusNodes[2],
              nextNode: provider.focusNodes[3],
            ),
            const SizedBox(height: 32),

            _buildSectionTitle(context, "Business Information".tr()),
            _buildTextFormField(
              context,
              controller: provider.clinicNameController,
              label: "Business Name".tr(),
              validator: provider.validateRequired,
              focusNode: provider.focusNodes[3],
              nextNode: provider.focusNodes[4],
            ),
            const SizedBox(height: 16),
            _buildSpecialtyDropdown(context),
            const SizedBox(height: 16),
            _buildTextFormField(
              context,
              controller: provider.durationController,
              label: 'Appointmnent duration(minutes)'.tr(),
              inputType: TextInputType.number,
              focusNode: provider.focusNodes[4],
              nextNode: provider.focusNodes[5],
            ),
            const SizedBox(height: 32),

            _buildSectionTitle(context, "Address & Contact".tr()),
            _buildCityDropdown(context),
            const SizedBox(height: 16),
            _buildTextFormField(
              context,
              controller: provider.addressController,
              label: "Address".tr(),
              validator: provider.validateRequired,
              focusNode: provider.focusNodes[6],
              nextNode: provider.focusNodes[7],
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              context,
              controller: provider.mapsLinkController,
              label: 'Google Maps link'.tr(),
              focusNode: provider.focusNodes[7],
              nextNode: provider.focusNodes[8],
            ),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse('https://www.google.com/maps ');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.location_pin),
                label: Text("Open Google Maps".tr()),
              ),
            ),
            _buildTextFormField(
              context,
              controller: provider.phoneController,
              label: "Phone Number".tr(),
              inputType: TextInputType.phone,
              validator: provider.validatePhone,
              focusNode: provider.focusNodes[8],
              onFieldSubmitted: () => provider.validateAndSubmit(context),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle(context, "Working Hours".tr()),
            _buildTimePickerRow(context, "Opening", 'opening'),
            const SizedBox(height: 12),
            _buildTimePickerRow(context, "Closing", 'closing'),
            const SizedBox(height: 12),
            _buildTimePickerRow(context, "Break Start", 'breakStart'),
            const SizedBox(height: 12),
            _buildTimePickerRow(context, "Break End", 'breakEnd'),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "opening Days".tr(), isSmall: true),
            _buildWorkingDaysChips(context),
            const SizedBox(height: 32),

            _buildSectionTitle(context, "Clinic Image".tr()),
            Center(child: _buildAvatarPicker(context)),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isSubmitting
                    ? null
                    : () async {
                        final success = await provider.validateAndSubmit(
                          context,
                        );
                        if (success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Clinichome(),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isSubmitting
                    ? _buildButtonProgress()
                    : Text("Complete Setup".tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI Helper methods with focus management
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTextFormField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? inputType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextNode,
    VoidCallback? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType ?? TextInputType.text,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
      onFieldSubmitted: (_) {
        if (nextNode != null) {
          FocusScope.of(context).requestFocus(nextNode);
        } else if (onFieldSubmitted != null) {
          onFieldSubmitted();
        }
      },
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
            : Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildButtonProgress() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _buildCityDropdown(BuildContext context) {
    final provider = context.watch<ClinicOnboardingProvider>();
    return DropdownButtonFormField<String>(
      initialValue: provider.algerianCities[0],
      decoration: InputDecoration(
        labelText: "City".tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text("Select City".tr()),
      onChanged: provider.selectCity,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a city'.tr();
        }
        return null;
      },
      items: provider.algerianCities.map((city) {
        return DropdownMenuItem(value: city, child: Text(city));
      }).toList(),
      menuMaxHeight: 300,
    );
  }

  Widget _buildSpecialtyDropdown(BuildContext context) {
    final provider = context.watch<ClinicOnboardingProvider>();
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedSpecialty,
      decoration: InputDecoration(
        labelText: "Specialty".tr(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: Text("Select Specialty".tr()),
      onChanged: provider.selectSpecialty,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a specialty'.tr();
        }
        return null;
      },
      items: provider.specialties.map((s) {
        return DropdownMenuItem(value: s, child: Text(s));
      }).toList(),
      menuMaxHeight: 250, 
    );
  }

  Widget _buildWorkingDaysChips(BuildContext context) {
    final provider = context.watch<ClinicOnboardingProvider>();
    final dayNames = [
      "Monday".tr(),
      "Tuesday".tr(),
      "Wednesday".tr(),
      "Thursday".tr(),
      "Friday".tr(),
      "Saturday".tr(),
      "Sunday".tr(),
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

  Widget _buildTimePickerRow(BuildContext context, String label, String type) {
    final provider = context.watch<ClinicOnboardingProvider>();
    String? timeText;
    switch (type) {
      case 'opening':
        timeText = provider.openingMinutes != null
            ? "${provider.openingMinutes! ~/ 60}:${(provider.openingMinutes! % 60).toString().padLeft(2, '0')}"
            : null;
        break;
      case 'closing':
        timeText = provider.closingMinutes != null
            ? "${provider.closingMinutes! ~/ 60}:${(provider.closingMinutes! % 60).toString().padLeft(2, '0')}"
            : null;
        break;
      case 'breakStart':
        timeText = provider.breakStartMinutes != null
            ? "${provider.breakStartMinutes! ~/ 60}:${(provider.breakStartMinutes! % 60).toString().padLeft(2, '0')}"
            : null;
        break;
      case 'breakEnd':
        timeText = provider.breakEndMinutes != null
            ? "${provider.breakEndMinutes! ~/ 60}:${(provider.breakEndMinutes! % 60).toString().padLeft(2, '0')}"
            : null;
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton.icon(
          icon: const Icon(Icons.access_time),
          label: Text(timeText ?? "Select Time".tr()),
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

  Widget _buildAvatarPicker(BuildContext context) {
    final provider = context.watch<ClinicOnboardingProvider>();
    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width * 0.9,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 10,
        itemBuilder: (cntx, i) {
          return GestureDetector(
            onTap: () {
              provider.selectAvatar(i);
            },
            child: CircleAvatar(
              
              radius: 11,
              backgroundColor: provider.avatarNumber == i
                  ? Colors.black
                  : Colors.green,
                  child: Image.asset("assets/avatars/${i+1}.png"),
            ),
          );
        },
      ),
    );
  }
}
