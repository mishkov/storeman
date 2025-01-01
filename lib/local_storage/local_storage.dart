abstract class LocalStorage {
  Future<void> putString(String key, String value);

  Future<String?> getString(String key);
}
