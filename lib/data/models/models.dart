// Hand-written immutable models mirroring docs/api/openapi.yaml (eng review D2:
// no freezed/json_serializable). Field names follow the JSON contract.

enum ProviderId {
  gemini,
  anthropic,
  openai;

  static ProviderId fromJson(String value) =>
      ProviderId.values.firstWhere((p) => p.name == value,
          orElse: () => throw FormatException('Unknown provider: $value'));

  String get label => switch (this) {
        ProviderId.gemini => 'Gemini',
        ProviderId.anthropic => 'Claude',
        ProviderId.openai => 'OpenAI',
      };
}

enum Sentiment {
  positive,
  negative,
  neutral;

  static Sentiment fromJson(String value) =>
      Sentiment.values.firstWhere((s) => s.name == value,
          orElse: () => Sentiment.neutral);
}

class Thread {
  const Thread({
    required this.id,
    required this.subreddit,
    required this.title,
    required this.author,
    required this.permalink,
    required this.createdAt,
    required this.score,
    required this.upvoteRatio,
    required this.numComments,
    required this.isNsfw,
    required this.selftextExcerpt,
  });

  final String id;
  final String subreddit;
  final String title;
  final String author;
  final String permalink;
  final DateTime createdAt;
  final int score;
  final double upvoteRatio;
  final int numComments;
  final bool isNsfw;
  final String? selftextExcerpt;

  factory Thread.fromJson(Map<String, dynamic> json) => Thread(
        id: json['id'] as String,
        subreddit: json['subreddit'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        permalink: json['permalink'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        score: (json['score'] as num).toInt(),
        upvoteRatio: (json['upvoteRatio'] as num).toDouble(),
        numComments: (json['numComments'] as num).toInt(),
        isNsfw: json['isNsfw'] as bool,
        selftextExcerpt: json['selftextExcerpt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subreddit': subreddit,
        'title': title,
        'author': author,
        'permalink': permalink,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'score': score,
        'upvoteRatio': upvoteRatio,
        'numComments': numComments,
        'isNsfw': isNsfw,
        'selftextExcerpt': selftextExcerpt,
      };
}

class Analysis {
  const Analysis({
    required this.language,
    required this.shortSummary,
    required this.detailedSummary,
    required this.sentiment,
    required this.emotions,
    required this.toxicity,
    required this.aiTake,
  });

  final String language;
  final String shortSummary;
  final String detailedSummary;
  final Sentiment sentiment;
  final List<String> emotions;
  final double? toxicity;
  final String aiTake;

  factory Analysis.fromJson(Map<String, dynamic> json) {
    final emotions = (json['emotions'] as List).cast<String>();
    return Analysis(
      language: json['language'] as String,
      shortSummary: json['shortSummary'] as String,
      detailedSummary: json['detailedSummary'] as String,
      sentiment: Sentiment.fromJson(json['sentiment'] as String),
      // Contract: never empty; fall back to neutral if a server misbehaves.
      emotions: emotions.isEmpty ? const ['neutral'] : emotions,
      toxicity: (json['toxicity'] as num?)?.toDouble(),
      aiTake: json['aiTake'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'shortSummary': shortSummary,
        'detailedSummary': detailedSummary,
        'sentiment': sentiment.name,
        'emotions': emotions,
        'toxicity': toxicity,
        'aiTake': aiTake,
      };
}

class SummaryMeta {
  const SummaryMeta({
    required this.provider,
    required this.model,
    required this.commentsAnalyzed,
    required this.commentsTotal,
    required this.truncated,
  });

  final ProviderId provider;
  final String model;
  final int commentsAnalyzed;
  final int commentsTotal;
  final bool truncated;

  factory SummaryMeta.fromJson(Map<String, dynamic> json) => SummaryMeta(
        provider: ProviderId.fromJson(json['provider'] as String),
        model: json['model'] as String,
        commentsAnalyzed: (json['commentsAnalyzed'] as num).toInt(),
        commentsTotal: (json['commentsTotal'] as num).toInt(),
        truncated: json['truncated'] as bool,
      );
}

class SummaryResult {
  const SummaryResult({
    required this.thread,
    required this.analysis,
    required this.meta,
  });

  final Thread thread;
  final Analysis analysis;
  final SummaryMeta meta;

  factory SummaryResult.fromJson(Map<String, dynamic> json) => SummaryResult(
        thread: Thread.fromJson(json['thread'] as Map<String, dynamic>),
        analysis: Analysis.fromJson(json['analysis'] as Map<String, dynamic>),
        meta: SummaryMeta.fromJson(json['meta'] as Map<String, dynamic>),
      );
}

class CatalogModel {
  const CatalogModel({required this.id, required this.name, required this.isDefault});

  final String id;
  final String name;
  final bool isDefault;

  factory CatalogModel.fromJson(Map<String, dynamic> json) => CatalogModel(
        id: json['id'] as String,
        name: json['name'] as String,
        isDefault: json['isDefault'] as bool,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isDefault': isDefault};
}

class CatalogProvider {
  const CatalogProvider({
    required this.id,
    required this.name,
    required this.keyHelpUrl,
    required this.keyPattern,
    required this.models,
  });

  final ProviderId id;
  final String name;
  final String keyHelpUrl;
  final String keyPattern;
  final List<CatalogModel> models;

  CatalogModel get defaultModel =>
      models.firstWhere((m) => m.isDefault, orElse: () => models.first);

  bool hasModel(String modelId) => models.any((m) => m.id == modelId);

  factory CatalogProvider.fromJson(Map<String, dynamic> json) => CatalogProvider(
        id: ProviderId.fromJson(json['id'] as String),
        name: json['name'] as String,
        keyHelpUrl: json['keyHelpUrl'] as String,
        keyPattern: json['keyPattern'] as String,
        models: (json['models'] as List)
            .map((m) => CatalogModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'name': name,
        'keyHelpUrl': keyHelpUrl,
        'keyPattern': keyPattern,
        'models': models.map((m) => m.toJson()).toList(),
      };
}

class ProviderCatalog {
  const ProviderCatalog(this.providers);

  final List<CatalogProvider> providers;

  CatalogProvider provider(ProviderId id) => providers.firstWhere((p) => p.id == id);

  factory ProviderCatalog.fromJson(Map<String, dynamic> json) => ProviderCatalog(
        (json['providers'] as List)
            .map((p) => CatalogProvider.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {'providers': providers.map((p) => p.toJson()).toList()};
}

class KeyValidation {
  const KeyValidation({required this.valid, required this.provider});

  final bool valid;
  final ProviderId provider;

  factory KeyValidation.fromJson(Map<String, dynamic> json) => KeyValidation(
        valid: json['valid'] as bool,
        provider: ProviderId.fromJson(json['provider'] as String),
      );
}

class TranslationResult {
  const TranslationResult(this.analysis);

  final Analysis analysis;

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(Analysis.fromJson(json['analysis'] as Map<String, dynamic>));
}
