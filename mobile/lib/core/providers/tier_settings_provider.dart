import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../persistence/local_store.dart';
import '../scoring/scoring.dart';

const String _storageKey = 'skillbox.affiliate.tier-settings.v1';

/// Direct port of `core/state/tier-settings.service.ts`. Admin-editable tier
/// score cutoffs + display payout ranges.
class TierSettingsProvider extends ChangeNotifier {
  List<TierBand> _tierBands = List<TierBand>.from(defaultTierBands);
  bool _loaded = false;

  List<TierBand> get tierBands => _tierBands;
  bool get loaded => _loaded;

  TierSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final json = await LocalStore.readJsonList(_storageKey);
    if (json != null) {
      try {
        _tierBands = json.map((b) => TierBand.fromJson(b as Map<String, dynamic>)).toList();
      } catch (_) {
        // fall back to defaults
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalStore.writeJsonList(_storageKey, _tierBands.map((b) => b.toJson()).toList());
  }

  void updateBand(Tier tier, {int? min, int? max, String? payout}) {
    _tierBands = _tierBands
        .map((b) => b.tier == tier ? b.copyWith(min: min, max: max, payout: payout) : b)
        .toList();
    notifyListeners();
    _persist();
  }

  void resetToDefaults() {
    _tierBands = List<TierBand>.from(defaultTierBands);
    notifyListeners();
    _persist();
  }
}
