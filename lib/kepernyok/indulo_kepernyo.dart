import 'package:flutter/material.dart';
import 'dart:async';
import 'hitelesites_ellenorzo.dart';
import '../tema/theme_controller.dart';

class InduloKepernyo extends StatefulWidget {
  const InduloKepernyo({super.key});

  @override
  State<InduloKepernyo> createState() => _InduloKepernyoState();
}

class _InduloKepernyoState extends State<InduloKepernyo> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Az animáció időtartama
    )..repeat(reverse: true); // Ismétlődés oda-vissza
    
    _animation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeApp() async {
    // Ide kerülhetnek az inicializálási feladatok.
    // A maximális késleltetést 1.2 másodpercre korlátozzuk.
    await Future.delayed(const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        // Ha a Future még fut, megjelenítjük a splash képernyőt animációval.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ValueListenableBuilder<bool>(
            valueListenable: themeNotifier,
            builder: (context, isLight, child) {
              return Scaffold(
                backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
                body: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation.value,
                        child: Image.asset(
                          'assets/images/screenlogo.png',
                          width: 300,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          // Hiba történt az inicializálás során.
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text(
                  'Hiba az inicializálás során: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        } else {
          // Ha az inicializálás befejeződött, navigálunk a HitelesitesEllenorzore.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HitelesitesEllenorzo(),
              ),
            );
          });
          // Addig is, amíg a navigáció megtörténik, egy üres konténert adunk vissza.
          return Container(color: Colors.transparent);
        }
      },
    );
  }
}
