import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const LabaFlowApp());
}

class LabaFlowApp extends StatelessWidget {
  final Widget home;
  const LabaFlowApp({super.key, this.home = const LabaFlowWebView()});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabaFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}

class LabaFlowWebView extends StatefulWidget {
  const LabaFlowWebView({super.key});

  @override
  State<LabaFlowWebView> createState() => _LabaFlowWebViewState();
}

class _LabaFlowWebViewState extends State<LabaFlowWebView> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialFile: 'assets/labaflow.html',
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                mediaPlaybackRequiresUserGesture: false,
                supportZoom: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                builtInZoomControls: false,
                displayZoomControls: false,
              ),
              onLoadStop: (controller, url) {
                setState(() => _isLoading = false);
              },
              onReceivedError: (controller, request, error) {
                setState(() => _isLoading = false);
              },
            ),
            if (_isLoading)
              Container(
              color: const Color(0xFFF0F4F8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF0284C7),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'LabaFlow',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lab-a-Day Laundry',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
