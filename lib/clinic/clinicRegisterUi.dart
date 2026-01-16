import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/clinic/clinicAuth.dart';
import 'package:eyadati/clinic/clinic_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_url_extractor/url_extractor.dart';
import 'package:eyadati/utils/network_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  File? pickedImage;
  String? picUrl;
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
  bool _agreeToTerms = false; // New property

  bool get agreeToTerms => _agreeToTerms;

  void toggleAgreeToTerms(bool? newValue) {
    _agreeToTerms = newValue ?? false;
    notifyListeners();
  }

  // Specialties as getter for locale updates
  List<String> get specialties => [
    'general_medicine'.tr(),
    'pediatrics'.tr(),
    'gynecology'.tr(),
    'dermatology'.tr(),
    'dentistry'.tr(),
    'orthopedics'.tr(),
    'ophthalmology'.tr(),
    'ent'.tr(),
    'cardiology'.tr(),
    'psychiatry'.tr(),
    'psychology'.tr(),
    'physiotherapy'.tr(),
    'nutrition'.tr(),
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
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      pickedImage = File(image.path);
      avatarNumber = -1; // Deselect default avatars
      notifyListeners();
    }
  }

  void selectAvatar(int i) {
    avatarNumber = i;
    pickedImage = null; // Deselect picked image
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
  Future<String?> _uploadImage() async {
    if (pickedImage == null) return null;

    final file = pickedImage!;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await Supabase.instance.client.storage
          .from('eyadati')
          .upload(fileName, file);
      final urlResponse = Supabase.instance.client.storage
          .from('eyadati')
          .getPublicUrl(fileName);
      return urlResponse;
    } catch (e) {
      return null;
    }
  }

  Future<bool> validateAndSubmit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields".tr())),
      );
      return false;
    }
    if (!await NetworkHelper.checkInternetConnectivity(context)) {
      isSubmitting = false; // Ensure submitting state is reset
      notifyListeners();
      return false;
    }
    // Validate time logic
    if (openingMinutes == null || closingMinutes == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select opening and closing times".tr())),
      );
      return false;
    }
    if (openingMinutes! >= closingMinutes!) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Opening time must be before closing time".tr()),
        ),
      );
      return false;
    }
    if (breakStartMinutes != null && breakEndMinutes != null) {
      if (breakStartMinutes! >= breakEndMinutes!) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Break start time must be before break end time".tr(),
            ),
          ),
        );
        return false;
      }
      if (breakStartMinutes! < openingMinutes! ||
          breakEndMinutes! > closingMinutes!) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Break times must be within working hours".tr()),
          ),
        );
        return false;
      }
    }

    // Validate duration
    final duration = int.tryParse(durationController.text);
    if (duration == null || duration <= 0) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Appointment duration must be a positive number".tr()),
        ),
      );
      return false;
    }

    if (_selectedCity == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a city".tr())));
      return false;
    }
    if (selectedSpecialty == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a specialty".tr())));
      return false;
    }
    if (workingDays.isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one working day".tr())),
      );
      return false;
    }

    if (!agreeToTerms) {
      // New validation for agreeToTerms
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please agree to the terms and privacy policy".tr()),
        ),
      );
      return false;
    }
    try {
      isSubmitting = true;
      notifyListeners();

      String? imageUrl;
      if (pickedImage != null) {
        imageUrl = await _uploadImage();
      } else {
        imageUrl = 'assets/avatars/${avatarNumber + 1}.png';
      }

      if (imageUrl == null) {
        throw Exception("Image upload failed or no image selected.");
      }

      await Clinicauth().clinicAccount(
        emailController.text.trim(),
        passwordController.text,
        context,
      );

      await ClinicFirestore().addClinic(
        nameController.text.trim(),
        mapsLinkController.text.trim(),
        clinicNameController.text.trim(),
        imageUrl,
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
