import 'package:flutter/material.dart';

// TODO: Move these imports to a centralized service locator or appropriate service files
import 'package:eyadati/user/user_firestore.dart';

class UserEditProfilePage extends StatefulWidget {
  // TODO: Pass existing user data map to pre-fill the form
  final String? userId;

  const UserEditProfilePage({super.key, this.userId});

  @override
  _UserEditProfilePageState createState() => _UserEditProfilePageState();
}

class _UserEditProfilePageState extends State<UserEditProfilePage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load existing user data from Firestore
    // _loadUserData();
  }

  // TODO: MOVE TO USER SERVICE FILE
  // Future<void> _loadUserData() async {
  //   if (widget.userId != null) {
  //     // Fetch user document from Firestore
  //     // Update all controllers with existing data
  //     // Example:
  //     // final userData = await UserFirestore().getUser(widget.userId!);
  //     // nameController.text = userData['name'] ?? '';
  //     // emailController.text = userData['email'] ?? '';
  //     // phoneController.text = userData['phone'] ?? '';
  //     // cityController.text = userData['city'] ?? '';
  //   }
  // }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),
                _buildTextFormField(nameController, "Full Name"),
                const SizedBox(height: 16),
                _buildTextFormField(
                  emailController,
                  "Email",
                  validator: _validateEmail,
                  readOnly: true, // Email typically can't be changed easily
                  helperText: "Contact support to change email",
                ),
                const SizedBox(height: 24),

                // Contact Information Section
                _buildSectionTitle('Contact Information'),
                const SizedBox(height: 16),
                _buildTextFormField(
                  phoneController,
                  "Phone Number",
                  inputType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(cityController, "City"),
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
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
  // Validates password strength (kept for potential password change feature)
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
  // Reusable text form field builder with enhanced options
  Widget _buildTextFormField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? inputType,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType ?? TextInputType.text,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
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

  // TODO: MOVE TO USER SERVICE FILE
  // Saves the profile data to Firestore
  Future<void> _saveProfile() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await UserFirestore().updateUser(
        nameController.text.trim(),
        phoneController.text.trim(),
        cityController.text.trim(),
      );

      // Temporary placeholder until you implement update logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
