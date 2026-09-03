import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WhatsAppResult {
  final bool success;
  final String statusText; // 'Sent' or 'Failed'
  final String? messageId;
  final String? error;
  final String? rawResponse;

  const WhatsAppResult({
    required this.success,
    required this.statusText,
    this.messageId,
    this.error,
    this.rawResponse,
  });
}

class WhatsAppService {
  static const String _apiToken = '22469|aB0G7AWOAhtazJWJqWiu2Fzkyki95vDAUoypfSpFb1ad3960';
  static const String _phoneNumberId = '1075217892352542';
  static const String _templateId = '418620';
  static const String _headerMediaUrl =
      'https://bot-data.s3.ap-southeast-1.wasabisys.com/flowbuilder/17/306044/whatsapp-440327/flowbuilder-306044-1785653095.png';
  static const String _quickReplyValues = '["fjDUteL1avhBBem"]';

  /// Normalizes phone number into Indian international format without plus (e.g. 919876543210).
  static String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.startsWith('91')) {
      return digits;
    }
    return '91$digits';
  }

  /// Dispatches the Botbiz WhatsApp template message to the customer.
  static Future<WhatsAppResult> sendBookingTemplate(String rawPhone) async {
    final phone = formatPhoneNumber(rawPhone);

    final queryParams = {
      'apiToken': _apiToken,
      'phone_number_id': _phoneNumberId,
      'template_id': _templateId,
      'template_header_media_url': _headerMediaUrl,
      'template_quick_reply_button_values': _quickReplyValues,
      'phone_number': phone,
    };

    final uri = Uri.https('dash.botbiz.io', '/api/v1/whatsapp/send/template', queryParams);

    debugPrint('WhatsAppService: Sending template to $phone...');

    try {
      final response = await http.post(uri).timeout(const Duration(seconds: 15));

      debugPrint('WhatsAppService response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status']?.toString();
        if (status == '1') {
          return WhatsAppResult(
            success: true,
            statusText: 'Sent',
            messageId: data['wa_message_id']?.toString(),
            rawResponse: response.body,
          );
        } else {
          return WhatsAppResult(
            success: false,
            statusText: 'Failed',
            error: data['message']?.toString() ?? 'API returned status $status',
            rawResponse: response.body,
          );
        }
      } else {
        return WhatsAppResult(
          success: false,
          statusText: 'Failed',
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          rawResponse: response.body,
        );
      }
    } catch (e) {
      debugPrint('WhatsAppService error: $e');
      return WhatsAppResult(
        success: false,
        statusText: 'Failed',
        error: e.toString(),
      );
    }
  }
}
