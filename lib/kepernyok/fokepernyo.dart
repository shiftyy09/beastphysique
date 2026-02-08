import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui';

// Widgetek és Modellek
import '../widgetek/heti_cel_kartya_uj.dart';
import '../widgetek/fokepernyo_elemek/brutal_header.dart';
import '../widgetek/fokepernyo_elemek/brutal_banner.dart';
import '../widgetek/fokepernyo_elemek/streak_card.dart';
import '../widgetek/fokepernyo_elemek/utolso_edzes_kartya.dart';
import '../widgetek/fokepernyo_elemek/stat_card.dart';
import '../widgetek/fokepernyo_elemek/kovetkezo_edzes_kartya.dart';
import '../widgetek/fokepernyo_elemek/section_title.dart';
import '../szolgaltatasok/firestore_szolgaltatas.dart';
import '../modellek/edzes.dart';
import 'aktiv_edzes_kepernyo.dart';

class FoKepernyo extends StatefulWidget {
  const FoKepernyo({super.key});

  @override
  State<FoKepernyo> createState() => _FoKepernyoState();
}

class _FoKepernyoState extends State<FoKepernyo> {
  final FirestoreSzolgaltatas _firestoreSzolgaltatas = FirestoreSzolgaltatas();

  Future<void> _setWeeklyGoal(int newGoal) async {
    await _firestoreSzolgaltatas.hetiCelMentes(newGoal);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nev = user?.displayName?.split(' ')[0] ?? 'Bajnok';
    final kepUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: Colors.black, // Mélyfekete alap
      body: Stack(
        children: [
          // 1. WOW FAKTOR: Háttér vörös izzás (Glow Effect)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container()
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  BrutalHeader(nev: nev, kepUrl: kepUrl),
                  const SizedBox(height: 25),

                  // HALADÁS PANEL
                  _buildProgressSection(),

                  const SizedBox(height: 30),
                  const BrutalBanner(),

                  const SizedBox(height: 35),

                  const SectionTitle(title: 'UTOLSÓ CSATA'),
                  const SizedBox(height: 12),
                  _buildUtolsoEdzesLoader(),

                  const SizedBox(height: 35),

                  const SectionTitle(title: 'TELJESÍTMÉNY MÁTRIX'),
                  const SizedBox(height: 15),
                  _buildStatisztikaGrid(),

                  const SizedBox(height: 35),

                  const SectionTitle(title: 'KÖVETKEZŐ KÜLDETÉS'),
                  const SizedBox(height: 12),
                  const KovetkezoEdzesKartya(),

                  // --- FONTOS JAVÍTÁS ---
                  // Kell a hely a lista végén, hogy az utolsó kártya is kigördüljön a FAB és a NavBar alól
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- FONTOS JAVÍTÁS: A GOMB MEGEMELÉSE ---
      floatingActionButton: Padding(
        // Ez a padding emeli meg a gombot pontosan a lebegő NavBar fölé
        padding: const EdgeInsets.only(bottom: 110),
        child: _buildBeastFAB(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- ARÉNA INDÍTÁSA GOMB (DESIGNED FAB) ---
  Widget _buildBeastFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AktivEdzesKepernyo())
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 65,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFD32F2F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B30).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Edzés indítása',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900, // Brutál vastag betű
                    letterSpacing: 1.5
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STATISZTIKA ÉS HALADÁS METÓDUSOK ---

  Widget _buildProgressSection() {
    return StreamBuilder<int>(
      stream: _firestoreSzolgaltatas.napiStreakLekeres(),
      builder: (context, streakSnapshot) {
        return StreamBuilder<int>(
          stream: _firestoreSzolgaltatas.hetiCelLekeres(),
          builder: (context, celSnapshot) {
            return StreamBuilder<int>(
              stream: _firestoreSzolgaltatas.hetiEdzesekSzama(),
              builder: (context, edzesekSnapshot) {
                final streak = streakSnapshot.data ?? 0;
                final cel = celSnapshot.data ?? 5;
                final aktSzeria = edzesekSnapshot.data ?? 0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniInfo('STREAK', '$streak NAP', Icons.local_fire_department, Colors.orange),
                          _buildMiniInfo('HETI CÉL', '$aktSzeria / $cel', Icons.ads_click, Colors.red),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (aktSzeria / cel).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: const Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMiniInfo(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        )
      ],
    );
  }

  Widget _buildStatisztikaGrid() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firestoreSzolgaltatas.teljesStatisztikaStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.red));

        final stats = snapshot.data!;
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildModernStatCard('ÖSSZES EDZÉS', stats['osszEdzes'].toString(), 'DB', const Color(0xFFFF3B30)),
            _buildModernStatCard('EMELT SÚLY', stats['osszEmeltSuly'].toStringAsFixed(1), 'TONNA', const Color(0xFFFF9500)),
            _buildModernStatCard('REKORDOK', stats['osszPr'].toString(), 'PR', const Color(0xFFFFD700)),
            _buildModernStatCard('IDŐTARTAM', stats['osszEdzesIdo'].toString(), 'ÓRA', const Color(0xFF00D9FF)),
          ],
        );
      },
    );
  }

  Widget _buildModernStatCard(String title, String value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtolsoEdzesLoader() {
    return FutureBuilder<Edzes?>(
      future: _firestoreSzolgaltatas.utolsoEdzesLekeres(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.red)));

        if (snapshot.hasData && snapshot.data != null) {
          final edzes = snapshot.data!;
          final osszSuly = edzes.gyakorlatok.fold<int>(0, (sum, gy) => sum + gy.szettek.fold<int>(0, (s, sz) => s + (sz.suly * sz.ismetlesek).toInt()));

          return UtolsoEdzesKartya(
            nev: edzes.nev,
            gyakorlatokSzama: edzes.gyakorlatok.length,
            osszSuly: osszSuly,
            idoElott: _getTimeAgo(edzes.datum.toDate()),
          );
        }
        return _buildNoWorkoutCard();
      },
    );
  }

  Widget _buildNoWorkoutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: const Text(
          'MÉG NEM VOLT CSATÁD. IDEJE ELKEZDENI!',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} napja';
    if (diff.inHours > 0) return '${diff.inHours} órája';
    return '${diff.inMinutes} perce';
  }
}