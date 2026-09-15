import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class FirewallScreen extends StatefulWidget {
  const FirewallScreen({Key? key}) : super(key: key);

  @override
  State<FirewallScreen> createState() => _FirewallScreenState();
}

class _FirewallScreenState extends State<FirewallScreen> {
  bool _isVpnRunning = false;
  List<VpnBlockedDomain> _blockedDomains = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    final running = await VpnServiceBridge.isVpnRunning();
    final list = await VpnServiceBridge.getBlockedDomains();
    setState(() {
      _isVpnRunning = running;
      _blockedDomains = list;
      _isLoading = false;
    });
  }

  Future<void> _toggleVpn(bool enable) async {
    if (enable) {
      final success = await VpnServiceBridge.startVpn();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🟢 SecureBubble Firewall Protected")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ VPN Permission required")),
        );
      }
    } else {
      await VpnServiceBridge.stopVpn();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("VPN Protection Stopped")),
      );
    }
    _refreshStatus();
  }

  Future<void> _unblockDomain(String domain) async {
    await VpnServiceBridge.removeBlockedDomain(domain);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unblocked $domain")),
    );
    _refreshStatus();
  }

  Future<void> _clearAll() async {
    await VpnServiceBridge.clearBlockedDomains();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cleared all blocked domains")),
    );
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final userBlockedCount = _blockedDomains.where((d) => d.source == "USER_BLOCKED").length;
    final aiBlockedCount = _blockedDomains.length - userBlockedCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C24),
        title: const Text(
          "SECUREBUBBLE FIREWALL",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStatus,
          ),
          if (_blockedDomains.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444)),
              onPressed: _clearAll,
              tooltip: "Clear Blocklist",
            ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VPN Status Control Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF140C24),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isVpnRunning ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isVpnRunning ? const Color(0xFF4ADE80) : const Color(0xFFEF4444)).withOpacity(0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "VPN Protection",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  _isVpnRunning ? "🟢 Protected" : "⚪ Stopped",
                                  style: TextStyle(
                                    color: _isVpnRunning ? const Color(0xFF4ADE80) : const Color(0xFF9CA3AF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _isVpnRunning,
                          activeColor: const Color(0xFF4ADE80),
                          inactiveTrackColor: const Color(0xFF1F1535),
                          onChanged: _toggleVpn,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard("Total Blocked", "${_blockedDomains.length}", const Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard("User Blocked", "$userBlockedCount", const Color(0xFFF97316)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard("AI Blocked", "$aiBlockedCount", const Color(0xFFA78BFA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Blocked Domains List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Blocked Domains",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_blockedDomains.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140C24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          "No domains blocked. Blocked suspicious sites will appear here.",
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    ..._blockedDomains.map((item) => Card(
                          color: const Color(0xFF140C24),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFF2E1E4E)),
                          ),
                          child: ListTile(
                            leading: const Text("🚫", style: TextStyle(fontSize: 20)),
                            title: Text(
                              item.domain,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              "Source: ${item.source} • Risk: ${item.riskScore}/100\n${item.reason}",
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.lock_open, color: Color(0xFF60A5FA)),
                              onPressed: () => _unblockDomain(item.domain),
                              tooltip: "Unblock Domain",
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String count, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF140C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
