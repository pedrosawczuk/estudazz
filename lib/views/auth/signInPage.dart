import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/controllers/auth/authController.dart';
import 'package:estudazz_main_code/utils/validators/TextFieldValidator.dart';
import 'package:estudazz_main_code/views/auth/forgotPasswordPage.dart';
import 'package:estudazz_main_code/views/homePage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signUpPage.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
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
        await _authController.signIn(email, password);
        Get.offAll(() => const HomePage());
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          CustomSnackBar.show(
            title: 'Erro!',
            message: 'Usuário não encontrado.',
            backgroundColor: ConstColors.redColor,
          );
        } else if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
          CustomSnackBar.show(
            title: 'Credenciais Incorretas',
            message: 'Verifique se seu email ou senha estão corretos.',
            backgroundColor: ConstColors.redColor,
          );
        } else if (e.code == 'invalid-email') {
          CustomSnackBar.show(
            title: 'Erro!',
            message: 'Por favor, insira um endereço de email válido.',
            backgroundColor: ConstColors.redColor,
          );
        } else if (e.code == 'user-disabled') {
          CustomSnackBar.show(
            title: 'Erro!',
            message: 'Essa conta foi desativada.',
            backgroundColor: ConstColors.redColor,
          );
        } else if (e.code == 'too-many-requests') {
          CustomSnackBar.show(
            title: 'Muitas Tentativas',
            message: 'Sua conta foi bloqueada temporariamente. Tente de novo mais tarde.',
            backgroundColor: ConstColors.redColor,
          );
        } else if (e.code == 'network-request-failed') {
          CustomSnackBar.show(
            title: 'Sem Conexão',
            message: 'Verifique sua conexão com a internet.',
            backgroundColor: ConstColors.redColor,
          );
        } else {
          CustomSnackBar.show(
            title: 'Erro',
            message: 'Ocorreu um erro ao entrar (${e.code}). Contate o suporte.',
            backgroundColor: ConstColors.redColor,
          );
        }
      } catch (e) {
        CustomSnackBar.show(
          title: 'Erro Inesperado',
          message: 'Falha ao processar o login. Tente novamente.',
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
                  'ENTRAR',
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
                            textFieldValidator(value, 'Email é obrigatório'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.offAll(() => const ForgotPasswordPage());
                      },
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(color: ConstColors.greyColor),
                      ),
                    ),
                  ],
                ),
                ConstSizedBox.h5,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Não tem uma conta?'),
                      TextButton(
                        onPressed: () {
                          Get.offAll(() => const SignUpPage());
                        },
                        child: const Text('Crie aqui'),
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
                        : const Text('Entrar', key: ValueKey('label')),
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
