import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storeman/clean_flutter_projects/clean_flutter_projects_bloc.dart';
import 'package:storeman/shared/ui/path_picker.dart';
import 'package:storeman/shared/ui/show_error_dialog.dart';
import 'package:storeman/shared/ui/show_info_dialog.dart';

class CleanFlutterProjectsPage extends StatefulWidget {
  const CleanFlutterProjectsPage({super.key});

  @override
  State<CleanFlutterProjectsPage> createState() =>
      _CleanFlutterProjectsPageState();
}

class _CleanFlutterProjectsPageState extends State<CleanFlutterProjectsPage> {
  String? _pickedFile;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CleanFlutterProjectsBloc, CleanFlutterProjectsState>(
      listenWhen: (previous, current) {
        return previous.addingProjectError != current.addingProjectError ||
            previous.cleaningProjectsError != current.cleaningProjectsError ||
            previous.loadingLastUsedValuesError !=
                current.loadingLastUsedValuesError;
      },
      listener: (context, state) async {
        await showErrorDialog(
          context,
          state.addingProjectError?.message ?? 'No error provided',
        );
      },
      child: Center(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PathPicker(
                    name: 'Path to directory with Flutter projects',
                    onChanged: (path) => setState(() => _pickedFile = path),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final path = _pickedFile;
                    if (path == null) {
                      await showErrorDialog(
                        context,
                        'Please select at least one folder to be able to find any Flutter projects',
                        title: 'No path',
                      );

                      return;
                    }

                    context
                        .read<CleanFlutterProjectsBloc>()
                        .add(AddProjectsPath(path: path));
                  },
                  child: Text(
                    'List projects',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text('Folders with Flutter projects:'),
                        BlocBuilder<CleanFlutterProjectsBloc,
                            CleanFlutterProjectsState>(
                          builder: (context, state) {
                            if (state.projectFolders.isEmpty) {
                              return Text('No any folder added yet');
                            }

                            return ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: state.projectFolders.length,
                              itemBuilder: (context, index) {
                                final folder = state.projectFolders[index];

                                return Text(folder);
                              },
                            );
                          },
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Ignored projects'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final newPath = await showAdaptiveDialog(
                                  context: context,
                                  builder: (context) {
                                    return AddIgnoredProjectDialog();
                                  },
                                );

                                if (newPath is! String) {
                                  return;
                                }

                                if (!context.mounted) {
                                  return;
                                }

                                context
                                    .read<CleanFlutterProjectsBloc>()
                                    .add(AddIgnoredProject(path: newPath));
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                        BlocBuilder<CleanFlutterProjectsBloc,
                            CleanFlutterProjectsState>(
                          builder: (context, state) {
                            if (state.projectFolders.isEmpty) {
                              return Text('No any folder added yet');
                            }

                            return ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: state.ignoredProjectPaths.length,
                              itemBuilder: (context, index) {
                                final folder = state.ignoredProjectPaths[index];

                                return Text(folder);
                              },
                            );
                          },
                        ),
                        const Divider(),
                        Expanded(
                          child: BlocBuilder<CleanFlutterProjectsBloc,
                              CleanFlutterProjectsState>(
                            builder: (context, state) {
                              return Column(
                                children: [
                                  if (state.isAddingProjectsFromFolder)
                                    LinearProgressIndicator(),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: state.projects.length,
                                      itemBuilder: (context, index) {
                                        final project = state.projects[index];

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Text(project.path),
                                            ),
                                            Text(
                                              project.sizeInBytes.toReadable(),
                                            )
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text('Settings'),
                          const SizedBox(height: 8),
                          BlocListener<CleanFlutterProjectsBloc,
                              CleanFlutterProjectsState>(
                            listenWhen: (previous, current) {
                              return previous.isCleaningProjects !=
                                      current.isCleaningProjects &&
                                  !current.isCleaningProjects;
                            },
                            listener: (context, state) async {
                              await showInfoDialog(
                                context,
                                'Total cleaned space: ${state.cleanedSpaceDuringLastRunInBytes.toReadable()}',
                              );
                            },
                            child: ElevatedButton(
                              onPressed: () {
                                context
                                    .read<CleanFlutterProjectsBloc>()
                                    .add(CleanProjects());
                              },
                              child: BlocBuilder<CleanFlutterProjectsBloc,
                                      CleanFlutterProjectsState>(
                                  builder: (context, state) {
                                if (state.isCleaningProjects) {
                                  return CircularProgressIndicator.adaptive();
                                }

                                return Text(
                                  'Clean',
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AddIgnoredProjectDialog extends StatefulWidget {
  const AddIgnoredProjectDialog({
    super.key,
  });

  @override
  State<AddIgnoredProjectDialog> createState() =>
      _AddIgnoredProjectDialogState();
}

class _AddIgnoredProjectDialogState extends State<AddIgnoredProjectDialog> {
  String? _path;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('Add ignored project'),
      contentPadding: const EdgeInsets.all(16.0),
      children: [
        PathPicker(
          name: 'Path to ignored project',
          onChanged: (path) => setState(() {
            _path = path;
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_path);
              },
              child: Text(
                'Add',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension ByteConverter on int? {
  /// Converts bytes into a human-readable string format.
  String toReadable({int decimals = 2}) {
    if (this == null) {
      return 'No size';
    }

    if (this! <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const sizeFactor = 1024;

    int index = 0;
    double size = this!.toDouble();

    while (size >= sizeFactor && index < suffixes.length - 1) {
      size /= sizeFactor;
      index++;
    }

    return '${size.toStringAsFixed(decimals)} ${suffixes[index]}';
  }
}
