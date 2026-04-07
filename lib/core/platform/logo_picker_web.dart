// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickLogoDataUrl() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;

  final reader = html.FileReader();
  final completer = Completer<String?>();

  reader.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  reader.onLoad.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete(reader.result as String?);
    }
  });

  reader.readAsDataUrl(file);
  return completer.future;
}
