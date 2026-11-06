import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'supabase_options.dart';

import 'web_view_stub.dart' if (dart.library.html) 'web_view_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The web app delegates authentication to the embedded HTML client. Let it
  // consume the OAuth callback fragment; initializing supabase_flutter here
  // can consume and clear the Google access token before the iframe receives it.
  if (!kIsWeb) {
    await Supabase.initialize(
      url: LabaFlowSupabaseOptions.url,
      publishableKey: LabaFlowSupabaseOptions.publishableKey,
    );
  }
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  runApp(const LabaFlowApp());
}

class LabaFlowApp extends StatelessWidget {
  const LabaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Web builds keep the existing embedded HTML client.
    if (kIsWeb) {
      return MaterialApp(
        title: 'LabaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const WebHome(),
      );
    }

    // Mobile → native Flutter UI
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const _MobileApp(),
    );
  }
}

// ─── WEB (unchanged) ────────────────────────────────────────
class WebHome extends StatelessWidget {
  const WebHome({super.key});

  @override
  Widget build(BuildContext context) {
    registerLabaFlowView();
    return const Scaffold(
      backgroundColor: AppColors.lightBg,
      body: HtmlElementViewWidget(),
    );
  }
}

// ─── MOBILE ─────────────────────────────────────────────────
class _MobileApp extends StatefulWidget {
  const _MobileApp();

  @override
  State<_MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<_MobileApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(context.read<AppProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LabaFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
