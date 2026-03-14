import 'package:gedcom_matcher/gedcom_matcher.dart';

void main() {
  const parser = GedcomParser();
  const matcher = GedcomMatcher();
  const formatter = MatchOutputFormatter();

  const leftGedcom = '''
0 @I1@ INDI
1 NAME Jean /Dupont/
1 SEX M
1 BIRT
2 DATE 12 JAN 1900
2 PLAC Paris
0 TRLR
''';

  const rightGedcom = '''
0 @I2@ INDI
1 NAME Jehan /Dupont/
1 SEX M
1 BIRT
2 DATE 12 JAN 1900
2 PLAC Paris
0 TRLR
''';

  final leftPeople = parser.parse(leftGedcom);
  final rightPeople = parser.parse(rightGedcom);
  final results = matcher.match(
    leftPeople: leftPeople,
    rightPeople: rightPeople,
    options: const MatchOptions(minConfidence: 70),
  );

  print(formatter.format(results, OutputFormat.table, useColor: false));
}
