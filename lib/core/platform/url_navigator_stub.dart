import 'package:url_launcher/url_launcher.dart';

Future<bool> navigateToUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return Future.value(false);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

