import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/report_model.dart';

class ReporterScreen extends StatefulWidget {
  const ReporterScreen({super.key});

  @override
  State<ReporterScreen> createState() => _ReporterScreenState();
}

class _ReporterScreenState extends State<ReporterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _indicatorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedScamType = 'phishing';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _indicatorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.executeReport(
        scamType: _selectedScamType,
        indicator: _indicatorController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      _indicatorController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crowdsourced threat successfully logged!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Background Glow Orbs
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowOrb(const Color(0xFFEF4444), 280),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildGlowOrb(const Color(0xFFDC2626), 250),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'CROWDSOURCED SECURITY',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Threat Report Hub',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interactive Form inside a Glass Panel
                  _buildGlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Report a Threat Vector',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Scam Type Dropdown
                          Text(
                            'Threat Type',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 6),
                          _buildDropdown(),
                          const SizedBox(height: 16),

                          // Indicator input
                          Text(
                            'Indicator (URL, Phone #, or Email sender)',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _indicatorController,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a valid indicator' : null,
                            decoration: _getInputDecoration('e.g. +1 (800) 555-0199 or badsite.net'),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            'Short Description / Message Copy',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please describe the threat context' : null,
                            decoration: _getInputDecoration('What details or context did this message try to request?'),
                          ),
                          const SizedBox(height: 20),

                          // Submit button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF040508),
                                      ),
                                    )
                                  : Text(
                                      'Broadcast Alert to Global Feed 📣',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF040508),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent crowdsourced threats header
                  Text(
                    'Live Threat Intelligence Feed',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live reports feed
                  if (appState.recentReports.isEmpty)
                    _buildEmptyReportsCard()
                  else
                    ...appState.recentReports.map((report) => _buildReportFeedCard(report)),
                  const SizedBox(height: 32),
                ],
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
        color: color.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0000).withOpacity(0.55),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedScamType,
          dropdownColor: const Color(0xFF1A0000),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFEF4444)),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'phishing', child: Text('Phishing (Email/Web)')),
            DropdownMenuItem(value: 'smishing', child: Text('Smishing (SMS Scam)')),
            DropdownMenuItem(value: 'vishing', child: Text('Vishing (Robocall/Voice)')),
            DropdownMenuItem(value: 'other', child: Text('Other Scam Vector')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedScamType = val;
              });
            }
          },
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildReportFeedCard(ScamReport report) {
    Color badgeColor = const Color(0xFFEF4444);
    if (report.scamType == 'smishing') badgeColor = const Color(0xFFDC2626);
    if (report.scamType == 'vishing') badgeColor = const Color(0xFFF59E0B);
    if (report.scamType == 'other') badgeColor = const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.5),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.08),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.scamType.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              Text(
                _formatTimeAgo(report.timestamp),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.indicator,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            report.description,
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.security, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Broadcast Verified • Source IP: ${report.reporterIp.replaceRange(3, report.reporterIp.length, ".xx.xx")}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ],
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
        color: const Color(0xFF1A0000).withOpacity(0.4),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('🛰️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Feed Currently Synchronized',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Global network threat logs will render here in real-time.',
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
