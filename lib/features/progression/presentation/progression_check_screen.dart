import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import '../../../services/viral/friend_competition_service.dart';
import '../../share/presentation/share_invite_dialog.dart';

/// 🔒 PROGRESSION LOCK SCREEN
///
/// CRITICAL PSYCHOLOGICAL BARRIER:
/// User CANNOT progress to Day N unless they have at least 1 accepted invite.
///
/// PSYCHOLOGY:
/// 1. Soft Lock: Not aggressive, but unavoidable
/// 2. Clear Value: Show benefit of inviting
/// 3. FOMO: "Your friends are already ahead"
/// 4. Loss Aversion: "If you don't invite, you lose"
/// 5. Social Proof: "X friends already playing"
///
/// CONVERSION GOAL: 80%+ will invite to proceed
///
/// STATE FLOW:
/// - User completed Day N
/// - System checks: Has user invited at least 1 friend?
/// - If NO: Show this screen (cannot dismiss)
/// - If YES: Proceed to next day
///
/// CRITICAL: This is NOT a dialog. User MUST interact to proceed.
class ProgressionCheckScreen extends ConsumerStatefulWidget {
  const ProgressionCheckScreen({
    required this.dayNumber,
    required this.onProgressionUnlocked,
    this.friendName,
    this.friendsInNetwork = 0,
  });

  final int dayNumber;
  final VoidCallback onProgressionUnlocked;
  final String? friendName;
  final int friendsInNetwork;

  @override
  ConsumerState<ProgressionCheckScreen> createState() =>
      _ProgressionCheckScreenState();
}

class _ProgressionCheckScreenState extends ConsumerState<ProgressionCheckScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward(from: 0.3);

    AppLog.info(
      'ProgressionCheckScreen shown for Day ${widget.dayNumber}',
      category: 'progression_lock',
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleInvitePressed() async {
    try {
      AppLog.info(
        'User tapped INVITE from progression lock (Day ${widget.dayNumber})',
        category: 'progression_lock',
      );

      // Show share dialog
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ShareInviteDialog(
          onInviteSent: () => _checkProgressionUnlocked(),
        ),
      );
    } catch (e) {
      AppLog.error(
        'Error showing invite dialog from progression lock',
        error: e,
        category: 'progression_lock',
      );
    }
  }

  Future<void> _checkProgressionUnlocked() async {
    try {
      final competitionService = ref.read(friendCompetitionProvider);

      // Get all competitions (invited friends who accepted)
      final competitions = await competitionService.getActiveCompetitions();

      // Check if user has at least 1 accepted invite
      if (competitions.isNotEmpty) {
        AppLog.info(
          'Progression unlocked - User has ${competitions.length} competitions',
          category: 'progression_lock',
        );

        if (mounted) {
          // Show success animation
          await _showUnlockAnimation();
          widget.onProgressionUnlocked();
        }
      } else {
        AppLog.debug(
          'No competitions yet - need to wait for acceptance',
          category: 'progression_lock',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waiting for friend to accept invite...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      AppLog.error(
        'Error checking progression unlock',
        error: e,
        category: 'progression_lock',
      );
    }
  }

  Future<void> _showUnlockAnimation() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                parent: _scaleController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7C3AED),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration emoji
                  const Text(
                    '🔓',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),

                  // Unlock text
                  const Text(
                    'Day Unlocked!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sub text
                  const Text(
                    'Now compete with your friend!',
                    style: TextStyle(
                      color: Color(0xFFB0ADE2),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFFF006E)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '🎉 LET\'S GO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🔒 Lock icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF006E), Color(0xFFFF6B00)],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🔒',
                      style: TextStyle(fontSize: 56),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Main heading
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFFF006E)],
                  ).createShader(bounds),
                  child: const Text(
                    'Day Locked',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.black,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sub heading
                Text(
                  'Bring a friend to unlock Day ${widget.dayNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB0ADE2),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Psychology box: Why lock?
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Point 1: More fun with friends
                      _buildBenefit(
                        emoji: '👥',
                        title: 'More Fun',
                        description: 'Compete with friends, not alone',
                      ),

                      const SizedBox(height: 16),

                      // Point 2: Social proof
                      _buildBenefit(
                        emoji: '⚡',
                        title: 'Proven System',
                        description:
                            '${widget.friendsInNetwork}+ people already competing',
                      ),

                      const SizedBox(height: 16),

                      // Point 3: Stay accountable
                      _buildBenefit(
                        emoji: '🎯',
                        title: 'Stay Accountable',
                        description: 'Harder to quit when someone\'s watching',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Social proof: Friends already playing
                if (widget.friendsInNetwork > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '⚡',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${widget.friendsInNetwork} friends are already on Day ${widget.dayNumber}',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.friendsInNetwork > 0) const SizedBox(height: 40),

                // Loss aversion message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF006E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF006E).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        '⏰',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'If you don\'t invite today, your friend wins tomorrow',
                          style: TextStyle(
                            color: Color(0xFFFF006E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Primary CTA: Massive invite button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFFF006E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleInvitePressed,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '🚀 INVITE NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.black,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 8),
                            const Text(
                              'to Unlock',
                              style: TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Secondary CTA: Already invited? Check
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
                      onTap: _checkProgressionUnlocked,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Already invited? Check status',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB0ADE2),
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

  Widget _buildBenefit({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFB0ADE2),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
