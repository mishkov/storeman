import 'dart:async';
import 'dart:ffi';

import 'color_generator.dart';
import 'directory_utility_bindings.dart';
import 'multi_level_pie_chart.dart';
import 'result_item.dart';

import 'dart:io' as io;

class HomeBloc {
  final _chartDataStreamController =
      StreamController<List<PieChartSectionData>>();
  final _resultStreamController = StreamController<List<ResultItem>>();

  DirectoryUtility? _lib;
  SizeCalculator? _utility;

  Stream<List<PieChartSectionData>> get chartDataStream {
    return _chartDataStreamController.stream;
  }

  Stream<List<ResultItem>> get resultStream {
    return _resultStreamController.stream;
  }

  Future<void> init() async {
    DynamicLibrary.open('libswiftapi.dylib');
    final dynamicLibrary = DynamicLibrary.process();
    _lib = DirectoryUtility(dynamicLibrary);
    _utility = SizeCalculator.new1(_lib!);
  }

  Future<void> dispose() async {
    await _chartDataStreamController.close();
    await _resultStreamController.close();
  }

  Future<void> analyzeFolder(String pathToFolder) async {
    final directory = io.Directory(pathToFolder);
    if (!directory.existsSync()) {
      _reportError('Folder is not found');

      return;
    }

    final List<ResultItem> results = [];
    final List<PieChartSectionData<int>> chartData = [];

    try {
      final entities = directory.listSync(followLinks: false);
      for (final entity in entities) {
        int totalSize = 0;

        if (entity is io.Directory) {
          totalSize = _utility!.getFolderSizeOnDiskInBytesWithPath_(
            NSString(_lib!, entity.path),
          );
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

        if (totalSize > 0) {
          chartData.add(PieChartSectionData<int>(
            value: totalSize.toDouble(),
            color: ColorGenerator.next(),
            data: totalSize,
            title: name,
          ));
          chartData.sort((a, b) {
            if (a.value == b.value) {
              return 0;
            } else if (a.value > b.value) {
              return -1;
            } else {
              return 1;
            }
          });
          _chartDataStreamController.add(_foldSmallPieces(chartData));
        }

        results.add(
          ResultItem(
            entityName: name,
            entirySizeIsBytes: totalSize,
          ),
        );
        results.sort((a, b) {
          if (a.entirySizeIsBytes == b.entirySizeIsBytes) {
            return 0;
          } else if (a.entirySizeIsBytes > b.entirySizeIsBytes) {
            return -1;
          } else {
            return 1;
          }
        });
        _resultStreamController.add(results);
      }
    } catch (e) {
      _reportError('Failed to calculate sizes of files! $e', e);
    }
  }

  List<PieChartSectionData<int>> _foldSmallPieces(
    List<PieChartSectionData<int>> data,
  ) {
    final sortedItems = List.of(data, growable: false)
      ..sort((a, b) {
        if (a.value == b.value) {
          return 0;
        } else if (a.value > b.value) {
          return 1;
        } else {
          return -1;
        }
      });

    const trescholdInPercent = 0.05;
    List<PieChartSectionData<int>> foldedItems = [];

    int totalOf(List<PieChartSectionData<int>> items) {
      return items.fold(0, (previousValue, element) {
        return previousValue + element.data;
      });
    }

    double percentOf(List<PieChartSectionData<int>> items) {
      return totalOf(items) / totalOf(sortedItems);
    }

    List<PieChartSectionData<int>> restItems = [];
    for (int i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i];

      final percent = percentOf([
        ...foldedItems,
        item,
      ]);

      if (percent <= trescholdInPercent) {
        foldedItems.add(item);
      } else {
        restItems = sortedItems.sublist(i);

        break;
      }
    }

    return [
      ...restItems,
      PieChartSectionData<int>(
        data: totalOf(foldedItems),
        value: totalOf(foldedItems).toDouble(),
        color: ColorGenerator.next(),
        title: 'Other',
      ),
    ];
  }

  void _reportError(String message, [Object? cause]) {
    final error = HomeBlocException(message, cause);

    _chartDataStreamController.addError(error);
    _resultStreamController.addError(error);
  }
}

class HomeBlocException {
  final String message;
  final Object? cause;

  HomeBlocException(this.message, [this.cause]);
}
