enum UserFocus { morning, discipline, focus }

enum PreferredDuration { twoMin, fiveMin }

extension UserFocusX on UserFocus {
  String get label {
    switch (this) {
      case UserFocus.morning:
        return 'Morning';
      case UserFocus.discipline:
        return 'Discipline';
      case UserFocus.focus:
        return 'Focus';
    }
  }
}

extension PreferredDurationX on PreferredDuration {
  String get label {
    switch (this) {
      case PreferredDuration.twoMin:
        return '2 min';
      case PreferredDuration.fiveMin:
        return '5 min';
    }
  }

  int get minutes {
    switch (this) {
      case PreferredDuration.twoMin:
        return 2;
      case PreferredDuration.fiveMin:
        return 5;
    }
  }
}
