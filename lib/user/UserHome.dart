import 'package:eyadati/NavBarUi/UserNavBar.dart';
import 'package:flutter/material.dart';

class Userhome extends StatelessWidget {
  const Userhome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const UserFloatingBottomNavBar());
  }
}
