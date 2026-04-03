import 'package:cotimax/features/auth/data/auth_repository.dart';
import 'package:cotimax/features/auth/data/supabase_auth_repository.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.error,
    this.otpEmail,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? otpEmail;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? otpEmail,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpEmail: otpEmail ?? this.otpEmail,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final client = ref.watch(supabaseClientProvider);
    final isAuthenticated = client.auth.currentSession != null;
    return AuthState(isAuthenticated: isAuthenticated);
  }

  Future<bool> requestOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).requestOtp(email: email);
      state = state.copyWith(isLoading: false, error: null, otpEmail: email);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _humanizeError(error, error.message),
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _humanizeError(error, 'No se pudo enviar el código.'),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String token) async {
    state = state.copyWith(isLoading: true, error: null, otpEmail: email);
    try {
      final ok = await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: email, token: token);
      if (ok) {
        await ref.read(authRepositoryProvider).ensureWorkspace();
        state = AuthState(isAuthenticated: true, otpEmail: email);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'El código no es válido.',
      );
      return false;
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _humanizeError(error, error.message),
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _humanizeError(error, 'No se pudo validar el código.'),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState(isAuthenticated: false);
  }

  void resetOtpFlow() {
    state = AuthState(isAuthenticated: state.isAuthenticated);
  }

  Future<void> recoverPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).recoverPassword(email);
      state = state.copyWith(isLoading: false, error: null);
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _humanizeError(error, error.message),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo enviar el enlace de recuperación.',
      );
    }
  }

  String _humanizeError(Object error, String fallback) {
    final message = error.toString().trim();
    if (message.isEmpty) return fallback;
    if (message.contains('ensure_user_workspace')) {
      return 'Falta ejecutar la migracion de workspace en Supabase.';
    }
    if (message.contains('Sin acceso a la empresa')) {
      return 'Tu usuario no tiene una empresa asignada todavia.';
    }
    if (message.contains('One of email or phone')) {
      return 'No se encontró el correo para enviar el código.';
    }
    if (message.contains('429') ||
        message.contains('Too Many Requests') ||
        message.contains('security purposes') ||
        message.contains('after 60 seconds') ||
        message.contains('after 55 seconds')) {
      return 'Espera un momento antes de solicitar otro código.';
    }
    if (message.contains('Failed to fetch') ||
        message.contains('ClientException')) {
      return 'No se pudo conectar con Supabase.';
    }
    if (message.contains('Invalid login credentials')) {
      return 'Las credenciales no son válidas.';
    }
    if (message.contains('Token has expired') || message.contains('expired')) {
      return 'El código ha expirado. Solicita uno nuevo.';
    }
    if (message.contains('Token has invalid claims') ||
        message.contains('token is invalid') ||
        message.contains('invalid token')) {
      return 'El código no es válido.';
    }
    if (message.contains('Email not confirmed')) {
      return 'El correo aun no ha sido confirmado.';
    }
    if (message.contains('User already registered')) {
      return 'Este correo ya esta registrado.';
    }
    return message;
  }
}
