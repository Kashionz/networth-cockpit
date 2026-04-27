import 'dart:io';

import 'csv_file_loader.dart';

CsvFileLoader createCsvFileLoader() => const _IoCsvFileLoader();

class _IoCsvFileLoader implements CsvFileLoader {
  const _IoCsvFileLoader();

  @override
  Future<CsvFileLoadResult> load(String path) async {
    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      return const CsvFileLoadResult.failure(message: '請輸入 CSV 檔案路徑。');
    }

    final file = File(trimmedPath);
    final exists = await file.exists();
    if (!exists) {
      return CsvFileLoadResult.failure(message: '找不到檔案：$trimmedPath');
    }

    try {
      final content = await file.readAsString();
      return CsvFileLoadResult.success(content: content, message: '已讀取檔案內容。');
    } catch (_) {
      return CsvFileLoadResult.failure(message: '檔案讀取失敗，請確認 CSV 編碼與權限。');
    }
  }
}
