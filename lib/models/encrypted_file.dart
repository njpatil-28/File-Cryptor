class EncryptedFile {
  final String id;
  final String fileName;
  final String filePath;
  final String userId;
  final DateTime uploadedAt;
  final String? metadata;

  EncryptedFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.userId,
    required this.uploadedAt,
    this.metadata,
  });

  factory EncryptedFile.fromJson(Map<String, dynamic> json) {
    return EncryptedFile(
      id: json['id'] ?? '',
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      userId: json['user_id'] ?? '',
      uploadedAt: DateTime.parse(
          json['uploaded_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'user_id': userId,
      'uploaded_at': uploadedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}
