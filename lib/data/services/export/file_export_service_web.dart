import 'dart:html' as html;
import 'dart:typed_data';

import 'file_export_service.dart';

ExportFileService createPlatformExportFileService() {
  return const _WebExportFileService();
}

class _WebExportFileService implements ExportFileService {
  const _WebExportFileService();

  @override
  Future<ExportSaveResult> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return ExportSaveResult(
      outputLocation: 'browser-download://$fileName',
      downloadTriggered: true,
    );
  }
}
