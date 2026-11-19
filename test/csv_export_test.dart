import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/utils/csv_export.dart';

void main() {
  test('plain cells are left alone', () {
    expect(csvCell('Ali bin Abu'), 'Ali bin Abu');
    expect(csvCell(12), '12');
    expect(csvCell(null), '');
  });

  test('commas, quotes and line breaks are quoted', () {
    expect(csvCell('Tan, Mei'), '"Tan, Mei"');
    expect(csvCell('say "hi"'), '"say ""hi"""');
    expect(csvCell('a\nb'), '"a\nb"');
  });

  test('cells that would run as spreadsheet formulas are neutralised', () {
    expect(csvCell('=SUM(A1:A9)'), "'=SUM(A1:A9)");
    expect(csvCell('+60123'), "'+60123");
    expect(csvCell('@cmd'), "'@cmd");
    expect(csvCell('-5'), "'-5");
  });

  test('toCsv joins rows with CRLF and starts with a byte-order mark', () {
    final csv = toCsv([
      ['Name', 'Programme'],
      ['李明', 'Software, Eng'],
    ]);
    expect(csv.startsWith('﻿'), isTrue);
    expect(csv.substring(1), 'Name,Programme\r\n李明,"Software, Eng"\r\n');
  });
}
