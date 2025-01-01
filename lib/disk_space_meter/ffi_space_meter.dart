import 'dart:ffi';
import 'dart:isolate';

import 'package:storeman/directory_utility_bindings.dart';
import 'package:storeman/disk_space_meter/disk_space_meter.dart';

class FfiSpaceMeter implements DiskSpaceMeter {
  @override
  Future<int> getFolderSizeInBytes(String path) async {
    return await Isolate.run<int>(() async {
      DynamicLibrary.open('libswiftapi.dylib');
      final library = DynamicLibrary.process();
      final utility = DirectoryUtility(library);
      final calculator = SizeCalculator.new1(utility);

      return calculator.getFolderSizeOnDiskInBytesWithPath_(
        NSString(utility, path),
      );
    });
  }
}
