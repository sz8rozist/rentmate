import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/document_service.dart';

final leaseContractViewModelProvider =
    ChangeNotifierProvider.family<LeaseContractViewModel, String>(
      (ref, flatId) => LeaseContractViewModel(flatId),
    );

class LeaseContractViewModel extends ChangeNotifier {
  final String flatId;
  final DocumentService _service = DocumentService();

  LeaseContractViewModel(this.flatId);

  // Például szerződés adatok (ezt bővítheted)
  String tenantName = '';
  DateTime leaseStart = DateTime.now();
  DateTime leaseEnd = DateTime.now().add(const Duration(days: 365));
  double monthlyRent = 0.0;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setTenantName(String value) {
    tenantName = value;
    notifyListeners();
  }

  void setLeaseStart(DateTime date) {
    leaseStart = date;
    notifyListeners();
  }

  void setLeaseEnd(DateTime date) {
    leaseEnd = date;
    notifyListeners();
  }

  void setMonthlyRent(double value) {
    monthlyRent = value;
    notifyListeners();
  }
  Uint8List? signature;

  void setSignature(Uint8List image) {
    signature = image;
    notifyListeners();
  }
  Future<void> createLeaseContractAndUpload() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pdfBytes = await generateLeaseContractPdf(
        tenantName,
        leaseStart,
        leaseEnd,
        monthlyRent,
      );

      final originalName = 'berleti_szerzodes.pdf';
      final storageKey = await _service.uploadBytes(pdfBytes, originalName);

      await _service.saveMetadata(
        originalName: originalName,
        storageKey: storageKey,
        category: 'Szerződés',
        flatId: flatId,
      );
    } catch (e) {
      debugPrint('Szerződés generálás/feltöltés hiba: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List> generateLeaseContractPdf(
      String tenantName,
      DateTime start,
      DateTime end,
      double rent,
      ) async {
    final pdf = pw.Document();

    // Betűtípus betöltése
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Ha van aláírás, képpé konvertáljuk
    pw.MemoryImage? signatureImage;
    if (signature != null) {
      signatureImage = pw.MemoryImage(signature!);
    }

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Bérleti szerződés', style: pw.TextStyle(font: ttf, fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Albérlő neve: $tenantName', style: pw.TextStyle(font: ttf)),
            pw.Text('Kezdés dátuma: ${start.toLocal()}', style: pw.TextStyle(font: ttf)),
            pw.Text('Lejárat dátuma: ${end.toLocal()}', style: pw.TextStyle(font: ttf)),
            pw.Text('Havi bérleti díj: ${rent.toStringAsFixed(0)} Ft', style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 20),
            pw.Text('Ez egy automatikusan generált szerződés.', style: pw.TextStyle(font: ttf)),

            if (signatureImage != null) ...[
              pw.SizedBox(height: 30),
              pw.Text('Aláírás:', style: pw.TextStyle(font: ttf, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Image(signatureImage, width: 150, height: 80),
            ],
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
