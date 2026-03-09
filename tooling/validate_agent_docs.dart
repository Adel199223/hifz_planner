import 'dart:convert';
import 'dart:io';

const List<String> _requiredFiles = <String>[
  'AGENTS.md',
  'agent.md',
  'APP_KNOWLEDGE.md',
  'README.md',
  '.gitignore',
  '.github/workflows/dart.yml',
  'docs/assistant/APP_KNOWLEDGE.md',
  'docs/assistant/DB_DRIFT_KNOWLEDGE.md',
  'docs/assistant/features/START_HERE_USER_GUIDE.md',
  'docs/assistant/GOLDEN_PRINCIPLES.md',
  'docs/assistant/INDEX.md',
  'docs/assistant/ISSUE_MEMORY.md',
  'docs/assistant/ISSUE_MEMORY.json',
  'docs/assistant/LOCAL_CAPABILITIES.md',
  'docs/assistant/LOCAL_ENV_PROFILE.example.md',
  'docs/assistant/LOCALIZATION_GLOSSARY.md',
  'docs/assistant/PERFORMANCE_BASELINES.md',
  'docs/assistant/SESSION_RESUME.md',
  'docs/assistant/exec_plans/PLANS.md',
  'docs/assistant/exec_plans/active',
  'docs/assistant/exec_plans/completed',
  'docs/assistant/manifest.json',
  'docs/assistant/workflows/READER_WORKFLOW.md',
  'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
  'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
  'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
  'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
  'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
  'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
  'docs/assistant/workflows/PLANNER_WORKFLOW.md',
  'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
  'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
  'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
  'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
  'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
  'docs/assistant/templates/BOOTSTRAP_TEMPLATE_MAP.json',
  'docs/assistant/templates/BOOTSTRAP_CORE_CONTRACT.md',
  'docs/assistant/templates/BOOTSTRAP_MODULES_AND_TRIGGERS.md',
  'docs/assistant/templates/BOOTSTRAP_ISSUE_MEMORY_SYSTEM.md',
  'docs/assistant/templates/BOOTSTRAP_PROJECT_HARNESS_SYNC_POLICY.md',
  'docs/assistant/templates/BOOTSTRAP_LOCAL_ENV_OVERLAY.md',
  'docs/assistant/templates/BOOTSTRAP_CAPABILITY_DISCOVERY.md',
  'docs/assistant/templates/BOOTSTRAP_WORKTREE_BUILD_IDENTITY.md',
  'docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
  'docs/assistant/templates/BOOTSTRAP_HOST_INTEGRATION_PREFLIGHT.md',
  'docs/assistant/templates/BOOTSTRAP_HARNESS_ISOLATION_AND_DIAGNOSTICS.md',
  'docs/assistant/templates/BOOTSTRAP_UPDATE_POLICY.md',
  'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
  'tooling/validate_workspace_hygiene.dart',
  'test/tooling/validate_workspace_hygiene_test.dart',
];

const List<String> _requiredTemplateModuleIds = <String>[
  'core_contract',
  'modules_and_triggers',
  'issue_memory_system',
  'project_harness_sync',
  'local_env_overlay',
  'capability_discovery',
  'worktree_build_identity',
  'roadmap_governance',
  'host_integration_preflight',
  'harness_isolation_diagnostics',
  'bootstrap_update_policy',
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
  'docs/assistant/ISSUE_MEMORY.md',
  'docs/assistant/LOCAL_CAPABILITIES.md',
  'docs/assistant/LOCAL_ENV_PROFILE.example.md',
  'docs/assistant/LOCALIZATION_GLOSSARY.md',
  'docs/assistant/PERFORMANCE_BASELINES.md',
  'docs/assistant/SESSION_RESUME.md',
  'docs/assistant/exec_plans/PLANS.md',
  'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
  'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
  'docs/assistant/workflows/LOCALIZATION_WORKFLOW.md',
  'docs/assistant/workflows/PERFORMANCE_WORKFLOW.md',
  'docs/assistant/workflows/REFERENCE_DISCOVERY_WORKFLOW.md',
  'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
  'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
  'docs/assistant/workflows/READER_WORKFLOW.md',
  'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
  'docs/assistant/workflows/PLANNER_WORKFLOW.md',
  'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
  'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
  'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
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
  AgentDocsValidator({required this.rootDirectory});

  final Directory rootDirectory;

  List<String> validate() {
    final issues = <String>[];
    _validateRequiredFiles(issues);
    _validateManifest(issues);
    _validateWorkflowSections(issues);
    _validateWorkflowNegativeRouting(issues);
    _validateFeatureGuideSections(issues);
    _validateStartHereGuideSections(issues);
    _validateSessionResumeSections(issues);
    _validateRoadmapRestingState(issues);
    _validateCanonicalContracts(issues);
    _validateBranchSafetyPolicy(issues);
    _validateApprovalGatesPolicy(issues);
    _validateExecPlanPolicy(issues);
    _validateWorktreeIsolationPolicy(issues);
    _validateUserGuideSupportRoutingPolicy(issues);
    _validateDocsMaintenanceUserGuideSyncPolicy(issues);
    _validateFreshSessionResumeRoutingPolicy(issues);
    _validateRoadmapGovernanceRoutingPolicy(issues);
    _validateProjectHarnessSyncRoutingPolicy(issues);
    _validateLocalizationRoutingPolicy(issues);
    _validatePerformanceRoutingPolicy(issues);
    _validateReferenceDiscoveryPolicy(issues);
    _validatePostChangeDocsSyncPolicy(issues);
    _validateTemplatePolicies(issues);
    _validateVendoredTemplateCommitPolicy(issues);
    _validateVendoredTemplateIgnorePolicy(issues);
    _validateBootstrapRoadmapGovernanceTemplate(issues);
    _validateBootstrapTemplateMapIntegrity(issues);
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
    } else if (version != 14) {
      issues.add('Manifest key "version" must be 14.');
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

    final sessionResume = manifest['session_resume'];
    if (sessionResume is! String || sessionResume.trim().isEmpty) {
      issues.add(
        'Manifest key "session_resume" must be a non-empty string path.',
      );
    } else {
      if (sessionResume != 'docs/assistant/SESSION_RESUME.md') {
        issues.add(
          'Manifest key "session_resume" must be docs/assistant/SESSION_RESUME.md.',
        );
      }
      if (!_exists(sessionResume)) {
        issues.add(
          'Manifest session_resume path does not exist: $sessionResume',
        );
      }
    }

    final userGuides = manifest['user_guides'];
    if (userGuides is! List) {
      issues.add('Manifest key "user_guides" must be an array.');
    } else {
      final values = <String>[];
      for (var i = 0; i < userGuides.length; i++) {
        final value = userGuides[i];
        if (value is! String || value.trim().isEmpty) {
          issues.add(
            'Manifest user_guides[$i] must be a non-empty string path.',
          );
          continue;
        }
        values.add(value);
        if (!_exists(value)) {
          issues.add('Manifest user guide path does not exist: $value');
        }
      }
      const startHere = 'docs/assistant/features/START_HERE_USER_GUIDE.md';
      const appGuide = 'docs/assistant/features/APP_USER_GUIDE.md';
      const plannerGuide = 'docs/assistant/features/PLANNER_USER_GUIDE.md';
      if (!values.contains(startHere) ||
          !values.contains(appGuide) ||
          !values.contains(plannerGuide)) {
        issues.add(
          'Manifest user_guides must include START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md.',
        );
      }
      if (values.isNotEmpty && values.first != startHere) {
        issues.add(
          'Manifest user_guides must list START_HERE_USER_GUIDE.md first.',
        );
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
        requiredId: 'project_harness_sync',
        expectedDoc:
            'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'roadmap_governance',
        expectedDoc: 'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'scheduling_companion',
        expectedDoc:
            'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      );
      _validateRequiredWorkflowId(
        issues,
        workflowsById: workflowsById,
        requiredId: 'worktree_build_identity',
        expectedDoc:
            'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
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
        contracts['vendored_template_assets_policy'],
        'contracts.vendored_template_assets_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['project_harness_sync_policy'],
        'contracts.project_harness_sync_policy',
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
        contracts['issue_memory_policy'],
        'contracts.issue_memory_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['local_env_overlay_policy'],
        'contracts.local_env_overlay_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['capability_inventory_policy'],
        'contracts.capability_inventory_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['worktree_build_identity_policy'],
        'contracts.worktree_build_identity_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['commit_shorthand_policy'],
        'contracts.commit_shorthand_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['push_shorthand_policy'],
        'contracts.push_shorthand_policy',
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
        contracts['fresh_session_resume_policy'],
        'contracts.fresh_session_resume_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_anchor_file_policy'],
        'contracts.roadmap_anchor_file_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['resume_trigger_policy'],
        'contracts.resume_trigger_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_resume_update_policy'],
        'contracts.roadmap_resume_update_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_trigger_policy'],
        'contracts.roadmap_trigger_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_granularity_policy'],
        'contracts.roadmap_granularity_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_artifact_authority_policy'],
        'contracts.roadmap_artifact_authority_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_detour_policy'],
        'contracts.roadmap_detour_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_closeout_policy'],
        'contracts.roadmap_closeout_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['roadmap_resting_state_policy'],
        'contracts.roadmap_resting_state_policy',
      );
      _validateNonEmptyString(
        issues,
        contracts['execplan_archive_policy'],
        'contracts.execplan_archive_policy',
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
      if (templatePolicy is String &&
          !templatePolicy.toLowerCase().contains('committed project assets')) {
        issues.add(
          'contracts.templates_read_policy must explain that vendored templates remain committed project assets.',
        );
      }
      final vendoredTemplateAssetsPolicy =
          contracts['vendored_template_assets_policy'];
      if (vendoredTemplateAssetsPolicy is! String ||
          !vendoredTemplateAssetsPolicy.contains(
            'docs/assistant/templates/*',
          ) ||
          !vendoredTemplateAssetsPolicy.toLowerCase().contains(
            'do not remove or ignore',
          )) {
        issues.add(
          'contracts.vendored_template_assets_policy must reference docs/assistant/templates/* and forbid remove/ignore defaults.',
        );
      }
      final projectHarnessSyncPolicy = contracts['project_harness_sync_policy'];
      if (projectHarnessSyncPolicy is! String ||
          !projectHarnessSyncPolicy.contains(
            'PROJECT_HARNESS_SYNC_WORKFLOW.md',
          ) ||
          !projectHarnessSyncPolicy.contains('implement the template files') ||
          !projectHarnessSyncPolicy.contains('sync project harness') ||
          !projectHarnessSyncPolicy.toLowerCase().contains(
            'without editing docs/assistant/templates/*',
          )) {
        issues.add(
          'contracts.project_harness_sync_policy must reference PROJECT_HARNESS_SYNC_WORKFLOW.md, the local apply triggers, and the no-template-edit rule.',
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
      final issueMemoryPolicy = contracts['issue_memory_policy'];
      if (issueMemoryPolicy is String &&
          (!issueMemoryPolicy.contains('docs/assistant/ISSUE_MEMORY.md') ||
              !issueMemoryPolicy.contains(
                'docs/assistant/ISSUE_MEMORY.json',
              ))) {
        issues.add(
          'contracts.issue_memory_policy must reference docs/assistant/ISSUE_MEMORY.md and docs/assistant/ISSUE_MEMORY.json.',
        );
      }
      final localEnvOverlayPolicy = contracts['local_env_overlay_policy'];
      if (localEnvOverlayPolicy is String &&
          (!localEnvOverlayPolicy.contains(
                'docs/assistant/LOCAL_ENV_PROFILE.example.md',
              ) ||
              !localEnvOverlayPolicy.contains(
                'docs/assistant/LOCAL_ENV_PROFILE.local.md',
              ))) {
        issues.add(
          'contracts.local_env_overlay_policy must reference docs/assistant/LOCAL_ENV_PROFILE.example.md and docs/assistant/LOCAL_ENV_PROFILE.local.md.',
        );
      }
      final capabilityInventoryPolicy =
          contracts['capability_inventory_policy'];
      if (capabilityInventoryPolicy is String &&
          !capabilityInventoryPolicy.contains(
            'docs/assistant/LOCAL_CAPABILITIES.md',
          )) {
        issues.add(
          'contracts.capability_inventory_policy must reference docs/assistant/LOCAL_CAPABILITIES.md.',
        );
      }
      final worktreeBuildIdentityPolicy =
          contracts['worktree_build_identity_policy'];
      if (worktreeBuildIdentityPolicy is String &&
          (!worktreeBuildIdentityPolicy.contains(
                'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
              ) ||
              !worktreeBuildIdentityPolicy.contains(
                'tooling/print_build_identity.dart',
              ))) {
        issues.add(
          'contracts.worktree_build_identity_policy must reference docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md and tooling/print_build_identity.dart.',
        );
      }
      final commitShorthandPolicy = contracts['commit_shorthand_policy'];
      if (commitShorthandPolicy is String &&
          (!commitShorthandPolicy.toLowerCase().contains('bare commit') ||
              !commitShorthandPolicy.toLowerCase().contains(
                'logical grouped commits',
              ))) {
        issues.add(
          'contracts.commit_shorthand_policy must define bare commit triage and logical grouped commits.',
        );
      }
      final pushShorthandPolicy = contracts['push_shorthand_policy'];
      if (pushShorthandPolicy is String &&
          (!pushShorthandPolicy.toLowerCase().contains('bare push') ||
              !pushShorthandPolicy.toLowerCase().contains(
                'push+pr+merge+cleanup',
              ))) {
        issues.add(
          'contracts.push_shorthand_policy must define bare push as Push+PR+Merge+Cleanup.',
        );
      }
      final referencePolicy =
          contracts['inspiration_reference_discovery_policy'];
      if (referencePolicy is String &&
          !referencePolicy.contains('REFERENCE_DISCOVERY_WORKFLOW.md')) {
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
          (!userGuideSupport.contains('START_HERE_USER_GUIDE.md') ||
              !userGuideSupport.contains('APP_USER_GUIDE.md') ||
              !userGuideSupport.contains('PLANNER_USER_GUIDE.md'))) {
        issues.add(
          'contracts.user_guides_support_usage_policy must reference START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md.',
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
          (!userGuideSync.contains('START_HERE_USER_GUIDE.md') ||
              !userGuideSync.contains('APP_USER_GUIDE.md') ||
              !userGuideSync.contains('PLANNER_USER_GUIDE.md'))) {
        issues.add(
          'contracts.user_guides_update_sync_policy must reference START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md targeted updates.',
        );
      }
      final nonCoderPolicy = contracts['non_coder_entrypoint_policy'];
      if (nonCoderPolicy is String &&
          (!nonCoderPolicy.contains('START_HERE_USER_GUIDE.md') ||
              !nonCoderPolicy.contains('APP_USER_GUIDE.md') ||
              !nonCoderPolicy.contains('PLANNER_USER_GUIDE.md'))) {
        issues.add(
          'contracts.non_coder_entrypoint_policy must reference START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md.',
        );
      }
      final beginnerEntrypoint = contracts['beginner_guide_entrypoint_policy'];
      if (beginnerEntrypoint is! String ||
          !beginnerEntrypoint.contains('START_HERE_USER_GUIDE.md')) {
        issues.add(
          'contracts.beginner_guide_entrypoint_policy must reference START_HERE_USER_GUIDE.md.',
        );
      }
      final beginnerSync = contracts['beginner_guide_sync_policy'];
      if (beginnerSync is! String ||
          !beginnerSync.contains('START_HERE_USER_GUIDE.md')) {
        issues.add(
          'contracts.beginner_guide_sync_policy must reference START_HERE_USER_GUIDE.md.',
        );
      }
      final freshSessionResume = contracts['fresh_session_resume_policy'];
      if (freshSessionResume is! String ||
          !freshSessionResume.contains('docs/assistant/SESSION_RESUME.md')) {
        issues.add(
          'contracts.fresh_session_resume_policy must reference docs/assistant/SESSION_RESUME.md.',
        );
      }
      final roadmapAnchorFile = contracts['roadmap_anchor_file_policy'];
      if (roadmapAnchorFile is! String ||
          !roadmapAnchorFile.contains('docs/assistant/SESSION_RESUME.md') ||
          !roadmapAnchorFile.toLowerCase().contains('anchor file')) {
        issues.add(
          'contracts.roadmap_anchor_file_policy must reference docs/assistant/SESSION_RESUME.md as the roadmap anchor file.',
        );
      }
      final resumeTrigger = contracts['resume_trigger_policy'];
      if (resumeTrigger is! String ||
          !resumeTrigger.contains('resume master plan') ||
          !resumeTrigger.contains('docs/assistant/SESSION_RESUME.md')) {
        issues.add(
          'contracts.resume_trigger_policy must reference `resume master plan` and docs/assistant/SESSION_RESUME.md.',
        );
      }
      final roadmapResumeUpdate = contracts['roadmap_resume_update_policy'];
      if (roadmapResumeUpdate is! String ||
          !roadmapResumeUpdate.contains('active wave ExecPlan') ||
          !roadmapResumeUpdate.contains('active roadmap tracker') ||
          !roadmapResumeUpdate.contains('docs/assistant/SESSION_RESUME.md')) {
        issues.add(
          'contracts.roadmap_resume_update_policy must reference the active wave ExecPlan, active roadmap tracker, and docs/assistant/SESSION_RESUME.md.',
        );
      }
      final roadmapTriggerPolicy = contracts['roadmap_trigger_policy'];
      if (roadmapTriggerPolicy is! String ||
          !roadmapTriggerPolicy.toLowerCase().contains('small isolated work') ||
          !roadmapTriggerPolicy.toLowerCase().contains('execplan-only') ||
          !roadmapTriggerPolicy.toLowerCase().contains('master plan')) {
        issues.add(
          'contracts.roadmap_trigger_policy must define small isolated work, ExecPlan-only, and master plan/roadmap equivalence.',
        );
      }
      final roadmapGranularityPolicy = contracts['roadmap_granularity_policy'];
      if (roadmapGranularityPolicy is! String ||
          !roadmapGranularityPolicy.contains('single-file fixes') ||
          !roadmapGranularityPolicy.toLowerCase().contains('docs cleanup')) {
        issues.add(
          'contracts.roadmap_granularity_policy must distinguish roadmap-grade work from single-file fixes and docs cleanup.',
        );
      }
      final roadmapAuthorityPolicy =
          contracts['roadmap_artifact_authority_policy'];
      if (roadmapAuthorityPolicy is! String ||
          !roadmapAuthorityPolicy.contains(
            'docs/assistant/SESSION_RESUME.md',
          ) ||
          !roadmapAuthorityPolicy.toLowerCase().contains('anchor file') ||
          !roadmapAuthorityPolicy.toLowerCase().contains(
            'active roadmap tracker',
          ) ||
          !roadmapAuthorityPolicy.toLowerCase().contains(
            'active wave execplan',
          ) ||
          !roadmapAuthorityPolicy.toLowerCase().contains('separate worktree')) {
        issues.add(
          'contracts.roadmap_artifact_authority_policy must reference SESSION_RESUME.md, the active roadmap tracker, the active wave ExecPlan, and separate-worktree authority.',
        );
      }
      final roadmapDetourPolicy = contracts['roadmap_detour_policy'];
      if (roadmapDetourPolicy is! String ||
          !roadmapDetourPolicy.contains('active wave ExecPlan') ||
          !roadmapDetourPolicy.contains('active roadmap tracker') ||
          !roadmapDetourPolicy.contains('docs/assistant/SESSION_RESUME.md')) {
        issues.add(
          'contracts.roadmap_detour_policy must reference the active wave ExecPlan, active roadmap tracker, and docs/assistant/SESSION_RESUME.md update order.',
        );
      }
      final roadmapCloseoutPolicy = contracts['roadmap_closeout_policy'];
      if (roadmapCloseoutPolicy is! String ||
          !roadmapCloseoutPolicy.toLowerCase().contains(
            'current roadmap status',
          ) ||
          !roadmapCloseoutPolicy.toLowerCase().contains('exact next step')) {
        issues.add(
          'contracts.roadmap_closeout_policy must require current roadmap status and exact next step in closeout messaging.',
        );
      }
      final roadmapRestingStatePolicy = contracts['roadmap_resting_state_policy'];
      if (roadmapRestingStatePolicy is! String ||
          !roadmapRestingStatePolicy.contains(
            'docs/assistant/exec_plans/completed/',
          ) ||
          !roadmapRestingStatePolicy.contains(
            'latest completed roadmap tracker',
          )) {
        issues.add(
          'contracts.roadmap_resting_state_policy must reference docs/assistant/exec_plans/completed/ and the latest completed roadmap tracker.',
        );
      }
      final execplanArchivePolicy = contracts['execplan_archive_policy'];
      if (execplanArchivePolicy is! String ||
          !execplanArchivePolicy.contains(
            'docs/assistant/exec_plans/active/',
          ) ||
          !execplanArchivePolicy.contains(
            'docs/assistant/exec_plans/completed/',
          )) {
        issues.add(
          'contracts.execplan_archive_policy must reference docs/assistant/exec_plans/active/ and docs/assistant/exec_plans/completed/.',
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
      issues.add('Manifest key "last_updated" must use YYYY-MM-DD format.');
    }
  }

  void _validateManifestWorkflow(
    List<String> issues,
    Map<String, dynamic> workflow, {
    required int index,
  }) {
    _validateNonEmptyString(issues, workflow['id'], 'workflows[$index].id');
    _validateNonEmptyString(
      issues,
      workflow['scope'],
      'workflows[$index].scope',
    );

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
      'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
      'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
      'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
      'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
      'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
      'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
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
      'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
      'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
      'docs/assistant/workflows/QURANCOM_DATA_WORKFLOW.md',
      'docs/assistant/workflows/PLANNER_WORKFLOW.md',
      'docs/assistant/workflows/SCHEDULING_COMPANION_WORKFLOW.md',
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
      'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
      'docs/assistant/workflows/WORKTREE_BUILD_IDENTITY_WORKFLOW.md',
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

  void _validateStartHereGuideSections(List<String> issues) {
    const relativePath = 'docs/assistant/features/START_HERE_USER_GUIDE.md';
    const requiredHeadings = <String>[
      '## Quick Start (No Technical Background)',
      '## What This App Helps You Do',
      '## The Main Places You Need',
      '## How The Parts Work Together',
      '## What To Ignore At First',
      '## Common Situations',
      '## What This App Does Not Do Yet',
      '## If You Want More Detail',
    ];
    final file = _resolveFile(relativePath);
    if (!file.existsSync()) {
      return;
    }
    final content = file.readAsStringSync();
    for (final heading in requiredHeadings) {
      if (!content.contains(heading)) {
        issues.add(
          'Beginner guide is missing required section "$heading": $relativePath',
        );
      }
    }
  }

  void _validateSessionResumeSections(List<String> issues) {
    const relativePath = 'docs/assistant/SESSION_RESUME.md';
    const requiredHeadings = <String>[
      '## Fresh Session Rule',
      '## Resume Trigger',
      '## Current Roadmap',
      '## Current Wave',
      '## Current Status',
      '## Exact Next Step',
      '## Active Worktree And Branch',
      '## Read These Next',
      '## Completed Roadmaps',
      '## Detours And Open Notes',
    ];
    final file = _resolveFile(relativePath);
    if (!file.existsSync()) {
      return;
    }
    final content = file.readAsStringSync();
    for (final heading in requiredHeadings) {
      if (!content.contains(heading)) {
        issues.add(
          'Session resume doc is missing required section "$heading": $relativePath',
        );
      }
    }
    if (!content.contains('resume master plan')) {
      issues.add(
        'SESSION_RESUME.md must document `resume master plan` as the explicit trigger phrase.',
      );
    }
    if (!content.toLowerCase().contains('roadmap anchor file')) {
      issues.add(
        'SESSION_RESUME.md must explicitly identify itself as the roadmap anchor file.',
      );
    }
  }

  void _validateRoadmapRestingState(List<String> issues) {
    final sessionResume = _resolveFile('docs/assistant/SESSION_RESUME.md');
    if (sessionResume.existsSync()) {
      final content = sessionResume.readAsStringSync();
      final lowered = content.toLowerCase();
      final readTheseNext = _sectionBody(content, '## Read These Next');
      final noActiveRoadmap = lowered.contains('no active roadmap') ||
          lowered.contains('no active wave') ||
          lowered.contains('define the next backlog or a new roadmap');
      if (noActiveRoadmap) {
        if (!readTheseNext.contains('docs/assistant/exec_plans/completed/')) {
          issues.add(
            'SESSION_RESUME.md must point Read These Next to completed roadmap history when no roadmap is active.',
          );
        }
        if (readTheseNext.contains('docs/assistant/exec_plans/active/')) {
          issues.add(
            'SESSION_RESUME.md must not point Read These Next to docs/assistant/exec_plans/active/ when no roadmap is active.',
          );
        }
      }
    }

    final activePlansDir = _resolveDirectory('docs/assistant/exec_plans/active');
    if (!activePlansDir.existsSync()) {
      return;
    }
    for (final entity in activePlansDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.md')) {
        continue;
      }
      final content = entity.readAsStringSync();
      final progress = _sectionBody(content, '## Progress');
      final checklistLines = progress
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.startsWith('- ['))
          .toList();
      if (checklistLines.isNotEmpty &&
          checklistLines.every((line) => line.startsWith('- [x]'))) {
        final relativePath = entity.path
            .substring(rootDirectory.path.length + 1)
            .replaceAll(Platform.pathSeparator, '/');
        issues.add(
          'Finished ExecPlans and completed roadmap trackers must move from active to completed: $relativePath',
        );
      }
    }
  }

  void _validateUserGuideSupportRoutingPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('START_HERE_USER_GUIDE.md') ||
          !text.contains('APP_USER_GUIDE.md') ||
          !text.contains('PLANNER_USER_GUIDE.md')) {
        issues.add(
          'AGENTS.md must route support/non-technical tasks to START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md.',
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
      if (!text.contains('START_HERE_USER_GUIDE.md') ||
          !text.contains('APP_USER_GUIDE.md') ||
          !text.contains('PLANNER_USER_GUIDE.md')) {
        issues.add(
          'agent.md quick routing must include START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md for support/non-technical tasks.',
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
    final file = _resolveFile(
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    );
    if (!file.existsSync()) {
      return;
    }
    final text = file.readAsStringSync();
    if (!text.contains('START_HERE_USER_GUIDE.md') ||
        !text.contains('APP_USER_GUIDE.md') ||
        !text.contains('PLANNER_USER_GUIDE.md')) {
      issues.add(
        'DOCS_MAINTENANCE_WORKFLOW.md must include user-guide sync guidance for START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md.',
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
    if (!text.contains('docs/assistant/SESSION_RESUME.md') ||
        !text.toLowerCase().contains('active roadmap') ||
        !text.toLowerCase().contains('next step')) {
      issues.add(
        'DOCS_MAINTENANCE_WORKFLOW.md must include SESSION_RESUME.md update guidance for roadmap state and next-step changes.',
      );
    }
  }

  void _validateFreshSessionResumeRoutingPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('## Fresh Session Resume Protocol')) {
        issues.add(
          'AGENTS.md must include "## Fresh Session Resume Protocol" section.',
        );
      }
      if (!text.contains('docs/assistant/SESSION_RESUME.md') ||
          !text.contains('resume master plan')) {
        issues.add(
          'AGENTS.md must route fresh-session roadmap resume to docs/assistant/SESSION_RESUME.md and mention `resume master plan`.',
        );
      }
      if (!text.toLowerCase().contains('roadmap anchor file')) {
        issues.add(
          'AGENTS.md fresh-session routing must identify docs/assistant/SESSION_RESUME.md as the roadmap anchor file.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      if (!text.contains('## Fresh Session Resume Protocol')) {
        issues.add(
          'agent.md must include "## Fresh Session Resume Protocol" section.',
        );
      }
      if (!text.contains('docs/assistant/SESSION_RESUME.md') ||
          !text.contains('resume master plan')) {
        issues.add(
          'agent.md must route fresh-session roadmap resume to docs/assistant/SESSION_RESUME.md and mention `resume master plan`.',
        );
      }
      if (!text.toLowerCase().contains('roadmap anchor file')) {
        issues.add(
          'agent.md fresh-session routing must identify docs/assistant/SESSION_RESUME.md as the roadmap anchor file.',
        );
      }
    }

    final readme = _resolveFile('README.md');
    if (readme.existsSync()) {
      final text = readme.readAsStringSync();
      if (!text.contains('## Fresh Session Resume') ||
          !text.contains('docs/assistant/SESSION_RESUME.md') ||
          !text.contains('resume master plan')) {
        issues.add(
          'README.md must include a Fresh Session Resume section that links docs/assistant/SESSION_RESUME.md and mentions `resume master plan`.',
        );
      }
      if (!text.toLowerCase().contains('roadmap anchor file')) {
        issues.add(
          'README.md Fresh Session Resume section must identify docs/assistant/SESSION_RESUME.md as the roadmap anchor file.',
        );
      }
    }

    final index = _resolveFile('docs/assistant/INDEX.md');
    if (index.existsSync()) {
      final text = index.readAsStringSync();
      if (!text.contains('## Fresh Session Resume') ||
          !text.contains('docs/assistant/SESSION_RESUME.md') ||
          !text.contains('resume master plan')) {
        issues.add(
          'INDEX.md must include a Fresh Session Resume section that routes to docs/assistant/SESSION_RESUME.md and mentions `resume master plan`.',
        );
      }
      if (!text.toLowerCase().contains('roadmap anchor file')) {
        issues.add(
          'INDEX.md Fresh Session Resume section must identify docs/assistant/SESSION_RESUME.md as the roadmap anchor file.',
        );
      }
    }

    final plans = _resolveFile('docs/assistant/exec_plans/PLANS.md');
    if (plans.existsSync()) {
      final text = plans.readAsStringSync();
      if (!text.contains('docs/assistant/SESSION_RESUME.md')) {
        issues.add(
          'PLANS.md roadmap return protocol must require updating docs/assistant/SESSION_RESUME.md.',
        );
      }
    }
  }

  void _validateRoadmapGovernanceRoutingPolicy(List<String> issues) {
    final roadmapWorkflow = _resolveFile(
      'docs/assistant/workflows/ROADMAP_WORKFLOW.md',
    );
    if (roadmapWorkflow.existsSync()) {
      final text = roadmapWorkflow.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('ExecPlan-only') ||
          !lowered.contains('small isolated work') ||
          !lowered.contains('separate worktree') ||
          !text.contains('docs/assistant/SESSION_RESUME.md')) {
        issues.add(
          'ROADMAP_WORKFLOW.md must define adaptive granularity, separate-worktree authority, and docs/assistant/SESSION_RESUME.md as the stable first stop.',
        );
      }
      if (!lowered.contains('roadmap anchor file') ||
          !lowered.contains('master plan') ||
          !lowered.contains('stages are optional') ||
          !lowered.contains('exact next step') ||
          !lowered.contains('resequence')) {
        issues.add(
          'ROADMAP_WORKFLOW.md must define roadmap/master-plan equivalence, anchor-file wording, stage/wave flexibility, exact-next-step guidance, and resequencing support.',
        );
      }
    }

    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('## Roadmap Trigger Policy') ||
          !text.contains('## Roadmap Artifact Authority')) {
        issues.add(
          'AGENTS.md must include Roadmap Trigger Policy and Roadmap Artifact Authority sections.',
        );
      }
      if (!text.contains('docs/assistant/workflows/ROADMAP_WORKFLOW.md') ||
          !lowered.contains('small isolated work') ||
          !text.contains('ExecPlan-only') ||
          !lowered.contains('active worktree')) {
        issues.add(
          'AGENTS.md must reference ROADMAP_WORKFLOW.md, adaptive granularity, and active-worktree authority.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('## Roadmap Trigger Policy') ||
          !text.contains('## Roadmap Artifact Authority')) {
        issues.add(
          'agent.md must include Roadmap Trigger Policy and Roadmap Artifact Authority sections.',
        );
      }
      if (!text.contains('docs/assistant/workflows/ROADMAP_WORKFLOW.md') ||
          !lowered.contains('small isolated work') ||
          !text.contains('ExecPlan-only') ||
          !lowered.contains('active worktree')) {
        issues.add(
          'agent.md must reference ROADMAP_WORKFLOW.md, adaptive granularity, and active-worktree authority.',
        );
      }
    }

    final plans = _resolveFile('docs/assistant/exec_plans/PLANS.md');
    if (plans.existsSync()) {
      final text = plans.readAsStringSync();
      if (!text.contains('## Adaptive Planning Rule') ||
          !text.contains('## Roadmap Artifact Authority') ||
          !text.contains(
            'long-running multi-wave or stage-plus-wave, restart-sensitive work -> roadmap',
          )) {
        issues.add(
          'PLANS.md must include adaptive planning guidance and roadmap artifact authority.',
        );
      }
    }

    final readme = _resolveFile('README.md');
    if (readme.existsSync()) {
      final text = readme.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('docs/assistant/workflows/ROADMAP_WORKFLOW.md') ||
          !lowered.contains('active worktree')) {
        issues.add(
          'README.md must reference ROADMAP_WORKFLOW.md and explain that the active worktree is the live roadmap source during in-flight wave work.',
        );
      }
    }
  }

  void _validateProjectHarnessSyncRoutingPolicy(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('implement the template files') ||
          !text.contains('sync project harness') ||
          !text.contains(
            'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
          )) {
        issues.add(
          'AGENTS.md must route `implement the template files` and `sync project harness` to PROJECT_HARNESS_SYNC_WORKFLOW.md.',
        );
      }
      if (!lowered.contains('committed project assets')) {
        issues.add(
          'AGENTS.md must state that vendored templates are committed project assets.',
        );
      }
    }

    final runbook = _resolveFile('agent.md');
    if (runbook.existsSync()) {
      final text = runbook.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('implement the template files') ||
          !text.contains('sync project harness') ||
          !text.contains(
            'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
          )) {
        issues.add(
          'agent.md must route `implement the template files` and `sync project harness` to PROJECT_HARNESS_SYNC_WORKFLOW.md.',
        );
      }
      if (!lowered.contains('committed project assets') ||
          !lowered.contains('do not edit')) {
        issues.add(
          'agent.md must explain that vendored templates are committed project assets and that local apply should not edit them by default.',
        );
      }
    }

    final readme = _resolveFile('README.md');
    if (readme.existsSync()) {
      final text = readme.readAsStringSync();
      if (!text.contains('## Vendored Bootstrap Apply') ||
          !text.contains('implement the template files') ||
          !text.contains('sync project harness') ||
          !text.contains(
            'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
          )) {
        issues.add(
          'README.md must include a Vendored Bootstrap Apply section that routes `implement the template files` to PROJECT_HARNESS_SYNC_WORKFLOW.md.',
        );
      }
    }

    final index = _resolveFile('docs/assistant/INDEX.md');
    if (index.existsSync()) {
      final text = index.readAsStringSync();
      if (!text.contains('## Vendored Template Apply') ||
          !text.contains('implement the template files') ||
          !text.contains('sync project harness') ||
          !text.contains('PROJECT_HARNESS_SYNC_WORKFLOW.md')) {
        issues.add(
          'INDEX.md must include Vendored Template Apply routing for `implement the template files` and `sync project harness`.',
        );
      }
    }

    final docsWorkflow = _resolveFile(
      'docs/assistant/workflows/DOCS_MAINTENANCE_WORKFLOW.md',
    );
    if (docsWorkflow.existsSync()) {
      final text = docsWorkflow.readAsStringSync();
      if (!text.contains('implement the template files') ||
          !text.contains('PROJECT_HARNESS_SYNC_WORKFLOW.md')) {
        issues.add(
          'DOCS_MAINTENANCE_WORKFLOW.md must negatively route `implement the template files` to PROJECT_HARNESS_SYNC_WORKFLOW.md.',
        );
      }
    }

    final harnessWorkflow = _resolveFile(
      'docs/assistant/workflows/PROJECT_HARNESS_SYNC_WORKFLOW.md',
    );
    if (harnessWorkflow.existsSync()) {
      final text = harnessWorkflow.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('implement the template files') ||
          !text.contains('sync project harness') ||
          !text.contains('docs/assistant/templates/*') ||
          (!lowered.contains("don't edit") &&
              !lowered.contains('do not edit'))) {
        issues.add(
          'PROJECT_HARNESS_SYNC_WORKFLOW.md must document the local apply triggers and the no-template-edit default.',
        );
      }
    }
  }

  void _validateCanonicalContracts(List<String> issues) {
    final agentsShim = _resolveFile('AGENTS.md');
    if (agentsShim.existsSync()) {
      final text = agentsShim.readAsStringSync();
      if (!text.contains('compatibility shim')) {
        issues.add('AGENTS.md must state that it is a compatibility shim.');
      }
    }

    final agentRunbook = _resolveFile('agent.md');
    if (agentRunbook.existsSync()) {
      final text = agentRunbook.readAsStringSync();
      if (!text.contains('short shim')) {
        issues.add('agent.md must explain AGENTS.md compatibility role.');
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
      if (!text.contains(
        'intentionally shorter than the canonical root document',
      )) {
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

  void _validateVendoredTemplateCommitPolicy(List<String> issues) {
    final workflow = _resolveFile(
      'docs/assistant/workflows/COMMIT_PUBLISH_WORKFLOW.md',
    );
    if (!workflow.existsSync()) {
      return;
    }
    final text = workflow.readAsStringSync().toLowerCase();
    if (!text.contains('docs/assistant/templates/*') ||
        (!(text.contains('remove or ignore') ||
            text.contains('removing or ignoring')))) {
      issues.add(
        'COMMIT_PUBLISH_WORKFLOW.md must state that vendored docs/assistant/templates/* files are not remove/ignore candidates by default.',
      );
    }
    if (!text.contains('vendored template sync') ||
        !text.contains('harness implementation from vendored templates')) {
      issues.add(
        'COMMIT_PUBLISH_WORKFLOW.md must define the default commit split between vendored template sync and harness implementation.',
      );
    }
  }

  void _validateVendoredTemplateIgnorePolicy(List<String> issues) {
    final gitignore = _resolveFile('.gitignore');
    if (!gitignore.existsSync()) {
      return;
    }
    final text = gitignore.readAsStringSync();
    final lines = text.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) {
        continue;
      }
      if (line == 'docs/assistant/templates' ||
          line == 'docs/assistant/templates/' ||
          line.startsWith('docs/assistant/templates/')) {
        issues.add(
          '.gitignore must not ignore vendored docs/assistant/templates/* files.',
        );
      }
    }
    if (!text.contains('!docs/assistant/templates/**')) {
      issues.add(
        '.gitignore must explicitly protect vendored docs/assistant/templates/** from accidental ignore rules.',
      );
    }
  }

  void _validateBootstrapRoadmapGovernanceTemplate(List<String> issues) {
    final roadmapTemplate = _resolveFile(
      'docs/assistant/templates/BOOTSTRAP_ROADMAP_GOVERNANCE.md',
    );
    if (roadmapTemplate.existsSync()) {
      final text = roadmapTemplate.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!lowered.contains('roadmap') ||
          !lowered.contains('wave') ||
          !text.contains('ExecPlan') ||
          !text.contains('docs/assistant/SESSION_RESUME.md') ||
          !lowered.contains('separate worktree')) {
        issues.add(
          'BOOTSTRAP_ROADMAP_GOVERNANCE.md must define roadmap terminology, SESSION_RESUME.md, and separate-worktree authority.',
        );
      }
      if (!lowered.contains('single-file fixes') ||
          !lowered.contains('one-shot docs cleanup') ||
          !text.contains('ExecPlan-only')) {
        issues.add(
          'BOOTSTRAP_ROADMAP_GOVERNANCE.md must define adaptive thresholds for no-roadmap, ExecPlan-only, and roadmap-grade work.',
        );
      }
      if (!lowered.contains('roadmap anchor file') ||
          !lowered.contains('master plan') ||
          !lowered.contains('stage') ||
          !lowered.contains('exact next step') ||
          !text.contains('docs/assistant/exec_plans/completed/')) {
        issues.add(
          'BOOTSTRAP_ROADMAP_GOVERNANCE.md must define roadmap/master-plan equivalence, SESSION_RESUME.md as the roadmap anchor file, stage/wave terminology, exact-next-step closeout guidance, and the archive-first resting state.',
        );
      }
    }

    final modules = _resolveFile(
      'docs/assistant/templates/BOOTSTRAP_MODULES_AND_TRIGGERS.md',
    );
    if (modules.existsSync()) {
      final text = modules.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('Roadmap Governance') ||
          !text.contains('BOOTSTRAP_ROADMAP_GOVERNANCE.md') ||
          !lowered.contains('single-file fixes') ||
          !text.contains('ExecPlan-only')) {
        issues.add(
          'BOOTSTRAP_MODULES_AND_TRIGGERS.md must reference Roadmap Governance, BOOTSTRAP_ROADMAP_GOVERNANCE.md, and adaptive activation thresholds.',
        );
      }
      if (!text.contains('implement the template files') ||
          !lowered.contains('project harness sync') ||
          !lowered.contains('roadmap anchor file')) {
        issues.add(
          'BOOTSTRAP_MODULES_AND_TRIGGERS.md must reference local harness apply triggers and the roadmap anchor-file model.',
        );
      }
    }

    final prompt = _resolveFile(
      'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
    );
    if (prompt.existsSync()) {
      final text = prompt.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('BOOTSTRAP_ROADMAP_GOVERNANCE.md') ||
          !lowered.contains('long-running multi-wave') ||
          !text.contains('SESSION_RESUME.md')) {
        issues.add(
          'CODEX_PROJECT_BOOTSTRAP_PROMPT.md must reference BOOTSTRAP_ROADMAP_GOVERNANCE.md, adaptive roadmap mode, and SESSION_RESUME.md generation.',
        );
      }
      if (!text.contains('implement the template files') ||
          !lowered.contains('full vendored template set')) {
        issues.add(
          'CODEX_PROJECT_BOOTSTRAP_PROMPT.md must describe the local `implement the template files` flow and the full vendored template set.',
        );
      }
    }

    final updatePolicy = _resolveFile(
      'docs/assistant/templates/BOOTSTRAP_UPDATE_POLICY.md',
    );
    if (updatePolicy.existsSync()) {
      final text = updatePolicy.readAsStringSync();
      final lowered = text.toLowerCase();
      if (!text.contains('BOOTSTRAP_ROADMAP_GOVERNANCE.md') ||
          !lowered.contains('do not leak app-specific dates') ||
          !lowered.contains('adaptive')) {
        issues.add(
          'BOOTSTRAP_UPDATE_POLICY.md must preserve adaptive roadmap governance and anti-overfitting rules for BOOTSTRAP_ROADMAP_GOVERNANCE.md.',
        );
      }
    }
  }

  void _validateBootstrapTemplateMapIntegrity(List<String> issues) {
    const templateMapPath =
        'docs/assistant/templates/BOOTSTRAP_TEMPLATE_MAP.json';
    final templateMapFile = _resolveFile(templateMapPath);
    if (!templateMapFile.existsSync()) {
      return;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(templateMapFile.readAsStringSync());
    } catch (error) {
      issues.add('BOOTSTRAP_TEMPLATE_MAP.json must be valid JSON: $error');
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      issues.add('BOOTSTRAP_TEMPLATE_MAP.json root must be a JSON object.');
      return;
    }

    final entrypoint = decoded['entrypoint'];
    if (entrypoint is! String || entrypoint.trim().isEmpty) {
      issues.add(
        'BOOTSTRAP_TEMPLATE_MAP.json must define a non-empty "entrypoint" path.',
      );
    } else if (!_exists(entrypoint)) {
      issues.add(
        'BOOTSTRAP_TEMPLATE_MAP.json entrypoint path does not exist: $entrypoint',
      );
    }

    final modules = decoded['modules'];
    if (modules is! List) {
      issues.add('BOOTSTRAP_TEMPLATE_MAP.json must define a "modules" array.');
      return;
    }

    final moduleIds = <String>{};
    for (var i = 0; i < modules.length; i++) {
      final module = modules[i];
      if (module is! Map<String, dynamic>) {
        issues.add(
          'BOOTSTRAP_TEMPLATE_MAP.json modules[$i] must be an object.',
        );
        continue;
      }
      final id = module['id'];
      final path = module['path'];
      if (id is! String || id.trim().isEmpty) {
        issues.add(
          'BOOTSTRAP_TEMPLATE_MAP.json modules[$i].id must be a non-empty string.',
        );
      } else {
        moduleIds.add(id);
      }
      if (path is! String || path.trim().isEmpty) {
        issues.add(
          'BOOTSTRAP_TEMPLATE_MAP.json modules[$i].path must be a non-empty string.',
        );
      } else if (!_exists(path)) {
        issues.add(
          'BOOTSTRAP_TEMPLATE_MAP.json references missing template file: $path',
        );
      }
    }

    for (final requiredId in _requiredTemplateModuleIds) {
      if (!moduleIds.contains(requiredId)) {
        issues.add(
          'BOOTSTRAP_TEMPLATE_MAP.json must include required module id "$requiredId".',
        );
      }
    }
  }

  void _validateTemplateNewbieLayer(List<String> issues) {
    final template = _resolveFile(
      'docs/assistant/templates/CODEX_PROJECT_BOOTSTRAP_PROMPT.md',
    );
    if (!template.existsSync()) {
      return;
    }
    final text = template.readAsStringSync();
    final lowered = text.toLowerCase();
    const heading =
        '## Newbie-First Layer (Optional: remove for developer-first repos)';
    if (!text.contains(heading)) {
      issues.add('CODEX_PROJECT_BOOTSTRAP_PROMPT.md must include "$heading".');
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
    if (!lowered.contains(
      'define unavoidable technical terms in one sentence',
    )) {
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
      if (!text.contains('docs/assistant/features/START_HERE_USER_GUIDE.md') ||
          !text.contains('docs/assistant/features/APP_USER_GUIDE.md') ||
          !text.contains('docs/assistant/features/PLANNER_USER_GUIDE.md') ||
          !text.contains('docs/assistant/INDEX.md')) {
        issues.add(
          'README.md non-coder entrypoint section must link START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, PLANNER_USER_GUIDE.md, and docs/assistant/INDEX.md.',
        );
      }
      final startIndex = text.indexOf(
        'docs/assistant/features/START_HERE_USER_GUIDE.md',
      );
      final appIndex = text.indexOf(
        'docs/assistant/features/APP_USER_GUIDE.md',
      );
      if (startIndex == -1 || appIndex == -1 || startIndex > appIndex) {
        issues.add(
          'README.md non-coder entrypoint section must mention START_HERE_USER_GUIDE.md before APP_USER_GUIDE.md.',
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
      if (!text.contains('docs/assistant/features/START_HERE_USER_GUIDE.md') ||
          !text.contains('docs/assistant/features/APP_USER_GUIDE.md') ||
          !text.contains('docs/assistant/features/PLANNER_USER_GUIDE.md')) {
        issues.add(
          'APP_KNOWLEDGE.md non-coder section must route readers to START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, and PLANNER_USER_GUIDE.md.',
        );
      }
    }

    final index = _resolveFile('docs/assistant/INDEX.md');
    if (index.existsSync()) {
      final text = index.readAsStringSync();
      if (!text.contains('## Beginner Quick Path')) {
        issues.add('INDEX.md must include "## Beginner Quick Path" section.');
      }
      if (!text.contains('START_HERE_USER_GUIDE.md') ||
          !text.contains('APP_USER_GUIDE.md') ||
          !text.contains('PLANNER_USER_GUIDE.md') ||
          !text.contains('APP_KNOWLEDGE.md')) {
        issues.add(
          'INDEX.md Beginner Quick Path must include START_HERE_USER_GUIDE.md, APP_USER_GUIDE.md, PLANNER_USER_GUIDE.md, and APP_KNOWLEDGE.md routing.',
        );
      }
      final startIndex = text.indexOf('START_HERE_USER_GUIDE.md');
      final appIndex = text.indexOf('APP_USER_GUIDE.md');
      if (startIndex == -1 || appIndex == -1 || startIndex > appIndex) {
        issues.add(
          'INDEX.md Beginner Quick Path must mention START_HERE_USER_GUIDE.md before APP_USER_GUIDE.md.',
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

    final ciWorkflow = _resolveFile(
      'docs/assistant/workflows/CI_REPO_WORKFLOW.md',
    );
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

  void _validatePathList(List<String> issues, dynamic value, String label) {
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

  void _validateCommandList(List<String> issues, dynamic value, String label) {
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

  String _sectionBody(String markdown, String heading) {
    final start = markdown.indexOf(heading);
    if (start == -1) {
      return '';
    }
    final afterHeading = markdown.substring(start + heading.length);
    final nextHeading = RegExp(r'\n##\s').firstMatch(afterHeading);
    if (nextHeading == null) {
      return afterHeading;
    }
    return afterHeading.substring(0, nextHeading.start);
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
  final validator = AgentDocsValidator(rootDirectory: Directory.current);
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
