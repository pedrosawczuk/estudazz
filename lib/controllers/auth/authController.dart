import 'package:estudazz_main_code/services/auth/authServices.dart';

class AuthController {
  final AuthServices _authServices = AuthServices();

  Future<void> signUp(String email, String password) async {
    try {
      await _authServices.createNewUser(email, password);
    } catch (e) {
      throw e;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _authServices.loginUser(email, password);
    } catch (e) {
      throw e;
    }
  }
}