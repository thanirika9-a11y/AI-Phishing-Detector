import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignup = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _passwordScore = 0;
  String _passwordLabel = '';
  List<String> _passwordChecks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    if (!_isSignup || _passwordController.text.isEmpty) {
      setState(() {
        _passwordScore = 0;
        _passwordLabel = '';
        _passwordChecks = [];
      });
      return;
    }

    final password = _passwordController.text;
    int score = 0;
    final List<String> checks = [];

    if (password.length >= 8) {
      score += 25;
      checks.add('8+ chars');
    }
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 25;
      checks.add('Uppercase');
    }
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 25;
      checks.add('Number');
    }
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      score += 25;
      checks.add('Symbol');
    }

    String label = 'Weak';
    if (score > 25 && score <= 50) label = 'Fair';
    if (score > 50 && score <= 75) label = 'Good';
    if (score > 75) label = 'Strong';

    setState(() {
      _passwordScore = score;
      _passwordLabel = label;
      _passwordChecks = checks;
    });
  }

  Color _getStrengthColor() {
    if (_passwordScore <= 25) return const Color(0xFFEF4444);
    if (_passwordScore <= 50) return const Color(0xFFF59E0B);
    if (_passwordScore <= 75) return const Color(0xFF8B5CF6);
    return const Color(0xFF10B981);
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    setState(() {
      _errorMessage = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (_isSignup) {
        await appState.signup(username, password);
      } else {
        await appState.login(username, password);
      }
      widget.onAuthSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      body: Stack(
        children: [
          // Background Orbs
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowOrb(const Color(0xFF8B5CF6), 300),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _buildGlowOrb(const Color(0xFFEC4899), 250),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF120828).withOpacity(0.65),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo icon
                        const Center(child: Text('🛡️', style: TextStyle(fontSize: 48))),
                        const SizedBox(height: 16),

                        // Logo text
                        Center(
                          child: Text(
                            'Aegis AI Phishing Detector',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Tab Selector
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSignup = false;
                                    _errorMessage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !_isSignup ? const Color(0xFF8B5CF6) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Sign In',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: !_isSignup ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSignup = true;
                                    _errorMessage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _isSignup ? const Color(0xFF8B5CF6) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Create Account',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: _isSignup ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Username text field
                        Text(
                          'Username',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameController,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter username',
                            hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
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
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password text field
                        Text(
                          'Password',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
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
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password strength checks (for signup only)
                        if (_isSignup && _passwordController.text.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * (_passwordScore / 100),
                                    decoration: BoxDecoration(
                                      color: _getStrengthColor(),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Password Strength',
                                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    _passwordLabel,
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _getStrengthColor()),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _passwordChecks.map((check) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.08),
                                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      check,
                                      style: GoogleFonts.outfit(fontSize: 9, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Error alerts
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.08),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit Button
                        ElevatedButton(
                          onPressed: appState.isLoading ? null : _handleSubmit,
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
                                colors: [Color(0xFF8B5CF6), Color(0xFF4FACFE)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: appState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF040508),
                                    ),
                                  )
                                : Text(
                                    _isSignup ? 'Create Account' : 'Sign In',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF040508),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        color: color.withOpacity(0.06),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
