import 'package:app_error/app_error.dart';

class DirectoryDoesNotExistsError extends AppError {
  final String path;

  DirectoryDoesNotExistsError(
    super.message, {
    required this.path,
    super.cause,
    super.stackTrace,
  });

  @override
  Map<String, Object?> describeDetails() => {
        'path': path,
        ...super.describeDetails(),
      };
}
