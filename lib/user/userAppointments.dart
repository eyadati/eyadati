import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/user/user_appointments.dart';
import 'package:eyadati/Appointments/clinicsList.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/FCM/notificationsService.dart';

// ADD THIS: Provider using Firestore's built-in cache
class ClinicsProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = true;
  String? _userCity;

  List<Map<String, dynamic>> get clinics => _clinics;
  bool get isLoading => _isLoading;
  String? get userCity => _userCity;

  Future<void> initialize() async {
    await fetchClinics();
  }

  // Firestore handles caching automatically with GetOptions.source
  Future<void> fetchClinics({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await firestore
          .collection('users')
          .doc(auth.currentUser?.uid)
          .get();
      _userCity = userDoc.data()?['city'];
      debugPrint(userCity);

      if (_userCity == null || _userCity!.isEmpty) {
        throw Exception('City not set');
      }

      final source = forceRefresh ? Source.server : Source.cache;

      final snapshot = await firestore
          .collection('clinics')
          .where('city', isEqualTo: _userCity)
          .get(GetOptions(source: source));

      // If cache empty, fetch from server
      if (snapshot.docs.isEmpty && !forceRefresh) {
        return fetchClinics(forceRefresh: true);
      }

      _clinics = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class UserAppointments extends StatefulWidget {
  const UserAppointments({super.key});

  @override
  State<UserAppointments> createState() => _UserAppointmentsState();
}

class _UserAppointmentsState extends State<UserAppointments> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = ClinicsProvider();
            provider.initialize(); // Fetch on start
            return provider;
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text("Hello Oussama".tr()),
          actions: [
            IconButton(
              onPressed: () => ClinicFilterBottomSheet.show(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ),

        body: Consumer<ClinicsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading)
              return const Center(child: CircularProgressIndicator());

            return Center(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Expanded(child: Appointmentslistview()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
