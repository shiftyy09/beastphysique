import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'kepernyok/indulo_kepernyo.dart';
import 'tema/alkalmazas_tema.dart';
import 'tema/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('=== APP INDULÁSA ===');
  try {
    debugPrint('Firebase inicializálása...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase sikeresen inicializálva');
  } catch (e) {
    debugPrint('Firebase init hiba: $e');
  }
  debugPrint('=== APP FUTÁSA ===');
  runApp(const BeastPhysicalAlkalmazas());
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
          home: const InduloKepernyo(), // Paraméterek eltávolítva
        );
      },
    );
  }
}
