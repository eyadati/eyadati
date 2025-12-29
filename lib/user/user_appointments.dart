import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadati/FCM/notificationsService.dart';
import 'package:eyadati/user/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';

class Appointmentslistview extends StatefulWidget {
  const Appointmentslistview({super.key});

  @override
  State<Appointmentslistview> createState() => _AppointmentslistviewState();
}

class _AppointmentslistviewState extends State<Appointmentslistview> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, dynamic>> _shopCache = {};

  Future<Map<String, dynamic>?> _getShopData(String ownerId) async {
    if (_shopCache.containsKey(ownerId)) {
      return _shopCache[ownerId];
    }
    final doc = await firestore.collection("clinics").doc(ownerId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        _shopCache[ownerId] = data;
        return data;
      }
    }
    return null;
  }

  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
    final weekday = DateFormat('EEEE').format(date);
    final formatted = DateFormat('M/d/yyyy').format(date);
    return "$weekday $formatted";
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Center(child: Text(tr("please_login")));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection("users")
          .doc(userId)
          .collection("appointments")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(tr("no appointments")));
        }

        final appointments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final data = appointments[index].data() as Map<String, dynamic>;
            final ownerId = data["clinicUid"] ?? "";
            final slot = data["date"] as Timestamp?;
            if (slot == null) return const SizedBox();

            return FutureBuilder<Map<String, dynamic>?>(
              future: _getShopData(ownerId),
              builder: (context, shopSnapshot) {
                if (!shopSnapshot.hasData) {
                  return ListTile(title: Text(tr("loading_shop")));
                }

                final shopData = shopSnapshot.data!;
                final shopName = shopData["name"] ?? tr("unknown_shop");
                final address = shopData["adress"] ?? tr("unknown_address");

                return Slidable(
                  key: ValueKey(data['id']),
                  endActionPane: ActionPane(
                    motion: ScrollMotion(),
                    children: [
                      Container(
                        height: 80,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: () async {
                              await UserFirestore().cancelAppointment(
                                data["id"],
                                data["userUid"],
                                context,
                              );
                              await NotificationService()
                                  .sendDirectNotification(
                                    fcmToken: shopData['FCM'],
                                    title: 'appointment cancelled'.tr(),
                                    body: 'the appointment at ${data['date']} got cancelled'.tr(),
                                  );
                            },
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      trailing: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.arrow_right, size: 35),
                      ),
                      contentPadding: const EdgeInsets.all(8),
                      title: SizedBox(
                        height: 35,
                        child: Row(
                          children: [
                            Text("${tr("clinic")}: "),
                            Expanded(
                              child: Marquee(
                                text: shopName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                velocity: 25,
                                blankSpace: 50,
                                pauseAfterRound: const Duration(seconds: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 30,
                            child: Row(
                              children: [
                                Text("${tr("address")}: "),
                                Expanded(
                                  child: Marquee(
                                    text: address,
                                    style: const TextStyle(fontSize: 14),
                                    velocity: 15,
                                    blankSpace: 40,
                                    pauseAfterRound: const Duration(seconds: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(slot),
                            style: const TextStyle(fontSize: 14),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(slot),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await launchUrl(
                                    mode: LaunchMode.platformDefault,
                                    Uri.parse(
                                      "https://maps.app.goo.gl/rJq6C7XsEqevUUNg9",
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.location_on,
                                  size: 40,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
