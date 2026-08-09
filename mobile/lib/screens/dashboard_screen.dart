import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/scan_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).refreshTelemetry();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -150,
            right: -100,
            child: _buildGlowOrb(const Color(0xFF8B5CF6), 280),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildGlowOrb(const Color(0xFFEC4899), 280),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: appState.refreshTelemetry,
              color: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFF120828),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    _buildHeader(appState),
                    const SizedBox(height: 24),

                    // Metrics Grid (4 Cards)
                    _buildMetricsGrid(appState),
                    const SizedBox(height: 24),

                    // Risk Breakdown Visual Widget
                    _buildRiskBreakdown(appState),
                    const SizedBox(height: 24),

                    // Scam Typology Breakdown
                    _buildScamTypology(appState),
                    const SizedBox(height: 28),

                    // Recent Threat Scans header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Real-time Scanner Logs',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () => appState.setActiveTab('scanner'),
                          child: Text(
                            'Scan New →',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8B5CF6),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Scan history items
                    if (appState.recentScans.isEmpty)
                      _buildEmptyScansCard()
                    else
                      ...appState.recentScans.take(5).map((scan) => _buildScanHistoryCard(scan)),
                    
                    const SizedBox(height: 32),

                    // Community Reported Threats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reported Threats',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () => appState.setActiveTab('reporter'),
                          child: Text(
                            'Report New →',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8B5CF6),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (appState.recentReports.isEmpty)
                      _buildEmptyReportsCard()
                    else
                      ...appState.recentReports.take(5).map((report) => _buildReportHistoryCard(report)),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeader(AppState appState) {
    final username = appState.currentUser?['username'] ?? 'Security Analyst';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aegis Console',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8B5CF6),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back, $username',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
          tooltip: 'Sign Out',
          onPressed: () {
            appState.logout();
          },
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(AppState appState) {
    final safeCount = appState.scansBreakdown['safe'] ?? 0;
    final suspiciousCount = appState.scansBreakdown['suspicious'] ?? 0;
    final dangerousCount = appState.scansBreakdown['dangerous'] ?? 0;
    final totalBreakdown = safeCount + suspiciousCount + dangerousCount;
    final safePercent = totalBreakdown > 0 ? (safeCount / totalBreakdown * 100).round() : 100;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Analyzed',
                value: appState.totalScans.toString(),
                icon: '🔍',
                color: const Color(0xFF00F2FE),
                bgColor: const Color(0xFF00F2FE).withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                label: 'Crowdsourced Reports',
                value: appState.totalReports.toString(),
                icon: '📢',
                color: const Color(0xFFB34EFF),
                bgColor: const Color(0xFFB34EFF).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Safe Queries',
                value: '$safePercent%',
                icon: '🛡️',
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                label: 'Malicious Threat Logs',
                value: dangerousCount.toString(),
                icon: '⚠️',
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String icon,
    required Color color,
    required Color bgColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF120828).withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBreakdown(AppState appState) {
    final safe = appState.scansBreakdown['safe'] ?? 0;
    final suspicious = appState.scansBreakdown['suspicious'] ?? 0;
    final dangerous = appState.scansBreakdown['dangerous'] ?? 0;
    final total = safe + suspicious + dangerous;

    final double safePct = total == 0 ? 0.0 : safe / total;
    final double suspPct = total == 0 ? 0.0 : suspicious / total;
    final double dangerPct = total == 0 ? 0.0 : dangerous / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF120828).withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Threat Level Share',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildProgressBar('Safe Queries', safe, safePct, const Color(0xFF10B981)),
              const SizedBox(height: 12),
              _buildProgressBar('Suspicious Alerts', suspicious, suspPct, const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _buildProgressBar('Confirmed Phish', dangerous, dangerPct, const Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScamTypology(AppState appState) {
    final reportsByType = appState.reportsByType;
    final total = reportsByType.values.fold(0, (a, b) => a + b);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF120828).withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scam Typology Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ...reportsByType.entries.map((entry) {
                final double pct = total == 0 ? 0.0 : entry.value / total;
                Color color = const Color(0xFFB34EFF);
                if (entry.key == 'phishing') color = const Color(0xFF00F2FE);
                if (entry.key == 'smishing') color = const Color(0xFF10B981);
                if (entry.key == 'vishing') color = const Color(0xFFF59E0B);
                
                String label = entry.key;
                if (label.isNotEmpty) {
                  label = label[0].toUpperCase() + label.substring(1);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildProgressBar(label, entry.value, pct, color),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              value.toString(),
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: Colors.white.withValues(alpha: 0.05),
            child: Row(
              children: [
                Expanded(
                  flex: (percent * 100).round(),
                  child: Container(color: color),
                ),
                Expanded(
                  flex: 100 - (percent * 100).round(),
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanHistoryCard(ScanHistoryItem scan) {
    Color riskColor = const Color(0xFF10B981);
    if (scan.riskLevel == 'SUSPICIOUS') riskColor = const Color(0xFFF59E0B);
    if (scan.riskLevel == 'DANGEROUS') riskColor = const Color(0xFFEF4444);
    
    // Extract first reason
    String reasonText = "No risk markers identified.";
    try {
      import 'dart:convert';
      final details = jsonDecode(scan.detailsJson);
      if (details['reasons'] != null && details['reasons'].isNotEmpty) {
        reasonText = details['reasons'][0];
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF120828).withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${scan.inputType.toUpperCase()}: ${scan.inputContent}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFFC4B5FD),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(scan.timestamp),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reasonText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  border: Border.all(color: riskColor.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: riskColor.withValues(alpha: 0.15), blurRadius: 8)
                  ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: riskColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '${scan.riskLevel} (${scan.riskScore}%)',
                      style: GoogleFonts.outfit(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportHistoryCard(dynamic report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF120828).withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${report.scamType.toUpperCase()}: ${report.indicator}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${report.timestamp.month}/${report.timestamp.day}/${report.timestamp.year}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.description.isEmpty ? "No description provided." : report.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'REPORTED',
              style: GoogleFonts.outfit(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScansCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF120828).withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'No Scans Executed Yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start analyzing suspicious links or texts to protect your profile.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReportsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF120828).withValues(alpha: 0.4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('📢', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'No Active Threats Reported',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
