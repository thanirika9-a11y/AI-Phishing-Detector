import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  // Hardcoded premium quiz questions to guarantee beautiful interactive training lab offline or online
  final List<Map<String, dynamic>> _fallbackQuestions = [
    {
      'id': 1,
      'content': 'Subject: ACTION REQUIRED - Confirm Google account recovery phone now at http://google-support-recovery.net/auth',
      'options': ['Legitimate Message', 'Phishing Attempt'],
      'correct_index': 1,
      'explanation': 'Look at the domain name: google-support-recovery.net. It is not google.com. Scammers register domains containing trusted brand names to fool targets.',
    },
    {
      'id': 2,
      'content': 'SMS: [USPS Alert] Your shipment has been put on hold due to missing street number. Fix it at http://usps-redirection-post.link',
      'options': ['Legitimate Message', 'Phishing Attempt'],
      'correct_index': 1,
      'explanation': 'USPS will never text you to correct addresses using unusual domain names like .link. This is a classic smishing hook.',
    },
    {
      'id': 3,
      'content': 'Email: Hi, I noticed your portfolio contains several spelling errors. I have compiled the corrections here: http://github.com/designers-feedback/repo/pulls',
      'options': ['Legitimate Message', 'Phishing Attempt'],
      'correct_index': 0,
      'explanation': 'This link redirects to the official github.com domain. While links can contain malicious files, the domain itself is trusted.',
    },
  ];

  int _currentIndex = 0;
  int? _selectedAnswerIndex;
  int _score = 0;
  bool _quizFinished = false;

  void _answerQuestion(int index) {
    if (_selectedAnswerIndex != null) return; // Answer already selected
    setState(() {
      _selectedAnswerIndex = index;
      if (index == _fallbackQuestions[_currentIndex]['correct_index']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _fallbackQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
      _submitQuizResult();
    }
  }

  Future<void> _submitQuizResult() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await appState.executeSubmitQuizScore(
        score: _score,
        total: _fallbackQuestions.length,
      );
    } catch (_) {}
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswerIndex = null;
      _score = 0;
      _quizFinished = false;
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'SECURITY ACADEMY',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5CF6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Threat Training Lab',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quiz Frame vs Finished View
                  if (!_quizFinished)
                    _buildQuizFrame()
                  else
                    _buildQuizFinishedView(),

                  const SizedBox(height: 32),

                  // Leaderboard section
                  Text(
                    'Global Leaderboard',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Leaderboard list
                  _buildLeaderboardList(appState),
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

  Widget _buildQuizFrame() {
    final question = _fallbackQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / _fallbackQuestions.length;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${_fallbackQuestions.length}',
                style: GoogleFonts.outfit(color: const Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Score: $_score',
                style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.04),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Question Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Text(
              question['content'],
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...List.generate(question['options'].length, (index) {
            final isSelected = _selectedAnswerIndex == index;
            final isCorrect = index == question['correct_index'];
            Color optionColor = Colors.white.withOpacity(0.06);
            Color textColor = Colors.white;
            BorderSide border = BorderSide(color: Colors.white.withOpacity(0.04));

            if (_selectedAnswerIndex != null) {
              if (isCorrect) {
                optionColor = const Color(0xFF10B981).withOpacity(0.08);
                textColor = const Color(0xFF10B981);
                border = const BorderSide(color: Color(0xFF10B981));
              } else if (isSelected) {
                optionColor = const Color(0xFFEF4444).withOpacity(0.08);
                textColor = const Color(0xFFEF4444);
                border = const BorderSide(color: Color(0xFFEF4444));
              }
            } else if (isSelected) {
              border = const BorderSide(color: Color(0xFF8B5CF6));
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _answerQuestion(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: optionColor,
                    border: Border.fromBorderSide(border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        question['options'][index],
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (_selectedAnswerIndex != null)
                        Text(
                          isCorrect ? '✅' : (isSelected ? '❌' : ''),
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation / Next Button
          if (_selectedAnswerIndex != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question['explanation'],
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF4FACFE)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _currentIndex < _fallbackQuestions.length - 1 ? 'Next Question →' : 'Finish Lab 🏁',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF040508),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizFinishedView() {
    final pct = (_score / _fallbackQuestions.length * 100).round();
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🎉', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Lab Completed!',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'You scored $_score / ${_fallbackQuestions.length} ($pct%)',
              style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF8B5CF6)),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'Retake Practice Lab',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(AppState appState) {
    if (appState.leaderboard.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF120828).withOpacity(0.4),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Leaderboard updates sync dynamically.',
            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(appState.leaderboard.length, (index) {
        final score = appState.leaderboard[index];
        final rank = index + 1;
        String medal = '';
        if (rank == 1) medal = '🥇';
        if (rank == 2) medal = '🥈';
        if (rank == 3) medal = '🥉';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF120828).withOpacity(0.5),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: medal.isNotEmpty
                    ? Text(medal, style: const TextStyle(fontSize: 18))
                    : Text(
                        '#$rank',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  score.username,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${score.score} / ${score.total}',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
