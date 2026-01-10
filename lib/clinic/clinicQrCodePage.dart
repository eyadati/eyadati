import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class ClinicQrCodePage extends StatefulWidget {
  const ClinicQrCodePage({super.key});

  @override
  State<ClinicQrCodePage> createState() => _ClinicQrCodePageState();
}

class _ClinicQrCodePageState extends State<ClinicQrCodePage> {
  String? clinicUid;

  @override
  void initState() {
    super.initState();
    clinicUid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('qr_code'.tr()),
      ),
      body: Center(
        child: clinicUid == null
            ? CircularProgressIndicator()
            : QrImageView(
                data: clinicUid!,
                version: QrVersions.auto,
                size: 200.0,
              ),
      ),
    );
  }
}
