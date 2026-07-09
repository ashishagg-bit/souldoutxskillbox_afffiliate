/// Direct port of the Angular prototype's `core/lib/types.ts`. Keep the two
/// in sync if the web reference is ever updated further; this is the
/// authoritative version once the Flutter app is the shipping feature.
library;

enum SocialPlatform { instagram, youtube, snapchat, twitter }

extension SocialPlatformLabel on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.youtube => 'YouTube',
        SocialPlatform.snapchat => 'Snapchat',
        SocialPlatform.twitter => 'Twitter / X',
      };
}

enum ContentFormat { reels, photos, stories, longForm }

extension ContentFormatLabel on ContentFormat {
  String get label => switch (this) {
        ContentFormat.reels => 'Reels / Short video',
        ContentFormat.photos => 'Photos / Carousel',
        ContentFormat.stories => 'Stories only',
        ContentFormat.longForm => 'Long-form video',
      };
}

enum City { delhi, mumbai, bengaluru, hyderabad, pune, goa, chennai, kolkata }

extension CityLabel on City {
  String get label => switch (this) {
        City.delhi => 'Delhi',
        City.mumbai => 'Mumbai',
        City.bengaluru => 'Bengaluru',
        City.hyderabad => 'Hyderabad',
        City.pune => 'Pune',
        City.goa => 'Goa',
        City.chennai => 'Chennai',
        City.kolkata => 'Kolkata',
      };
}

enum Niche { nightlife, music, lifestyle, foodAndDrink, fashion, travel }

extension NicheLabel on Niche {
  String get label => switch (this) {
        Niche.nightlife => 'Nightlife',
        Niche.music => 'Music',
        Niche.lifestyle => 'Lifestyle',
        Niche.foodAndDrink => 'Food & Drink',
        Niche.fashion => 'Fashion',
        Niche.travel => 'Travel',
      };
}

enum Tier { bronze, silver, gold, platinum }

extension TierLabel on Tier {
  String get label => switch (this) {
        Tier.bronze => 'Bronze',
        Tier.silver => 'Silver',
        Tier.gold => 'Gold',
        Tier.platinum => 'Platinum',
      };
}

enum ApplicationStatus { notApplied, underReview, approved, rejected }

enum GigApplicationStatus { pending, approved, rejected }

enum GigType { storyCoverage, attendance, ugc, brandCampaign }

extension GigTypeLabel on GigType {
  String get label => switch (this) {
        GigType.storyCoverage => 'Story coverage',
        GigType.attendance => 'Attendance',
        GigType.ugc => 'UGC',
        GigType.brandCampaign => 'Brand campaign',
      };
}

class SocialsInfo {
  final String instagramHandle;
  final List<SocialPlatform> platforms;

  const SocialsInfo({this.instagramHandle = '', this.platforms = const []});

  SocialsInfo copyWith({String? instagramHandle, List<SocialPlatform>? platforms}) => SocialsInfo(
        instagramHandle: instagramHandle ?? this.instagramHandle,
        platforms: platforms ?? this.platforms,
      );

  Map<String, dynamic> toJson() => {
        'instagramHandle': instagramHandle,
        'platforms': platforms.map((p) => p.name).toList(),
      };

  factory SocialsInfo.fromJson(Map<String, dynamic> json) => SocialsInfo(
        instagramHandle: json['instagramHandle'] as String? ?? '',
        platforms: (json['platforms'] as List<dynamic>? ?? [])
            .map((p) => SocialPlatform.values.byName(p as String))
            .toList(),
      );
}

class LocationNicheInfo {
  final City? city;
  final Niche? niche;

  const LocationNicheInfo({this.city, this.niche});

  LocationNicheInfo copyWith({City? city, Niche? niche}) =>
      LocationNicheInfo(city: city ?? this.city, niche: niche ?? this.niche);

  Map<String, dynamic> toJson() => {'city': city?.name, 'niche': niche?.name};

  factory LocationNicheInfo.fromJson(Map<String, dynamic> json) => LocationNicheInfo(
        city: json['city'] != null ? City.values.byName(json['city'] as String) : null,
        niche: json['niche'] != null ? Niche.values.byName(json['niche'] as String) : null,
      );
}

class InsightsInfo {
  final int followers;
  final double engagementRate;
  final ContentFormat? contentFormat;
  final int audienceIndiaPercent;
  final String? screenshotFileName;

  const InsightsInfo({
    this.followers = 0,
    this.engagementRate = 0,
    this.contentFormat,
    this.audienceIndiaPercent = 70,
    this.screenshotFileName,
  });

  InsightsInfo copyWith({
    int? followers,
    double? engagementRate,
    ContentFormat? contentFormat,
    int? audienceIndiaPercent,
    String? screenshotFileName,
  }) =>
      InsightsInfo(
        followers: followers ?? this.followers,
        engagementRate: engagementRate ?? this.engagementRate,
        contentFormat: contentFormat ?? this.contentFormat,
        audienceIndiaPercent: audienceIndiaPercent ?? this.audienceIndiaPercent,
        screenshotFileName: screenshotFileName ?? this.screenshotFileName,
      );

  Map<String, dynamic> toJson() => {
        'followers': followers,
        'engagementRate': engagementRate,
        'contentFormat': contentFormat?.name,
        'audienceIndiaPercent': audienceIndiaPercent,
        'screenshotFileName': screenshotFileName,
      };

  factory InsightsInfo.fromJson(Map<String, dynamic> json) => InsightsInfo(
        followers: json['followers'] as int? ?? 0,
        engagementRate: (json['engagementRate'] as num?)?.toDouble() ?? 0,
        contentFormat:
            json['contentFormat'] != null ? ContentFormat.values.byName(json['contentFormat'] as String) : null,
        audienceIndiaPercent: json['audienceIndiaPercent'] as int? ?? 70,
        screenshotFileName: json['screenshotFileName'] as String?,
      );
}

class SkillboxPerformance {
  final int ticketsSold;
  final double contentApprovalRate;
  final int gigsCompleted;
  final bool activeLast60Days;

  const SkillboxPerformance({
    this.ticketsSold = 0,
    this.contentApprovalRate = 0,
    this.gigsCompleted = 0,
    this.activeLast60Days = true,
  });

  Map<String, dynamic> toJson() => {
        'ticketsSold': ticketsSold,
        'contentApprovalRate': contentApprovalRate,
        'gigsCompleted': gigsCompleted,
        'activeLast60Days': activeLast60Days,
      };

  factory SkillboxPerformance.fromJson(Map<String, dynamic> json) => SkillboxPerformance(
        ticketsSold: json['ticketsSold'] as int? ?? 0,
        contentApprovalRate: (json['contentApprovalRate'] as num?)?.toDouble() ?? 0,
        gigsCompleted: json['gigsCompleted'] as int? ?? 0,
        activeLast60Days: json['activeLast60Days'] as bool? ?? true,
      );
}

class ScoreBreakdownItem {
  final String label;
  final String detail;
  final double earned;
  final double max;

  const ScoreBreakdownItem({required this.label, required this.detail, required this.earned, required this.max});
}

class ScoreBreakdown {
  final int total;
  final Tier tier;
  final List<ScoreBreakdownItem> platformMetrics;
  final List<ScoreBreakdownItem> skillboxPerformance;

  const ScoreBreakdown({
    required this.total,
    required this.tier,
    required this.platformMetrics,
    required this.skillboxPerformance,
  });
}

class Gig {
  final String id;
  final GigType type;
  final Tier minTier;
  final int minScore;
  final String title;
  final String? location;
  final String? date;
  final int? spotsLeft;
  final String? deliverable;
  final int payoutMin;
  final int payoutMax;
  final int? ticketPrice;
  final double? commissionRate;

  const Gig({
    required this.id,
    required this.type,
    required this.minTier,
    required this.minScore,
    required this.title,
    this.location,
    this.date,
    this.spotsLeft,
    this.deliverable,
    required this.payoutMin,
    required this.payoutMax,
    this.ticketPrice,
    this.commissionRate,
  });

  Gig copyWith({
    GigType? type,
    Tier? minTier,
    int? minScore,
    String? title,
    String? location,
    String? date,
    int? spotsLeft,
    String? deliverable,
    int? payoutMin,
    int? payoutMax,
    int? ticketPrice,
    double? commissionRate,
    bool clearLocation = false,
    bool clearDate = false,
    bool clearSpotsLeft = false,
    bool clearDeliverable = false,
    bool clearTicketPrice = false,
    bool clearCommissionRate = false,
  }) =>
      Gig(
        id: id,
        type: type ?? this.type,
        minTier: minTier ?? this.minTier,
        minScore: minScore ?? this.minScore,
        title: title ?? this.title,
        location: clearLocation ? null : (location ?? this.location),
        date: clearDate ? null : (date ?? this.date),
        spotsLeft: clearSpotsLeft ? null : (spotsLeft ?? this.spotsLeft),
        deliverable: clearDeliverable ? null : (deliverable ?? this.deliverable),
        payoutMin: payoutMin ?? this.payoutMin,
        payoutMax: payoutMax ?? this.payoutMax,
        ticketPrice: clearTicketPrice ? null : (ticketPrice ?? this.ticketPrice),
        commissionRate: clearCommissionRate ? null : (commissionRate ?? this.commissionRate),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'minTier': minTier.name,
        'minScore': minScore,
        'title': title,
        'location': location,
        'date': date,
        'spotsLeft': spotsLeft,
        'deliverable': deliverable,
        'payoutMin': payoutMin,
        'payoutMax': payoutMax,
        'ticketPrice': ticketPrice,
        'commissionRate': commissionRate,
      };

  factory Gig.fromJson(Map<String, dynamic> json) => Gig(
        id: json['id'] as String,
        type: GigType.values.byName(json['type'] as String),
        minTier: Tier.values.byName(json['minTier'] as String),
        minScore: json['minScore'] as int,
        title: json['title'] as String,
        location: json['location'] as String?,
        date: json['date'] as String?,
        spotsLeft: json['spotsLeft'] as int?,
        deliverable: json['deliverable'] as String?,
        payoutMin: json['payoutMin'] as int,
        payoutMax: json['payoutMax'] as int,
        ticketPrice: json['ticketPrice'] as int?,
        commissionRate: (json['commissionRate'] as num?)?.toDouble(),
      );
}

class AppliedGig {
  final String gigId;
  final DateTime appliedAt;
  final GigApplicationStatus status;
  final DateTime? reviewedAt;
  final String? referralCode;

  const AppliedGig({
    required this.gigId,
    required this.appliedAt,
    required this.status,
    this.reviewedAt,
    this.referralCode,
  });

  AppliedGig copyWith({
    GigApplicationStatus? status,
    DateTime? reviewedAt,
    String? referralCode,
  }) =>
      AppliedGig(
        gigId: gigId,
        appliedAt: appliedAt,
        status: status ?? this.status,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        referralCode: referralCode ?? this.referralCode,
      );

  Map<String, dynamic> toJson() => {
        'gigId': gigId,
        'appliedAt': appliedAt.toIso8601String(),
        'status': status.name,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'referralCode': referralCode,
      };

  factory AppliedGig.fromJson(Map<String, dynamic> json) => AppliedGig(
        gigId: json['gigId'] as String,
        appliedAt: DateTime.parse(json['appliedAt'] as String),
        status: GigApplicationStatus.values.byName(json['status'] as String),
        reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
        referralCode: json['referralCode'] as String?,
      );
}

class AffiliateApplication {
  final ApplicationStatus status;
  final SocialsInfo socials;
  final LocationNicheInfo locationNiche;
  final InsightsInfo insights;
  final SkillboxPerformance performance;
  final DateTime? submittedAt;
  final DateTime? scoredAt;
  final List<AppliedGig> appliedGigs;

  const AffiliateApplication({
    this.status = ApplicationStatus.notApplied,
    this.socials = const SocialsInfo(),
    this.locationNiche = const LocationNicheInfo(),
    this.insights = const InsightsInfo(),
    this.performance = const SkillboxPerformance(),
    this.submittedAt,
    this.scoredAt,
    this.appliedGigs = const [],
  });

  AffiliateApplication copyWith({
    ApplicationStatus? status,
    SocialsInfo? socials,
    LocationNicheInfo? locationNiche,
    InsightsInfo? insights,
    SkillboxPerformance? performance,
    DateTime? submittedAt,
    DateTime? scoredAt,
    List<AppliedGig>? appliedGigs,
    bool clearScoredAt = false,
  }) =>
      AffiliateApplication(
        status: status ?? this.status,
        socials: socials ?? this.socials,
        locationNiche: locationNiche ?? this.locationNiche,
        insights: insights ?? this.insights,
        performance: performance ?? this.performance,
        submittedAt: submittedAt ?? this.submittedAt,
        scoredAt: clearScoredAt ? null : (scoredAt ?? this.scoredAt),
        appliedGigs: appliedGigs ?? this.appliedGigs,
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'socials': socials.toJson(),
        'locationNiche': locationNiche.toJson(),
        'insights': insights.toJson(),
        'performance': performance.toJson(),
        'submittedAt': submittedAt?.toIso8601String(),
        'scoredAt': scoredAt?.toIso8601String(),
        'appliedGigs': appliedGigs.map((g) => g.toJson()).toList(),
      };

  factory AffiliateApplication.fromJson(Map<String, dynamic> json) => AffiliateApplication(
        status: ApplicationStatus.values.byName(json['status'] as String? ?? 'notApplied'),
        socials: SocialsInfo.fromJson(json['socials'] as Map<String, dynamic>? ?? {}),
        locationNiche: LocationNicheInfo.fromJson(json['locationNiche'] as Map<String, dynamic>? ?? {}),
        insights: InsightsInfo.fromJson(json['insights'] as Map<String, dynamic>? ?? {}),
        performance: SkillboxPerformance.fromJson(json['performance'] as Map<String, dynamic>? ?? {}),
        submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'] as String) : null,
        scoredAt: json['scoredAt'] != null ? DateTime.parse(json['scoredAt'] as String) : null,
        appliedGigs: (json['appliedGigs'] as List<dynamic>? ?? [])
            .map((g) => AppliedGig.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}
