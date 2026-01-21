import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eyadati/utils/network_helper.dart';

// CREATING NEW USER
class Userauth {
  Future<String?> createUser(
    String email,
    String password,
  ) async {
    if (!await NetworkHelper.checkInternetConnectivity()) {
      return "no_internet_connection".tr();
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "error_generic".tr();
    }
  }

  // USER LOGIN
  Future<void> userLogIn(BuildContext context) async {
    final TextEditingController loginEmail = TextEditingController();
    final TextEditingController loginPassword = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("login".tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: loginEmail,
                decoration: InputDecoration(
                  labelText: "email".tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: loginPassword,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "password".tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("cancel".tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!await NetworkHelper.checkInternetConnectivity()) {
                  return;
                }
                try {
                  final cred = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                        email: loginEmail.text.trim(),
                        password: loginPassword.text.trim(),
                      );
                  if (cred.user != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx); // close modal
                    if (!context.mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Userhome()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  debugPrint("Login error: $e");
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("login_failed".tr())));
                }
              },
              child: Text("login".tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> userLogOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
