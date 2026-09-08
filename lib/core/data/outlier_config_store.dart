import 'package:shared_preferences/shared_preferences.dart';

import '../../features/data_entry/domain/entities/outlier_stats.dart';

/// Persists the one global [OutlierConfig] the data-entry outlier check
/// uses. Plain SharedPreferences, like [OnboardingService]: it's a UI
/// preference, not a credential, and should survive login/logout.
class OutlierConfigStore {
  OutlierConfigStore._();

  static const _algorithmKey = 'outlier_algorithm';
  static const _thresholdKey = 'outlier_threshold';

  static Future<OutlierConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final algoName = prefs.getString(_algorithmKey);
    var algorithm = OutlierConfig.defaults.algorithm;
    for (final a in OutlierAlgorithm.values) {
      if (a.name == algoName) {
        algorithm = a;
        break;
      }
    }
    final threshold = prefs.getDouble(_thresholdKey);
    return OutlierConfig(
      algorithm: algorithm,
      threshold: threshold ?? OutlierConfig.defaults.threshold,
    );
  }

  static Future<void> save(OutlierConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_algorithmKey, config.algorithm.name);
    await prefs.setDouble(_thresholdKey, config.threshold);
  }
}
