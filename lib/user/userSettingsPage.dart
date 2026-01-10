import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/Themes/ThemeProvider.dart'; // Import ThemeProvider
import 'package:eyadati/flow.dart';
import 'package:eyadati/user/userEditProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserSettingProvider extends ChangeNotifier {}

class UserSettings extends StatelessWidget {
  const UserSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SettingsList(
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile.navigation(
                title: Text("Edit Profile".tr()),
                leading: Icon(LucideIcons.user),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return UserEditProfilePage();
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

              SettingsTile.switchTile(
                onToggle: (value) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                },
                initialValue: Provider.of<ThemeProvider>(context).isDarkMode,
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
                        future: decidePage(context),
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
