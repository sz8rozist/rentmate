import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
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

  // Szerződés adatok
  DateTime leaseStart = DateTime.now();
  DateTime? leaseEnd; // nullable, mert lehet határozatlan
  String deposit = '';
  String rent = '';
  String noticePeriod = '';
  String otherAgreements = '';

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLeaseStart(DateTime date) {
    leaseStart = date;
    notifyListeners();
  }

  void setLeaseEnd(DateTime? date) {
    leaseEnd = date;
    notifyListeners();
  }

  void setDeposit(String value) {
    deposit = value;
    notifyListeners();
  }

  void setRent(String value) {
    rent = value;
    notifyListeners();
  }

  void setNoticePeriod(String value) {
    noticePeriod = value;
    notifyListeners();
  }

  void setOtherAgreements(String value) {
    otherAgreements = value;
    notifyListeners();
  }

  Uint8List? signature;

  void setSignature(Uint8List image) {
    signature = image;
    notifyListeners();
  }

  Future<void> setMultipleSignatures({
    required List<Map<String, dynamic>> collected,
    required DateTime leaseStart,
    DateTime? leaseEnd,
    required String deposit,
    required String rent,
    required String noticePeriod,
    required String otherAgreements,
    required Uint8List landlordSignature
  }) async {
    _isLoading = true;
    notifyListeners();
    // Frissítjük a ViewModelben az adatokat
    this.leaseStart = leaseStart;
    this.leaseEnd = leaseEnd;
    this.deposit = deposit;
    this.rent = rent;
    this.noticePeriod = noticePeriod;
    this.otherAgreements = otherAgreements;
    try {
      // Egyszer hívjuk meg a PDF generálót az összes bérlő adataival együtt
      final pdfBytes = await generateLeaseContractPdf(
        collected,
        leaseStart,
        leaseEnd,
        deposit,
        rent,
        noticePeriod,
        otherAgreements,
        landlordSignature
      );

      // Az eredmény egy PDF, amit feltöltünk
      final originalName = 'berleti_szerzodes_${flatId}.pdf';
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
      List<Map<String, dynamic>> tenantsData,
      DateTime start,
      DateTime? end,
      String deposit,
      String rent,
      String noticePeriod,
      String otherAgreements,
      Uint8List landLordSignature,
      ) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pw.Widget dashedLine() {
      return pw.LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 5.0;
          const dashSpacing = 3.0;
          final dashCount =
          (constraints!.maxWidth / (dashWidth + dashSpacing)).floor();
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
                  (_) => pw.Container(
                width: dashWidth,
                height: 1,
                color: PdfColors.grey,
              ),
            ),
          );
        },
      );
    }

    final pw.MemoryImage landlordSigImage = pw.MemoryImage(landLordSignature);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Bérleti szerződés',
              style: pw.TextStyle(font: ttf, fontSize: 24),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Kezdés dátuma: ${start.toLocal().toIso8601String().substring(0, 10)}',
              style: pw.TextStyle(font: ttf),
            ),
            pw.Text(
              'Lejárat dátuma: ${end == null ? "Határozatlan" : end.toLocal().toIso8601String().substring(0, 10)}',
              style: pw.TextStyle(font: ttf),
            ),
            pw.Text(
              'Kaució összege: ${deposit.isEmpty ? "-" : "$deposit Ft"}',
              style: pw.TextStyle(font: ttf),
            ),
            pw.Text(
              'Havi bérleti díj: ${rent.isEmpty ? "-" : "$rent Ft"}',
              style: pw.TextStyle(font: ttf),
            ),
            pw.Text(
              'Felmondási idő: ${noticePeriod.isEmpty ? "-" : noticePeriod}',
              style: pw.TextStyle(font: ttf),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Egyéb megállapodások:',
              style: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Text(
                otherAgreements.isEmpty ? '-' : otherAgreements,
                style: pw.TextStyle(font: ttf),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Albérlők:',
              style: pw.TextStyle(font: ttf, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            ...tenantsData.map((tenant) {
              final String name = tenant['name'] ?? '';
              final Uint8List? sig = tenant['signature'];

              pw.MemoryImage? signatureImage;
              if (sig != null) {
                signatureImage = pw.MemoryImage(sig);
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (signatureImage != null) ...[
                    pw.Image(signatureImage, width: 150, height: 80),
                    pw.SizedBox(height: 5),
                  ],
                  dashedLine(),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    name,
                    style: pw.TextStyle(font: ttf, fontSize: 14),
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
            pw.SizedBox(height: 30),
            pw.Text(
              'Főbérlő aláírása:',
              style: pw.TextStyle(font: ttf, fontSize: 18),
            ),
            pw.SizedBox(height: 10),
            pw.Image(landlordSigImage, width: 150, height: 80),
            pw.SizedBox(height: 5),
            dashedLine(),
            pw.SizedBox(height: 5),
            pw.Text(
              'Főbérlő',
              style: pw.TextStyle(font: ttf, fontSize: 14),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Ez egy automatikusan generált szerződés.',
              style: pw.TextStyle(font: ttf),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

}
