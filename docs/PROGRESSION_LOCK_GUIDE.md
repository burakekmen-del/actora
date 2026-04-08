# 🔒 LOCKED PROGRESSION SYSTEM - COMPLETE INTEGRATION GUIDE

**Status:** Production-Ready  
**Date:** April 8, 2026  
**Version:** 1.0

---

## 📋 QUICK START

The locked progression system has 3 layers:

1. **ProgressionCheckScreen** - Modal shown when user tries Day N (forced invite)
2. **LossAversionScreen** - Emotional trigger when user falls behind
3. **ProgressionLockService** - Backend logic that enforces the lock

---

## 🎯 INTEGRATION POINTS

### Point 1: After Task Completion (main.dart or task_service.dart)

```dart
// After user completes daily task:

// 1. Show celebration screen (existing TaskCompletedScreen)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TaskCompletedScreen(
      dayNumber: 5,
      taskTitle: 'Morning Meditation',
      currentStreak: 5,
      friendName: 'Ali',
      friendStreak: 7,
      friendsWhoStarted: 3,
      onInvitePressed: () {
        // Goes to ShareInviteDialog
        showDialog(
          context: context,
          builder: (_) => ShareInviteDialog(
            onInviteSent: _refreshCompetitions,
          ),
        );
      },
    ),
  ),
);

// 2. Sync streak with all competitors
final progressionService = ref.read(progressionLockProvider);
await progressionService.syncStreakWithAllCompetitors(
  newStreak: 5,
  dayNumber: 5,
);
```

---

### Point 2: When User Tries to Progress to Next Day (home_screen.dart or similar)

```dart
// User taps "Continue to Day 6" button

Future<void> _handleProgressToNextDay() async {
  try {
    final progressionService = ref.read(progressionLockProvider);
    
    // CHECK: Can user progress?
    final status = await progressionService.getProgressionStatus(
      currentDay: 5,
      currentStreak: 5,
    );
    
    if (!status.canProgressToNextDay) {
      // ❌ LOCKED: Show progression lock screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProgressionCheckScreen(
            dayNumber: 6,
            friendsInNetwork: status.totalCompetitors,
            onProgressionUnlocked: () {
              // Proceed to Day 6
              _navigateToDay(6);
            },
          ),
        ),
      );
    } else {
      // ✅ UNLOCKED: Proceed to next day
      _navigateToDay(6);
    }
  } catch (e) {
    AppLog.error('Error checking progression', error: e);
    // Fail-safe: allow progression
    _navigateToDay(6);
  }
}

void _navigateToDay(int day) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DayScreen(dayNumber: day),
    ),
  );
}
```

---

### Point 3: Daily Check-in (triggers loss aversion)

```dart
// When user opens app the next day (home_screen.dart)

@override
void initState() {
  super.initState();
  _checkDailyStatus();
}

Future<void> _checkDailyStatus() async {
  try {
    final progressionService = ref.read(progressionLockProvider);
    
    final status = await progressionService.getProgressionStatus(
      currentDay: _currentDay,
      currentStreak: _currentStreak,
    );
    
    // ⚠️ If user is behind, show loss aversion before anything else
    if (status.shouldShowLossAversion && 
        status.topCompetitor != null &&
        !_hasShownLossAversionToday) {
      
      _hasShownLossAversionToday = true;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => LossAversionScreen(
          currentDay: _currentDay,
          currentStreak: _currentStreak,
          friendName: status.topCompetitor!['friendName'],
          friendDay: status.topCompetitor!['friendDay'],
          friendStreak: status.topCompetitor!['friendStreak'],
          onTaskContinue: () {
            Navigator.pop(context);
            // User commits to the task
            _startDailyTask();
          },
          onQuit: () {
            Navigator.pop(context);
            progressionService.recordProgressionQuit(
              dayNumber: _currentDay,
              streak: _currentStreak,
            );
            // Optional: show exit survey
          },
        ),
      );
    }
  } catch (e) {
    AppLog.error('Error checking daily status', error: e);
  }
}
```

---

## 🗂️ FIRESTORE SCHEMA UPDATES

### Users Collection

```json
{
  "userId": "user123",
  "email": "user@example.com",
  "currentDay": 5,
  "currentStreak": 5,
  "totalDaysCompleted": 12,
  "lastCompletedDay": "2026-04-08",
  "progressionUnlockedDays": [2, 3, 4, 5], // Days that required invite unlock
  "hasInvitedFriend": true, // For Day 2+ progression
  "createdAt": "2026-03-15",
}
```

### Progressions Collection (OPTIONAL - for analytics)

```json
{
  "progressionId": "prog_user123_day5",
  "userId": "user123",
  "day": 5,
  "streak": 5,
  "unlockedBy": "friend_accepted",
  "competitionId": "comp_user123_ali",
  "unlockedAt": "2026-04-08T14:23:00Z",
  "wasLocked": true,
  "timeLocked": 3600000, // milliseconds locked
  "showedLossAversion": false,
}
```

---

## 🔄 STATE MANAGEMENT (Riverpod)

Add this to your pubspec.yaml providers:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './services/progression/progression_lock_service.dart';
import './services/viral/friend_competition_service.dart';

// Provider for progression lock service
final progressionLockProvider = 
    FutureProvider<ProgressionLockService>((ref) async {
  
  // Get the competition service first
  final competitionService = ref.watch(friendCompetitionProvider);
  
  // Initialize with current user ID
  final userId = 'current_user_id'; // Get from auth
  
  return ProgressionLockService(
    userId: userId,
    competitionService: competitionService,
  );
});

// Alternative: If using AsyncValue for better error handling
final progressionStatusProvider = 
    FutureProvider.family<ProgressionStatus, Map<String, dynamic>>((ref, params) async {
  
  final progressionService = await ref.watch(progressionLockProvider.future);
  
  return progressionService.getProgressionStatus(
    currentDay: params['currentDay'],
    currentStreak: params['currentStreak'],
  );
});
```

---

## 📱 UI FLOW DIAGRAM

```
User Completes Day 5
    ↓
├─→ TaskCompletedScreen (celebration)
│    ↓
│    └─→ ShareInviteDialog (or skip)
│
└─→ [Invite sent OR skipped]
    
    [Next day - User opens app]
    ↓
    ├─→ Loss Aversion Check
    │    ├─→ If behind: LossAversionScreen
    │    │    ├─→ Continue task → Day 5 task
    │    │    └─→ Quit → Record exit
    │    │
    │    └─→ If not behind: Home screen
    │
    └─→ User taps "Continue to Day 6"
        ↓
        Progression Check
        ├─→ Has invite accepted? 
        │    ├─→ YES ✅ → Navigate to Day 6
        │    └─→ NO ❌ → ProgressionCheckScreen (forced invite)
        │         ↓
        │         User invites friend
        │         ↓
        │         Friend accepts (deep link)
        │         ↓
        │         Unlock animation
        │         ↓
        │         Proceed to Day 6
        │
```

---

## 🧪 TESTING CHECKLIST

### Unit Tests

- [ ] `test_progression_lock_service.dart`
  ```dart
  test('User cannot progress without 1+ accepted invites', () async {
    // Mock: 0 competitions
    final service = ProgressionLockService(...);
    final canProgress = await service.canProgressToNextDay(6);
    expect(canProgress, false);
  });

  test('User can progress with 1+ accepted invites', () async {
    // Mock: 1+ competitions
    final service = ProgressionLockService(...);
    final canProgress = await service.canProgressToNextDay(6);
    expect(canProgress, true);
  });

  test('Loss aversion triggers when user is 2+ days behind', () async {
    // Setup: user on day 3, friend on day 5
    final shouldShow = await service.shouldShowLossAversion(
      currentDay: 3,
      currentStreak: 3,
    );
    expect(shouldShow, true);
  });
  ```

### Manual Tests (QA)

- [ ] **Scenario 1: User without invites tries Day 2**
  - Expected: ProgressionCheckScreen shown
  - User cannot dismiss
  - Tapping INVITE shows ShareInviteDialog
  - After sending invite, "Check status" button visible

- [ ] **Scenario 2: User completes Day 3 far behind friend**
  - Expected: LossAversionScreen shown before home
  - Displays friend 2+ days ahead
  - Shows what will be lost (3-day streak)
  - Motivational copy

- [ ] **Scenario 3: User accepts Day 2 without inviting**
  - Expected: Cannot proceed to Day 3
  - ProgressionCheckScreen shown
  - Must invite to unlock

- [ ] **Scenario 4: Friend accepts invite**
  - Expected: Competition created
  - User can now progress
  - Notification sent?

---

## 📊 ANALYTICS EVENTS TO TRACK

```dart
// In your analytics service:

enum ProgressionEvent {
  // Locking events
  PROGRESSION_LOCKED,        // User hit lock (no invites)
  PROGRESSION_UNLOCK_INVITED, // User invited to unlock
  PROGRESSION_UNLOCK_SUCCESS, // Lock successfully removed
  PROGRESSION_QUIT,          // User quit instead of progressing
  
  // Loss aversion events
  LOSS_AVERSION_SHOWN,      // Loss aversion screen displayed
  LOSS_AVERSION_CONTINUED,  // User continued task after loss aversion
  LOSS_AVERSION_QUIT,       // User quit after loss aversion
  
  // Streak events
  STREAK_SYNCED,            // Streak updated with competitors
  STREAK_LOST,              // User's streak ended
}

// Example tracking:
AppLog.info(
  'Progression locked',
  category: 'progression_lock',
  extraData: {
    'event': 'PROGRESSION_LOCKED',
    'day': 6,
    'user_competitions': 0,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

---

## ⚡ PERFORMANCE OPTIMIZATION

### Caching Competitions

```dart
// In FriendCompetitionService, cache competitions for 5 minutes

class FriendCompetitionService {
  Map<String, dynamic>? _cachedCompetitions;
  DateTime? _cacheExpiry;
  
  static const Duration CACHE_DURATION = Duration(minutes: 5);
  
  Future<List<Map<String, dynamic>>> getActiveCompetitions() async {
    // Check cache first
    if (_cachedCompetitions != null && 
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedCompetitions!;
    }
    
    // Fetch fresh
    final competitions = await _fetchFromBackend();
    _cachedCompetitions = competitions;
    _cacheExpiry = DateTime.now().add(CACHE_DURATION);
    
    return competitions;
  }
  
  void invalidateCache() {
    _cachedCompetitions = null;
    _cacheExpiry = null;
  }
}
```

### Lazy Loading Loss Aversion

```dart
// Don't check loss aversion on every app open
// Only check once per day

class LossAversionManager {
  static const String CHECKED_TODAY_KEY = 'loss_aversion_checked_today';
  
  Future<bool> shouldCheckLossAversion() async {
    final prefs = await SharedPreferences.getInstance();
    final lastChecked = prefs.getString(CHECKED_TODAY_KEY);
    
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = lastChecked?.split('T')[0] ?? '';
    
    return today != lastDate;
  }
  
  Future<void> markAsChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      CHECKED_TODAY_KEY,
      DateTime.now().toIso8601String(),
    );
  }
}
```

---

## 🐛 TROUBLESHOOTING

### Problem: User can bypass lock

**Solution:** 
- Ensure Backend API validates invites before allowing progression
- Don't trust client-side `canProgressToNextDay` alone
- Server should check: `user.activeInvitations.count > 0` before progressionAPI/v1/progression/unlock

### Problem: Loss aversion shown too often

**Solution:**
- Add `_hasShownLossAversionToday` flag (SharedPreferences)
- Only check when opening app
- Prevent showing more than once per calendar day

### Problem: Competitions not syncing

**Solution:**
- Ensure `syncStreakWithAllCompetitors` called after EVERY task completion
- Check network connectivity before firing off updates
- Implement retry logic with exponential backoff

---

## 🚀 DEPLOYMENT PHASES

### Phase 1: Day 2 Unlock Requirement
- Users cannot reach Day 3 without inviting
- Softer enforcement (easier to implement)
- ~50% of users affected per day

### Phase 2: Loss Aversion System
- Triggers when 2+ days behind
- Emotional pressure, not blocking
- ~30% of users affected

### Phase 3: Full Progression Enforcement
- All days N > 1 require at least N-1 friends
- Compound incentive to keep inviting
- Network effect amplified

---

## 📚 RELATED DOCUMENTATION

- [VIRAL_SYSTEM_ARCHITECTURE.md](../VIRAL_SYSTEM_ARCHITECTURE.md) - Full system overview
- [INTEGRATION_GUIDE.md](../INTEGRATION_GUIDE.md) - All components integration
- [ProgressionLockService.dart](../../lib/services/progression/progression_lock_service.dart) - Service code
- [ProgressionCheckScreen.dart](../../lib/features/progression/presentation/progression_check_screen.dart) - Lock UI
- [LossAversionScreen.dart](../../lib/features/progression/presentation/loss_aversion_screen.dart) - Loss aversion UI

---

## ✅ IMPLEMENTATION CHECKLIST

- [ ] Create `/lib/features/progression/` directory
- [ ] Copy `ProgressionCheckScreen.dart` → `lib/features/progression/presentation/`
- [ ] Copy `LossAversionScreen.dart` → `lib/features/progression/presentation/`
- [ ] Copy `ProgressionLockService.dart` → `lib/services/progression/`
- [ ] Add Riverpod providers to main provider file
- [ ] Add integration points in `home_screen.dart` or task completion handler
- [ ] Update Firestore rules to validate invites server-side
- [ ] Add Cloud Function for progression check validation
- [ ] Setup analytics event tracking
- [ ] Test all scenarios
- [ ] Deploy Phase 1 (Day 2 unlock) to 10% test group
- [ ] Monitor K-factor, acceptance rate, retention
- [ ] Expand to 50%, then 100%

---

**Status:** Ready for implementation  
**Estimated Development Time:** 2-3 days (integration + testing)  
**Expected Impact:** 30-40% increase in share rate (forced invites)
