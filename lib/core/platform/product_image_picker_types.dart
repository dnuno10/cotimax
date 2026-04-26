import 'dart:typed_data';

class ProductImagePickResult {
  ProductImagePickResult({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;

  int get sizeBytes => bytes.lengthInBytes;

  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot > 0 && dot < fileName.length - 1) {
      return fileName.substring(dot + 1).toLowerCase();
    }
    final normalized = mimeType.toLowerCase();
    if (normalized.contains('png')) return 'png';
    if (normalized.contains('webp')) return 'webp';
    if (normalized.contains('jpeg') || normalized.contains('jpg')) return 'jpg';
    return 'jpg';
  }
}
