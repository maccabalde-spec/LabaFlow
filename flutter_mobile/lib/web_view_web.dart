// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';

const String _viewType = 'labaflow-iframe';
bool _registered = false;

void registerLabaFlowView() {
  if (_registered) return;
  _registered = true;

  ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final location = html.window.location;
    final callbackParams = '${location.search}${location.hash}';
    final locationSearch = location.search ?? '';
    // Version the embedded document so Firebase Hosting and the browser do
    // not keep showing an older cached landing page after a web release.
    final forwardedQuery = locationSearch.isEmpty
        ? ''
        : '&${locationSearch.substring(1)}';
    final iframe = html.IFrameElement()
      ..src =
          'labaflow.html?v=20261107-otp1$forwardedQuery${location.hash}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..setAttribute('allow', 'camera; microphone; geolocation')
      ..setAttribute('allowfullscreen', 'true');

    // Keep OAuth tokens inside the same-origin app frame, then clear them
    // from the address bar so the published URL stays at the clean root.
    if (callbackParams.isNotEmpty) {
      html.window.history.replaceState(null, '', location.pathname);
    }

    return iframe;
  });
}

class HtmlElementViewWidget extends StatelessWidget {
  const HtmlElementViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(child: HtmlElementView(viewType: _viewType));
  }
}
