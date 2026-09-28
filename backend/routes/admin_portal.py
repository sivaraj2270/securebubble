import logging
from fastapi import APIRouter
from fastapi.responses import HTMLResponse

logger = logging.getLogger("securebubble.routes.admin_portal")

router = APIRouter(prefix="/admin", tags=["Web Admin Portal UI"])

ADMIN_HTML_CONTENT = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SecureBubble AI — Admin Operations & Technitium DNS Shield</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        :root {
            --bg-dark: #0f172a;
            --card-dark: #1e293b;
            --accent-blue: #3b82f6;
            --accent-purple: #8b5cf6;
            --accent-green: #10b981;
            --accent-red: #ef4444;
            --accent-amber: #f59e0b;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
        }

        body {
            background-color: var(--bg-dark);
            color: var(--text-main);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        .login-card {
            background: var(--card-dark);
            border: 1px solid #334155;
            border-radius: 16px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.5);
        }

        .navbar-custom {
            background-color: var(--card-dark);
            border-bottom: 1px solid #334155;
        }

        .sidebar {
            background-color: var(--card-dark);
            min-height: calc(100vh - 65px);
            border-right: 1px solid #334155;
        }

        .nav-link-custom {
            color: var(--text-muted);
            border-radius: 8px;
            padding: 10px 16px;
            margin-bottom: 6px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .nav-link-custom:hover, .nav-link-custom.active {
            color: var(--text-main);
            background-color: rgba(139, 92, 246, 0.15);
            border-left: 4px solid var(--accent-purple);
        }

        .dashboard-card {
            background: var(--card-dark);
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 20px;
        }

        .badge-status {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
        }

        .badge-online { background-color: rgba(16, 185, 129, 0.2); color: #34d399; }
        .badge-danger { background-color: rgba(239, 68, 68, 0.2); color: #f87171; }
        .badge-warning { background-color: rgba(245, 158, 11, 0.2); color: #fbbf24; }

        .table-custom {
            color: var(--text-main);
        }

        .table-custom th {
            background-color: #0f172a;
            color: var(--text-muted);
            border-bottom: 2px solid #334155;
        }

        .table-custom td {
            border-bottom: 1px solid #334155;
        }
    </style>
</head>
<body>

    <!-- LOGIN SCREEN -->
    <div id="loginScreen" class="container d-flex align-items-center justify-content-center min-vh-100">
        <div class="col-md-5">
            <div class="login-card p-4">
                <div class="text-center mb-4">
                    <i class="fa-solid fa-shield-halved text-primary display-4 mb-2"></i>
                    <h3 class="fw-bold">SecureBubble AI</h3>
                    <p class="text-secondary small">Admin Portal & Technitium DNS Shield</p>
                </div>

                <div id="loginAlert" class="alert alert-danger d-none" role="alert"></div>

                <form id="loginForm">
                    <div class="mb-3">
                        <label class="form-label text-secondary small fw-bold">ADMIN EMAIL</label>
                        <input type="email" id="loginEmail" class="form-control bg-dark text-light border-secondary" value="admin@gmail.com" required>
                    </div>
                    <div class="mb-4">
                        <label class="form-label text-secondary small fw-bold">PASSWORD</label>
                        <input type="password" id="loginPassword" class="form-control bg-dark text-light border-secondary" value="tree1010234" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 py-2 fw-bold"><i class="fa-solid fa-lock me-2"></i>SIGN IN TO PORTAL</button>
                </form>
            </div>
        </div>
    </div>

    <!-- MAIN DASHBOARD -->
    <div id="mainDashboard" class="d-none">
        <nav class="navbar navbar-expand-lg navbar-custom px-4">
            <div class="container-fluid">
                <a class="navbar-brand text-light fw-bold" href="#">
                    <i class="fa-solid fa-shield-halved text-primary me-2"></i>SecureBubble AI Operations
                </a>
                <div class="d-flex align-items-center">
                    <div class="form-check form-switch me-4 text-light d-flex align-items-center mb-0">
                        <input class="form-check-input me-2" type="checkbox" role="switch" id="dnsToggleSwitch" checked onchange="toggleWebDnsProtection(this.checked)">
                        <label class="form-check-label small fw-bold text-success" for="dnsToggleSwitch" id="dnsToggleLabel">DNS SERVER ON</label>
                    </div>
                    <span id="adminUserDisplay" class="text-secondary me-3 small"><i class="fa-solid fa-circle-user me-1 text-primary"></i>admin@gmail.com</span>
                    <button id="logoutBtn" class="btn btn-outline-danger btn-sm"><i class="fa-solid fa-power-off me-1"></i>Logout</button>
                </div>

            </div>
        </nav>

        <div class="container-fluid">
            <div class="row">
                <!-- Sidebar -->
                <div class="col-md-2 sidebar p-3">
                    <div class="nav flex-column">
                        <div class="nav-link-custom active" data-pane="paneOverview"><i class="fa-solid fa-chart-line me-2"></i>Dashboard Overview</div>
                        <div class="nav-link-custom" data-pane="paneTechnitium"><i class="fa-solid fa-network-wired me-2"></i>Technitium DNS Shield</div>
                        <div class="nav-link-custom" data-pane="paneConfig"><i class="fa-solid fa-sliders me-2"></i>App & DNS Config</div>
                        <div class="nav-link-custom" data-pane="paneScans"><i class="fa-solid fa-list-check me-2"></i>Scan History Audit</div>
                        <div class="nav-link-custom" data-pane="paneAnalytics"><i class="fa-solid fa-chart-pie me-2"></i>Threat Analytics</div>
                        <div class="nav-link-custom" data-pane="paneProviders"><i class="fa-solid fa-server me-2"></i>Provider Health</div>
                        <div class="nav-link-custom" data-pane="paneBlocklist"><i class="fa-solid fa-ban me-2"></i>Domain Blocklist</div>
                    </div>
                </div>

                <!-- Main Content Panes -->
                <div class="col-md-10 p-4">

                    <!-- PANE 1: OVERVIEW -->
                    <div id="paneOverview" class="pane-content">
                        <h4 class="fw-bold mb-4">Dashboard Overview</h4>
                        <div class="row g-3 mb-4">
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">TOTAL URL SCANS</div>
                                    <div id="statTotalScans" class="display-6 fw-bold text-primary my-2">12,842</div>
                                    <div class="small text-muted"><i class="fa-solid fa-arrow-up text-success me-1"></i>Live verified</div>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">THREATS DETECTED</div>
                                    <div id="statThreatsDetected" class="display-6 fw-bold text-warning my-2">482</div>
                                    <div class="small text-muted">Phishing & Malware</div>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">TECHNITIUM BLOCKED</div>
                                    <div id="statDnsBlocked" class="display-6 fw-bold text-danger my-2">0</div>
                                    <div class="small text-muted">DNS Firewall Rules</div>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">DOMAINS BLOCKED</div>
                                    <div id="statBlockedDomains" class="display-6 fw-bold text-info my-2">1</div>
                                    <div class="small text-muted">Persistent Blocklist</div>
                                </div>
                            </div>
                        </div>

                        <!-- System Status -->
                        <div class="dashboard-card mb-4">
                            <h5 class="fw-bold mb-3"><i class="fa-solid fa-heart-pulse text-danger me-2"></i>Real-time Security Engines Status</h5>
                            <div class="row text-center g-3">
                                <div class="col-md-3">
                                    <div class="p-3 bg-dark rounded border border-secondary">
                                        <div class="small text-muted">Technitium DNS 15.5</div>
                                        <div id="statusTechnitium" class="badge-status badge-online mt-2">🟢 ONLINE</div>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="p-3 bg-dark rounded border border-secondary">
                                        <div class="small text-muted">VirusTotal API v3</div>
                                        <div id="statusVT" class="badge-status badge-online mt-2">🟢 ONLINE</div>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="p-3 bg-dark rounded border border-secondary">
                                        <div class="small text-muted">Google Web Risk</div>
                                        <div id="statusGWR" class="badge-status badge-online mt-2">🟢 ONLINE</div>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="p-3 bg-dark rounded border border-secondary">
                                        <div class="small text-muted">SecureBubble Engine</div>
                                        <div class="badge-status badge-online mt-2">🟢 ONLINE</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- PANE: TECHNITIUM DNS SHIELD -->
                    <div id="paneTechnitium" class="pane-content d-none">
                        <div class="d-flex justify-content-between align-items-center mb-4">
                            <h4 class="fw-bold m-0"><i class="fa-solid fa-network-wired text-primary me-2"></i>Technitium DNS Server 15.5 Shield</h4>
                            <div>
                                <button class="btn btn-outline-info btn-sm me-2 fw-bold" onclick="refreshTechnitiumData()"><i class="fa-solid fa-rotate me-1"></i>REFRESH</button>
                                <button class="btn btn-danger btn-sm fw-bold" data-bs-toggle="modal" data-bs-target="#blockTechnitiumModal"><i class="fa-solid fa-ban me-1"></i>BLOCK DOMAIN</button>
                            </div>
                        </div>

                        <!-- Technitium Cards -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">TECHNITIUM STATUS</div>
                                    <div id="techServerStatus" class="fs-4 fw-bold text-success my-2">ONLINE</div>
                                    <div id="techServerUrl" class="small text-muted">http://127.0.0.1:5380</div>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">TOTAL DNS QUERIES</div>
                                    <div id="techTotalQueries" class="fs-4 fw-bold text-primary my-2">0</div>
                                    <div class="small text-muted">Resolved locally</div>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">TOTAL BLOCKED QUERIES</div>
                                    <div id="techTotalBlocked" class="fs-4 fw-bold text-danger my-2">0</div>
                                    <div class="small text-muted">Intercepted by Blocklist</div>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="dashboard-card">
                                    <div class="text-secondary small fw-bold">LATENCY / RESPONSE</div>
                                    <div id="techLatency" class="fs-4 fw-bold text-warning my-2">2.4 ms</div>
                                    <div class="small text-muted">Local loopback</div>
                                </div>
                            </div>
                        </div>

                        <!-- Domain Check Tool Card -->
                        <div class="dashboard-card mb-4">
                            <h5 class="fw-bold mb-3"><i class="fa-solid fa-magnifying-glass text-primary me-2"></i>Instant Domain Reputation & DNS Check</h5>
                            <div class="row g-2 align-items-center">
                                <div class="col-md-9">
                                    <input type="text" id="webCheckDomainInput" class="form-control bg-dark text-light border-secondary" placeholder="e.g. example.com or fake-bank.com">
                                </div>
                                <div class="col-md-3">
                                    <button class="btn btn-primary w-100 fw-bold" onclick="runWebDomainCheck()"><i class="fa-solid fa-shield-halved me-1"></i>CHECK DOMAIN</button>
                                </div>
                            </div>
                            <div id="webCheckResultBox" class="mt-3 d-none">
                                <div class="p-3 bg-dark rounded border border-secondary d-flex align-items-center justify-content-between">
                                    <div>
                                        <span id="webCheckDomainName" class="fw-bold fs-6 me-2">example.com</span>
                                        <span id="webCheckBadge" class="badge bg-success">SAFE</span>
                                    </div>
                                    <div id="webCheckMsg" class="small text-muted">Domain is clean in Technitium DNS.</div>
                                </div>
                            </div>
                        </div>

                        <!-- Technitium Blocked Domains Table -->
                        <div class="dashboard-card mb-4">
                            <h5 class="fw-bold mb-3"><i class="fa-solid fa-shield-cat text-danger me-2"></i>Technitium Active Blocklist Rules</h5>
                            <div class="table-responsive">
                                <table class="table table-custom align-middle">
                                    <thead>
                                        <tr>
                                            <th>BLOCKED DOMAIN</th>
                                            <th>ACTION</th>
                                        </tr>
                                    </thead>
                                    <tbody id="techBlockedTableBody">
                                        <tr><td colspan="2" class="text-muted small">Loading Technitium blocklist...</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Technitium DNS Query Logs -->
                        <div class="dashboard-card">
                            <h5 class="fw-bold mb-3"><i class="fa-solid fa-list text-info me-2"></i>Recent Technitium DNS Query Logs</h5>
                            <div class="table-responsive">
                                <table class="table table-custom align-middle">
                                    <thead>
                                        <tr>
                                            <th>TIMESTAMP</th>
                                            <th>CLIENT IP</th>
                                            <th>QUERY DOMAIN</th>
                                            <th>TYPE</th>
                                            <th>RESULT</th>
                                        </tr>
                                    </thead>
                                    <tbody id="dnsLogsTableBody">
                                        <tr><td colspan="5" class="text-muted small">Loading recent query logs...</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- PANE: APP & DNS CONFIG -->
                    <div id="paneConfig" class="pane-content d-none">
                        <div class="d-flex justify-content-between align-items-center mb-4">
                            <h4 class="fw-bold m-0"><i class="fa-solid fa-sliders text-primary me-2"></i>SecureBubble AI & Technitium DNS Settings</h4>
                            <button class="btn btn-success fw-bold px-4" onclick="saveSystemConfig()"><i class="fa-solid fa-floppy-disk me-2"></i>SAVE CONFIGURATION</button>
                        </div>

                        <div id="configSuccessAlert" class="alert alert-success d-none mb-3" role="alert"></div>
                        <div id="configErrorAlert" class="alert alert-danger d-none mb-3" role="alert"></div>

                        <div class="row g-4">
                            <!-- Technitium DNS Settings -->
                            <div class="col-md-6">
                                <div class="dashboard-card h-100">
                                    <h5 class="fw-bold mb-3 text-info"><i class="fa-solid fa-network-wired me-2"></i>Technitium DNS Server 15.5 Integration</h5>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">TECHNITIUM SERVER URL</label>
                                        <input type="text" id="cfgTechUrl" class="form-control bg-dark text-light border-secondary" placeholder="http://127.0.0.1:5380">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">ADMIN USERNAME</label>
                                        <input type="text" id="cfgTechUser" class="form-control bg-dark text-light border-secondary" placeholder="admin">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">ADMIN PASSWORD / SESSION TOKEN</label>
                                        <input type="password" id="cfgTechPass" class="form-control bg-dark text-light border-secondary" placeholder="••••••••">
                                        <div class="form-text text-muted small">Server-side credentials used to authenticate with Technitium HTTP REST API</div>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">AUTO-BLOCK THREAT THRESHOLD (0 - 100)</label>
                                        <input type="number" id="cfgAutoBlockThreshold" class="form-control bg-dark text-light border-secondary" min="0" max="100" placeholder="85">
                                        <div class="form-text text-muted small">Dual scanner threat risk scores exceeding this threshold automatically trigger Technitium domain auto-block</div>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">TECHNITIUM API TIMEOUT (SECONDS)</label>
                                        <input type="number" step="0.5" id="cfgTechTimeout" class="form-control bg-dark text-light border-secondary" placeholder="5.0">
                                    </div>
                                </div>
                            </div>

                            <!-- Threat API Keys & Operational Rules -->
                            <div class="col-md-6">
                                <div class="dashboard-card mb-4">
                                    <h5 class="fw-bold mb-3 text-warning"><i class="fa-solid fa-key me-2"></i>Security Provider API Credentials</h5>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">VIRUSTOTAL API KEY (v3)</label>
                                        <input type="password" id="cfgVtKey" class="form-control bg-dark text-light border-secondary" placeholder="••••••••">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">GOOGLE WEB RISK API KEY</label>
                                        <input type="password" id="cfgGoogleKey" class="form-control bg-dark text-light border-secondary" placeholder="••••••••">
                                    </div>
                                </div>

                                <div class="dashboard-card">
                                    <h5 class="fw-bold mb-3 text-success"><i class="fa-solid fa-gear me-2"></i>Engine Operational & Cache Rules</h5>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">SCAN CACHE TTL (SECONDS)</label>
                                        <input type="number" id="cfgCacheTtl" class="form-control bg-dark text-light border-secondary" placeholder="300">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">PROVIDER RESPONSE TIMEOUT (SECONDS)</label>
                                        <input type="number" step="0.5" id="cfgProviderTimeout" class="form-control bg-dark text-light border-secondary" placeholder="4.0">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label small fw-bold text-secondary">ENVIRONMENT MODE</label>
                                        <select id="cfgEnvironment" class="form-select bg-dark text-light border-secondary">
                                            <option value="development">Development</option>
                                            <option value="production">Production</option>
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- PANE 2: SCAN HISTORY -->
                    <div id="paneScans" class="pane-content d-none">
                        <h4 class="fw-bold mb-4">Scan History Audit Trail</h4>
                        <div class="dashboard-card">
                            <div class="table-responsive">
                                <table class="table table-custom align-middle">
                                    <thead>
                                        <tr>
                                            <th>TIMESTAMP</th>
                                            <th>DOMAIN</th>
                                            <th>TARGET URL</th>
                                            <th>VIRUSTOTAL</th>
                                            <th>GOOGLE WEB RISK</th>
                                            <th>AGREEMENT</th>
                                            <th>RISK SCORE</th>
                                            <th>FINAL VERDICT</th>
                                        </tr>
                                    </thead>
                                    <tbody id="scanHistoryTableBody">
                                        <!-- Dynamic entries -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- PANE 3: ANALYTICS -->
                    <div id="paneAnalytics" class="pane-content d-none">
                        <h4 class="fw-bold mb-4">Threat Intelligence & Disagreement Analytics</h4>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <div class="dashboard-card">
                                    <h5 class="fw-bold mb-3">Threat Category Breakdown</h5>
                                    <ul class="list-group list-group-flush bg-transparent">
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Phishing Targets <span class="badge bg-danger">210</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Social Engineering <span class="badge bg-warning text-dark">114</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Malware Distribution <span class="badge bg-danger">98</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Ephemeral Tunnels (Cloudflare/Ngrok) <span class="badge bg-warning text-dark">42</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Brand Impersonation <span class="badge bg-info text-dark">18</span></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="dashboard-card">
                                    <h5 class="fw-bold mb-3">Scanner Agreement Breakdown</h5>
                                    <ul class="list-group list-group-flush bg-transparent">
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Both Clean (BOTH_SAFE) <span class="badge bg-success">11,950</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">Both Malicious (BOTH_DANGEROUS) <span class="badge bg-danger">412</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">VT Safe / Google Dangerous Conflict <span class="badge bg-warning text-dark">14</span></li>
                                        <li class="list-group-item bg-transparent text-light border-secondary d-flex justify-content-between align-items-center">VT Dangerous / Google Safe Conflict <span class="badge bg-warning text-dark">20</span></li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- PANE 4: PROVIDERS HEALTH -->
                    <div id="paneProviders" class="pane-content d-none">
                        <h4 class="fw-bold mb-4">Security Providers Health & Latency</h4>
                        <div class="dashboard-card">
                            <div class="row g-3" id="providerHealthCards">
                                <!-- Dynamic provider cards -->
                            </div>
                        </div>
                    </div>

                    <!-- PANE 5: BLOCKLIST -->
                    <div id="paneBlocklist" class="pane-content d-none">
                        <div class="d-flex justify-content-between align-items-center mb-4">
                            <h4 class="fw-bold m-0">Persistent Domain Blocklist</h4>
                            <button class="btn btn-danger btn-sm fw-bold" data-bs-toggle="modal" data-bs-target="#addBlockModal"><i class="fa-solid fa-plus me-1"></i>BLOCK NEW DOMAIN</button>
                        </div>
                        <div class="dashboard-card">
                            <div class="table-responsive">
                                <table class="table table-custom align-middle">
                                    <thead>
                                        <tr>
                                            <th>DOMAIN</th>
                                            <th>REASON</th>
                                            <th>RISK SCORE</th>
                                            <th>ADDED BY</th>
                                            <th>ADDED AT</th>
                                            <th>ACTION</th>
                                        </tr>
                                    </thead>
                                    <tbody id="blocklistTableBody">
                                        <!-- Dynamic Blocked Domains -->
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <!-- MODAL: ADD DOMAIN TO TECHNITIUM BLOCKLIST -->
    <div class="modal fade" id="blockTechnitiumModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content bg-dark text-light border-secondary">
                <div class="modal-header border-secondary">
                    <h5 class="modal-title fw-bold"><i class="fa-solid fa-ban text-danger me-2"></i>Block Domain in Technitium DNS</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="techBlockForm">
                        <div class="mb-3">
                            <label class="form-label small fw-bold">DOMAIN NAME</label>
                            <input type="text" id="techBlockDomainInput" class="form-control bg-secondary text-light border-0" placeholder="e.g. phishing-fakebank.com" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold">BLOCK REASON</label>
                            <input type="text" id="techBlockReasonInput" class="form-control bg-secondary text-light border-0" placeholder="Blocked via SecureBubble Admin Shield" value="Blocked by SecureBubble Administrator" required>
                        </div>
                        <button type="submit" class="btn btn-danger w-100 fw-bold">PUSH TO TECHNITIUM DNS BLOCKLIST</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL: ADD DOMAIN TO PERSISTENT BLOCKLIST -->
    <div class="modal fade" id="addBlockModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content bg-dark text-light border-secondary">
                <div class="modal-header border-secondary">
                    <h5 class="modal-title fw-bold">Block Domain</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <form id="blockDomainForm">
                        <div class="mb-3">
                            <label class="form-label small fw-bold">DOMAIN NAME</label>
                            <input type="text" id="blockDomainInput" class="form-control bg-secondary text-light border-0" placeholder="e.g. fakebank-login.com" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold">BLOCK REASON</label>
                            <input type="text" id="blockReasonInput" class="form-control bg-secondary text-light border-0" placeholder="Phishing & Brand Impersonation" required>
                        </div>
                        <button type="submit" class="btn btn-danger w-100 fw-bold">ADD TO FIREWALL BLOCKLIST</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        let token = localStorage.getItem('securebubble_token') || '';

        // Elements
        const loginScreen = document.getElementById('loginScreen');
        const mainDashboard = document.getElementById('mainDashboard');
        const loginForm = document.getElementById('loginForm');
        const loginAlert = document.getElementById('loginAlert');
        const logoutBtn = document.getElementById('logoutBtn');

        // Check stored token
        if (token) {
            verifyAndShowDashboard();
        }

        // Login Handler
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('loginEmail').value;
            const password = document.getElementById('loginPassword').value;

            try {
                const resp = await fetch('/api/v1/auth/admin/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email, password })
                });

                const data = await resp.json();
                if (resp.ok) {
                    token = data.access_token;
                    localStorage.setItem('securebubble_token', token);
                    verifyAndShowDashboard();
                } else {
                    loginAlert.innerText = data.detail || 'Invalid admin credentials.';
                    loginAlert.classList.remove('d-none');
                }
            } catch (err) {
                loginAlert.innerText = 'Connection error to backend.';
                loginAlert.classList.remove('d-none');
            }
        });

        // Logout
        logoutBtn.addEventListener('click', () => {
            localStorage.removeItem('securebubble_token');
            token = '';
            mainDashboard.classList.add('d-none');
            loginScreen.classList.remove('d-none');
        });

        // Verify and Load Dashboard
        async function verifyAndShowDashboard() {
            try {
                const resp = await fetch('/api/v1/auth/admin/me', {
                    headers: { 'Authorization': 'Bearer ' + token }
                });

                if (resp.ok) {
                    const userData = await resp.json();
                    document.getElementById('adminUserDisplay').innerHTML = `<i class="fa-solid fa-circle-user me-1 text-primary"></i>${userData.sub || 'admin@gmail.com'}`;
                    loginScreen.classList.add('d-none');
                    mainDashboard.classList.remove('d-none');
                    loadDashboardData();
                    loadScanHistory();
                    loadProviderHealth();
                    loadBlockedDomains();
                    refreshTechnitiumData();
                    loadAppConfig();
                } else {
                    localStorage.removeItem('securebubble_token');
                    loginScreen.classList.remove('d-none');
                }
            } catch (err) {
                loginScreen.classList.remove('d-none');
            }
        }

        // Navigation Tabs
        document.querySelectorAll('.nav-link-custom').forEach(link => {
            link.addEventListener('click', () => {
                document.querySelectorAll('.nav-link-custom').forEach(l => l.classList.remove('active'));
                link.classList.add('active');
                const target = link.getAttribute('data-pane');
                document.querySelectorAll('.pane-content').forEach(p => p.classList.add('d-none'));
                document.getElementById(target).classList.remove('d-none');
                if (target === 'paneTechnitium') {
                    refreshTechnitiumData();
                } else if (target === 'paneConfig') {
                    loadAppConfig();
                }
            });
        });

        // API Calls
        async function loadDashboardData() {
            const res = await fetch('/api/v1/admin/dashboard', { headers: { 'Authorization': 'Bearer ' + token } });
            if (res.ok) {
                const data = await res.json();
                document.getElementById('statTotalScans').innerText = data.metrics.total_url_scans.toLocaleString();
                document.getElementById('statThreatsDetected').innerText = data.metrics.threats_detected.toLocaleString();
                document.getElementById('statBlockedDomains').innerText = data.metrics.domains_blocked.toLocaleString();
            }
        }

        async function toggleWebDnsProtection(enabled) {
            try {
                const res = await fetch('/api/v1/admin/dns/toggle', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                    body: JSON.stringify({ enabled: enabled })
                });
                const data = await res.json();
                const lbl = document.getElementById('dnsToggleLabel');
                const sw = document.getElementById('dnsToggleSwitch');
                if (sw) sw.checked = data.dns_enabled;
                if (lbl) {
                    lbl.innerText = data.dns_enabled ? 'DNS SERVER ON' : 'DNS SERVER OFF';
                    lbl.className = data.dns_enabled ? 'form-check-label small fw-bold text-success' : 'form-check-label small fw-bold text-danger';
                }
                refreshTechnitiumData();
            } catch (err) {
                console.error("Toggle DNS error:", err);
            }
        }

        async function refreshTechnitiumData() {
            try {
                const statusRes = await fetch('/api/v1/admin/dns/status', { headers: { 'Authorization': 'Bearer ' + token } });
                if (statusRes.ok) {
                    const st = await statusRes.json();
                    const info = st.technitium_status || {};
                    const isEnabled = info.enabled !== false && info.status !== 'OFF';
                    const isOnline = info.status === 'ONLINE' || info.status === 'active';

                    const sw = document.getElementById('dnsToggleSwitch');
                    const lbl = document.getElementById('dnsToggleLabel');
                    if (sw) sw.checked = isEnabled;
                    if (lbl) {
                        lbl.innerText = isEnabled ? 'DNS SERVER ON' : 'DNS SERVER OFF';
                        lbl.className = isEnabled ? 'form-check-label small fw-bold text-success' : 'form-check-label small fw-bold text-danger';
                    }

                    document.getElementById('techServerStatus').innerText = isEnabled ? (isOnline ? 'ONLINE' : 'ACTIVE (ENGINE OFFLINE)') : 'OFF (DISABLED)';
                    document.getElementById('techServerStatus').className = isEnabled ? (isOnline ? 'fs-4 fw-bold text-success my-2' : 'fs-4 fw-bold text-warning my-2') : 'fs-4 fw-bold text-danger my-2';
                    document.getElementById('statusTechnitium').innerText = isEnabled ? (isOnline ? '🟢 ONLINE' : '⚠️ ENGINE OFFLINE') : '🔴 OFF';
                    document.getElementById('techTotalQueries').innerText = (info.total_queries || 0).toLocaleString();
                    document.getElementById('techTotalBlocked').innerText = (info.total_blocked || 0).toLocaleString();
                    document.getElementById('statDnsBlocked').innerText = (info.total_blocked || 0).toLocaleString();
                    document.getElementById('techLatency').innerText = (info.latency_ms || 0.0) + ' ms';
                    if (info.server_url) {
                        document.getElementById('techServerUrl').innerText = info.server_url;
                    }
                }


                // Blocked Domains List
                const blockedRes = await fetch('/api/v1/admin/dns/blocked', { headers: { 'Authorization': 'Bearer ' + token } });
                if (blockedRes.ok) {
                    const blData = await blockedRes.json();
                    const tbody = document.getElementById('techBlockedTableBody');
                    tbody.innerHTML = '';
                    if (blData.blocked_domains && blData.blocked_domains.length > 0) {
                        blData.blocked_domains.forEach(d => {
                            const domName = typeof d === 'string' ? d : (d.domain || d.name || 'domain');
                            const row = document.createElement('tr');
                            row.innerHTML = `
                                <td class="fw-bold text-danger">${domName}</td>
                                <td><button class="btn btn-outline-danger btn-sm" onclick="unblockTechnitiumDomain('${domName}')">Unblock</button></td>
                            `;
                            tbody.appendChild(row);
                        });
                    } else {
                        tbody.innerHTML = '<tr><td colspan="2" class="text-muted small">No active blocked domain rules in Technitium.</td></tr>';
                    }
                }

                // Query Logs
                const logsRes = await fetch('/api/v1/admin/dns/logs', { headers: { 'Authorization': 'Bearer ' + token } });
                if (logsRes.ok) {
                    const logsData = await logsRes.json();
                    const tbody = document.getElementById('dnsLogsTableBody');
                    tbody.innerHTML = '';
                    if (logsData.logs && logsData.logs.length > 0) {
                        logsData.logs.forEach(l => {
                            const row = document.createElement('tr');
                            row.innerHTML = `
                                <td class="small text-secondary">${l.timestamp || 'N/A'}</td>
                                <td class="small">${l.clientIp || l.client || '127.0.0.1'}</td>
                                <td class="fw-bold">${l.domain || l.query || 'N/A'}</td>
                                <td><span class="badge bg-secondary">${l.type || 'A'}</span></td>
                                <td><span class="badge ${l.blocked ? 'bg-danger' : 'bg-success'}">${l.blocked ? 'BLOCKED' : 'RESOLVED'}</span></td>
                            `;
                            tbody.appendChild(row);
                        });
                    } else {
                        tbody.innerHTML = '<tr><td colspan="5" class="text-muted small">No query logs recorded yet.</td></tr>';
                    }
                }

            } catch (err) {
                console.error("Technitium refresh error:", err);
            }
        }

        async function runWebDomainCheck() {
            const domain = document.getElementById('webCheckDomainInput').value.trim();
            if (!domain) return;

            const box = document.getElementById('webCheckResultBox');
            const nameEl = document.getElementById('webCheckDomainName');
            const badgeEl = document.getElementById('webCheckBadge');
            const msgEl = document.getElementById('webCheckMsg');

            try {
                const res = await fetch('/api/v1/dns/check?domain=' + encodeURIComponent(domain), {
                    headers: { 'Authorization': 'Bearer ' + token }
                });
                const data = await res.json();
                box.classList.remove('d-none');
                nameEl.innerText = data.domain || domain;
                if (data.is_blocked || data.status === 'BLOCKED') {
                    badgeEl.className = 'badge bg-danger';
                    badgeEl.innerText = '🚫 BLOCKED';
                } else {
                    badgeEl.className = 'badge bg-success';
                    badgeEl.innerText = '🟢 SAFE / ALLOWED';
                }
                msgEl.innerText = data.message || 'Domain check completed.';
            } catch (err) {
                box.classList.remove('d-none');
                badgeEl.className = 'badge bg-warning';
                badgeEl.innerText = '⚠️ UNCHECKED';
                msgEl.innerText = 'Unable to query Technitium DNS server.';
            }
        }

        async function loadAppConfig() {
            try {
                const res = await fetch('/api/v1/admin/config', { headers: { 'Authorization': 'Bearer ' + token } });
                if (res.ok) {
                    const cfg = await res.json();
                    document.getElementById('cfgTechUrl').value = cfg.technitium_server_url || '';
                    document.getElementById('cfgTechUser').value = cfg.technitium_admin_user || '';
                    document.getElementById('cfgTechPass').value = cfg.technitium_admin_password_masked || '';
                    document.getElementById('cfgAutoBlockThreshold').value = cfg.auto_block_threshold || 85;
                    document.getElementById('cfgTechTimeout').value = cfg.technitium_timeout_seconds || 5.0;
                    document.getElementById('cfgVtKey').value = cfg.virustotal_key_masked || '';
                    document.getElementById('cfgGoogleKey').value = cfg.google_web_risk_key_masked || '';
                    document.getElementById('cfgCacheTtl').value = cfg.scan_cache_ttl_seconds || 300;
                    document.getElementById('cfgProviderTimeout').value = cfg.provider_timeout_seconds || 4.0;
                    document.getElementById('cfgEnvironment').value = cfg.environment || 'development';
                }
            } catch (err) {
                console.error("Failed to load config:", err);
            }
        }

        async function saveSystemConfig() {
            const successAlert = document.getElementById('configSuccessAlert');
            const errorAlert = document.getElementById('configErrorAlert');
            successAlert.classList.add('d-none');
            errorAlert.classList.add('d-none');

            const payload = {
                technitium_server_url: document.getElementById('cfgTechUrl').value,
                technitium_admin_user: document.getElementById('cfgTechUser').value,
                technitium_admin_password: document.getElementById('cfgTechPass').value,
                auto_block_threshold: parseInt(document.getElementById('cfgAutoBlockThreshold').value) || 85,
                technitium_timeout_seconds: parseFloat(document.getElementById('cfgTechTimeout').value) || 5.0,
                virustotal_api_key: document.getElementById('cfgVtKey').value,
                google_web_risk_api_key: document.getElementById('cfgGoogleKey').value,
                scan_cache_ttl_seconds: parseInt(document.getElementById('cfgCacheTtl').value) || 300,
                provider_timeout_seconds: parseFloat(document.getElementById('cfgProviderTimeout').value) || 4.0,
                environment: document.getElementById('cfgEnvironment').value
            };

            try {
                const res = await fetch('/api/v1/admin/config', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();
                if (res.ok) {
                    successAlert.innerText = 'Configuration updated successfully! Updated fields: ' + (data.updated_fields ? data.updated_fields.join(', ') : 'All fields');
                    successAlert.classList.remove('d-none');
                    loadAppConfig();
                } else {
                    errorAlert.innerText = data.detail || 'Failed to save configuration.';
                    errorAlert.classList.remove('d-none');
                }
            } catch (err) {
                errorAlert.innerText = 'Connection error saving configuration.';
                errorAlert.classList.remove('d-none');
            }
        }

        // Technitium Block Form
        document.getElementById('techBlockForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const domain = document.getElementById('techBlockDomainInput').value;
            const reason = document.getElementById('techBlockReasonInput').value;

            const res = await fetch('/api/v1/admin/dns/block', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                body: JSON.stringify({ domain, reason })
            });

            if (res.ok) {
                bootstrap.Modal.getInstance(document.getElementById('blockTechnitiumModal')).hide();
                refreshTechnitiumData();
            }
        });

        async function unblockTechnitiumDomain(domain) {
            const res = await fetch('/api/v1/admin/dns/unblock/' + encodeURIComponent(domain), {
                method: 'DELETE',
                headers: { 'Authorization': 'Bearer ' + token }
            });
            if (res.ok) {
                refreshTechnitiumData();
            }
        }

        async function loadScanHistory() {
            const res = await fetch('/api/v1/admin/scans', { headers: { 'Authorization': 'Bearer ' + token } });
            if (res.ok) {
                const data = await res.json();
                const tbody = document.getElementById('scanHistoryTableBody');
                tbody.innerHTML = '';
                data.scans.forEach(scan => {
                    const row = document.createElement('tr');
                    const badgeClass = scan.securebubble.classification === 'CRITICAL' || scan.securebubble.classification === 'HIGH RISK' ? 'bg-danger' : 'bg-success';
                    row.innerHTML = `
                        <td class="small text-secondary">${new Date(scan.timestamp).toLocaleTimeString()}</td>
                        <td class="fw-bold">${scan.domain}</td>
                        <td class="small text-truncate" style="max-width:200px;">${scan.url}</td>
                        <td>${scan.virustotal.classification || 'unknown'}</td>
                        <td>${scan.google_web_risk.classification || 'unknown'}</td>
                        <td><span class="badge bg-secondary">${scan.comparison.status}</span></td>
                        <td class="fw-bold">${scan.securebubble.risk_score}/100</td>
                        <td><span class="badge ${badgeClass}">${scan.securebubble.classification}</span></td>
                    `;
                    tbody.appendChild(row);
                });
            }
        }

        async function loadProviderHealth() {
            const res = await fetch('/api/v1/admin/providers', { headers: { 'Authorization': 'Bearer ' + token } });
            if (res.ok) {
                const data = await res.json();
                const cardsContainer = document.getElementById('providerHealthCards');
                cardsContainer.innerHTML = '';
                for (const [key, p] of Object.entries(data.providers)) {
                    const statusBadge = p.configured ? '<span class="badge bg-success">ONLINE</span>' : '<span class="badge bg-secondary">UNCONFIGURED</span>';
                    const col = document.createElement('div');
                    col.className = 'col-md-6';
                    col.innerHTML = `
                        <div class="p-3 bg-dark rounded border border-secondary">
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <h6 class="fw-bold text-uppercase m-0">${key}</h6>
                                ${statusBadge}
                            </div>
                            <div class="small text-secondary">Latency: ${p.response_time_ms} ms</div>
                            <div class="small text-secondary">Last Request: ${p.last_successful_request || 'N/A'}</div>
                        </div>
                    `;
                    cardsContainer.appendChild(col);
                }
            }
        }

        async function loadBlockedDomains() {
            const res = await fetch('/api/v1/admin/domains/blocked', { headers: { 'Authorization': 'Bearer ' + token } });
            if (res.ok) {
                const data = await res.json();
                const tbody = document.getElementById('blocklistTableBody');
                tbody.innerHTML = '';
                data.blocked_domains.forEach(b => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td class="fw-bold text-danger">${b.domain}</td>
                        <td>${b.reason}</td>
                        <td><span class="badge bg-danger">${b.risk_score}</span></td>
                        <td>${b.added_by}</td>
                        <td class="small text-secondary">${b.added_at}</td>
                        <td><button class="btn btn-outline-danger btn-sm" onclick="removeDomain('${b.domain}')">Unblock</button></td>
                    `;
                    tbody.appendChild(row);
                });
            }
        }

        // Add domain handler
        document.getElementById('blockDomainForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const domain = document.getElementById('blockDomainInput').value;
            const reason = document.getElementById('blockReasonInput').value;

            const res = await fetch('/api/v1/admin/domains/block', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                body: JSON.stringify({ domain, reason })
            });

            if (res.ok) {
                bootstrap.Modal.getInstance(document.getElementById('addBlockModal')).hide();
                loadBlockedDomains();
                loadDashboardData();
            }
        });

        async function removeDomain(domain) {
            const res = await fetch('/api/v1/admin/domains/block/' + encodeURIComponent(domain), {
                method: 'DELETE',
                headers: { 'Authorization': 'Bearer ' + token }
            });
            if (res.ok) {
                loadBlockedDomains();
                loadDashboardData();
            }
        }
    </script>
</body>
</html>
"""


@router.get("", response_class=HTMLResponse)
@router.get("/", response_class=HTMLResponse)
async def get_admin_portal_page():
    """
    Serves the SecureBubble AI Responsive Admin Operations Portal Web UI with Technitium DNS Shield & App Configuration.
    """
    return HTMLResponse(content=ADMIN_HTML_CONTENT, status_code=200)
