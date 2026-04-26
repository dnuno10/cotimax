import 'dart:html' as html;

Future<bool> navigateToUrl(String url) async {
  html.window.location.assign(url);
  return true;
}

