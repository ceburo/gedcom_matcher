import 'dart:io';

import 'package:gedcom_matcher/gedcom_matcher.dart';

Future<void> main(List<String> arguments) async {
  final code = await runCli(arguments);
  exit(code);
}
