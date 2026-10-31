import 'dart:convert';
import 'package:estudazz_main_code/env.dart';
import 'package:estudazz_main_code/models/ia/iaChatModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IaChatStorageService {
  static final String _storageKey = Env.iaChatStorageKey;

  static String? _scopedKey([String? uid]) {
    final resolvedUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUid == null || resolvedUid.isEmpty) {
      return null;
    }
    return '${_storageKey}_$resolvedUid';
  }

  static Future<void> saveMessages(
    List<IaChatModel> messages, {
    String? uid,
  }) async {
    final key = _scopedKey(uid);
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();

    final jsonList =
        messages
            .map((message) => {'text': message.text, 'isUser': message.isUser})
            .toList();

    final encoded = jsonEncode(jsonList);
    await prefs.setString(key, encoded);
  }

  static Future<List<IaChatModel>> loadMessages({String? uid}) async {
    final key = _scopedKey(uid);
    if (key == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);

    if (data == null) return [];

    final decoded = jsonDecode(data) as List;
    return decoded
        .map((json) => IaChatModel(text: json['text'], isUser: json['isUser']))
        .toList();
  }

  static Future<void> clearMessages({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _scopedKey(uid);
    if (key != null) {
      await prefs.remove(key);
    }
    await prefs.remove(_storageKey);
  }
}
