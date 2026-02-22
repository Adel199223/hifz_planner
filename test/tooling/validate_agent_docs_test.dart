import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tooling/validate_agent_docs.dart';

void main() {
  test('agent docs validator passes for current repository docs', () {
    final validator = AgentDocsValidator(
      rootDirectory: Directory.current,
    );
    final issues = validator.validate();
    expect(
      issues,
      isEmpty,
      reason: issues.isEmpty ? null : issues.join('\n'),
    );
  });
}
