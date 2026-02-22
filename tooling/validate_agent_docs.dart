import 'dart:convert';
import 'dart:io';

const List<String> _requiredFiles = <String>[
  'AGENTS.md',
  'agent.md',
  'APP_KNOWLEDGE.md',
  'README.md',
  'docs/assistant/APP_KNOWLEDGE.md',
  'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
  'docs/assistant/INDEX.md',
  'docs/assistant/manifest.json',
  'docs/assistant/workflows/READER_WORKFLOW.md',
  'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
  'docs/assistant/workflows/PLANNER_WORKFLOW.md',
  'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
];

const List<String> _workflowRequiredSections = <String>[
  '## What This Workflow Is For',
  '## When To Use',
  '## What Not To Do',
  '## Primary Files',
  '## Minimal Commands',
  '## Targeted Tests',
  '## Failure Modes and Fallback Steps',
  '## Handoff Checklist',
];

const List<String> _docsToScanForBackticks = <String>[
  'AGENTS.md',
  'agent.md',
  'APP_KNOWLEDGE.md',
  'README.md',
  'docs/assistant/APP_KNOWLEDGE.md',
  'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
  'docs/assistant/INDEX.md',
  'docs/assistant/workflows/READER_WORKFLOW.md',
  'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
  'docs/assistant/workflows/PLANNER_WORKFLOW.md',
  'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
];

final RegExp _backtickRegex = RegExp(r'`([^`\n]+)`');
final RegExp _pathLikeRegex = RegExp(
  r'^(AGENTS\.md|agent\.md|APP_KNOWLEDGE\.md|README\.md|docs/|lib/|test/|tooling/|assets/)',
);

class AgentDocsValidator {
  AgentDocsValidator({
    required this.rootDirectory,
  });

  final Directory rootDirectory;

  List<String> validate() {
    final issues = <String>[];
    _validateRequiredFiles(issues);
    _validateManifest(issues);
    _validateWorkflowSections(issues);
    _validateCanonicalContracts(issues);
    _validateBacktickPaths(issues);
    return issues;
  }

  void _validateRequiredFiles(List<String> issues) {
    for (final relativePath in _requiredFiles) {
      if (!_exists(relativePath)) {
        issues.add('Missing required file: $relativePath');
      }
    }
  }

  void _validateManifest(List<String> issues) {
    const manifestPath = 'docs/assistant/manifest.json';
    final file = _resolveFile(manifestPath);
    if (!file.existsSync()) {
      issues.add('Manifest missing: $manifestPath');
      return;
    }

    Map<String, dynamic> manifest;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        issues.add('Manifest root must be a JSON object.');
        return;
      }
      manifest = decoded;
    } catch (error) {
      issues.add('Manifest is invalid JSON: $error');
      return;
    }

    final version = manifest['version'];
    if (version is! int) {
      issues.add('Manifest key "version" must be an integer.');
    }

    final canonical = manifest['canonical'];
    if (canonical is! Map<String, dynamic>) {
      issues.add('Manifest key "canonical" must be an object.');
    } else {
      _validateManifestPathValue(
        issues,
        canonical,
        key: 'agent_runbook',
        label: 'canonical.agent_runbook',
      );
      _validateManifestPathValue(
        issues,
        canonical,
        key: 'app_knowledge',
        label: 'canonical.app_knowledge',
      );
      _validateManifestPathValue(
        issues,
        canonical,
        key: 'db_knowledge',
        label: 'canonical.db_knowledge',
      );
    }

    final bridges = manifest['bridges'];
    if (bridges is! List) {
      issues.add('Manifest key "bridges" must be an array.');
    } else {
      for (var i = 0; i < bridges.length; i++) {
        final value = bridges[i];
        if (value is! String || value.trim().isEmpty) {
          issues.add('Manifest bridges[$i] must be a non-empty string path.');
          continue;
        }
        if (!_exists(value)) {
          issues.add('Manifest bridge path does not exist: $value');
        }
      }
    }

    final workflows = manifest['workflows'];
    if (workflows is! List) {
      issues.add('Manifest key "workflows" must be an array.');
    } else {
      for (var i = 0; i < workflows.length; i++) {
        final value = workflows[i];
        if (value is! Map<String, dynamic>) {
          issues.add('Manifest workflows[$i] must be an object.');
          continue;
        }
        _validateManifestWorkflow(issues, value, index: i);
      }
    }

    final globalCommands = manifest['global_commands'];
    if (globalCommands is! Map<String, dynamic>) {
      issues.add('Manifest key "global_commands" must be an object.');
    } else {
      _validateStringList(
        issues,
        globalCommands['bootstrap'],
        'global_commands.bootstrap',
      );
      _validateStringList(
        issues,
        globalCommands['analysis'],
        'global_commands.analysis',
      );
      _validateStringList(
        issues,
        globalCommands['tests'],
        'global_commands.tests',
      );
    }

    final contracts = manifest['contracts'];
    if (contracts is! Map<String, dynamic>) {
      issues.add('Manifest key "contracts" must be an object.');
    } else {
      _validateNonEmptyString(
        issues,
        contracts['canonical_precedence'],
        'contracts.canonical_precedence',
      );
      _validateNonEmptyString(
        issues,
        contracts['docs_sync_rule'],
        'contracts.docs_sync_rule',
      );
      _validateNonEmptyString(
        issues,
        contracts['windows_test_policy'],
        'contracts.windows_test_policy',
      );
    }

    final lastUpdated = manifest['last_updated'];
    if (lastUpdated is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(lastUpdated.trim())) {
      issues.add(
        'Manifest key "last_updated" must use YYYY-MM-DD format.',
      );
    }
  }

  void _validateManifestWorkflow(
    List<String> issues,
    Map<String, dynamic> workflow, {
    required int index,
  }) {
    _validateNonEmptyString(issues, workflow['id'], 'workflows[$index].id');
    _validateNonEmptyString(issues, workflow['scope'], 'workflows[$index].scope');

    final doc = workflow['doc'];
    if (doc is! String || doc.trim().isEmpty) {
      issues.add('workflows[$index].doc must be a non-empty string path.');
    } else if (!_exists(doc)) {
      issues.add('Workflow doc path does not exist: $doc');
    }

    _validatePathList(
      issues,
      workflow['primary_files'],
      'workflows[$index].primary_files',
    );
    _validatePathList(
      issues,
      workflow['targeted_tests'],
      'workflows[$index].targeted_tests',
    );
    _validateStringList(
      issues,
      workflow['validation_commands'],
      'workflows[$index].validation_commands',
    );
  }

  void _validateWorkflowSections(List<String> issues) {
    const workflowDocs = <String>[
      'docs/assistant/workflows/READER_WORKFLOW.md',
      'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
      'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    ];
    for (final relativePath in workflowDocs) {
      final file = _resolveFile(relativePath);
      if (!file.existsSync()) {
        continue;
      }
      final content = file.readAsStringSync();
      for (final section in _workflowRequiredSections) {
        if (!content.contains(section)) {
          issues.add(
            'Workflow doc missing required section "$section": $relativePath',
          );
        }
      }
    }
  }

  void _validateCanonicalContracts(List<String> issues) {
    final appKnowledge = _resolveFile('APP_KNOWLEDGE.md');
    if (appKnowledge.existsSync()) {
      final text = appKnowledge.readAsStringSync();
      if (!text.contains('Canonical app brief: `APP_KNOWLEDGE.md`')) {
        issues.add(
          'APP_KNOWLEDGE.md must declare canonical app brief contract.',
        );
      }
      if (!text.contains('source code remains the final truth')) {
        issues.add(
          'APP_KNOWLEDGE.md must state that source code is final truth.',
        );
      }
    }

    final bridge = _resolveFile('docs/assistant/APP_KNOWLEDGE.md');
    if (bridge.existsSync()) {
      final text = bridge.readAsStringSync();
      if (!text.contains('Root canonical wins')) {
        issues.add(
          'docs/assistant/APP_KNOWLEDGE.md must include "Root canonical wins".',
        );
      }
      if (!text.contains('if this file conflicts with `APP_KNOWLEDGE.md`')) {
        issues.add(
          'Bridge doc must include explicit conflict rule for APP_KNOWLEDGE.md.',
        );
      }
    }
  }

  void _validateBacktickPaths(List<String> issues) {
    for (final relativePath in _docsToScanForBackticks) {
      final file = _resolveFile(relativePath);
      if (!file.existsSync()) {
        continue;
      }
      final text = file.readAsStringSync();
      for (final match in _backtickRegex.allMatches(text)) {
        final token = match.group(1)?.trim() ?? '';
        if (token.isEmpty || !_pathLikeRegex.hasMatch(token)) {
          continue;
        }
        if (!_pathTokenExists(token)) {
          issues.add('Backtick path not found in $relativePath: $token');
        }
      }
    }
  }

  void _validateManifestPathValue(
    List<String> issues,
    Map<String, dynamic> map, {
    required String key,
    required String label,
  }) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      issues.add('Manifest key "$label" must be a non-empty string path.');
      return;
    }
    if (!_exists(value)) {
      issues.add('Manifest path does not exist for "$label": $value');
    }
  }

  void _validatePathList(
    List<String> issues,
    dynamic value,
    String label,
  ) {
    if (value is! List) {
      issues.add('Manifest key "$label" must be an array of paths.');
      return;
    }
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! String || entry.trim().isEmpty) {
        issues.add('$label[$i] must be a non-empty string path.');
        continue;
      }
      if (!_pathTokenExists(entry)) {
        issues.add('$label[$i] path does not exist: $entry');
      }
    }
  }

  void _validateStringList(
    List<String> issues,
    dynamic value,
    String label,
  ) {
    if (value is! List) {
      issues.add('Manifest key "$label" must be an array of strings.');
      return;
    }
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! String || entry.trim().isEmpty) {
        issues.add('$label[$i] must be a non-empty string.');
      }
    }
  }

  void _validateNonEmptyString(
    List<String> issues,
    dynamic value,
    String label,
  ) {
    if (value is! String || value.trim().isEmpty) {
      issues.add('Manifest key "$label" must be a non-empty string.');
    }
  }

  bool _pathTokenExists(String token) {
    final normalized = token.replaceAll('/', Platform.pathSeparator);
    if (!normalized.contains('*')) {
      return _exists(normalized);
    }

    final segments = normalized.split(Platform.pathSeparator);
    if (segments.isEmpty) {
      return false;
    }
    final pattern = segments.removeLast();
    final dirPath = segments.join(Platform.pathSeparator);
    final dir = _resolveDirectory(dirPath);
    if (!dir.existsSync()) {
      return false;
    }

    final regex = RegExp(
      '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$',
      caseSensitive: false,
    );
    for (final entity in dir.listSync()) {
      final name = entity.uri.pathSegments.isEmpty
          ? ''
          : entity.uri.pathSegments.last.replaceAll('/', '');
      if (regex.hasMatch(name)) {
        return true;
      }
    }
    return false;
  }

  bool _exists(String relativePath) {
    final file = _resolveFile(relativePath);
    if (file.existsSync()) {
      return true;
    }
    return _resolveDirectory(relativePath).existsSync();
  }

  File _resolveFile(String relativePath) {
    return File(_join(rootDirectory.path, relativePath));
  }

  Directory _resolveDirectory(String relativePath) {
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
  final validator = AgentDocsValidator(
    rootDirectory: Directory.current,
  );
  final issues = validator.validate();
  if (issues.isEmpty) {
    stdout.writeln('Agent docs validation passed.');
    return 0;
  }

  stderr.writeln('Agent docs validation failed (${issues.length} issue(s)):');
  for (final issue in issues) {
    stderr.writeln('- $issue');
  }
  return 1;
}
