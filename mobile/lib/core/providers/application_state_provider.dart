import 'package:flutter/foundation.dart';
import '../models/types.dart';
import '../persistence/local_store.dart';
import '../referral/referral.dart';

const String _storageKey = 'skillbox.affiliate.application.v2';

/// Direct port of `core/state/application-state.service.ts`. Holds the
/// affiliate-application state client-side (SharedPreferences) so the app
/// is fully demoable without a backend. Every mutation here has a 1:1
/// candidate Laravel endpoint documented in docs/api-spec.md.
///
/// There's only ever one applicant in this local store (no real accounts
/// yet), so the admin review screens read and mutate this same provider -
/// it's standing in for what would be a separate reviewer looking at a
/// queue of many applicants' rows in the real backend.
class ApplicationStateProvider extends ChangeNotifier {
  AffiliateApplication _application = const AffiliateApplication();
  bool _loaded = false;

  AffiliateApplication get application => _application;
  bool get loaded => _loaded;

  ApplicationStateProvider() {
    _load();
  }

  Future<void> _load() async {
    final json = await LocalStore.readJson(_storageKey);
    if (json != null) {
      try {
        _application = AffiliateApplication.fromJson(json);
      } catch (_) {
        // Corrupt/old-shape data - fall back to the empty default.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await LocalStore.writeJson(_storageKey, _application.toJson());
  }

  void _update(AffiliateApplication next) {
    _application = next;
    notifyListeners();
    _persist();
  }

  void setInstagramHandle(String handle) {
    _update(_application.copyWith(socials: _application.socials.copyWith(instagramHandle: handle)));
  }

  void togglePlatform(SocialPlatform platform) {
    final platforms = List<SocialPlatform>.from(_application.socials.platforms);
    if (platforms.contains(platform)) {
      platforms.remove(platform);
    } else {
      platforms.add(platform);
    }
    _update(_application.copyWith(socials: _application.socials.copyWith(platforms: platforms)));
  }

  void setCity(City city) {
    _update(_application.copyWith(locationNiche: _application.locationNiche.copyWith(city: city)));
  }

  void setNiche(Niche niche) {
    _update(_application.copyWith(locationNiche: _application.locationNiche.copyWith(niche: niche)));
  }

  void setInsights({
    int? followers,
    double? engagementRate,
    ContentFormat? contentFormat,
    int? audienceIndiaPercent,
    String? screenshotFileName,
  }) {
    _update(_application.copyWith(
      insights: _application.insights.copyWith(
        followers: followers,
        engagementRate: engagementRate,
        contentFormat: contentFormat,
        audienceIndiaPercent: audienceIndiaPercent,
        screenshotFileName: screenshotFileName,
      ),
    ));
  }

  void setContentFormat(ContentFormat format) {
    _update(_application.copyWith(insights: _application.insights.copyWith(contentFormat: format)));
  }

  /// Creator action: step-4 "Submit application" - profile now awaits Skillbox review.
  void submitApplication() {
    _update(_application.copyWith(
      status: ApplicationStatus.underReview,
      submittedAt: DateTime.now(),
      clearScoredAt: true,
    ));
  }

  /// Admin action: reviewer confirms the AI-derived tier is right and unlocks the marketplace.
  void approveApplication() {
    _update(_application.copyWith(status: ApplicationStatus.approved, scoredAt: DateTime.now()));
  }

  /// Admin action: reviewer rejects the profile (bad-fit audience, fake followers, etc).
  void rejectApplication() {
    _update(_application.copyWith(status: ApplicationStatus.rejected, scoredAt: DateTime.now()));
  }

  /// Creator action: apply to promote a specific show - starts pending, not yet approved.
  void applyToGig(String gigId) {
    if (_application.appliedGigs.any((g) => g.gigId == gigId)) return;
    final applied = AppliedGig(gigId: gigId, appliedAt: DateTime.now(), status: GigApplicationStatus.pending);
    _update(_application.copyWith(appliedGigs: [..._application.appliedGigs, applied]));
  }

  /// Admin action: approves a creator to promote this show and issues their unique tracking link.
  void approveGigApplication(String gigId) {
    final updated = _application.appliedGigs.map((g) {
      if (g.gigId != gigId) return g;
      return g.copyWith(
        status: GigApplicationStatus.approved,
        reviewedAt: DateTime.now(),
        referralCode: generateReferralCode(_application.socials.instagramHandle, gigId),
      );
    }).toList();
    _update(_application.copyWith(appliedGigs: updated));
  }

  /// Admin action: rejects a creator's request to promote this specific show.
  void rejectGigApplication(String gigId) {
    final updated = _application.appliedGigs.map((g) {
      if (g.gigId != gigId) return g;
      return g.copyWith(status: GigApplicationStatus.rejected, reviewedAt: DateTime.now());
    }).toList();
    _update(_application.copyWith(appliedGigs: updated));
  }

  void resetApplication() {
    _update(const AffiliateApplication());
  }
}
