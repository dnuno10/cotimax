import 'package:cotimax/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> requestOtp({required String email}) async {
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    return response.session != null;
  }

  @override
  Future<void> ensureWorkspace() async {
    await _client.rpc('ensure_user_workspace');
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> recoverPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
