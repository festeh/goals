import 'package:dimaist/main.dart';
import 'package:dimaist/models/project.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockAppDatabase mockAppDatabase;

  setUpAll(() async {
    // Initialize shared preferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockApiService = MockApiService();
    mockAppDatabase = MockAppDatabase();
  });

  testWidgets('MainScreen renders and shows Today view by default',
      (WidgetTester tester) async {
    // Mock the ApiService and AppDatabase
    when(mockAppDatabase.allProjects).thenAnswer((_) async => [
          Project(id: 1, name: 'Inbox', order: 1, isInbox: true, color: 'grey'),
        ]);
    when(mockApiService.syncData()).thenAnswer((_) async => null);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(),
      ),
    );

    // Wait for the app to finish loading
    await tester.pumpAndSettle();

    // Verify that the "Today" view is displayed.
    expect(find.text('Today'), findsOneWidget);

    // Verify that the main screen is displayed
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
