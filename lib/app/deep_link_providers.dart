import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/share/domain/invite_challenge.dart';

/// Stores pending invite from deep link
final pendingInviteChallengeProvider =
    StateProvider<InviteChallenge?>((ref) => null);

/// Marks that invite modal should be shown
final showInviteModalProvider = StateProvider<bool>((ref) => false);
