import 'dart:convert';
import 'dart:io';

class WorkspaceHygieneValidator {
  WorkspaceHygieneValidator({
    required this.rootDirectory,
  });

  final Directory rootDirectory;

  List<String> validate() {
    final issues = <String>[];
    final settings = _readSettings(issues);
    final watcherExclude = _toBoolMap(settings?['files.watcherExclude']);
    final searchExclude = _toBoolMap(settings?['search.exclude']);

    _validateAlwaysExcludes(issues, watcherExclude, searchExclude);

    final isFlutterProject = _isFlutterProject();
    final isPythonProject = _isPythonProject();
    final isNodeProject = _isNodeProject();

    if (isFlutterProject) {
      _validateToken(
        issues,
        map: watcherExclude,
        token: '.dart_tool',
        label: 'files.watcherExclude',
        reason: 'Flutter projects must exclude .dart_tool from watchers.',
      );
      _validateToken(
        issues,
        map: searchExclude,
        token: '.dart_tool',
        label: 'search.exclude',
        reason: 'Flutter projects must exclude .dart_tool from search.',
      );
      _validateToken(
        issues,
        map: watcherExclude,
        token: 'build',
        label: 'files.watcherExclude',
        reason: 'Flutter projects must exclude build outputs from watchers.',
      );
      _validateToken(
        issues,
        map: searchExclude,
        token: 'build',
        label: 'search.exclude',
        reason: 'Flutter projects must exclude build outputs from search.',
      );
      _validateGitignorePatterns(
        issues,
        patterns: const <String>[
          '.dart_tool/',
          'build/',
        ],
      );
    }

    if (isPythonProject) {
      _validateToken(
        issues,
        map: watcherExclude,
        token: '.venv',
        label: 'files.watcherExclude',
        reason: 'Python projects must exclude .venv from watchers.',
      );
      _validateToken(
        issues,
        map: searchExclude,
        token: '.venv',
        label: 'search.exclude',
        reason: 'Python projects must exclude .venv from search.',
      );
      _validateGitignorePatterns(
        issues,
        patterns: const <String>[
          '.venv/',
          'venv/',
          '__pycache__/',
          '.pytest_cache/',
          '.mypy_cache/',
        ],
      );
    }

    if (isNodeProject) {
      _validateToken(
        issues,
        map: watcherExclude,
        token: 'node_modules',
        label: 'files.watcherExclude',
        reason: 'Node projects must exclude node_modules from watchers.',
      );
      _validateToken(
        issues,
        map: searchExclude,
        token: 'node_modules',
        label: 'search.exclude',
        reason: 'Node projects must exclude node_modules from search.',
      );
      _validateGitignorePatterns(
        issues,
        patterns: const <String>[
          'node_modules/',
        ],
      );
    }

    _validateOutsideWorkspaceEnvPolicy(issues);
    return issues;
  }

  Map<String, dynamic>? _readSettings(List<String> issues) {
    const settingsPath = '.vscode/settings.json';
    final file = _file(settingsPath);
    if (!file.existsSync()) {
      issues.add('Missing required workspace settings file: $settingsPath');
      return null;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        issues.add('Workspace settings must be a JSON object: $settingsPath');
        return null;
      }
      return decoded;
    } catch (error) {
      issues.add('Workspace settings JSON is invalid ($settingsPath): $error');
      return null;
    }
  }

  void _validateAlwaysExcludes(
    List<String> issues,
    Map<String, bool> watcherExclude,
    Map<String, bool> searchExclude,
  ) {
    _validateToken(
      issues,
      map: watcherExclude,
      token: '.git',
      label: 'files.watcherExclude',
      reason: 'Always exclude .git from watchers.',
    );
    _validateToken(
      issues,
      map: watcherExclude,
      token: 'build',
      label: 'files.watcherExclude',
      reason: 'Always exclude build outputs from watchers.',
    );
    _validateToken(
      issues,
      map: searchExclude,
      token: 'build',
      label: 'search.exclude',
      reason: 'Always exclude build outputs from search.',
    );
  }

  void _validateToken(
    List<String> issues, {
    required Map<String, bool> map,
    required String token,
    required String label,
    required String reason,
  }) {
    final normalizedToken = token.toLowerCase();
    final hasMatch = map.entries.any((entry) {
      final key = _normalizePattern(entry.key);
      return entry.value && key.contains(normalizedToken);
    });
    if (!hasMatch) {
      issues.add('$reason Missing token "$token" in $label.');
    }
  }

  void _validateGitignorePatterns(
    List<String> issues, {
    required List<String> patterns,
  }) {
    final gitignoreFile = _file('.gitignore');
    if (!gitignoreFile.existsSync()) {
      issues.add('Missing required file: .gitignore');
      return;
    }
    final lines = gitignoreFile
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    for (final pattern in patterns) {
      final normalizedPattern = _normalizeGitignorePattern(pattern);
      final hasPattern = lines.any(
        (line) => _normalizeGitignorePattern(line) == normalizedPattern,
      );
      if (!hasPattern) {
        issues.add(
          '.gitignore is missing recommended pattern "$pattern" for detected stack.',
        );
      }
    }
  }

  void _validateOutsideWorkspaceEnvPolicy(List<String> issues) {
    if (!_outsideWorkspacePolicyEnabled()) {
      return;
    }
    final repoVenv = _directory('.venv');
    if (repoVenv.existsSync()) {
      issues.add(
        'Repository contains .venv/ but policy requires heavyweight environments outside repo root. '
        'Create external venv, verify imports, then remove .venv safely.',
      );
    }
  }

  bool _outsideWorkspacePolicyEnabled() {
    final manifest = _file('docs/assistant/manifest.json');
    if (!manifest.existsSync()) {
      return false;
    }
    try {
      final decoded = jsonDecode(manifest.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      final contracts = decoded['contracts'];
      if (contracts is! Map<String, dynamic>) {
        return false;
      }
      final policy = contracts['env_artifacts_outside_workspace_default'];
      return policy is String && policy.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _isFlutterProject() {
    final pubspec = _file('pubspec.yaml');
    if (!pubspec.existsSync()) {
      return false;
    }
    final text = pubspec.readAsStringSync().toLowerCase();
    return text.contains('flutter:');
  }

  bool _isPythonProject() {
    if (_directory('.venv').existsSync() || _directory('venv').existsSync()) {
      return true;
    }
    if (_file('pyproject.toml').existsSync() ||
        _file('requirements.txt').existsSync() ||
        _file('setup.py').existsSync()) {
      return true;
    }
    return _hasFileExtension('.py');
  }

  bool _isNodeProject() {
    return _file('package.json').existsSync();
  }

  bool _hasFileExtension(String extension) {
    final ignoredDirs = <String>{
      '.git',
      '.dart_tool',
      'build',
      '.venv',
      'venv',
      'node_modules',
    };
    final stack = <Directory>[rootDirectory];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      for (final entity in current.listSync()) {
        if (entity is Directory) {
          final name = entity.uri.pathSegments.isEmpty
              ? ''
              : entity.uri.pathSegments.last.replaceAll('/', '');
          if (ignoredDirs.contains(name)) {
            continue;
          }
          stack.add(entity);
          continue;
        }
        if (entity.path.toLowerCase().endsWith(extension.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, bool> _toBoolMap(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return const <String, bool>{};
    }
    final map = <String, bool>{};
    value.forEach((key, rawValue) {
      if (rawValue is bool) {
        map[key] = rawValue;
      }
    });
    return map;
  }

  String _normalizePattern(String input) {
    return input.replaceAll('\\', '/').toLowerCase();
  }

  String _normalizeGitignorePattern(String input) {
    var normalized = input.replaceAll('\\', '/').trim().toLowerCase();
    if (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    return normalized;
  }

  File _file(String relativePath) {
    return File(_join(rootDirectory.path, relativePath));
  }

  Directory _directory(String relativePath) {
    return Directory(_join(rootDirectory.path, relativePath));
  }
}

String _join(String root, String child) {
  final normalizedChild = child.replaceAll('/', Platform.pathSeparator);
  if (root.endsWith(Platform.pathSeparator)) {
    return '$root$normalizedChild';
  }
  return '$root${Platform.pathSeparator}$normalizedChild';
}

int main() {
  final validator = WorkspaceHygieneValidator(rootDirectory: Directory.current);
  final issues = validator.validate();
  if (issues.isEmpty) {
    stdout.writeln('Workspace hygiene validation passed.');
    return 0;
  }

  stderr.writeln(
    'Workspace hygiene validation failed (${issues.length} issue(s)):',
  );
  for (final issue in issues) {
    stderr.writeln('- $issue');
  }
  return 1;
}
