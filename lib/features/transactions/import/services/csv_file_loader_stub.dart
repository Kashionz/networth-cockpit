import 'csv_file_loader.dart';

CsvFileLoader createCsvFileLoader() => const _UnsupportedCsvFileLoader();

class _UnsupportedCsvFileLoader implements CsvFileLoader {
  const _UnsupportedCsvFileLoader();

  @override
  Future<CsvFileLoadResult> load(String path) async {
    return const CsvFileLoadResult.failure(
      message: '目前平台不支援直接讀取檔案路徑，請改用貼上 CSV 內容。',
    );
  }
}
