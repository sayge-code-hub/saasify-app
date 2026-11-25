import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../auth/domain/entities/user.dart';
import '../../hrms/domain/entities/employee.dart';

/// Creates a two-page employee identity-card PDF: front first, reverse second.
/// The Sayge reverse reuses the approved print artwork rather than recreating
/// its typography in code.
abstract final class EmployeeIdCardPdfBuilder {
  static const _width = 310.0;
  static const _height = 522.0;
  static const _orange = PdfColor.fromInt(0xFFFF6A4B);

  static Future<Uint8List> build({
    required Employee employee,
    required User? user,
    required bool isSayge,
  }) async {
    final document = pw.Document();
    final logo = await _loadLogo(isSayge);
    final backSvg = isSayge
        ? await rootBundle.loadString('assets/images/id_cards/sayge_id_card_back.svg')
        : null;

    document.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(_width, _height),
        margin: pw.EdgeInsets.zero,
        build: (_) => _front(employee: employee, logo: logo),
      ),
    );
    document.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(_width, _height),
        margin: pw.EdgeInsets.zero,
        build: (_) => backSvg == null
            ? _genericBack(employee: employee, user: user, logo: logo)
            : pw.SvgImage(svg: backSvg, fit: pw.BoxFit.fill),
      ),
    );
    return Uint8List.fromList(await document.save());
  }

  static Future<pw.MemoryImage?> _loadLogo(bool isSayge) async {
    try {
      final data = await rootBundle.load(
        isSayge ? 'assets/images/sayge_logo.png' : 'assets/images/saasify_logo.png',
      );
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _cardShell(pw.Widget child) => pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(30),
          border: pw.Border.all(color: PdfColor.fromInt(0xFF36363A)),
        ),
        child: child,
      );

  static pw.Widget _front({
    required Employee employee,
    required pw.MemoryImage? logo,
  }) {
    final role = employee.designation.trim().isEmpty
        ? 'Employee'
        : employee.designation.trim();
    final phone = employee.contactNo.trim().isEmpty ? '—' : employee.contactNo.trim();
    return _cardShell(
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(19, 28, 19, 19),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null) pw.Image(logo, width: 111, height: 25),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromInt(0xFF36363A)),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(role, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Employee Code : ${employee.employeeId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 31),
            pw.Text(
              employee.employeeName,
              maxLines: 2,
              style: pw.TextStyle(color: _orange, fontSize: 32, fontWeight: pw.FontWeight.bold, lineSpacing: 0),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 28),
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF0E2D5),
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('EMPLOYEE ID CARD', style: pw.TextStyle(color: PdfColor.fromInt(0xFF6C6C6C), fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _genericBack({
    required Employee employee,
    required User? user,
    required pw.MemoryImage? logo,
  }) => _cardShell(
        pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logo != null) pw.Center(child: pw.Image(logo, width: 136, height: 34)),
              pw.Spacer(),
              pw.Text('Employee identity card', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('This card remains company property. Please return it when your employment ends.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
              pw.Spacer(),
              pw.Text(employee.employeeId, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(user?.email ?? '', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      );
}
