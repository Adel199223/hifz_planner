import 'dart:convert';
import 'dart:io';

const List<String> _requiredFiles = <String>[
  'AGENTS.md',
  'agent.md',
  'APP_KNOWLEDGE.md',
  'README.md',
  '.github/workflows/dart.yml',
  'docs/assistant/APP_KNOWLEDGE.md',
  'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
  'docs/assistant/GOLDEN_PRINCIPLES.md',
  'docs/assistant/INDEX.md',
  'docs/assistant/ROADMAP_ANCHOR.md',
  'docs/assistant/LOCALIZATION_GLOSSARY.md',
  'docs/assistant/PERFORMANCE_BASELINES.md',
  'docs/assistant/exec_plans/PLANS.md',
  'docs/assistant/exec_plans/active',
  'docs/assistant/exec_plans/completed',
  'docs/assistant/manifest.json',
  'docs/assistant/workflows/READER_WORKFLOW.md',
  'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
  'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
  'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
  'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
  'docs/assistant/workflows/PLANNER_WORKFLOW.md',
  'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
  'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
  'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
  'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
  'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
  'tooling/validate_workspace_hygiene.dart',
  'test/tooling/validate_workspace_hygiene_test.dart',
];

const List<String> _workflowRequiredSections = <String>[
  '## What This Workflow Is For',
  '## Expected Outputs',
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
  'docs/assistant/GOLDEN_PRINCIPLES.md',
  'docs/assistant/INDEX.md',
  'docs/assistant/ROADMAP_ANCHOR.md',
  'docs/assistant/LOCALIZATION_GLOSSARY.md',
  'docs/assistant/PERFORMANCE_BASELINES.md',
  'docs/assistant/exec_plans/PLANS.md',
  'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
  'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
  'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
  'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
  'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
  'docs/assistant/workflows/READER_WORKFLOW.md',
  'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
  'docs/assistant/workflows/PLANNER_WORKFLOW.md',
  'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
  'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
];

final RegExp _backtickRegex = RegExp(r'`([^`\n]+)`');
final RegExp _pathLikeRegex = RegExp(
  r'^(AGENTS\.md|agent\.md|APP_KNOWLEDGE\.md|README\.md|docs/|lib/|test/|tooling/|assets/|\.github/|\.vscode/|\.gitignore|pubspec\.yaml)',
);

final List<RegExp> _bashOnlyPatterns = <RegExp>[
  RegExp(r'(^|\s)grep(\s|$)', caseSensitive: false),
  RegExp(r'(^|\s)awk(\s|$)', caseSensitive: false),
  RegExp(r'(^|\s)sed(\s|$)', caseSensitive: false),
  RegExp(r'\bexport\s+[A-Za-z_]', caseSensitive: false),
  RegExp(r'\|\s*xargs\b', caseSensitive: false),
  RegExp(r'\bset -e\b', caseSensitive: false),
  RegExp(r'(^|\s)\./'),
  RegExp(r'&&'),
];

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
    _validateWorkflowNegativeRouting(issues);
    _validateFeatureGuideSections(issues);
    _validateCanonicalContracts(issues);
    _validateBranchSafetyPolicy(issues);
    _validateApprovalGatesPolicy(issues);
    _validateExecPlanPolicy(issues);
    _validateWorktreeIsolationPolicy(issues);
    _validateUserGuideSupportRoutingPolicy(issues);
    _validateDocsMaintenanceUserGuideSyncPolicy(issues);
    _validateLocalizationRoutingPolicy(issues);
    _validatePerformanceRoutingPolicy(issues);
    _validateReferenceDiscoveryPolicy(issues);
    _validatePostChangeDocsSyncPolicy(issues);
    _validateTemplatePolicies(issues);
    _validateTemplateNewbieLayer(issues);
    _validateNonCoderEntrypoints(issues);
    _validateGoldenAndExecPlanDiscoverability(issues);
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

    final userGuides = manifest['user_guides'];
    if (userGuides is! List) {
      issues.add('Manifest key "user_guides" must be an array.');
    } else {
      for (var i = 0; i < userGuides.length; i++) {
        final value = userGuides[i];
        if (value is! String || value.trim().isEmpty) {
          issues
              .add('Manifest user_guides[$i] must be a non-empty string path.');
          continue;
        }
        if (!_exists(value)) {
          issues.add('Manifest user guide path does not exist: $value');
        }
      }
    }

    final workflows = manifest['workflows'];
    final workflowsById = <String, Map<String, dynamic>>{};
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
        final id = value['id'];
        if (id is String && id.trim().isNotEmpty) {
          workflowsById[id] = value;
        }
      }
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'ci_repo_ops',
        expectedDoc: 'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'commit_publish_ops',
        expectedDoc: 'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'localization_i18n',
        expectedDoc: 'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'workspace_performance',
        expectedDoc: 'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'reference_discovery',
        expectedDoc: 'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'scheduling_companion',
        expectedDoc:
            'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      );
    }

    final globalCommands = manifest['global_commands'];
    if (globalCommands is! Map<String, dynamic>) {
      issues.add('Manifest key "global_commands" must be an object.');
    } else {
      _validateCommandList(
        issues,
        globalCommands['bootstrap'],
        'global_commands.bootstrap',
      );
      _validateCommandList(
        issues,
        globalCommands['analysis'],
        'global_commands.analysis',
      );
      _validateCommandList(
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
      _validateNonEmptyString(
        issues,
        contracts['templates_read_policy'],
        'contracts.templates_read_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['localization_glossary_source_of_truth'],
        'contracts.localization_glossary_source_of_truth',
      );
      _validateNonEmptyString(
        issues,
        contracts['workspace_performance_source_of_truth'],
        'contracts.workspace_performance_source_of_truth',
      );
      _validateNonEmptyString(
        issues,
        contracts['env_artifacts_outside_workspace_default'],
        'contracts.env_artifacts_outside_workspace_default',
      );
      _validateNonEmptyString(
        issues,
        contracts['post_change_docs_sync_prompt_policy'],
        'contracts.post_change_docs_sync_prompt_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['inspiration_reference_discovery_policy'],
        'contracts.inspiration_reference_discovery_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['golden_principles_source_of_truth'],
        'contracts.golden_principles_source_of_truth',
      );
      _validateNonEmptyString(
        issues,
        contracts['execplan_policy'],
        'contracts.execplan_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['approval_gates_policy'],
        'contracts.approval_gates_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['worktree_isolation_policy'],
        'contracts.worktree_isolation_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['doc_gardening_policy'],
        'contracts.doc_gardening_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['user_guides_support_usage_policy'],
        'contracts.user_guides_support_usage_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['user_guides_canonical_deference_policy'],
        'contracts.user_guides_canonical_deference_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['user_guides_update_sync_policy'],
        'contracts.user_guides_update_sync_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['non_coder_entrypoint_policy'],
        'contracts.non_coder_entrypoint_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['plain_language_support_response_policy'],
        'contracts.plain_language_support_response_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['term_definition_policy'],
        'contracts.term_definition_policy',
      );
      final templatePolicy = contracts['templates_read_policy'];
      if (templatePolicy is String &&
          !templatePolicy.toLowerCase().contains('read-on-demand')) {
        issues.add(
          'contracts.templates_read_policy must include read-on-demand guidance.',
        );
      }
      final glossaryContract =
          contracts['localization_glossary_source_of_truth'];
      if (glossaryContract is String &&
          !glossaryContract.contains(
            'docs/assistant/LOCALIZATION_GLOSSARY.md',
          )) {
        issues.add(
          'contracts.localization_glossary_source_of_truth must reference docs/assistant/LOCALIZATION_GLOSSARY.md.',
        );
      }
      final performanceContract =
          contracts['workspace_performance_source_of_truth'];
      if (performanceContract is String &&
          !performanceContract.contains(
            'docs/assistant/PERFORMANCE_BASELINES.md',
          )) {
        issues.add(
          'contracts.workspace_performance_source_of_truth must reference docs/assistant/PERFORMANCE_BASELINES.md.',
        );
      }
      final docsSyncPolicy = contracts['post_change_docs_sync_prompt_policy'];
      if (docsSyncPolicy is String &&
          !docsSyncPolicy.toLowerCase().contains('assistant docs sync')) {
        issues.add(
          'contracts.post_change_docs_sync_prompt_policy must include "Assistant Docs Sync" guidance.',
        );
      }
      final referencePolicy =
          contracts['inspiration_reference_discovery_policy'];
      if (referencePolicy is String &&
          !referencePolicy.contains(
            'REFERENCE_DISCOVERY_WORKFLOW.md',
          )) {
        issues.add(
          'contracts.inspiration_reference_discovery_policy must reference docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md.',
        );
      }
      final goldenPrinciples = contracts['golden_principles_source_of_truth'];
      if (goldenPrinciples is String &&
          !goldenPrinciples.contains('docs/assistant/GOLDEN_PRINCIPLES.md')) {
        issues.add(
          'contracts.golden_principles_source_of_truth must reference docs/assistant/GOLDEN_PRINCIPLES.md.',
        );
      }
      final execPlanPolicy = contracts['execplan_policy'];
      if (execPlanPolicy is String &&
          !execPlanPolicy.contains('docs/assistant/exec_plans/PLANS.md')) {
        issues.add(
          'contracts.execplan_policy must reference docs/assistant/exec_plans/PLANS.md.',
        );
      }
      final approvalGates = contracts['approval_gates_policy'];
      if (approvalGates is String &&
          !approvalGates.toLowerCase().contains('approval')) {
        issues.add(
          'contracts.approval_gates_policy must include approval guidance.',
        );
      }
      final worktreePolicy = contracts['worktree_isolation_policy'];
      if (worktreePolicy is String &&
          !worktreePolicy.toLowerCase().contains('worktree')) {
        issues.add(
          'contracts.worktree_isolation_policy must include worktree guidance.',
        );
      }
      final userGuideSupport = contracts['user_guides_support_usage_policy'];
      if (userGuideSupport is String &&
          (!userGuideSupport.contains('APP_USER_GUIDE.md') ||
              !userGuideSupport.contains('PLANNER_USER_GUIDE.md'))) {
        issues.add(
          'contracts.user_guides_support_usage_policy must reference both APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md.',
        );
      }
      final userGuideDeference =
          contracts['user_guides_canonical_deference_policy'];
      if (userGuideDeference is String &&
          !userGuideDeference.contains('APP_KNOWLEDGE.md')) {
        issues.add(
          'contracts.user_guides_canonical_deference_policy must reference APP_KNOWLEDGE.md precedence.',
        );
      }
      final userGuideSync = contracts['user_guides_update_sync_policy'];
      if (userGuideSync is String &&
          (!userGuideSync.contains('APP_USER_GUIDE.md') ||
              !userGuideSync.contains('PLANNER_USER_GUIDE.md'))) {
        issues.add(
          'contracts.user_guides_update_sync_policy must reference APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md targeted updates.',
        );
      }
      final nonCoderPolicy = contracts['non_coder_entrypoint_policy'];
      if (nonCoderPolicy is String &&
          (!nonCoderPolicy.contains('APP_USER_GUIDE.md') ||
              !nonCoderPolicy.contains('PLANNER_USER_GUIDE.md'))) {
        issues.add(
          'contracts.non_coder_entrypoint_policy must reference APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md.',
        );
      }
      final plainLanguagePolicy =
          contracts['plain_language_support_response_policy'];
      if (plainLanguagePolicy is String &&
          !plainLanguagePolicy.toLowerCase().contains('plain-language-first')) {
        issues.add(
          'contracts.plain_language_support_response_policy must require plain-language-first support responses.',
        );
      }
      final termDefinitionPolicy = contracts['term_definition_policy'];
      if (termDefinitionPolicy is String &&
          !termDefinitionPolicy.toLowerCase().contains('technical term')) {
        issues.add(
          'contracts.term_definition_policy must require concise technical-term definitions.',
        );
      }
    }

    _validateNoTemplateRoutingInManifest(issues, manifest);

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
    _validateNonEmptyString(
        issues, workflow['scope'], 'workflows[$index].scope');

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
    _validateCommandList(
      issues,
      workflow['validation_commands'],
      'workflows[$index].validation_commands',
    );
  }

  void _validateWorkflowSections(List<String> issues) {
    const workflowDocs = <String>[
      'docs/assistant/workflows/READER_WORKFLOW.md',
      'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
      'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
      'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
      'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
      'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
      'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
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

  void _validateWorkflowNegativeRouting(List<String> issues) {
    const workflowDocs = <String>[
      'docs/assistant/workflows/READER_WORKFLOW.md',
      'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
      'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
      'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
      'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
      'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
      'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    ];
    for (final relativePath in workflowDocs) {
      final file = _resolveFile(relativePath);
      if (!file.existsSync()) {
        continue;
      }
      final content = file.readAsStringSync().toLowerCase();
      if (!content.contains("don't use this workflow when")) {
        issues.add(
          'Workflow doc is missing explicit negative routing phrase "Don\'t use this workflow when...": $relativePath',
        );
      }
      if (!content.contains('instead use')) {
        issues.add(
          'Workflow doc is missing alternative route guidance ("Instead use ..."): $relativePath',
        );
      }
    }
  }

  void _validateFeatureGuideSections(List<String> issues) {
    const requiredHeadings = <String>[
      '## Use This Guide When',
      '## Do Not Use This Guide For',
      '## For Agents: Support Interaction Contract',
      '## Canonical Deference Rule',
      '## Quick Start (No Technical Background)',
      '## Terms in Plain English',
    ];
    const guides = <String>[
      'docs/assistant/features/APP_USER_GUIDE.md',
      'docs/assistant/features/PLANNER_USER_GUIDE.md',
    ];
    for (final relativePath in guides) {
      final file = _resolveFile(relativePath);
      if (!file.existsSync()) {
        continue;
      }
      final content = file.readAsStringSync();
      for (final heading in requiredHeadings) {
        if (!content.contains(heading)) {
          issues.add(
            'Feature guide is missing required section "$heading": $relativePath',
          );
        }
      }
      final lowered = content.toLowerCase();
      if (!lowered.contains('plain language')) {
        issues.add(
          'Feature guide support contract must require plain-language responses: $relativePath',
        );
      }
      if (!lowered.contains('cross-check') ||
          !content.contains('APP_KNOWLEDGE.md')) {
        issues.add(
          'Feature guide support contract must require canonical cross-check with APP_KNOWLEDGE.md: $relativePath',
        );
      }
      if (!lowered.contains('uncertainty')) {
        issues.add(
          'Feature guide support contract must include uncertainty handling language: $relativePath',
        );
      }
      if (!lowered.contains('define') || !lowered.contains('technical term')) {
        issues.add(
          'Feature guide support contract must require one-line technical-term definitions: $relativePath',
        );
      }
    }
  }

  void _validateUserGuideSupportRoutingPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('APP_USER_GUIDE.md') ||
          !text.contains('PLANNER_USER_GUIDE.md')) {
        issues.add(
          'AGENTS.md must route support/non-technical tasks to APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md.',
        );
      }
      if (!lowered.contains('plain language') &&
          !lowered.contains('plain-language')) {
        issues.add(
          'AGENTS.md support-routing policy must require plain-language responses for non-technical users.',
        );
      }
      if (!lowered.contains('canonical cross-check')) {
        issues.add(
          'AGENTS.md support-routing policy must require canonical cross-check before technical behavior claims.',
        );
      }
      if (!text.contains('## Non-Coder Communication Mode')) {
        issues.add(
          'AGENTS.md must include "## Non-Coder Communication Mode" section.',
        );
      }
      if (!lowered.contains('avoid jargon') ||
          !lowered.contains('define it in one short line')) {
        issues.add(
          'AGENTS.md non-coder communication policy must include jargon-avoidance and one-line term-definition guidance.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('APP_USER_GUIDE.md') ||
          !text.contains('PLANNER_USER_GUIDE.md')) {
        issues.add(
          'agent.md quick routing must include APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md for support/non-technical tasks.',
        );
      }
      if (!lowered.contains('plain language') &&
          !lowered.contains('plain-language')) {
        issues.add(
          'agent.md support-routing policy must require plain-language responses for non-technical users.',
        );
      }
      if (!lowered.contains('canonical cross-check')) {
        issues.add(
          'agent.md support-routing policy must require canonical cross-check before technical behavior claims.',
        );
      }
      if (!text.contains('## Non-Coder Communication Mode')) {
        issues.add(
          'agent.md must include "## Non-Coder Communication Mode" section.',
        );
      }
      if (!lowered.contains('plain language first') ||
          !lowered.contains('define it in one short line')) {
        issues.add(
          'agent.md non-coder communication policy must include plain-language-first and one-line term-definition guidance.',
        );
      }
    }
  }

  void _validateDocsMaintenanceUserGuideSyncPolicy(List<String> issues) {
    final file =
        _resolveFile('docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md');
    if (!file.existsSync()) {
      return;
    }
    final text = file.readAsStringSync();
    if (!text.contains('APP_USER_GUIDE.md') ||
        !text.contains('PLANNER_USER_GUIDE.md')) {
      issues.add(
        'DOCS_MAINTENANCE_WORKFLOW.md must include user-guide sync guidance for APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md.',
      );
    }
    final lowered = text.toLowerCase();
    if (!lowered.contains('user guide sections') &&
        !lowered.contains('user-guide sections')) {
      issues.add(
        'DOCS_MAINTENANCE_WORKFLOW.md must include targeted user-guide section update guidance.',
      );
    }
    if (!text.contains('Quick Start') ||
        !text.contains('Terms in Plain English')) {
      issues.add(
        'DOCS_MAINTENANCE_WORKFLOW.md must require preserving/updating beginner-focused sections (Quick Start, Terms in Plain English).',
      );
    }
  }

  void _validateCanonicalContracts(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('compatibility shim')) {
        issues.add(
          'AGENTS.md must state that it is a compatibility shim.',
        );
      }
    }

    final agentRunbook = _resolveFile('agent.md');
    if (agentRunbook.existsSync()) {
      final text = agentRunbook.readAsStringSync();
      if (!text.contains('short shim')) {
        issues.add(
          'agent.md must explain AGENTS.md compatibility role.',
        );
      }
    }

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
      if (!text.contains('Why two `APP_KNOWLEDGE.md` files:')) {
        issues.add(
          'APP_KNOWLEDGE.md must explain canonical-vs-bridge file split.',
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
      if (!text
          .contains('intentionally shorter than the canonical root document')) {
        issues.add(
          'Bridge doc must explain why it differs from canonical content.',
        );
      }
    }
  }

  void _validateTemplatePolicies(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('docs/assistant/templates/*') ||
          !text.toLowerCase().contains('read-on-demand only')) {
        issues.add(
          'AGENTS.md must declare docs/assistant/templates/* read-on-demand policy.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains('docs/assistant/templates/*') ||
          !text.toLowerCase().contains('read-on-demand only')) {
        issues.add(
          'agent.md must declare docs/assistant/templates/* read-on-demand policy.',
        );
      }
      if (!text.toLowerCase().contains('explicitly requests template/prompt')) {
        issues.add(
          'agent.md must state explicit user-request exception for template usage.',
        );
      }
    }

    final index = _resolveFile('docs/assistant/INDEX.md');
    if (index.existsSync()) {
      final text = index.readAsStringSync().toLowerCase();
      if (text.contains('docs/assistant/templates/')) {
        issues.add(
          'INDEX.md must not route private template files as default docs.',
        );
      }
    }
  }

  void _validateTemplateNewbieLayer(List<String> issues) {
    final template = _resolveFile(
        'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md');
    if (!template.existsSync()) {
      return;
    }
    final text = template.readAsStringSync();
    final lowered = text.toLowerCase();
    const heading =
        '## Newbie-First Layer (Optional: remove for developer-first repos)';
    if (!text.contains(heading)) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md must include "$heading".',
      );
    }
    if (!lowered.contains('assume user is a complete beginner/non-coder')) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must declare beginner default assumption.',
      );
    }
    if (!lowered.contains('unless this section is removed') ||
        !lowered.contains('explicitly requests technical depth')) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must include removable/override rule.',
      );
    }
    if (!lowered.contains(
      'do not reduce testing, validation, approval gates, or canonical precedence',
    )) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must preserve safety/governance guardrails.',
      );
    }
    if (!lowered.contains(
      'switch style while keeping all governance contracts unchanged',
    )) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must define developer-depth override behavior.',
      );
    }
    if (!lowered.contains(
      'plain-language-first, steps-second, canonical-check-last',
    )) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must require plain-language-first support structure.',
      );
    }
    if (!lowered.contains(
      'plain explanation -> numbered steps -> canonical check -> uncertainty note if needed',
    )) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must include support reply skeleton guidance.',
      );
    }
    if (!lowered
        .contains('define unavoidable technical terms in one sentence')) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must require one-sentence technical-term definitions.',
      );
    }
    if (!text.contains('## Quick Start (No Technical Background)')) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must require user guides to include "## Quick Start (No Technical Background)".',
      );
    }
    if (!text.contains('## Terms in Plain English')) {
      issues.add(
        'CODEX_PROJECT_BOOTSTRAP_PROMPT.md newbie layer must require user guides to include "## Terms in Plain English".',
      );
    }
  }

  void _validateNonCoderEntrypoints(List<String> issues) {
    final readme = _resolveFile('README.md');
    if (readme.existsSync()) {
      final text = readme.readAsStringSync();
      if (!text.contains('## If You Are Not a Developer, Start Here')) {
        issues.add(
          'README.md must include "## If You Are Not a Developer, Start Here" entrypoint section.',
        );
      }
      if (!text.contains('docs/assistant/features/APP_USER_GUIDE.md') ||
          !text.contains('docs/assistant/features/PLANNER_USER_GUIDE.md') ||
          !text.contains('docs/assistant/INDEX.md')) {
        issues.add(
          'README.md non-coder entrypoint section must link APP_USER_GUIDE.md, PLANNER_USER_GUIDE.md, and docs/assistant/INDEX.md.',
        );
      }
    }

    final appKnowledge = _resolveFile('APP_KNOWLEDGE.md');
    if (appKnowledge.existsSync()) {
      final text = appKnowledge.readAsStringSync();
      if (!text.contains('## If You Are Not a Developer (Read This First)')) {
        issues.add(
          'APP_KNOWLEDGE.md must include "## If You Are Not a Developer (Read This First)" section.',
        );
      }
      if (!text.contains('docs/assistant/features/APP_USER_GUIDE.md') ||
          !text.contains('docs/assistant/features/PLANNER_USER_GUIDE.md')) {
        issues.add(
          'APP_KNOWLEDGE.md non-coder section must route readers to APP_USER_GUIDE.md and PLANNER_USER_GUIDE.md.',
        );
      }
    }

    final index = _resolveFile('docs/assistant/INDEX.md');
    if (index.existsSync()) {
      final text = index.readAsStringSync();
      if (!text.contains('## Beginner Quick Path')) {
        issues.add(
          'INDEX.md must include "## Beginner Quick Path" section.',
        );
      }
      if (!text.contains('APP_USER_GUIDE.md') ||
          !text.contains('PLANNER_USER_GUIDE.md') ||
          !text.contains('APP_KNOWLEDGE.md')) {
        issues.add(
          'INDEX.md Beginner Quick Path must include APP_USER_GUIDE.md, PLANNER_USER_GUIDE.md, and APP_KNOWLEDGE.md routing.',
        );
      }
    }
  }

  void _validateLocalizationRoutingPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('LOCALIZATION_WORKFLOW.md') ||
          !text.contains('LOCALIZATION_GLOSSARY.md')) {
        issues.add(
          'AGENTS.md must route localization tasks to LOCALIZATION_WORKFLOW.md and LOCALIZATION_GLOSSARY.md.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains('LOCALIZATION_WORKFLOW.md') ||
          !text.contains('LOCALIZATION_GLOSSARY.md')) {
        issues.add(
          'agent.md must route localization tasks to LOCALIZATION_WORKFLOW.md and LOCALIZATION_GLOSSARY.md.',
        );
      }
    }
  }

  void _validatePerformanceRoutingPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('PERFORMANCE_WORKFLOW.md') ||
          !text.contains('PERFORMANCE_BASELINES.md')) {
        issues.add(
          'AGENTS.md must route performance tasks to PERFORMANCE_WORKFLOW.md and PERFORMANCE_BASELINES.md.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains('PERFORMANCE_WORKFLOW.md') ||
          !text.contains('PERFORMANCE_BASELINES.md')) {
        issues.add(
          'agent.md must route performance tasks to PERFORMANCE_WORKFLOW.md and PERFORMANCE_BASELINES.md.',
        );
      }
    }
  }

  void _validateReferenceDiscoveryPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('REFERENCE_DISCOVERY_WORKFLOW.md')) {
        issues.add(
          'AGENTS.md must route inspiration/parity tasks to REFERENCE_DISCOVERY_WORKFLOW.md.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains('REFERENCE_DISCOVERY_WORKFLOW.md')) {
        issues.add(
          'agent.md must route inspiration/parity tasks to REFERENCE_DISCOVERY_WORKFLOW.md.',
        );
      }
    }
  }

  void _validatePostChangeDocsSyncPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync().toLowerCase();
      if (!text.contains('assistant docs sync') ||
          !text.contains('significant')) {
        issues.add(
          'AGENTS.md must include significant-change Assistant Docs Sync prompt policy.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains(
            'Would you like me to run Assistant Docs Sync for this change now?',
          ) &&
          !text.toLowerCase().contains('assistant docs sync')) {
        issues.add(
          'agent.md must include mandatory post-significant-change Assistant Docs Sync prompt policy.',
        );
      }
    }
  }

  void _validateBranchSafetyPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync().toLowerCase();
      if (!text.contains('major changes') ||
          !text.contains('feat/*') ||
          !text.contains('main')) {
        issues.add(
          'AGENTS.md must enforce branch safety: major changes on feat/*, main stays stable.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync().toLowerCase();
      if (!text.contains('major changes') ||
          !text.contains('feat/*') ||
          !text.contains('main') ||
          !text.contains('pr flow')) {
        issues.add(
          'agent.md must enforce branch safety and PR flow for major work on main.',
        );
      }
    }

    final ciWorkflow =
        _resolveFile('docs/assistant/workflows/CI_REPO_WORKFLOW.md');
    if (ciWorkflow.existsSync()) {
      final text = ciWorkflow.readAsStringSync().toLowerCase();
      if (!text.contains('major changes directly on `main`') ||
          !text.contains('feat/*') ||
          !text.contains('required checks')) {
        issues.add(
          'CI_REPO_WORKFLOW.md must include explicit main/feat/* branch safety and required checks policy.',
        );
      }
    }
  }

  void _validateGoldenAndExecPlanDiscoverability(List<String> issues) {
    final index = _resolveFile('docs/assistant/INDEX.md');
    if (index.existsSync()) {
      final text = index.readAsStringSync();
      if (!text.contains('docs/assistant/GOLDEN_PRINCIPLES.md')) {
        issues.add(
          'INDEX.md must include docs/assistant/GOLDEN_PRINCIPLES.md for discoverability.',
        );
      }
      if (!text.contains('docs/assistant/exec_plans/PLANS.md')) {
        issues.add(
          'INDEX.md must include docs/assistant/exec_plans/PLANS.md for discoverability.',
        );
      }
    }

    final readme = _resolveFile('README.md');
    if (readme.existsSync()) {
      final text = readme.readAsStringSync();
      if (!text.contains('docs/assistant/GOLDEN_PRINCIPLES.md')) {
        issues.add(
          'README.md onboarding docs must include docs/assistant/GOLDEN_PRINCIPLES.md.',
        );
      }
      if (!text.contains('docs/assistant/exec_plans/PLANS.md')) {
        issues.add(
          'README.md onboarding docs must include docs/assistant/exec_plans/PLANS.md.',
        );
      }
    }
  }

  void _validateApprovalGatesPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('## Approval Gates')) {
        issues.add('AGENTS.md must include "## Approval Gates" section.');
      }
      if (!lowered.contains('ask') || !lowered.contains('approval')) {
        issues.add(
          'AGENTS.md Approval Gates must explicitly require asking for approval.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('## Approval Gates')) {
        issues.add('agent.md must include "## Approval Gates" section.');
      }
      if (!lowered.contains('ask') || !lowered.contains('approval')) {
        issues.add(
          'agent.md Approval Gates must explicitly require asking for approval.',
        );
      }
    }
  }

  void _validateExecPlanPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('## ExecPlans')) {
        issues.add('AGENTS.md must include "## ExecPlans" section.');
      }
      if (!lowered.contains('major') ||
          !lowered.contains('multi-file') ||
          !lowered.contains('docs/assistant/exec_plans/')) {
        issues.add(
          'AGENTS.md ExecPlans section must require major/multi-file work to use docs/assistant/exec_plans/.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('## ExecPlans')) {
        issues.add('agent.md must include "## ExecPlans" section.');
      }
      if (!lowered.contains('major') ||
          !lowered.contains('multi-file') ||
          !lowered.contains('docs/assistant/exec_plans/')) {
        issues.add(
          'agent.md ExecPlans section must require major/multi-file work to use docs/assistant/exec_plans/.',
        );
      }
    }
  }

  void _validateWorktreeIsolationPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('## Worktree Isolation') ||
          !text.toLowerCase().contains('worktree')) {
        issues.add(
          'AGENTS.md must include "## Worktree Isolation" guidance with worktree usage.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains('## Worktree Isolation') ||
          !text.toLowerCase().contains('worktree')) {
        issues.add(
          'agent.md must include "## Worktree Isolation" guidance with worktree usage.',
        );
      }
    }

    const workflowDocs = <String>[
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
      'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    ];
    for (final relativePath in workflowDocs) {
      final file = _resolveFile(relativePath);
      if (!file.existsSync()) {
        continue;
      }
      final text = file.readAsStringSync().toLowerCase();
      if (!text.contains('worktree')) {
        issues.add(
          '$relativePath must include worktree isolation guidance for parallel streams.',
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

  void _validateRequiredWorkflowId(
    List<String> issues, {
    required Map<String, Map<String, dynamic>> workflowsById,
    required String requiredId,
    required String expectedDoc,
  }) {
    final workflow = workflowsById[requiredId];
    if (workflow == null) {
      issues.add('Manifest must include required workflow id "$requiredId".');
      return;
    }
    final doc = workflow['doc'];
    if (doc != expectedDoc) {
      issues.add(
        'Manifest workflow "$requiredId" must point to "$expectedDoc".',
      );
      return;
    }
    if (!_exists(doc)) {
      issues.add('Manifest required workflow doc does not exist: $doc');
    }
  }

  void _validateNoTemplateRoutingInManifest(
    List<String> issues,
    Map<String, dynamic> manifest,
  ) {
    final canonical = manifest['canonical'];
    if (canonical is Map<String, dynamic>) {
      for (final entry in canonical.entries) {
        final value = entry.value;
        if (value is String && _isTemplatePath(value)) {
          issues.add(
            'Template path must not appear in manifest canonical routing: ${entry.key} -> $value',
          );
        }
      }
    }

    final bridges = manifest['bridges'];
    if (bridges is List) {
      for (final value in bridges) {
        if (value is String && _isTemplatePath(value)) {
          issues.add(
            'Template path must not appear in manifest bridges routing: $value',
          );
        }
      }
    }

    final workflows = manifest['workflows'];
    if (workflows is List) {
      for (var i = 0; i < workflows.length; i++) {
        final workflow = workflows[i];
        if (workflow is! Map<String, dynamic>) {
          continue;
        }
        final doc = workflow['doc'];
        if (doc is String && _isTemplatePath(doc)) {
          issues.add(
            'Template path must not appear as workflow doc (workflows[$i].doc): $doc',
          );
        }
        _checkNoTemplatePathInList(
          issues,
          workflow['primary_files'],
          'workflows[$i].primary_files',
        );
        _checkNoTemplatePathInList(
          issues,
          workflow['targeted_tests'],
          'workflows[$i].targeted_tests',
        );
      }
    }
  }

  void _checkNoTemplatePathInList(
    List<String> issues,
    dynamic value,
    String label,
  ) {
    if (value is! List) {
      return;
    }
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is String && _isTemplatePath(entry)) {
        issues.add(
          'Template path must not appear in manifest routing list ($label[$i]): $entry',
        );
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

  void _validateCommandList(
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
        continue;
      }
      if (!_isPowerShellSafe(entry)) {
        issues.add(
          '$label[$i] appears bash-specific; use PowerShell-safe syntax: $entry',
        );
      }
    }
  }

  bool _isPowerShellSafe(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    for (final pattern in _bashOnlyPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return false;
      }
    }
    return true;
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

  bool _isTemplatePath(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return normalized.startsWith('docs/assistant/templates/');
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
