import 'package:flutter/material.dart';
import 'dart:async';
import 'hitelesites_ellenorzo.dart';
import '../tema/theme_controller.dart';

class InduloKepernyo extends StatefulWidget {
  const InduloKepernyo({super.key});

  @override
  State<InduloKepernyo> createState() => _InduloKepernyoState();
}

class _InduloKepernyoState extends State<InduloKepernyo> {
  @override
  void initState() {
    super.initState();
    _navigaciokeszitese();
  }

  void _navigaciokeszitese() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HitelesitesEllenorzo(), // Paraméterek eltávolítva
            ),
          );
        } catch (e) {
          debugPrint('Navigációs hiba: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isLight, child) {
        return Scaffold(
          backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/screenlogo.png',
                  width: 300,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  color: Color(0xFFE65100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
