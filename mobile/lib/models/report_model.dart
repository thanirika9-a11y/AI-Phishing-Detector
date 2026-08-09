class ScamReport {
  final int? id;
  final String scamType;
  final String indicator;
  final String description;
  final String reporterIp;
  final DateTime timestamp;

  ScamReport({
    this.id,
    required this.scamType,
    required this.indicator,
    required this.description,
    required this.reporterIp,
    required this.timestamp,
  });

  factory ScamReport.fromJson(Map<String, dynamic> json) {
    return ScamReport(
      id: json['id'],
      scamType: json['scam_type'] ?? 'phishing',
      indicator: json['indicator'] ?? '',
      description: json['description'] ?? '',
      reporterIp: json['reporter_ip'] ?? '127.0.0.1',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scam_type': scamType,
      'indicator': indicator,
      'description': description,
      'reporter_ip': reporterIp,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
