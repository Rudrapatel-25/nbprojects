import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../config/cloudinary_config.dart';

class CloudinaryService {
  Future<String> uploadPickedImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('No image selected');
    }
    final file = result.files.first;
    var rawBytes = file.bytes;
    if (rawBytes == null) {
      throw Exception('Could not read image bytes');
    }

    // 1. Compress image to max 1000px width before uploading or creating fallback data URL
    final bytes = await _compressImageBytes(rawBytes, targetWidth: 1000);

    // 2. Upload to Cloudinary
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.imageUploadUrl()),
      );
      request.fields['upload_preset'] = CloudinaryConfig.unsignedPreset;
      request.fields['folder'] = 'nbprojects';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = json['secure_url']?.toString();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
    }

    // 3. Fallback: Return compressed Base64 Data URL (tiny size ~60KB-120KB)
    final base64Str = base64Encode(bytes);
    final ext = file.extension?.toLowerCase() ?? file.name.split('.').last.toLowerCase();
    final mime = (ext == 'png')
        ? 'image/png'
        : (ext == 'webp')
            ? 'image/webp'
            : (ext == 'svg')
                ? 'image/svg+xml'
                : 'image/jpeg';
    return 'data:$mime;base64,$base64Str';
  }

  static Future<Uint8List> _compressImageBytes(Uint8List inputBytes, {int targetWidth = 1000}) async {
    try {
      final codec = await ui.instantiateImageCodec(
        inputBytes,
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      print('Compression error: $e');
    }
    return inputBytes;
  }
}
