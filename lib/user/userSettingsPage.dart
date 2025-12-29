import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/flow.dart';
import 'package:eyadati/user/userEditProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

class userSettingProvider extends ChangeNotifier {}

class UserSettings extends StatelessWidget {
  const UserSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsList(
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile.navigation(
                title: Text("Edit Profile".tr()),
                leading: Icon(Icons.person),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return UserEditProfilePage();
                  },
                ),
              ),
              SettingsTile.navigation(
                title: Text("Language".tr()),
                leading: Icon(Icons.language),
                onPressed: (_) => showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(title: Text("Language".tr()));
                  },
                ),
              ),

              SettingsTile.switchTile(
                onToggle: (_) {},
                initialValue: true,
                title: Text("Dark mode".tr()),
                leading: Icon(Icons.dark_mode),
              ),
              SettingsTile.navigation(
                title: Text("log out".tr()),
                leading: Icon(Icons.language),
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
