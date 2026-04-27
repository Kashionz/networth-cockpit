import 'dart:typed_data';

import 'file_export_service.dart';

ExportFileService createPlatformExportFileService() {
  return const _UnsupportedExportFileService();
}

class _UnsupportedExportFileService implements ExportFileService {
  const _UnsupportedExportFileService();

  @override
  Future<ExportSaveResult> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) {
    throw UnsupportedError(
      'Current platform does not support export yet. '
      'file=$fileName mime=$mimeType bytes=${bytes.length}',
    );
  }
}
