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
    };

    try {
      debugPrint('Firebase inicializálása...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Enable Firestore persistence *after* Firebase is initialized
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      debugPrint('Firebase sikeresen inicializálva és Firestore perzisztencia engedélyezve');
    } catch (e) {
      debugPrint('Firebase init hiba: $e');
      // Throw the error to be caught by our handler and displayed on screen
      throw Exception('Firebase inicializálás sikertelen: $e');
    }
    
    debugPrint('=== APP FUTÁSA ===');
    runApp(const BeastPhysicalAlkalmazas());
  }, (error, stackTrace) {
    // This handles async errors outside the Flutter framework
    debugPrint('Zóna hiba elkapva: $error');
    debugPrint('Stack trace: $stackTrace');
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
        debugPrint('MaterialApp felépítése - Téma: ${isLight ? "VILÁGOS" : "SÖTÉT"}');
        return MaterialApp(
          title: 'BeastPhysical',
          debugShowCheckedModeBanner: false,
          theme: isLight ? AlkalmazasTema.vilagTema : AlkalmazasTema.sotetTema,
          home: const InduloKepernyo(),
        );
      },
    );
  }
}
