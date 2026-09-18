class Stone {
  const Stone({
    required this.id,
    required this.nameDe,
    this.nameEn,
    this.scientificName,
    this.category,
    this.colors = const [],
    this.hardnessMin,
    this.hardnessMax,
    this.streak,
    this.densityMin,
    this.densityMax,
    this.transparency = const [],
    this.description,
    this.sourceName,
    this.sourceUrl,
    this.verified = false,
  });

  final String id;
  final String nameDe;
  final String? nameEn;
  final String? scientificName;
  final String? category;
  final List<String> colors;
  final double? hardnessMin;
  final double? hardnessMax;
  final String? streak;
  final double? densityMin;
  final double? densityMax;
  final List<String> transparency;
  final String? description;
  final String? sourceName;
  final String? sourceUrl;
  final bool verified;

  factory Stone.fromJson(Map<String, dynamic> json) => Stone(
        id: (json['id'] ?? json['slug'] ?? json['name_de']).toString(),
        nameDe: (json['name_de'] ?? json['name'] ?? 'Unbekannt').toString(),
        nameEn: json['name_en']?.toString(),
        scientificName: json['scientific_name']?.toString(),
        category: json['category']?.toString(),
        colors: (json['colors'] as List? ?? const []).map((e) => e.toString()).toList(),
        hardnessMin: (json['hardness_min'] as num?)?.toDouble(),
        hardnessMax: (json['hardness_max'] as num?)?.toDouble(),
        streak: json['streak']?.toString(),
        densityMin: (json['density_min'] as num?)?.toDouble(),
        densityMax: (json['density_max'] as num?)?.toDouble(),
        transparency: (json['transparency'] as List? ?? const []).map((e) => e.toString()).toList(),
        description: json['description']?.toString(),
        sourceName: json['source_name']?.toString(),
        sourceUrl: json['source_url']?.toString(),
        verified: json['verified'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_de': nameDe,
        'name_en': nameEn,
        'scientific_name': scientificName,
        'category': category,
        'colors': colors,
        'hardness_min': hardnessMin,
        'hardness_max': hardnessMax,
        'streak': streak,
        'density_min': densityMin,
        'density_max': densityMax,
        'transparency': transparency,
        'description': description,
        'source_name': sourceName,
        'source_url': sourceUrl,
        'verified': verified,
      };
}

class ScanPrediction {
  const ScanPrediction({
    required this.name,
    required this.visualFit,
    required this.reason,
    this.category = '',
    this.regionalLevel = 'none',
    this.regionalExplanation = '',
  });

  final String name;
  final int visualFit;
  final String reason;
  final String category;
  final String regionalLevel;
  final String regionalExplanation;

  Map<String, dynamic> toJson() => {
    'name': name,
    'visualFit': visualFit,
    'reason': reason,
    'category': category,
    'regionalLevel': regionalLevel,
    'regionalExplanation': regionalExplanation,
  };

  ScanPrediction copyWith({
    int? visualFit,
    String? regionalLevel,
    String? regionalExplanation,
  }) =>
      ScanPrediction(
        name: name,
        visualFit: visualFit ?? this.visualFit,
        reason: reason,
        category: category,
        regionalLevel: regionalLevel ?? this.regionalLevel,
        regionalExplanation: regionalExplanation ?? this.regionalExplanation,
      );
}

class ReferenceImage {
  const ReferenceImage({
    required this.src,
    required this.source,
    required this.license,
    required this.author,
    required this.provider,
  });

  final String src;
  final String source;
  final String license;
  final String author;
  final String provider;

  Map<String, dynamic> toJson() => {
    'src': src, 'source': source, 'license': license,
    'author': author, 'provider': provider,
  };

  factory ReferenceImage.fromJson(Map<String, dynamic> json) => ReferenceImage(
        src: (json['src'] ?? '').toString(),
        source: (json['source'] ?? '').toString(),
        license: (json['license'] ?? '').toString(),
        author: (json['author'] ?? '').toString(),
        provider: (json['provider'] ?? '').toString(),
      );
}

class CandidateComparison {
  const CandidateComparison({
    required this.candidateName,
    required this.verdict,
    required this.supports,
    required this.contradicts,
    required this.traditionalSummary,
    required this.traditionalClaims,
    this.reference,
    this.gallery = const [],
    this.referenceStatus = 'UNKNOWN',
  });

  final String candidateName;
  final String verdict;
  final List<String> supports;
  final List<String> contradicts;
  final String traditionalSummary;
  final List<String> traditionalClaims;
  final ReferenceImage? reference;
  final List<ReferenceImage> gallery;
  final String referenceStatus;

  Map<String, dynamic> toJson() => {
    'candidateName': candidateName,
    'verdict': verdict,
    'supports': supports,
    'contradicts': contradicts,
    'traditionalBeliefs': {'summary': traditionalSummary, 'claims': traditionalClaims},
    'reference': reference?.toJson(),
    'gallery': gallery.map((image) => image.toJson()).toList(),
    'referenceLibraryStatus': referenceStatus,
  };

  factory CandidateComparison.fromJson(Map<String, dynamic> json) {
    final beliefs = (json['traditionalBeliefs'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CandidateComparison(
      candidateName: (json['candidateName'] ?? '').toString(),
      verdict: (json['verdict'] ?? 'teilweise passend').toString(),
      supports: (json['supports'] as List? ?? const []).map((e) => e.toString()).toList(),
      contradicts: (json['contradicts'] as List? ?? const []).map((e) => e.toString()).toList(),
      traditionalSummary: (beliefs['summary'] ?? 'Keine kuratierte Zuschreibung vorhanden.').toString(),
      traditionalClaims: (beliefs['claims'] as List? ?? const []).map((e) => e.toString()).toList(),
      reference: json['reference'] is Map<String, dynamic>
          ? ReferenceImage.fromJson(json['reference'] as Map<String, dynamic>)
          : null,
      gallery: (json['gallery'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ReferenceImage.fromJson(e.cast<String, dynamic>()))
          .toList(),
      referenceStatus: (json['referenceLibraryStatus'] ?? 'UNKNOWN').toString(),
    );
  }
}

class RegionContext {
  const RegionContext({
    required this.supplied,
    required this.profileMatched,
    required this.regionName,
    required this.reason,
    required this.method,
    required this.sources,
    required this.ranking,
  });

  final bool supplied;
  final bool profileMatched;
  final String regionName;
  final String reason;
  final String method;
  final List<Map<String, dynamic>> sources;
  final List<Map<String, dynamic>> ranking;

  Map<String, dynamic> toJson() => {
    'supplied': supplied, 'profileMatched': profileMatched,
    'regionName': regionName, 'reason': reason, 'method': method,
    'sources': sources, 'regionalOrder': ranking,
  };

  factory RegionContext.fromJson(Map<String, dynamic> json) => RegionContext(
        supplied: json['supplied'] == true,
        profileMatched: json['profileMatched'] == true,
        regionName: (json['regionName'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        method: (json['method'] ?? '').toString(),
        sources: (json['sources'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
        ranking: (json['regionalOrder'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
      );

  static const empty = RegionContext(
    supplied: false,
    profileMatched: false,
    regionName: '',
    reason: 'Kein Standort verwendet.',
    method: '',
    sources: [],
    ranking: [],
  );
}

class ScanResult {
  const ScanResult({
    required this.candidates,
    required this.comparisons,
    required this.observations,
    required this.uncertainty,
    required this.needsMoreInfo,
    required this.region,
    required this.source,
  });

  final List<ScanPrediction> candidates;
  final List<CandidateComparison> comparisons;
  final List<String> observations;
  final String uncertainty;
  final List<String> needsMoreInfo;
  final RegionContext region;
  final String source;

  Map<String, dynamic> toJson() => {
    'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
    'candidateComparisons': comparisons.map((comparison) => comparison.toJson()).toList(),
    'observations': observations,
    'uncertainty': uncertainty,
    'needsMoreInfo': needsMoreInfo,
    'regionContext': region.toJson(),
    'source': source,
  };

  factory ScanResult.fromJson(Map<String, dynamic> json, {String? source}) => ScanResult(
        candidates: (json['candidates'] as List? ?? const []).whereType<Map>().map((item) {
          final m = item.cast<String, dynamic>();
          return ScanPrediction(
            name: (m['name'] ?? 'Unbekannt').toString(),
            visualFit: (m['visualFit'] as num? ?? 0).round().clamp(0, 100).toInt(),
            reason: (m['reason'] ?? '').toString(),
            category: (m['category'] ?? '').toString(),
            regionalLevel: (m['regionalLevel'] ?? 'none').toString(),
            regionalExplanation: (m['regionalExplanation'] ?? '').toString(),
          );
        }).toList(),
        comparisons: (json['candidateComparisons'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => CandidateComparison.fromJson(e.cast<String, dynamic>()))
            .toList(),
        observations: (json['observations'] as List? ?? const []).map((e) => e.toString()).toList(),
        uncertainty: (json['uncertainty'] ?? '').toString(),
        needsMoreInfo: (json['needsMoreInfo'] as List? ?? const []).map((e) => e.toString()).toList(),
        region: json['regionContext'] is Map
            ? RegionContext.fromJson((json['regionContext'] as Map).cast<String, dynamic>())
            : RegionContext.empty,
        source: source ?? (json['source'] ?? 'remote').toString(),
      );
}
