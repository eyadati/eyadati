// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: Move these imports to a centralized service locator or appropriate service files
import 'package:eyadati/clinic/clinic_firestore.dart';

class ClinicEditProfilePage extends StatefulWidget {
  // TODO: Pass existing clinic data map to pre-fill the form
  final String? clinicId;
  
  const ClinicEditProfilePage({
    super.key, 
    this.clinicId,
  });

  @override
  _ClinicEditProfilePageState createState() => _ClinicEditProfilePageState();
}

class _ClinicEditProfilePageState extends State<ClinicEditProfilePage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mapsLinkController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController staffController = TextEditingController();

  // Time values stored as minutes since midnight
  int? openingMinutes;
  int? closingMinutes;
  int? breakStartMinutes;
  int? breakEndMinutes;
  List<int> workingDays = [];

  // Specialty selection
  final List<String> specialties = [
    'General Medicine', 'Pediatrics', 'Gynecology', 'Dermatology', 'Dentistry',
    'Orthopedics', 'Ophthalmology', 'ENT (Ear, Nose, Throat)', 'Cardiology',
    'Psychiatry', 'Psychology', 'Physiotherapy', 'Nutrition', 'Neurology',
    'Gastroenterology', 'Urology', 'Pulmonology', 'Endocrinology', 'Rheumatology',
    'Oncology', 'Surgery', 'Radiology', 'Laboratory Services', 'Nephrology',
  ];
  String? selectedSpecialty;
  
  // Image handling
  XFile? profileImage;
  String? existingImageUrl; // TODO: Store existing image URL for replacement/update logic
  final ImagePicker _picker = ImagePicker();
  
  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load existing clinic data from Firestore
    // _loadClinicData();
  }

  // TODO: MOVE TO CLINIC SERVICE FILE
  // Future<void> _loadClinicData() async {
  //   if (widget.clinicId != null) {
  //     // Fetch clinic document from Firestore
  //     // Update all controllers with existing data
  //     // Set existingImageUrl if available
  //     // Update state variables (times, workingDays, selectedSpecialty)
  //   }
  // }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    nameController.dispose();
    clinicNameController.dispose();
    cityController.dispose();
    addressController.dispose();
    mapsLinkController.dispose();
    phoneController.dispose();
    staffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Clinic Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner Information Section
                _buildSectionTitle('Owner Information'),
                const SizedBox(height: 16),
                _buildTextFormField(nameController, "Owner Full Name"),
                const SizedBox(height: 24),

                // Business Information Section
                _buildSectionTitle('Business Information'),
                const SizedBox(height: 16),
                _buildTextFormField(clinicNameController, "Clinic Name"),
                const SizedBox(height: 16),
                
                // Specialty Dropdown
                Text("Specialty", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSpecialty,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: const Text("Select Specialty"),
                  onChanged: (value) {
                    setState(() {
                      selectedSpecialty = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a specialty';
                    }
                    return null;
                  },
                  items: specialties.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                _buildTextFormField(
                  staffController,
                  'Number of Doctors',
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Address & Contact Section
                _buildSectionTitle('Address & Contact'),
                const SizedBox(height: 16),
                _buildTextFormField(cityController, "City"),
                const SizedBox(height: 16),
                _buildTextFormField(addressController, "Address"),
                const SizedBox(height: 16),
                _buildTextFormField(
                  mapsLinkController,
                  'Google Maps Link (so people can find your clinic)',
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final uri = Uri.parse('https://www.google.com/maps');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text("Open Google Maps"),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  phoneController,
                  "Phone Number",
                  inputType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 24),

                // Working Hours Section
                _buildSectionTitle('Working Hours'),
                const SizedBox(height: 16),
                _buildTimePickerRow("Opening Time", (minutes) {
                  openingMinutes = minutes;
                }),
                const SizedBox(height: 16),
                _buildTimePickerRow("Closing Time", (minutes) {
                  closingMinutes = minutes;
                }),
                const SizedBox(height: 16),
                _buildTimePickerRow("Break Start Time", (minutes) {
                  breakStartMinutes = minutes;
                }),
                const SizedBox(height: 16),
                _buildTimePickerRow("Break End Time", (minutes) {
                  breakEndMinutes = minutes;
                }),
                const SizedBox(height: 24),
                
                Text(
                  "Working Days",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final dayName = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][i];
                    final selected = workingDays.contains(i);
                    return FilterChip(
                      label: Text(dayName),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            workingDays.add(i);
                          } else {
                            workingDays.remove(i);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Profile Image Section
                _buildSectionTitle('Clinic Image'),
                const SizedBox(height: 16),
                Center(
                  child: _buildAvatarPicker(profileImage, (xFile) {
                    setState(() => profileImage = xFile);
                  }),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TODO: MOVE TO SHARED UI HELPERS FILE
  // Builds a section title widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // TODO: MOVE TO VALIDATION SERVICE FILE
  // Validates email format
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final pattern = RegExp(r'^\S+@\S+\.\S+$');
    if (!pattern.hasMatch(value.trim())) return 'Invalid email';
    return null;
  }

  // TODO: MOVE TO VALIDATION SERVICE FILE
  // Validates password strength
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 6) return 'Password too short';
    return null;
  }

  // TODO: MOVE TO VALIDATION SERVICE FILE
  // Validates phone number format
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final pattern = RegExp(r'^[0-9]+$');
    if (!pattern.hasMatch(value.trim())) return 'Invalid number';
    return null;
  }

  // TODO: MOVE TO WIDGET/UI COMPONENTS FILE
  // Reusable text form field builder
  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? inputType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType ?? TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
    );
  }

  // TODO: MOVE TO WIDGET/UI COMPONENTS FILE
  // Builds a time picker row with label and button
  Widget _buildTimePickerRow(
    String label,
    void Function(int minutesSinceMidnight) onSelected,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton.icon(
          icon: const Icon(Icons.access_time),
          label: const Text("Select"),
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              final int minutes = picked.hour * 60 + picked.minute;
              onSelected(minutes);
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  // TODO: MOVE TO WIDGET/UI COMPONENTS FILE
  // Builds an avatar/image picker widget
  Widget _buildAvatarPicker(XFile? image, Function(XFile) onPick) {
    return GestureDetector(
      onTap: () async {
        XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80, // Built-in compression
        );
        if (picked != null) onPick(picked);
      },
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        backgroundImage: image != null ? FileImage(File(image.path)) : null,
        child: image == null
            ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
            : null,
      ),
    );
  }

  // TODO: MOVE TO CLINIC SERVICE FILE
  // Saves the profile data to Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required business fields
    if (clinicNameController.text.trim().isEmpty ||
        selectedSpecialty == null ||
        cityController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required information")),
      );
      return;
    }

    // Validate time logic
    if (openingMinutes == null ||
        closingMinutes == null ||
        openingMinutes! >= closingMinutes!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set valid opening and closing times")),
      );
      return;
    }

    if (breakStartMinutes != null &&
        breakEndMinutes != null &&
        !(openingMinutes! <= breakStartMinutes! &&
            breakStartMinutes! < breakEndMinutes! &&
            breakEndMinutes! <= closingMinutes!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Break time is invalid")),
      );
      return;
    }

    if (workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one working day")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {

      await ClinicFirestore().updateClinic(
                      nameController.text.trim(),
                      clinicNameController.text.trim(),
                      mapsLinkController.text.trim(),
                      1,
                      cityController.text.trim(),
                      workingDays,
                      phoneController.text.trim(),
                      selectedSpecialty!,
                      staffController.text.trim(),
                      openingMinutes!,
                      closingMinutes!,
                      breakStartMinutes!,
                      breakEndMinutes!,
                      addressController.text.trim(),
       );

      // Temporary placeholder until you implement update logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}