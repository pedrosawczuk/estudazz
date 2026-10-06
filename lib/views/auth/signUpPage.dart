import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/controllers/auth/authController.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/utils/validators/TextFieldValidator.dart';
import 'package:estudazz_main_code/views/auth/signInPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _submitForm() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim().toLowerCase();
      String password = _passwordController.text;

      setState(() => _isLoading = true);

      try {
        await _authController.signUp(email, password);
        Get.offAndToNamed(AppRoutes.signInPage);
      } on FirebaseAuthException catch (e) {
        String msg;
        if (e.code == 'email-already-in-use') {
          msg = 'Esse email já está sendo usado. Tente outro!';
        } else if (e.code == 'invalid-email') {
          msg = 'Email inválido. Digite um email válido!';
        } else if (e.code == 'weak-password') {
          msg = 'A senha deve ter pelo menos 6 caracteres!';
        } else {
          msg = 'Erro de cadastro. Verifique os dados: ${e.message}';
        }
        
        CustomSnackBar.show(
          title: 'Erro!',
          message: msg,
          backgroundColor: ConstColors.redColor,
        );
      } catch (e) {
        CustomSnackBar.show(
          title: 'Erro Inesperado',
          message: 'Erro ao criar conta. Tente novamente mais tarde.',
          backgroundColor: ConstColors.redColor,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'REGISTRAR',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                ConstSizedBox.h30,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (value) =>
                            textFieldValidator(value, 'A email é obrigatório'),
                  ),
                ),
                ConstSizedBox.h10,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator:
                        (value) =>
                            textFieldValidator(value, 'Senha é obrigatória'),
                  ),
                ),
                ConstSizedBox.h10,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Já tem uma conta?'),
                      TextButton(
                        onPressed: () {
                          Get.offAll(() => const SignInPage());
                        },
                        child: const Text('Entre aqui'),
                      ),
                    ],
                  ),
                ),
                ConstSizedBox.h10,
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(200, 44),
                    backgroundColor: ConstColors.orangeColor,
                    foregroundColor: ConstColors.whiteColor,
                    disabledBackgroundColor: ConstColors.orangeColor.withValues(alpha: 0.7),
                    disabledForegroundColor: ConstColors.whiteColor,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ConstColors.whiteColor,
                            ),
                          )
                        : const Text('Criar Conta', key: ValueKey('label')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}