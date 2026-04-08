import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import '../../../services/viral/friend_competition_service.dart';

/// 😰 LOSS AVERSION TRIGGER SCREEN
///
/// PSYCHOLOGY: Loss Aversion (Kahneman & Tversky)
/// People feel loss 2x stronger than equivalent gain
///
/// TRIGGERS WHEN:
/// - User hasn't completed task for Day N
/// - System detects "inactive day"
/// - Friend just completed their streak
///
/// PSYCHOLOGICAL MESSAGING:
/// 1. Friend comparison: "Friend is on Day 7, you're on Day 5"
/// 2. What you lose: "You'll lose your 5-day streak"
/// 3. Relative status: "Friend will be AHEAD"
/// 4. FOMO: "Friend getting notifications about you falling behind"
/// 5. Sunk cost: "5 days wasted if you quit"
///
/// CONVERSION GOAL: 70%+ return to complete task
class LossAversionScreen extends ConsumerStatefulWidget {
  const LossAversionScreen({
    required this.currentDay,
    required this.currentStreak,
    required this.friendName,
    required this.friendDay,
    required this.friendStreak,
    required this.onTaskContinue,
    required this.onQuit,
  });

  final int currentDay;
  final int currentStreak;
  final String friendName;
  final int friendDay;
  final int friendStreak;
  final VoidCallback onTaskContinue;
  final VoidCallback onQuit;

  @override
  ConsumerState<LossAversionScreen> createState() =>
      _LossAversionScreenState();
}

class _LossAversionScreenState extends ConsumerState<LossAversionScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  int get _daysAhead => widget.friendDay - widget.currentDay;
  int get _streakLoss => widget.currentStreak;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    AppLog.info(
      'Loss aversion screen shown: Friend ${_daysAhead} days ahead',
      category: 'loss_aversion',
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleQuit() {
    AppLog.warning(
      'User attempting to quit - Loss aversion shown but skipped',
      category: 'loss_aversion',
    );

    // Show confirmation dialog (make it hard to quit)
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ Are you sure?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your $_streakLoss-day streak will be LOST',
                style: const TextStyle(
                  color: Color(0xFFFF006E),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.friendName} will be $_daysAhead days ahead forever',
                style: const TextStyle(
                  color: Color(0xFFB0ADE2),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF555555)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Stay',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF006E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onQuit();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Quit',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: ScaleTransition(
        scale: Tween<double>(begin: 0.90, end: 1.0).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 😰 Sad emoji
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: const Text(
                    '😰',
                    style: TextStyle(fontSize: 80),
                  ),
                ),

                const SizedBox(height: 28),

                // Main headline
                const ShaderMask(
                  shaderCallback: LinearGradient(
                    colors: [Color(0xFFFF006E), Color(0xFFFF6B00)],
                  ).createShader,
                  child: Text(
                    'You\'re Falling Behind',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.black,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // Sub headline
                Text(
                  'Complete today\'s task to stay in the game',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB0ADE2),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 🔴 CRITICAL: Streak comparison box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF006E).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF006E).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // You vs Friend header
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📍 YOU',
                            style: TextStyle(
                              color: Color(0xFFB0ADE2),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'GAP',
                            style: TextStyle(
                              color: Color(0xFFFF006E),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'FRIEND 🔥',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Streak numbers - MASSIVE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${widget.currentStreak}d',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.black,
                                  color: Color(0xFFB0ADE2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Day ${widget.currentDay}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // GAP indicator - PULSING RED
                          Column(
                            children: [
                              const Text(
                                '⬇️',
                                style: TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '-$_daysAhead',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.black,
                                  color: Color(0xFFFF006E),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${widget.friendStreak}d',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.black,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Day ${widget.friendDay}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Friend name
                      Text(
                        '${widget.friendName} is $_daysAhead days ahead',
                        style: const TextStyle(
                          color: Color(0xFFFF006E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Loss messaging - WHAT WILL BE LOST
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF006E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF006E).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ If you quit today:',
                        style: TextStyle(
                          color: Color(0xFFFF006E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLossItem(
                        emoji: '💥',
                        loss: 'Your $_streakLoss-day streak ENDS',
                        impact: 'Back to Day 1',
                      ),
                      const SizedBox(height: 12),
                      _buildLossItem(
                        emoji: '📉',
                        loss: '${widget.friendName} moves to Day ${widget.friendDay + 1}',
                        impact: 'Gap grows to $_daysAhead+ days',
                      ),
                      const SizedBox(height: 12),
                      _buildLossItem(
                        emoji: '🚀',
                        loss: 'Friend reaches day 30 while you\'re stuck',
                        impact: 'They\'ll always be ahead',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Motivational message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '💪 You can do this',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You\'ve already made it $_streakLoss days. Just 1 more day to extend your streak.',
                        style: TextStyle(
                          color: Color(0xFFB0ADE2),
                          fontSize: 13,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // PRIMARY CTA: Continue task
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF00D4FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTaskContinue,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          '💪 Do Today\'s Task Now',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.black,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Secondary CTA: Maybe not today...
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF555555),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleQuit,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Maybe later...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLossItem({
    required String emoji,
    required String loss,
    required String impact,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loss,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                impact,
                style: const TextStyle(
                  color: Color(0xFFFF006E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
