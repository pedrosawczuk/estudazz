import 'package:estudazz_main_code/models/ia/iaChatModel.dart';
import 'package:estudazz_main_code/models/user/userModel.dart';
import 'package:estudazz_main_code/services/ia/iaChatStorageService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('isola o histórico do chat de IA por uid entre contas distintas', () async {
    await IaChatStorageService.saveMessages(
      [IaChatModel(text: 'Pergunta da conta A', isUser: true)],
      uid: 'user-a',
    );

    final userBMessages = await IaChatStorageService.loadMessages(uid: 'user-b');
    expect(userBMessages, isEmpty);

    final userAMessages = await IaChatStorageService.loadMessages(uid: 'user-a');
    expect(userAMessages, hasLength(1));
    expect(userAMessages.first.text, 'Pergunta da conta A');

    await IaChatStorageService.clearMessages(uid: 'user-a');
    final afterClear = await IaChatStorageService.loadMessages(uid: 'user-a');
    expect(afterClear, isEmpty);
  });

  test('separa campos públicos e privados no UserModel', () {
    final user = UserModel(
      uid: 'uid-123',
      displayName: 'Maria',
      username: 'maria_s',
      email: 'maria@example.com',
      birthDate: '01/01/2002',
      institution: 'USP',
      course: 'Engenharia',
      expectedGraduation: '12/2027',
      profileCompleted: true,
      photoUrl: '',
    );

    final publicMap = user.toPublicMap();
    final privateMap = user.toPrivateMap();

    expect(publicMap.containsKey('birth_date'), isFalse);
    expect(publicMap.containsKey('institution'), isFalse);
    expect(publicMap.containsKey('course'), isFalse);
    expect(publicMap.containsKey('expected_graduation'), isFalse);
    expect(publicMap['display_name'], 'Maria');
    expect(publicMap['username'], 'maria_s');

    expect(privateMap['birth_date'], '01/01/2002');
    expect(privateMap['institution'], 'USP');
    expect(privateMap['course'], 'Engenharia');
    expect(privateMap['expected_graduation'], '12/2027');

    final reconstructed = UserModel.fromMap(
      publicMap,
      'uid-123',
      privateMap: privateMap,
    );
    expect(reconstructed.birthDate, '01/01/2002');
    expect(reconstructed.institution, 'USP');
  });
}
