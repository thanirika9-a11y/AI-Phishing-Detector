import 'dart:convert';

class ScanHistoryItem {
  final int? id;
  final String inputType;
  final String inputContent;
  final int riskScore;
  final String riskLevel;
  final String detailsJson;
  final DateTime timestamp;

  ScanHistoryItem({
    this.id,
    required this.inputType,
    required this.inputContent,
    required this.riskScore,
    required this.riskLevel,
    required this.detailsJson,
    required this.timestamp,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'],
      inputType: json['input_type'] ?? 'url',
      inputContent: json['input_content'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'SAFE',
      detailsJson: json['details_json'] ?? '{}',
      timestamp: () {
        final rawTs = json['timestamp'];
        if (rawTs == null) return DateTime.now();
        String str = rawTs.toString();
        if (!str.endsWith('Z') && !str.contains('+')) {
          str += 'Z';
        }
        return DateTime.tryParse(str)?.toLocal() ?? DateTime.now();
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'input_type': inputType,
      'input_content': inputContent,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'details_json': detailsJson,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Decoded details helpers
  Map<String, dynamic> get details {
    try {
      return jsonDecode(detailsJson);
    } catch (_) {
      return {};
    }
  }

  List<String> get reasons {
    final list = details['reasons'];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic>? get geoIp {
    final geo = details['geo_ip'];
    if (geo is Map<String, dynamic>) {
      return geo;
    }
    return null;
  }

  Map<String, String> get weights {
    final w = details['weights'];
    if (w is Map<String, dynamic>) {
      return w.map((key, value) => MapEntry(key, value.toString()));
    }
    return {};
  }
}
