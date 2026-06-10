import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_provider.dart';

// Supabase client instance provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Real-time Auth state change stream provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  
  // Listen to changes to persist user email locally
  client.auth.onAuthStateChange.listen((data) async {
    final user = data.session?.user;
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString('user_email', user.email ?? '');
    } else {
      await prefs.remove('user_email');
    }
  });

  return client.auth.onAuthStateChange;
});

// Helper class/provider to check if current user is logged in
class CurrentUserNotifier extends Notifier<User?> {
  @override
  User? build() {
    final client = ref.watch(supabaseClientProvider);
    final sub = client.auth.onAuthStateChange.listen((data) {
      Future.microtask(() {
        state = data.session?.user;
      });
    });
    ref.onDispose(() => sub.cancel());
    return client.auth.currentUser;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, User?>(CurrentUserNotifier.new);

// Active user's JWT Token provider (for API headers)
class AuthSessionTokenNotifier extends Notifier<String?> {
  @override
  String? build() {
    final client = ref.watch(supabaseClientProvider);
    final sub = client.auth.onAuthStateChange.listen((data) {
      Future.microtask(() {
        state = data.session?.accessToken;
      });
    });
    ref.onDispose(() => sub.cancel());
    return client.auth.currentSession?.accessToken;
  }
}

final authSessionTokenProvider = NotifierProvider<AuthSessionTokenNotifier, String?>(AuthSessionTokenNotifier.new);

// Theme selection Notifier (persisted in SharedPreferences)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark; // Default theme
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('theme_is_dark') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setBool('theme_is_dark', false);
    } else {
      state = ThemeMode.dark;
      await prefs.setBool('theme_is_dark', true);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

// Auth actions result type
class AuthResult {
  final bool success;
  final String errorMessage;

  AuthResult({required this.success, this.errorMessage = ''});
}

// Auth Actions Manager Notifier
class AuthActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<AuthResult> signUpWithEmail({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
      return AuthResult(success: true);
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  Future<AuthResult> signInWithEmail({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
      state = const AsyncValue.data(null);
      return AuthResult(success: true);
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      // Initiate OAuth flow
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.quickslot://login-callback',
      );
      state = const AsyncValue.data(null);
      return AuthResult(success: true);
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Delete FCM token from backend database before clearing auth session
      try {
        await ref.read(fcmManagerProvider).deleteToken();
      } catch (e) {
        debugPrint('FCM: Error deleting token during signOut: $e');
      }

      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();
      
      // Clean local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final authActionsProvider = NotifierProvider<AuthActions, AsyncValue<void>>(AuthActions.new);
