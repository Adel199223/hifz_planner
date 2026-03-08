import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tooling/validate_workspace_hygiene.dart';

void main() {
  test('workspace hygiene validator passes for current repository', () {
    final validator =
        WorkspaceHygieneValidator(rootDirectory: Directory.current);
    final issues = validator.validate();
    expect(
      issues,
      isEmpty,
      reason: issues.isEmpty ? null : issues.join('\n'),
    );
  });

  test('validator fails when workspace settings miss required excludes', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final settingsFile = File(_join(fixture.path, '.vscode/settings.json'));
    settingsFile.writeAsStringSync('''
{
  "files.watcherExclude": {
    "**/.git/**": true
  },
  "search.exclude": {
    "**/.git/**": true
  }
}
''');

    final validator = WorkspaceHygieneValidator(rootDirectory: fixture);
    final issues = validator.validate();
    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing token "build"') ||
            issue.contains('Missing token ".dart_tool"'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when detected stack misses stack-specific excludes',
      () {
    final fixture = _createValidFixture(includePythonProject: true);
    addTearDown(() => fixture.deleteSync(recursive: true));

    final settingsFile = File(_join(fixture.path, '.vscode/settings.json'));
    settingsFile.writeAsStringSync('''
{
  "files.watcherExclude": {
    "**/.git/**": true,
    "**/build/**": true,
    "**/.dart_tool/**": true
  },
  "search.exclude": {
    "**/build/**": true,
    "**/.dart_tool/**": true
  }
}
''');

    final validator = WorkspaceHygieneValidator(rootDirectory: fixture);
    final issues = validator.validate();
    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing token ".venv"') ||
            issue
                .contains('.gitignore is missing recommended pattern ".venv/"'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when outside-workspace policy is enabled and root .venv exists',
      () {
    final fixture = _createValidFixture(includePythonProject: true);
    addTearDown(() => fixture.deleteSync(recursive: true));

    Directory(_join(fixture.path, '.venv')).createSync(recursive: true);

    final validator = WorkspaceHygieneValidator(rootDirectory: fixture);
    final issues = validator.validate();
    expect(
      issues.any(
        (issue) => issue.contains('Repository contains .venv/'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });
}

Directory _createValidFixture({bool includePythonProject = false}) {
  final root = Directory.systemTemp.createTempSync(
    'workspace-hygiene-validator-fixture-',
  );

  void writeFile(String relativePath, String content) {
    final file = File(_join(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  writeFile(
    '.vscode/settings.json',
    '''
{
  "files.watcherExclude": {
    "**/.git/**": true,
    "**/.dart_tool/**": true,
    "**/build/**": true,
    "**/.venv/**": true
  },
  "search.exclude": {
    "**/.dart_tool/**": true,
    "**/build/**": true,
    "**/.venv/**": true
  }
}
''',
  );

  writeFile(
    '.gitignore',
    '''
.dart_tool/
build/
.venv/
venv/
__pycache__/
.pytest_cache/
.mypy_cache/
''',
  );

  writeFile(
    'pubspec.yaml',
    '''
name: fixture
dependencies:
  flutter:
    sdk: flutter
''',
  );

  writeFile(
    'docs/assistant/manifest.json',
    '''
{
  "contracts": {
    "env_artifacts_outside_workspace_default": "Heavyweight environments and generated runtime artifacts should live outside repo root when feasible."
  }
}
''',
  );

  if (includePythonProject) {
    writeFile('pyproject.toml', '[project]\nname = "fixture"\n');
  }

  return root;
}

String _join(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}
