import 'package:gedcom_parser/gedcom_parser.dart' as gp;

import 'models.dart';

class GedcomParser {
  const GedcomParser();

  List<PersonRecord> parse(String content) {
    final parser = gp.GedcomParser();
    final lines = content.split(RegExp(r'\r?\n'));
    final data = parser.parseLines(lines);

    final recordsById = <String, PersonRecord>{};
    for (final entry in data.persons.entries) {
      final person = entry.value;
      recordsById[entry.key] = PersonRecord(
        id: person.id,
        givenName: person.firstName,
        surname: person.lastName,
        sex: person.sex,
        birthDate: person.birthDate,
        birthPlace: person.birthPlace,
        deathDate: person.deathDate,
        deathPlace: person.deathPlace,
      );
    }

    final spouseNamesById = <String, Set<String>>{};
    for (final family in data.families.values) {
      _linkSpouse(
        spouseNamesById: spouseNamesById,
        recordsById: recordsById,
        personId: family.husbandId,
        spouseId: family.wifeId,
      );
      _linkSpouse(
        spouseNamesById: spouseNamesById,
        recordsById: recordsById,
        personId: family.wifeId,
        spouseId: family.husbandId,
      );
    }

    return recordsById.values
        .map((record) {
          final spouseNames = spouseNamesById[record.id];
          return PersonRecord(
            id: record.id,
            givenName: record.givenName,
            surname: record.surname,
            sex: record.sex,
            birthDate: record.birthDate,
            birthPlace: record.birthPlace,
            deathDate: record.deathDate,
            deathPlace: record.deathPlace,
            spouseName: _joinedSpouseNames(spouseNames),
          );
        })
        .toList(growable: false);
  }

  void _linkSpouse({
    required Map<String, Set<String>> spouseNamesById,
    required Map<String, PersonRecord> recordsById,
    required String? personId,
    required String? spouseId,
  }) {
    if (personId == null || spouseId == null) {
      return;
    }

    final spouse = recordsById[spouseId];
    if (spouse == null || spouse.fullName.isEmpty) {
      return;
    }

    spouseNamesById
        .putIfAbsent(personId, () => <String>{})
        .add(spouse.fullName);
  }

  String? _joinedSpouseNames(Set<String>? spouseNames) {
    if (spouseNames == null || spouseNames.isEmpty) {
      return null;
    }
    final sorted = spouseNames.toList()..sort();
    return sorted.join(', ');
  }
}
