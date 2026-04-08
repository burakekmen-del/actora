import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import 'share_invite_dialog.dart';

/// 🔥 TASK COMPLETED SCREEN - THE VIRAL TRIGGER
///
/// PSYCHOLOGY BREAKDOWN:
/// 1. Dopamine Hit: "You completed Day X" (achievement)
/// 2. Loss Aversion: Show friend who's AHEAD (comparison)
/// 3. FOMO: "They're already on Day Y" (urgency to catch up)
/// 4. Social Proof: "3 friends also started" (network effect)
/// 5. Ego/Dominance: "Can you beat them?" (competition)
/// 6. Sunk Cost: Streak progress visualization (invest more)
///
/// CONVERSION GOAL: 85%+ transition to invite screen
///
/// COPY TONE: Provocative, slightly aggressive, ego-driven
/// COLORS: High contrast - purple/red gradient (dominance)
/// ANIMATIONS: Celebratory bounce, then shift to competition
class TaskCompletedScreen extends ConsumerStatefulWidget {
  const TaskCompletedScreen({
    required this.dayNumber,
    required this.taskTitle,
    required this.currentStreak,
    this.friendName = 'Your friend',
    this.friendStreak = 0,
    this.friendsWhoStarted = 0,
    this.onInvitePressed,
    this.onContinuePressed,
  });

  final int dayNumber;
  final String taskTitle;
  final int currentStreak;
  final String friendName;
  final int friendStreak;
  final int friendsWhoStarted;
  final VoidCallback? onInvitePressed;
  final VoidCallback? onContinuePressed;

  @override
  ConsumerState<TaskCompletedScreen> createState() =>
      _TaskCompletedScreenState();
}

class _TaskCompletedScreenState extends ConsumerState<TaskCompletedScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _competitionController;
  bool _showCompetition = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _competitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Celebration first (500ms), then show competition
    _celebrationController.forward().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() => _showCompetition = true);
            _competitionController.forward();
          }
        });
      }
    });

    AppLog.action('ui.task_completed_screen_shown', details: {
      'day_number': widget.dayNumber,
      'streak': widget.currentStreak,
      'friend_name': widget.friendName,
      'is_ahead': widget.friendStreak > widget.currentStreak,
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _competitionController.dispose();
    super.dispose();
  }

  Future<void> _handleInvitePressed() async {
    AppLog.action('ui.task_completed_invite_tapped', details: {
      'day_number': widget.dayNumber,
      'conversion_point': 'task_complete_cta',
    });

    widget.onInvitePressed?.call();

    // Show share dialog
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ShareInviteDialog(
        senderLabel: 'You',
        streak: widget.currentStreak,
        userId: 'current_user_placeholder',
        onShareComplete: () {
          widget.onContinuePressed?.call();
        },
      ),
    );
  }

  void _handleSkip() {
    AppLog.action('ui.task_completed_skip_tapped', details: {
      'day_number': widget.dayNumber,
      'skipped_invite': true,
    });
    widget.onContinuePressed?.call();
  }

  String _getStreakEmoji(int streak) {
    if (streak == 0) return '📍';
    if (streak < 3) return '💪';
    if (streak < 7) return '🔥';
    return '⭐';
  }

  String _getComparisonText() {
    final difference = widget.friendStreak - widget.currentStreak;
    if (difference == 0) return 'You\'re equal 🤝';
    if (difference > 0) {
      return '${widget.friendName} is ${difference}d ahead 🎯';
    } else {
      return 'You\'re ahead by ${-difference}d! 👑';
    }
  }

  String _getMotivationCopy() {
    if (widget.friendStreak > widget.currentStreak) {
      return 'Time to show them what you\'re made of.';
    } else if (widget.friendStreak == widget.currentStreak) {
      return 'Let\'s see who can go further.';
    } else {
      return 'But can you maintain it?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _competitionController, curve: Curves.easeOut),
    );

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _competitionController, curve: Curves.easeIn),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Celebration Section
            ScaleTransition(
              scale: scaleAnimation,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Confetti emoji
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        '✅ 🎉 ✅',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),

                    // Achievement text
                    Text(
                      'Day ${widget.dayNumber} Complete!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Task title
                    Text(
                      widget.taskTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Streak badge
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade700,
                            Colors.red.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade700.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStreakEmoji(widget.currentStreak),
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.currentStreak} day streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Competition Section (slides in after celebration)
            if (_showCompetition)
              SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Friend Comparison Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            border: Border.all(
                              color: Colors.blue.shade600.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Comparison Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Friend side
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_getStreakEmoji(widget.friendStreak)} ${widget.friendStreak}d',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.friendName,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // VS Badge
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade700,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Text(
                                      '⚡',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),

                                  // You side
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_getStreakEmoji(widget.currentStreak)} ${widget.currentStreak}d',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'You',
                                        style: TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Comparison text
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade900.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  _getComparisonText(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.cyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Motivation text
                              Text(
                                _getMotivationCopy(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Social proof
                        if (widget.friendsWhoStarted > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '⚡ ${widget.friendsWhoStarted} friends already started',
                              style: TextStyle(
                                color: Colors.amber.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                        // CTA Buttons
                        Column(
                          children: [
                            // PRIMARY CTA: INVITE NOW
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade600,
                                    Colors.red.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.purple.shade600.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleInvitePressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  '🚀 INVITE SOMEONE NOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // SECONDARY: Skip (weak button)
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _handleSkip,
                                child: Text(
                                  'Maybe later',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
