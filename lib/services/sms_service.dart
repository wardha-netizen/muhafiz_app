import 'package:flutter_sms/flutter_sms.dart';

class SMSService {
  static Future<void> sendEmergencySMS(String number, String message) async {
    await sendSMS(message: message, recipients: [number]);
  }
}
