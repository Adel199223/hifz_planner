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
      '## Worktree Isolation',
      'Use git worktree isolation for parallel streams.',
      'For localization tasks use docs/assistant/workflows/LOCALIZATION_WORKFLOW.md and docs/assistant/LOCALIZATION_GLOSSARY.md.',
      'For performance tasks use docs/assistant/workflows/PERFORMANCE_WORKFLOW.md and docs/assistant/PERFORMANCE_BASELINES.md.',
      'For inspiration/parity tasks use docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md.',
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
      '## Worktree Isolation',
      'Use git worktree isolation for parallel streams.',
      'For localization tasks use docs/assistant/workflows/LOCALIZATION_WORKFLOW.md and docs/assistant/LOCALIZATION_GLOSSARY.md.',
      'For performance tasks use docs/assistant/workflows/PERFORMANCE_WORKFLOW.md and docs/assistant/PERFORMANCE_BASELINES.md.',
      'For inspiration/parity tasks use docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md.',
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
    'docs/assistant/INDEX.md',
    [
      '# INDEX',
      '',
      '- docs/assistant/GOLDEN_PRINCIPLES.md',
      '- docs/assistant/exec_plans/PLANS.md',
    ].join('\n'),
  );
  writeFile('docs/assistant/LOCALIZATION_GLOSSARY.md', '# LOCALIZATION');
  writeFile('docs/assistant/PERFORMANCE_BASELINES.md', '# PERFORMANCE');
  writeFile('docs/assistant/exec_plans/PLANS.md', '# PLANS');
  writeFile('docs/assistant/exec_plans/active/.gitkeep', '');
  writeFile('docs/assistant/exec_plans/completed/.gitkeep', '');
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
    workflowTemplate,
  );

  writeFile('tooling/validate_agent_docs.dart', '// placeholder');
  writeFile('tooling/validate_workspace_hygiene.dart', '// placeholder');
  writeFile('test/tooling/validate_agent_docs_test.dart', '// placeholder');
  writeFile(
      'test/tooling/validate_workspace_hygiene_test.dart', '// placeholder');

  final manifest = <String, dynamic>{
    'version': 9,
    'canonical': <String, dynamic>{
      'agent_runbook': 'agent.md',
      'app_knowledge': 'APP_KNOWLEDGE.md',
      'db_knowledge': 'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
    },
    'bridges': <String>[
      'AGENTS.md',
      'docs/assistant/APP_KNOWLEDGE.md',
    ],
    'user_guides': <String>[
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
        id: 'planner_scheduler',
        doc: 'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'scheduling_companion',
        doc: 'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
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
    },
    'last_updated': '2026-02-22',
  };

  writeFile(
    'docs/assistant/features/APP_USER_GUIDE.md',
    '# APP USER GUIDE',
  );
  writeFile(
    'docs/assistant/features/PLANNER_USER_GUIDE.md',
    '# PLANNER USER GUIDE',
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

String _joinPath(String left, String right) {
  final normalizedRight = right.replaceAll('/', Platform.pathSeparator);
  if (left.endsWith(Platform.pathSeparator)) {
    return '$left$normalizedRight';
  }
  return '$left${Platform.pathSeparator}$normalizedRight';
}
