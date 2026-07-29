import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

import 'onboarding_service.dart';

/// Starts [tourId]'s spotlight sequence over [keys] — unless it's
/// already been seen, or [force] (the drawer's "take the tour again")
/// overrides that. Shared by every screen with its own tour so the
/// "seen it once, never auto-show again, but replayable" rule can't
/// drift between them.
Future<void> maybeStartTour(
  BuildContext context, {
  required String tourId,
  required List<GlobalKey> keys,
  bool force = false,
}) async {
  if (!force && OnboardingService.hasSeenTour(tourId)) return;
  if (keys.isEmpty) return;
  ShowCaseWidget.of(context).startShowCase(keys);
  await OnboardingService.markTourSeen(tourId);
}
