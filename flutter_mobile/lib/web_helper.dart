// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebHtmlView {
  static bool _registered = false;
  static void registerView(String viewId) {
    if (_registered) return;
    _registered = true;

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => html.IFrameElement()
        ..src = 'assets/labaflow.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }
}
