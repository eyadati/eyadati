import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/chargili/paiment.dart';
import 'package:eyadati/clinic/clinicEditeProfile.dart';
import 'package:eyadati/flow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClinicsettingProvider extends ChangeNotifier {}

class Clinicsettings extends StatelessWidget {
  const Clinicsettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile.navigation(
                title: Text("Edit Profile".tr()),
                leading: Icon(LucideIcons.user),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ClinicEditProfilePage();
                  },
                ),
              ),
              SettingsTile.navigation(
                title: Text("Language".tr()),
                leading: Icon(LucideIcons.globe),
                onPressed: (_) => showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(title: Text("Language".tr()));
                  },
                ),
              ),
              SettingsTile.navigation(
                title: Text("Subscription".tr()),
                leading: Icon(LucideIcons.user),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return SubscribeScreen();
                  },
                ),
              ),
              SettingsTile.switchTile(
                onToggle: (_) {},
                initialValue: true,
                title: Text("Dark mode".tr()),
                leading: Icon(LucideIcons.moon),
              ),
              SettingsTile.navigation(
                title: Text("log out".tr()),
                leading: Icon(LucideIcons.globe),
                onPressed: (_) {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => FutureBuilder<Widget>(
                        future: decidePage(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return Container(
                            child:
                                snapshot.data ??
                                Text('Something went wrong'.tr()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
