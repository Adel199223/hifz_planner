import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

enum RecoveryWizardScenario {
  missedSession,
  missedDay,
  severalDays,
  heavyBacklog,
}

Future<void> showPlannerRecoveryWizard({
  required BuildContext context,
  required AppStrings strings,
  required VoidCallback onOpenMyPlan,
  required VoidCallback onMinimumDay,
}) async {
  var selected = RecoveryWizardScenario.missedSession;

  String labelFor(RecoveryWizardScenario scenario) {
    return switch (scenario) {
      RecoveryWizardScenario.missedSession =>
        strings.recoveryScenarioMissedSession,
      RecoveryWizardScenario.missedDay => strings.recoveryScenarioMissedDay,
      RecoveryWizardScenario.severalDays => strings.recoveryScenarioSeveralDays,
      RecoveryWizardScenario.heavyBacklog =>
        strings.recoveryScenarioHeavyBacklog,
    };
  }

  String recommendationFor(RecoveryWizardScenario scenario) {
    return switch (scenario) {
      RecoveryWizardScenario.missedSession =>
        strings.recoveryRecommendationMissedSession,
      RecoveryWizardScenario.missedDay =>
        strings.recoveryRecommendationMissedDay,
      RecoveryWizardScenario.severalDays =>
        strings.recoveryRecommendationSeveralDays,
      RecoveryWizardScenario.heavyBacklog =>
        strings.recoveryRecommendationHeavyBacklog,
    };
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(strings.recoveryAssistantTitle),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.recoveryAssistantQuestion),
                    const SizedBox(height: 12),
                    for (final scenario in RecoveryWizardScenario.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          key: ValueKey('recovery_wizard_${scenario.name}'),
                          contentPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: selected == scenario
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                            ),
                          ),
                          title: Text(labelFor(scenario)),
                          trailing: Icon(
                            selected == scenario
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          onTap: () {
                            setState(() {
                              selected = scenario;
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      strings.recoveryAssistantRecommendationTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recommendationFor(selected),
                      key: const ValueKey('recovery_wizard_recommendation'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(strings.close),
              ),
              OutlinedButton(
                key: const ValueKey('recovery_wizard_minimum_day'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onMinimumDay();
                },
                child: Text(strings.todayMinimumDayAction),
              ),
              FilledButton(
                key: const ValueKey('recovery_wizard_open_plan'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onOpenMyPlan();
                },
                child: Text(strings.todayOpenMyPlan),
              ),
            ],
          );
        },
      );
    },
  );
}
