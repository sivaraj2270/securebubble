import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> readText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);

      final RecognizedText recognizedText =
      await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      return "OCR Error: $e";
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}