import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/clinic/clinicRegisterUi_widgets.dart';
import 'package:eyadati/clinic/clinic_login_page.dart';
import 'package:flutter/material.dart';

class ClinicAuthSelectionScreen extends StatelessWidget {
  const ClinicAuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('clinic_authentication'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClinicLoginPage(),
                    ),
                  );
                },
                child: Text('already_have_account_login'.tr()),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClinicOnboardingPages(),
                    ),
                  );
                },
                child: Text('create_new_account'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
