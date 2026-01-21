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
                title: Text("edit_profile".tr()),
                leading: Icon(LucideIcons.user),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return UserEditProfilePage();
                  },
                ),
              ),
              SettingsTile.navigation(
                title: Text("language".tr()),
                leading: Icon(LucideIcons.globe),
                onPressed: (_) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("language".tr()),
                        content: StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            Locale selectedLocale = context.locale;
                            
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ignore: deprecated_member_use
                                RadioListTile<Locale>(
                                  title: const Text('English'),
                                  value: const Locale('en'),
                                  // ignore: deprecated_member_use
                                  groupValue: selectedLocale,
                                  // ignore: deprecated_member_use
                                  onChanged: (Locale? value) async {
                                    if (value != null) {
                                      setState(() {
                                        selectedLocale = value;
                                      });
                                      await context.setLocale(value);
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                                // ignore: deprecated_member_use
                                RadioListTile<Locale>(
                                  title: const Text('Français'),
                                  value: const Locale('fr'),
                                  // ignore: deprecated_member_use
                                  groupValue: selectedLocale,
                                  // ignore: deprecated_member_use
                                  onChanged: (Locale? value) async {
                                    if (value != null) {
                                      setState(() {
                                        selectedLocale = value;
                                      });
                                      await context.setLocale(value);
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                                // ignore: deprecated_member_use
                                RadioListTile<Locale>(
                                  title: const Text('العربية'),
                                  value: const Locale('ar'),
                                  // ignore: deprecated_member_use
                                  groupValue: selectedLocale,
                                  // ignore: deprecated_member_use
                                  onChanged: (Locale? value) async {
                                    if (value != null) {
                                      setState(() {
                                        selectedLocale = value;
                                      });
                                      await context.setLocale(value);
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('close'.tr()),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              SettingsTile.switchTile(
                onToggle: (value) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme();
                },
                initialValue: Provider.of<ThemeProvider>(context).isDarkMode,
                title: Text("dark_mode".tr()),
                leading: Icon(LucideIcons.moon),
              ),
              SettingsTile.navigation(
                title: Text("log_out".tr()),
                leading: Icon(LucideIcons.globe),
                onPressed: (context) async {
                  // Added async
                  await FirebaseAuth.instance.signOut(); // Await signOut
                  if (!context.mounted) return; // Check context after await
                  Navigator.pushAndRemoveUntil(
                    // Use pushAndRemoveUntil
                    context,
                    MaterialPageRoute(builder: (ctx) => intro(ctx)),
                    (route) => false, // Clear all previous routes
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
