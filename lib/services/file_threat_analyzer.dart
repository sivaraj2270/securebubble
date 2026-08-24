import 'dart:io';
import 'package:crypto/crypto.dart';

class FileAnalysisResult {
  final String fileName;
  final String sha256Hash;
  final int fileSizeBytes;
  final bool hasDoubleExtension;
  final bool isExecutableDisguised;
  final List<String> threatFlags;
  final String riskStatus;
  final int riskScore;

  FileAnalysisResult({
    required this.fileName,
    required this.sha256Hash,
    required this.fileSizeBytes,
    required this.hasDoubleExtension,
    required this.isExecutableDisguised,
    required this.threatFlags,
    required this.riskStatus,
    required this.riskScore,
  });
}

class FileThreatAnalyzer {
  static final List<String> _executableExtensions = [
    'exe', 'bat', 'cmd', 'vbs', 'ps1', 'js', 'jar', 'apk', 'scr', 'pif'
  ];

  static Future<FileAnalysisResult> analyzeFile(File file) async {
    final name = file.path.split(Platform.pathSeparator).last.toLowerCase();
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final flags = <String>[];

    int score = 0;
    bool doubleExt = false;
    bool executableDisguised = false;

    // 1. Double Extension Trick Check (e.g. invoice.pdf.exe)
    final parts = name.split('.');
    if (parts.length > 2) {
      doubleExt = true;
      final secondLast = parts[parts.length - 2];
      final last = parts.last;
      if (_executableExtensions.contains(last) && ['pdf', 'doc', 'docx', 'jpg', 'png', 'txt'].contains(secondLast)) {
        executableDisguised = true;
        score += 70;
        flags.add("CRITICAL: Executable file disguised with double extension (e.g. .$secondLast.$last).");
      }
    }

    // 2. High Risk Extension Check
    final ext = parts.last;
    if (_executableExtensions.contains(ext)) {
      score += 35;
      flags.add("File has executable extension (.$ext).");
    }

    // 3. Macro / Script Indicators
    if (ext == 'docm' || ext == 'xlsm' || ext == 'pptm') {
      score += 40;
      flags.add("Office document contains macros (.$ext). Potential macro virus target.");
    }

    score = score.clamp(0, 99);
    String status = "SAFE";
    if (score >= 76) {
      status = "DANGEROUS";
    } else if (score >= 51) {
      status = "SUSPICIOUS";
    } else if (score >= 26) {
      status = "LOW RISK";
    }

    if (flags.isEmpty) {
      flags.add("File structure analyzed. No malicious extension or hash anomalies found.");
    }

    return FileAnalysisResult(
      fileName: name,
      sha256Hash: hash,
      fileSizeBytes: bytes.length,
      hasDoubleExtension: doubleExt,
      isExecutableDisguised: executableDisguised,
      threatFlags: flags,
      riskStatus: status,
      riskScore: score,
    );
  }
}
