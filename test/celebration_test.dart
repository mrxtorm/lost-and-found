import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_app/widgets/celebration_overlay.dart';

void main() {
  testWidgets('celebration shows from a popped route navigator', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => ElevatedButton(
                onPressed: () {
                  final nav = Navigator.of(c);
                  Navigator.pop(c);
                  CelebrationOverlay.show(nav.overlay);
                },
                child: const Text('approve'),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('approve'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Item returned!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Item returned!'), findsNothing);
  });
}
