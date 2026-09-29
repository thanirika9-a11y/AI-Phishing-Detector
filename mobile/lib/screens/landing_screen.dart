import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onLaunch;

  const LandingScreen({super.key, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Ambient Background Orbs
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowOrb(const Color(0xFFEF4444), 300),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _buildGlowOrb(const Color(0xFFDC2626), 250),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.3,
            child: _buildGlowOrb(const Color(0xFF10B981).withOpacity(0.4), 200),
          ),

          // Content Layout
          SafeArea(
            child: Column(
              children: [
                // Top Custom Nav bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🛡️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Aegis AI',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: onLaunch,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.04),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Console →',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Tech badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.06),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔬', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                'Powered by Hybrid AI + Lexical Heuristics',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Hero title
                        Text(
                          'Stop Phishing Attacks\nBefore They Start',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'Real-time AI-powered detection engine that analyzes URLs, emails, and SMS messages to identify phishing attempts, social engineering, and online scams instantly.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // CTA Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: onLaunch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Text(
                                  'Launch Security Console  →',
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
                        const SizedBox(height: 48),

                        // Stats Bar grid
                        _buildStatsGrid(),
                        const SizedBox(height: 48),

                        // Features Title
                        Text(
                          'What Makes It Powerful',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Feature list
                        _buildFeatureCard(
                          icon: '🌐',
                          title: 'URL Threat Analysis',
                          desc: 'Instantly detect phishing domains, typosquatting attacks, and malicious redirects with multi-layer URL inspection.',
                          tag: 'CORE',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          icon: '📸',
                          title: 'Screenshot Threat Scan',
                          desc: 'Upload or paste screenshots of suspicious texts or alert emails for automatic extraction and safety verification.',
                          tag: 'NEW',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          icon: '✉️',
                          title: 'Email & SMS Scanner',
                          desc: 'AI-powered natural language analysis identifies urgency manipulation, credential harvesting, and social hooks.',
                          tag: 'AI',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          icon: '🚨',
                          title: 'Community Threat Feeds',
                          desc: 'Crowdsourced reports database allows you to report scams to protect others and view live global threat maps.',
                          tag: 'SOCIAL',
                        ),
                        const SizedBox(height: 32),
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
        color: color.withOpacity(0.07),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'val': '98.2%', 'lbl': 'Accuracy'},
      {'val': '<5ms', 'lbl': 'Analysis Speed'},
      {'val': '42k+', 'lbl': 'Analyzed'},
      {'val': '24/7', 'lbl': 'Uptime'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((st) {
          return Expanded(
            child: Column(
              children: [
                Text(
                  st['val']!,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  st['lbl']!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String desc,
    required String tag,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0000).withOpacity(0.55),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
