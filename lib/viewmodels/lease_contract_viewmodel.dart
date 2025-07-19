
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/document_service.dart';

final leaseContractViewModelProvider = ChangeNotifierProvider.family<LeaseContractViewModel, String>(
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

  Future<void> createLeaseContractAndUpload() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Generáld le a PDF-et (példa, itt implementáld a saját logikádat)
      final pdfBytes = await generateLeaseContractPdf(
        tenantName,
        leaseStart,
        leaseEnd,
        monthlyRent,
      );

      // 2. Upload a Supabase Storage-be
      final fileName = 'lease_contract_${flatId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final url = await _service.uploadBytes(pdfBytes, fileName);

      // 3. Mentés metadata-val, flatId-vel és kategóriával "bérleti szerződés"
      await _service.saveMetadata(fileName, url, 'bérleti szerződés', flatId);

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Ez egy placeholder, implementáld a pdf generálást saját logika alapján
Future<Uint8List> generateLeaseContractPdf(String tenantName, DateTime start, DateTime end, double rent) async {
  // pdf csomagokkal pl. pdf, pdfx, printing stb.
  // Return egy PDF fájl tartalmát byte formában
  throw UnimplementedError('Implement pdf generálást!');
}
