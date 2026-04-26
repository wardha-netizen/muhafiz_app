import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dnc0jmsle';
  static const String _uploadPreset = 'muhafiz_preset';

  // resource_type=auto lets Cloudinary detect image / video / audio automatically.
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  /// Uploads [file] to Cloudinary and returns the secure_url on success,
  /// or null if the upload fails. Throws nothing — errors are logged only.
  static Future<String?> uploadFile(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }

      debugPrint('Cloudinary upload failed [${streamed.statusCode}]: $body');
      return null;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
}
