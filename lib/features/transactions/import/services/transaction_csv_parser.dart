import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/imported_transaction.dart';

final transactionCsvParserProvider = Provider<TransactionCsvParser>(
  (ref) => const TransactionCsvParser(),
);

class TransactionCsvParser {
  const TransactionCsvParser();

  TransactionCsvParseResult parse(String rawCsv) {
    final normalized = rawCsv.trim();
    if (normalized.isEmpty) {
      return const TransactionCsvParseResult.failure('請先提供 CSV 內容。');
    }

    final delimiter = _detectDelimiter(normalized);
    final rows = _splitCsvRows(normalized, delimiter: delimiter);
    if (rows.isEmpty) {
      return const TransactionCsvParseResult.failure('讀不到任何 CSV 列，請確認檔案內容。');
    }

    final hasHeader = _looksLikeHeader(rows.first);
    final header = hasHeader ? rows.first : const <String>[];
    final dataStartIndex = hasHeader ? 1 : 0;

    final dateIndex = _resolveColumnIndex(
      header: header,
      defaultIndex: hasHeader ? null : 0,
      aliases: _dateAliases,
    );
    final merchantIndex = _resolveColumnIndex(
      header: header,
      defaultIndex: hasHeader ? null : 1,
      aliases: _merchantAliases,
    );
    final amountIndex = _resolveColumnIndex(
      header: header,
      defaultIndex: hasHeader ? null : 2,
      aliases: _amountAliases,
    );
    final categoryIndex = _resolveColumnIndex(
      header: header,
      defaultIndex: null,
      aliases: _categoryAliases,
    );
    final noteIndex = _resolveColumnIndex(
      header: header,
      defaultIndex: null,
      aliases: _noteAliases,
    );

    if (merchantIndex == null || amountIndex == null) {
      return const TransactionCsvParseResult.failure(
        '找不到必要欄位，請確認至少有「商家」與「金額」。',
      );
    }

    final transactions = <ImportedTransaction>[];
    var skippedRowCount = 0;
    DateTime? periodStart;
    DateTime? periodEnd;

    for (var index = dataStartIndex; index < rows.length; index++) {
      final row = rows[index];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      final merchantName = _cell(row, merchantIndex).trim();
      final amount = _parseAmount(_cell(row, amountIndex));
      final transactedAt = _parseDate(_cell(row, dateIndex));
      if (merchantName.isEmpty || amount == null || transactedAt == null) {
        skippedRowCount += 1;
        continue;
      }

      final csvCategory = _cell(row, categoryIndex);
      final note = _cell(row, noteIndex).trim();
      final suggestion = _suggestCategory(
        merchantName: merchantName,
        csvCategory: csvCategory,
      );

      final transaction = ImportedTransaction(
        id: 'csv-${index + 1}',
        transactedAt: transactedAt,
        merchantName: merchantName,
        amount: amount,
        suggestedCategory: suggestion.category,
        reason: suggestion.reason,
        confidence: suggestion.confidence,
        note: note.isEmpty ? null : note,
        newMerchant: suggestion.newMerchant,
      );
      transactions.add(transaction);

      periodStart = periodStart == null || transactedAt.isBefore(periodStart)
          ? transactedAt
          : periodStart;
      periodEnd = periodEnd == null || transactedAt.isAfter(periodEnd)
          ? transactedAt
          : periodEnd;
    }

    if (transactions.isEmpty) {
      return const TransactionCsvParseResult.failure(
        '找不到可用交易列，請確認日期、商家與金額欄位內容。',
      );
    }

    return TransactionCsvParseResult.success(
      transactions: transactions,
      periodStart: periodStart ?? DateTime.now(),
      periodEnd: periodEnd ?? DateTime.now(),
      skippedRowCount: skippedRowCount,
    );
  }

  int _detectDelimiter(String csvContent) {
    final firstLine = csvContent.split(RegExp(r'\r?\n')).first;
    final commaCount = ','.allMatches(firstLine).length;
    final semicolonCount = ';'.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;
    if (tabCount > commaCount && tabCount > semicolonCount) {
      return '\t'.codeUnitAt(0);
    }
    if (semicolonCount > commaCount) {
      return ';'.codeUnitAt(0);
    }
    return ','.codeUnitAt(0);
  }

  List<List<String>> _splitCsvRows(String input, {required int delimiter}) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < input.length; index++) {
      final char = input.codeUnitAt(index);
      final isQuote = char == '"'.codeUnitAt(0);
      final isDelimiter = char == delimiter;
      final isCarriageReturn = char == '\r'.codeUnitAt(0);
      final isLineFeed = char == '\n'.codeUnitAt(0);

      if (isQuote) {
        final nextIndex = index + 1;
        final nextIsQuote =
            nextIndex < input.length &&
            input.codeUnitAt(nextIndex) == '"'.codeUnitAt(0);
        if (inQuotes && nextIsQuote) {
          cell.write('"');
          index += 1;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (!inQuotes && isDelimiter) {
        currentRow.add(cell.toString().trim());
        cell.clear();
        continue;
      }

      if (!inQuotes && (isLineFeed || isCarriageReturn)) {
        currentRow.add(cell.toString().trim());
        cell.clear();
        if (currentRow.isNotEmpty &&
            currentRow.any((value) => value.isNotEmpty)) {
          rows.add(List<String>.from(currentRow));
        }
        currentRow.clear();
        if (isCarriageReturn &&
            index + 1 < input.length &&
            input.codeUnitAt(index + 1) == '\n'.codeUnitAt(0)) {
          index += 1;
        }
        continue;
      }

      cell.writeCharCode(char);
    }

    currentRow.add(cell.toString().trim());
    if (currentRow.any((value) => value.isNotEmpty)) {
      rows.add(List<String>.from(currentRow));
    }

    return rows;
  }

  bool _looksLikeHeader(List<String> row) {
    final normalized = row.map(_normalizeHeader).toList(growable: false);
    final hasKnownAlias = normalized.any(
      (value) =>
          _dateAliases.contains(value) ||
          _merchantAliases.contains(value) ||
          _amountAliases.contains(value),
    );
    if (hasKnownAlias) {
      return true;
    }
    final numbers = row.where((value) => num.tryParse(value) != null).length;
    return numbers <= 1;
  }

  int? _resolveColumnIndex({
    required List<String> header,
    required Set<String> aliases,
    required int? defaultIndex,
  }) {
    if (header.isEmpty) {
      return defaultIndex;
    }

    for (var index = 0; index < header.length; index++) {
      final normalized = _normalizeHeader(header[index]);
      if (aliases.contains(normalized)) {
        return index;
      }
    }
    return defaultIndex;
  }

  String _cell(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.replaceAll('.', '/').replaceAll('-', '/');
    final ymd = RegExp(r'^(\d{3,4})/(\d{1,2})/(\d{1,2})$').firstMatch(
      normalized,
    );
    if (ymd != null) {
      final yearRaw = int.tryParse(ymd.group(1)!);
      final month = int.tryParse(ymd.group(2)!);
      final day = int.tryParse(ymd.group(3)!);
      if (yearRaw != null && month != null && day != null) {
        final year = yearRaw < 1911 ? yearRaw + 1911 : yearRaw;
        return _safeDate(year, month, day);
      }
    }

    final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(
      normalized,
    );
    if (dmy != null) {
      final first = int.tryParse(dmy.group(1)!);
      final second = int.tryParse(dmy.group(2)!);
      final yearRaw = int.tryParse(dmy.group(3)!);
      if (first != null && second != null && yearRaw != null) {
        final year = yearRaw < 100 ? yearRaw + 2000 : yearRaw;
        final month = first > 12 ? second : first;
        final day = first > 12 ? first : second;
        return _safeDate(year, month, day);
      }
    }

    return DateTime.tryParse(trimmed);
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12) {
      return null;
    }
    final maxDay = DateTime(year, month + 1, 0).day;
    if (day < 1 || day > maxDay) {
      return null;
    }
    return DateTime(year, month, day);
  }

  num? _parseAmount(String raw) {
    var normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }

    var isNegative = false;
    if (normalized.startsWith('(') && normalized.endsWith(')')) {
      isNegative = true;
      normalized = normalized.substring(1, normalized.length - 1);
    }

    if (normalized.endsWith('-')) {
      isNegative = true;
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.startsWith('-')) {
      isNegative = true;
    }

    normalized = normalized.replaceAll(RegExp(r'[^\d\-,.]'), '');
    normalized = normalized.replaceAll(',', '');

    final amount = num.tryParse(normalized);
    if (amount == null) {
      return null;
    }

    return isNegative ? -amount.abs() : amount;
  }

  _CategorySuggestion _suggestCategory({
    required String merchantName,
    required String csvCategory,
  }) {
    final normalizedCategory = _normalizeHeader(csvCategory);
    final csvMapped = _csvCategoryMap[normalizedCategory];
    if (csvMapped != null) {
      return _CategorySuggestion(
        category: csvMapped,
        confidence: 0.96,
        reason: '依 CSV 原始分類欄位。',
        newMerchant: false,
      );
    }

    final normalizedMerchant = merchantName.toLowerCase();
    for (final entry in _keywordCategoryMap.entries) {
      final matched = entry.value.any(
        (keyword) => normalizedMerchant.contains(keyword),
      );
      if (matched) {
        return _CategorySuggestion(
          category: entry.key,
          confidence: _categoryConfidence[entry.key] ?? 0.9,
          reason: '依商家關鍵字建議分類。',
          newMerchant: false,
        );
      }
    }

    return const _CategorySuggestion(
      category: '其他',
      confidence: 0.62,
      reason: '新商家，建議你確認分類。',
      newMerchant: true,
    );
  }

  String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-()/]'), '');
  }
}

class TransactionCsvParseResult {
  const TransactionCsvParseResult._({
    required this.transactions,
    required this.periodStart,
    required this.periodEnd,
    required this.skippedRowCount,
    required this.errorMessage,
  });

  const TransactionCsvParseResult.success({
    required List<ImportedTransaction> transactions,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int skippedRowCount,
  }) : this._(
         transactions: transactions,
         periodStart: periodStart,
         periodEnd: periodEnd,
         skippedRowCount: skippedRowCount,
         errorMessage: null,
       );

  const TransactionCsvParseResult.failure(String message)
    : this._(
        transactions: const <ImportedTransaction>[],
        periodStart: null,
        periodEnd: null,
        skippedRowCount: 0,
        errorMessage: message,
      );

  final List<ImportedTransaction> transactions;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int skippedRowCount;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

class _CategorySuggestion {
  const _CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reason,
    required this.newMerchant,
  });

  final String category;
  final double confidence;
  final String reason;
  final bool newMerchant;
}

const _dateAliases = <String>{
  'date',
  'transactiondate',
  'transactedat',
  'postingdate',
  '日期',
  '交易日',
  '入帳日',
  '消費日期',
};

const _merchantAliases = <String>{
  'merchant',
  'description',
  'store',
  'shop',
  'payee',
  'memo',
  'merchantname',
  '商家',
  '店家',
  '摘要',
  '說明',
  '交易摘要',
};

const _amountAliases = <String>{
  'amount',
  'total',
  'charge',
  'debit',
  'transactionamount',
  '金額',
  '交易金額',
  '消費金額',
  '應付金額',
};

const _categoryAliases = <String>{
  'category',
  '分類',
  '類別',
  'type',
};

const _noteAliases = <String>{
  'note',
  '備註',
  'remarks',
  'comment',
  'memo',
};

const _csvCategoryMap = <String, String>{
  '固定': '固定',
  '生活': '生活',
  '交通': '交通',
  '訂閱': '訂閱',
  '彈性': '彈性',
  '其他': '其他',
  'fixed': '固定',
  'living': '生活',
  'transport': '交通',
  'subscription': '訂閱',
  'flex': '彈性',
  'other': '其他',
};

const _keywordCategoryMap = <String, List<String>>{
  '交通': ['uber', 'taxi', 'metro', '捷運', '高鐵', '台鐵', '公車', '停車'],
  '訂閱': [
    'netflix',
    'spotify',
    'youtube',
    'icloud',
    'googleone',
    'subscription',
    '月費',
    '雲端',
  ],
  '固定': ['rent', '房租', '保費', '電信', '保險', '水電', '瓦斯'],
  '生活': ['cafe', 'coffee', 'market', 'supermarket', '餐', '全聯', '家樂福', 'food'],
  '彈性': ['book', 'momo', 'pchome', 'shopee', 'shop', '娛樂', '購物'],
};

const _categoryConfidence = <String, double>{
  '交通': 0.92,
  '訂閱': 0.9,
  '固定': 0.88,
  '生活': 0.87,
  '彈性': 0.8,
};
