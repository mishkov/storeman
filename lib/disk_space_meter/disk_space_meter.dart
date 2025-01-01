import 'package:storeman/disk_space_meter/ffi_space_meter.dart';

abstract class DiskSpaceMeter {
  factory DiskSpaceMeter() => FfiSpaceMeter();

  Future<int> getFolderSizeInBytes(String path);
}
