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

  for (final missingFileCase in <Map<String, String>>[
    <String, String>{
      'description': 'issue memory markdown file',
      'path': 'docs/assistant/ISSUE_MEMORY.md',
      'needle': 'ISSUE_MEMORY.md',
    },
    <String, String>{
      'description': 'issue memory json file',
      'path': 'docs/assistant/ISSUE_MEMORY.json',
      'needle': 'ISSUE_MEMORY.json',
    },
    <String, String>{
      'description': 'local env profile example file',
      'path': 'docs/assistant/LOCAL_ENV_PROFILE.example.md',
      'needle': 'LOCAL_ENV_PROFILE.example.md',
    },
    <String, String>{
      'description': 'local capabilities file',
      'path': 'docs/assistant/LOCAL_CAPABILITIES.md',
      'needle': 'LOCAL_CAPABILITIES.md',
    },
    <String, String>{
      'description': 'worktree build identity workflow doc',
      'path': 'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
      'needle': 'WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
    },
    <String, String>{
      'description': 'roadmap workflow doc',
      'path': 'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
      'needle': 'ROADMAP_WORKFLOW.md',
    },
    <String, String>{
      'description': 'bootstrap roadmap governance template',
      'path': 'docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
      'needle': 'BOOTSTRAP_ROADMAP_GOVERNANCE.md',
    },
  ]) {
    test('validator fails when ${missingFileCase['description']} is missing',
        () {
      final fixture = _createValidFixture();
      addTearDown(() => fixture.deleteSync(recursive: true));

      final file = File(_joinPath(fixture.path, missingFileCase['path']!));
      file.deleteSync();

      final validator = AgentDocsValidator(rootDirectory: fixture);
      final issues = validator.validate();

      expect(
        issues.any(
          (issue) =>
              issue.contains('Missing required file:') &&
              issue.contains(missingFileCase['needle']!),
        ),
        isTrue,
        reason: issues.join('\n'),
      );
    });
  }

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

  test(
      'validator fails when manifest misses required localization_i18n workflow',
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
        .where((workflow) => workflow['id'] != 'localization_i18n')
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
            issue.contains('localization_i18n'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest misses workspace_performance workflow',
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
        .where((workflow) => workflow['id'] != 'workspace_performance')
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
            issue.contains('workspace_performance'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest misses reference_discovery workflow', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final workflows = (manifest['workflows'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((workflow) => workflow['id'] != 'reference_discovery')
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
            issue.contains('reference_discovery'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest misses roadmap_governance workflow', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final workflows = (manifest['workflows'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((workflow) => workflow['id'] != 'roadmap_governance')
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
            issue.contains('roadmap_governance'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest misses worktree_build_identity workflow',
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
        .where((workflow) => workflow['id'] != 'worktree_build_identity')
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
            issue.contains('worktree_build_identity'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest version is not 13', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    manifest['version'] = 9;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues
          .any((issue) => issue.contains('Manifest key "version" must be 13.')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest session_resume is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    manifest.remove('session_resume');
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('Manifest key "session_resume"')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when localization glossary contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('localization_glossary_source_of_truth');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.localization_glossary_source_of_truth'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when workspace performance contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('workspace_performance_source_of_truth');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.workspace_performance_source_of_truth'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when post-change docs sync contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('post_change_docs_sync_prompt_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.post_change_docs_sync_prompt_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when inspiration discovery contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('inspiration_reference_discovery_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.inspiration_reference_discovery_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when golden principles file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final golden = File(
      _joinPath(fixture.path, 'docs/assistant/GOLDEN_PRINCIPLES.md'),
    );
    golden.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('GOLDEN_PRINCIPLES.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when exec plan scaffold file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final plans = File(
      _joinPath(fixture.path, 'docs/assistant/exec_plans/PLANS.md'),
    );
    plans.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('docs/assistant/exec_plans/PLANS.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses Approval Gates section', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated =
        agentsFile.readAsStringSync().replaceAll('## Approval Gates', '## X');
    agentsFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('Approval Gates')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses Worktree Isolation section', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated = agentsFile
        .readAsStringSync()
        .replaceAll('## Worktree Isolation', '## Isolation')
        .replaceAll('worktree', 'isolation');
    agentsFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('Worktree Isolation')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when workflow misses negative-routing phrase', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final workflow = File(
      _joinPath(fixture.path, 'docs/assistant/workflows/READER_WORKFLOW.md'),
    );
    final updated = workflow
        .readAsStringSync()
        .replaceAll("Don't use this workflow when", 'Do not use this when')
        .replaceAll('Instead use', 'Use');
    workflow.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('negative routing phrase')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when workflow misses Expected Outputs heading', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final workflow = File(
      _joinPath(fixture.path, 'docs/assistant/workflows/READER_WORKFLOW.md'),
    );
    final updated = workflow
        .readAsStringSync()
        .replaceAll('## Expected Outputs\n\n- Output.\n', '');
    workflow.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Workflow doc missing required section') &&
            issue.contains('## Expected Outputs'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when golden principles contract key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('golden_principles_source_of_truth');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.golden_principles_source_of_truth'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when execplan policy contract key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('execplan_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('contracts.execplan_policy')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when approval gates contract key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('approval_gates_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('contracts.approval_gates_policy')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when worktree isolation contract key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('worktree_isolation_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
          (issue) => issue.contains('contracts.worktree_isolation_policy')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when doc gardening contract key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('doc_gardening_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains('contracts.doc_gardening_policy')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when APP user guide misses required heading', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/APP_USER_GUIDE.md'),
    );
    final updated = appGuide.readAsStringSync().replaceAll(
        '## For Agents: Support Interaction Contract', '## Support');
    appGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Feature guide is missing required section') &&
            issue.contains('APP_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when start-here guide file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final file = File(
      _joinPath(
        fixture.path,
        'docs/assistant/features/START_HERE_USER_GUIDE.md',
      ),
    );
    file.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('START_HERE_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when start-here guide misses required heading', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final startGuide = File(
      _joinPath(
        fixture.path,
        'docs/assistant/features/START_HERE_USER_GUIDE.md',
      ),
    );
    final updated = startGuide
        .readAsStringSync()
        .replaceAll('## What This App Helps You Do', '## Purpose');
    startGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Beginner guide is missing required section') &&
            issue.contains('START_HERE_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when planner user guide misses required heading', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final plannerGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/PLANNER_USER_GUIDE.md'),
    );
    final updated = plannerGuide
        .readAsStringSync()
        .replaceAll('## Canonical Deference Rule', '## Deference');
    plannerGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Feature guide is missing required section') &&
            issue.contains('PLANNER_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when APP user guide support contract misses plain language',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/APP_USER_GUIDE.md'),
    );
    final updated = appGuide
        .readAsStringSync()
        .replaceAll('plain language first', 'technical jargon first');
    appGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains(
              'Feature guide support contract must require plain-language responses',
            ) &&
            issue.contains('APP_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when planner user guide support contract misses plain language',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final plannerGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/PLANNER_USER_GUIDE.md'),
    );
    final updated = plannerGuide
        .readAsStringSync()
        .replaceAll('plain language first', 'technical jargon first');
    plannerGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains(
              'Feature guide support contract must require plain-language responses',
            ) &&
            issue.contains('PLANNER_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses support routing to user guides',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated = agentsFile
        .readAsStringSync()
        .replaceAll('START_HERE_USER_GUIDE.md', 'START_HERE.md')
        .replaceAll('APP_USER_GUIDE.md', 'APP_GUIDE.md')
        .replaceAll('PLANNER_USER_GUIDE.md', 'PLANNER_GUIDE.md');
    agentsFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('AGENTS.md must route support/non-technical tasks'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses fresh-session resume protocol',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final mutated = agentsFile
        .readAsStringSync()
        .replaceAll('## Fresh Session Resume Protocol', '## Resume Protocol')
        .replaceAll('resume master plan', 'resume plan');
    agentsFile.writeAsStringSync(mutated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
            (issue) => issue.contains(
              'AGENTS.md must include "## Fresh Session Resume Protocol" section.',
            ),
          ) ||
          issues.any(
            (issue) => issue.contains(
              'AGENTS.md must route fresh-session roadmap resume to docs/assistant/SESSION_RESUME.md and mention `resume master plan`.',
            ),
          ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses roadmap trigger policy', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final mutated = agentsFile
        .readAsStringSync()
        .replaceAll('## Roadmap Trigger Policy', '## Trigger Policy')
        .replaceAll('ExecPlan-only', 'ExecPlan only')
        .replaceAll('small isolated work', 'small work');
    agentsFile.writeAsStringSync(mutated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'AGENTS.md must include Roadmap Trigger Policy and Roadmap Artifact Authority sections.',
        ),
      ) ||
          issues.any(
            (issue) => issue.contains(
              'AGENTS.md must reference ROADMAP_WORKFLOW.md, adaptive granularity, and active-worktree authority.',
            ),
          ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when README.md misses roadmap live-source guidance', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final readme = File(_joinPath(fixture.path, 'README.md'));
    final updated = readme
        .readAsStringSync()
        .replaceAll('docs/assistant/workflows/ROADMAP_WORKFLOW.md', 'docs/assistant/workflows/PLANNER_WORKFLOW.md')
        .replaceAll('active worktree is authoritative during live roadmap work', 'main is enough');
    readme.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'README.md must reference ROADMAP_WORKFLOW.md and explain that the active worktree is the live roadmap source during in-flight wave work.',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when agent.md misses support routing to user guides',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final runbook = File(_joinPath(fixture.path, 'agent.md'));
    final updated = runbook
        .readAsStringSync()
        .replaceAll('START_HERE_USER_GUIDE.md', 'START_HERE.md')
        .replaceAll('APP_USER_GUIDE.md', 'APP_GUIDE.md')
        .replaceAll('PLANNER_USER_GUIDE.md', 'PLANNER_GUIDE.md');
    runbook.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'agent.md quick routing must include START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when AGENTS.md support routing misses plain-language rule',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated =
        agentsFile.readAsStringSync().replaceAll('plain language', 'jargon');
    agentsFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'AGENTS.md support-routing policy must require plain-language responses',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when agent.md support routing misses plain-language rule',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final runbook = File(_joinPath(fixture.path, 'agent.md'));
    final updated =
        runbook.readAsStringSync().replaceAll('plain language', 'jargon');
    runbook.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'agent.md support-routing policy must require plain-language responses',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when user-guides support usage contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('user_guides_support_usage_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('contracts.user_guides_support_usage_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when user-guides canonical deference contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('user_guides_canonical_deference_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.user_guides_canonical_deference_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when user-guides update sync contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('user_guides_update_sync_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('contracts.user_guides_update_sync_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when beginner-guide entrypoint contract key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('beginner_guide_entrypoint_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('contracts.beginner_guide_entrypoint_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when beginner-guide sync contract key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('beginner_guide_sync_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('contracts.beginner_guide_sync_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when docs maintenance misses user-guide sync clause',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final docsWorkflow = File(
      _joinPath(fixture.path,
          'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md'),
    );
    final updated = docsWorkflow
        .readAsStringSync()
        .replaceAll('START_HERE_USER_GUIDE.md', 'START_HERE.md')
        .replaceAll('APP_USER_GUIDE.md', 'APP_GUIDE.md')
        .replaceAll('PLANNER_USER_GUIDE.md', 'PLANNER_GUIDE.md')
        .replaceAll('user-guide sections', 'sections');
    docsWorkflow.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
            'DOCS_MAINTENANCE_WORKFLOW.md must include user-guide sync guidance'),
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

  test('validator fails when branch safety policy is missing in AGENTS.md', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    agentsFile.writeAsStringSync(
      [
        '# AGENTS',
        '',
        'This is a compatibility shim.',
        'docs/assistant/templates/* is read-on-demand only.',
      ].join('\n'),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('AGENTS.md must enforce branch safety'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses reference discovery routing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated = agentsFile
        .readAsStringSync()
        .replaceAll('REFERENCE_DISCOVERY_WORKFLOW.md', 'MISSING_WORKFLOW.md');
    agentsFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('AGENTS.md must route inspiration/parity tasks'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when AGENTS.md misses docs sync prompt policy', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agentsFile = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated = agentsFile.readAsStringSync().replaceAll(
        'Would you like me to run Assistant Docs Sync for this change now?',
        'REMOVED_PROMPT');
    agentsFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
            'AGENTS.md must include significant-change Assistant Docs Sync prompt policy.'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when agent.md misses reference discovery routing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final runbookFile = File(_joinPath(fixture.path, 'agent.md'));
    final updated = runbookFile
        .readAsStringSync()
        .replaceAll('REFERENCE_DISCOVERY_WORKFLOW.md', 'MISSING_WORKFLOW.md');
    runbookFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('agent.md must route inspiration/parity tasks'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when agent.md misses docs sync prompt policy', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final runbookFile = File(_joinPath(fixture.path, 'agent.md'));
    final updated = runbookFile.readAsStringSync().replaceAll(
        'Would you like me to run Assistant Docs Sync for this change now?',
        'REMOVED_PROMPT');
    runbookFile.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
            'agent.md must include mandatory post-significant-change Assistant Docs Sync prompt policy.'),
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

  test('validator fails when template misses newbie-layer heading', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final template = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
      ),
    );
    final updated = template.readAsStringSync().replaceAll(
        '## Newbie-First Layer (Optional: remove for developer-first repos)',
        '## Beginner Layer');
    template.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('CODEX_PROJECT_BOOTSTRAP_PROMPT.md must include') &&
            issue.contains('Newbie-First Layer'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when template misses beginner-default assumption', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final template = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
      ),
    );
    final updated = template.readAsStringSync().replaceAll(
        'Assume user is a complete beginner/non-coder', 'Assume user');
    template.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'newbie layer must declare beginner default assumption',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when template misses newbie-layer override rule', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final template = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
      ),
    );
    final updated = template.readAsStringSync().replaceAll(
          'If user explicitly requests developer depth, switch style while keeping all governance contracts unchanged.',
          'If user explicitly requests developer depth, switch style.',
        );
    template.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains(
                'newbie layer must include removable/override rule') ||
            issue.contains(
              'newbie layer must define developer-depth override behavior',
            ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when README misses non-coder entrypoint section', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final readme = File(_joinPath(fixture.path, 'README.md'));
    final updated = readme
        .readAsStringSync()
        .replaceAll('## If You Are Not a Developer, Start Here', '## Start');
    readme.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'README.md must include "## If You Are Not a Developer, Start Here" entrypoint section.',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when APP_KNOWLEDGE misses non-coder entrypoint section',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appKnowledge = File(_joinPath(fixture.path, 'APP_KNOWLEDGE.md'));
    final updated = appKnowledge.readAsStringSync().replaceAll(
          '## If You Are Not a Developer (Read This First)',
          '## For Developers',
        );
    appKnowledge.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'APP_KNOWLEDGE.md must include "## If You Are Not a Developer (Read This First)" section.',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when INDEX misses beginner quick path section', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final index = File(_joinPath(fixture.path, 'docs/assistant/INDEX.md'));
    final updated = index
        .readAsStringSync()
        .replaceAll('## Beginner Quick Path', '## Path');
    index.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'INDEX.md must include "## Beginner Quick Path" section.',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when APP guide misses Terms in Plain English heading',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/APP_USER_GUIDE.md'),
    );
    final updated = appGuide
        .readAsStringSync()
        .replaceAll('## Terms in Plain English', '## Terms');
    appGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Feature guide is missing required section') &&
            issue.contains('## Terms in Plain English') &&
            issue.contains('APP_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when planner guide misses Terms in Plain English heading',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final plannerGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/PLANNER_USER_GUIDE.md'),
    );
    final updated = plannerGuide
        .readAsStringSync()
        .replaceAll('## Terms in Plain English', '## Terms');
    plannerGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Feature guide is missing required section') &&
            issue.contains('## Terms in Plain English') &&
            issue.contains('PLANNER_USER_GUIDE.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when support contract misses term-definition rule', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final appGuide = File(
      _joinPath(fixture.path, 'docs/assistant/features/APP_USER_GUIDE.md'),
    );
    final updated = appGuide.readAsStringSync().replaceAll(
          'Define unavoidable technical terms in one short sentence.',
          'Keep terms simple.',
        );
    appGuide.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'Feature guide support contract must require one-line technical-term definitions',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when AGENTS.md misses Non-Coder Communication Mode section',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final agents = File(_joinPath(fixture.path, 'AGENTS.md'));
    final updated = agents.readAsStringSync().replaceAll(
          '## Non-Coder Communication Mode',
          '## Communication',
        );
    agents.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains(
          'AGENTS.md must include "## Non-Coder Communication Mode" section.')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when agent.md misses Non-Coder Communication Mode section',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final runbook = File(_joinPath(fixture.path, 'agent.md'));
    final updated = runbook.readAsStringSync().replaceAll(
          '## Non-Coder Communication Mode',
          '## Communication',
        );
    runbook.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any((issue) => issue.contains(
          'agent.md must include "## Non-Coder Communication Mode" section.')),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when non_coder_entrypoint_policy key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('non_coder_entrypoint_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('contracts.non_coder_entrypoint_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test(
      'validator fails when plain_language_support_response_policy key is missing',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('plain_language_support_response_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('contracts.plain_language_support_response_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when term_definition_policy key is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final contracts = Map<String, dynamic>.from(
      manifest['contracts'] as Map<String, dynamic>,
    );
    contracts.remove('term_definition_policy');
    manifest['contracts'] = contracts;
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains('contracts.term_definition_policy'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  for (final contractKey in <String>[
    'issue_memory_policy',
    'local_env_overlay_policy',
    'capability_inventory_policy',
    'worktree_build_identity_policy',
    'commit_shorthand_policy',
    'push_shorthand_policy',
    'roadmap_trigger_policy',
    'roadmap_granularity_policy',
    'roadmap_artifact_authority_policy',
    'roadmap_detour_policy',
    'roadmap_closeout_policy',
  ]) {
    test('validator fails when $contractKey key is missing', () {
      final fixture = _createValidFixture();
      addTearDown(() => fixture.deleteSync(recursive: true));

      final manifestFile = File(
        _joinPath(fixture.path, 'docs/assistant/manifest.json'),
      );
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final contracts = Map<String, dynamic>.from(
        manifest['contracts'] as Map<String, dynamic>,
      );
      contracts.remove(contractKey);
      manifest['contracts'] = contracts;
      manifestFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest),
      );

      final validator = AgentDocsValidator(rootDirectory: fixture);
      final issues = validator.validate();

      expect(
        issues.any((issue) => issue.contains('contracts.$contractKey')),
        isTrue,
        reason: issues.join('\n'),
      );
    });
  }

  test(
      'validator fails when template misses Terms in Plain English requirement',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final template = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
      ),
    );
    final updated = template
        .readAsStringSync()
        .replaceAll('## Terms in Plain English', '## Glossary');
    template.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'newbie layer must require user guides to include "## Terms in Plain English"',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when bootstrap roadmap template misses adaptive rules',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final template = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
      ),
    );
    final updated = template
        .readAsStringSync()
        .replaceAll('single-file fixes', 'small fixes')
        .replaceAll('one-shot docs cleanup', 'docs work')
        .replaceAll('ExecPlan-only', 'ExecPlan only');
    template.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'BOOTSTRAP_ROADMAP_GOVERNANCE.md must define adaptive thresholds for no-roadmap, ExecPlan-only, and roadmap-grade work.',
        ),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when bootstrap template map misses roadmap module', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final templateMap = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/BOOTSTRAP_TEMPLATE_MAP.json',
      ),
    );
    templateMap.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'version': 2,
        'modules': <Map<String, dynamic>>[],
      }),
    );

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'BOOTSTRAP_TEMPLATE_MAP.json must include the roadmap_governance module and BOOTSTRAP_ROADMAP_GOVERNANCE.md path.',
        ),
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
      '## Approval Gates',
      'Ask for approval before destructive, force-push, publish, risky DB, or non-essential network actions.',
      '## ExecPlans',
      'Major and multi-file work uses docs/assistant/exec_plans/active/ with docs/assistant/exec_plans/PLANS.md.',
      '## Roadmap Trigger Policy',
      'Use no roadmap for small isolated work.',
      'Use ExecPlan-only for bounded major work.',
      'Use a roadmap for long-running multi-wave restart-sensitive work.',
      'See docs/assistant/workflows/ROADMAP_WORKFLOW.md for adaptive thresholds.',
      '## Worktree Isolation',
      'Use git worktree isolation for parallel streams.',
      'For localization tasks use docs/assistant/workflows/LOCALIZATION_WORKFLOW.md and docs/assistant/LOCALIZATION_GLOSSARY.md.',
      'For performance tasks use docs/assistant/workflows/PERFORMANCE_WORKFLOW.md and docs/assistant/PERFORMANCE_BASELINES.md.',
      'For inspiration/parity tasks use docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md.',
      '## Fresh Session Resume Protocol',
      'For a new chat that asks to continue, resume, or asks what the next roadmap step is, open docs/assistant/SESSION_RESUME.md first.',
      'Use `resume master plan` as the explicit trigger phrase.',
      'After docs/assistant/SESSION_RESUME.md, open the linked active roadmap tracker and linked active wave ExecPlan.',
      '## Roadmap Artifact Authority',
      'During in-flight roadmap work, the active worktree is authoritative for live roadmap state.',
      'For user support/non-technical explanation tasks, start with docs/assistant/features/START_HERE_USER_GUIDE.md; then use docs/assistant/features/APP_USER_GUIDE.md for broader support and docs/assistant/features/PLANNER_USER_GUIDE.md for planner behavior/support. Respond in plain language first and run a canonical cross-check with APP_KNOWLEDGE.md before technical behavior claims.',
      '## Non-Coder Communication Mode',
      'For support tasks, start with docs/assistant/features/START_HERE_USER_GUIDE.md, then docs/assistant/features/APP_USER_GUIDE.md and docs/assistant/features/PLANNER_USER_GUIDE.md for planner-specific support.',
      'Answer in plain language first.',
      'Avoid jargon unless you define it in one short line.',
      'Verify technical claims using APP_KNOWLEDGE.md before asserting them.',
      'After significant implementation changes ask: "Would you like me to run Assistant Docs Sync for this change now?"',
      'Major changes must start on a new feat/* branch, not on main.',
      'Keep main stable; merge major work through PR flow with required checks.',
      'docs/assistant/templates/* is read-on-demand only.',
    ].join('\n'),
  );
  writeFile(
    'agent.md',
    [
      '# Agent Runbook',
      '',
      'AGENTS.md is a short shim for discovery.',
      '## Approval Gates',
      'Ask for approval before destructive, force-push, publish, risky DB, or non-essential network actions.',
      '## ExecPlans',
      'Major and multi-file work uses docs/assistant/exec_plans/active/ with docs/assistant/exec_plans/PLANS.md.',
      '## Roadmap Trigger Policy',
      'Use no roadmap for small isolated work.',
      'Use ExecPlan-only for bounded major work.',
      'Use a roadmap for long-running multi-wave restart-sensitive work.',
      'See docs/assistant/workflows/ROADMAP_WORKFLOW.md for adaptive thresholds.',
      '## Worktree Isolation',
      'Use git worktree isolation for parallel streams.',
      'For localization tasks use docs/assistant/workflows/LOCALIZATION_WORKFLOW.md and docs/assistant/LOCALIZATION_GLOSSARY.md.',
      'For performance tasks use docs/assistant/workflows/PERFORMANCE_WORKFLOW.md and docs/assistant/PERFORMANCE_BASELINES.md.',
      'For inspiration/parity tasks use docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md.',
      '## Fresh Session Resume Protocol',
      'Open docs/assistant/SESSION_RESUME.md first when a new chat needs roadmap continuity.',
      'Use `resume master plan` as the explicit trigger phrase.',
      'After docs/assistant/SESSION_RESUME.md, open the linked active roadmap tracker and linked active wave ExecPlan.',
      '## Roadmap Artifact Authority',
      'During in-flight roadmap work, the active worktree is authoritative for live roadmap state.',
      'Support/non-technical explanation routing: docs/assistant/features/START_HERE_USER_GUIDE.md, docs/assistant/features/APP_USER_GUIDE.md, and docs/assistant/features/PLANNER_USER_GUIDE.md. Use plain language first and perform a canonical cross-check with APP_KNOWLEDGE.md before technical behavior claims.',
      '## Non-Coder Communication Mode',
      'For support tasks, start with docs/assistant/features/START_HERE_USER_GUIDE.md, then docs/assistant/features/APP_USER_GUIDE.md and docs/assistant/features/PLANNER_USER_GUIDE.md for planner-specific support.',
      'Answer in plain language first, then give numbered UI steps.',
      'If you must use a technical term, define it in one short line.',
      'Verify technical claims with APP_KNOWLEDGE.md before asserting them.',
      'Would you like me to run Assistant Docs Sync for this change now?',
      'docs/assistant/templates/* is read-on-demand only.',
      'Only open templates when user explicitly requests template/prompt work.',
      'Major changes must start on a new feat/* branch, not on main.',
      'Keep main stable; merge major work through PR flow with required checks.',
    ].join('\n'),
  );
  writeFile(
    'APP_KNOWLEDGE.md',
    [
      '# APP_KNOWLEDGE',
      '',
      '## If You Are Not a Developer (Read This First)',
      '- docs/assistant/features/START_HERE_USER_GUIDE.md',
      '- docs/assistant/features/APP_USER_GUIDE.md',
      '- docs/assistant/features/PLANNER_USER_GUIDE.md',
      'Canonical app brief: `APP_KNOWLEDGE.md`',
      'source code remains the final truth',
      'Why two `APP_KNOWLEDGE.md` files:',
    ].join('\n'),
  );
  writeFile(
    'README.md',
    [
      '# README',
      '',
      '## Fresh Session Resume',
      '- docs/assistant/SESSION_RESUME.md',
      '- `resume master plan`',
      '- docs/assistant/workflows/ROADMAP_WORKFLOW.md',
      '- active worktree is authoritative during live roadmap work',
      '## If You Are Not a Developer, Start Here',
      '- docs/assistant/features/START_HERE_USER_GUIDE.md',
      '- docs/assistant/features/APP_USER_GUIDE.md',
      '- docs/assistant/features/PLANNER_USER_GUIDE.md',
      '- docs/assistant/INDEX.md',
      '- docs/assistant/GOLDEN_PRINCIPLES.md',
      '- docs/assistant/exec_plans/PLANS.md',
    ].join('\n'),
  );
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
  writeFile('docs/assistant/GOLDEN_PRINCIPLES.md', '# GOLDEN');
  writeFile(
    'docs/assistant/SESSION_RESUME.md',
    [
      '# Session Resume',
      '',
      '## Fresh Session Rule',
      '',
      'Start here for roadmap continuity.',
      '',
      '## Resume Trigger',
      '',
      'Use `resume master plan`.',
      '',
      '## Current Roadmap',
      '',
      'Roadmap.',
      '',
      '## Current Wave',
      '',
      'Wave.',
      '',
      '## Current Status',
      '',
      'Status.',
      '',
      '## Exact Next Step',
      '',
      'Next.',
      '',
      '## Active Worktree And Branch',
      '',
      'Worktree and branch.',
      '',
      '## Read These Next',
      '',
      'Read these.',
      '',
      '## Completed Roadmaps',
      '',
      'Completed.',
      '',
      '## Detours And Open Notes',
      '',
      'Notes.',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/INDEX.md',
    [
      '# INDEX',
      '',
      '## Beginner Quick Path',
      '- docs/assistant/features/START_HERE_USER_GUIDE.md',
      '- docs/assistant/features/APP_USER_GUIDE.md',
      '- docs/assistant/features/PLANNER_USER_GUIDE.md',
      '- APP_KNOWLEDGE.md',
      '',
      '## Fresh Session Resume',
      '- docs/assistant/SESSION_RESUME.md',
      '- `resume master plan`',
      '- active roadmap tracker',
      '- active wave ExecPlan',
      '- docs/assistant/GOLDEN_PRINCIPLES.md',
      '- docs/assistant/exec_plans/PLANS.md',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/ISSUE_MEMORY.md',
    [
      '# ISSUE MEMORY',
      '',
      'Use this file for repeatable workflow and tooling issues.',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/ISSUE_MEMORY.json',
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'version': 1,
      'last_updated': '2026-03-08',
      'issues': <dynamic>[],
    }),
  );
  writeFile(
    'docs/assistant/LOCAL_CAPABILITIES.md',
    [
      '# LOCAL CAPABILITIES',
      '',
      '- dart',
      '- git',
      '- rg',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/LOCAL_ENV_PROFILE.example.md',
    [
      '# LOCAL ENV PROFILE EXAMPLE',
      '',
      'Use docs/assistant/LOCAL_ENV_PROFILE.local.md for machine-local facts.',
    ].join('\n'),
  );
  writeFile('docs/assistant/LOCALIZATION_GLOSSARY.md', '# LOCALIZATION');
  writeFile('docs/assistant/PERFORMANCE_BASELINES.md', '# PERFORMANCE');
  writeFile(
    'docs/assistant/exec_plans/PLANS.md',
    [
      '# PLANS',
      '',
      '## Adaptive Planning Rule',
      '',
      'small isolated work -> no roadmap, ExecPlan optional',
      'bounded major work -> ExecPlan only',
      'long-running multi-wave, restart-sensitive work -> roadmap',
      '',
      '## Roadmap Return Protocol',
      '',
      'Update the active wave ExecPlan first.',
      'Update the active roadmap tracker second.',
      'Update docs/assistant/SESSION_RESUME.md third.',
      'Resume from docs/assistant/SESSION_RESUME.md unless the active roadmap tracker changes sequence.',
      '',
      '## Roadmap Artifact Authority',
      '',
      'docs/assistant/SESSION_RESUME.md is the stable first resume stop.',
      'The active roadmap tracker is the sequence source.',
      'The active wave ExecPlan is the implementation-detail source.',
      'If a wave is active in a separate worktree, that active worktree is authoritative for live roadmap state.',
    ].join('\n'),
  );
  writeFile('docs/assistant/exec_plans/active/.gitkeep', '');
  writeFile('docs/assistant/exec_plans/completed/.gitkeep', '');
  writeFile(
    'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
    [
      '# Template',
      '',
      'Template files to apply:',
      '- docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
      'Use adaptive roadmap mode for long-running multi-wave restart-sensitive work.',
      'Generate docs/assistant/SESSION_RESUME.md when roadmap mode is active.',
      '',
      '## Newbie-First Layer (Optional: remove for developer-first repos)',
      '- Assume user is a complete beginner/non-coder unless this section is removed or user explicitly requests technical depth.',
      '- Do not reduce testing, validation, approval gates, or canonical precedence.',
      '- If user explicitly requests developer depth, switch style while keeping all governance contracts unchanged.',
      '- For support/explainer tasks, use this response shape: plain-language-first, steps-second, canonical-check-last.',
      '- Support reply skeleton: `plain explanation -> numbered steps -> canonical check -> uncertainty note if needed`.',
      '- Agents must define unavoidable technical terms in one sentence.',
      '- If this section is retained, generated user guides must include near the top:',
      '  - `## Quick Start (No Technical Background)`',
      '  - `## Terms in Plain English`',
      '- Keep governance strict in beginner mode (no relaxation of validators, approval gates, or canonical precedence).',
    ].join('\n'),
  );

  final workflowTemplate = _workflowTemplate();
  writeFile(
    'docs/assistant/workflows/READER_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
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
    'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md', _ciWorkflowTemplate());
  writeFile(
    'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    _docsMaintenanceWorkflowTemplate(),
  );
  writeFile(
    'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
    [
      '## What This Workflow Is For',
      '',
      'Roadmap purpose.',
      '',
      '## Expected Outputs',
      '',
      '- Adaptive roadmap output.',
      '',
      '## When To Use',
      '',
      'Use for long-running multi-wave, restart-sensitive work.',
      'Use ExecPlan-only for bounded major work.',
      'Use no roadmap for small isolated work.',
      '',
      '## What Not To Do',
      '',
      'Don\'t use this workflow when a small isolated change can stay lighter. Instead use docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md.',
      'Do not treat main as the live roadmap source while a wave is active in a separate worktree.',
      '',
      '## Primary Files',
      '',
      '- docs/assistant/SESSION_RESUME.md',
      '- docs/assistant/exec_plans/PLANS.md',
      '',
      '## Minimal Commands',
      '',
      'git worktree list',
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
      'Use ExecPlan-only when work is bounded.',
      'Use the active worktree as the live roadmap authority during in-flight wave work.',
      'Keep docs/assistant/SESSION_RESUME.md as the stable first stop.',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
    [
      '# BOOTSTRAP ROADMAP GOVERNANCE',
      '',
      'Use roadmap mode for long-running multi-wave, restart-sensitive work.',
      'Use ExecPlan-only for bounded major work.',
      'Use no roadmap for single-file fixes or one-shot docs cleanup.',
      'Treat roadmap and master plan as equivalent user intents.',
      'Generate docs/assistant/SESSION_RESUME.md as the stable fresh-session wrapper.',
      'Generate an active roadmap tracker and active wave ExecPlan.',
      'During in-flight work in a separate worktree, that separate worktree is authoritative for live roadmap state.',
      'Update order: active wave ExecPlan, active roadmap tracker, docs/assistant/SESSION_RESUME.md.',
      'Reusable issue classes include roadmap_trigger_granularity_ambiguity and active_worktree_resume_authority_confusion.',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/templates/BOOTSTRAP_TEMPLATE_MAP.json',
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'version': 2,
      'modules': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'roadmap_governance',
          'path': 'docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
        },
      ],
    }),
  );
  writeFile(
    'docs/assistant/templates/BOOTSTRAP_MODULES_AND_TRIGGERS.md',
    [
      '# BOOTSTRAP MODULES AND TRIGGERS',
      '',
      'Roadmap Governance -> docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
      'Use no roadmap for single-file fixes.',
      'Use ExecPlan-only for bounded major work.',
      'Use roadmap mode for long-running multi-wave restart-sensitive work.',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/templates/BOOTSTRAP_UPDATE_POLICY.md',
    [
      '# BOOTSTRAP UPDATE POLICY',
      '',
      'Promote reusable governance/process patterns only.',
      'Use BOOTSTRAP_ROADMAP_GOVERNANCE.md for adaptive roadmap rules.',
      'Do not leak app-specific dates, branch names, tracker filenames, or domain language into UCBS.',
      'Keep adaptive trigger thresholds general.',
    ].join('\n'),
  );

  writeFile('tooling/validate_agent_docs.dart', '// placeholder');
  writeFile('tooling/validate_workspace_hygiene.dart', '// placeholder');
  writeFile('test/tooling/validate_agent_docs_test.dart', '// placeholder');
  writeFile(
      'test/tooling/validate_workspace_hygiene_test.dart', '// placeholder');

  final manifest = <String, dynamic>{
    'version': 13,
    'canonical': <String, dynamic>{
      'agent_runbook': 'agent.md',
      'app_knowledge': 'APP_KNOWLEDGE.md',
      'db_knowledge': 'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
    },
    'session_resume': 'docs/assistant/SESSION_RESUME.md',
    'bridges': <String>[
      'AGENTS.md',
      'docs/assistant/APP_KNOWLEDGE.md',
    ],
    'user_guides': <String>[
      'docs/assistant/features/START_HERE_USER_GUIDE.md',
      'docs/assistant/features/APP_USER_GUIDE.md',
      'docs/assistant/features/PLANNER_USER_GUIDE.md',
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
        id: 'localization_i18n',
        doc: 'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'workspace_performance',
        doc: 'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'reference_discovery',
        doc: 'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'roadmap_governance',
        doc: 'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'planner_scheduler',
        doc: 'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'scheduling_companion',
        doc: 'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'worktree_build_identity',
        doc: 'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
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
      'localization_glossary_source_of_truth':
          'docs/assistant/LOCALIZATION_GLOSSARY.md is the canonical term source.',
      'workspace_performance_source_of_truth':
          'docs/assistant/PERFORMANCE_BASELINES.md is the canonical source for workspace/editor performance defaults.',
      'env_artifacts_outside_workspace_default':
          'Heavyweight environments and generated runtime artifacts should live outside repo root when feasible.',
      'post_change_docs_sync_prompt_policy':
          'After significant implementation changes, ask whether to run Assistant Docs Sync and update only relevant assistant docs if approved.',
      'issue_memory_policy':
          'docs/assistant/ISSUE_MEMORY.md and docs/assistant/ISSUE_MEMORY.json are the always-on issue registry; Assistant Docs Sync should consult issue memory before widening touched-scope updates.',
      'local_env_overlay_policy':
          'Use docs/assistant/LOCAL_ENV_PROFILE.example.md for shared routing format and keep machine-local runtime facts in docs/assistant/LOCAL_ENV_PROFILE.local.md.',
      'capability_inventory_policy':
          'Use docs/assistant/LOCAL_CAPABILITIES.md to record only discovered local capabilities that materially affect workflow decisions.',
      'worktree_build_identity_policy':
          'Use docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md and tooling/print_build_identity.dart for runnable-build identity, baseline locking, and deterministic launch handoff.',
      'commit_shorthand_policy':
          'Bare commit means full pending-tree triage, logical grouped commits, and immediate push suggestion unless the user narrows scope.',
      'push_shorthand_policy':
          'Bare push means Push+PR+Merge+Cleanup unless the user narrows scope explicitly.',
      'inspiration_reference_discovery_policy':
          'When user names a product/site to emulate, run docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md and prioritize official sources first.',
      'golden_principles_source_of_truth':
          'docs/assistant/GOLDEN_PRINCIPLES.md is the canonical source for mechanical agent/human implementation rules.',
      'execplan_policy':
          'Major or multi-file work must start with an ExecPlan under docs/assistant/exec_plans/active/ and follow docs/assistant/exec_plans/PLANS.md.',
      'approval_gates_policy':
          'AGENTS.md and agent.md must include Approval Gates that require explicit user confirmation.',
      'worktree_isolation_policy':
          'For parallel implementation streams, prefer git worktree isolation.',
      'doc_gardening_policy':
          'Run docs validators regularly and apply targeted docs maintenance to prevent drift.',
      'user_guides_support_usage_policy':
          'For support/non-technical explanations, start with docs/assistant/features/START_HERE_USER_GUIDE.md for first-time orientation, then use docs/assistant/features/APP_USER_GUIDE.md for broader support and docs/assistant/features/PLANNER_USER_GUIDE.md for planner-focused support.',
      'user_guides_canonical_deference_policy':
          'Feature guides are explanatory docs; if they conflict with technical docs, APP_KNOWLEDGE.md and source code win.',
      'user_guides_update_sync_policy':
          'When user-facing behavior copy/flow changes, update only affected sections in START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and/or PLANNER_USER_GUIDE.md based on scope.',
      'non_coder_entrypoint_policy':
          'Non-coders should start with docs/assistant/features/START_HERE_USER_GUIDE.md before moving to APP_USER_GUIDE.md or PLANNER_USER_GUIDE.md.',
      'beginner_guide_entrypoint_policy':
          'First-time users and future restarts should start with docs/assistant/features/START_HERE_USER_GUIDE.md before the broader support guides.',
      'beginner_guide_sync_policy':
          'When main navigation, first-run mental model, primary user journeys, what-to-ignore-at-first guidance, or the role of Today, Read, My Plan, Practice from Memory, Library, or My Quran changes, update START_HERE_USER_GUIDE.md during Assistant Docs Sync.',
      'fresh_session_resume_policy':
          'Fresh sessions that need roadmap continuity should resume from docs/assistant/SESSION_RESUME.md before opening any active roadmap tracker or wave ExecPlan.',
      'resume_trigger_policy':
          'Use `resume master plan` as the explicit resume trigger phrase; equivalent intents like `where did we leave off` and `what is the next roadmap step` should route to docs/assistant/SESSION_RESUME.md too.',
      'roadmap_resume_update_policy':
          'After roadmap detours or changes to active wave, next step, closeout state, branch, or worktree, update the active wave ExecPlan first, the active roadmap tracker second, and docs/assistant/SESSION_RESUME.md third.',
      'roadmap_trigger_policy':
          'Use no roadmap for small isolated work, use ExecPlan-only for bounded major work, and use roadmap mode for long-running multi-wave restart-sensitive work. Treat master plan and roadmap as equivalent user intents.',
      'roadmap_granularity_policy':
          'Do not open a roadmap for single-file fixes, narrow bug fixes, small UI text tweaks, or one-shot docs cleanup. Prefer the lightest planning mode that is still safe.',
      'roadmap_artifact_authority_policy':
          'During in-flight roadmap work, docs/assistant/SESSION_RESUME.md is the stable first resume stop, the active roadmap tracker is the sequence source, and the active wave ExecPlan is the implementation-detail source. If a wave is active in a separate worktree, that worktree\'s roadmap files are authoritative for live roadmap state.',
      'roadmap_detour_policy':
          'After roadmap detours, update the active wave ExecPlan first, the active roadmap tracker second, and docs/assistant/SESSION_RESUME.md third before resuming the sequence.',
      'roadmap_closeout_policy':
          'Every roadmap closeout must report current roadmap status and exact next step. When the next action is a closeout step, say so explicitly instead of naming a new wave.',
      'plain_language_support_response_policy':
          'Support responses must be plain-language-first with numbered next steps and exact UI labels.',
      'term_definition_policy':
          'If a technical term is unavoidable in support replies, define it in one short sentence.',
    },
    'last_updated': '2026-03-09',
  };

  writeFile(
    'docs/assistant/features/START_HERE_USER_GUIDE.md',
    _startHereGuideTemplate(),
  );
  writeFile(
    'docs/assistant/features/APP_USER_GUIDE.md',
    _featureGuideTemplate(),
  );
  writeFile(
    'docs/assistant/features/PLANNER_USER_GUIDE.md',
    _featureGuideTemplate(),
  );
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
    '## Expected Outputs',
    '',
    '- Output.',
    '',
    '## When To Use',
    '',
    'When.',
    '',
    '## What Not To Do',
    '',
    'Don\'t use this workflow when not needed. Instead use docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md.',
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

String _ciWorkflowTemplate() {
  return [
    '## What This Workflow Is For',
    '',
    'CI purpose.',
    '',
    '## Expected Outputs',
    '',
    '- CI output.',
    '',
    '## When To Use',
    '',
    'When.',
    '',
    '## What Not To Do',
    '',
    'Don\'t use this workflow when commit triage is requested. Instead use docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md.',
    'Do not implement major changes directly on `main`; use `feat/*` first.',
    'Do not merge major work to `main` without PR flow and required checks.',
    '',
    '## Primary Files',
    '',
    '- APP_KNOWLEDGE.md',
    '',
    '## Minimal Commands',
    '',
    'git worktree list',
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
    'major changes were developed on `feat/*` branch, not directly on `main`.',
    '`main` updates for major work followed PR flow and required checks.',
    'worktree isolation used for parallel streams.',
  ].join('\n');
}

String _docsMaintenanceWorkflowTemplate() {
  return [
    '## What This Workflow Is For',
    '',
    'Docs purpose.',
    '',
    '## Expected Outputs',
    '',
    '- Docs output.',
    '',
    '## When To Use',
    '',
    'When.',
    '',
    '## What Not To Do',
    '',
    'Don\'t use this workflow when runtime implementation is requested. Instead use docs/assistant/workflows/READER_WORKFLOW.md.',
    'Do not rewrite entire user guides when only one user journey changed; update touched sections only.',
    'Do not widen docs/assistant/features/START_HERE_USER_GUIDE.md unless the beginner mental model or main navigation changed.',
    'Do not let docs/assistant/SESSION_RESUME.md drift from the active roadmap tracker or active wave ExecPlan.',
    '',
    '## Primary Files',
    '',
    '- docs/assistant/SESSION_RESUME.md',
    '- docs/assistant/features/START_HERE_USER_GUIDE.md',
    '- docs/assistant/features/APP_USER_GUIDE.md',
    '- docs/assistant/features/PLANNER_USER_GUIDE.md',
    '',
    '## Minimal Commands',
    '',
    'git worktree list',
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
    '## Significant-Change Docs Sync Policy',
    '',
    'User-facing behavior copy/flow change -> update affected sections in docs/assistant/features/START_HERE_USER_GUIDE.md, docs/assistant/features/APP_USER_GUIDE.md, and/or docs/assistant/features/PLANNER_USER_GUIDE.md',
    'Beginner navigation/mental-model change -> update docs/assistant/features/START_HERE_USER_GUIDE.md first.',
    'Fresh-session roadmap resume change -> update docs/assistant/SESSION_RESUME.md and only the routing/validator docs needed to keep it discoverable.',
    'Update docs/assistant/SESSION_RESUME.md when active roadmap, active wave, next step, or worktree state changes.',
    '',
    '## Handoff Checklist',
    '',
    'Relevant user-guide sections were updated or explicitly deemed unchanged.',
    'docs/assistant/features/START_HERE_USER_GUIDE.md was updated or explicitly deemed unchanged when beginner navigation changed.',
    'docs/assistant/SESSION_RESUME.md was updated or explicitly deemed unchanged when roadmap state or next step changed.',
  ].join('\n');
}

String _startHereGuideTemplate() {
  return [
    '# START HERE',
    '',
    '## Quick Start (No Technical Background)',
    '',
    'Start here.',
    '',
    '## What This App Helps You Do',
    '',
    'What it helps with.',
    '',
    '## The Main Places You Need',
    '',
    'Places.',
    '',
    '## How The Parts Work Together',
    '',
    'Flow.',
    '',
    '## What To Ignore At First',
    '',
    'Ignore advanced items.',
    '',
    '## Common Situations',
    '',
    'Situations.',
    '',
    '## What This App Does Not Do Yet',
    '',
    'Limits.',
    '',
    '## If You Want More Detail',
    '',
    'See APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md.',
  ].join('\n');
}

String _featureGuideTemplate() {
  return [
    '# GUIDE',
    '',
    '## Use This Guide When',
    '',
    'Use for support.',
    '',
    '## Do Not Use This Guide For',
    '',
    'Do not use for internals.',
    '',
    '## For Agents: Support Interaction Contract',
    '',
    'Answer in plain language first.',
    'Provide numbered next steps with exact UI labels.',
    'Run a canonical cross-check with APP_KNOWLEDGE.md before technical claims.',
    'Explicitly mention uncertainty when behavior may evolve.',
    'Define unavoidable technical terms in one short sentence.',
    '',
    '## Canonical Deference Rule',
    '',
    'APP_KNOWLEDGE.md and source code win on conflicts.',
    '',
    '## Quick Start (No Technical Background)',
    '',
    '1. Open the main screen and follow guided steps.',
    '',
    '## Terms in Plain English',
    '',
    '- Canonical: final source when docs disagree.',
  ].join('\n');
}

String _joinPath(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}
