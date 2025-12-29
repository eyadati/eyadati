import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyadati/Appointments/booking_logic.dart';
import 'package:eyadati/Appointments/slotsUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Clinicslist extends StatefulWidget {
 const Clinicslist({super.key,required this.city});
 final String? city;
  @override
  State<Clinicslist> createState() => _ClinicslistState();
}

class _ClinicslistState extends State<Clinicslist> {
  late Future<List<Map<String, dynamic>>> _clinicsFuture;

  @override
  void initState() {
    super.initState();
    // ✅ Pre-load future to avoid rebuilds
    _clinicsFuture = _loadClinics();
    print(widget.city);
    print(_clinicsFuture);
  }

  Future<List<Map<String, dynamic>>> _loadClinics() async {
    try {
      
      return await BookingLogic().cityClinics(widget.city!);
      
    } catch (e) {
      print("Error loading clinics: $e");
      return [];
    }

  }

  Future<String> getCity() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // ✅ Add null safety check
    if (auth.currentUser == null) return "";
    
    final userDoc = await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get();
    
    return userDoc.data()?["city"]?.toString() ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Clinics"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _clinicsFuture,
        builder: (context, snapshot) {
          // ✅ Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // ✅ Handle errors
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          // ✅ Handle empty data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No clinics found in your city"));
          }

          final clinics = snapshot.data!;

          return ListView.builder(
            itemCount: clinics.length,
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  tileColor: ThemeData().cardColor,
                  // ✅ Leading avatar with Supabase image
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
                  
                  // ✅ Title with clinic name
                  title: Text(
                    clinic["name"] ?? "Unknown Clinic",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  
                  // ✅ Subtitle with address
                  subtitle: Text(
                    clinic["address"] ?? "No address available",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // ✅ Navigate to booking page with clinic info and slots and booking function
                  onTap: () {
                   showModalBottomSheet(context: context, builder: (_){
                    return SlotsUi(clinic: clinic);
                   });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}