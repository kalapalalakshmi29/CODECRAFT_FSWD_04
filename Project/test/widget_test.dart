import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_chat_app/main.dart';

void main() {
  testWidgets('Chat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatApp());
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}