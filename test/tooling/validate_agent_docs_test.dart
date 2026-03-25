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

  test('validator fails when explainer HTML template file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final templateFile = File(
      _joinPath(
        fixture.path,
        'docs/assistant/templates/EXPLAINER_HTML_PROMPT.md',
      ),
    );
    templateFile.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('EXPLAINER_HTML_PROMPT.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when roadmap anchor file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final missingAnchor = File(
      _joinPath(fixture.path, 'docs/assistant/ROADMAP_ANCHOR.md'),
    );
    missingAnchor.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('ROADMAP_ANCHOR.md'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when harness profile file is missing', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final missingProfile = File(
      _joinPath(fixture.path, 'docs/assistant/HARNESS_PROFILE.json'),
    );
    missingProfile.deleteSync();

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) =>
            issue.contains('Missing required file:') &&
            issue.contains('HARNESS_PROFILE.json'),
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

  test('validator fails when manifest misses project_harness_sync workflow',
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
        .where((workflow) => workflow['id'] != 'project_harness_sync')
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
            issue.contains('project_harness_sync'),
      ),
      isTrue,
      reason: issues.join('\n'),
    );
  });

  test('validator fails when manifest misses explainer_html workflow', () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final manifestFile = File(
      _joinPath(fixture.path, 'docs/assistant/manifest.json'),
    );
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final workflows = (manifest['workflows'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((workflow) => workflow['id'] != 'explainer_html')
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
            issue.contains('explainer_html'),
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

  test('validator fails when agent.md misses support routing to user guides',
      () {
    final fixture = _createValidFixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final runbook = File(_joinPath(fixture.path, 'agent.md'));
    final updated = runbook
        .readAsStringSync()
        .replaceAll('APP_USER_GUIDE.md', 'APP_GUIDE.md')
        .replaceAll('PLANNER_USER_GUIDE.md', 'PLANNER_GUIDE.md');
    runbook.writeAsStringSync(updated);

    final validator = AgentDocsValidator(rootDirectory: fixture);
    final issues = validator.validate();

    expect(
      issues.any(
        (issue) => issue.contains(
          'agent.md quick routing must include APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md',
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
      'For bootstrap harness apply/audit tasks use docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md.',
      'For explicit HTML explainer requests use docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md.',
      'For user support/non-technical explanation tasks, start with docs/assistant/features/APP_USER_GUIDE.md; for planner behavior/support use docs/assistant/features/PLANNER_USER_GUIDE.md. Respond in plain language first and run a canonical cross-check with APP_KNOWLEDGE.md before technical behavior claims.',
      '## Non-Coder Communication Mode',
      'For support tasks, start with docs/assistant/features/APP_USER_GUIDE.md and docs/assistant/features/PLANNER_USER_GUIDE.md for planner-specific support.',
      'Answer in plain language first.',
      'Avoid jargon unless you define it in one short line.',
      'Verify technical claims using APP_KNOWLEDGE.md before asserting them.',
      'After significant implementation changes ask: "Would you like me to run Assistant Docs Sync for this change now?"',
      'Major changes must start on a new feat/* branch, not on main.',
      'Keep main stable; merge major work through PR flow with required checks.',
      'docs/assistant/templates/* is read-on-demand only.',
      'Explicit HTML explainer requests may also use docs/assistant/templates/EXPLAINER_HTML_PROMPT.md.',
      'Explicit bootstrap harness tasks such as implement the template files or sync project harness may use docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md.',
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
      'For bootstrap harness apply/audit tasks use docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md.',
      'For explicit HTML explainer requests use docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md.',
      'Support/non-technical explanation routing: docs/assistant/features/APP_USER_GUIDE.md and docs/assistant/features/PLANNER_USER_GUIDE.md. Use plain language first and perform a canonical cross-check with APP_KNOWLEDGE.md before technical behavior claims.',
      '## Non-Coder Communication Mode',
      'For support tasks, start with docs/assistant/features/APP_USER_GUIDE.md and docs/assistant/features/PLANNER_USER_GUIDE.md for planner-specific support.',
      'Answer in plain language first, then give numbered UI steps.',
      'If you must use a technical term, define it in one short line.',
      'Verify technical claims with APP_KNOWLEDGE.md before asserting them.',
      'Would you like me to run Assistant Docs Sync for this change now?',
      'docs/assistant/templates/* is read-on-demand only.',
      'Only open templates when user explicitly requests template/prompt work.',
      'Explicit HTML explainer requests may also use docs/assistant/templates/EXPLAINER_HTML_PROMPT.md.',
      'Explicit bootstrap harness tasks such as implement the template files or sync project harness may use docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md.',
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
      '- docs/assistant/features/APP_USER_GUIDE.md',
      '- docs/assistant/features/PLANNER_USER_GUIDE.md',
      'Canonical app brief: `APP_KNOWLEDGE.md`',
      'Bootstrap profile source of truth: `docs/assistant/HARNESS_PROFILE.json`',
      'Bootstrap output mapping overlay: `docs/assistant/HARNESS_OUTPUT_MAP.json`',
      'source code remains the final truth',
      'Why two `APP_KNOWLEDGE.md` files:',
    ].join('\n'),
  );
  writeFile(
    'README.md',
    [
      '# README',
      '',
      '## If You Are Not a Developer, Start Here',
      '- docs/assistant/features/APP_USER_GUIDE.md',
      '- docs/assistant/features/PLANNER_USER_GUIDE.md',
      '- docs/assistant/INDEX.md',
      '- docs/assistant/GOLDEN_PRINCIPLES.md',
      '- docs/assistant/exec_plans/PLANS.md',
      '- docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
      '- docs/assistant/HARNESS_PROFILE.json',
      '- docs/assistant/HARNESS_OUTPUT_MAP.json',
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
      'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
    ].join('\n'),
  );
  writeFile('docs/assistant/DB_DRIFT_KNOWLEDGE.md', '# DB');
  writeFile('docs/assistant/GOLDEN_PRINCIPLES.md', '# GOLDEN');
  writeFile(
    'docs/assistant/ROADMAP_ANCHOR.md',
    [
      '# Roadmap Anchor',
      '',
      'Read this after `agent.md` and `APP_KNOWLEDGE.md` when resuming roadmap work.',
    ].join('\n'),
  );
  writeFile(
    'docs/assistant/INDEX.md',
    [
      '# INDEX',
      '',
      'For explicit HTML explainer requests, use docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md first.',
      'For explicit bootstrap harness apply/audit requests, use docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md first.',
      '',
      '## Beginner Quick Path',
      '- docs/assistant/features/APP_USER_GUIDE.md',
      '- docs/assistant/features/PLANNER_USER_GUIDE.md',
      '- APP_KNOWLEDGE.md',
      '- docs/assistant/GOLDEN_PRINCIPLES.md',
      '- docs/assistant/exec_plans/PLANS.md',
    ].join('\n'),
  );
  writeFile('docs/assistant/LOCALIZATION_GLOSSARY.md', '# LOCALIZATION');
  writeFile('docs/assistant/PERFORMANCE_BASELINES.md', '# PERFORMANCE');
  writeFile('docs/assistant/CAPABILITY_DISCOVERY.md', '# CAPABILITY');
  writeFile('docs/assistant/CODEX_ENVIRONMENT.md', '# CODEX ENV');
  writeFile('docs/assistant/DIAGNOSTICS.md', '# DIAGNOSTICS');
  writeFile('docs/assistant/HARNESS_OUTPUT_MAP.json', '{"schema_version":1,"output_mappings":[]}');
  writeFile('docs/assistant/HARNESS_PROFILE.json', '{"schema_version":1}');
  writeFile('docs/assistant/HOST_INTEGRATION.md', '# HOST');
  writeFile('docs/assistant/ISSUE_MEMORY.json', '{"schema_version":1,"entries":[]}');
  writeFile('docs/assistant/ISSUE_MEMORY.md', '# ISSUE MEMORY');
  writeFile('docs/assistant/LOCAL_ENVIRONMENT.md', '# LOCAL ENV');
  writeFile('docs/assistant/QA_CHECKS.md', '# QA');
  writeFile('docs/assistant/SAFE_COMMANDS.md', '# SAFE');
  writeFile('docs/assistant/TERMS_IN_PLAIN_ENGLISH.md', '# TERMS');
  writeFile('docs/assistant/exec_plans/PLANS.md', '# PLANS');
  writeFile('docs/assistant/exec_plans/active/.gitkeep', '');
  writeFile('docs/assistant/exec_plans/completed/.gitkeep', '');
  writeFile('docs/assistant/runtime/BOOTSTRAP_STATE.json', '{"schema_version":1}');
  writeFile('docs/assistant/runtime/CANONICAL_BUILD.json', '{"schema_version":1}');
  writeFile('docs/assistant/schemas/HARNESS_PROFILE.schema.json', '{}');
  writeFile('docs/assistant/templates/BOOTSTRAP_ARCHETYPE_REGISTRY.json', '{}');
  writeFile('docs/assistant/templates/BOOTSTRAP_CORE_CONTRACT.md', '# Core');
  writeFile('docs/assistant/templates/BOOTSTRAP_ISSUE_MEMORY_SYSTEM.md', '# Issue');
  writeFile('docs/assistant/templates/BOOTSTRAP_MODULES_AND_TRIGGERS.md', '# Modules');
  writeFile('docs/assistant/templates/BOOTSTRAP_PROFILE_RESOLUTION.md', '# Profile');
  writeFile('docs/assistant/templates/BOOTSTRAP_PROJECT_HARNESS_SYNC_POLICY.md', '# Sync');
  writeFile('docs/assistant/templates/BOOTSTRAP_TEMPLATE_MAP.json', '{}');
  writeFile('docs/assistant/templates/BOOTSTRAP_VERSION.json', '{}');
  writeFile(
    'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
    [
      '# Template',
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
  writeFile(
    'docs/assistant/templates/EXPLAINER_HTML_PROMPT.md',
    [
      '# Explainer HTML Prompt',
      '',
      'Read docs/assistant/features/APP_USER_GUIDE.md, docs/assistant/features/PLANNER_USER_GUIDE.md, APP_KNOWLEDGE.md, and docs/assistant/ROADMAP_ANCHOR.md when relevant.',
      'Write docs/assistant/features/<TOPIC>_EXPLAINER.html and docs/assistant/features/<TOPIC>_EXPLAINER_READING.html as local-only explanation artifacts.',
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
    'docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md',
    workflowTemplate,
  );
  writeFile(
    'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
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

  writeFile('tooling/bootstrap_profile_wizard.py', '# placeholder');
  writeFile('tooling/check_harness_profile.py', '# placeholder');
  writeFile('tooling/harness_profile_lib.py', '# placeholder');
  writeFile('tooling/preview_harness_sync.py', '# placeholder');
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
        id: 'project_harness_sync',
        doc: 'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
      ),
      _manifestWorkflow(
        id: 'explainer_html',
        doc: 'docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md',
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
          'docs/assistant/templates/* are read-on-demand only. Explicit bootstrap harness tasks may use PROJECT_HARNESS_SYNC_WORKFLOW.md.',
      'bootstrap_profile_source_of_truth':
          'docs/assistant/HARNESS_PROFILE.json is the source of truth for bootstrap profile resolution.',
      'bootstrap_output_map_policy':
          'docs/assistant/HARNESS_OUTPUT_MAP.json preserves stronger repo-local equivalents.',
      'project_harness_sync_policy':
          'Use docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md to implement the template files and keep local template-file apply behavior separate from template maintenance.',
      'html_explainer_route_policy':
          'Explicit HTML explainer requests route to docs/assistant/workflows/EXPLAINER_HTML_WORKFLOW.md and docs/assistant/templates/EXPLAINER_HTML_PROMPT.md.',
      'html_explainer_local_only_policy':
          'Generated explainer HTML files are local-only and use repo-local exclude rules by default.',
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
      'user_guides_support_usage_policy':
          'For support/non-technical explanations, start with docs/assistant/features/APP_USER_GUIDE.md and use docs/assistant/features/PLANNER_USER_GUIDE.md for planner-focused support.',
      'user_guides_canonical_deference_policy':
          'Feature guides are explanatory docs; if they conflict with technical docs, APP_KNOWLEDGE.md and source code win.',
      'user_guides_update_sync_policy':
          'When user-facing behavior copy/flow changes, update only affected sections in APP_USER_GUIDE.md and/or PLANNER_USER_GUIDE.md.',
      'non_coder_entrypoint_policy':
          'Non-coders should start with docs/assistant/features/APP_USER_GUIDE.md (or PLANNER_USER_GUIDE.md for planner topics) before technical docs.',
      'plain_language_support_response_policy':
          'Support responses must be plain-language-first with numbered next steps and exact UI labels.',
      'term_definition_policy':
          'If a technical term is unavoidable in support replies, define it in one short sentence.',
    },
    'last_updated': '2026-02-22',
  };

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
    '',
    '## Primary Files',
    '',
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
    'User-facing behavior copy/flow change -> update affected sections in docs/assistant/features/APP_USER_GUIDE.md and/or docs/assistant/features/PLANNER_USER_GUIDE.md',
    '',
    '## Handoff Checklist',
    '',
    'Relevant user-guide sections were updated or explicitly deemed unchanged.',
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
