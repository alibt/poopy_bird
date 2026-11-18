import 'dart:convert';

import '../storage/key_value_store.dart';
import 'game_settings.dart';

/// Loads and saves [GameSettings] through the shared [KeyValueStore].
class SettingsStore {
  SettingsStore(this._store);

  static const String key = 'poopy_bird.settings.v1';

  final KeyValueStore _store;

  Future<GameSettings> load() async {
    final raw = await _store.read(key);
    if (raw == null || raw.isEmpty) return const GameSettings();
    try {
      return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const GameSettings();
    }
  }

  Future<void> save(GameSettings settings) =>
      _store.write(key, jsonEncode(settings.toJson()));
}
