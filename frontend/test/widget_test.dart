import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aigym_frontend/main.dart';

void main() {
  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(const GymPlannerApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
