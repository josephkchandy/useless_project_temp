// This is a basic Flutter widget test for your FoodSwipeApp.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_flutter/main.dart';

// IMPORTANT: Make sure this import path points to your main.dart file.
// If your package name is different from 'tinder_final', you'll need to change it.

// A mock camera description to be used in tests.
final mockCamera = CameraDescription(
  name: 'mock',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 90,
);

void main() {
  testWidgets('FoodSwipeApp builds and shows the title', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // We provide the mockCamera to satisfy the requirement of the FoodSwipeApp widget.
    await tester.pumpWidget(FoodSwipeApp(camera: mockCamera));

    // Wait for widgets to settle, especially if there are any async operations on startup.
    await tester.pumpAndSettle();

    // Verify that the main app title 'SNACKER' is present.
    // We check for it twice because it might appear in the AppBar.
    expect(find.text('SNACKER'), findsAtLeastNWidgets(1));

    // Verify that the default counter app's text ('0' or '1') is NOT present.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}
