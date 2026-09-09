import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/dialog/notifications/notificationPermissionDialog.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  _NotificationsSettingsPageState createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage>
    with WidgetsBindingObserver {
  bool _permissionGranted = false;
  bool _tasksEnabled = true;
  bool _eventsEnabled = true;
  bool _studyRoomEnabled = true;
  bool _updatesEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _permissionGranted = OneSignal.Notifications.permission;
      _tasksEnabled = prefs.getBool('notif_pref_tasks') ?? true;
      _eventsEnabled = prefs.getBool('notif_pref_events') ?? true;
      _studyRoomEnabled = prefs.getBool('notif_pref_studyroom') ?? true;
      _updatesEnabled = prefs.getBool('notif_pref_updates') ?? true;
      _loading = false;
    });
  }

  void _refreshPermissionStatus() {
    setState(() {
      _permissionGranted = OneSignal.Notifications.permission;
    });
  }

  Future<void> _setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(titleAppBar: 'Configurações de Notificação'),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildPermissionStatusCard(),
                  const Divider(),
                  _buildSectionHeader('Categorias de Notificação'),
                  SwitchListTile(
                    secondary: const Icon(Icons.task_alt),
                    title: const Text('Tarefas'),
                    subtitle: const Text(
                      'Lembretes de prazos das suas tarefas',
                    ),
                    value: _tasksEnabled,
                    onChanged: (value) {
                      setState(() => _tasksEnabled = value);
                      _setPreference('notif_pref_tasks', value);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.calendar_today),
                    title: const Text('Eventos'),
                    subtitle: const Text(
                      'Lembretes de eventos do calendário',
                    ),
                    value: _eventsEnabled,
                    onChanged: (value) {
                      setState(() => _eventsEnabled = value);
                      _setPreference('notif_pref_events', value);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.group),
                    title: const Text('Sala de Estudo'),
                    subtitle: const Text(
                      'Atividade nas salas de estudo que você participa',
                    ),
                    value: _studyRoomEnabled,
                    onChanged: (value) {
                      setState(() => _studyRoomEnabled = value);
                      _setPreference('notif_pref_studyroom', value);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.campaign),
                    title: const Text('Novidades do App'),
                    subtitle: const Text(
                      'Anúncios e novidades do Estudazz',
                    ),
                    value: _updatesEnabled,
                    onChanged: (value) {
                      setState(() => _updatesEnabled = value);
                      _setPreference('notif_pref_updates', value);
                    },
                  ),
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

  Widget _buildPermissionStatusCard() {
    return ListTile(
      leading: Icon(
        _permissionGranted
            ? Icons.notifications_active
            : Icons.notifications_off,
        color: _permissionGranted ? ConstColors.greenColor : ConstColors.redColor,
      ),
      title: Text(
        _permissionGranted
            ? 'Notificações ativadas'
            : 'Notificações desativadas',
      ),
      subtitle: Text(
        _permissionGranted
            ? 'Você receberá lembretes e novidades do Estudazz.'
            : 'Ative para receber lembretes de tarefas, eventos e novidades.',
      ),
      trailing:
          _permissionGranted
              ? null
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConstColors.orangeColor,
                  foregroundColor: ConstColors.whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await NotificationPermissionDialog.showNotificationPermissionDialog(
                    context: context,
                  );
                  _refreshPermissionStatus();
                },
                child: const Text('Ativar'),
              ),
    );
  }
}
