import 'package:flutter/foundation.dart';
import '../persistence/local_store.dart';
import '../scoring/scoring.dart';

const String _storageKey = 'skillbox.affiliate.scoring-weights.v1';

/// Direct port of `core/state/scoring-weights.service.ts`. Admin-editable
/// point weight (ceiling) for each of the 8 scoring metrics. Band *shapes*
/// stay fixed in scoring.dart - only how many points a bracket is worth is
/// configurable here.
class ScoringWeightsProvider extends ChangeNotifier {
  ScoringWeights _weights = defaultScoringWeights;
  bool _loaded = false;

  ScoringWeights get weights => _weights;
  bool get loaded => _loaded;

  ScoringWeightsProvider() {
    _load();
  }

  Future<void> _load() async {
    final json = await LocalStore.readJson(_storageKey);
    if (json != null) {
      try {
        _weights = ScoringWeights.fromJson(json);
      } catch (_) {
        // fall back to defaults
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalStore.writeJson(_storageKey, _weights.toJson());
  }

  void updateWeight(String key, double value) {
    _weights = _weights.copyWithField(key, value < 0 ? 0 : value);
    notifyListeners();
    _persist();
  }

  void resetToDefaults() {
    _weights = defaultScoringWeights;
    notifyListeners();
    _persist();
  }
}
