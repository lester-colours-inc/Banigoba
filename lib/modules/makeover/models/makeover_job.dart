// Coordinated makeover job.
//
// Clothing and hair are one journey for the user and two engines underneath —
// the arrangement BNG SRS 001 asks for (SRS-DEC-002, DEV DEC-003): "presented
// as one coordinated makeover journey but implemented as separable
// capabilities so either domain can be retried, refined, benchmarked,
// replaced or degraded without restarting the other".
//
// Each domain therefore carries its own independent state, and the coordinator
// keeps the intermediate artifact from every stage so a refinement can resume
// from the last unaffected point instead of starting over.
import 'package:banigoba/core/supabase/rows.dart';

/// The two transformation domains in the lean MVP.
enum MakeoverDomain {
  hair('hair', 'Hair'),
  clothing('clothing', 'Clothing');

  const MakeoverDomain(this.id, this.label);

  final String id;
  final String label;

  static MakeoverDomain? fromId(String? id) {
    for (final domain in MakeoverDomain.values) {
      if (domain.id == id) return domain;
    }
    return null;
  }
}

/// Lifecycle of one domain within a job.
enum MakeoverStageStatus {
  /// The user did not ask for this domain.
  skipped('skipped'),
  queued('queued'),
  running('running'),
  succeeded('succeeded'),
  failed('failed');

  const MakeoverStageStatus(this.id);

  final String id;

  bool get isTerminal =>
      this == MakeoverStageStatus.succeeded ||
      this == MakeoverStageStatus.failed ||
      this == MakeoverStageStatus.skipped;

  static MakeoverStageStatus fromId(String? id) {
    for (final status in MakeoverStageStatus.values) {
      if (status.id == id) return status;
    }
    return MakeoverStageStatus.queued;
  }
}

/// State of one domain.
class MakeoverStage {
  const MakeoverStage({
    required this.domain,
    this.status = MakeoverStageStatus.queued,
    this.outputImageUrls = const [],
    this.errorMessage = '',
    this.startedAt,
    this.completedAt,
  });

  final MakeoverDomain domain;
  final MakeoverStageStatus status;

  /// Images this stage produced. The stage that runs last carries the
  /// selectable alternatives; earlier stages carry a single intermediate.
  final List<String> outputImageUrls;
  final String errorMessage;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get succeeded => status == MakeoverStageStatus.succeeded;
  bool get isRequested => status != MakeoverStageStatus.skipped;
  String get primaryOutput =>
      outputImageUrls.isEmpty ? '' : outputImageUrls.first;

  MakeoverStage copyWith({
    MakeoverStageStatus? status,
    List<String>? outputImageUrls,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return MakeoverStage(
      domain: domain,
      status: status ?? this.status,
      outputImageUrls: outputImageUrls ?? this.outputImageUrls,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory MakeoverStage.fromMap(
    Map<String, dynamic> data, {
    required MakeoverDomain domain,
  }) {
    final rawOutputs = data['outputImageUrls'];
    final startedAt = data['startedAt'];
    final completedAt = data['completedAt'];
    return MakeoverStage(
      domain: domain,
      status: MakeoverStageStatus.fromId(data['status']?.toString()),
      outputImageUrls: rawOutputs is Iterable
          ? rawOutputs
                .map((value) => value.toString())
                .where((value) => value.isNotEmpty)
                .toList()
          : const [],
      errorMessage: (data['errorMessage'] ?? '').toString(),
      startedAt: asDateTime(startedAt),
      completedAt: asDateTime(completedAt),
    );
  }

  Map<String, dynamic> toMap() => {
    'status': status.id,
    'outputImageUrls': outputImageUrls,
    'errorMessage': errorMessage,
    if (startedAt != null) 'startedAt': startedAt!.toUtc().toIso8601String(),
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
  };
}

/// What the user asked for, captured before any generation runs (UI-04).
///
/// Boundaries are user-selected: an empty [hairPrompt] or empty [garments]
/// means "do not touch this domain", never "decide for me". Nothing here may
/// alter body shape, skin tone or facial structure.
class MakeoverIntent {
  const MakeoverIntent({
    this.occasion = '',
    this.desiredFeeling = '',
    this.hairPrompt = '',
    this.garments = const [],
    this.climate = '',
    this.modestyPreference = '',
    this.budget = '',
    this.exclusions = const [],
  });

  final String occasion;
  final String desiredFeeling;

  /// Hair instruction. Empty means hair is left alone.
  final String hairPrompt;

  /// Catalogue products to try on. Empty means clothing is left alone.
  final List<Map<String, dynamic>> garments;

  final String climate;
  final String modestyPreference;
  final String budget;
  final List<String> exclusions;

  bool get wantsHair => hairPrompt.trim().isNotEmpty;
  bool get wantsClothing => garments.isNotEmpty;
  bool get isEmpty => !wantsHair && !wantsClothing;

  /// Domains the user asked for, in pipeline order.
  List<MakeoverDomain> get requestedDomains => [
    if (wantsHair) MakeoverDomain.hair,
    if (wantsClothing) MakeoverDomain.clothing,
  ];

  MakeoverIntent copyWith({
    String? occasion,
    String? desiredFeeling,
    String? hairPrompt,
    List<Map<String, dynamic>>? garments,
    String? climate,
    String? modestyPreference,
    String? budget,
    List<String>? exclusions,
  }) {
    return MakeoverIntent(
      occasion: occasion ?? this.occasion,
      desiredFeeling: desiredFeeling ?? this.desiredFeeling,
      hairPrompt: hairPrompt ?? this.hairPrompt,
      garments: garments ?? this.garments,
      climate: climate ?? this.climate,
      modestyPreference: modestyPreference ?? this.modestyPreference,
      budget: budget ?? this.budget,
      exclusions: exclusions ?? this.exclusions,
    );
  }

  factory MakeoverIntent.fromMap(Map<String, dynamic> data) {
    final rawGarments = data['garments'];
    final rawExclusions = data['exclusions'];
    return MakeoverIntent(
      occasion: (data['occasion'] ?? '').toString(),
      desiredFeeling: (data['desiredFeeling'] ?? '').toString(),
      hairPrompt: (data['hairPrompt'] ?? '').toString(),
      garments: rawGarments is Iterable
          ? rawGarments
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const [],
      climate: (data['climate'] ?? '').toString(),
      modestyPreference: (data['modestyPreference'] ?? '').toString(),
      budget: (data['budget'] ?? '').toString(),
      exclusions: rawExclusions is Iterable
          ? rawExclusions.map((value) => value.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'occasion': occasion,
    'desiredFeeling': desiredFeeling,
    'hairPrompt': hairPrompt,
    'garments': garments,
    'climate': climate,
    'modestyPreference': modestyPreference,
    'budget': budget,
    'exclusions': exclusions,
  };
}

/// One coordinated alternative the user can select (AI-003 requires at least
/// two, separately selectable).
class MakeoverAlternative {
  const MakeoverAlternative({
    required this.index,
    required this.imageUrl,
    this.appliedDomains = const [],
  });

  final int index;
  final String imageUrl;

  /// Domains that contributed to this image, so the compare screen can say
  /// what actually changed.
  final List<MakeoverDomain> appliedDomains;

  String get label => 'Look ${String.fromCharCode(65 + index)}';
}

/// A coordinated clothing-and-hair makeover.
class MakeoverJob {
  const MakeoverJob({
    required this.id,
    required this.userId,
    required this.sourceImageUrl,
    required this.intent,
    required this.stages,
    this.alternatives = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;

  /// The user's own photo. Preserved unmodified for the before/after view.
  final String sourceImageUrl;
  final MakeoverIntent intent;
  final Map<MakeoverDomain, MakeoverStage> stages;
  final List<MakeoverAlternative> alternatives;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MakeoverStage stageFor(MakeoverDomain domain) =>
      stages[domain] ??
      MakeoverStage(domain: domain, status: MakeoverStageStatus.skipped);

  /// Requested domains only — a skipped domain is not a failure.
  Iterable<MakeoverStage> get activeStages =>
      stages.values.where((stage) => stage.isRequested);

  bool get isRunning => activeStages.any(
    (stage) =>
        stage.status == MakeoverStageStatus.running ||
        stage.status == MakeoverStageStatus.queued,
  );

  bool get hasFailure =>
      activeStages.any((stage) => stage.status == MakeoverStageStatus.failed);

  /// True when every requested domain succeeded.
  bool get isComplete =>
      activeStages.isNotEmpty && activeStages.every((stage) => stage.succeeded);

  /// True when some domains succeeded and others failed. The user keeps what
  /// worked; the spec forbids silently substituting a degraded result.
  bool get isPartial =>
      hasFailure && activeStages.any((stage) => stage.succeeded);

  MakeoverJob copyWith({
    String? sourceImageUrl,
    MakeoverIntent? intent,
    Map<MakeoverDomain, MakeoverStage>? stages,
    List<MakeoverAlternative>? alternatives,
    DateTime? updatedAt,
  }) {
    return MakeoverJob(
      id: id,
      userId: userId,
      sourceImageUrl: sourceImageUrl ?? this.sourceImageUrl,
      intent: intent ?? this.intent,
      stages: stages ?? this.stages,
      alternatives: alternatives ?? this.alternatives,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Builds a job from its stored document (see CoordinatedMakeoverService).
  factory MakeoverJob.fromDocument(String id, Map<String, dynamic> data) {
    final rawStages = data['stages'];
    final stages = <MakeoverDomain, MakeoverStage>{};
    if (rawStages is Map) {
      for (final entry in rawStages.entries) {
        final domain = MakeoverDomain.fromId(entry.key.toString());
        final value = entry.value;
        if (domain == null || value is! Map) continue;
        stages[domain] = MakeoverStage.fromMap(
          Map<String, dynamic>.from(value),
          domain: domain,
        );
      }
    }

    final rawAlternatives = data['alternatives'];
    final alternatives = <MakeoverAlternative>[];
    if (rawAlternatives is Iterable) {
      var index = 0;
      for (final item in rawAlternatives) {
        final url = item.toString();
        if (url.isEmpty) continue;
        alternatives.add(MakeoverAlternative(index: index, imageUrl: url));
        index += 1;
      }
    }

    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return MakeoverJob(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      sourceImageUrl: (data['sourceImageUrl'] ?? '').toString(),
      intent: data['intent'] is Map
          ? MakeoverIntent.fromMap(
              Map<String, dynamic>.from(data['intent'] as Map),
            )
          : const MakeoverIntent(),
      stages: stages,
      alternatives: alternatives,
      createdAt: asDateTime(createdAt),
      updatedAt: asDateTime(updatedAt),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'sourceImageUrl': sourceImageUrl,
    'intent': intent.toMap(),
    'stages': {
      for (final entry in stages.entries) entry.key.id: entry.value.toMap(),
    },
    'alternatives': alternatives
        .map((alternative) => alternative.imageUrl)
        .toList(),
  };
}
