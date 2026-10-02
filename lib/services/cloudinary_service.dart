import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'puiaj0lx';
  static const String uploadPreset = 'lost_found_upload';

  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode}\n$body',
      );
    }

    final data = jsonDecode(body) as Map<String, dynamic>;

    final url = data['secure_url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return url;
  }
}