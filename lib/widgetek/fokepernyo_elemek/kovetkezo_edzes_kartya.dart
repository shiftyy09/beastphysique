import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:beast_physique/szolgaltatasok/firestore_szolgaltatas.dart';
import 'package:beast_physique/modellek/kuldetes.dart';
import '../../kepernyok/kuldetesek_kepernyo.dart'; // Az új, HELYES képernyő importálása

class KovetkezoEdzesKartya extends StatefulWidget {
  const KovetkezoEdzesKartya({super.key});

  @override
  State<KovetkezoEdzesKartya> createState() => _KovetkezoEdzesKartyaState();
}

class _KovetkezoEdzesKartyaState extends State<KovetkezoEdzesKartya> {
  final FirestoreSzolgaltatas _firestoreSzolgaltatas = FirestoreSzolgaltatas();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Kuldetes?>( // StreamBuilder a küldetés streamhez
      stream: _firestoreSzolgaltatas.aktivKuldetesStream(),
      builder: (context, snapshot) {
        final Kuldetes? kuldetes = snapshot.data;

        // Ha nincs adat vagy üres, jelenítsünk meg egy üzenetet
        if (kuldetes == null) {
          return _buildNoMissionWidget(context);
        }

        // Ha van aktív küldetés, jelenítsük meg
        return GestureDetector(
          onTap: () {
            // Navigálás a küldetések képernyőre
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KuldetesekKepernyo()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: kuldetes.teljesitve
                          ? [const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.8)] // Zöld ha teljesítve
                          : [const Color(0xFFFFD700), const Color(0xFFFF9500)], // Sárga/narancs ha aktív
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: Icon(
                    kuldetes.teljesitve ? Icons.check_circle_outline : Icons.bolt_rounded,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kuldetes.nev.toUpperCase(),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                kuldetes.leiras,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2, // Hogy ne törje a layoutot
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kuldetes.teljesitve
                                    ? const Color(0xFF10B981).withOpacity(0.3)
                                    : const Color(0xFFFFD700).withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: kuldetes.teljesitve ? const Color(0xFF10B981) : const Color(0xFFFFD700),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget ha nincs küldetés
  Widget _buildNoMissionWidget(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const KuldetesekKepernyo()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFF444444).withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.add_task,
                color: Color(0xFF444444),
                size: 40,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nincs aktív küldetés',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fedezz fel új kihívásokat a küldetések között!',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
