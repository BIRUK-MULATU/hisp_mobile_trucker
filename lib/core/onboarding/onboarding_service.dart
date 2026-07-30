import 'package:shared_preferences/shared_preferences.dart';

/// First-run gating for the onboarding carousel and every screen's own
/// interactive app tour. Loaded once at startup (see main.dart) so the
/// router's redirect — a synchronous function — can read
/// [hasSeenOnboarding] without an async round-trip. Deliberately plain
/// SharedPreferences, not the secure/session storage: these are
/// UI-state flags, not credentials, and must survive independently of
/// login/logout.
///
/// Each screen that has its own spotlight tour (Home, data entry,
/// Visualization, Settings…) owns a distinct [tourId] so it triggers
/// once per screen, on its own first visit, rather than one monolithic
/// tour trying to span separate routes/navigations.
class OnboardingService {
  OnboardingService._();

  static const _onboardingKey = 'has_seen_onboarding';
  static const _tourKeyPrefix = 'has_seen_tour_';

  /// Every screen-tour id in the app — kept in one place so
  /// [resetAllTours] (the drawer's "App Tour" replay) doesn't miss one.
  static const tourIds = [
    'home',
    'data_entry_routine',
    'data_entry_disease',
    'visualization',
  ];

  static bool hasSeenOnboarding = false;
  static final Set<String> _seenTours = {};

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    _seenTours
      ..clear()
      ..addAll([
        for (final id in tourIds)
          if (prefs.getBool('$_tourKeyPrefix$id') ?? false) id,
      ]);
  }

  static Future<void> markOnboardingSeen() async {
    hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static bool hasSeenTour(String id) => _seenTours.contains(id);

  static Future<void> markTourSeen(String id) async {
    _seenTours.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_tourKeyPrefix$id', true);
  }

  /// "Take the tour again" (Home drawer): clears every screen's tour
  /// flag. Home's own tour is re-triggered immediately by the caller;
  /// the others simply replay next time their screen is visited.
  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    _seenTours.clear();
    for (final id in tourIds) {
      await prefs.setBool('$_tourKeyPrefix$id', false);
    }
  }
}
