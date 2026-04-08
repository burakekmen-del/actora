import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_log.dart';
import '../../../services/viral/invite_tracker_service.dart';

/// 🔥 ULTRA-HIGH-CONVERSION Share Invite Dialog
///
/// Psychology drivers:
/// - FOMO: "Arkadaş bırakma, hepsi başladı"
/// - Competition: "Seni de çeker misin?" (challenge tone)
/// - Social Proof: "X arkadaş zaten başladı"
/// - Ego: "Strekinizi birlikte büyütün" (co-creation feeling)
/// - Urgency: "Davet X dakikada geçerli" (time pressure)
class ShareInviteDialog extends ConsumerStatefulWidget {
  const ShareInviteDialog({
    required this.senderLabel,
    required this.streak,
    required this.userId,
    this.onShareComplete,
  });

  final String senderLabel;
  final int streak;
  final String userId;
  final VoidCallback? onShareComplete;

  @override
  ConsumerState<ShareInviteDialog> createState() => _ShareInviteDialogState();
}

class _ShareInviteDialogState extends ConsumerState<ShareInviteDialog> {
  ShareableInvite? _invite;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareInvite();
  }

  Future<void> _prepareInvite() async {
    try {
      final trackerService = ref.read(inviteTrackerProvider);
      final invite = await trackerService.prepareShareInvite(
        senderId: widget.userId,
        senderLabel: widget.senderLabel,
        streak: widget.streak,
        dayIndex: 1,
      );

      AppLog.action('ui.share_dialog_opened', details: {
        'invite_id': invite.inviteId,
      });

      if (mounted) {
        setState(() {
          _invite = invite;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLog.error(
        'ui.share_dialog_prepare_failed',
        e,
        StackTrace.current,
      );
      if (mounted) {
        setState(() {
          _error = 'Davet hazırlanamadı: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareVia(String channel) async {
    if (_invite == null) return;

    try {
      // Track share action
      final trackerService = ref.read(inviteTrackerProvider);
      await trackerService.trackShareAction(
        inviteId: _invite!.inviteId,
        userId: widget.userId,
        channel: channel,
      );

      AppLog.action('viral.share_initiated', details: {
        'invite_id': _invite!.inviteId,
        'channel': channel,
      });

      // Share based on channel
      String text = '';
      switch (channel) {
        case 'whatsapp':
          text = _invite!.whatsappShare;
          await Share.share(
            text,
            subject: 'Actora Davet',
          );
          break;

        case 'sms':
          text = _invite!.smsShare;
          await Share.share(
            text,
            subject: 'Actora Davet',
          );
          break;

        case 'copy_link':
          text = _invite!.copyLinkShare;
          await Clipboard.setData(ClipboardData(text: text));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link kopyalandı! 📋'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${widget.senderLabel}\'ı davet ettin! Seri sende başladı 🚀',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );

        AppLog.action('viral.share_completed', details: {
          'invite_id': _invite!.inviteId,
          'channel': channel,
        });

        widget.onShareComplete?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      AppLog.error(
        'ui.share_failed',
        e,
        StackTrace.current,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hazırlanıyor')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _invite == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Davetiye')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Hata oluştu'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Davet Et'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main CTA - High-Conversion Headline
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade700,
                      Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade700.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // FOMO Badge
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: const Text(
                        '⚡ 4 arkadaş başladı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Main Headline - Competition + Ego
                    const Text(
                      '🚀 Strekinizi\nBirlikte Büyütün!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subheadline - Challenge tone
                    Text(
                      '${widget.senderLabel}\'in ${widget.streak} günlük çizgisine karşı koy, sen daha efsane olabilir misin?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time Pressure Badge
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: const Text(
                        '⏱️ Davet 5 dakikada kapanacak',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Share channels title
              const Text(
                '🎯 Nasıl Davet Etmek İstersin?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              // Share Channel Buttons - High Contrast
              _ShareOptionButton(
                icon: '💬',
                title: 'WhatsApp\'ta Gönder',
                subtitle: 'Çincede 43 kişi zaten başladı',
                tagline: 'En hızlısı',
                tagColor: Colors.green,
                onTap: () => _shareVia('whatsapp'),
              ),
              const SizedBox(height: 12),

              _ShareOptionButton(
                icon: '📱',
                title: 'SMS ile Gönder',
                subtitle: 'Doğrudan cep telefonuna',
                tagline: 'Garantili',
                tagColor: Colors.blue,
                onTap: () => _shareVia('sms'),
              ),
              const SizedBox(height: 12),

              _ShareOptionButton(
                icon: '🔗',
                title: 'Linki Kopyala',
                subtitle: 'Panoya kopyala ve yapıştır',
                tagline: 'Diğer uygulamalar',
                tagColor: Colors.purple,
                onTap: () => _shareVia('copy_link'),
              ),
              const SizedBox(height: 24),

              // Social Proof + Urgency Box
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade50,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const Text(
                      '✨ Anında Bildirim Al',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B8B1B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Arkadaşın davetini kabul ettiği anda seni haberdar edeceğiz. Strekiniz birlikte büyüyecek! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOptionButton extends StatefulWidget {
  const _ShareOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.tagColor,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String tagline;
  final Color tagColor;
  final VoidCallback onTap;

  @override
  State<_ShareOptionButton> createState() => _ShareOptionButtonState();
}

class _ShareOptionButtonState extends State<_ShareOptionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.8 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: widget.tagColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              widget.tagline,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.tagColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Arrow
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.grey,
                    size: 16,
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
