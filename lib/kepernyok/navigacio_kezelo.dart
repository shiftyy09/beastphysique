import 'package:flutter/material.dart';
import 'fokepernyo.dart';
import 'edzesek_kepernyo.dart';
import 'beallitasok_kepernyo.dart';
import '../tema/theme_controller.dart';

class NavigacioKezelo extends StatefulWidget {
  const NavigacioKezelo({super.key});

  @override
  State<NavigacioKezelo> createState() => _NavigacioKezeloState();
}

class _NavigacioKezeloState extends State<NavigacioKezelo> {
  int _aktuaisIndex = 0;

  void _oldalValtas(int index) {
    debugPrint('[NavigacioKezelo] oldalValtas from $_aktuaisIndex to $index');
    setState(() {
      _aktuaisIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isLight, child) {
        debugPrint('[NavigacioKezelo] build (from notifier), isLight=$isLight, currentIndex=$_aktuaisIndex');
        final kepernyok = [
          const FoKepernyo(),
          const EdzesekKepernyo(),
          const BeallitasokKepernyo(), // Paraméterek eltávolítva
        ];

        return Scaffold(
          body: kepernyok[_aktuaisIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _aktuaisIndex,
            onTap: _oldalValtas,
            backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
            selectedItemColor: const Color(0xFFE65100),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Kezdőlap',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center),
                label: 'Edzések',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Beállítások',
              ),
            ],
          ),
        );
      },
    );
  }
}
