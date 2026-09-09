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
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnectivity();
  }

  void _checkInitialConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!(Get.isDialogOpen ?? false)) {
        Get.dialog(
          PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Row(
                children: [
                  Icon(Icons.wifi_off, color: ConstColors.redColor, size: 28),
                  SizedBox(width: 10),
                  Text('Você está offline'),
                ],
              ),
              content: const Text(
                'Parece que você perdeu a conexão com a internet.\n\nPor favor, conecte-se a uma rede para continuar usando o aplicativo sem erros.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }
    } else {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
