import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:storeman/multi_level_pie_chart.dart';

import 'home_bloc.dart';

void main() {
  runApp(const StoremanApp());
}

class StoremanApp extends StatelessWidget {
  const StoremanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _bloc = HomeBloc();

  Animation<double>? _animation;
  AnimationController? _controller;

  PieChartSectionData? _selectedItem;

  final _directoryPathController = TextEditingController(
    text: '/Users/mishkov/Library/',
  );

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _bloc.init();
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller!);
    _controller!.forward();
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
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
                IconButton(
                  onPressed: () async {
                    String? selectedDirectory =
                        await FilePicker.platform.getDirectoryPath();

                    if (selectedDirectory == null) {
                      return;
                    }

                    _directoryPathController.text = selectedDirectory;
                  },
                  icon: const Icon(Icons.folder_open_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await _bloc.analyzeFolder(_directoryPathController.text);
              },
              child: const Text('Calculate size'),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _bloc.resultStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    String? errorMessage;

                    final error = snapshot.error;
                    if (error is HomeBlocException) {
                      errorMessage = error.message;
                    }

                    return Center(
                      child: Text(
                        errorMessage ?? 'Неизвестная ошибка',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'Результатов нет',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  final results = snapshot.data!;

                  return Row(
                    children: [
                      SizedBox(
                        width: 400,
                        child: StreamBuilder(
                          stream: _bloc.chartDataStream,
                          builder: (contex, snapshot) {
                            if (snapshot.hasError) {
                              String? errorMessage;

                              final error = snapshot.error;
                              if (error is HomeBlocException) {
                                errorMessage = error.message;
                              }

                              return Center(
                                child: Text(
                                  errorMessage ?? 'Неизвестная ошибка',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: Text(
                                  'Результатов нет',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            return MultiLevelPieChart(
                              data: snapshot.data!,
                              onSectionHover: (section) {
                                setState(() {
                                  _selectedItem = section;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            var backgroundColor = Colors.transparent;

                            if (results[index].entirySizeIsBytes ==
                                _selectedItem?.data) {
                              backgroundColor = Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5);
                            }

                            return AnimatedContainer(
                              duration: const Duration(),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(results[index].entityName),
                                  ),
                                  Text(
                                    _getPrettyFileSize(
                                      results[index].entirySizeIsBytes,
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }
}
