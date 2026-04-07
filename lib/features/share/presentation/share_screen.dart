import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/logging/app_log.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/firebase/firestore_service.dart';

enum SharePlatform { general, x, instagram, whatsapp, linkedin }

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key, required this.streak});

  final int streak;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final GlobalKey _posterKey = GlobalKey();

  SharePlatform _selectedPlatform = SharePlatform.x;
  bool _didAutoCopy = false;
  bool _isCopying = false;
  bool _actionsEnabled = false;
  bool _shareClicked = false;
  String _fromUserId = 'local';
  Timer? _activationTimer;

  @override
  void initState() {
    super.initState();
    AppLog.flow('share.screen', 'init_state', details: {
      'streak': widget.streak,
    });
    unawaited(ref.read(analyticsServiceProvider).logShareScreenShown());
    unawaited(_prepareViralContext());
    _activationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _actionsEnabled = true;
      });
      AppLog.verbose('share.screen.actions_enabled', details: {
        'streak': widget.streak,
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLog.flow('share.screen', 'auto_copy_triggered');
      _copyCurrentText(auto: true, showToast: false);
    });
  }

  Future<void> _prepareViralContext() async {
    final service = ref.read(firestoreServiceProvider);
    final userId = await service.getOrCreateLocalUserId();
    if (!mounted) {
      return;
    }
    setState(() {
      _fromUserId = userId;
    });
  }

  @override
  void dispose() {
    if (!_shareClicked) {
      unawaited(
          ref.read(analyticsServiceProvider).logShareClosedWithoutShare());
    }
    AppLog.flow('share.screen', 'dispose');
    _activationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final shareText = _shareText(l10n, widget.streak, _selectedPlatform);
    final aggressiveLine = l10n.challengeAggressiveLineByStreak(widget.streak);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final platform in SharePlatform.values)
                    ChoiceChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                      selected: _selectedPlatform == platform,
                      label: Text(_platformLabel(l10n, platform)),
                      onSelected: _actionsEnabled
                          ? (_) async {
                              setState(() {
                                _selectedPlatform = platform;
                              });
                              await _copyCurrentText(showToast: false);
                            }
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Spacer(),
              RepaintBoundary(
                key: _posterKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${l10n.shareScreenDayLabel.toUpperCase()} ${widget.streak}',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'MOST PEOPLE STOP HERE',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'YOU KEPT GOING',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 54,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'ACTORA',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                    height: 1.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          aggressiveLine,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.pressurePercentByStreak(widget.streak),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.challengeInviteLine,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                    letterSpacing: 0.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _actionsEnabled
                    ? () async {
                        final analytics = ref.read(analyticsServiceProvider);
                        _shareClicked = true;
                        AppLog.action('share_screen.share_tapped', details: {
                          'streak': widget.streak,
                          'platform': _selectedPlatform.name,
                        });
                        await analytics.logShareClicked();
                        await analytics.logChallengeSent(
                          streak: widget.streak,
                          fromUserId: _fromUserId,
                          dayIndex: widget.streak,
                        );
                        await ref
                            .read(firestoreServiceProvider)
                            .markChallengeInviteSent();
                        final snapshot = await ref
                            .read(firestoreServiceProvider)
                            .getViralSnapshot();
                        await analytics.logViralCoefficient(
                          value: snapshot.$3,
                          invites: snapshot.$1,
                          accepted: snapshot.$2,
                          streak: widget.streak,
                          dayIndex: widget.streak,
                        );
                        await _sharePosterImage(shareText: shareText);
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    : null,
                child: Text(l10n.shareLabel),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _actionsEnabled
                    ? () async {
                        final analytics = ref.read(analyticsServiceProvider);
                        final text = _shareText(
                          l10n,
                          widget.streak,
                          _selectedPlatform,
                        );
                        _shareClicked = true;
                        await analytics.logFriendLinkCreated(
                          streak: widget.streak,
                          dayIndex: widget.streak,
                        );
                        await analytics.logChallengeSent(
                          streak: widget.streak,
                          fromUserId: _fromUserId,
                          dayIndex: widget.streak,
                        );
                        await ref
                            .read(firestoreServiceProvider)
                            .markChallengeInviteSent();
                        await SharePlus.instance.share(
                          ShareParams(
                            text: text,
                            subject: 'Actora Challenge',
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    : null,
                child: Text(l10n.challengeFriendButton),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: !_actionsEnabled || _isCopying
                    ? null
                    : () async {
                        await _copyCurrentText();
                        if (!mounted) {
                          return;
                        }
                        setState(() {});
                      },
                child: Text(l10n.shareCopyButton),
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.tiktokPrompt,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.tiktokHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _actionsEnabled
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final overlayText =
                                    l10n.tiktokOverlay(widget.streak);
                                await Clipboard.setData(
                                  ClipboardData(text: overlayText),
                                );
                                if (!mounted) {
                                  return;
                                }
                                setState(() {});
                                messenger.showSnackBar(
                                  SnackBar(content: Text(l10n.tiktokCta)),
                                );
                              }
                            : null,
                        child: Text(l10n.tiktokCta),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _didAutoCopy
                    ? l10n.shareScreenAutoCopied
                    : l10n.shareScreenCopied,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.referralRewardLine,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _platformLabel(AppLocalizations l10n, SharePlatform platform) {
    switch (platform) {
      case SharePlatform.general:
        return l10n.sharePlatformGeneral;
      case SharePlatform.x:
        return l10n.sharePlatformX;
      case SharePlatform.instagram:
        return l10n.sharePlatformInstagram;
      case SharePlatform.whatsapp:
        return l10n.sharePlatformWhatsApp;
      case SharePlatform.linkedin:
        return l10n.sharePlatformLinkedIn;
    }
  }

  String _challengeLink() {
    return 'actora://actora/challenge?from=$_fromUserId&streak=${widget.streak}';
  }

  String _shareText(
    AppLocalizations l10n,
    int streak,
    SharePlatform platform,
  ) {
    return '$streak gundur yapiyorum.\n'
        '${l10n.challengeAggressiveLineByStreak(streak)}\n'
        '${l10n.challengeQuestionByStreak(streak)}\n'
        '${l10n.challengeInviteLine}\n'
        '${_challengeLink()}';
  }

  Future<void> _copyCurrentText(
      {bool auto = false, bool showToast = true}) async {
    AppLog.verbose('share.copy.begin', details: {
      'auto': auto,
      'show_toast': showToast,
      'platform': _selectedPlatform.name,
    });
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final text = _shareText(l10n, widget.streak, _selectedPlatform);
    if (mounted) {
      setState(() {
        _isCopying = true;
      });
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() {
      _didAutoCopy = auto;
      _isCopying = false;
    });
    if (showToast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareCopiedToast)),
      );
    }
    unawaited(ref.read(analyticsServiceProvider).logShareCopied());
    AppLog.verbose('share.copy.completed', details: {
      'auto': auto,
      'platform': _selectedPlatform.name,
    });
  }

  Future<void> _sharePosterImage({required String shareText}) async {
    AppLog.flow('share.poster', 'capture_begin', details: {
      'platform': _selectedPlatform.name,
      'streak': widget.streak,
    });
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await _capturePosterBytes();

    if (bytes == null) {
      AppLog.blocked('share.poster.capture', 'bytes_null', details: {
        'platform': _selectedPlatform.name,
      });
      await _copyCurrentText(showToast: true);
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Actora'),
      );
      AppLog.action('share.poster.shared_text_only', details: {
        'platform': _selectedPlatform.name,
      });
      return;
    }

    await _copyCurrentText(showToast: false);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'actora-share.png',
          ),
        ],
        text: shareText,
        subject: 'Actora',
      ),
    );
    AppLog.action('share.poster.shared_with_image', details: {
      'platform': _selectedPlatform.name,
      'bytes': bytes.length,
    });

    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.shareCopiedToast)),
    );
  }

  Future<Uint8List?> _capturePosterBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final renderObject = _posterKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      AppLog.blocked('share.poster.capture', 'boundary_missing');
      return null;
    }

    final image = await renderObject.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return null;
    }
    return data.buffer.asUint8List();
  }
}
