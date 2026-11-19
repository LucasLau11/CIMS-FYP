import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// One CSV cell. Quotes, commas and line breaks are escaped as RFC 4180
/// requires. A cell that starts with =, +, - or @ would be run as a formula by
/// Excel or Sheets, so it gets a leading apostrophe (names and emails never
/// start with those, so real data is unchanged).
String csvCell(Object? value) {
  var text = value == null ? '' : value.toString();
  if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) text = "'$text";
  if (text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r')) {
    text = '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Rows of cells to CSV text with CRLF line ends and a UTF-8 byte-order mark, so
/// Excel shows Malay and Chinese names correctly.
String toCsv(List<List<Object?>> rows) => '﻿${rows.map((r) => r.map(csvCell).join(',')).join('\r\n')}\r\n';

/// Writes [csv] to a file in the app's temporary folder and opens it with
/// whatever spreadsheet app the phone has. Returns false when that fails.
Future<bool> saveAndOpenCsv(String fileName, String csv) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(csv, flush: true);
    final result = await OpenFile.open(file.path, type: 'text/csv');
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}
