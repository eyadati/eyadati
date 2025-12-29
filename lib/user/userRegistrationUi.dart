import 'package:eyadati/user/UserHome.dart';
import 'package:eyadati/user/userAuth.dart';
import 'package:eyadati/user/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserOnboardingPages extends StatefulWidget {
  const UserOnboardingPages({super.key});

  @override
  _UserOnboardingPagesState createState() => _UserOnboardingPagesState();
}

class _UserOnboardingPagesState extends State<UserOnboardingPages> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final PageController pageController = PageController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      physics: NeverScrollableScrollPhysics(),
      children: [buildSignupPage(), buildUserInfoPage()],
    );
  }

  Widget buildSignupPage() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            _buildTextFormField(nameController, "Full Name"),
            SizedBox(height: 16),
            _buildTextFormField(
              emailController,
              "Email",
              validator: _validateEmail,
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              passwordController,
              "Password",
              obscureText: true,
              validator: _validatePassword,
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text("Next"),
            ),

            Center(
              child: TextButton(
                onPressed: () =>Userauth().userLogIn(context),
                child: Text('Already have an account?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text("User Info", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 24),
          _buildTextFormField(
            phoneController,
            "Phone Number",
            inputType: TextInputType.phone,
            validator: _validatePhone,
          ),
          SizedBox(height: 16),
          _buildTextFormField(cityController, "City"),
          Spacer(),
          ElevatedButton(
            onPressed: () async {
              if (phoneController.text.trim().isEmpty ||
                  cityController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please fill all required fields")),
                );
                return;
              }
              await Userauth().createUser(
                emailController.text,
                passwordController.text,
              );
              //user future builder
              await UserFirestore().addUser(
                nameController.text.trim(),
                phoneController.text.trim(),
                cityController.text.trim(),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Userhome()),
              );
            },
            child: Text("Finish"),
          ),
        ],
      ),
    );
  }

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
              return 'Required';
            }
            return null;
          },
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final pattern = RegExp(r'^\S+@\S+\.\S+$');
    if (!pattern.hasMatch(value.trim())) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 6) return 'Password too short';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final pattern = RegExp(r'^[0-9]+$');
    if (!pattern.hasMatch(value.trim())) return 'Invalid number';
    return null;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    cityController.dispose();
    super.dispose();
  }
}
