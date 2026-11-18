import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/settings/game_settings.dart';
import 'package:poopy_bird/settings/settings_store.dart';
import 'package:poopy_bird/storage/key_value_store.dart';

void main() {
  test('GameSettings JSON round trip', () {
    const settings = GameSettings(
      music: false,
      sfx: true,
      haptics: false,
      leftHanded: true,
      seenTutorial: true,
    );
    expect(GameSettings.fromJson(settings.toJson()), settings);
  });

  test('SettingsStore persists through KeyValueStore', () async {
    final memory = MemoryKeyValueStore();
    final store = SettingsStore(memory);
    expect((await store.load()).music, isTrue);

    const next = GameSettings(music: false, leftHanded: true);
    await store.save(next);
    expect(await store.load(), next);
    expect(memory.values.containsKey(SettingsStore.key), isTrue);
  });
}
