import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../models/scan_model.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _callerController = TextEditingController();
  
  // Screenshot upload status
  PlatformFile? _selectedFile;
  bool _isAnalyzing = false;
  ScanHistoryItem? _scanResult;
  Map<String, dynamic>? _headerResult;
  Map<String, dynamic>? _callerResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _scanResult = null;
          _headerResult = null;
          _callerResult = null;
          _selectedFile = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _textController.dispose();
    _headerController.dispose();
    _callerController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _scanResult = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error choosing file: $e')),
      );
    }
  }

  // Simulate pasting screenshot from clipboard
  void _simulatePasteScreenshot() {
    setState(() {
      _selectedFile = PlatformFile(
        name: 'clipboard_screenshot_2026.png',
        size: 245000,
        bytes: Uint8List.fromList(List<int>.generate(100, (i) => i)), // dummy bytes
      );
      _scanResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot pasted from clipboard simulation.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _runScan(String type) async {
    String content = '';
    if (type == 'url') {
      content = _urlController.text.trim();
    } else if (type == 'text') {
      content = _textController.text.trim();
    }

    if (type != 'screenshot' && content.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _scanResult = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      ScanHistoryItem result;
      if (type == 'screenshot') {
        if (_selectedFile == null || _selectedFile!.bytes == null) {
          throw Exception('No screenshot selected');
        }
        result = await appState.executeScreenshotScan(
          bytes: _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        );
      } else {
        result = await appState.executeScan(
          inputType: type,
          inputContent: content,
        );
      }
      setState(() {
        _scanResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning failed: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _runHeaderScan() async {
    final content = _headerController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _headerResult = null;
      _scanResult = null;
      _callerResult = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final res = await appState.executeHeaderAnalysis(content);
      setState(() {
        _headerResult = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _runCallerLookup() async {
    final content = _callerController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _callerResult = null;
      _scanResult = null;
      _headerResult = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final res = await appState.executeCallerLookup(content);
      setState(() {
        _callerResult = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lookup failed: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      body: Stack(
        children: [
          // Ambient backgrounds
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowOrb(const Color(0xFF8B5CF6), 280),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _buildGlowOrb(const Color(0xFFEC4899), 250),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENGINES ACTIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8B5CF6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Threat Scanner Lab',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Custom Glass Tab bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF120828).withOpacity(0.6),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF4FACFE)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: const Color(0xFF040508),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'URL Scan'),
                        Tab(text: 'Text Scan'),
                        Tab(text: 'Screenshot'),
                        Tab(text: 'Email Header'),
                        Tab(text: 'Spam Lookup'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Scanner Content + Analysis Panel
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        // Input section (changes dynamically depending on active tab index)
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            return _buildTabInputPanel();
                          },
                        ),
                        const SizedBox(height: 24),

                        // Loading State OR Scan Results Show
                        if (_isAnalyzing) _buildScanningAnimation(),
                        if (_scanResult != null) _buildScanResultDetails(),
                        if (_headerResult != null) _buildHeaderResultDetails(),
                        if (_callerResult != null) _buildCallerResultDetails(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _buildTabInputPanel() {
    switch (_tabController.index) {
      case 0:
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter URL to Inspect',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: _getInputDecoration('https://suspicious-link.com/secure-login'),
              ),
              const SizedBox(height: 20),
              _buildAnalyzeButton(() => _runScan('url')),
            ],
          ),
        );
      case 1:
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste SMS / Email Message Text',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 4,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: _getInputDecoration('Paste full content here to evaluate heuristics...'),
              ),
              const SizedBox(height: 20),
              _buildAnalyzeButton(() => _runScan('text')),
            ],
          ),
        );
      case 2:
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Screenshot Scanning (OCR)',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Analyze mock texts, banners, or suspicious message images.',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📸', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              'Click to Browse Screenshot',
                              style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📄', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFile!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _simulatePasteScreenshot,
                    icon: const Icon(Icons.paste_rounded, size: 16, color: Color(0xFF8B5CF6)),
                    label: Text(
                      'Paste Screenshot Simulation',
                      style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_selectedFile != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedFile = null),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAnalyzeButton(
                _selectedFile == null ? null : () => _runScan('screenshot'),
              ),
            ],
          ),
        );
      case 3:
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Email Header Analyzer',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Paste raw email headers to evaluate DKIM, SPF, and DMARC alignment security.',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _headerController,
                maxLines: 4,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                decoration: _getInputDecoration('Paste full header fields (Received, From, DKIM-Signature)...'),
              ),
              const SizedBox(height: 20),
              _buildAnalyzeButton(_runHeaderScan),
            ],
          ),
        );
      case 4:
        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Spam ID & Caller Lookup',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Lookup phone numbers or SMS sender names to check spam records.',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _callerController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: _getInputDecoration('e.g., +1 (800) 444-1234 or USPS-ALERT'),
              ),
              const SizedBox(height: 20),
              _buildAnalyzeButton(_runCallerLookup),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF120828).withOpacity(0.55),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: child,
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
        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildAnalyzeButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF4FACFE)]),
          color: onPressed == null ? Colors.white.withOpacity(0.04) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          'Analyze Input ⚡',
          style: GoogleFonts.outfit(
            color: onPressed == null ? const Color(0xFF64748B) : const Color(0xFF040508),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Column(
      children: [
        const SizedBox(height: 32),
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Running Security Sandbox & Heuristics...',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Querying global threat feeds and lexical patterns...',
          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildScanResultDetails() {
    final result = _scanResult!;
    Color riskColor = const Color(0xFF10B981);
    if (result.riskLevel == 'SUSPICIOUS') riskColor = const Color(0xFFF59E0B);
    if (result.riskLevel == 'DANGEROUS') riskColor = const Color(0xFFEF4444);

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SECURITY REPORT',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.08),
                      border: Border.all(color: riskColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.riskLevel,
                      style: GoogleFonts.outfit(color: riskColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Threat score meter
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: result.riskScore / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withOpacity(0.04),
                            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${result.riskScore}%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'RISK INDEX',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Reasons list
              Text(
                'Detected Vulnerabilities',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (result.reasons.isEmpty)
                Text(
                  'No critical threat flags matched.',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                )
              else
                ...result.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•', style: TextStyle(color: Color(0xFFEF4444), fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Geo IP / Domain Metadata
              if (result.geoIp != null) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Text(
                  'Server & Domain Details',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildDetailsRow('IP Address', result.geoIp!['ip'] ?? 'N/A'),
                _buildDetailsRow('Location', result.geoIp!['country'] ?? 'N/A'),
                _buildDetailsRow('Provider', result.geoIp!['isp'] ?? 'N/A'),
                _buildDetailsRow('Domain Age', result.geoIp!['domain_age'] ?? 'N/A'),
              ],

              // Weights breakdown
              if (result.weights.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Text(
                  'AI Classifier Breakdown',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...result.weights.entries.map((w) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              w.key.replaceAll('_', ' ').toUpperCase(),
                              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              w.value,
                              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            color: Colors.white.withOpacity(0.04),
                            child: LinearProgressIndicator(
                              value: double.tryParse(w.value.replaceAll('%', '')) != null
                                  ? double.parse(w.value.replaceAll('%', '')) / 100
                                  : 0.0,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderResultDetails() {
    final result = _headerResult!;
    final status = result['status'] ?? 'UNKNOWN';
    final Color statusColor;
    switch (status) {
      case 'PASS':
        statusColor = const Color(0xFF10B981);
        break;
      case 'FAIL':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EMAIL HEADER ANALYSIS',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (result['dkim'] != null) _buildDetailsRow('DKIM', result['dkim']),
              if (result['spf'] != null) _buildDetailsRow('SPF', result['spf']),
              if (result['dmarc'] != null) _buildDetailsRow('DMARC', result['dmarc']),
              if (result['message'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  result['message'],
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallerResultDetails() {
    final result = _callerResult!;
    final risk = result['risk'] ?? 'UNKNOWN';
    final Color riskColor;
    switch (risk) {
      case 'SAFE':
        riskColor = const Color(0xFF10B981);
        break;
      case 'SPAM':
        riskColor = const Color(0xFFEF4444);
        break;
      default:
        riskColor = const Color(0xFFF59E0B);
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CALLER / SMS LOOKUP',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.08),
                      border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      risk,
                      style: GoogleFonts.outfit(color: riskColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (result['carrier'] != null) _buildDetailsRow('Carrier', result['carrier']),
              if (result['reports'] != null) _buildDetailsRow('Spam Reports', result['reports'].toString()),
              if (result['type'] != null) _buildDetailsRow('Type', result['type']),
              if (result['message'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  result['message'],
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
