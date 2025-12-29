import 'package:eyadati/user/UserHome.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eyadati/Appointments/booking_logic.dart';

class SlotsUi extends StatefulWidget {
  final Map<String, dynamic> clinic; // Clinic data from previous screen

  const SlotsUi({super.key, required this.clinic});

  @override
  State<SlotsUi> createState() => _SlotsUiState();
}

class _SlotsUiState extends State<SlotsUi> {
  DateTime selectedDate = DateTime.now();
  List<DateTime> availableSlots = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final bookingLogic = BookingLogic();
      final slots = await bookingLogic.generateSlots(
        selectedDate, 
        widget.clinic["uid"],
      );
      
      setState(() {
        availableSlots = slots;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load slots: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      print(selectedDate);
      _loadSlots();
    }
  }

  Future<void> _bookSlot(DateTime slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Text(
          "Book appointment on ${selectedDate.toString().split(' ')[0]} at ${slot.hour}:00?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final bookingLogic = BookingLogic();
        final user = FirebaseAuth.instance.currentUser;
        
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please log in to book")),
          );
          return;
        }
       
        await bookingLogic.bookAppointment(
          widget.clinic["uid"], 
          slot,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Appointment booked!")),
        );
        
        // Refresh slots after booking
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>Userhome()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Booking failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic["name"] ?? "Clinic Slots"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date picker header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date: ${selectedDate.toString().split(' ')[0]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Change"),
                ),
              ],
            ),
          ),
          
          // Slots list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : availableSlots.isEmpty
                        ? const Center(child: Text("No available slots"))
                        : ListView.builder(
                            itemCount: availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = availableSlots[index];
                              final timeString = 
                                  "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString()}";
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.access_time,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    timeString,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(
                                    slot.hour < 12 ? "Morning" : 
                                    slot.hour < 17 ? "Afternoon" : "Evening",
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () => _bookSlot(slot),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}