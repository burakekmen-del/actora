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

  String get unfinishedPressurePrimary => isTurkish ? 'Bitmedi.' : 'Not done.';

  String get unfinishedPressureSecondary => isTurkish ? 'Yap.' : 'Do it.';

  String get doneMomentLineTwo =>
      isTurkish ? 'Çoğu kişi burada bırakır.' : 'Most people stop here.';

  String get doneMomentLineThree =>
      isTurkish ? 'Sen bırakmadın.' : 'You didn\'t quit.';

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
          ? 'Yarın gelmezsen sıfırlanır. Çoğu kişi burada bırakır.'
          : 'If you miss tomorrow, it resets. Most people stop here.';
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
      ? 'Şimdi bırakırsan, diğerleri gibisin.'
      : 'If you stop now, you are like the others.';

  String socialPressureMessage(int streak) {
    if (streak >= 3 && streak <= 5) {
      return isTurkish
          ? 'Çoğu kişi 3. günde bırakır.'
          : 'Most people quit on day 3.';
    }
    return isTurkish ? 'Çoğu kişi burada bırakır.' : 'Most people stop here.';
  }

  String dynamicMessage(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Artık geri dönüş yok.'
          : 'There is no going back now.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'Sen bırakan biri değilsin.'
          : 'You are not someone who quits.';
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
          ? 'Yarın gelmezsen sıfırlanır. Artık geri dönüş yok.'
          : 'If you miss tomorrow, it resets. There is no going back now.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'Yarın gelmezsen sıfırlanır. Sen bırakan biri değilsin.'
          : 'If you miss tomorrow, it resets. You are not someone who quits.';
    }
    return returnPressureMessage;
  }

  String curiosityLoopMessage(int streak) {
    if (streak >= 7) {
      return isTurkish ? 'Yarın daha zor.' : 'Tomorrow gets harder.';
    }
    return isTurkish ? 'Yarın gerçek başlıyor.' : 'Tomorrow starts for real.';
  }

  String get lossHeadline => isTurkish ? 'Seri bozuldu.' : 'Streak broken.';

  String lossBody(int previousStreak) {
    if (previousStreak <= 0) {
      return isTurkish ? 'Tekrar başla.' : 'Start again.';
    }
    if (isTurkish) {
      return '$previousStreak gün. Gitti.';
    }
    return '$previousStreak days. Gone.';
  }

  String get shareLabel => isTurkish ? 'Paylaş' : 'Share';

  String get shareNudgeTitle => isTurkish ? 'Bitti.' : 'Done.';

  String get shareNudgeBody =>
      isTurkish ? 'Çoğu kişi burada bırakır.' : 'Most people stop here.';

  String shareNudgeBodyByStreak(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Bu seviyeye çok az kişi gelir.'
          : 'Very few people reach this level.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'Çoğu kişi 3. günde bırakır.'
          : 'Most people quit on day 3.';
    }
    return shareNudgeBody;
  }

  String shareLineByStreak(int streak) {
    if (streak >= 3) {
      return isTurkish
          ? 'Çoğu kişi başarısız olur. Sen olmadın.'
          : 'Most people fail. You didn\'t.';
    }
    return isTurkish ? 'Çoğu kişi bırakır.' : 'Most people quit.';
  }

  String get shareContinueLabel => isTurkish ? 'Devam et' : 'Continue';

  String get shareScreenDayLabel => isTurkish ? 'Gün' : 'Day';

  String get shareScreenStillGoing =>
      isTurkish ? 'Devam ediyorum.' : 'Still going.';

  String get shareStatementThirdLine =>
      isTurkish ? 'Çoğu kişi bırakır.' : 'Most people quit.';

  String get shareStatementFootnote => "You wouldn't get it.";

  String get shareScreenActora => 'Actora';

  String get challengeInviteLine => isTurkish
      ? 'Seni 7 gunluk bir denemeye davet ediyorum.'
      : 'I invite you to a 7-day challenge.';

  String challengeAggressiveLineByStreak(int streak) {
    if (streak >= 7) {
      return isTurkish
          ? 'Az kisi buraya gelir.\nBen geldim.'
          : 'Few people reach this point.\nI did.';
    }
    if (streak >= 3) {
      return isTurkish
          ? 'Cogu kisi burada durur.\nBen devam ettim.'
          : 'Most people stop here.\nI kept going.';
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
      ? 'Bugun 1,284 kisi gorevini tamamladi.'
      : '1,284 people finished today.';

  String socialPressureCounter(int count) {
    return isTurkish
        ? 'Bugun $count kisi gorevini tamamladi.'
        : '$count people completed today.';
  }

  String pressurePercentByStreak(int streak) {
    if (streak >= 14) {
      return isTurkish ? 'Elite.' : 'Elite.';
    }
    if (streak >= 7) {
      return isTurkish ? 'Top 10%.' : 'Top 10%.';
    }
    if (streak >= 5) {
      return isTurkish
          ? 'Sadece %31 buraya kadar geldi.'
          : 'Only 31% made it this far.';
    }
    if (streak >= 3) {
      return isTurkish ? 'Insanlarin %72si burada birakir.' : '72% quit here.';
    }
    return isTurkish ? 'Basladin.' : 'You started.';
  }

  String leaderboardRankLabel(int rank) {
    return isTurkish ? 'Bugun #$rank siradasin' : 'You are #$rank today';
  }

  String leaderboardTopStreakLabel(int streak) {
    return isTurkish
        ? 'En yuksek seri: $streak gun'
        : 'Top streak: $streak days';
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
          ? 'Artık geri dönüş yok.'
          : 'There is no going back now.';
    }
    if (streak >= 7) {
      return isTurkish
          ? 'Artık bırakan biri değilsin.'
          : 'You are no longer someone who quits.';
    }
    if (streak >= 3) {
      return isTurkish ? 'Çoğu kişi burada bırakır.' : 'Most people stop here.';
    }
    return isTurkish ? 'Başladın.' : 'You started.';
  }

  String comeBackMessage(int streak) {
    if (streak >= 7) {
      return isTurkish ? 'Kaybetme.' : 'Don\'t lose it.';
    }

    if (streak >= 3) {
      return isTurkish ? 'Zinciri koru.' : 'Protect the chain.';
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
      if (streak >= 7) return 'Artık geri dönüş yok.';
      if (streak >= 3) return 'Bırakanlar burada bırakır.';
      if (streak >= 1) return 'Başladın.';
      return 'Yeni başlangıç';
    }

    if (streak >= 7) return 'No going back now.';
    if (streak >= 3) return 'Most people stop here.';
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
