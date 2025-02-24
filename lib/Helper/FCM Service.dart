import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http; // Add this import

class FCMService {
  static const String _fcmURL = 'https://fcm.googleapis.com/v1/projects/split-wise-891b7/messages:send'; // Your project ID

  static Future<String> _getAccessToken() async {
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      jsonDecode(await rootBundle.loadString('assets/split-wise-891b7-firebase-adminsdk-fbsvc-48c6733945.json')),
    );
    final List<String> scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final AuthClient authClient = await clientViaServiceAccount(serviceAccountCredentials, scopes);
    return authClient.credentials.accessToken.data;
  }

  static Future<void> sendPushNotification(String deviceToken, String title, String body) async {
    try {
      String accessToken = await _getAccessToken();
      final Map<String, dynamic> payload = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "status": "done"
          },
          "android": {
            "notification": {
              "sound": "default",
              "channel_id": "settleup_notifications",
            }
          }
        }
      };
      final response = await http.post(
        Uri.parse(_fcmURL),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        log('Push notification sent successfully.');
      } else {
        log('Failed to send notification. Response: ${response.body}');
      }
    } catch (e) {
      log('Error sending push notification: $e');
    }
  }
}