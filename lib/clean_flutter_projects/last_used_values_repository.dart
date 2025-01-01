abstract class LastUsedValuesRepository {
  Future<List<String>?> getProjectFolders();

  Future<void> setProjectFolders(List<String> folders);

  Future<List<String>?> getIgnoredProjectPaths();

  Future<void> setIgnoredProjectsPaths(List<String> paths);
}
