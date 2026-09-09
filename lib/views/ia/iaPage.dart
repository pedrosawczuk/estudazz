import 'package:estudazz_main_code/components/custom/customAppBar.dart';
import 'package:estudazz_main_code/components/custom/customSnackBar.dart';
import 'package:estudazz_main_code/components/ia/aiResponseMessage.dart';
import 'package:estudazz_main_code/components/ia/userInputMessage.dart';
import 'package:estudazz_main_code/constants/color/constColors.dart';
import 'package:estudazz_main_code/constants/constSizedBox.dart';
import 'package:estudazz_main_code/models/ia/iaChatModel.dart';
import 'package:estudazz_main_code/services/ia/iaChatStorageService.dart';
import 'package:estudazz_main_code/services/ia/iaGeminiServices.dart';
import 'package:flutter/material.dart';

class IaPage extends StatefulWidget {
  const IaPage({super.key});

  @override
  _IaPageState createState() => _IaPageState();
}

class _IaPageState extends State<IaPage> {
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final storedMessages = await IaChatStorageService.loadMessages();
    setState(() {
      _messages.addAll(storedMessages);
    });
  }

  final TextEditingController _messageController = TextEditingController();
  final AiGeminiServices _aiGeminiServices = AiGeminiServices();
  final List<IaChatModel> _messages = [];

  int _usedTokens = 0;
  final int _totalTokens = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleAppBar: 'Inteligência Artificial',
        showSettingsIAIcon: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return message.isUser
                    ? UserInputMessage(text: message.text)
                    : AIResponseMessage(text: message.text);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: ConstColors.grey900Color,
            child: Row(
              children: [
                const Icon(Icons.bolt, color: ConstColors.orangeColor, size: 20),
                ConstSizedBox.w8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tokens: $_usedTokens / $_totalTokens',
                        style: const TextStyle(
                          color: ConstColors.greyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ConstSizedBox.h4,
                      LinearProgressIndicator(
                        value: _usedTokens / _totalTokens,
                        backgroundColor: ConstColors.blackColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            ConstColors.orangeColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            color: ConstColors.blackColor,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    style: const TextStyle(color: ConstColors.whiteColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ConstColors.grey900Color,
                      hintText: 'Digite sua mensagem',
                      hintStyle: const TextStyle(color: ConstColors.greyColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                ConstSizedBox.w8,
                IconButton(
                  icon: const Icon(Icons.send, color: ConstColors.whiteColor),
                  onPressed: () async {
                    final userInputText = _messageController.text.trim();

                    if (userInputText.isEmpty) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message:
                            'Por favor, digite uma mensagem para enviar à IA.',
                        backgroundColor: ConstColors.redColor,
                      );
                      return;
                    }

                    setState(() {
                      _messages.insert(
                        0,
                        IaChatModel(text: userInputText, isUser: true),
                      );
                    });

                    await IaChatStorageService.saveMessages(_messages);
                    _messageController.clear();

                    try {
                      final responseIA = await _aiGeminiServices.generateText(
                        userInputText,
                      );

                      setState(() {
                        _messages.insert(
                          0,
                          IaChatModel(text: responseIA, isUser: false),
                        );
                      });

                      await IaChatStorageService.saveMessages(_messages);
                    } catch (e) {
                      CustomSnackBar.show(
                        title: 'Erro!',
                        message: 'Erro ao enviar mensagem para a IA. $e',
                        backgroundColor: ConstColors.redColor,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
