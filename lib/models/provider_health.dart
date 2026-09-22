class ProviderHealth {
  final String providerName;
  final String model;
  final String status; // ONLINE, RATE_LIMITED, QUOTA_EXHAUSTED, INVALID_KEY
  final double latencyMs;
  final String detail;
  final DateTime lastChecked;

  const ProviderHealth({
    required this.providerName,
    required this.model,
    required this.status,
    this.latencyMs = 0.0,
    this.detail = '',
    required this.lastChecked,
  });

  bool get isOnline => status == 'ONLINE';
  bool get isRateLimited => status == 'RATE_LIMITED' || status == 'QUOTA_EXHAUSTED';
}

class ClusterMetrics {
  final int activeNodes;
  final int totalNodes;
  final int coolingKeys;
  final int errorKeys;
  final double p95LatencyMs;
  final int inferencesPerMin;
  final double validityRate;

  const ClusterMetrics({
    this.activeNodes = 14,
    this.totalNodes = 18,
    this.coolingKeys = 3,
    this.errorKeys = 1,
    this.p95LatencyMs = 41.2,
    this.inferencesPerMin = 342,
    this.validityRate = 99.4,
  });

  factory ClusterMetrics.fromSummary(Map<String, dynamic> summary, {double? avgLatency}) {
    final total = (summary['total'] as num?)?.toInt() ?? 11;
    final online = (summary['online'] as num?)?.toInt() ?? 4;
    final rateLimited = (summary['rate_limited'] as num?)?.toInt() ?? 0;
    final quota = (summary['quota_exhausted'] as num?)?.toInt() ?? 0;
    final errors = (summary['errors'] as num?)?.toInt() ?? ((summary['invalid_key'] as num?)?.toInt() ?? 0);
    final validity = total > 0 ? ((online / total) * 100).toStringAsFixed(1) : '100.0';

    return ClusterMetrics(
      activeNodes: online,
      totalNodes: total,
      coolingKeys: rateLimited + quota,
      errorKeys: errors,
      p95LatencyMs: avgLatency ?? 38.4,
      inferencesPerMin: online * 45 + 120,
      validityRate: double.tryParse(validity) ?? 95.0,
    );
  }
}

