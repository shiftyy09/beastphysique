import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for FirebaseFirestore
import 'firebase_options.dart';
import 'kepernyok/indulo_kepernyo.dart';
import 'tema/alkalmazas_tema.dart';
import 'tema/theme_controller.dart';

void main() {
  // Wrap the app in a guarded zone to catch all Dart errors
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('=== APP INDULÁSA ===');

    // This is the custom error widget that will be displayed on the screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Hiba történt:\n\n${details.exceptionAsString()}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    };

    // This handles errors caught by the Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter hiba elkapva: ${details.exception}');
      // The ErrorWidget.builder will be used to display the error
      // In release mode, this might not show on screen without custom setup.
      // We already have ErrorWidget.builder, but this ensures a fallback.
    };

    try {
      debugPrint('Firebase inicializálása...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Enable Firestore persistence *after* Firebase is initialized
      FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
      debugPrint(
          'Firebase sikeresen inicializálva és Firestore perzisztencia engedélyezve');
    } catch (e) {
      debugPrint('Firebase init hiba: $e');
      // If Firebase init fails before runApp, display a simple error screen immediately
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Kritikus hiba az indításkor:\n\nFirebase inicializálás sikertelen: $e',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return; // Stop further execution in main()
    }

    debugPrint('=== APP FUTÁSA ===');
    runApp(const BeastPhysicalAlkalmazas());
  }, (error, stackTrace) {
    // This handles async errors outside the Flutter framework
    debugPrint('Zóna hiba elkapva: $error');
    debugPrint('Stack trace: $stackTrace');
    // For errors caught by runZonedGuarded, ensure an error screen is shown
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Kritikus hiba:\n\n${error.toString()}\n\n${stackTrace
                      .toString().substring(0, stackTrace
                      .toString()
                      .length > 500 ? 500 : stackTrace
                      .toString()
                      .length)}...', // Limit stack trace length
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  });
}

class BeastPhysicalAlkalmazas extends StatelessWidget {
  const BeastPhysicalAlkalmazas({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('BeastPhysicalAlkalmazas build');
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isLight, child) {
        debugPrint(
            'MaterialApp felépítése - Téma: ${isLight ? "VILÁGOS" : "SÖTÉT"}');
        return MaterialApp(
          title: 'Beast Physique',
          debugShowCheckedModeBanner: false,
          theme: isLight ? AlkalmazasTema.vilagTema : AlkalmazasTema.sotetTema,
          home: const InduloKepernyo(),
        );
      },
    );
  }
}