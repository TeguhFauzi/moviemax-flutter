import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class CloudinaryService {
  static Future<String?> uploadImage(dynamic imageFile) async {
    try {
      final cloudName = EnvConfig.cloudinaryCloudName;
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = 'ml_default'; // default unsigned preset
      request.fields['api_key'] = EnvConfig.cloudinaryApiKey;

      if (imageFile is File) {
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      } else if (imageFile is String) {
        request.fields['file'] = imageFile; // URL string
      } else {
        return null;
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['secure_url'] as String?;
      } else {
        print('Cloudinary Upload Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Cloudinary Exception: $e');
    }
    return null;
  }
}
