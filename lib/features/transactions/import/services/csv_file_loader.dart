import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'csv_file_loader_stub.dart'
    if (dart.library.io) 'csv_file_loader_io.dart';

final csvFileLoaderProvider = Provider<CsvFileLoader>((ref) {
  return createCsvFileLoader();
});

abstract interface class CsvFileLoader {
  Future<CsvFileLoadResult> load(String path);
}

class CsvFileLoadResult {
  const CsvFileLoadResult._({
    required this.success,
    required this.content,
    required this.message,
  });

  const CsvFileLoadResult.success({
    required String content,
    required String message,
  }) : this._(success: true, content: content, message: message);

  const CsvFileLoadResult.failure({required String message})
    : this._(success: false, content: null, message: message);

  final bool success;
  final String? content;
  final String message;
}
