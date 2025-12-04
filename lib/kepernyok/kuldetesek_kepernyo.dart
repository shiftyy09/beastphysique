import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beast_physique/szolgaltatasok/firestore_szolgaltatas.dart';
import 'package:beast_physique/modellek/kuldetes.dart';
import 'package:beast_physique/modellek/edzes.dart'; // Importáljuk az Edzés modellt
import 'package:beast_physique/kepernyok/aktiv_edzes_kepernyo.dart'; // AktivEdzesKepernyo importálása

class KuldetesekKepernyo extends StatefulWidget {
  const KuldetesekKepernyo({super.key});

  @override
  State<KuldetesekKepernyo> createState() => _KuldetesekKepernyoState();
}

class _KuldetesekKepernyoState extends State<KuldetesekKepernyo> {
  final FirestoreSzolgaltatas _firestoreSzolgaltatas = FirestoreSzolgaltatas();

  // Ideiglenes metódus küldetések generálására
  Future<void> _generateInitialMissions() async {
    final List<Kuldetes> initialMissions = [
      Kuldetes(
        id: 'push_day_1',
        nev: 'Push Day Kihívás',
        leiras: 'Végezz el egy "Push" edzésnapot (mell, váll, tricepsz).',
        targetWorkoutName: 'Push',
        aktiv: true, // Az első küldetés legyen azonnal aktív
        activatedDate: Timestamp.now(),
      ),
      Kuldetes(
        id: 'pull_day_1',
        nev: 'Pull Day Kihívás',
        leiras: 'Végezz el egy "Pull" edzésnapot (hát, bicepsz).',
        targetWorkoutName: 'Pull',
      ),
      Kuldetes(
        id: 'leg_day_1',
        nev: 'Lábnap Kihívás',
        leiras: 'Végezz el egy "Láb" edzésnapot.',
        targetWorkoutName: 'Láb',
      ),
    ];

    for (var mission in initialMissions) {
      await _firestoreSzolgaltatas.kuldetesHozzaadasa(mission);
    }
  }

  // Küldetés aktiválása
  Future<void> _activateMission(Kuldetes missionToActivate, List<Kuldetes> allMissions) async {
    // Először deaktiváljuk az összes többi aktív küldetést
    for (var mission in allMissions) {
      if (mission.aktiv) {
        mission.aktiv = false;
        await _firestoreSzolgaltatas.kuldetesFrissitese(mission);
      }
    }

    // Majd aktiváljuk a kiválasztottat
    missionToActivate.aktiv = true;
    missionToActivate.activatedDate = Timestamp.now();
    await _firestoreSzolgaltatas.kuldetesFrissitese(missionToActivate);
  }

  // Edzés indítása a küldetés alapján
  void _startMissionWorkout(Kuldetes mission) {
    // Létrehozunk egy "sablon" edzést a küldetés célnevével
    final templateEdzes = Edzes(
      nev: mission.targetWorkoutName,
      datum: Timestamp.now(),
      duration: Duration.zero,
      gyakorlatok: [], // Üresen hagyjuk, az AktivEdzesKepernyo majd betölti a korábbiakat a név alapján
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AktivEdzesKepernyo(sablonEdzes: templateEdzes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Küldetések',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<Kuldetes>>(
        stream: _firestoreSzolgaltatas.osszesKuldetesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9500)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nincsenek küldetések.', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _generateInitialMissions,
                    child: const Text('Kezdeti küldetések generálása'),
                  ),
                ],
              ),
            );
          }

          final kuldetesek = snapshot.data!;
          // A küldetések sorrendje: aktív, elérhető, teljesített
          kuldetesek.sort((a, b) {
            if (a.aktiv) return -1;
            if (b.aktiv) return 1;
            if (a.teljesitve) return 1;
            if (b.teljesitve) return -1;
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kuldetesek.length,
            itemBuilder: (context, index) {
              final kuldetes = kuldetesek[index];
              return _buildMissionCard(kuldetes, kuldetesek);
            },
          );
        },
      ),
    );
  }

  Widget _buildMissionCard(Kuldetes kuldetes, List<Kuldetes> allMissions) {
    Color borderColor = const Color(0xFF2A2A2A);
    Color iconColor = const Color(0xFFFFD700);
    IconData icon = Icons.bolt_rounded;
    String statusText = 'Aktiválás';
    VoidCallback? onActionButtonPressed;

    if (kuldetes.aktiv) {
      borderColor = const Color(0xFFFFD700);
      iconColor = const Color(0xFFFFD700);
      icon = Icons.bolt_rounded;
      statusText = 'EDZÉS INDÍTÁSA'; // Módosított szöveg aktív küldetésnél
      onActionButtonPressed = () => _startMissionWorkout(kuldetes); // Edzés indítása
    } else if (kuldetes.teljesitve) {
      borderColor = const Color(0xFF10B981);
      iconColor = const Color(0xFF10B981);
      icon = Icons.check_circle;
      statusText = 'Teljesítve';
      onActionButtonPressed = null; // Teljesítettnél nincs gomb funkció (vagy lehetne részletek)
    } else {
      // Még nem aktív
      statusText = 'Aktiválás';
      onActionButtonPressed = () => _activateMission(kuldetes, allMissions);
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column( // Column, hogy a gomb lejjebb kerülhessen ha kell
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kuldetes.nev,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kuldetes.leiras,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!kuldetes.teljesitve) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, // Teljes szélességű gomb
                child: ElevatedButton(
                  onPressed: onActionButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kuldetes.aktiv ? const Color(0xFFFFD700) : const Color(0xFF2A2A2A),
                    foregroundColor: kuldetes.aktiv ? Colors.black : const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ] else ...[
               const SizedBox(height: 16),
               Align(
                 alignment: Alignment.centerRight,
                 child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(color: iconColor.withOpacity(0.7), fontWeight: FontWeight.bold),
                 ),
               ),
            ]
          ],
        ),
      ),
    );
  }
}
