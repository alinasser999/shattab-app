import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:batsh/core/services/form_draft_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('writes, restores, and clears a form draft', () async {
    await FormDraftStore.write('brief:test', {
      'description': 'دهان شقة كاملة',
      'city': 'القاهرة الجديدة',
      'specialties': ['paint'],
    });

    expect(await FormDraftStore.read('brief:test'), {
      'description': 'دهان شقة كاملة',
      'city': 'القاهرة الجديدة',
      'specialties': ['paint'],
    });

    await FormDraftStore.clear('brief:test');
    expect(await FormDraftStore.read('brief:test'), isNull);
  });

  test('drops malformed local draft data safely', () async {
    SharedPreferences.setMockInitialValues({
      'shattab_form_draft_v1:broken': '{not-json',
    });

    expect(await FormDraftStore.read('broken'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('shattab_form_draft_v1:broken'), isFalse);
  });
}
