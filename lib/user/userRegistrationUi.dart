import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/userAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ================ PROVIDER ================

class UserOnboardingProvider extends ChangeNotifier {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  UserOnboardingProvider({required this.auth, required this.firestore});

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  String? selectedCity;
  bool isLoading = false;
  String? error;

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

  void selectCity(String? city) {
    selectedCity = city;
    notifyListeners();
  }

  Future<void> submitRegistration(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCity == null) {
      error = "Please select a city".tr();
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Create user
      await Userauth().createUser(
        emailController.text.trim(),
        passwordController.text,
      );

      // Add user data
      await firestore.collection("users").doc(auth.currentUser!.uid).set({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "city": selectedCity,
        "email": emailController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Navigate to home
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Userhome()),
          (route) => false,
        );
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}

// ================ UI WIDGET ================

class UserOnboardingPages extends StatelessWidget {
  const UserOnboardingPages({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserOnboardingProvider(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
      child: const _UserOnboardingContent(),
    );
  }
}

class _UserOnboardingContent extends StatelessWidget {
  const _UserOnboardingContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("user_registration".tr())),
      body: Consumer<UserOnboardingProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: provider.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // All fields in one column
                  _buildTextFormField(
                    provider.nameController,
                    "full_name".tr(),
                    provider,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    provider.emailController,
                    "email".tr(),
                    provider,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    provider.passwordController,
                    "password".tr(),
                    provider,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    provider.phoneController,
                    "phone_number".tr(),
                    provider,
                    inputType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 16),

                  _buildCityDropdown(context, provider),
                  const SizedBox(height: 24),

                  // Error message
                  if (provider.error != null) ...[
                    Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.submitRegistration(context),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text("finish".tr()),
                  ),

                  const SizedBox(height: 16),

                  // Login link
                  TextButton(
                    onPressed: () => Userauth().userLogIn(context),
                    child: Text('already have account'.tr()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    UserOnboardingProvider provider, {
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
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'required_field'.tr();
            }
            return null;
          },
    );
  }

  Widget _buildCityDropdown(
    BuildContext context,
    UserOnboardingProvider provider,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedCity,
      decoration: InputDecoration(
        labelText: "city".tr(),
        prefixIcon: const Icon(Icons.location_city),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: Text("select_city".tr()),
      items: provider.algerianCities.map((city) {
        return DropdownMenuItem(value: city, child: Text(city));
      }).toList(),
      onChanged: (value) => provider.selectCity(value),
      validator: (value) {
        if (value == null) return 'city_required'.tr();
        return null;
      },
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'required_field'.tr();
    final pattern = RegExp(r'^\S+@\S+\.\S+$');
    if (!pattern.hasMatch(value.trim())) return 'invalid_email'.tr();
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'required_field'.tr();
    if (value.length < 6) return 'password_too_short'.tr();
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'required_field'.tr();
    final pattern = RegExp(r'^[0-9]+$');
    if (!pattern.hasMatch(value.trim())) return 'invalid_phone'.tr();
    return null;
  }
}
