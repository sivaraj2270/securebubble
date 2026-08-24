class DomainResult {
  final String domain;
  final bool isHttps;
  final String domainAgeStatus;
  final String registrar;
  final String dnsStatus;
  final String threatIntelStatus;
  final String brandImpersonationStatus;
  final String detectedBrand;
  final String expectedOfficialDomain;
  final String riskLevel;

  DomainResult({
    required this.domain,
    required this.isHttps,
    required this.domainAgeStatus,
    required this.registrar,
    required this.dnsStatus,
    required this.threatIntelStatus,
    required this.brandImpersonationStatus,
    required this.detectedBrand,
    required this.expectedOfficialDomain,
    required this.riskLevel,
  });

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'isHttps': isHttps,
        'domainAgeStatus': domainAgeStatus,
        'registrar': registrar,
        'dnsStatus': dnsStatus,
        'threatIntelStatus': threatIntelStatus,
        'brandImpersonationStatus': brandImpersonationStatus,
        'detectedBrand': detectedBrand,
        'expectedOfficialDomain': expectedOfficialDomain,
        'riskLevel': riskLevel,
      };
}
