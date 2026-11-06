import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'providers/app_provider.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/seller/seller_shell.dart';
import 'screens/admin/admin_shell.dart';

GoRouter buildRouter(AppProvider provider) {
  return GoRouter(
    initialLocation: '/',
    // Keep one router alive as application state changes. Recreating it after
    // every provider notification resets the active route (including chats).
    refreshListenable: provider,
    redirect: (context, state) {
      // On web, skip native routes because the HTML client is embedded there.
      if (kIsWeb) return null;

      final user = provider.currentUser;
      final loc  = state.matchedLocation;

      // Not logged in — only allow landing and auth
      if (user == null) {
        if (loc == '/' || loc == '/auth') return null;
        return '/';
      }

      // Logged in — route by role
      switch (user.role) {
        case UserRole.customer:
          if (loc.startsWith('/customer')) return null;
          return '/customer';
        case UserRole.seller:
          if (loc.startsWith('/seller')) return null;
          return '/seller';
        case UserRole.admin:
          if (loc.startsWith('/admin')) return null;
          return '/admin';
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LandingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'sign';
          return AuthScreen(tab: tab);
        },
      ),
      GoRoute(
        path: '/customer',
        builder: (_, __) => const CustomerShell(),
      ),
      GoRoute(
        path: '/seller',
        builder: (_, __) => const SellerShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminShell(),
      ),
    ],
  );
}


