import 'file_export_service.dart';
import 'file_export_service_stub.dart'
    if (dart.library.html) 'file_export_service_web.dart'
    if (dart.library.io) 'file_export_service_io.dart';

ExportFileService createExportFileService() => createPlatformExportFileService();
