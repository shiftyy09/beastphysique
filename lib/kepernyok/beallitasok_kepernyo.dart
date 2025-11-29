import 'package:flutter/material.dart';
import '../tema/theme_controller.dart';

class BeallitasokKepernyo extends StatelessWidget {
  const BeallitasokKepernyo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ellenőrizzük, hogy a jelenlegi téma világos-e
    final isLight = theme.brightness == Brightness.light;

    // Színek beállítása a téma alapján (megtartva az eredeti dizájnt)
    final backgroundColor = isLight ? Colors.white : const Color(0xFF000000);
    final appBarColor = isLight ? const Color(0xFFE65100) : const Color(0xFF1A1A1A);
    final containerColor = isLight ? Colors.grey[100] : const Color(0xFF1E1E1E);
    final borderColor = isLight ? Colors.grey[300]! : Colors.grey[700]!;
    final textColor = isLight ? Colors.black : Colors.white;
    final subtitleColor = isLight ? Colors.grey[700] : Colors.grey[400];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'Beállítások',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Téma beállítás
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              leading: Icon(
                isLight ? Icons.light_mode : Icons.dark_mode,
                color: const Color(0xFFE65100),
                size: 28,
              ),
              title: Text(
                'Téma',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                isLight ? 'Világos téma' : 'Sötét téma',
                style: TextStyle(color: subtitleColor),
              ),
              trailing: Switch(
                value: isLight,
                onChanged: (value) {
                  // Itt hívjuk meg a globális váltót
                  toggleTheme();
                },
                activeColor: const Color(0xFFE65100),
                inactiveThumbColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // További beállítások placeholder-ek
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications,
                color: Color(0xFFE65100),
                size: 28,
              ),
              title: Text(
                'Értesítések',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Hamarosan elérhető',
                style: TextStyle(color: subtitleColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.privacy_tip,
                color: Color(0xFFE65100),
                size: 28,
              ),
              title: Text(
                'Adatvédelem',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Hamarosan elérhető',
                style: TextStyle(color: subtitleColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.info,
                color: Color(0xFFE65100),
                size: 28,
              ),
              title: Text(
                'Rólunk',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Verzió 1.0.0',
                style: TextStyle(color: subtitleColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
