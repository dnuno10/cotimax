abstract class AuthRepository {
  Future<void> requestOtp({required String email});
  Future<bool> verifyOtp({required String email, required String token});
  Future<void> signOut();
  Future<void> recoverPassword(String email);
}
