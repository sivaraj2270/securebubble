import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'admin_service.dart';

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
  static const platform = MethodChannel("nukezero/service");

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_filename');
  }

  /// Synchronizes all saved blocklist items to native Android BlockedDomainManager
  /// and ensures system-wide DNS blocking is active.
  static Future<void> syncNativeBlocklist() async {
    try {
      final list = await getBlocklist();
      for (final item in list) {
        final domain = extractDomain(item.domain.isNotEmpty ? item.domain : item.url);
        await platform.invokeMethod("addBlockedDomain", {
          "domain": domain,
          "reason": item.threatReason,
          "riskScore": item.riskScore,
          "source": "USER_BLOCKED",
        });
      }
    } catch (e) {
      debugPrint("Error syncing native blocklist: $e");
    }
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

    // 1. Check native Android BlockedDomainManager first
    try {
      final bool nativeBlocked = await platform.invokeMethod("isDomainBlocked", {"domain": domain});
      if (nativeBlocked) return true;
    } catch (_) {}

    // 2. Check local JSON storage
    final list = await getBlocklist();
    return list.any((item) =>
      item.url.toLowerCase() == rawUrl.toLowerCase() ||
      item.domain.toLowerCase() == domain.toLowerCase()
    );
  }

  /// Blocks a URL and domain system-wide across all mobile phone applications and browsers.
  static Future<void> blockUrl(String url, int riskScore, String reason) async {
    final list = await getBlocklist();
    final domain = extractDomain(url);

    // 1. Save to local JSON storage
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

    // 2. Add domain natively to Android BlockedDomainManager for system-wide DNS interception
    try {
      await platform.invokeMethod("addBlockedDomain", {
        "domain": domain,
        "reason": reason,
        "riskScore": riskScore,
        "source": "USER_BLOCKED",
      });
    } catch (e) {
      debugPrint("Failed to add native blocked domain: $e");
    }

    // 3. Ensure Local VPN DNS Firewall Service is active so browsers cannot resolve the domain
    try {
      await platform.invokeMethod("startVpn");
    } catch (e) {
      debugPrint("Failed to start VPN firewall: $e");
    }

    // 4. Sync block rule with Technitium DNS server backend
    try {
      await AdminService().blockDomain(domain, reason: reason);
    } catch (e) {
      debugPrint("Failed to block domain on Technitium DNS: $e");
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

    // 1. Remove from native Android BlockedDomainManager
    try {
      await platform.invokeMethod("removeBlockedDomain", {"domain": domain});
    } catch (e) {
      debugPrint("Failed to remove native blocked domain: $e");
    }

    // 2. Unblock on Technitium DNS server backend
    try {
      await AdminService().unblockDomain(domain);
    } catch (e) {
      debugPrint("Failed to unblock domain on Technitium DNS: $e");
    }
  }

  static Future<void> clearBlocklist() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    // Clear native Android BlockedDomainManager
    try {
      await platform.invokeMethod("clearBlockedDomains");
    } catch (e) {
      debugPrint("Failed to clear native blocked domains: $e");
    }
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
