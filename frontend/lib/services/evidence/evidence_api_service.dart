import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class EvidenceMedia {
  final String bucket;
  final String key;
  final String contentType;
  final int sizeBytes;
  final String? lastModified;
  final String signedUrl;

  const EvidenceMedia({
    required this.bucket,
    required this.key,
    required this.contentType,
    required this.sizeBytes,
    required this.lastModified,
    required this.signedUrl,
  });

  bool get isVideo =>
      contentType.startsWith('video/') ||
      key.toLowerCase().endsWith('.webm') ||
      key.toLowerCase().endsWith('.mp4') ||
      key.toLowerCase().endsWith('.mov') ||
      (key.toLowerCase().endsWith('.bin') &&
          key.toLowerCase().contains('/recordings/'));

  bool get isPhoto =>
      contentType.startsWith('image/') ||
      key.toLowerCase().endsWith('.png') ||
      key.toLowerCase().endsWith('.jpg') ||
      key.toLowerCase().endsWith('.jpeg') ||
      key.toLowerCase().endsWith('.webp');

  String get filename {
    final parts = key.split('/');
    return parts.isEmpty ? key : parts.last;
  }

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }

    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory EvidenceMedia.fromJson(Map<String, dynamic> json) {
    return EvidenceMedia(
      bucket: json['bucket']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      contentType:
          json['contentType']?.toString() ?? 'application/octet-stream',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      lastModified: json['lastModified']?.toString(),
      signedUrl: json['signedUrl']?.toString() ?? '',
    );
  }
}

class EvidenceData {
  final String awb;
  final List<EvidenceMedia> recordings;
  final List<EvidenceMedia> photos;

  const EvidenceData({
    required this.awb,
    required this.recordings,
    required this.photos,
  });

  int get videoCount => recordings.length;

  int get photoCount => photos.length;

  factory EvidenceData.fromJson(Map<String, dynamic> json) {
    final recordingsJson = json['recordings'] as List<dynamic>? ?? <dynamic>[];

    final photosJson = json['photos'] as List<dynamic>? ?? <dynamic>[];

    return EvidenceData(
      awb: json['awb']?.toString() ?? '',
      recordings: recordingsJson
          .whereType<Map>()
          .map(
            (item) => EvidenceMedia.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((media) => media.signedUrl.isNotEmpty)
          .toList(),
      photos: photosJson
          .whereType<Map>()
          .map(
            (item) => EvidenceMedia.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((media) => media.signedUrl.isNotEmpty)
          .toList(),
    );
  }
}

class EvidenceApiService {
  const EvidenceApiService();

  Future<Map<String, dynamic>> createEvidence({
    required String recordingId,
    String type = 'VIDEO',
    String? fileName,
    String? contentType,
    int? sizeBytes,
    int? durationSeconds,
  }) async {
    final value = recordingId.trim();

    if (value.isEmpty) {
      throw Exception('recordingId is required.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/evidence');

    const apiClient = ApiClient();

    final body = <String, dynamic>{
      'recordingId': value,
      'type': type,
      if (fileName != null && fileName.trim().isNotEmpty)
        'fileName': fileName.trim(),
      if (contentType != null && contentType.trim().isNotEmpty)
        'contentType': contentType.trim(),
      'sizeBytes': ?sizeBytes,
      'durationSeconds': ?durationSeconds,
    };

    final response = await apiClient.post(uri, body: body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Evidence create failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid evidence create response.');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Evidence creation failed.',
      );
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Evidence data is missing from API response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<EvidenceData> getEvidence(String awb) async {
    final value = awb.trim();

    if (value.isEmpty) {
      throw Exception('AWB is required.');
    }

    final uri = Uri.parse(
      '${ApiConfig.storageBaseUrl}/evidence/'
      '${Uri.encodeComponent(value)}',
    );

    const apiClient = ApiClient();

    final response = await apiClient.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Evidence API failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid evidence API response.');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Evidence loading failed.',
      );
    }

    final evidence = decoded['evidence'];

    if (evidence is! Map) {
      throw Exception('Evidence data is missing from API response.');
    }

    return EvidenceData.fromJson(Map<String, dynamic>.from(evidence));
  }
}
