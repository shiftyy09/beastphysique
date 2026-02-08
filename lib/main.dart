import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'kepernyok/indulo_kepernyo.dart';
import 'tema/alkalmazas_tema.dart';
import 'tema/theme_controller.dart';

Future<void> main() async {
  // 1. Alapvető inicializálás
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('=== BEAST PHYSIQUE INDULÁSA ===');

  try {
    // 2. Firebase inicializálás biztonságosan
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 3. Firestore beállítások
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    debugPrint('Firebase & Firestore OK');
  } catch (e) {
    debugPrint('Kritikus hiba az indításkor: $e');
  }

  // 4. Alkalmazás indítása
  runApp(const BeastPhysicalAlkalmazas());
}

class BeastPhysicalAlkalmazas extends StatelessWidget {
  const BeastPhysicalAlkalmazas({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isLight, child) {
        return MaterialApp(
          title: 'Beast Physique',
          debugShowCheckedModeBanner: false,
          // Sötét/Világos téma kezelése
          theme: AlkalmazasTema.vilagTema,
          darkTheme: AlkalmazasTema.sotetTema,
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          home: const InduloKepernyo(),
        );
      },
    );
  }
}