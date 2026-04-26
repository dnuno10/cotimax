// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cotimax/core/platform/product_image_picker_types.dart';

Future<ProductImagePickResult?> pickProductImage() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.style.display = 'none';
  html.document.body?.append(input);
  input.click();

  try {
    await input.onChange.first.timeout(const Duration(minutes: 2));
  } catch (_) {
    input.remove();
    return null;
  }

  final file = input.files?.first;
  input.remove();
  if (file == null) return null;

  final reader = html.FileReader();
  final completer = Completer<ProductImagePickResult?>();

  reader.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  reader.onLoad.first.then((_) {
    if (completer.isCompleted) return;
    final result = reader.result;
    Uint8List? bytes;
    if (result is ByteBuffer) {
      bytes = Uint8List.view(result);
    } else if (result is Uint8List) {
      bytes = result;
    } else if (result is List<int>) {
      bytes = Uint8List.fromList(result);
    }

    if (bytes == null) {
      completer.complete(null);
      return;
    }
    completer.complete(
      ProductImagePickResult(
        bytes: bytes,
        mimeType: file.type.toString(),
        fileName: file.name.toString(),
      ),
    );
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
