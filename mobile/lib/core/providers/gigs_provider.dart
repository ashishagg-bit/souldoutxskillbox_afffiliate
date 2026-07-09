import 'package:flutter/foundation.dart';
import '../data/seed_gigs.dart';
import '../models/types.dart';
import '../persistence/local_store.dart';

const String _storageKey = 'skillbox.affiliate.gigs.v1';

String _slugify(String title) {
  final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'(^-|-$)'), '');
  return slug;
}

/// Direct port of `core/data/gigs.service.ts`. Shows (gigs) available in the
/// marketplace - reactive + persisted so the admin panel's "Shows" tab can
/// create/edit/delete them, standing in for `gigs` CRUD endpoints against
/// the real backend (see docs/api-spec.md).
class GigsProvider extends ChangeNotifier {
  List<Gig> _gigs = List<Gig>.from(seedGigs);
  bool _loaded = false;

  List<Gig> get gigs => _gigs;
  bool get loaded => _loaded;

  GigsProvider() {
    _load();
  }

  Future<void> _load() async {
    final json = await LocalStore.readJsonList(_storageKey);
    if (json != null) {
      try {
        _gigs = json.map((g) => Gig.fromJson(g as Map<String, dynamic>)).toList();
      } catch (_) {
        // Corrupt/old-shape data - fall back to seed.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalStore.writeJsonList(_storageKey, _gigs.map((g) => g.toJson()).toList());
  }

  Gig? getById(String id) {
    for (final g in _gigs) {
      if (g.id == id) return g;
    }
    return null;
  }

  Gig addGig(Gig draft) {
    final base = _slugify(draft.title).isEmpty ? 'show' : _slugify(draft.title);
    var id = base;
    var n = 2;
    while (_gigs.any((g) => g.id == id)) {
      id = '$base-${n++}';
    }
    final created = draft.copyWith()._withId(id);
    _gigs = [..._gigs, created];
    notifyListeners();
    _persist();
    return created;
  }

  void updateGig(String id, Gig Function(Gig current) update) {
    _gigs = _gigs.map((g) => g.id == id ? update(g) : g).toList();
    notifyListeners();
    _persist();
  }

  void deleteGig(String id) {
    _gigs = _gigs.where((g) => g.id != id).toList();
    notifyListeners();
    _persist();
  }

  void resetToSeed() {
    _gigs = List<Gig>.from(seedGigs);
    notifyListeners();
    _persist();
  }
}

extension _WithId on Gig {
  Gig _withId(String newId) => Gig(
        id: newId,
        type: type,
        minTier: minTier,
        minScore: minScore,
        title: title,
        location: location,
        date: date,
        spotsLeft: spotsLeft,
        deliverable: deliverable,
        payoutMin: payoutMin,
        payoutMax: payoutMax,
        ticketPrice: ticketPrice,
        commissionRate: commissionRate,
      );
}
