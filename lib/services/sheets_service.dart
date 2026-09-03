import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SheetsService {
  static const String sheetUrl =
      'https://docs.google.com/spreadsheets/d/1zd4ZNASPB49qLoErerYks6at1Tjmxxj_SIc2JptZglQ/edit?gid=0#gid=0';

  static const String defaultWebhookUrl =
      'https://script.google.com/macros/s/AKfycbw7PyLpD6iCCi-QLf-2WNO7NGj1PE3_WH5pk94uhpLZN0WTxWYRXz5f0edLE9Np4r3j0Q/exec';

  // Can be configured dynamically via Firestore or kept here once deployed
  static String? _cachedWebhookUrl;

  /// Fetches the configured Google Apps Script Webhook URL from Firestore (or fallback).
  static Future<String?> getWebhookUrl() async {
    if (_cachedWebhookUrl != null && _cachedWebhookUrl!.isNotEmpty) {
      return _cachedWebhookUrl;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('google_sheets')
          .get();
      if (doc.exists) {
        final url = doc.data()?['webhookUrl']?.toString();
        if (url != null && url.isNotEmpty) {
          _cachedWebhookUrl = url;
          return url;
        }
      }
    } catch (e) {
      debugPrint('SheetsService notice: $e');
    }
    _cachedWebhookUrl = defaultWebhookUrl;
    return defaultWebhookUrl;
  }

  /// Saves or updates the Google Apps Script Webhook URL in Firestore.
  static Future<void> saveWebhookUrl(String url) async {
    _cachedWebhookUrl = url.trim();
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('google_sheets')
          .set({
        'webhookUrl': url.trim(),
        'sheetUrl': sheetUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving Sheets webhook URL: $e');
    }
  }

  /// Sends the lead data to the Google Sheet in realtime via Google Apps Script Web App.
  static Future<bool> syncLead({
    required String name,
    required String phone,
    required String configuration,
    String purpose = 'Site Visit',
    String message = '',
    String whatsappStatus = '-',
  }) async {
    final webhook = await getWebhookUrl();
    if (webhook == null || webhook.trim().isEmpty) {
      debugPrint('SheetsService: No webhook URL configured yet. Skipping realtime sync.');
      return false;
    }

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final payload = {
      'date': dateStr,
      'time': timeStr,
      'dateTime': '$dateStr $timeStr',
      'name': name,
      'phone': phone,
      'configuration': configuration,
      'purpose': purpose,
      'message': message,
      'whatsappStatus': whatsappStatus,
      'source': 'NB Legacy Website',
    };

    try {
      final uri = Uri.parse(webhook.trim());
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'text/plain;charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('SheetsService sync response (${response.statusCode}): ${response.body}');
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      debugPrint('SheetsService sync error: $e');
      return false;
    }
  }
}
