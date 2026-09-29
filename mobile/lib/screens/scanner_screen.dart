import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ml_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0202), // Dark reddish-black
              Color(0xFF030101), // Almost solid black
              Color(0xFF060000), // Slightly warmer deep black
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient backgrounds
            Positioned(
              top: -100,
              left: -100,
              child: _buildGlowOrb(const Color(0xFFEF4444), 320),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: _buildGlowOrb(const Color(0xFFDC2626), 280),
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
                          color: const Color(0xFFEF4444),
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
                      color: const Color(0xFF1A0000).withOpacity(0.6),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
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

                // ML Dataset Upload Panel (embedded in every tab)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: MlScreen(
                          key: ValueKey(['url', 'text', 'screenshot', 'email', 'spam'][_tabController.index]),
                          embedded: true,
                          category: ['url', 'text', 'screenshot', 'email', 'spam'][_tabController.index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
}
