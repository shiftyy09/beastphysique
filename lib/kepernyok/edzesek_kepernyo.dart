import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beast_physique/modellek/edzes.dart'; // Edzés modell importálása
import 'package:beast_physique/szolgaltatasok/firestore_szolgaltatas.dart'; // Firestore szolgáltatás importálása
import 'package:beast_physique/kepernyok/aktiv_edzes_kepernyo.dart'; // AktivEdzesKepernyo importálása az újraindításhoz

class EdzesekKepernyo extends StatefulWidget {
  const EdzesekKepernyo({super.key});

  @override
  State<EdzesekKepernyo> createState() => _EdzesekKepernyoState();
}

class _EdzesekKepernyoState extends State<EdzesekKepernyo> {
  final FirestoreSzolgaltatas _firestoreSzolgaltatas = FirestoreSzolgaltatas();
  String _kivalasztottKategoria = 'Összes'; // Alapértelmezett kategória

  @override
  void initState() {
    super.initState();
  }

  void _restartWorkout(Edzes edzes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AktivEdzesKepernyo(sablonEdzes: edzes), 
      ),
    );
  }

  int _calculateTotalWeight(Edzes edzes) {
    int totalWeight = 0;
    for (var gyakorlat in edzes.gyakorlatok) {
      for (var szett in gyakorlat.szettek) {
        totalWeight += (szett.suly * szett.ismetlesek).toInt();
      }
    }
    return totalWeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Edzések',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _buildKategoriaSzuro(),
        ],
      ),
      body: StreamBuilder<List<Edzes>>(
        stream: _firestoreSzolgaltatas.edzesekStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9500)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hiba: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Még nincsenek edzéseid.', style: TextStyle(color: Colors.white)));
          }

          final osszesEdzes = snapshot.data!;
          // Kategória szerinti szűrés
          final List<Edzes> szurtEdzesek = osszesEdzes.where((edzes) {
            if (_kivalasztottKategoria == 'Összes') return true;
            return edzes.nev.toLowerCase().contains(_kivalasztottKategoria.toLowerCase());
          }).toList();

          // Csoportosítás dátum szerint
          final Map<String, List<Edzes>> csoportositottEdzesek = {};
          for (var edzes in szurtEdzesek) {
            final datum = edzes.datum.toDate();
            final datumString = "${datum.year}. ${datum.month}. ${datum.day}.";
            csoportositottEdzesek.putIfAbsent(datumString, () => []).add(edzes);
          }

          final rendezettDatumKulcsok = csoportositottEdzesek.keys.toList()..sort((a, b) => DateTime.parse(b.replaceAll('. ', '-').replaceAll('.', '')).compareTo(DateTime.parse(a.replaceAll('. ', '-').replaceAll('.', ''))));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rendezettDatumKulcsok.length,
            itemBuilder: (context, index) {
              final datumKulcs = rendezettDatumKulcsok[index];
              final napiEdzesek = csoportositottEdzesek[datumKulcs]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      datumKulcs,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...napiEdzesek.map((edzes) => _buildEdzesCard(edzes)).toList(),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildKategoriaSzuro() {
    // A kategóriák dinamikusan is kinyerhetők az edzések neveiből
    final List<String> kategoriak = ['Összes', 'Push', 'Pull', 'Láb', 'Full Body', 'Kardió', 'Egyéb'];
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _kivalasztottKategoria,
          icon: const Icon(Icons.filter_list, color: Colors.white),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          onChanged: (String? newValue) {
            setState(() {
              _kivalasztottKategoria = newValue!;
            });
          },
          items: kategoriak.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEdzesCard(Edzes edzes) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    edzes.nev,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    edzes.duration.inMinutes > 0 ? '${edzes.duration.inMinutes} perc' : 'Kevesebb mint 1 perc',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${edzes.gyakorlatok.length} gyakorlat, ${_calculateTotalWeight(edzes)} kg összesen',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () => _restartWorkout(edzes),
                  icon: const Icon(Icons.restart_alt, color: Color(0xFFFF9500)),
                  label: const Text(
                    'Újraindítás',
                    style: TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
