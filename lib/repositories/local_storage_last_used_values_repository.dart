import 'dart:convert';

import 'package:storeman/clean_flutter_projects/last_used_values_repository.dart';
import 'package:storeman/local_storage/local_storage.dart';

class LocalStorageLastUsedValuesRepository implements LastUsedValuesRepository {
  final LocalStorage _localStorage;

  static const _projectsFolderListKey = '_projectsFolderListKey';
  static const _ignoredProjectPathsKey = '_ignoredProjectPathsKey';

  LocalStorageLastUsedValuesRepository({required LocalStorage localStorage})
      : _localStorage = localStorage;

  @override
  Future<List<String>?> getProjectFolders() async {
    final rawList = await _localStorage.getString(_projectsFolderListKey);

    if (rawList == null) {
      return null;
    }

    return (jsonDecode(rawList) as List)
        .map((rawFolder) => rawFolder.toString())
        .toList();
  }

  @override
  Future<void> setProjectFolders(List<String> folders) async {
    await _localStorage.putString(_projectsFolderListKey, jsonEncode(folders));
  }

  @override
  Future<List<String>?> getIgnoredProjectPaths() async {
    final rawList = await _localStorage.getString(_ignoredProjectPathsKey);

    if (rawList == null) {
      return null;
    }

    return (jsonDecode(rawList) as List)
        .map((rawFolder) => rawFolder.toString())
        .toList();
  }

  @override
  Future<void> setIgnoredProjectsPaths(List<String> paths) async {
    await _localStorage.putString(_ignoredProjectPathsKey, jsonEncode(paths));
  }
}
