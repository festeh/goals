import 'package:dimaist/models/note.dart';
import 'package:dimaist/screens/wear_note_screen.dart';
import 'package:dimaist/screens/wear_recording_screen.dart';
import 'package:dimaist/services/api_service.dart';
import 'package:dimaist/services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:dimaist/screens/wear_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggingService.setup();
  try {
    await ApiService.syncData();
  } catch (e) {
    LoggingService.logger.severe('Error syncing data on wear app startup', e);
  }

  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goals - Wear',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.compact,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const WearMainScreen(),
            );
          case '/recording':
            return MaterialPageRoute(
              builder: (context) => const WearRecordingScreen(),
            );
          case '/note':
            final note = settings.arguments as Note;
            return MaterialPageRoute(
              builder: (context) => WearNoteScreen(note: note),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const WearMainScreen(),
            );
        }
      },
    );
  }
}
