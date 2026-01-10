import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/clinic/clinicHome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eyadati/utils/network_helper.dart';

class Clinicauth {
  final auth = FirebaseAuth.instance;
  Future<void> clinicAccount(
    String email,
    String password,
    BuildContext context,
  ) async {
    if (!await NetworkHelper.checkInternetConnectivity(context)) {
      return;
    }
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> clinicLoginIn(BuildContext context) async {
    final TextEditingController loginEmail = TextEditingController();
    final TextEditingController loginPassword = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Login".tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: loginEmail,
                decoration: InputDecoration(labelText: "Email".tr()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: loginPassword,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password".tr()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel".tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!await NetworkHelper.checkInternetConnectivity(ctx)) {
                  return;
                }
                try {
                  final cred = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                        email: loginEmail.text.trim(),
                        password: loginPassword.text.trim(),
                      );
                  if (cred.user != null) {
                    Navigator.pop(ctx); // close modal
                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Clinichome()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  debugPrint("Login error: $e");
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Login failed".tr())));
                }
              },
              child: Text("Login".tr()),
            ),
          ],
        );
      },
    );
  }
}
