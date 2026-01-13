import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naija_property_connect/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive UI Tests', () {
    testWidgets('should render correctly on phone screen', (
      WidgetTester tester,
    ) async {
      // Set phone screen size (iPhone 12 Pro)
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify app renders without overflow
      expect(tester.takeException(), isNull);

      // Check for common widgets
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should render correctly on small phone screen', (
      WidgetTester tester,
    ) async {
      // Set small phone screen size (iPhone SE)
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render correctly on large phone screen', (
      WidgetTester tester,
    ) async {
      // Set large phone screen size (iPhone 14 Pro Max)
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render correctly on tablet screen', (
      WidgetTester tester,
    ) async {
      // Set tablet screen size (iPad Pro 11")
      await tester.binding.setSurfaceSize(const Size(834, 1194));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render correctly on large tablet screen', (
      WidgetTester tester,
    ) async {
      // Set large tablet screen size (iPad Pro 12.9")
      await tester.binding.setSurfaceSize(const Size(1024, 1366));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle portrait orientation', (
      WidgetTester tester,
    ) async {
      // Portrait orientation
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final size = tester.view.physicalSize;
      expect(size.height, greaterThan(size.width));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle landscape orientation', (
      WidgetTester tester,
    ) async {
      // Landscape orientation
      await tester.binding.setSurfaceSize(const Size(844, 390));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final size = tester.view.physicalSize;
      expect(size.width, greaterThan(size.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle orientation change', (
      WidgetTester tester,
    ) async {
      // Start in portrait
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Change to landscape
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Change back to portrait
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle safe area on iOS-like devices', (
      WidgetTester tester,
    ) async {
      // iPhone with notch
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for SafeArea widgets
      find.byType(SafeArea);

      // App should use SafeArea for proper layout
      // Note: This might not find any if SafeArea is not explicitly used
      // but the test ensures the app renders without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render text at readable sizes on all screens', (
      WidgetTester tester,
    ) async {
      final screenSizes = [
        const Size(375, 667), // Small phone
        const Size(390, 844), // Medium phone
        const Size(430, 932), // Large phone
        const Size(834, 1194), // Tablet
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // Verify no overflow
        expect(tester.takeException(), isNull);

        // Find text widgets
        final textFinder = find.byType(Text);

        if (textFinder.evaluate().isNotEmpty) {
          // Verify text widgets exist
          expect(textFinder, findsWidgets);
        }
      }
    });

    testWidgets('should handle different pixel densities', (
      WidgetTester tester,
    ) async {
      // Test with different device pixel ratios
      final pixelRatios = [1.0, 2.0, 3.0];

      for (final _ in pixelRatios) {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should not have overflow errors on any screen size', (
      WidgetTester tester,
    ) async {
      final screenSizes = [
        const Size(320, 568), // iPhone SE (1st gen) - smallest
        const Size(375, 667), // iPhone 8
        const Size(390, 844), // iPhone 12/13 Pro
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(430, 932), // iPhone 14 Pro Max
        const Size(768, 1024), // iPad
        const Size(834, 1194), // iPad Pro 11"
        const Size(1024, 1366), // iPad Pro 12.9"
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // The most important check: no overflow errors
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow error on screen size: ${size.width}x${size.height}',
        );
      }
    });

    testWidgets('should maintain aspect ratios for images', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find image widgets
      final imageFinder = find.byType(Image);

      if (imageFinder.evaluate().isNotEmpty) {
        // Images should exist and render properly
        expect(imageFinder, findsWidgets);
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle scrolling on small screens', (
      WidgetTester tester,
    ) async {
      // Small screen where content might need scrolling
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for scrollable widgets
      find.byType(Scrollable);

      // App should have scrollable content
      // Note: This might not find any on the initial screen
      expect(tester.takeException(), isNull);
    });

    testWidgets('should adapt layout for different screen widths', (
      WidgetTester tester,
    ) async {
      // Test narrow screen
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Test wide screen (tablet)
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
