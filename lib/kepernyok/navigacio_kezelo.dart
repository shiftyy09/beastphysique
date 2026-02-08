import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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
  int _aktualisIndex = 0;

  // Az oldalak listája
  final List<Widget> _kepernyok = [
    const FoKepernyo(),
    const EdzesekKepernyo(),
    const BeallitasokKepernyo(),
  ];

  void _onTap(int index) {
    if (_aktualisIndex == index) return;

    // Apró rezgés a váltáskor a minőségi érzetért
    HapticFeedback.lightImpact();

    setState(() {
      _aktualisIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lekérjük az alsó rendszersáv magasságát (Android gombok vagy gesztuscsík)
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isLight, child) {
        return Scaffold(
          // Az extendBody engedi a tartalmat a navbar mögé csúszni (a blur effekt miatt fontos)
          extendBody: true,
          backgroundColor: Colors.black,
          body: _kepernyok[_aktualisIndex],

          // Egyedi, lebegő navigációs sáv
          bottomNavigationBar: Padding(
            // Itt kezeljük a Safe Area-t: rendszersáv + 10 pixel extra hely
            padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: systemBottomPadding > 0 ? systemBottomPadding : 20
            ),
            child: _buildModernNavBar(),
          ),
        );
      },
    );
  }

  Widget _buildModernNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        // Sötét, enyhén áttetsző háttér
        color: const Color(0xFF121212).withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          // Üvegszerű blur effekt
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Kezdőlap'),
              _buildNavItem(1, Icons.fitness_center_rounded, 'Edzések'),
              _buildNavItem(2, Icons.settings_rounded, 'Beállítások'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _aktualisIndex == index;
    // A Beast Physique fő színe
    const Color beastRed = Color(0xFFFF3B30);

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon konténer izzással
            Container(
              padding: const EdgeInsets.all(8),
              decoration: isSelected
                  ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: beastRed.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              )
                  : null,
              child: Icon(
                icon,
                color: isSelected ? beastRed : Colors.grey[600],
                size: isSelected ? 30 : 24,
              ),
            ),

            // Kis pont indikátor az ikon alatt
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 2),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                  color: beastRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: beastRed.withOpacity(0.8),
                      blurRadius: 4,
                    )
                  ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}