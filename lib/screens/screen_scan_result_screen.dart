import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/detected_link_item.dart';
import '../services/blocklist_service.dart';
import '../widgets/warning_dialog.dart';

class ScreenScanResultScreen extends StatefulWidget {
  final List<DetectedLinkItem> detectedLinks;

  const ScreenScanResultScreen({Key? key, required this.detectedLinks}) : super(key: key);

  @override
  State<ScreenScanResultScreen> createState() => _ScreenScanResultScreenState();
}

class _ScreenScanResultScreenState extends State<ScreenScanResultScreen> {
  final Set<String> _blockedDomains = {};

  @override
  void initState() {
    super.initState();
    _checkBlocklist();
  }

  Future<void> _checkBlocklist() async {
    for (final item in widget.detectedLinks) {
      final blocked = await BlocklistService.isBlocked(item.url);
      if (blocked) {
        final domain = BlocklistService.extractDomain(item.url);
        setState(() {
          _blockedDomains.add(domain.toLowerCase());
        });
      }
    }

    // Auto-prompt High Risk Dialog for score >= 90 if not already blocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptHighRiskDialogs();
    });
  }

  void _promptHighRiskDialogs() {
    final critical = widget.detectedLinks.where((item) => item.riskScore >= 80).toList();
    if (critical.isNotEmpty) {
      final target = critical.first;
      final domain = BlocklistService.extractDomain(target.url);
      if (!_blockedDomains.contains(domain.toLowerCase())) {
        showDialog(
          context: context,
          builder: (context) => HighRiskWarningDialog(
            url: target.url,
            riskScore: target.riskScore,
            threatCategory: target.detectionType,
            onBlock: () => _blockItem(target.url, target.riskScore, target.detectionType),
            onAllow: () {},
          ),
        );
      }
    }
  }

  Future<void> _blockItem(String url, int score, String reason) async {
    await BlocklistService.blockUrl(url, score, reason);
    final domain = BlocklistService.extractDomain(url);
    setState(() {
      _blockedDomains.add(domain.toLowerCase());
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚫 $domain added to SecureBubble Blocklist")),
      );
    }
  }

  Future<void> _unblockItem(String url) async {
    await BlocklistService.unblockUrl(url);
    final domain = BlocklistService.extractDomain(url);
    setState(() {
      _blockedDomains.remove(domain.toLowerCase());
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unblocked $domain")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final critical = widget.detectedLinks.where((item) => item.riskScore >= 80 || item.riskLevel == 'CRITICAL' || item.riskLevel == 'HIGH').toList();
    final highRisk = widget.detectedLinks.where((item) => (item.riskScore >= 60 && item.riskScore < 80) || !item.domainMatch).toList();
    final suspicious = widget.detectedLinks.where((item) => item.riskScore >= 35 && item.riskScore < 60).toList();
    final safe = widget.detectedLinks.where((item) => item.riskScore < 35 && item.domainMatch).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C24),
        title: const Text(
          "🛡️ SecureBubble Active Threat Prevention",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined Security Report Header (Section 6)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "🛡️ SECUREBUBBLE SECURITY REPORT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                        ),
                        child: Text(
                          "${widget.detectedLinks.length} Items",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildReportBadge("🟢 Safe", "${safe.length}", const Color(0xFF4ADE80)),
                      const SizedBox(width: 8),
                      _buildReportBadge("🟠 Suspicious", "${suspicious.length + highRisk.length}", const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildReportBadge("🔴 Dangerous", "${critical.length}", const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "All visible screen content analyzed before opening links.",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔴 CRITICAL Section (Score >= 90)
            if (critical.isNotEmpty) ...[
              _buildSectionTitle("🔴 CRITICAL THREATS (Score >= 90)", const Color(0xFFEF4444)),
              const SizedBox(height: 8),
              ...critical.map((item) => _buildLinkCard(context, item, const Color(0xFFEF4444))),
              const SizedBox(height: 16),
            ],

            // 🟠 HIGH RISK Section (70 - 89)
            if (highRisk.isNotEmpty) ...[
              _buildSectionTitle("🟠 HIGH RISK LINKS (Score 70–89)", const Color(0xFFF97316)),
              const SizedBox(height: 8),
              ...highRisk.map((item) => _buildLinkCard(context, item, const Color(0xFFF97316))),
              const SizedBox(height: 16),
            ],

            // 🟡 SUSPICIOUS Section (40 - 69)
            if (suspicious.isNotEmpty) ...[
              _buildSectionTitle("🟡 SUSPICIOUS LINKS (Score 40–69)", const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              ...suspicious.map((item) => _buildLinkCard(context, item, const Color(0xFFF59E0B))),
              const SizedBox(height: 16),
            ],

            // 🟢 SAFE Section (< 40)
            if (safe.isNotEmpty) ...[
              _buildSectionTitle("🟢 VERIFIED SAFE LINKS (Score < 40)", const Color(0xFF4ADE80)),
              const SizedBox(height: 8),
              ...safe.map((item) => _buildLinkCard(context, item, const Color(0xFF4ADE80))),
              const SizedBox(height: 16),
            ],

            if (widget.detectedLinks.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF140C24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    "No suspicious links or QR payloads detected on screen.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportBadge(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLinkCard(BuildContext context, DetectedLinkItem item, Color accentColor) {
    final domain = BlocklistService.extractDomain(item.url);
    final isBlocked = _blockedDomains.contains(domain.toLowerCase());

    return Card(
      color: const Color(0xFF140C24),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isBlocked ? const Color(0xFFEF4444) : accentColor.withOpacity(0.5), width: isBlocked ? 1.5 : 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.url,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
            if (isBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "BLOCKED",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Visible: ${item.text}",
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.warning.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.warning,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${item.riskScore}/100",
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        onTap: () {
          _showLinkDetailsModal(context, item, accentColor, isBlocked);
        },
      ),
    );
  }

  void _showLinkDetailsModal(BuildContext context, DetectedLinkItem item, Color accentColor, bool isBlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF140C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "🛡️ Active Threat Details",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2E1E4E)),
              const SizedBox(height: 8),
              Text("Target URL: ${item.url}", style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 13.5)),
              const SizedBox(height: 6),
              Text("Risk Score: ${item.riskScore}/100", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              Text("Detection: ${item.detectionType}", style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12.5)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("URL copied to clipboard")),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: Colors.lightBlueAccent),
                    label: const Text("Copy URL", style: TextStyle(color: Colors.lightBlueAccent)),
                  ),
                  if (isBlocked)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _unblockItem(item.url);
                      },
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text("UNBLOCK"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _blockItem(item.url, item.riskScore, item.detectionType);
                      },
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text("BLOCK"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
