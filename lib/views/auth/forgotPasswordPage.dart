import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/utils/validators/TextFieldValidator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'signInPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  Future<void> recoverPassword() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim().toLowerCase();

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        CustomSnackBar.show(
          title: 'Sucesso!',
          message:
              'Email de recuperação enviado! Verifique sua caixa de entrada.',
          backgroundColor: ConstColors.greenColor,
        );
        Get.offAllNamed(AppRoutes.signInPage);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          CustomSnackBar.show(
            title: 'Erro!',
            message: 'Usuário não encontrado com este email',
            backgroundColor: ConstColors.redColor,
          );
        } else if (e.code == 'invalid-email') {
          CustomSnackBar.show(
            title: 'Erro!',
            message: 'Email inválido',
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
            title: 'Erro Inesperado',
            message: 'Erro ao entrar, contate o suporte',
            backgroundColor: ConstColors.redColor,
          );
        }
      } catch (e) {
        CustomSnackBar.show(
          title: 'Erro Inesperado',
          message: 'Não foi possível enviar o email. Tente novamente.',
          backgroundColor: ConstColors.redColor,
        );
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
                  'RECUPERAR CONTA',
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Get.offAll(() => const SignInPage());
                        },
                        child: const Text(
                          'Voltar ao login',
                          style: TextStyle(color: ConstColors.greyColor),
                        ),
                      ),
                    ],
                  ),
                ),
                ConstSizedBox.h10,
                LoadingButton(
                  onPressed: recoverPassword,
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(200, 44),
                    backgroundColor: ConstColors.orangeColor,
                    foregroundColor: ConstColors.whiteColor,
                  ),
                  child: const Text('Recuperar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
