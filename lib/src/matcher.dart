import 'models.dart';
import 'normalizer.dart';

/// Callback invoked as matching progresses.
///
/// `current` is 1-based and `total` is the number of left-side people.
typedef ProgressCallback = void Function(int current, int total);

/// Computes best person matches between two GEDCOM datasets.
class GedcomMatcher {
  /// Creates a matching engine instance.
  const GedcomMatcher();

  /// Matches `leftPeople` against `rightPeople` and returns best matches.
  ///
  /// The result list contains at most one best candidate per left-side person,
  /// filtered by `options.minConfidence`, and sorted by descending confidence.
  List<MatchResult> match({
    required List<PersonRecord> leftPeople,
    required List<PersonRecord> rightPeople,
    required MatchOptions options,
    ProgressCallback? onProgress,
  }) {
    if (leftPeople.isEmpty || rightPeople.isEmpty) {
      return const <MatchResult>[];
    }

    final preparedRight = rightPeople
        .map(_PreparedPerson.fromPerson)
        .toList(growable: false);
    final indexes = _CandidateIndexes.build(preparedRight);

    final results = <MatchResult>[];
    final total = leftPeople.length;

    for (var index = 0; index < leftPeople.length; index++) {
      final left = _PreparedPerson.fromPerson(leftPeople[index]);
      MatchResult? best;
      final candidates = _selectCandidates(
        left: left,
        preparedRight: preparedRight,
        indexes: indexes,
        maxCandidatesPerPerson: options.maxCandidatesPerPerson,
      );

      for (final right in candidates) {
        final confidence = _confidence(left, right, options.weights);
        if (best == null || confidence > best.confidence) {
          best = MatchResult(
            left: left.person,
            right: right.person,
            confidence: confidence,
          );
        }
      }

      if (best != null && best.confidence >= options.minConfidence) {
        results.add(best);
      }

      onProgress?.call(index + 1, total);
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  List<_PreparedPerson> _selectCandidates({
    required _PreparedPerson left,
    required List<_PreparedPerson> preparedRight,
    required _CandidateIndexes indexes,
    required int maxCandidatesPerPerson,
  }) {
    final candidatesById = <String, _PreparedPerson>{};

    void addAll(Iterable<_PreparedPerson> values) {
      for (final value in values) {
        candidatesById[value.person.id] = value;
      }
    }

    if (left.surnameKey.isNotEmpty) {
      addAll(indexes.bySurname[left.surnameKey] ?? const <_PreparedPerson>[]);
    }

    if (left.birthYear != null && left.surnameKey.isNotEmpty) {
      final key = '${left.birthYear}|${left.surnameKey}';
      addAll(indexes.byBirthYearAndSurname[key] ?? const <_PreparedPerson>[]);
    }

    if (left.sex.isNotEmpty && left.surnameKey.isNotEmpty) {
      final key = '${left.sex}|${left.surnameKey}';
      addAll(indexes.bySexAndSurname[key] ?? const <_PreparedPerson>[]);
    }

    if (candidatesById.isEmpty && left.surnamePrefix.isNotEmpty) {
      addAll(
        indexes.bySurnamePrefix[left.surnamePrefix] ??
            const <_PreparedPerson>[],
      );
    }

    var candidates = candidatesById.values.toList(growable: false);
    if (candidates.isEmpty) {
      candidates = preparedRight;
    }

    if (maxCandidatesPerPerson > 0 &&
        candidates.length > maxCandidatesPerPerson) {
      final sorted = [...candidates]
        ..sort(
          (a, b) => _cheapScore(
            left: left,
            right: b,
          ).compareTo(_cheapScore(left: left, right: a)),
        );
      return sorted.take(maxCandidatesPerPerson).toList(growable: false);
    }

    return candidates;
  }

  int _cheapScore({
    required _PreparedPerson left,
    required _PreparedPerson right,
  }) {
    var score = 0;
    if (left.normalizedName == right.normalizedName) {
      score += 60;
    } else if (left.surnameKey.isNotEmpty &&
        left.surnameKey == right.surnameKey) {
      score += 25;
    }

    if (left.birthYear != null && left.birthYear == right.birthYear) {
      score += 20;
    }
    if (left.sex.isNotEmpty && left.sex == right.sex) {
      score += 10;
    }
    if (left.normalizedSpouse.isNotEmpty &&
        left.normalizedSpouse == right.normalizedSpouse) {
      score += 10;
    }
    if (left.normalizedBirthPlace.isNotEmpty &&
        left.normalizedBirthPlace == right.normalizedBirthPlace) {
      score += 5;
    }
    return score;
  }

  double _confidence(
    _PreparedPerson left,
    _PreparedPerson right,
    MatchWeights weights,
  ) {
    var weightedScore = 0.0;
    var availableWeight = 0;

    void apply(
      int weight,
      String? leftValue,
      String? rightValue,
      double Function(String, String) scorer,
    ) {
      if (weight <= 0) {
        return;
      }
      final a = (leftValue ?? '').trim();
      final b = (rightValue ?? '').trim();
      if (a.isEmpty || b.isEmpty) {
        return;
      }
      final score = scorer(a, b);
      availableWeight += weight;
      weightedScore += score * weight;
    }

    apply(
      weights.name,
      left.normalizedName,
      right.normalizedName,
      _stringSimilarityNormalized,
    );

    apply(
      weights.birthDate,
      left.normalizedBirthDate,
      right.normalizedBirthDate,
      _dateSimilarityNormalized,
    );
    apply(
      weights.birthPlace,
      left.normalizedBirthPlace,
      right.normalizedBirthPlace,
      _stringSimilarityNormalized,
    );
    apply(
      weights.deathDate,
      left.normalizedDeathDate,
      right.normalizedDeathDate,
      _dateSimilarityNormalized,
    );
    apply(weights.sex, left.sex, right.sex, (a, b) => a == b ? 1 : 0);
    apply(
      weights.spouse,
      left.normalizedSpouse,
      right.normalizedSpouse,
      _stringSimilarityNormalized,
    );

    if (availableWeight == 0) {
      return 0;
    }

    final score = (weightedScore / availableWeight) * 100;
    return double.parse(score.toStringAsFixed(2));
  }

  double _dateSimilarityNormalized(String a, String b) {
    if (a == b) {
      return 1;
    }

    final yearA = _extractYear(a);
    final yearB = _extractYear(b);
    if (yearA != null && yearB != null && yearA == yearB) {
      return 0.7;
    }

    return _stringSimilarityNormalized(a, b);
  }

  int? _extractYear(String value) {
    final match = RegExp(r'\b(1[5-9]\d{2}|20\d{2})\b').firstMatch(value);
    return match == null ? null : int.parse(match.group(1)!);
  }

  double _stringSimilarityNormalized(String left, String right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    if (left == right) {
      return 1;
    }

    final maxLength = left.length > right.length ? left.length : right.length;
    final lengthGap = (left.length - right.length).abs();
    if (lengthGap > (maxLength / 2).floor()) {
      return (maxLength - lengthGap) / maxLength;
    }

    final distance = _levenshtein(left, right);
    return (maxLength - distance) / maxLength;
  }

  int _levenshtein(String source, String target) {
    final rows = source.length + 1;
    final cols = target.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var row = 0; row < rows; row++) {
      matrix[row][0] = row;
    }
    for (var col = 0; col < cols; col++) {
      matrix[0][col] = col;
    }

    for (var row = 1; row < rows; row++) {
      for (var col = 1; col < cols; col++) {
        final cost = source[row - 1] == target[col - 1] ? 0 : 1;
        matrix[row][col] = [
          matrix[row - 1][col] + 1,
          matrix[row][col - 1] + 1,
          matrix[row - 1][col - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[rows - 1][cols - 1];
  }
}

class _CandidateIndexes {
  const _CandidateIndexes({
    required this.bySurname,
    required this.byBirthYearAndSurname,
    required this.bySexAndSurname,
    required this.bySurnamePrefix,
  });

  final Map<String, List<_PreparedPerson>> bySurname;
  final Map<String, List<_PreparedPerson>> byBirthYearAndSurname;
  final Map<String, List<_PreparedPerson>> bySexAndSurname;
  final Map<String, List<_PreparedPerson>> bySurnamePrefix;

  static _CandidateIndexes build(List<_PreparedPerson> people) {
    final bySurname = <String, List<_PreparedPerson>>{};
    final byBirthYearAndSurname = <String, List<_PreparedPerson>>{};
    final bySexAndSurname = <String, List<_PreparedPerson>>{};
    final bySurnamePrefix = <String, List<_PreparedPerson>>{};

    for (final person in people) {
      if (person.surnameKey.isNotEmpty) {
        bySurname
            .putIfAbsent(person.surnameKey, () => <_PreparedPerson>[])
            .add(person);
      }

      if (person.birthYear != null && person.surnameKey.isNotEmpty) {
        final key = '${person.birthYear}|${person.surnameKey}';
        byBirthYearAndSurname
            .putIfAbsent(key, () => <_PreparedPerson>[])
            .add(person);
      }

      if (person.sex.isNotEmpty && person.surnameKey.isNotEmpty) {
        final key = '${person.sex}|${person.surnameKey}';
        bySexAndSurname.putIfAbsent(key, () => <_PreparedPerson>[]).add(person);
      }

      if (person.surnamePrefix.isNotEmpty) {
        bySurnamePrefix
            .putIfAbsent(person.surnamePrefix, () => <_PreparedPerson>[])
            .add(person);
      }
    }

    return _CandidateIndexes(
      bySurname: bySurname,
      byBirthYearAndSurname: byBirthYearAndSurname,
      bySexAndSurname: bySexAndSurname,
      bySurnamePrefix: bySurnamePrefix,
    );
  }
}

class _PreparedPerson {
  _PreparedPerson._({
    required this.person,
    required this.normalizedName,
    required this.normalizedBirthDate,
    required this.normalizedBirthPlace,
    required this.normalizedDeathDate,
    required this.normalizedSpouse,
    required this.surnameKey,
    required this.surnamePrefix,
    required this.sex,
    required this.birthYear,
  });

  final PersonRecord person;
  final String normalizedName;
  final String normalizedBirthDate;
  final String normalizedBirthPlace;
  final String normalizedDeathDate;
  final String normalizedSpouse;
  final String surnameKey;
  final String surnamePrefix;
  final String sex;
  final int? birthYear;

  static _PreparedPerson fromPerson(PersonRecord person) {
    final normalizedBirthDate = normalizeText(person.birthDate ?? '');
    final normalizedSurname = normalizeText(person.surname);

    return _PreparedPerson._(
      person: person,
      normalizedName: normalizeName(person.givenName, person.surname),
      normalizedBirthDate: normalizedBirthDate,
      normalizedBirthPlace: normalizeText(person.birthPlace ?? ''),
      normalizedDeathDate: normalizeText(person.deathDate ?? ''),
      normalizedSpouse: normalizeText(person.spouseName ?? ''),
      surnameKey: normalizedSurname,
      surnamePrefix: _prefix(normalizedSurname),
      sex: (person.sex ?? '').trim().toUpperCase(),
      birthYear: _extractYear(normalizedBirthDate),
    );
  }

  static String _prefix(String value) {
    if (value.isEmpty) {
      return '';
    }
    return value.length <= 3 ? value : value.substring(0, 3);
  }

  static int? _extractYear(String value) {
    final match = RegExp(r'\b(1[5-9]\d{2}|20\d{2})\b').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1) ?? '');
  }
}
