import 'dart:convert';
import 'dart:io';

import 'package:gedcom_matcher/gedcom_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('GedcomParser', () {
    test('parses individuals and spouse link', () {
      const content = '''
0 @I1@ INDI
1 NAME Jean /Martin/
1 SEX M
1 BIRT
2 DATE 12 JAN 1900
2 PLAC Lyon
1 FAMS @F1@
0 @I2@ INDI
1 NAME Jeanne /Durand/
1 SEX F
1 FAMS @F1@
0 @F1@ FAM
1 HUSB @I1@
1 WIFE @I2@
0 TRLR
''';

      const parser = GedcomParser();
      final people = parser.parse(content);
      expect(people, hasLength(2));
      final jean = people.firstWhere((person) => person.id == 'I1');
      final jeanne = people.firstWhere((person) => person.id == 'I2');

      expect(jean.fullName, 'Jean Martin');
      expect(jean.spouseName, 'Jeanne Durand');
      expect(jean.birthDate, '12 JAN 1900');
      expect(jeanne.spouseName, 'Jean Martin');
    });

    test('parses realistic GEDCOM fixtures via adapter', () async {
      final fileA = File('test/fixtures/tree_a.ged');
      final fileB = File('test/fixtures/tree_b.ged');

      expect(await fileA.exists(), isTrue);
      expect(await fileB.exists(), isTrue);

      final contentA = await fileA.readAsString();
      final contentB = await fileB.readAsString();

      const parser = GedcomParser();
      final peopleA = parser.parse(contentA);
      final peopleB = parser.parse(contentB);

      expect(peopleA, hasLength(2));
      expect(peopleB, hasLength(2));

      final jeanA = peopleA.firstWhere((person) => person.id == 'I1');
      final jehanB = peopleB.firstWhere((person) => person.id == 'I9');

      expect(jeanA.fullName, 'Jean Martin');
      expect(jeanA.spouseName, 'Jeanne Durand');
      expect(jehanB.fullName, 'Jehan Martin');
      expect(jehanB.spouseName, 'Jeanne Durant');
      expect(jeanA.birthPlace, contains('Lyon'));
      expect(jehanB.birthPlace, contains('Lyon'));
    });
  });

  group('GedcomMatcher', () {
    test('high score for similar people', () {
      const left = PersonRecord(
        id: 'A1',
        givenName: 'Jean',
        surname: 'Dupont',
        sex: 'M',
        birthDate: '12 JAN 1900',
        birthPlace: 'Paris',
        spouseName: 'Marie Martin',
      );
      const right = PersonRecord(
        id: 'B1',
        givenName: 'Jehan',
        surname: 'Dupont',
        sex: 'M',
        birthDate: '12 JAN 1900',
        birthPlace: 'Paris',
        spouseName: 'Marie Martin',
      );

      const matcher = GedcomMatcher();
      final results = matcher.match(
        leftPeople: const [left],
        rightPeople: const [right],
        options: const MatchOptions(minConfidence: 70),
      );

      expect(results, hasLength(1));
      expect(results.first.confidence, greaterThanOrEqualTo(80));
    });

    test('keeps a good match with limited maxCandidatesPerPerson', () {
      const left = PersonRecord(
        id: 'A1',
        givenName: 'Jean',
        surname: 'Martin',
        sex: 'M',
        birthDate: '12 JAN 1900',
      );

      final rightPeople = <PersonRecord>[
        const PersonRecord(
          id: 'B1',
          givenName: 'Alice',
          surname: 'Martin',
          sex: 'F',
          birthDate: '01 JAN 1901',
        ),
        const PersonRecord(
          id: 'B2',
          givenName: 'Jehan',
          surname: 'Martin',
          sex: 'M',
          birthDate: '12 JAN 1900',
        ),
        const PersonRecord(
          id: 'B3',
          givenName: 'Louis',
          surname: 'Durand',
          sex: 'M',
          birthDate: '12 JAN 1900',
        ),
      ];

      const matcher = GedcomMatcher();
      final results = matcher.match(
        leftPeople: const [left],
        rightPeople: rightPeople,
        options: const MatchOptions(
          minConfidence: 70,
          maxCandidatesPerPerson: 1,
        ),
      );

      expect(results, hasLength(1));
      expect(results.first.right.id, 'B2');
      expect(results.first.confidence, greaterThanOrEqualTo(90));
    });
  });

  group('MatchOutputFormatter', () {
    const sampleResult = MatchResult(
      left: PersonRecord(id: 'A1', givenName: 'Jean', surname: 'Dupont'),
      right: PersonRecord(id: 'B1', givenName: 'Jean', surname: 'Dupond'),
      confidence: 84.5,
    );

    test('produces json csv markdown and table', () {
      const formatter = MatchOutputFormatter();
      final results = const [sampleResult];

      final json = formatter.format(
        results,
        OutputFormat.json,
        useColor: false,
      );
      final csv = formatter.format(results, OutputFormat.csv, useColor: false);
      final markdown = formatter.format(
        results,
        OutputFormat.markdown,
        useColor: false,
      );
      final table = formatter.format(
        results,
        OutputFormat.table,
        useColor: false,
      );

      expect(json, contains('confidence'));
      expect(json, contains('summary'));
      expect(csv, contains('left_id'));
      expect(csv, contains('summary_key,summary_value'));
      expect(markdown, contains('| Confidence |'));
      expect(markdown, contains('## Summary'));
      expect(table, contains('GEDCOM Matcher'));
      expect(table, contains('Summary:'));
    });
  });

  group('CLI', () {
    test('returns 0 with --help', () async {
      final code = await runCli(const ['--help']);
      expect(code, 0);
    });

    test('exports json based on extension', () async {
      final temp = await Directory.systemTemp.createTemp(
        'gedcom_matcher_test_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final leftFile = File('${temp.path}/left.ged');
      final rightFile = File('${temp.path}/right.ged');
      final outputFile = File('${temp.path}/results.json');

      await leftFile.writeAsString('''
0 @I1@ INDI
1 NAME Jean /Dupont/
1 SEX M
0 TRLR
''');

      await rightFile.writeAsString('''
0 @I2@ INDI
1 NAME Jean /Dupond/
1 SEX M
0 TRLR
''');

      final code = await runCli([
        '--format',
        'json',
        '--output',
        outputFile.path,
        leftFile.path,
        rightFile.path,
      ]);

      expect(code, 0);
      expect(await outputFile.exists(), isTrue);
      final exported = await outputFile.readAsString();
      final decoded = jsonDecode(exported) as Map<String, dynamic>;
      expect(decoded.containsKey('matches'), isTrue);
      expect(decoded.containsKey('summary'), isTrue);
      final matches = decoded['matches'] as List<dynamic>;
      expect(matches, isNotEmpty);
      final first = matches.first as Map<String, dynamic>;
      expect(first.containsKey('confidence'), isTrue);
      expect(first.containsKey('left'), isTrue);
      expect(first.containsKey('right'), isTrue);
      final summary = decoded['summary'] as Map<String, dynamic>;
      expect(summary['compared_people'], 1);
      expect(summary.containsKey('average_confidence'), isTrue);
      expect(summary.containsKey('confidence_100_count'), isTrue);
    });

    test(
      'accepts repeatable options with fixtures and markdown export',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'gedcom_matcher_test_e2e_',
        );
        addTearDown(() async {
          if (await temp.exists()) {
            await temp.delete(recursive: true);
          }
        });

        final outputFile = File('${temp.path}/matches.md');

        final code = await runCli([
          '--format',
          'table',
          '--format',
          'json',
          '--format',
          'csv',
          '--min-confidence',
          '60',
          '--output',
          outputFile.path,
          'test/fixtures/tree_a.ged',
          'test/fixtures/tree_b.ged',
        ]);

        expect(code, 0);
        expect(await outputFile.exists(), isTrue);
        final exported = await outputFile.readAsString();
        expect(exported, contains('| Confidence |'));
        expect(exported, contains('Jean Martin'));
        expect(exported, contains('Jehan Martin'));
        expect(exported, contains('## Summary'));
        expect(exported, contains('Compared people: 2'));
      },
    );

    test('exports csv with fixtures', () async {
      final temp = await Directory.systemTemp.createTemp(
        'gedcom_matcher_test_csv_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final outputFile = File('${temp.path}/matches.csv');

      final code = await runCli([
        '--format',
        'table',
        '--min-confidence',
        '60',
        '--output',
        outputFile.path,
        'test/fixtures/tree_a.ged',
        'test/fixtures/tree_b.ged',
      ]);

      expect(code, 0);
      expect(await outputFile.exists(), isTrue);
      final exported = await outputFile.readAsString();
      final lines = exported
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList(growable: false);

      expect(lines, isNotEmpty);
      expect(
        lines.first,
        'confidence,left_id,left_name,right_id,right_name,left_birth,right_birth,left_spouse,right_spouse',
      );
      expect(lines.length, greaterThanOrEqualTo(3));

      final firstDataColumns = lines[1].split(',');
      expect(firstDataColumns.length, 9);
      expect(exported, contains('Jean Martin'));
      expect(exported, contains('Jehan Martin'));
      expect(exported, contains('summary_key,summary_value'));
      expect(exported, contains('compared_people,2'));
    });

    test('exports json with fixtures', () async {
      final temp = await Directory.systemTemp.createTemp(
        'gedcom_matcher_test_json_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final outputFile = File('${temp.path}/matches.json');

      final code = await runCli([
        '--format',
        'markdown',
        '--min-confidence',
        '60',
        '--output',
        outputFile.path,
        'test/fixtures/tree_a.ged',
        'test/fixtures/tree_b.ged',
      ]);

      expect(code, 0);
      expect(await outputFile.exists(), isTrue);
      final exported = await outputFile.readAsString();
      final decoded = jsonDecode(exported) as Map<String, dynamic>;
      final matches = decoded['matches'] as List<dynamic>;
      expect(matches, hasLength(greaterThanOrEqualTo(2)));

      final first = matches.first as Map<String, dynamic>;
      final left = first['left'] as Map<String, dynamic>;
      final right = first['right'] as Map<String, dynamic>;

      expect(first['confidence'], isA<num>());
      expect(left['full_name'], isA<String>());
      expect(right['full_name'], isA<String>());
      expect(
        matches.any(
          (item) =>
              (item as Map<String, dynamic>)['left']['full_name'] ==
              'Jean Martin',
        ),
        isTrue,
      );
      expect(
        matches.any(
          (item) =>
              (item as Map<String, dynamic>)['right']['full_name'] ==
              'Jehan Martin',
        ),
        isTrue,
      );

      final summary = decoded['summary'] as Map<String, dynamic>;
      expect(summary['compared_people'], 2);
      expect(summary.containsKey('average_confidence'), isTrue);
      expect(summary.containsKey('confidence_100_count'), isTrue);
    });
  });
}
