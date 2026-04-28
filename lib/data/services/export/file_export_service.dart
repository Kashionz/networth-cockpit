import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_export_service_factory.dart';

final exportFileServiceProvider = Provider<ExportFileService>(
  (ref) => createExportFileService(),
);

abstract interface class ExportFileService {
  Future<ExportSaveResult> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
}

class ExportSaveResult {
  const ExportSaveResult({
    required this.outputLocation,
    required this.downloadTriggered,
  });

  final String outputLocation;
  final bool downloadTriggered;
}
