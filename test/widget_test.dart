import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/app.dart';
import 'package:hostelhub/core/config/env.dart';
import 'package:hostelhub/core/strings.dart';

void main() {
  testWidgets('App renders shell or missing config appropriately', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HostelHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    if (!Env.isConfigured) {
      expect(find.text(AppStrings.configMissingTitle), findsWidgets);
    } else {
      expect(find.text(AppStrings.navDashboard), findsWidgets);
    }
  });
}
