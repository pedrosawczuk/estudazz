import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/routes/appRoutes.dart';
import 'package:estudazz_main_code/services/auth/saveUserLocal.dart';
import 'package:estudazz_main_code/utils/user/userDeleteAccount.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleAppBar: 'Configurações'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Conta'),
          _buildAccountListTile(),
          const Divider(),

          _buildSectionHeader('Configurações do App'),
          _buildNotificationsListTile(),
          const Divider(),

          _buildSectionHeader('Sobre'),
          _buildAboutListTile(),
          const Divider(),

          _buildLogoutListTile(),
          const SizedBox(height: 20),
          _buildDeleteAccountButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAccountListTile() {
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('Meus Dados'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Get.toNamed(AppRoutes.myDataPage);
      },
    );
  }

  Widget _buildAboutListTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('O que é o Estudazz'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Get.toNamed(AppRoutes.aboutPage);
      },
    );
  }

  Widget _buildNotificationsListTile() {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: const Text('Notificações'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Get.toNamed(AppRoutes.notificationsPage);
      },
    );
  }

  Widget _buildLogoutListTile() {
    return ListTile(
      leading: const Icon(Icons.logout, color: ConstColors.redColor),
      title: const Text('Sair', style: TextStyle(color: ConstColors.redColor)),
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        await SaveUserLocal.clearUser();
        Get.offAllNamed(AppRoutes.signInPage);
        CustomSnackBar.show(
          title: 'Desconectado',
          message: 'Você foi desconectado com sucesso.',
          backgroundColor: ConstColors.greenColor,
        );
      },
    );
  }

  Widget _buildDeleteAccountButton() {
    return Center(
      child: TextButton(
        onPressed: () => showDeleteAccountDialog(context),
        style: TextButton.styleFrom(
          foregroundColor: ConstColors.redColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ConstColors.redColor),
          ),
        ),
        child: const Text(
          'Deletar Conta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
