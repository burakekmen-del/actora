import '../../../core/localization/app_localizations.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../domain/task.dart';

class FirstTaskFactory {
  static Task create({
    required UserFocus focus,
    required PreferredDuration preferredDuration,
    required String languageCode,
    int streakDay = 1,
    bool followUp = false,
  }) {
    final l10n = AppLocalizations(languageCode);
    final titles =
        _evolvedTitles(l10n: l10n, focus: focus, streakDay: streakDay);
    final titleIndex = _titleIndex(
      streakDay: streakDay,
      followUp: followUp,
      length: titles.length,
    );
    final minutes = _estimatedMinutes(
      preferredDuration: preferredDuration,
      streakDay: streakDay,
      followUp: followUp,
    );

    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titles[titleIndex],
      status: TaskStatus.idle,
      createdAt: DateTime.now(),
      type: TaskType.focus,
      estimatedMinutes: minutes,
      isFirstTask: !followUp,
    );
  }

  static List<String> _evolvedTitles({
    required AppLocalizations l10n,
    required UserFocus focus,
    required int streakDay,
  }) {
    if (streakDay > 15) {
      return l10n.isTurkish
          ? <String>[
              '5 dk derin odak',
              'Tam sessizlikte odak',
              'Zor odak bloğu'
            ]
          : <String>[
              '5 min deep focus',
              'Full silence focus',
              'Hard focus block'
            ];
    }

    if (streakDay >= 8) {
      return l10n.isTurkish
          ? <String>[
              'Dikkat dağıtıcıları kapat',
              '3 dk odak',
              'Sessiz mod + odak'
            ]
          : <String>[
              'Turn off distractions',
              '3 min focus',
              'Silent mode + focus'
            ];
    }

    if (streakDay >= 4) {
      return l10n.isTurkish
          ? <String>['2 dk disiplin', 'Masayı düzenle', 'Dikkatini toparla']
          : <String>['2 min discipline', 'Reset your desk', 'Regain attention'];
    }

    return l10n.isTurkish
        ? <String>['1 dk başlat', 'Su iç', 'Kısa nefes']
        : <String>['1 min start', 'Drink water', 'Short breathing'];
  }

  static int _titleIndex({
    required int streakDay,
    required bool followUp,
    required int length,
  }) {
    final base = followUp ? streakDay + 1 : streakDay;
    return base % length;
  }

  static int _estimatedMinutes({
    required PreferredDuration preferredDuration,
    required int streakDay,
    required bool followUp,
  }) {
    if (followUp) {
      return 2;
    }
    if (streakDay > 15) {
      return preferredDuration.minutes < 5 ? 5 : preferredDuration.minutes;
    }
    if (streakDay >= 8) {
      return preferredDuration.minutes < 3 ? 3 : preferredDuration.minutes;
    }
    if (streakDay >= 4) {
      return preferredDuration.minutes < 2 ? 2 : preferredDuration.minutes;
    }
    return preferredDuration.minutes;
  }
}
