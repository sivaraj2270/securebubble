import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static Future<void> showBubble() async {
    bool? permission =
    await FlutterOverlayWindow.isPermissionGranted();

    if (permission != true) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      height: 80,
      width: 80,
      overlayTitle: "SecureBubble",
      overlayContent: "Running",
    );
  }

  static Future<void> closeBubble() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}