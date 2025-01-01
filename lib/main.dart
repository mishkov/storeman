import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storeman/clean_flutter_projects/clean_flutter_projects_bloc.dart';
import 'package:storeman/disk_space_meter/ffi_space_meter.dart';
import 'package:storeman/local_storage/shared_preferences_local_storage.dart';
import 'package:storeman/repositories/local_storage_last_used_values_repository.dart';
import 'package:storeman/storeman_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: CleanFlutterProjectsBloc(
            CleanFlutterProjectsState(
              isAddingProjectsFromFolder: false,
              isLoadingLastUsedValues: false,
              isCleaningProjects: false,
              projectFolders: [],
              projects: [],
              ignoredProjectPaths: [],
              addingProjectError: null,
              loadingLastUsedValuesError: null,
              cleaningProjectsError: null,
              // TODO: Don't hardcode the path because other users won't be able to use the program.
              pathToBin:
                  '/Volumes/Macintosh HD/Users/mishkov/Projects/Projects Bin',
              foldersToDelete: [
                'build',
                '.dart_tool',
                'android/app/build',
                'ios/Pods'
              ],
              cleanedSpaceDuringLastRunInBytes: -1,
            ),
            spaceMeter: FfiSpaceMeter(),
            lastUsedValuedRepository: LocalStorageLastUsedValuesRepository(
              localStorage: SharedPreferencesLocalStorage(),
            ),
          )..add(LoadLastUsedValues()),
        ),
      ],
      child: const StoremanApp(),
    ),
  );
}
