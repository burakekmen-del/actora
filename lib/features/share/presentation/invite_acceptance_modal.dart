import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_log.dart';
import '../../../services/viral/invite_tracker_service.dart';
import '../domain/invite_challenge.dart';

/// 🔥 ULTRA-HIGH-CONVERSION Invite Acceptance Modal
///
/// Psychological triggers implemented:
/// 1. FOMO - "Others already accepted"
/// 2. Social Proof - "5 friends accepted"
/// 3. Time Pressure - "Offer expires in 5 min"
/// 4. Competition - "Beat their streak"
/// 5. Ego/Challenge - "Prove you can do it"
///
/// Target: 10% → 40%+ acceptance rate
class InviteAcceptanceModal extends ConsumerStatefulWidget {
  const InviteAcceptanceModal({
    required this.challenge,
    this.acceptanceCount = 5, // Social proof number
    this.onAccepted,
    this.onDismissed,
  });

  final InviteChallenge challenge;
  final int acceptanceCount;
  final VoidCallback? onAccepted;
  final VoidCallback? onDismissed;

  @override
  ConsumerState<InviteAcceptanceModal> createState() =>
      _InviteAcceptanceModalState();
}

class _InviteAcceptanceModalState extends ConsumerState<InviteAcceptanceModal>
    with TickerProviderStateMixin {
  bool _isAccepting = false;
  String? _error;
  late AnimationController _scaleController;
  late AnimationController _countdownController;
  int _remainingSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController.forward();

    // Countdown timer
    _countdownController = AnimationController(
      duration: const Duration(seconds: 300),
      vsync: this,
    );
    _countdownController.forward();

    // Update remaining time every second
    _countdownController.addListener(() {
      setState(() {
        _remainingSeconds = (300 * (1 - _countdownController.value)).toInt();
        if (_remainingSeconds <= 0) {
          _countdownController.stop();
        }
      });
    });

    AppLog.action('ui.invite_modal_shown_v2', details: {
      'invite_id': widget.challenge.inviteId,
      'sender': widget.challenge.senderLabel,
      'streak': widget.challenge.senderStreak,
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  Future<void> _acceptChallenge() async {
    setState(() => _isAccepting = true);

    try {
      final currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final inviteService = ref.read(inviteTrackerProvider);

      await inviteService.acceptInvite(
        inviteId: widget.challenge.inviteId,
        acceptedBy: currentUserId,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pending_challenge_invite',
        widget.challenge.inviteId,
      );
      await prefs.setString(
        'pending_challenge_sender_label',
        widget.challenge.senderLabel,
      );
      await prefs.setInt(
        'pending_challenge_sender_streak',
        widget.challenge.senderStreak,
      );

      AppLog.action('viral.invite_accepted_v2', details: {
        'invite_id': widget.challenge.inviteId,
        'acceptor_id': currentUserId,
      });

      if (mounted) {
        widget.onAccepted?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLog.error(
        'ui.invite_acceptance_failed',
        e,
        StackTrace.current,
      );

      if (mounted) {
        setState(() {
          _error = 'Davet kabul edilemedi. Tekrar dene.';
          _isAccepting = false;
        });
      }
    }
  }

  void _dismiss() {
    AppLog.action('ui.invite_modal_dismissed', details: {
      'invite_id': widget.challenge.inviteId,
      'reason': 'user_tapped_close',
    });
    widget.onDismissed?.call();
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {}, // Prevent dismiss on background tap
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.purple.shade600.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade600.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '🔥 Challenge Time!',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Main CTA Headline - BOLD, EMOTIONAL
                      Text(
                        '${challenge.senderLabel}\'nin ${challenge.senderStreak} Günlük\nÇizgisini Geç!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // FOMO Badge + Social Proof
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade900.withOpacity(0.3),
                              Colors.orange.shade900.withOpacity(0.2),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.red.shade600.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '⚡ ',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${widget.acceptanceCount} arkadaş zaten başladı',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Streak Comparison Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.blue.shade600.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // Visual Comparison
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '🔥 ${challenge.senderStreak} gün',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${challenge.senderLabel}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.arrow_forward_sharp,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '📍 0 gün',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Sen',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Onu 15 günde geçebilir misin?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Time Pressure Badge
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade900.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.orange.shade600.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '⏱️ ',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${_formatTime(_remainingSeconds)} içinde davet sona erecek',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error message
                      if (_error != null) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.shade700.withOpacity(0.4),
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // CTA Buttons
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            // PRIMARY: BAŞLA (Big, Bold, Gradient)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade600,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isAccepting
                                    ? [
                                        BoxShadow(
                                          color: Colors.purple.shade600
                                              .withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _isAccepting ? null : _acceptChallenge,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isAccepting
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        '✅ BAŞLA - Hadi Başla Koş!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // SECONDARY: Daha Sonra (Subtle dismiss)
                            TextButton(
                              onPressed: _isAccepting ? null : _dismiss,
                              child: Text(
                                'Belki 5 dak. sonra?',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
