import 'package:flutter/material.dart';
import 'package:storeman/home_bloc.dart';
import 'package:storeman/multi_level_pie_chart.dart';
import 'package:storeman/shared/ui/path_picker.dart';

class SpaceUsage extends StatefulWidget {
  const SpaceUsage({super.key});

  @override
  State<SpaceUsage> createState() => _SpaceUsageState();
}

class _SpaceUsageState extends State<SpaceUsage>
    with SingleTickerProviderStateMixin {
  final _bloc = HomeBloc();

  Animation<double>? _animation;
  AnimationController? _controller;

  PieChartSectionData? _selectedItem;

  String _directoryPath = '';

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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        PathPicker(
          name: 'Path to directory',
          onChanged: (path) => setState(() {
            _directoryPath = path;
          }),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            await _bloc.analyzeFolder(_directoryPath);
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
                          backgroundColor =
                              Theme.of(context).primaryColor.withOpacity(0.5);
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
    );
  }
}
