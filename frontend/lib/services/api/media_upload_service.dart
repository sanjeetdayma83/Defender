import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../camera/camera_recording_service.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'media_models.dart';

class MediaUploadService {
  const MediaUploadService();

  Future<MediaUploadResponse> uploadRecording({
    required RecordingResult recording,
    required String awb,
    required String sku,
  }) async {
    final bytes = await _downloadObjectBytes(recording.objectUrl);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.storageBaseUrl}/recording'),
    );

    request.fields['awb'] = awb;
    request.fields['sku'] = sku;

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: recording.filename),
    );

    const apiClient = ApiClient();

    final streamedResponse = await apiClient.sendMultipart(request);

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Upload failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON response from storage API.');
    }

    return MediaUploadResponse.fromJson(decoded);
  }

  Future<Uint8List> _downloadObjectBytes(String objectUrl) async {
    final response = await http.get(Uri.parse(objectUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unable to read recorded video '
        'from browser memory.',
      );
    }

    return response.bodyBytes;
  }
}
