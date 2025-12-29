import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final supabase = Supabase.instance.client;
  
  // FCM token now comes from your local storage (SharedPreferences, etc.)
  // which you previously saved when the token was generated

  Future<void> sendDirectNotification({
    required String fcmToken, // Pass the token directly
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'fcm_notifications',
        body: {
          'token': fcmToken,      // Direct token from client
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      print('✅ Notification sent: ${response.data}');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }
}