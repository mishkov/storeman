import 'dart:async';
import 'dart:developer';
import 'dart:io' as io;

import 'package:app_error/app_error.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:storeman/app_errors/directory_does_not_exists_error.dart';
import 'package:storeman/clean_flutter_projects/last_used_values_repository.dart';
import 'package:storeman/configuration/is_debug.dart';
import 'package:storeman/core/option_or_null.dart';
import 'package:storeman/disk_space_meter/disk_space_meter.dart';

sealed class CleanFlutterProjectsEvent {}

class AddProjectsPath extends CleanFlutterProjectsEvent {
  final String path;

  AddProjectsPath({
    required this.path,
  });
}

class AddIgnoredProject extends CleanFlutterProjectsEvent {
  final String path;

  AddIgnoredProject({
    required this.path,
  });
}

class LoadLastUsedValues extends CleanFlutterProjectsEvent {}

class CleanProjects extends CleanFlutterProjectsEvent {}

class CleanFlutterProjectsBloc
    extends Bloc<CleanFlutterProjectsEvent, CleanFlutterProjectsState> {
  final DiskSpaceMeter _spaceMeter;
  final LastUsedValuesRepository _lastUsedValues;

  CleanFlutterProjectsBloc(
    super.initialState, {
    required DiskSpaceMeter spaceMeter,
    required LastUsedValuesRepository lastUsedValuedRepository,
  })  : _spaceMeter = spaceMeter,
        _lastUsedValues = lastUsedValuedRepository {
    on<AddProjectsPath>((event, emit) async {
      try {
        await _addProjectsFromFolder(event.path, emit);
      } catch (error, stackTrace) {
        emit(state.copyWith(
          addingProjectError: Value(AppError(
            'Unexpected error during adding projects',
            cause: error,
            stackTrace: stackTrace,
          )),
        ));

        if (isDebug) {
          rethrow;
        }
      }
    });

    on<LoadLastUsedValues>((event, emit) async {
      try {
        emit(state.copyWith(isLoadingLastUsedValues: true));

        final ignoredProjectPaths =
            await _lastUsedValues.getIgnoredProjectPaths();
        emit(state.copyWith(ignoredProjectPaths: ignoredProjectPaths));

        final projectFolders = await _lastUsedValues.getProjectFolders();

        emit(state.copyWith(
          projectFolders: projectFolders,
        ));

        if (projectFolders == null) {
          return;
        }

        if (projectFolders.isEmpty) {
          return;
        }

        for (final folder in projectFolders) {
          await _addProjectsFromFolder(folder, emit);
        }
      } catch (error, stackTrace) {
        emit(state.copyWith(
          loadingLastUsedValuesError: Value(AppError(
            'Unexpected Error during loading last used values',
            cause: error,
            stackTrace: stackTrace,
          )),
        ));

        if (isDebug) {
          rethrow;
        }
      } finally {
        emit(state.copyWith(isLoadingLastUsedValues: false));
      }
    });

    on<CleanProjects>((event, emit) async {
      try {
        emit(state.copyWith(
          isCleaningProjects: true,
          cleanedSpaceDuringLastRunInBytes: -1,
        ));

        var freeSpace = 0;
        final projectsCopy = state.projects;
        for (final project in projectsCopy) {
          if (state.ignoredProjectPaths.any((ignoredPath) {
            return path.equals(ignoredPath, project.path);
          })) {
            continue;
          }

          final directory = io.Directory(project.path);

          if (!directory.existsSync()) {
            emit(state.copyWith(
              addingProjectError: Value(DirectoryDoesNotExistsError(
                'Project does not exists',
                path: project.path,
              )),
            ));

            return;
          }

          final result = await io.Process.run(
            'flutter',
            ['clean'],
            workingDirectory: directory.path,
          );

          if (result.exitCode != 0) {
            log('Failed to run `flutter clean` at ${directory.path}');

            continue;
          }

          if (project.sizeInBytes != null) {
            final updatedProjectsList = List.of(state.projects);

            final projectToUpdate = updatedProjectsList.firstWhere((elemet) {
              return elemet.path == project.path;
            });

            final isRemoved = updatedProjectsList.remove(projectToUpdate);
            assert(isRemoved);

            final projectSizeAfterFlutterClean =
                await _spaceMeter.getFolderSizeInBytes(directory.path);

            final sizeDiff =
                project.sizeInBytes! - projectSizeAfterFlutterClean;

            log(
              'Cleaned by flutter clean: $sizeDiff for ${path.basename(directory.path)}',
            );

            if (sizeDiff > 0) {
              freeSpace += sizeDiff;

              updatedProjectsList.add(FlutterProject(
                path: projectToUpdate.path,
                sizeInBytes: projectSizeAfterFlutterClean,
              ));

              updatedProjectsList.sort((a, b) {
                if (a.sizeInBytes == null || b.sizeInBytes == null) {
                  return -1;
                }

                return -a.sizeInBytes!.compareTo(b.sizeInBytes!);
              });

              emit(state.copyWith(projects: updatedProjectsList));
            }
          }

          for (final targetFolder in state.foldersToDelete) {
            final movedFolderSize = await _moveFolderToBinIfExists(
              projectPath: project.path,
              relateivePathToFolder: targetFolder,
            );
            freeSpace += movedFolderSize;

            if (project.sizeInBytes != null) {
              final updatedProjectsList = List.of(state.projects);

              final projectToUpdate = updatedProjectsList.firstWhere((elemet) {
                return elemet.path == project.path;
              });

              final isRemoved = updatedProjectsList.remove(projectToUpdate);
              assert(isRemoved);

              updatedProjectsList.add(FlutterProject(
                path: projectToUpdate.path,
                sizeInBytes: projectToUpdate.sizeInBytes! - movedFolderSize,
              ));

              updatedProjectsList.sort((a, b) {
                if (a.sizeInBytes == null || b.sizeInBytes == null) {
                  return -1;
                }

                return -a.sizeInBytes!.compareTo(b.sizeInBytes!);
              });

              emit(state.copyWith(projects: updatedProjectsList));
            }
          }
        }

        emit(state.copyWith(cleanedSpaceDuringLastRunInBytes: freeSpace));
      } catch (error, stackTrace) {
        emit(state.copyWith(
          loadingLastUsedValuesError: Value(AppError(
            'Unexpected Error during cleaning projects',
            cause: error,
            stackTrace: stackTrace,
          )),
        ));

        if (isDebug) {
          rethrow;
        }
      } finally {
        emit(state.copyWith(isCleaningProjects: false));
      }
    });

    on<AddIgnoredProject>((event, emit) async {
      try {
        if (state.ignoredProjectPaths.contains(event.path)) {
          return;
        }

        final updatedIgnoredProjectsList = List.of(state.ignoredProjectPaths);
        updatedIgnoredProjectsList.add(event.path);

        await _lastUsedValues.setIgnoredProjectsPaths(
          updatedIgnoredProjectsList,
        );

        emit(state.copyWith(ignoredProjectPaths: updatedIgnoredProjectsList));
      } catch (error, stackTrace) {
        emit(state.copyWith(
          loadingLastUsedValuesError: Value(AppError(
            'Unexpected Error during adding ignored project',
            cause: error,
            stackTrace: stackTrace,
          )),
        ));

        if (isDebug) {
          rethrow;
        }
      }
    });
  }

  Future<void> _addProjectsFromFolder(
    String path,
    Emitter<CleanFlutterProjectsState> emit,
  ) async {
    try {
      emit(state.copyWith(isAddingProjectsFromFolder: true));

      // TODO: move this implementation details to somewhere else.
      final directory = io.Directory(path);

      if (!directory.existsSync()) {
        emit(state.copyWith(
          addingProjectError: Value(DirectoryDoesNotExistsError(
            'Directory does not exists',
            path: path,
          )),
        ));

        return;
      }

      await _addProjectFolder(path, emit);

      final entities = directory.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is! io.Directory) {
          continue;
        }

        if (!await _isFlutterProject(entity)) {
          continue;
        }

        final size = await _spaceMeter.getFolderSizeInBytes(entity.path);

        final project = FlutterProject(
          path: entity.path,
          sizeInBytes: size,
        );

        if (state.projects.contains(project)) {
          continue;
        }

        final updatedProjectsList = List.of(state.projects);
        updatedProjectsList.add(project);
        updatedProjectsList.sort((a, b) {
          if (a.sizeInBytes == null || b.sizeInBytes == null) {
            return -1;
          }

          return -a.sizeInBytes!.compareTo(b.sizeInBytes!);
        });
        emit(state.copyWith(projects: updatedProjectsList));
      }
    } finally {
      emit(state.copyWith(isAddingProjectsFromFolder: false));
    }
  }

  Future<void> _addProjectFolder(
    String path,
    Emitter<CleanFlutterProjectsState> emit,
  ) async {
    if (state.projectFolders.contains(path)) {
      return;
    }

    final updatedProjectFoldersList = List.of(state.projectFolders);
    updatedProjectFoldersList.add(path);

    emit(state.copyWith(projectFolders: updatedProjectFoldersList));

    await _lastUsedValues.setProjectFolders(state.projectFolders);
  }

  Future<bool> _isFlutterProject(io.Directory folder) async {
    return await folder
        .list()
        .any((entity) => path.basename(entity.path) == 'pubspec.yaml');
  }

  /// Moves folder to bin and returns number of free space in bytes.
  Future<int> _moveFolderToBinIfExists({
    required String projectPath,
    required String relateivePathToFolder,
  }) async {
    final folder = io.Directory(path.join(projectPath, relateivePathToFolder));
    if (!await folder.exists()) {
      return 0;
    }

    final newLocation = path.join(
      state.pathToBin,
      path.basename(projectPath),
      relateivePathToFolder,
    );

    final newLocationFolder = io.Directory(newLocation).parent;
    if (!await newLocationFolder.exists()) {
      await newLocationFolder.create(recursive: true);
    }

    int uniqueNumber = 1;
    var newLocationWithUniqueName = newLocation;
    while (await io.Directory(newLocationWithUniqueName).exists()) {
      newLocationWithUniqueName = '$newLocation$uniqueNumber';
      uniqueNumber++;
    }

    await folder.rename(newLocationWithUniqueName);

    final movedFolderSize = await _spaceMeter.getFolderSizeInBytes(
      newLocationWithUniqueName,
    );

    return movedFolderSize;
  }
}

class CleanFlutterProjectsState extends Equatable {
  final bool isLoadingLastUsedValues;
  final bool isAddingProjectsFromFolder;
  final bool isCleaningProjects;
  final List<String> projectFolders;
  final List<FlutterProject> projects;
  final AppError? addingProjectError;
  final AppError? loadingLastUsedValuesError;
  final AppError? cleaningProjectsError;
  final String pathToBin;
  final int cleanedSpaceDuringLastRunInBytes;
  final List<String> ignoredProjectPaths;

  /// In relative format like `build`, '.dart_tool`, `android/app/build`.
  final List<String> foldersToDelete;

  const CleanFlutterProjectsState({
    required this.isLoadingLastUsedValues,
    required this.isAddingProjectsFromFolder,
    required this.isCleaningProjects,
    required this.projectFolders,
    required this.projects,
    required this.addingProjectError,
    required this.loadingLastUsedValuesError,
    required this.cleaningProjectsError,
    required this.pathToBin,
    required this.cleanedSpaceDuringLastRunInBytes,
    required this.ignoredProjectPaths,
    required this.foldersToDelete,
  });

  @override
  List<Object?> get props => [
        isLoadingLastUsedValues,
        isAddingProjectsFromFolder,
        isCleaningProjects,
        projectFolders,
        projects,
        addingProjectError,
        loadingLastUsedValuesError,
        cleaningProjectsError,
        pathToBin,
        cleanedSpaceDuringLastRunInBytes,
        ignoredProjectPaths,
        foldersToDelete,
      ];

  CleanFlutterProjectsState copyWith({
    bool? isLoadingLastUsedValues,
    bool? isAddingProjectsFromFolder,
    bool? isCleaningProjects,
    List<String>? projectFolders,
    List<FlutterProject>? projects,
    OptionOrNull<AppError>? addingProjectError,
    OptionOrNull<AppError>? loadingLastUsedValuesError,
    OptionOrNull<AppError>? cleaningProjectsError,
    String? pathToBin,
    int? cleanedSpaceDuringLastRunInBytes,
    List<String>? ignoredProjectPaths,
    List<String>? foldersToDelete,
  }) {
    return CleanFlutterProjectsState(
      isLoadingLastUsedValues:
          isLoadingLastUsedValues ?? this.isLoadingLastUsedValues,
      isAddingProjectsFromFolder:
          isAddingProjectsFromFolder ?? this.isAddingProjectsFromFolder,
      isCleaningProjects: isCleaningProjects ?? this.isCleaningProjects,
      projectFolders: projectFolders ?? this.projectFolders,
      projects: projects ?? this.projects,
      addingProjectError: addingProjectError == null
          ? this.addingProjectError
          : addingProjectError.value,
      loadingLastUsedValuesError: loadingLastUsedValuesError == null
          ? this.loadingLastUsedValuesError
          : loadingLastUsedValuesError.value,
      cleaningProjectsError: cleaningProjectsError == null
          ? this.cleaningProjectsError
          : cleaningProjectsError.value,
      pathToBin: pathToBin ?? this.pathToBin,
      cleanedSpaceDuringLastRunInBytes: cleanedSpaceDuringLastRunInBytes ??
          this.cleanedSpaceDuringLastRunInBytes,
      ignoredProjectPaths: ignoredProjectPaths ?? this.ignoredProjectPaths,
      foldersToDelete: foldersToDelete ?? this.foldersToDelete,
    );
  }
}

class FlutterProject extends Equatable {
  final String path;
  final int? sizeInBytes;

  const FlutterProject({
    required this.path,
    required this.sizeInBytes,
  });

  @override
  List<Object?> get props => [path, sizeInBytes];
}
