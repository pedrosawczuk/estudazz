import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/custom/loadingButton.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/models/user/userModel.dart';
import 'package:estudazz_main_code/utils/formatter/inputsFormatter.dart';
import 'package:estudazz_main_code/utils/user/getUserData.dart';
import 'package:estudazz_main_code/utils/validators/TextFieldValidator.dart';
import 'package:estudazz_main_code/utils/validators/birthDateValidator.dart';
import 'package:estudazz_main_code/utils/validators/graduationDateValidator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditDataPage extends StatefulWidget {
  const EditDataPage({super.key});

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _institutionController = TextEditingController();
  final _courseController = TextEditingController();
  final _graduationDateController = TextEditingController();
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _institutionController.dispose();
    _courseController.dispose();
    _graduationDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = await GetUserData.getUserUid();
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final results = await Future.wait([
      userRef.get(),
      userRef.collection('private').doc('profile').get(),
    ]);
    final snapshot = results[0];
    final privateSnapshot = results[1];

    if (snapshot.exists) {
      final user = UserModel.fromMap(
        snapshot.data()!,
        uid,
        privateMap: privateSnapshot.data(),
      );

      _nameController.text = user.displayName;
      _usernameController.text = user.username;
      _emailController.text =
          FirebaseAuth.instance.currentUser?.email ?? user.email;
      _birthDateController.text = user.birthDate;
      _institutionController.text = user.institution;
      _courseController.text = user.course;
      _graduationDateController.text = user.expectedGraduation;
      _photoUrl = user.photoUrl;
    }
  }

  Future<void> _saveUserData() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        final currentUser = FirebaseAuth.instance.currentUser;
        final uid = currentUser?.uid ?? await GetUserData.getUserUid();
        if (uid == null) return;

        final verifiedEmail = currentUser?.email ?? _emailController.text.trim();

        final updatedUser = UserModel(
          uid: uid,
          displayName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: verifiedEmail,
          birthDate: _birthDateController.text.trim(),
          institution: _institutionController.text.trim(),
          course: _courseController.text.trim(),
          expectedGraduation: _graduationDateController.text.trim(),
          profileCompleted: true,
          photoUrl: _photoUrl,
        );

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final batch = FirebaseFirestore.instance.batch();

        batch.update(userRef, {
          ...updatedUser.toPublicMap(),
          'birth_date': FieldValue.delete(),
          'institution': FieldValue.delete(),
          'course': FieldValue.delete(),
          'expected_graduation': FieldValue.delete(),
        });

        batch.set(
          userRef.collection('private').doc('profile'),
          updatedUser.toPrivateMap(),
          SetOptions(merge: true),
        );

        await batch.commit();

        FocusManager.instance.primaryFocus?.unfocus();
        Get.back();
        CustomSnackBar.show(
          title: 'Sucesso!',
          message: 'Dados atualizados com sucesso!',
          backgroundColor: ConstColors.greenColor,
        );
      } else {
        CustomSnackBar.show(
          title: 'Atenção!',
          message:
              'Verifique se você preencheu todos os campos obrigatórios corretamente.',
          backgroundColor: ConstColors.orangeColor,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao atualizar dados do usuário: $e');
      }
      CustomSnackBar.show(
        title: 'Erro!',
        message: 'Erro ao atualizar os dados. Tente novamente mais tarde.',
        backgroundColor: ConstColors.redColor,
      );
      Get.back();
    }
  }

  InputDecoration _buildPremiumDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ConstColors.orangeColor),
      filled: true,
      fillColor: ConstColors.blackColor,
      labelStyle: const TextStyle(color: ConstColors.greyColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ConstColors.orangeColor, width: 2),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData sectionIcon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ConstColors.grey900Color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sectionIcon, color: ConstColors.orangeColor, size: 28),
              ConstSizedBox.w8,
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ConstColors.whiteColor,
                ),
              ),
            ],
          ),
          ConstSizedBox.h20,
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleAppBar: 'Editar Dados'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionCard(
                  title: 'Informações Pessoais',
                  sectionIcon: Icons.person_outline,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      inputFormatters: [nameFormatter],
                      keyboardType: TextInputType.text,
                      decoration: _buildPremiumDecoration(
                        'Nome',
                        Icons.badge_outlined,
                      ),
                      validator: (value) =>
                          textFieldValidator(value, 'Nome é obrigatório'),
                    ),
                    ConstSizedBox.h16,
                    TextFormField(
                      controller: _usernameController,
                      inputFormatters: [usernameFormatter],
                      keyboardType: TextInputType.text,
                      decoration: _buildPremiumDecoration(
                        'Username',
                        Icons.alternate_email,
                      ),
                      validator: (value) =>
                          textFieldValidator(value, 'Username é obrigatório'),
                    ),
                    ConstSizedBox.h16,
                    GestureDetector(
                      onTap: () {
                        CustomSnackBar.show(
                          title: 'Atenção!',
                          message: 'Você não pode alterar o email do usuário.',
                          backgroundColor: ConstColors.orangeColor,
                        );
                      },
                      child: TextFormField(
                        controller: _emailController,
                        enabled: false,
                        decoration: _buildPremiumDecoration(
                          'Email',
                          Icons.email_outlined,
                        ),
                        validator: (value) =>
                            textFieldValidator(value, 'Email é obrigatório'),
                      ),
                    ),
                    ConstSizedBox.h16,
                    TextFormField(
                      controller: _birthDateController,
                      inputFormatters: [birthDateFormatter],
                      keyboardType: TextInputType.number,
                      decoration: _buildPremiumDecoration(
                        'Data de Nascimento',
                        Icons.cake_outlined,
                        hint: 'DD/MM/AAAA',
                      ),
                      validator: birthDateValidator,
                    ),
                  ],
                ),

                ConstSizedBox.h24,

                _buildSectionCard(
                  title: 'Informações Acadêmicas',
                  sectionIcon: Icons.school_outlined,
                  children: [
                    TextFormField(
                      controller: _institutionController,
                      decoration: _buildPremiumDecoration(
                        'Instituição',
                        Icons.account_balance_outlined,
                      ),
                      validator: (value) => textFieldValidator(
                        value,
                        'Instituição é obrigatória',
                      ),
                    ),
                    ConstSizedBox.h16,
                    TextFormField(
                      controller: _courseController,
                      decoration: _buildPremiumDecoration(
                        'Curso',
                        Icons.menu_book_outlined,
                      ),
                      validator: (value) =>
                          textFieldValidator(value, 'Curso é obrigatório'),
                    ),
                    ConstSizedBox.h16,
                    TextFormField(
                      controller: _graduationDateController,
                      inputFormatters: [graduationDateFormatter],
                      keyboardType: TextInputType.number,
                      decoration: _buildPremiumDecoration(
                        'Conclusão (MM/AAAA)',
                        Icons.timeline,
                      ),
                      validator: graduationDateValidator,
                    ),
                  ],
                ),

                ConstSizedBox.h32,

                LoadingButton(
                  onPressed: _saveUserData,
                  icon: const Icon(Icons.check_circle_outline, size: 28),
                  child: const Text(
                    'Salvar Alterações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    foregroundColor: ConstColors.whiteColor,
                    backgroundColor: ConstColors.orangeColor,
                    elevation: 8,
                    shadowColor: ConstColors.orangeColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                ConstSizedBox.h30,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
