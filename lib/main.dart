import 'dart:ffi';
import 'dart:io' as io;

import 'package:flutter/material.dart';

import 'directory_utility_bindings.dart';

void main() {
  runApp(const StoremanApp());
}

class StoremanApp extends StatelessWidget {
  const StoremanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _directoryPathController = TextEditingController(
    text: '/Users/mishkov/Library/Developer/CoreSimulator/Devices/',
  );
  List<ResultItem> _result = [];

  DirectoryUtility? _lib;
  SizeCalculator? _utility;

  @override
  void initState() {
    super.initState();
    DynamicLibrary.open('libswiftapi.dylib');
    final dynamicLibrary = DynamicLibrary.process();
    _lib = DirectoryUtility(dynamicLibrary);
    _utility = SizeCalculator.new1(_lib!);
  }

  List<ResultItem> _getSizesOfEntitiesIn(io.Directory directory) {
    final List<ResultItem> result = [];

    try {
      final entities = directory.listSync(followLinks: false);
      for (final entity in entities) {
        int totalSize = 0;

        if (entity is io.Directory) {
          totalSize = _utility!.getFolderSizeOnDiskInBytesWithPath_(
              NSString(_lib!, entity.path));
        } else if (entity is io.File) {
          totalSize = entity.lengthSync();
        } else {
          totalSize = -1;
        }

        final String name;
        if (entity.path.startsWith(directory.path)) {
          name = entity.path.substring(directory.path.length);
        } else {
          name = entity.path;
        }

        result.add(
          ResultItem(
            entityName: name,
            entirySizeIsBytes: totalSize,
          ),
        );
      }
    } catch (e) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text('Failed to calculate sizes of files! $e'),
      ));
    }

    return result;
  }

  String _getPrettyFileSize(int sizeInBytes) {
    final levelToSuffixMap = {
      0: 'B',
      1: 'KB',
      2: 'MB',
      3: 'GB',
    };
    int level = 0;
    double result = sizeInBytes.toDouble();
    while (result > 1024.0) {
      result /= 1024;
      level++;
    }

    return '${result.toStringAsFixed(2)} ${levelToSuffixMap[level] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _directoryPathController,
                decoration: const InputDecoration(
                  labelText: 'Path to directory',
                  enabledBorder: OutlineInputBorder(),
                  errorBorder: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(),
                  disabledBorder: OutlineInputBorder(),
                  focusedErrorBorder: OutlineInputBorder(),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final directory = io.Directory(_directoryPathController.text);
                  if (!directory.existsSync()) {
                    messenger.removeCurrentSnackBar();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Directory is not found!'),
                      ),
                    );

                    return;
                  }
                  setState(() {
                    _result = _getSizesOfEntitiesIn(directory);
                    _result.sort(
                      (a, b) {
                        if (a.entirySizeIsBytes == b.entirySizeIsBytes) {
                          return 0;
                        } else if (a.entirySizeIsBytes > b.entirySizeIsBytes) {
                          return -1;
                        } else {
                          return 1;
                        }
                      },
                    );
                  });

                  // showDialog(
                  //   context: context,
                  //   builder: (context) {
                  //     return Padding(
                  //       padding: const EdgeInsets.all(24.0),
                  //       child: Container(
                  //         decoration: BoxDecoration(
                  //           color:
                  //               Theme.of(context).scaffoldBackgroundColor,
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         padding: const EdgeInsets.all(8.0),
                  //         child: Scaffold(
                  //           backgroundColor: Colors.transparent,
                  //           body: Center(
                  //             child: Column(
                  //               mainAxisSize: MainAxisSize.min,
                  //               crossAxisAlignment:
                  //                   CrossAxisAlignment.center,
                  //               children: [
                  //                 const Text('Size of the directory:'),
                  //                 const SizedBox(height: 16),
                  //                 Text('$size bytes'),
                  //                 const SizedBox(height: 16),
                  //                 Text('${size / 1024} kilo bytes'),
                  //                 const SizedBox(height: 16),
                  //                 Text(
                  //                     '${size / (math.pow(1024, 2))} mega bytes'),
                  //                 const SizedBox(height: 16),
                  //                 Text(
                  //                     '${size / (math.pow(1024, 3))} giga bytes'),
                  //                 Text('$size bytes'),
                  //                 const Spacer(),
                  //                 TextButton(
                  //                   onPressed: Navigator.of(context).pop,
                  //                   child: const Text('OK'),
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // );
                },
                child: const Text('Calculate size'),
              ),
              _result.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _result.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(_result[index].entityName),
                              ),
                              Text(
                                _getPrettyFileSize(
                                  _result[index].entirySizeIsBytes,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text('Результатов нет'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultItem {
  final String entityName;
  final int entirySizeIsBytes;

  ResultItem({
    required this.entityName,
    required this.entirySizeIsBytes,
  });
}
