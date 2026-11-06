import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // NEW
import 'core/constants.dart';
import 'core/notifications.dart'; // NEW
import 'screens/auth/login_screen.dart';
import 'screens/home/customer_home_screen.dart';
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Requires google-services.json / firebase_options.dart)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD7351iG-hsJQmYZ8pZD7yWICCm3rIPKA8",
      appId: "1:432117023020:web:e1e3b9c4a56fc8989eac89",
      messagingSenderId: "432117023020",
      projectId: "labaflow-ebaa4",
      authDomain: "labaflow-ebaa4.firebaseapp.com",
      storageBucket: "labaflow-ebaa4.firebasestorage.app",
    ),
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: LabaFlowApp()));
}

class LabaFlowApp extends ConsumerStatefulWidget {
  const LabaFlowApp({super.key});

  @override
  ConsumerState<LabaFlowApp> createState() => _LabaFlowAppState();
}

class _LabaFlowAppState extends ConsumerState<LabaFlowApp> {
  @override
  void initState() {
    super.initState();
    // Setup listeners for auth state to register notification tokens upon login
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        NotificationService.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      // ... (Theme and structure remains the same as Phase 5) ...
      title: 'LabaFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, background: AppColors.background),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (data) => data.session != null ? const CustomerHomeScreen() : const LoginScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}