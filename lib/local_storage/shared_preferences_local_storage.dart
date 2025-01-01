import 'package:shared_preferences/shared_preferences.dart';
import 'package:storeman/local_storage/local_storage.dart';

class SharedPreferencesLocalStorage implements LocalStorage {
  @override
  Future<String?> getString(String key) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    return sharedPreferences.getString(key);
  }

  @override
  Future<void> putString(String key, String value) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    await sharedPreferences.setString(key, value);
  }
}
