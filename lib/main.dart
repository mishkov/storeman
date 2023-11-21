import 'dart:ffi';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:storeman/color_generator.dart';
import 'package:storeman/multi_level_pie_chart.dart';

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
    text: '/Users/mishkov/Library/',
  );
  List<ResultItem> _result = [];

  DirectoryUtility? _lib;
  SizeCalculator? _utility;

  int touchedIndex = -1;

  final List<PieChartSectionData> _chartData = [];

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

        _chartData.add(PieChartSectionData(
          value: totalSize.toDouble(),
          color: ColorGenerator.next(),
          data: totalSize,
          title: name,
        ));
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
      body: Padding(
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
                  
                  _chartData.sort(
                    (a, b) {
                      if (a.value == b.value) {
                        return 0;
                      } else if (a.value > b.value) {
                        return -1;
                      } else {
                        return 1;
                      }
                    },
                  );
                });
              },
              child: const Text('Calculate size'),
            ),
            _result.isNotEmpty
                ? Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 400,
                          child: MultiLevelPieChart(data: _chartData),
                        ),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: _result.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('Результатов нет'),
                  ),
          ],
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
