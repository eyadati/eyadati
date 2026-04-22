import 'package:eyadati/NavBarUi/clinic_nav_bar.dart';
import 'package:eyadati/webUI/clinic_web_ui.dart';
import 'package:eyadati/webUI/web_ui_helper.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Clinichome extends StatefulWidget {
  const Clinichome({super.key});

  @override
  State<Clinichome> createState() => _ClinichomeState();
}

class _ClinichomeState extends State<Clinichome> {
  CliniNavBarProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider == null) {
      final clinicUid = FirebaseAuth.instance.currentUser!.uid;
      _provider = CliniNavBarProvider(clinicUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CliniNavBarProvider>.value(
      value: _provider!,
      child: Builder(builder: (context) {
        if (WebUIHelper.isLargeScreen(context)) {
          return const ClinicWebUI();
        }
        return const FloatingBottomNavBar();
      }),
    );
  }
}
