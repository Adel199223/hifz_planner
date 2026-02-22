import 'dart:convert';
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

  test('validator fails when CI workflow doc is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final missingWorkflow = File(
      _joinPath(fixture.path, 'docs/assistant/workflows/CI_REPO_WORKFLOW.md'),
    );
    missingWorkflow.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('CI_REPO_WORKFLOW.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when private template file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final templateFile = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
      ),
    );
    templateFile.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('CODEX_PROJECT_BOOTSTRAP_PROMPT.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest misses required ci_repo_ops workflow',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final workflows = (manifest['workflows'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((workflow) => workflow['id'] != 'ci_repo_ops')
        .toList();
    manifest['workflows'] = workflows;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Manifest must include required workflow id') &&
            issue.contains('ci_repo_ops'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when manifest misses required commit_publish_ops workflow',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final workflows = (manifest['workflows'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((workflow) => workflow['id'] != 'commit_publish_ops')
        .toList();
    manifest['workflows'] = workflows;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Manifest must include required workflow id') &&
            issue.contains('commit_publish_ops'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses template read-policy phrase', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    agentsFile.writeAsStringSync(
      [
        '# AGENTS',
        '',
        'This is a compatibility shim.',
      ].join('\n'),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('AGENTS.md must declare') &&
            issue.contains('templates'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when template path is added to manifest routing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final bridges = (manifest['bridges'] as List<dynamic>).cast<String>();
    bridges.add('docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md');
    manifest['bridges'] = bridges;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Template path must not appear in manifest bridges'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when template path is listed in INDEX.md', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final indexFile = File(_joinPath(fixture.path, 'docs/assistant/INDEX.md'));
    indexFile.writeAsStringSync(
      [
        '# INDEX',
        '',
        '- docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
      ].join('\n'),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('INDEX.md must not route private template files'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });
}

Directory _createValidFixture() {
  final root = Directory.systemTemp.createTempSync(
    'agent-docs-validator-fixture-',
  );

  void writeFile(String relativePath, String content) {
    final file = File(_joinPath(root.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  writeFile(
    'AGENTS.md',
    [
      '# AGENTS Compatibility Entry',
      '',
      'This is a compatibility shim.',
      'docs/assistant/templates/* is read-on-demand only.',
    ].join('\n'),
  );
  writeFile(
    'agent.md',
    [
      '# Agent Runbook',
      '',
      'AGENTS.md is a short shim for discovery.',
      'docs/assistant/templates/* is read-on-demand only.',
      'Only open templates when user explicitly requests template/prompt work.',
    ].join('\n'),
  );
  writeFile(
    'APP_KNOWLEDGE.md',
    [
      '# APP_KNOWLEDGE',
      '',
      'Canonical app brief: `APP_KNOWLEDGE.md`',
      'source code remains the final truth',
      'Why two `APP_KNOWLEDGE.md` files:',
    ].join('\n'),
  );
  writeFile('README.md', '# README');
  writeFile(
    '.github/workflows/dart.yml',
    [
      'name: CI',
      'on: [push]',
      'jobs:',
      '  verify:',
      '    runs-on: ubuntu-latest',
      '    steps: []',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/APP_KNOWLEDGE.md',
    [
      '# Assistant Bridge',
      '',
      'Root canonical wins',
      'if this file conflicts with `APP_KNOWLEDGE.md`',
      'intentionally shorter than the canonical root document',
    ].join('\n'),
  );
  writeFile('docs/assistant/DB_DRIFT_KNOWLEDGE.md', '# DB');
  writeFile('docs/assistant/INDEX.md', '# INDEX');
  writeFile(
    'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
    '# Template',
  );

  final workflowTemplate = _workflowTemplate();
  writeFile(
    'docs/assistant/workflows/READER_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/PLANNER_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    workflowTemplate,
  );

  writeFile('tooling/validate_agent_docs.dart', '// placeholder');
  writeFile('test/tooling/validate_agent_docs_test.dart', '// placeholder');

  final manifest = <String, dynamic>{
    'version': 4,
    'canonical': <String, dynamic>{
      'agent_runbook': 'agent.md',
      'app_knowledge': 'APP_KNOWLEDGE.md',
      'db_knowledge': 'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
    },
    'bridges': <String>[
      'AGENTS.md',
      'docs/assistant/APP_KNOWLEDGE.md',
    ],
    'workflows': <Map<String, dynamic>>[
      _manifestWorkflow(
        id: 'reader_ui',
        doc: 'docs/assistant/workflows/READER_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'qurancom_data_pipeline',
        doc: 'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'planner_scheduler',
        doc: 'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'ci_repo_ops',
        doc: 'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
        primaryFiles: <String>[
          '.github/workflows/dart.yml',
          'agent.md',
        ],
      ),
      _manifestWorkflow(
        id: 'commit_publish_ops',
        doc: 'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'docs_maintenance',
        doc: 'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
      ),
    ],
    'global_commands': <String, dynamic>{
      'bootstrap': <String>[
        'git status --short --branch',
      ],
      'analysis': <String>[
        'flutter analyze --no-fatal-infos --no-fatal-warnings',
      ],
      'tests': <String>[
        'flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart',
      ],
    },
    'contracts': <String, dynamic>{
      'canonical_precedence': 'canonical doc contract',
      'docs_sync_rule': 'docs sync contract',
      'windows_test_policy': 'windows test policy',
      'templates_read_policy':
          'docs/assistant/templates/* are read-on-demand only.',
    },
    'last_updated': '2026-02-22',
  };
  writeFile(
    'docs/assistant/manifest.json',
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  return root;
}

Map<String, dynamic> _manifestWorkflow({
  required String id,
  required String doc,
  List<String>? primaryFiles,
}) {
  return <String, dynamic>{
    'id': id,
    'doc': doc,
    'scope': 'workflow scope',
    'primary_files': primaryFiles ??
        <String>[
          'APP_KNOWLEDGE.md',
        ],
    'targeted_tests': <String>[
      'test/tooling/validate_agent_docs_test.dart',
    ],
    'validation_commands': <String>[
      'git status --short --branch',
      'flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart',
    ],
  };
}

String _workflowTemplate() {
  return [
    '## What This Workflow Is For',
    '',
    'Purpose.',
    '',
    '## When To Use',
    '',
    'When.',
    '',
    '## What Not To Do',
    '',
    'Do not.',
    '',
    '## Primary Files',
    '',
    '- APP_KNOWLEDGE.md',
    '',
    '## Minimal Commands',
    '',
    'git status --short --branch',
    '',
    '## Targeted Tests',
    '',
    'flutter test -j 1 -r expanded test/tooling/validate_agent_docs_test.dart',
    '',
    '## Failure Modes and Fallback Steps',
    '',
    'Fallback.',
    '',
    '## Handoff Checklist',
    '',
    'Done.',
  ].join('\n');
}

String _joinPath(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}
