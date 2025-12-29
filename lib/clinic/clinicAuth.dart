import 'package:eyadati/clinic/clinicHome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Clinicauth {
  final auth = FirebaseAuth.instance;
  Future<void> clinicAccount(String email, String password) async {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> ClinicLoginIn(BuildContext context) async {
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
                decoration: InputDecoration(labelText: "Email"),
              ),
              SizedBox(height: 12),
              TextField(
                controller: loginPassword,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
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
                      MaterialPageRoute(builder: (_) => Clinichome()),
                      (route)=>false
                    );
                  }
                } catch (e) {
                  debugPrint("Login error: $e");
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Login failed")));
                }
              },
              child: Text("Login"),
            ),
          ],
        );
      },
    );
  }
}
