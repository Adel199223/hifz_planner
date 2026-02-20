import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_planner/main.dart';

void main() {
  testWidgets('loads Today screen with NavigationRail', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HifzPlannerApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('TodayScreen'), findsOneWidget);
  });

  testWidgets('navigates to Bookmarks from rail', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HifzPlannerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.text('BookmarksScreen'), findsOneWidget);
  });
}
