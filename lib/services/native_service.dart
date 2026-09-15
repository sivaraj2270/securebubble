import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/detected_content_item.dart';

class NativeService {
  static const MethodChannel _channel =
  MethodChannel('nukezero/service');

  // Native Test
  static Future<void> showToast() async {
    try {
      await _channel.invokeMethod('showToast');
    } catch (e) {
      print("Method Channel Error: $e");
    }
  }

  // Overlay Permission
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print("Overlay Error: $e");
    }
  }

  // Start Bubble Service
  static Future<void> startBubbleService() async {
    try {
      await _channel.invokeMethod('startBubbleService');
    } catch (e) {
      print("Bubble Service Error: $e");
    }
  }

  // Stop Bubble Service
  static Future<void> stopBubbleService() async {
    try {
      await _channel.invokeMethod('stopBubbleService');
    } catch (e) {
      print("Stop Bubble Error: $e");
    }
  }

  // Scan Current Screen
  static Future<ScreenScanReportModel?> scanCurrentScreen() async {
    try {
      final String? jsonResult = await _channel.invokeMethod<String>('startScreenScan');
      if (jsonResult == null || jsonResult.isEmpty) return null;

      final Map<String, dynamic> parsed = jsonDecode(jsonResult);
      if (parsed['success'] != true) return null;

      final String pkg = parsed['packageName'] ?? "";
      final List<dynamic> rawItems = parsed['items'] ?? [];
      final List<DetectedContentItem> items = rawItems
          .map((item) => DetectedContentItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return ScreenScanReportModel.fromItems(
        packageName: pkg,
        items: items,
      );
    } catch (e) {
      print("Scan Current Screen Error: $e");
      return null;
    }
  }
}