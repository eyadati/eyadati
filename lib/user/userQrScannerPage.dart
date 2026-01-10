import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/NavBarUi/UserNavBar.dart';

class UserQrScannerPage extends StatefulWidget {
  const UserQrScannerPage({super.key});

  @override
  State<UserQrScannerPage> createState() => _UserQrScannerPageState();
}

class _UserQrScannerPageState extends State<UserQrScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    cameraController.stop(); // Ensure camera is stopped initially
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('scan_qr_code'.tr()),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(
              _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
            ),
            onPressed: () {
              setState(() {
                _isFrontCamera = !_isFrontCamera;
              });
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (!_screenOpened) {
            _screenOpened = true;
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? clinicUid = barcodes.first.rawValue;
              if (clinicUid != null) {
                _foundBarcode(context, clinicUid);
              }
            }
          }
        },
      ),
    );
  }

  void _foundBarcode(BuildContext context, String clinicUid) async {
    debugPrint('Scanned clinic UID: $clinicUid');
    // For now, we assume the scanned QR code is a clinic UID
    // In a real app, you might want to validate this UID or fetch clinic data first

    try {
      final provider = Provider.of<UserNavBarProvider>(context, listen: false);
      // First, check if the clinic exists and is valid before adding to favorites
      // For this example, we'll assume it's valid.
      // In a real application, you would query Firestore for the clinic's existence.

      // Simulate fetching clinic data from Firestore
      final clinicDoc = await Provider.of<UserNavBarProvider>(context, listen: false)
          .firestore
          .collection('clinics')
          .doc(clinicUid)
          .get();

      if (!clinicDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('clinic_not_found'.tr())),
        );
        Navigator.of(context).pop(); // Go back to favorites screen
        return;
      }
      
      final Map<String, dynamic> actualClinicData = clinicDoc.data()!;


      await provider.toggleFavorite(clinicUid, actualClinicData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to favorites'.tr())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to favorites: $e'.tr())),
      );
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // Go back to favorites screen
      }
    }
  }
}