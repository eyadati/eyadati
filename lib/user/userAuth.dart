import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/user/UserHome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// CREATING NEW USER
class Userauth {
  Future<void> createUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        debugPrint('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password provided for that user.');
      }
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
          title: Text("Login"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: loginEmail,
                decoration: InputDecoration(
                  labelText: "Email".tr(),
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
                  labelText: "Password".tr(),
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
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final cred = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                        email: loginEmail.text.trim(),
                        password: loginPassword.text.trim(),
                      );
                  if (cred.user != null) {
                    Navigator.pop(ctx); // close modal

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Userhome()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  debugPrint("Login error: $e");
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Login failed".tr())));
                }
              },
              child: Text("Login"),
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
