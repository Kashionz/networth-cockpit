import 'dart:io';
import 'dart:typed_data';

import 'file_export_service.dart';

ExportFileService createPlatformExportFileService() {
  return const _IoExportFileService();
}

class _IoExportFileService implements ExportFileService {
  const _IoExportFileService();

  @override
  Future<ExportSaveResult> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final exportDirectory = Directory(
      '${Directory.systemTemp.path}'
      '${Platform.pathSeparator}'
      'networth_cockpit_exports',
    );
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await file.writeAsBytes(bytes, flush: true);

    return ExportSaveResult(
      outputLocation: file.path,
      downloadTriggered: false,
    );
  }
}
