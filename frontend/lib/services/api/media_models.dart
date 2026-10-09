class CloudMedia {
  final String type;
  final String bucket;
  final String key;
  final String contentType;
  final int sizeBytes;
  final String url;

  const CloudMedia({
    required this.type,
    required this.bucket,
    required this.key,
    required this.contentType,
    required this.sizeBytes,
    required this.url,
  });

  factory CloudMedia.fromJson(Map<String, dynamic> json) {
    return CloudMedia(
      type: json['type']?.toString() ?? 'recording',
      bucket: json['bucket']?.toString() ?? '',
      key: json['key']?.toString() ?? json['storageKey']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      sizeBytes: json['sizeBytes'] is num
          ? (json['sizeBytes'] as num).toInt()
          : int.tryParse(json['sizeBytes']?.toString() ?? '') ?? 0,
      url: json['url']?.toString() ?? '',
    );
  }
}

class MediaUploadResponse {
  final bool success;
  final CloudMedia? media;
  final String? message;

  const MediaUploadResponse({required this.success, this.media, this.message});

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final rawData = json['data'];

    final Map<String, dynamic>? mediaJson = rawMedia is Map
        ? Map<String, dynamic>.from(rawMedia)
        : rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : null;

    return MediaUploadResponse(
      success: json['success'] == true,
      media: mediaJson == null ? null : CloudMedia.fromJson(mediaJson),
      message: json['message']?.toString(),
    );
  }
}
