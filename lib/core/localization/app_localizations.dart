import 'dart:ui';

import '../../features/onboarding/domain/onboarding_models.dart';

class AppLocalizations {
  AppLocalizations(String languageCode)
      : languageCode = languageCode.toLowerCase();

  factory AppLocalizations.ofLocale(Locale locale) {
    return AppLocalizations(locale.languageCode);
  }

  final String languageCode;

  bool get isTurkish => languageCode.startsWith('tr');

  String get stopWaiting => isTurkish ? 'Bekle.' : 'Wait.';

  String get startSplash => isTurkish ? 'Başla.' : 'Start.';

  String get youDontNeedMotivation => isTurkish ? 'Başla.' : 'Start.';

  String get youNeedAction => isTurkish ? 'Odak seç.' : 'Choose focus.';

  String get continueLabel => isTurkish ? 'Devam et' : 'Continue';

  String get startLabel => isTurkish ? 'Başla' : 'Start';

  String get backLabel => isTurkish ? 'Geri' : 'Back';

  String get chooseYourAction => isTurkish ? 'Hazırla.' : 'Set it up.';

  String get focusSection => isTurkish ? 'Odak seç' : 'Choose focus';

  String get durationSection => isTurkish ? 'Süre seç' : 'Set duration';

  String get youCameBackFinishIt =>
      isTurkish ? 'Zaten başladın. Bitir.' : 'You already started. Finish it.';

  String get todaysProofPrompt =>
      isTurkish ? 'Bugün neyi kanıtlayacaksın?' : 'What will you prove today?';

  String get continueShort => 'OK';

  String get streakSavedDontWasteIt =>
      isTurkish ? 'Seri korundu. Devam et.' : 'Saved. Keep going.';

  String get streakReset => isTurkish ? 'Seri bozuldu.' : 'The chain broke.';

  String get laterLabel => isTurkish ? 'Sonra' : 'Later';

  String get deferredToast => isTurkish
      ? 'Bugün pas geçtin. Yarın tekrar dene.'
      : 'Skipped today. Try again tomorrow.';

  String get cantDoLabel => isTurkish ? 'Yapamayacağım' : 'Can\'t do it';

  String get done => isTurkish ? 'Bitti.' : 'Done.';

  String get unfinishedPressurePrimary =>
      isTurkish ? 'Hazırlanıyor.' : 'Getting ready.';

  String get unfinishedPressureSecondary =>
      isTurkish ? 'Devam et.' : 'Keep going.';

  String get doneMomentLineTwo =>
      isTurkish ? 'Sen devam ettin.' : 'You kept going.';

  String get doneMomentLineThree =>
      isTurkish ? 'Bugünlük tamam.' : 'Done for today.';

  String get doOneMorePrompt =>
      isTurkish ? 'Devam etmek ister misin?' : 'Do you want to keep going?';

  String get oneMoreLabel => isTurkish ? 'Bir tane daha' : 'One more';

  String get continueTomorrowLabel => isTurkish ? 'Yarın' : 'Tomorrow';

  String doneIdlePrimary(int streak) {
    if (streak <= 0) {
      return isTurkish ? 'Bugün yaptın.' : 'You did it today.';
    }
    return isTurkish ? 'Bitti.' : 'Done.';
  }

  String doneIdleSecondary(int streak) {
    if (streak <= 0) {
      return isTurkish ? 'Yarın devam et.' : 'Continue tomorrow.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'Yarın gelmezsen sıfırlanır. Devam etmeyi unutma.'
          : 'If you miss tomorrow, it resets. Keep the momentum.';
    }
    return isTurkish
        ? 'Yarın gelmezsen sıfırlanır.'
        : 'If you miss tomorrow, it resets.';
  }

  String get publicCommitmentLine =>
      isTurkish ? 'Bunu 7 gün yapıyorum.' : "I'm doing this for 7 days.";

  String get hookMomentStepOne =>
      isTurkish ? 'Buraya kadar geldin.' : 'You made it this far.';

  String get hookMomentStepTwo => isTurkish
      ? 'Şimdi durursan, ritim bozulur.'
      : 'If you stop now, the rhythm breaks.';

  String socialPressureMessage(int streak) {
    if (streak >= 3 && streak <= 5) {
      return isTurkish
          ? '3. gün genelde kritik bir eşik olur.'
          : 'Day 3 is usually a critical point.';
    }
    return isTurkish ? 'Devam et.' : 'Keep going.';
  }

  String dynamicMessage(int streak) {
    if (streak >= 7) {
      return isTurkish ? 'İstikrar kuruldu.' : 'Consistency is established.';
    }
    if (streak >= 3) {
      return isTurkish ? 'İlerliyorsun.' : 'You are progressing.';
    }
    if (streak >= 2) {
      return isTurkish ? 'Devam et.' : 'Keep going.';
    }
    return isTurkish ? 'İyi başlangıç.' : 'Good start.';
  }

  String get returnPressureMessage => isTurkish
      ? 'Yarın yapmazsan sıfırlanır.'
      : 'If you miss tomorrow, it resets.';

  String returnPressureByStreak(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Yarın gelmezsen sıfırlanır. Ritmi koru.'
          : 'If you miss tomorrow, it resets. Keep the rhythm.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'Yarın gelmezsen sıfırlanır. Devam etmek iyi olur.'
          : 'If you miss tomorrow, it resets. Keep it moving.';
    }
    return returnPressureMessage;
  }

  String curiosityLoopMessage(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Yarın daha anlamlı.'
          : 'Tomorrow feels more meaningful.';
    }
    return isTurkish ? 'Yarın devam et.' : 'Keep going tomorrow.';
  }

  String get lossHeadline => isTurkish ? 'Seri bozuldu.' : 'Streak broken.';

  String lossBody(int previousStreak) {
    if (previousStreak <= 0) {
      return isTurkish ? 'Yeniden başla.' : 'Start again.';
    }
    if (isTurkish) {
      return '$previousStreak gün tamamlandı. Devam et.';
    }
    return '$previousStreak days completed. Keep going.';
  }

  String get shareLabel => isTurkish ? 'Paylaş' : 'Share';

  String get shareNudgeTitle => isTurkish ? 'Bitti.' : 'Done.';

  String get shareNudgeBody =>
      isTurkish ? 'Bugünlük tamam.' : 'Done for today.';

  String shareNudgeBodyByStreak(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Bu seviyeye gelmen iyi bir işaret.'
          : 'Reaching this level is a good sign.';
    }
    if (streak >= 3) {
      return isTurkish
          ? '3. gün önemli bir eşik.'
          : 'Day 3 is an important checkpoint.';
    }
    return shareNudgeBody;
  }

  String shareLineByStreak(int streak) {
    if (streak >= 3) {
      return isTurkish
          ? 'Devam eden taraftasın.'
          : 'You are on the continuing side.';
    }
    return isTurkish ? 'Bugün başladın.' : 'You started today.';
  }

  String get shareContinueLabel => isTurkish ? 'Devam et' : 'Continue';

  String get shareScreenDayLabel => isTurkish ? 'Gün' : 'Day';

  String get shareScreenStillGoing =>
      isTurkish ? 'Devam ediyorum.' : 'Still going.';

  String get shareStatementThirdLine =>
      isTurkish ? 'Bugünlük tamam.' : 'Done for today.';

  String get shareStatementFootnote =>
      isTurkish ? 'İstersen sen de deneyebilirsin.' : 'You can try it too.';

  String get shareScreenActora => 'Actora';

  String get challengeInviteLine => isTurkish
      ? 'Seni 7 gunluk bir denemeye davet ediyorum.'
      : 'I invite you to a 7-day challenge.';

  String challengeAggressiveLineByStreak(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Bu seviyeye geldin.\nDevam et.'
          : 'You reached this level.\nKeep going.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'İyi gidiyorsun.\nDevam ettin.'
          : 'You are doing well.\nYou kept going.';
    }
    return isTurkish
        ? 'Bugun basladim. Devam ediyorum.'
        : 'Started today. I am keeping going.';
  }

  String challengeQuestionByStreak(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Bu seviyede sen kac gun devam edersin?'
          : 'At this level, how long would you keep going?';
    }
    if (streak >= 3) {
      return isTurkish
          ? '3. gunden sonra sen kac gun devam edersin?'
          : 'After day 3, how long would you keep going?';
    }
    return isTurkish
        ? 'Sen kac gun devam edersin?'
        : 'How many days will you keep going?';
  }

  String get deepLinkChallengeTitle =>
      isTurkish ? 'Sana bir davet geldi.' : 'You got a challenge invite.';

  String get deepLinkChallengeBody =>
      isTurkish ? 'Devam etmek ister misin?' : 'Do you want to join?';

  String get acceptChallengeLabel => isTurkish ? 'Kabul Et' : 'Accept';

  String get declineChallengeLabel => isTurkish ? 'Vazgec' : 'Decline';

  String get tiktokPrompt =>
      isTurkish ? 'Bunu paylasmak ister misin?' : 'Want to share this?';

  String tiktokOverlay(int streak) {
    return 'Day $streak\nStill going.';
  }

  String get tiktokHint => isTurkish
      ? '10-15 sn video cek, metni ustune koy, TikTok/Reels\'e at.'
      : 'Record 10-15s, overlay the text, post to TikTok/Reels.';

  String get tiktokCta =>
      isTurkish ? 'TikTok/Reels metnini kopyala' : 'Copy TikTok/Reels overlay';

  String get socialPressureCounterLine => isTurkish
      ? 'Bugun tamamlananlar görünüyor.'
      : 'Completed today is shown here.';

  String socialPressureCounter(int count) {
    return isTurkish ? 'Bugün tamamlanan: $count' : 'Completed today: $count';
  }

  String pressurePercentByStreak(int streak) {
    if (streak >= 14) {
      return isTurkish ? 'Çok güçlü.' : 'Very strong.';
    }
    if (streak >= 7) {
      return isTurkish ? 'Harika seri.' : 'Strong streak.';
    }
    if (streak >= 5) {
      return isTurkish ? 'İyi ilerleme.' : 'Good progress.';
    }
    if (streak >= 3) {
      return isTurkish ? 'Bu nokta önemli.' : 'This is an important point.';
    }
    return isTurkish ? 'Basladin.' : 'You started.';
  }

  String leaderboardRankLabel(int rank) {
    return isTurkish ? 'Yerel siran #$rank' : 'Local rank #$rank';
  }

  String leaderboardTopStreakLabel(int streak) {
    return isTurkish
        ? 'Gunun en yuksek serisi: $streak gun'
        : 'Today\'s top streak: $streak days';
  }

  String friendStreakLabel({required String friendName, required int day}) {
    return isTurkish
        ? '$friendName ile seri yapiyorsun (Gun $day)'
        : 'You are on a streak with $friendName (Day $day)';
  }

  String get challengeFriendButton =>
      isTurkish ? 'Arkadasini davet et' : 'Invite a friend';

  String get referralRewardLine => isTurkish
      ? 'Arkadasin katilirsa +1 freeze kazanirsin.'
      : 'If a friend joins, you earn +1 freeze.';

  String get shareScreenCopied => isTurkish ? 'Kopyalandı.' : 'Copied.';

  String get shareScreenAutoCopied =>
      isTurkish ? 'Hazırlandı ve kopyalandı.' : 'Prepared and copied.';

  String get shareScreenPlatformLabel =>
      isTurkish ? 'Platform seç' : 'Choose platform';

  String get sharePlatformGeneral => isTurkish ? 'Genel' : 'General';

  String get sharePlatformX => 'X';

  String get sharePlatformInstagram => 'Instagram';

  String get sharePlatformWhatsApp => 'WhatsApp';

  String get sharePlatformLinkedIn => 'LinkedIn';

  String get sharePosterTagline =>
      isTurkish ? 'Bahane yok. Sadece icraat.' : 'No excuses. Just action.';

  String get sharePosterFooter =>
      isTurkish ? 'Bir gün değil, zincir.' : 'Not a day. A chain.';

  String get shareCopyButton => isTurkish ? 'Kopyala' : 'Copy';

  String get shareCopiedToast =>
      isTurkish ? 'Paylaşım metni kopyalandı.' : 'Share text copied.';

  String get comeBackTomorrow =>
      isTurkish ? 'Yarın gel.' : 'Come back tomorrow.';

  String get youreDoneForToday => isTurkish ? 'Bugün bitti.' : 'All done.';

  String get streakRiskLabel => isTurkish
      ? 'Bugün kaçırırsan sıfırlanır.'
      : 'If you miss today, it resets.';

  String weeklyProgressLabel(int completed, int goal) {
    return isTurkish ? '$completed/$goal tamamlandı' : '$completed/$goal done';
  }

  String identityLevelLabel(int streak) {
    if (streak >= 14) return 'Unstoppable';
    if (streak >= 7) return 'Locked in';
    if (streak >= 3) return 'Building';
    return 'Started';
  }

  String identityDoneMessage(int streak) {
    if (streak >= 14) {
      return isTurkish
          ? 'Bu ritim artık çok güçlü.'
          : 'This rhythm is very strong now.';
    }
    if (streak >= 7) {
      return isTurkish ? 'İstikrar kuruldu.' : 'Consistency is established.';
    }
    if (streak >= 3) {
      return isTurkish ? 'İlerliyorsun.' : 'You are progressing.';
    }
    return isTurkish ? 'Başladın.' : 'You started.';
  }

  String comeBackMessage(int streak) {
    if (streak >= 7) {
      return isTurkish ? 'Ritmi koru.' : 'Keep the rhythm.';
    }

    if (streak >= 3) {
      return isTurkish ? 'Devam et.' : 'Keep going.';
    }

    if (streak >= 1) {
      return isTurkish ? 'Devam et.' : 'Keep going.';
    }
    return comeBackTomorrow;
  }

  String minutesLabel(int value) {
    return isTurkish ? '$value dk' : '$value min';
  }

  String streakMood(int streak) {
    if (isTurkish) {
      if (streak >= 7) return 'İstikrar kuruldu.';
      if (streak >= 3) return 'İyi gidiyorsun.';
      if (streak >= 1) return 'Başladın.';
      return 'Yeni başlangıç';
    }

    if (streak >= 7) return 'Consistency is established.';
    if (streak >= 3) return 'You are doing well.';
    if (streak >= 1) return 'You started.';
    return 'Fresh start';
  }

  String userFocusLabel(UserFocus focus) {
    switch (focus) {
      case UserFocus.morning:
        return isTurkish ? 'Sabah' : 'Morning';
      case UserFocus.discipline:
        return isTurkish ? 'Disiplin' : 'Discipline';
      case UserFocus.focus:
        return isTurkish ? 'Odak' : 'Focus';
    }
  }

  String preferredDurationLabel(PreferredDuration duration) {
    switch (duration) {
      case PreferredDuration.twoMin:
        return isTurkish ? '2 dk' : '2 min';
      case PreferredDuration.fiveMin:
        return isTurkish ? '5 dk' : '5 min';
    }
  }

  List<String> firstTaskTitles(UserFocus focus) {
    switch (focus) {
      case UserFocus.morning:
        return isTurkish
            ? <String>['Su iç', 'Nefes al', 'Yazı yaz']
            : <String>['Drink water', 'Breathe', 'Write it'];
      case UserFocus.discipline:
        return isTurkish
            ? <String>['Masayı düzenle', 'Sessiz mod', 'Yazı yaz']
            : <String>['Clean desk', 'Silent mode', 'Write it'];
      case UserFocus.focus:
        return isTurkish
            ? <String>['Sessiz mod', 'Nefes al', 'Masayı düzenle']
            : <String>['Silent mode', 'Breathe', 'Clean desk'];
    }
  }
}
