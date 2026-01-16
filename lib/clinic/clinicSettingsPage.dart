import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/chargili/paiment.dart';
import 'package:eyadati/clinic/clinicEditeProfile.dart';
import 'package:eyadati/flow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:provider/provider.dart';
import 'package:eyadati/Themes/ThemeProvider.dart';

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
                title: Text("edit_profile".tr()),
                leading: Icon(LucideIcons.user),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ClinicEditProfilePage();
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
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<Locale>(
                              title: const Text('English'),
                              value: const Locale('en'),
                              groupValue: context.locale,
                              onChanged: (Locale? value) async {
                                if (value != null) {
                                  await context.setLocale(value);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            RadioListTile<Locale>(
                              title: const Text('Français'),
                              value: const Locale('fr'),
                              groupValue: context.locale,
                              onChanged: (Locale? value) async {
                                if (value != null) {
                                  await context.setLocale(value);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            RadioListTile<Locale>(
                              title: const Text('العربية'),
                              value: const Locale('ar'),
                              groupValue: context.locale,
                              onChanged: (Locale? value) async {
                                if (value != null) {
                                  await context.setLocale(value);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
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
              SettingsTile.navigation(
                title: Text("subscription".tr()),
                leading: Icon(LucideIcons.user),
                onPressed: (_) => showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return SubscribeScreen();
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
                title: Text("dark_mode".tr()),
                leading: Icon(LucideIcons.moon),
              ),
              SettingsTile.navigation(
                title: Text("qr_code".tr()),
                leading: Icon(LucideIcons.qrCode),
                onPressed: (_) {
                  final clinicUid = FirebaseAuth.instance.currentUser?.uid;
                  if (clinicUid != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("qr_code".tr()),
                        content: SizedBox(
                          width: 250,
                          height: 250,
                          child: Center(
                            child: QrImageView(
                              data: clinicUid,
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('close'.tr()),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              SettingsTile.navigation(
                title: Text("log_out".tr()),
                leading: Icon(LucideIcons.globe),
                onPressed: (_) {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (ctx) => intro(ctx)),
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
