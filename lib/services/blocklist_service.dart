import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BlockedItem {
  final String url;
  final String domain;
  final int riskScore;
  final String threatReason;
  final String blockedAt;

  BlockedItem({
    required this.url,
    required this.domain,
    required this.riskScore,
    required this.threatReason,
    required this.blockedAt,
  });

  factory BlockedItem.fromJson(Map<String, dynamic> json) {
    return BlockedItem(
      url: json['url'] ?? '',
      domain: json['domain'] ?? '',
      riskScore: json['riskScore'] ?? 90,
      threatReason: json['threatReason'] ?? 'High-risk phishing target',
      blockedAt: json['blockedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'domain': domain,
      'riskScore': riskScore,
      'threatReason': threatReason,
      'blockedAt': blockedAt,
    };
  }
}

class BlocklistService {
  static const String _filename = "securebubble_blocklist.json";

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_filename');
  }

  static Future<List<BlockedItem>> getBlocklist() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final jsonStr = await file.readAsString();
      if (jsonStr.isEmpty) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => BlockedItem.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isBlocked(String rawUrl) async {
    if (rawUrl.isEmpty) return false;
    final domain = extractDomain(rawUrl);
    final list = await getBlocklist();
    return list.any((item) =>
      item.url.toLowerCase() == rawUrl.toLowerCase() ||
      item.domain.toLowerCase() == domain.toLowerCase()
    );
  }

  static Future<void> blockUrl(String url, int riskScore, String reason) async {
    final list = await getBlocklist();
    final domain = extractDomain(url);

    // Prevent duplicates
    if (!list.any((item) => item.domain.toLowerCase() == domain.toLowerCase())) {
      list.add(BlockedItem(
        url: url,
        domain: domain,
        riskScore: riskScore,
        threatReason: reason,
        blockedAt: DateTime.now().toIso8601String(),
      ));
      final file = await _getFile();
      await file.writeAsString(jsonEncode(list.map((i) => i.toJson()).toList()));
    }
  }

  static Future<void> unblockUrl(String domainOrUrl) async {
    var list = await getBlocklist();
    final domain = extractDomain(domainOrUrl);
    list.removeWhere((item) =>
      item.url.toLowerCase() == domainOrUrl.toLowerCase() ||
      item.domain.toLowerCase() == domain.toLowerCase()
    );
    final file = await _getFile();
    await file.writeAsString(jsonEncode(list.map((i) => i.toJson()).toList()));
  }

  static Future<void> clearBlocklist() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static String extractDomain(String input) {
    try {
      var clean = input.trim().toLowerCase();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'https://$clean';
      }
      final uri = Uri.parse(clean);
      final host = uri.host;
      final parts = host.split('.');
      if (parts.length >= 2) {
        return parts.sublist(parts.length - 2).join('.');
      }
      return host;
    } catch (_) {
      return input;
    }
  }
}
