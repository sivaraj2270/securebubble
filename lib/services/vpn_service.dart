import 'dart:convert';
import 'package:flutter/services.dart';

class VpnBlockedDomain {
  final String domain;
  final String reason;
  final int riskScore;
  final String source; // "USER_BLOCKED", "AI_BLOCKED", "THREAT_INTELLIGENCE_BLOCKED"
  final String blockedAt;

  VpnBlockedDomain({
    required this.domain,
    required this.reason,
    required this.riskScore,
    required this.source,
    required this.blockedAt,
  });

  factory VpnBlockedDomain.fromJson(Map<String, dynamic> json) {
    return VpnBlockedDomain(
      domain: json['domain'] ?? '',
      reason: json['reason'] ?? 'User Blocked',
      riskScore: json['riskScore'] ?? 94,
      source: json['source'] ?? 'USER_BLOCKED',
      blockedAt: json['blockedAt'] ?? '',
    );
  }
}

class VpnServiceBridge {
  static const _channel = MethodChannel("nukezero/service");

  static Future<bool> requestVpnPermission() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>("requestVpnPermission");
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> startVpn() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>("startVpn");
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopVpn() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>("stopVpn");
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isVpnRunning() async {
    try {
      final bool? running = await _channel.invokeMethod<bool>("isVpnRunning");
      return running ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addBlockedDomain(
    String domainOrUrl, {
    String reason = "Possible Phishing",
    int riskScore = 94,
    String source = "USER_BLOCKED",
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>("addBlockedDomain", {
        "domain": domainOrUrl,
        "reason": reason,
        "riskScore": riskScore,
        "source": source,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeBlockedDomain(String domainOrUrl) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>("removeBlockedDomain", {
        "domain": domainOrUrl,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isDomainBlocked(String domainOrUrl) async {
    try {
      final bool? blocked = await _channel.invokeMethod<bool>("isDomainBlocked", {
        "domain": domainOrUrl,
      });
      return blocked ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<VpnBlockedDomain>> getBlockedDomains() async {
    try {
      final String? jsonStr = await _channel.invokeMethod<String>("getBlockedDomains");
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list.map((item) => VpnBlockedDomain.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> clearBlockedDomains() async {
    try {
      await _channel.invokeMethod("clearBlockedDomains");
    } catch (_) {}
  }
}
