import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final adminService = AdminService();

  bool isLoading = false;
  bool isServerOnline = false;
  bool isDnsProtectionEnabled = true;
  String serverStatusText = "DNS Server Protection Active";

  // Technitium Metrics
  int totalQueries = 0;
  int totalBlocked = 0;
  int totalAllowed = 0;
  double latencyMs = 0.0;
  String version = "15.5";
  String uptime = "N/A";

  // Real Data Lists
  List<dynamic> blockedDomains = [];
  List<dynamic> allowedDomains = [];
  List<dynamic> dnsLogs = [];

  // Domain Check Tool
  final checkDomainController = TextEditingController();
  Map<String, dynamic>? checkResult;
  bool isCheckingDomain = false;

  // Auto-Block Risk Score Threshold
  double autoBlockThreshold = 85.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllAdminData();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchDnsStatus(),
      _fetchBlockedDomains(),
      _fetchAllowedDomains(),
      _fetchDnsLogs(),
    ]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleDnsProtection(bool value) async {
    setState(() => isDnsProtectionEnabled = value);
    final res = await adminService.toggleDnsServer(value);
    await _fetchDnsStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? "DNS Protection ${value ? 'turned ON' : 'turned OFF'}."),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _fetchDnsStatus() async {
    final statusRes = await adminService.getDnsStatus();
    if (mounted) {
      if (statusRes["status"] == "success") {
        final data = statusRes["data"] ?? {};
        final rawStatus = data["status"] ?? "";
        setState(() {
          isDnsProtectionEnabled = data["enabled"] ?? (rawStatus != "OFF");
          isServerOnline = (rawStatus == "ONLINE" || rawStatus == "active");
          serverStatusText = !isDnsProtectionEnabled
              ? "DNS Protection OFF"
              : (isServerOnline ? "ONLINE" : "DNS Server Protection Active (Engine Offline)");
          totalQueries = data["total_queries"] ?? 0;
          totalBlocked = data["total_blocked"] ?? 0;
          totalAllowed = data["total_allowed"] ?? 0;
          latencyMs = (data["latency_ms"] as num?)?.toDouble() ?? 0.0;
          version = data["version"] ?? "15.5";
          uptime = data["uptime"] ?? "N/A";
        });
      } else {
        setState(() {
          isServerOnline = false;
          serverStatusText = !isDnsProtectionEnabled ? "DNS Protection OFF" : "DNS Protection Active";
        });
      }
    }
  }


  Future<void> _fetchBlockedDomains() async {
    final list = await adminService.getBlockedDomains();
    if (mounted) {
      setState(() => blockedDomains = list);
    }
  }

  Future<void> _fetchAllowedDomains() async {
    final list = await adminService.getAllowedDomains();
    if (mounted) {
      setState(() => allowedDomains = list);
    }
  }

  Future<void> _fetchDnsLogs() async {
    final logs = await adminService.getDnsLogs();
    if (mounted) {
      setState(() => dnsLogs = logs);
    }
  }

  Future<void> _handleBlockDomainDialog() async {
    final domainController = TextEditingController();
    final reasonController = TextEditingController(text: "Blocked by SecureBubble Admin");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Block Domain in Technitium DNS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: domainController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "e.g. phishing-fakebank.com",
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Block reason",
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B5CF6))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              final domain = domainController.text.trim();
              if (domain.isNotEmpty) {
                Navigator.pop(ctx);
                final res = await adminService.blockDomain(domain, reason: reasonController.text.trim());
                _loadAllAdminData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res["message"] ?? "Domain block command executed.")),
                  );
                }
              }
            },
            child: const Text("BLOCK DOMAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAllowDomainDialog() async {
    final domainController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Allow Domain in Technitium DNS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: domainController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "e.g. trusted-partner.com",
            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              final domain = domainController.text.trim();
              if (domain.isNotEmpty) {
                Navigator.pop(ctx);
                final res = await adminService.allowDomain(domain);
                _loadAllAdminData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res["message"] ?? "Domain allow command executed.")),
                  );
                }
              }
            },
            child: const Text("ALLOW DOMAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnblockDomain(String domain) async {
    final res = await adminService.unblockDomain(domain);
    _loadAllAdminData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Unblock command executed.")),
      );
    }
  }

  Future<void> _handleRemoveAllowedDomain(String domain) async {
    final res = await adminService.removeAllowedDomain(domain);
    _loadAllAdminData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Remove allowed domain executed.")),
      );
    }
  }

  Future<void> _runDomainCheck() async {
    final domain = checkDomainController.text.trim();
    if (domain.isEmpty) return;

    setState(() => isCheckingDomain = true);
    final res = await adminService.checkDomain(domain);
    if (mounted) {
      setState(() {
        checkResult = res;
        isCheckingDomain = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    checkDomainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZentraTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6), size: 22),
            SizedBox(width: 10),
            Text(
              "Technitium DNS Shield Admin",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _loadAllAdminData,
            tooltip: "Refresh Live DNS Data",
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              adminService.logout();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.speed_rounded, size: 20), text: "Status"),
            Tab(icon: Icon(Icons.list_alt_rounded, size: 20), text: "Rules"),
            Tab(icon: Icon(Icons.history_toggle_off_rounded, size: 20), text: "Logs"),
            Tab(icon: Icon(Icons.settings_suggest_rounded, size: 20), text: "Config"),
          ],
        ),
      ),
      body: ZentraTheme.buildAmbientBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStatusOverviewTab(),
                  _buildDomainRulesTab(),
                  _buildDnsLogsTab(),
                  _buildSettingsTab(),
                ],
              ),
      ),
    );
  }

  // TAB 1: DNS Protection Status & Server Health
  Widget _buildStatusOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Server Health Hero Card with Admin ON / OFF Switch
          ZentraTheme.buildGlassCard(
            borderColor: (isDnsProtectionEnabled && isServerOnline) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ((isDnsProtectionEnabled && isServerOnline) ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (isDnsProtectionEnabled && isServerOnline) ? Icons.dns_rounded : Icons.gpp_bad_rounded,
                    color: (isDnsProtectionEnabled && isServerOnline) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DNS Protection Status",
                        style: TextStyle(color: ZentraTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !isDnsProtectionEnabled
                            ? "🔴 DNS Protection OFF"
                            : (isServerOnline ? "🟢 ONLINE • Technitium v$version" : "⚠️ Protection Active (Engine Offline)"),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: !isDnsProtectionEnabled
                              ? Colors.redAccent
                              : (isServerOnline ? const Color(0xFF10B981) : Colors.orangeAccent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDnsProtectionEnabled
                            ? "Technitium Engine @ ${adminService.baseUrl} • Latency: ${latencyMs.toStringAsFixed(1)} ms"
                            : "DNS protection bypassed by Admin toggle",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDnsProtectionEnabled ? "SERVER ON" : "SERVER OFF",
                      style: TextStyle(
                        color: isDnsProtectionEnabled ? const Color(0xFF10B981) : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: isDnsProtectionEnabled,
                      activeColor: const Color(0xFF10B981),
                      inactiveThumbColor: Colors.redAccent,
                      onChanged: (val) => _toggleDnsProtection(val),
                    ),
                  ],
                ),
              ],
            ),
          ),


          const SizedBox(height: 18),

          // DNS Query Statistics Grid
          const Text("DNS Threat & Query Statistics", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildMetricCard("Total Queries", isServerOnline ? "$totalQueries" : "Data unavailable", const Color(0xFF38BDF8))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard("Blocked Queries", isServerOnline ? "$totalBlocked" : "Data unavailable", const Color(0xFFEF4444))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard("Allowed Queries", isServerOnline ? "$totalAllowed" : "Data unavailable", const Color(0xFF10B981))),
            ],
          ),

          const SizedBox(height: 24),

          // Live Domain Reputation Tester
          const Text("Live Domain Reputation Check", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ZentraTheme.buildGlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: checkDomainController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "Enter domain (e.g. test-domain.com)",
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                      onPressed: isCheckingDomain ? null : _runDomainCheck,
                      child: isCheckingDomain
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("CHECK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (checkResult != null) ...[
                  const Divider(color: Color(0xFF334155), height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Domain: ${checkResult!['domain']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (checkResult!['is_blocked'] == true ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          checkResult!['status'] ?? "UNKNOWN",
                          style: TextStyle(
                            color: checkResult!['is_blocked'] == true ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(checkResult!['message'] ?? "", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Domain Rules (Blocked & Allowed Lists)
  Widget _buildDomainRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Active Domain Rules", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text("BLOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _handleBlockDomainDialog,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text("ALLOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _handleAllowDomainDialog,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Blocked Domains Section
          const Text("Technitium Blocked Domains", style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (!isServerOnline)
            _buildUnavailableText("DNS Server Unavailable")
          else if (blockedDomains.isEmpty)
            _buildEmptyText("No active blocked domains in Technitium DNS.")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blockedDomains.length,
              itemBuilder: (ctx, idx) {
                final item = blockedDomains[idx];
                final dom = item is String ? item : (item["domain"] ?? item["name"] ?? "domain");
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        onPressed: () => _handleUnblockDomain(dom),
                        tooltip: "Unblock Domain",
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Allowed Domains Section
          const Text("Technitium Allowed Domains", style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (!isServerOnline)
            _buildUnavailableText("DNS Server Unavailable")
          else if (allowedDomains.isEmpty)
            _buildEmptyText("No active allowed domains in Technitium DNS.")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allowedDomains.length,
              itemBuilder: (ctx, idx) {
                final item = allowedDomains[idx];
                final dom = item is String ? item : (item["domain"] ?? item["name"] ?? "domain");
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF10B981), size: 20),
                        onPressed: () => _handleRemoveAllowedDomain(dom),
                        tooltip: "Remove from Allowlist",
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 3: Technitium DNS Query Activity Logs
  Widget _buildDnsLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DNS Activity & Query Logs", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF8B5CF6), size: 20),
                onPressed: _fetchDnsLogs,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!isServerOnline)
            _buildUnavailableText("DNS Server Unavailable")
          else if (dnsLogs.isEmpty)
            _buildEmptyText("Data unavailable or no recent DNS queries recorded.")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dnsLogs.length,
              itemBuilder: (ctx, idx) {
                final log = dnsLogs[idx];
                final isBlocked = log["blocked"] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBlocked ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                          color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log["domain"] ?? log["query"] ?? "N/A",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Client: ${log['clientIp'] ?? '127.0.0.1'} • Type: ${log['type'] ?? 'A'}",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isBlocked ? "BLOCKED" : "RESOLVED",
                        style: TextStyle(
                          color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 4: DNS Protection Settings
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DNS Security Settings", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // DNS Server Protection Switch Card
          ZentraTheme.buildGlassCard(
            borderColor: isDnsProtectionEnabled ? const Color(0xFF10B981) : Colors.redAccent,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Technitium DNS Server Protection",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDnsProtectionEnabled
                            ? "DNS protection is active and evaluating queries."
                            : "DNS protection is turned OFF. Queries will bypass local Technitium engine.",
                        style: TextStyle(color: ZentraTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDnsProtectionEnabled ? "SERVER ON" : "SERVER OFF",
                      style: TextStyle(
                        color: isDnsProtectionEnabled ? const Color(0xFF10B981) : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: isDnsProtectionEnabled,
                      activeColor: const Color(0xFF10B981),
                      inactiveThumbColor: Colors.redAccent,
                      onChanged: (val) => _toggleDnsProtection(val),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ZentraTheme.buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Technitium Auto-Block Threshold",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Threats scoring at or above this threshold will be automatically pushed to Technitium DNS blocklist.",
                  style: TextStyle(color: ZentraTheme.textSecondary, fontSize: 12),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Risk Score Threshold:", style: TextStyle(color: Colors.white, fontSize: 13.5)),
                    Text("${autoBlockThreshold.round()} / 100", style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Slider(
                  value: autoBlockThreshold,
                  min: 50.0,
                  max: 95.0,
                  divisions: 9,
                  activeColor: const Color(0xFF8B5CF6),
                  inactiveColor: const Color(0xFF334155),
                  onChanged: (val) => setState(() => autoBlockThreshold = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return ZentraTheme.buildGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildUnavailableText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
      ),
    );
  }
}
