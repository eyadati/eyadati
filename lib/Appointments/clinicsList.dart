import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Manages clinic list state with pagination and efficient data fetching
class ClinicsListProvider extends ChangeNotifier {
  final FirebaseFirestore firestore;
  final String city;
  
  List<Map<String, dynamic>> _clinics = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  List<Map<String, dynamic>> get clinics => _clinics;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  ClinicsListProvider({
    required this.city,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance {
    loadClinics();
  }

  /// Loads clinics with pagination
  Future<void> loadClinics() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query = firestore
          .collection("clinics")
          .where("city", isEqualTo: city.toLowerCase())
          .orderBy("name") // Required for pagination
          .limit(20);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        return;
      }

      _lastDocument = snapshot.docs.last;
      
     final newClinics = snapshot.docs.map((doc) {
  final data = doc.data();
  if (data is Map<String, dynamic>) {
    return <String, dynamic>{"uid": doc.id, ...data};
  }
  return {"uid": doc.id};
}).toList();

      _clinics.addAll(newClinics);
    } catch (e) {
      debugPrint("Error loading clinics: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the clinic list
  Future<void> refresh() async {
    _clinics.clear();
    _lastDocument = null;
    _hasMore = true;
    await loadClinics();
  }
}

/// Main widget for displaying available clinics
class Clinicslist extends StatelessWidget {
  final String? city;
  
  const Clinicslist({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    if (city == null || city!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No city specified")),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ClinicsListProvider(city: city!),
      child: Scaffold(
        appBar: AppBar(title: const Text("Available Clinics"), centerTitle: true),
        body: const _ClinicsListView(),
      ),
    );
  }
}

/// Clinic list view with infinite scroll
class _ClinicsListView extends StatelessWidget {
  const _ClinicsListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicsListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.clinics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!provider.isLoading && provider.clinics.isEmpty) {
          return const Center(child: Text("No clinics found in your city"));
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            itemCount: provider.clinics.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Load more when reaching end
              if (index >= provider.clinics.length) {
                if (!provider.isLoading) {
                  provider.loadClinics();
                }
                return const Center(child: CircularProgressIndicator());
              }

              final clinic = provider.clinics[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: clinic["picUrl"] != null
                        ? NetworkImage(clinic["picUrl"])
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: clinic["picUrl"] == null
                        ? const Icon(Icons.local_hospital, size: 75)
                        : null,
                  ),
                  title: Text(
                    clinic["name"] ?? "Unknown Clinic",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    clinic["address"] ?? "No address available",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SlotsUi(clinic: clinic),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}