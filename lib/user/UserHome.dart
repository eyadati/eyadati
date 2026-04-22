import 'package:eyadati/NavBarUi/UserNavBar.dart';
import 'package:eyadati/webUI/patient_web_ui.dart';
import 'package:eyadati/webUI/web_ui_helper.dart';
import 'package:eyadati/NavBarUi/user_nav_bar_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  final _provider = UserNavBarProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Builder(builder: (context) {
        if (WebUIHelper.isLargeScreen(context)) {
          return const PatientWebUI();
        }
        return const UserFloatingBottomNavBar();
      }),
    );
  }
}
