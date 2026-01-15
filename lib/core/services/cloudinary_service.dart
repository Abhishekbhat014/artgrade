import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "drdqop40u";
  static const String uploadPreset = "f89ezlgo";

  static Future<String> uploadProfileImage(File image) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
        "Cloudinary upload failed (${response.statusCode}): $responseBody",
      );
    }

    final data = json.decode(responseBody);

    if (data['secure_url'] == null) {
      throw Exception("Cloudinary did not return image URL");
    }

    return data['secure_url'];
  }
}
