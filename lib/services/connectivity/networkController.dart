import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _checkInitialConnectivity();
  }

  void _checkInitialConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  bool _isOfflineDialogOpen = false;

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    final isOffline =
        connectivityResult.isEmpty ||
        connectivityResult.every((result) => result == ConnectivityResult.none);

    if (isOffline) {
      _showOfflineDialog();
    } else {
      _closeOfflineDialog();
    }
  }

  void _showOfflineDialog() {
    if (_isOfflineDialogOpen) return;
    _isOfflineDialogOpen = true;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: ConstColors.redColor, size: 28),
            SizedBox(width: 10),
            Text('Você está offline'),
          ],
        ),
        content: const Text(
          'Parece que você perdeu a conexão com a internet.\n\nAlgumas funções podem não funcionar até você se conectar novamente.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: _closeOfflineDialog,
            child: const Text('Entendi'),
          ),
        ],
      ),
    ).whenComplete(() => _isOfflineDialogOpen = false);
  }

  void _closeOfflineDialog() {
    if (!_isOfflineDialogOpen) return;
    _isOfflineDialogOpen = false;
    Get.back();
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
