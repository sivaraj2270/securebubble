import 'package:flutter/services.dart';

class NativeService {
  static const MethodChannel _channel =
  MethodChannel('securebubble/native');

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
}