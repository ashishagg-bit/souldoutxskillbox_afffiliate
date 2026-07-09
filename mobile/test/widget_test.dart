import 'package:flutter_test/flutter_test.dart';

import 'package:skillbox_affiliate/main.dart';

void main() {
  testWidgets('App boots to the More menu', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillboxAffiliateApp());
    await tester.pumpAndSettle();

    expect(find.text('Avadh Nagpal'), findsOneWidget);
    expect(find.text('Gigs'), findsOneWidget);
  });
}
