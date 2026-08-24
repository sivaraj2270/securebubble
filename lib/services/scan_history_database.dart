import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ScanRecord {
  final String id;
  final DateTime timestamp;
  final String urlOrItem;
  final int riskScore; // 0 to 100
  final String status; // 'SAFE', 'LOW RISK', 'SUSPICIOUS', 'DANGEROUS'
  final String threatCategory;

  ScanRecord({
    required this.id,
    required this.timestamp,
    required this.urlOrItem,
    required this.riskScore,
    required this.status,
    required this.threatCategory,
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      urlOrItem: json['urlOrItem'] ?? '',
      riskScore: json['riskScore'] ?? 0,
      status: json['status'] ?? 'SAFE',
      threatCategory: json['threatCategory'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'urlOrItem': urlOrItem,
        'riskScore': riskScore,
        'status': status,
        'threatCategory': threatCategory,
      };
}

class ScanHistoryDatabase {
  static const _fileName = 'nukezero_scan_history.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<ScanRecord>> getScanHistory() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);
      return list.map((item) => ScanRecord.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addScanRecord(ScanRecord record) async {
    try {
      final history = await getScanHistory();
      history.insert(0, record);
      final file = await _getFile();
      await file.writeAsString(jsonEncode(history.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> deleteRecord(String id) async {
    try {
      final history = await getScanHistory();
      history.removeWhere((r) => r.id == id);
      final file = await _getFile();
      await file.writeAsString(jsonEncode(history.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> clearAllHistory() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
