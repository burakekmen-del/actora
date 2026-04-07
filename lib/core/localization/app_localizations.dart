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
