import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/logging/app_log.dart';
import '../../../services/analytics/analytics_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _copyCurrentText(auto: true, showToast: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final posterTheme = _posterTheme(widget.streak, l10n);
    final shareText = _shareText(l10n, widget.streak, _selectedPlatform);
    final headline = _shareHeadline(l10n, _selectedPlatform);

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
                      onSelected: (_) async {
                        setState(() {
                          _selectedPlatform = platform;
                        });
                        await _copyCurrentText(showToast: false);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Spacer(),
              RepaintBoundary(
                key: _posterKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: posterTheme.gradient,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: posterTheme.border),
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
                          posterTheme.badge,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: posterTheme.accent,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${l10n.shareScreenDayLabel} ${widget.streak}',
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
                          headline,
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
                            color: posterTheme.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.shareStatementThirdLine,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.shareScreenActora,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 1.2,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.shareStatementFootnote,
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
                onPressed: () async {
                  final analytics = ref.read(analyticsServiceProvider);
                  AppLog.action('share_screen.share_tapped', details: {
                    'streak': widget.streak,
                    'platform': _selectedPlatform.name,
                  });
                  await analytics.logShareClicked();
                  await _sharePosterImage(shareText: shareText);
                },
                child: Text(l10n.shareLabel),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isCopying ? null : () => _copyCurrentText(),
                child: Text(l10n.shareCopyButton),
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

  String _shareHeadline(AppLocalizations l10n, SharePlatform platform) {
    return l10n.shareScreenStillGoing;
  }

  String _shareText(
    AppLocalizations l10n,
    int streak,
    SharePlatform platform,
  ) {
    return '${_streakLabel(l10n, streak)}.\n${l10n.shareScreenStillGoing}\n\n${l10n.shareStatementThirdLine}\n\n${l10n.shareScreenActora}';
  }

  Future<void> _copyCurrentText(
      {bool auto = false, bool showToast = true}) async {
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
  }

  Future<void> _sharePosterImage({required String shareText}) async {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final bytes = await _capturePosterBytes();

    if (bytes == null) {
      await _copyCurrentText(showToast: true);
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Actora'),
      );
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

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shareCopiedToast)),
    );
  }

  Future<Uint8List?> _capturePosterBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final renderObject = _posterKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }

    final image = await renderObject.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return null;
    }
    return data.buffer.asUint8List();
  }

  String _streakLabel(AppLocalizations l10n, int streak) {
    return '${l10n.shareScreenDayLabel} $streak';
  }

  _PosterTheme _posterTheme(int streak, AppLocalizations l10n) {
    if (streak >= 14) {
      return _PosterTheme(
        badge: l10n.isTurkish ? 'DURDURULAMAZ' : 'UNSTOPPABLE',
        footer: l10n.isTurkish
            ? 'Zincir ürünün kendisi.'
            : 'The chain is the product.',
        accent: const Color(0xFFFF5C5C),
        border: const Color(0x33FF5C5C),
        gradient: const [Color(0xFF240606), Color(0xFF0C0C0C)],
      );
    }
    if (streak >= 7) {
      return _PosterTheme(
        badge: l10n.isTurkish ? 'KİLİTLENDİ' : 'LOCKED IN',
        footer: l10n.isTurkish
            ? 'Artık pazarlık yok.'
            : 'You are no longer negotiating.',
        accent: const Color(0xFFFFD166),
        border: const Color(0x33FFD166),
        gradient: const [Color(0xFF191919), Color(0xFF090909)],
      );
    }
    if (streak >= 3) {
      return _PosterTheme(
        badge: l10n.isTurkish ? 'İNŞA EDİLİYOR' : 'BUILDING',
        footer: l10n.isTurkish
            ? 'Momentum artık görünür.'
            : 'Momentum is visible now.',
        accent: const Color(0xFF8BE9FD),
        border: const Color(0x338BE9FD),
        gradient: const [Color(0xFF0D1420), Color(0xFF090909)],
      );
    }
    return _PosterTheme(
      badge: l10n.isTurkish ? 'BAŞLADI' : 'STARTED',
      footer: l10n.isTurkish
          ? 'İlk halka önemlidir.'
          : 'The first chain link matters.',
      accent: const Color(0xFFB4FF9F),
      border: const Color(0x33B4FF9F),
      gradient: const [Color(0xFF101512), Color(0xFF090909)],
    );
  }
}

class _PosterTheme {
  const _PosterTheme({
    required this.badge,
    required this.footer,
    required this.accent,
    required this.border,
    required this.gradient,
  });

  final String badge;
  final String footer;
  final Color accent;
  final Color border;
  final List<Color> gradient;
}
