import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../providers/admin_provider.dart';
import 'admin_audit_log_screen.dart';

class AdminHealthScreen extends StatelessWidget {
  const AdminHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final metrics = admin.metrics;
    final providers = admin.providers;

    return Scaffold(
      backgroundColor: ShiraziColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShiraziColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'SUPERUSER',
                  style: ShiraziTypography.labelSm(
                    color: ShiraziColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ShiraziColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              'Admin System Metrics',
              style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: ShiraziColors.onSurfaceVariant),
            onPressed: () => admin.refreshDiagnostics(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: ShiraziSpacing.gutterMobile).copyWith(
          top: 12,
          bottom: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sub-navigation Segment Pill Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerLowest,
                borderRadius: ShiraziRadius.roundedXl,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminAuditLogScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Inquiries Log',
                            style: ShiraziTypography.labelMd(color: ShiraziColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerHigh,
                        borderRadius: ShiraziRadius.roundedMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: ShiraziColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'API & Keys',
                            style: ShiraziTypography.labelMd(
                              color: ShiraziColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'Lucene Index',
                          style: ShiraziTypography.labelMd(color: ShiraziColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ShiraziSpacing.spaceMd),

            // KPI Metric Mosaic
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Active Pool',
                    value: '${metrics.activeNodes}',
                    total: '/ ${metrics.totalNodes}',
                    subtext: '${metrics.validityRate}% Healthy',
                    color: ShiraziColors.secondary,
                    subtextColor: ShiraziColors.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Cooling (429)',
                    value: '${metrics.coolingKeys}',
                    total: 'Keys',
                    subtext: 'Backoff: ~120s',
                    color: ShiraziColors.tertiary,
                    subtextColor: ShiraziColors.tertiaryFixedDim,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Revoked/Err',
                    value: '${metrics.errorKeys}',
                    total: 'Fatal',
                    subtext: 'Action req.',
                    color: ShiraziColors.error,
                    subtextColor: ShiraziColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ShiraziSpacing.spaceMd),

            // Aggregate Throughput Sparkline Visual Card
            Container(
              padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerLow,
                borderRadius: ShiraziRadius.roundedXl,
                border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GLOBAL CONCURRENCY & LOAD',
                            style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${metrics.inferencesPerMin} Inferences / min • ${metrics.validityRate}% Validity',
                            style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${metrics.p95LatencyMs} ms',
                            style: ShiraziTypography.headlineSm(color: ShiraziColors.secondary),
                          ),
                          Text(
                            'p95 Latency',
                            style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sparkline graph
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SparklinePainter(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ShiraziSpacing.spaceMd),

            // Live Diagnostics Provider Probes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIVE AI PROVIDER PROBES (${providers.length})',
                  style: ShiraziTypography.labelMd(
                    color: ShiraziColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (admin.isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ShiraziColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (admin.isLoading)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLow,
                  borderRadius: ShiraziRadius.roundedMd,
                  border: Border.all(color: ShiraziColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ShiraziColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Probing all 11 live AI cluster nodes on Shirazi server... (Takes ~15-20s)',
                        style: ShiraziTypography.bodySm(color: ShiraziColors.primaryFixedDim),
                      ),
                    ),
                  ],
                ),
              ),

            if (providers.isEmpty && !admin.isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLowest,
                  borderRadius: ShiraziRadius.roundedLg,
                  border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, size: 36, color: ShiraziColors.outline),
                    const SizedBox(height: 10),
                    Text(
                      admin.errorMessage ?? 'No live provider diagnostics returned.',
                      textAlign: TextAlign.center,
                      style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ShiraziColors.surfaceContainerHigh,
                        foregroundColor: ShiraziColors.primary,
                      ),
                      onPressed: () => admin.refreshDiagnostics(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Probe'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: providers.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerLowest,
                      borderRadius: ShiraziRadius.roundedLg,
                      border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: p.isOnline
                                      ? ShiraziColors.secondary
                                      : (p.isRateLimited ? ShiraziColors.tertiary : ShiraziColors.error),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            p.providerName,
                                            style: ShiraziTypography.bodyMd(
                                              color: ShiraziColors.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${p.model})',
                                          style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    if (p.detail.isNotEmpty)
                                      Text(
                                        p.detail,
                                        style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ShiraziColors.surfaceContainerHigh,
                            borderRadius: ShiraziRadius.roundedFull,
                          ),
                          child: Text(
                            '${p.latencyMs.toInt()} ms',
                            style: ShiraziTypography.labelSm(
                              color: p.isOnline ? ShiraziColors.secondary : ShiraziColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String total,
    required String subtext,
    required Color color,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLowest,
        borderRadius: ShiraziRadius.roundedXl,
        border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: ShiraziTypography.headlineLg(
                  color: color == ShiraziColors.tertiary ? color : ShiraziColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                total,
                style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: ShiraziTypography.labelSm(color: subtextColor),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = ShiraziColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ShiraziColors.secondary.withOpacity(0.3),
          ShiraziColors.secondary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.8, size.width * 0.3, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.2, size.width * 0.6, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.3, size.width * 0.9, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.35);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
