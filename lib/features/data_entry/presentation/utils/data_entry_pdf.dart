import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/data_element_entity.dart';

/// Ethiopian period labels (see EthiopianPeriodService.formatPeriodId)
/// and data element/org unit names routinely contain Ge'ez script
/// (e.g. "መስከረም"). The `pdf` package's default fonts only cover
/// Latin-1, so Amharic text would print as blank boxes without this —
/// loaded once and reused as a font FALLBACK (Latin text still uses
/// the small built-in Helvetica; this only kicks in for glyphs
/// Helvetica doesn't have).
Future<pw.Font> _ethiopicFallbackFont() async {
  final data =
      await rootBundle.load('assets/fonts/NotoSansEthiopic-Regular.ttf');
  return pw.Font.ttf(data);
}

/// Data elements that have at least one recorded value — what actually
/// gets printed. Printing every element in [dataElements] would be
/// fine for a small Routine form, but Disease Registration loads
/// hundreds of diseases just so the picker can search them (see
/// DiseaseEntryList) and only a handful are ever recorded; printing
/// all of them would produce a mostly-blank, many-page document.
List<DataElementEntity> recordedDataElements({
  required List<DataElementEntity> dataElements,
  required Map<String, DataValueEntity> dataValues,
}) {
  return [
    for (final e in dataElements)
      if (e.categoryOptionCombos.any((c) =>
          (dataValues['${e.id}_${c.id}']?.value ?? '').trim().isNotEmpty))
        e,
  ];
}

/// Builds a printable snapshot of a data entry form: every recorded
/// data element and its category option combos, laid out as one small
/// table per element. Entirely local — the PDF is built from whatever
/// is already loaded on screen, so it works offline exactly like the
/// rest of data entry.
Future<Uint8List> buildDataEntryPdf({
  required String title,
  required String orgUnitName,
  required String periodLabel,
  required bool isDiseaseRegistration,
  required List<DataElementEntity> dataElements,
  required Map<String, DataValueEntity> dataValues,
  String? printedBy,
}) async {
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(fontFallback: [await _ethiopicFallbackFont()]),
  );
  final generatedAt = DateFormat('d MMM y, HH:mm').format(DateTime.now());
  final elements =
      recordedDataElements(dataElements: dataElements, dataValues: dataValues);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          if (isDiseaseRegistration)
            pw.Text('Disease Registration',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
          pw.SizedBox(height: 4),
          pw.Text('$orgUnitName  ·  $periodLabel',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated $generatedAt'
                '${printedBy != null && printedBy.isNotEmpty ? ' by $printedBy' : ''}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
      build: (context) => [
        if (elements.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 40),
            child: pw.Center(
              child: pw.Text('Nothing recorded yet.',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey600)),
            ),
          ),
        for (final element in elements) ...[
          pw.Text(element.displayName,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('Category', bold: true),
                  _cell('Value', bold: true),
                ],
              ),
              for (final combo in element.categoryOptionCombos)
                pw.TableRow(children: [
                  _cell(combo.displayName),
                  _cell(_valueOf(dataValues, element.id, combo.id)),
                ]),
            ],
          ),
          pw.SizedBox(height: 14),
        ],
      ],
    ),
  );

  return doc.save();
}

String _valueOf(
    Map<String, DataValueEntity> dataValues, String elementId, String comboId) {
  final v = dataValues['${elementId}_$comboId']?.value.trim() ?? '';
  return v.isEmpty ? '—' : v;
}

pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
