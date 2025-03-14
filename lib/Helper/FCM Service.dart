import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static const String _fcmURL = 'https://fcm.googleapis.com/v1/projects/split-wise-891b7/messages:send';

  static Future<String> _getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString('assets/split-wise-891b7-firebase-adminsdk-fbsvc-e1cf10d06c.json');
      log('Service account JSON loaded successfully');
      final credentials = ServiceAccountCredentials.fromJson(jsonDecode(jsonString));
      log('Credentials parsed: ${credentials.email}');
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(credentials, scopes);
      final token = authClient.credentials.accessToken.data;
      log('Access token obtained: $token');
      authClient.close();
      return token;
    } catch (e, stackTrace) {
      log('Error in _getAccessToken: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> sendPushNotification(String deviceToken, String title, String body) async {
    try {
      final accessToken = await _getAccessToken();
      final payload = {
        'message': {
          'token': deviceToken,
          'notification': {'title': title, 'body': body},
          'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'status': 'done'},
          'android': {'notification': {'sound': 'default', 'channel_id': 'settleup_channel'}},
        }
      };
      final response = await http.post(
        Uri.parse(_fcmURL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        log('Push notification sent successfully: ${response.body}');
      } else {
        log('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error sending push notification: $e');
      rethrow; // Optional: rethrow to handle errors upstream
    }
  }
}