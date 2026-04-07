# ACTORA - PRODUCT SPEC (FINAL)

## 1. PRODUCT OVERVIEW

Actora is not a reminder app.
Actora is not a productivity tool.
Actora is not a habit tracker.

**Actora is an execution engine.**

It eliminates hesitation and forces action through a single-task system.

---

## 2. CORE PRINCIPLE

> One day -> One task -> One action -> One streak

No lists.
No planning.
No complexity.

---

## 3. CORE SYSTEMS

---

### 3.1 Execution Loop

User flow:

1. Open app
2. See one task
3. Tap "Start"
4. Complete task
5. Build streak
6. Return next day

---

### 3.2 Task System

#### Task States

```text
idle -> inProgress -> completed
idle -> deferred
idle -> cannotDo
```

Rules:

- One task is active at a time.
- Completed task is not restored on app reopen.
- Only idle and inProgress tasks are restorable.
- Same-day duplicate completion does not increment streak again.

---

### 3.3 Dynamic Psychology System

Done-state copy changes by streak:

- Day 0:
	- "Bugün yaptın."
	- "Yarın devam et."
- Day 1-2:
	- "Bitti."
	- "Yarın gelmezsen sıfırlanır."
- Day 3+:
	- "Bitti."
	- "Çoğu kişi burada bırakır."

System intent:

- Avoid dead-end feeling.
- Keep next action pressure alive.
- Reinforce identity through progression.

---

### 3.4 Hook Moment (First Completion)

Trigger:

- Runs after first successful completion.

Copy:

- "Most people stop here."
- "You didn't."

CTA:

- Continue

---

### 3.5 Return Pressure

Return nudge copy:

- "Zaten başladın. Bitir."

Post-complete pressure:

- "Yarın gelmezsen sıfırlanır."

Visibility rule:

- Pressure line is emphasized for streak > 2.

---

### 3.6 Failure System (Cannot Do)

If user cannot do task:

- With freeze/premium: streak is protected.
- Without freeze: streak resets.

Loss copy:

- Title: "Bitti." / "Over."
- Body: "X gün. Gitti." / "X days. Gone."

---

### 3.7 Session Loop (Done State)

Done-state actions:

- 🔁 Bir tane daha
- ⏳ Yarın devam
- 🚀 Paylaş

Primary action:

- Bir tane daha

---

### 3.8 Share System

Share card:

- Day X
- Still going.
- Most people stopped.
- Actora

Share text:

- Day X.
- Still going.
- Most people stopped.
- Actora

After-done share nudge (streak >= 3):

- "Bitti."
- "Çoğu kişi burada bırakır."
- [Paylaş] [Devam et]

---

### 3.9 Task Evolution

Difficulty progression:

- Day 1-3: very easy
- Day 4-7: discipline
- Day 8-15: focus
- Day 15+: hard

Task generation notes:

- Follow-up task keeps friction low.
- Title repetition is reduced with deterministic cycling.

---

## 4. UX RULES

- Single visible task
- Single clear primary action
- Large primary button
- Minimal copy
- Fast transitions
- Haptic feedback on key interactions

Header progression tone:

- Day 1: "Başladın."
- Day 3: "Bırakanlar burada bırakır."
- Day 7: "Artık geri dönüş yok."

Risk badge copy:

- "Bugün kaçırırsan sıfırlanır."

---

## 5. STATE SAFETY

- Onboarding shown once.
- Selected focus/duration persist.
- Task state persists across restarts.
- Invalid saved task payload is ignored safely.
- Null-task complete/start transitions do not crash.

---

## 6. ANALYTICS (ACTIVE)

Tracked events:

- task_started
- task_completed
- cannot_do
- share_clicked
- app_open_day_2

---

## 7. PAYWALL STATUS

- Paywall is disabled in current MVP flow.
- Freeze/premium data structures may exist in state.
- Active sales/paywall screen is out of launch scope.

---

## 8. LAUNCH-READY DEFINITION

Actora is launch-ready when:

- Core loop works without regression.
- Dynamic psychology, hook, loss, return pressure, and share flows are stable.
- flutter test passes.
- flutter analyze lib returns clean.
- Manual QA checklist is green on real device.

# 🚀 ACTORA – FULL PRODUCT SPEC (PRODUCTION READY)

---

## 1. PRODUCT OVERVIEW

Actora is not a reminder app.  
Actora is not a productivity tool.  
Actora is not a habit tracker.

**Actora is an execution engine.**

It removes hesitation and forces action through a single-task system.

---

## 2. CORE PRINCIPLE

> One day → One task → One action → One streak

No lists.  
No planning.  
No complexity.  

Only execution.

---

## 3. CORE SYSTEMS

---

### 3.1 Execution Loop

1. Open app  
2. See ONE task  
3. Tap Start  
4. Complete  
5. Build streak  
6. Return tomorrow  

---

### 3.2 Task System

#### Task States

idle → inProgress → completed  
idle → deferred  
idle → cannotDo  

---

### Rules (CRITICAL)

- Only ONE task per day
- No new task after completion
- No new task after defer
- No new task after cannotDo

---

### Daily Guard

IF todayCompleted == true  
→ DO NOT create new task

---

## 4. STREAK SYSTEM

- +1 only once per day
- reset if missed day
- no double increment
- identity evolves with streak

---

### Identity Levels

Day 1 → Started  
Day 3 → Most people quit here  
Day 7 → You don’t quit anymore  
Day 14 → You’re in control  

---

## 5. UX STRUCTURE

---

### 5.1 Launch

Stop.  
Start.

---

### 5.2 Onboarding

- Focus selection
- Duration selection
- Commitment trigger

---

### 5.3 Today Screen

- Streak header
- Weekly progress
- Single task card
- Primary CTA (Start / Done)
- Secondary:
  - Later
  - Can't do

---

## 6. FOCUS MODE

Full screen  
Timer  
No distraction  

Display:

01:42  
Task name  

---

## 7. DONE FLOW (CRITICAL)

Bitti.  

Çoğu kişi burada bırakır.  

[ Paylaş ]  
[ Yarın devam ]  

---

### Rules

- No new task
- Minimum 3s display
- Must create pressure

---

## 8. SHARE SYSTEM (VIRAL)

Trigger:

onTaskCompleted → showShare()

---

### Share Copy

Day 4  

Still going.  

Most people quit already.  

Actora  

---

## 9. LOSS SYSTEM

Trigger:

- cannotDo
- missed day

---

### UI

Seri bozuldu.  

X gündür yapıyordun.  

---

## 10. DEFER SYSTEM

onDefer():

- clear task
- mark day inactive

---

### UI

Bugün pas geçtin.  
Yarın tekrar dene.  

---

## 11. PERSISTENCE RULES

- completed task NEVER restored
- only today + active task loads

---

## 12. ANALYTICS

Events:

- task_started  
- task_completed  
- task_deferred  
- task_cannot_do  
- share_opened  
- share_clicked  

---

## 13. DEBUG SYSTEM

- Shake → debug panel
- Auto test runner
- Fail overlay

---

## 14. CRITICAL RULES

MUST:
- single task per day
- no duplicate tasks
- clear state after completion

MUST NOT:
- multi task system
- list UI
- complex flows

---

## 15. PSYCHOLOGY ENGINE

Triggers:

- loss aversion  
- identity shift  
- social pressure  
- completion reward  

---

## 16. FINAL EXPERIENCE

User should feel:

- pressure  
- clarity  
- no escape  
- no confusion  

---

## 17. SUMMARY

Actora is not optional.

You either act  
or you break the streak.

---

# 🚀 ACTORA – GROWTH ENGINE (VIRAL + RETENTION x2)

## 1. CORE GROWTH LOOP

Actora grows through a closed-loop system:

DO → FEEL → SHARE → RETURN → REPEAT

- DO → user completes task
- FEEL → identity reinforcement
- SHARE → social proof
- RETURN → streak pressure
- REPEAT → habit formation

---

## 2. VIRAL ENGINE

### 2.1 Share Trigger (CRITICAL)

Trigger:
- onTaskCompleted()

User MUST see share layer before exiting flow.

---

### 2.2 Share Flow

Bitti.

Çoğu kişi burada bırakır.

(1.5s delay)

[ Paylaş ]
[ Devam et ]

Rules:
- Cannot instantly dismiss
- Minimum visibility: 1.5 seconds
- Share must feel like continuation, not optional

---

### 2.3 Share Card Structure

Day X

Still going.

Most people quit already.

Actora

---

### 2.4 Share Psychology

User shares because:
- ego boost
- superiority signal
- identity broadcast

---

### 2.5 Share Amplifiers

Streak ≥ 3:

"Çoğu kişi 3. günde bırakır."

Streak ≥ 7:

"Bu seviyeye çok az kişi gelir."

---

### 2.6 Target Metrics

- Share Rate ≥ %20 → Viral
- Share Rate < %5 → Weak growth

---

## 3. RETENTION ENGINE

### 3.1 Core Mechanism

Streak is NOT a number.
Streak = identity + loss risk

---

### 3.2 Return Pressure

After completion:

"Yarın gelmezsen sıfırlanır."

---

### 3.3 Day-Based Messaging

Day 1 → Başladın  
Day 3 → Çoğu kişi burada bırakır  
Day 7 → Artık bırakan biri değilsin  
Day 14 → Kontrol sende  

---

### 3.4 App Open Hook

"Zaten başladın."  
"Bitir."

---

### 3.5 Missed Day Shock

Seri bozuldu.

X gündür yapıyordun.

---

## 4. ADDICTION ENGINE

### 4.1 Completion Reward

- Haptic feedback
- Micro animation
- Instant closure

---

### 4.2 Curiosity Loop

"Yarın daha zor."

---

### 4.3 Session Extension

"Bir tane daha?"

---

## 5. VIRAL + RETENTION INTERSECTION

DONE → SHARE → RETURN

---

### Scenario:

1. User completes task  
2. Sees: "Çoğu kişi burada bırakır"  
3. Shares result  
4. Returns next day to protect streak  

---

## 6. ANALYTICS FOR GROWTH

Track:

- task_completed
- share_opened
- share_clicked
- app_open_day_2
- streak_day_3
- streak_day_7

---

## 7. TARGET KPI

- D1 Retention ≥ %40
- D3 Retention ≥ %25
- Share Rate ≥ %15
- Completion Rate ≥ %60

---

## 8. CRITICAL RULES

MUST:
- show share after completion
- maintain daily single task
- enforce loss pressure

MUST NOT:
- remove pressure
- allow passive usage
- add multi-task complexity

---

## 9. FINAL OUTCOME

User does NOT just use the app.

User:
- builds identity
- shares progress
- fears loss
- returns daily

Actora becomes:
→ behavioral system
→ not a utility