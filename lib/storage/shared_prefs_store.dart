import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// On-device storage backed by shared preferences.
class SharedPrefsStore implements KeyValueStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);
}
