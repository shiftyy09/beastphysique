import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:beast_physique/modellek/edzes.dart';
import 'package:beast_physique/szolgaltatasok/firestore_szolgaltatas.dart';
import 'package:beast_physique/kepernyok/aktiv_edzes_kepernyo.dart';
import 'package:flutter/services.dart';

class EdzesekKepernyo extends StatefulWidget {
  const EdzesekKepernyo({super.key});

  @override
  State<EdzesekKepernyo> createState() => _EdzesekKepernyoState();
}

class _EdzesekKepernyoState extends State<EdzesekKepernyo> {
  final FirestoreSzolgaltatas _fs = FirestoreSzolgaltatas();
  String _activeKategoria = 'Összes';
  final List<String> _kategoriak = ['Összes', 'Push', 'Pull', 'Láb', 'Kardió'];

  // --- LOGIKA: KATEGÓRIA FELISMERÉS ---
  String _detectCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('push') || n.contains('mell') || n.contains('váll') || n.contains('tricepsz')) return 'Push';
    if (n.contains('pull') || n.contains('hát') || n.contains('bicepsz')) return 'Pull';
    if (n.contains('láb') || n.contains('leg') || n.contains('guggolás')) return 'Láb';
    if (n.contains('kardió') || n.contains('futás') || n.contains('hiit')) return 'Kardió';
    return 'Egyéb';
  }

  // --- LOGIKA: VOLUMEN SZÁMÍTÁS ---
  double _calculateVolume(Edzes edzes) {
    double vol = 0;
    for (var gy in edzes.gyakorlatok) {
      for (var sz in gy.szettek) {
        vol += sz.suly * sz.ismetlesek;
      }
    }
    return vol;
  }

  // --- LOGIKA: TÖRLÉS MEGERŐSÍTÉSE ---
  Future<void> _confirmDelete(Edzes edzes) async {
    HapticFeedback.heavyImpact(); // Rezgés a figyelemfelkeltéshez
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF3B30), width: 1),
        ),
        title: const Text('EDZÉS TÖRLÉSE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: Text('Biztosan törölni szeretnéd a "${edzes.nev}" edzést? Ez a folyamat nem vonható vissza.',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MÉGSE', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (edzes.id != null) {
                await _fs.edzesTorlese(edzes.id!);
                if (mounted) Navigator.pop(context);
                HapticFeedback.vibrate();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('TÖRLÉS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA: TELJESÍTMÉNY ÖSSZEHASONLÍTÁS ---
  Widget _getPerformanceIndicator(Edzes current, List<Edzes> allWorkouts) {
    final sameNameWorkouts = allWorkouts.where((e) =>
    e.nev == current.nev &&
        e.datum.toDate().isBefore(current.datum.toDate())
    ).toList();

    if (sameNameWorkouts.isEmpty) return const SizedBox();

    sameNameWorkouts.sort((a, b) => b.datum.compareTo(a.datum));
    final lastWorkout = sameNameWorkouts.first;

    double currentVol = _calculateVolume(current);
    double lastVol = _calculateVolume(lastWorkout);

    if (lastVol == 0) return const SizedBox();

    if (currentVol > lastVol) {
      double diff = ((currentVol / lastVol) - 1) * 100;
      return _badge("FEJLŐDÉS +${diff.toStringAsFixed(0)}%", Colors.green);
    } else if (currentVol < lastVol) {
      double diff = (1 - (currentVol / lastVol)) * 100;
      return _badge("FORMA ALATT ${diff.toStringAsFixed(0)}%", Colors.orange);
    }
    return const SizedBox();
  }

  static Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('EDZÉSTÖRTÉNET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Edzes>>(
        stream: _fs.edzesekStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allWorkouts = snapshot.data!;

          Edzes bestWorkout = allWorkouts.first;
          double maxVol = 0;
          for (var e in allWorkouts) {
            double v = _calculateVolume(e);
            if (v > maxVol) {
              maxVol = v;
              bestWorkout = e;
            }
          }

          final filteredWorkouts = allWorkouts.where((e) {
            if (_activeKategoria == 'Összes') return true;
            return _detectCategory(e.nev) == _activeKategoria;
          }).toList();

          return Column(
            children: [
              _buildTopStats(bestWorkout, maxVol),
              _buildCategoryStrip(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredWorkouts.length,
                  itemBuilder: (context, index) {
                    return _buildEdzesCard(filteredWorkouts[index], allWorkouts);
                  },
                ),
              ),
              const SizedBox(height: 100), // Hely a lebegő menünek
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopStats(Edzes best, double vol) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
          gradient: LinearGradient(
            colors: [Colors.amber.withOpacity(0.05), Colors.transparent],
            begin: Alignment.topLeft,
          )
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("LEGNAGYOBB CSATA (RECORD)", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(best.nev.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text("${vol.toInt()} KG ÖSSZESEN", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _kategoriak.length,
        itemBuilder: (context, index) {
          bool active = _activeKategoria == _kategoriak[index];
          return GestureDetector(
            onTap: () => setState(() => _activeKategoria = _kategoriak[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFF3B30) : const Color(0xFF121212),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: active ? Colors.transparent : Colors.white.withOpacity(0.05)),
              ),
              alignment: Alignment.center,
              child: Text(
                  _kategoriak[index].toUpperCase(),
                  style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.w900, fontSize: 11)
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEdzesCard(Edzes edzes, List<Edzes> all) {
    final vol = _calculateVolume(edzes);
    final date = edzes.datum.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(edzes.nev.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(width: 8),
                          _getPerformanceIndicator(edzes, all),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          "${date.year}. ${date.month}. ${date.day}. • ${edzes.duration.inMinutes} PERC • ${vol.toInt()} KG",
                          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                // --- TÖRLÉS GOMB ---
                IconButton(
                  onPressed: () => _confirmDelete(edzes),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF444444), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "KATEGÓRIA: ${_detectCategory(edzes.nev).toUpperCase()}",
                    style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.w900)
                ),
                // --- ÚJRAINDÍTÁS GOMB ---
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AktivEdzesKepernyo(sablonEdzes: edzes)),
                    );
                  },
                  child: const Row(
                    children: [
                      Text("ÚJRAINDÍTÁS",
                          style: TextStyle(color: Color(0xFFFF3B30), fontSize: 10, fontWeight: FontWeight.w900)),
                      SizedBox(width: 4),
                      Icon(Icons.restart_alt, color: Color(0xFFFF3B30), size: 16),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.grey[900], size: 100),
          const SizedBox(height: 20),
          const Text("MÉG NINCSENEK EDZÉSEID", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}