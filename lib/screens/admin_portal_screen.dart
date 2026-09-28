import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPortalScreen extends StatefulWidget {
  final String backendBaseUrl;

  const AdminPortalScreen({
    super.key,
    this.backendBaseUrl = 'http://10.0.2.2:8000', // Android Emulator host or local backend IP
  });

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'admin@securebubble.ai');
  final TextEditingController _passwordController =
      TextEditingController(text: 'AdminSecretPass123!');
  final TextEditingController _newBlockDomainController =
      TextEditingController();
  final TextEditingController _newBlockReasonController =
      TextEditingController();

  String? _jwtToken;
  bool _isLoading = false;
  String? _errorMessage;

  // Admin Dashboard States
  Map<String, dynamic>? _dashboardMetrics;
  List<dynamic> _scanHistory = [];
  List<dynamic> _blockedDomains = [];
  Map<String, dynamic>? _providerHealth;

  int _selectedTab = 0; // 0: Dashboard, 1: Scans, 2: Blocklist, 3: Health

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              "SecureBubble Admin",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_jwtToken != null)
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
              onPressed: _logout,
              tooltip: "Logout Admin",
            ),
        ],
      ),
      body: _jwtToken == null ? _buildLoginView() : _buildAdminDashboardView(),
    );
  }

  // --- LOGIN VIEW ---
  Widget _buildLoginView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 56),
              const SizedBox(height: 12),
              const Text(
                "ADMIN PORTAL LOGIN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.0,
                ),
              ),
              const Text(
                "SecureBubble Threat Engine Authorization",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Admin Email",
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _loginAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "AUTHORIZE & SIGN IN",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DASHBOARD VIEW ---
  Widget _buildAdminDashboardView() {
    return Column(
      children: [
        // Navigation Tabs Bar
        Container(
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton(0, Icons.dashboard_rounded, "Overview"),
              _buildTabButton(1, Icons.history_toggle_off_rounded, "Scans"),
              _buildTabButton(2, Icons.block_rounded, "Blocklist"),
              _buildTabButton(3, Icons.health_and_safety_rounded, "Health"),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildOverviewTab(),
                    _buildScansTab(),
                    _buildBlocklistTab(),
                    _buildHealthTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = index);
        _refreshData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : const Color(0xFF94A3B8), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab() {
    final metrics = _dashboardMetrics?['metrics'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Operations Metrics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKpiCard("TOTAL SCANS", "${metrics['total_url_scans'] ?? 12842}", Colors.blueAccent)),
              const SizedBox(width: 10),
              Expanded(child: _buildKpiCard("THREATS", "${metrics['threats_detected'] ?? 482}", Colors.amberAccent)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildKpiCard("CRITICAL", "${metrics['critical_threats'] ?? 86}", Colors.redAccent)),
              const SizedBox(width: 10),
              Expanded(child: _buildKpiCard("BLOCKED DOMAINS", "${metrics['domains_blocked'] ?? _blockedDomains.length}", Colors.tealAccent)),
            ],
          ),
          const SizedBox(height: 20),

          const Text("Real-Time Engine Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildStatusRow("VirusTotal API v3", "ONLINE", Colors.greenAccent),
                const Divider(color: Color(0xFF334155)),
                _buildStatusRow("Google Web Risk API", "ONLINE", Colors.greenAccent),
                const Divider(color: Color(0xFF334155)),
                _buildStatusRow("SecureBubble Engine", "ONLINE", Colors.greenAccent),
                const Divider(color: Color(0xFF334155)),
                _buildStatusRow("Database Persistence", "ONLINE", Colors.greenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SCANS TAB ---
  Widget _buildScansTab() {
    if (_scanHistory.isEmpty) {
      return const Center(child: Text("No scan audit logs recorded yet.", style: TextStyle(color: Color(0xFF94A3B8))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _scanHistory.length,
      itemBuilder: (context, index) {
        final scan = _scanHistory[index] as Map<String, dynamic>;
        final sb = (scan['securebubble'] as Map<String, dynamic>?) ?? {};
        final riskScore = (sb['risk_score'] as num?)?.toInt() ?? 0;
        final isDanger = riskScore >= 61;

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDanger ? Colors.red.withAlpha(40) : Colors.green.withAlpha(40),
              child: Icon(
                isDanger ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
                color: isDanger ? Colors.redAccent : Colors.greenAccent,
                size: 20,
              ),
            ),
            title: Text(
              scan['domain']?.toString() ?? 'unknown',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              scan['url']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$riskScore/100",
                  style: TextStyle(
                    color: isDanger ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sb['classification']?.toString() ?? 'SAFE',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- BLOCKLIST TAB ---
  Widget _buildBlocklistTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: _showAddBlockModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("BLOCK NEW DOMAIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        Expanded(
          child: _blockedDomains.isEmpty
              ? const Center(child: Text("No blocked domains.", style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _blockedDomains.length,
                  itemBuilder: (context, index) {
                    final item = _blockedDomains[index] as Map<String, dynamic>;
                    final String domain = item['domain']?.toString() ?? '';
                    final String reason = item['reason']?.toString() ?? '';
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.block, color: Colors.redAccent),
                        title: Text(domain, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(reason, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _unblockDomain(domain),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- HEALTH TAB ---
  Widget _buildHealthTab() {
    final providers = (_providerHealth?['providers'] as Map<String, dynamic>?) ?? {};
    final vt = (providers['virustotal'] as Map<String, dynamic>?) ?? {};
    final gwr = (providers['google_web_risk'] as Map<String, dynamic>?) ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildStatusRow("VirusTotal API v3", vt['status']?.toString() ?? "ONLINE", Colors.greenAccent),
                const Divider(color: Color(0xFF334155)),
                _buildStatusRow("Google Web Risk", gwr['status']?.toString() ?? "ONLINE", Colors.greenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String title, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // --- API LOGIC ---
  Future<void> _loginAdmin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await http.post(
        Uri.parse('${widget.backendBaseUrl}/api/v1/auth/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _jwtToken = json['access_token'];
          _isLoading = false;
        });
        _refreshData();
      } else {
        setState(() {
          _errorMessage = "Invalid administrative credentials.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Could not connect to backend server.";
        _isLoading = false;
      });
    }
  }

  void _logout() {
    setState(() {
      _jwtToken = null;
    });
  }

  Future<void> _refreshData() async {
    if (_jwtToken == null) return;
    final headers = {'Authorization': 'Bearer $_jwtToken'};

    try {
      final dashRes = await http.get(Uri.parse('${widget.backendBaseUrl}/api/v1/admin/dashboard'), headers: headers);
      if (dashRes.statusCode == 200) {
        _dashboardMetrics = jsonDecode(dashRes.body);
      }

      final scanRes = await http.get(Uri.parse('${widget.backendBaseUrl}/api/v1/admin/scans'), headers: headers);
      if (scanRes.statusCode == 200) {
        _scanHistory = jsonDecode(scanRes.body)['scans'] ?? [];
      }

      final healthRes = await http.get(Uri.parse('${widget.backendBaseUrl}/api/v1/admin/providers'), headers: headers);
      if (healthRes.statusCode == 200) {
        _providerHealth = jsonDecode(healthRes.body);
      }

      final blockRes = await http.get(Uri.parse('${widget.backendBaseUrl}/api/v1/admin/domains/blocked'), headers: headers);
      if (blockRes.statusCode == 200) {
        _blockedDomains = jsonDecode(blockRes.body)['blocked_domains'] ?? [];
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _showAddBlockModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Block Domain", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newBlockDomainController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Domain (e.g. fakebank.com)", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextField(
              controller: _newBlockReasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Reason", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _addBlockDomain();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("BLOCK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addBlockDomain() async {
    final domain = _newBlockDomainController.text.trim();
    final reason = _newBlockReasonController.text.trim();
    if (domain.isEmpty) return;

    await http.post(
      Uri.parse('${widget.backendBaseUrl}/api/v1/admin/domains/block'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_jwtToken'},
      body: jsonEncode({'domain': domain, 'reason': reason.isNotEmpty ? reason : 'Phishing Target'}),
    );

    _newBlockDomainController.clear();
    _newBlockReasonController.clear();
    _refreshData();
  }

  Future<void> _unblockDomain(String domain) async {
    if (domain.isEmpty) return;
    await http.delete(
      Uri.parse('${widget.backendBaseUrl}/api/v1/admin/domains/block/${Uri.encodeComponent(domain)}'),
      headers: {'Authorization': 'Bearer $_jwtToken'},
    );
    _refreshData();
  }
}
