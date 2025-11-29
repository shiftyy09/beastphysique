import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp miatt kell
import 'package:beast_physical/modellek/edzes.dart'; // Edzés modell importálása
import 'package:beast_physical/szolgaltatasok/firestore_szolgaltatas.dart'; // Firestore szolgáltatás importálása
import 'package:beast_physical/kepernyok/aktiv_edzes_kepernyo.dart'; // AktivEdzesKepernyo importálása az újraindításhoz

class EdzesekKepernyo extends StatefulWidget {
  const EdzesekKepernyo({super.key});

  @override
  State<EdzesekKepernyo> createState() => _EdzesekKepernyoState();
}

class _EdzesekKepernyoState extends State<EdzesekKepernyo> {
  final FirestoreSzolgaltatas _firestoreSzolgaltatas = FirestoreSzolgaltatas();

  // Segédfüggvény az idő formázásához
  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    // Csak a releváns egységeket jelenítsük meg
    if (duration.inHours > 0) {
      return "${hours}h ${minutes}m";
    } else if (duration.inMinutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  // Segédfüggvény az idő megjelenítéséhez (pl. "2 napja")
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} napja';
    if (diff.inHours > 0) return '${diff.inHours} órája';
    if (diff.inMinutes > 0) return '${diff.inMinutes} perce';
    return 'nemrég';
  }

  // Edzés újraindítása
  void _restartWorkout(Edzes edzes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AktivEdzesKepernyo(sablonEdzes: edzes), 
      ),
    );
  }

  // Segédfüggvény az összsúly kiszámításához
  int _calculateTotalWeight(Edzes edzes) {
    return edzes.gyakorlatok.fold<int>(
        0, (sum, gy) => sum + gy.szettek.fold<int>(
        0, (s, sz) => s + (sz.suly * sz.ismetlesek).toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        title: Text(
          'Edzések',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: theme.appBarTheme.iconTheme ?? const IconThemeData(color: Colors.white), // ikonok az AppBar-ban
      ),
      body: StreamBuilder<List<Edzes>>(
        stream: _firestoreSzolgaltatas.edzesekStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Még nincsenek mentett edzéseid.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor, fontSize: 18),
              ),
            );
          }

          final osszesEdzes = snapshot.data!;
          
          // Csoportosítás név szerint
          // Map<EdzésNeve, List<Edzes>>
          final Map<String, List<Edzes>> csoportositottEdzesek = {};
          for (var edzes in osszesEdzes) {
            if (!csoportositottEdzesek.containsKey(edzes.nev)) {
              csoportositottEdzesek[edzes.nev] = [];
            }
            csoportositottEdzesek[edzes.nev]!.add(edzes);
          }

          // A megjelenítendő lista (minden csoportból a legfrissebb)
          // Mivel az eredeti lista már időrendben van (legfrissebb elöl),
          // ezért minden lista 0. eleme a legfrissebb.
          final List<Edzes> megjelenitendoEdzesek = [];
          
          // Azért, hogy a sorrend megmaradjon (legutóbb végzett edzésfajták elöl),
          // végigmegyünk az eredeti listán, és ha még nem adtuk hozzá a típusát, akkor hozzáadjuk.
          final Set<String> hozzaadottTipusok = {};
          
          for (var edzes in osszesEdzes) {
            if (!hozzaadottTipusok.contains(edzes.nev)) {
              megjelenitendoEdzesek.add(edzes);
              hozzaadottTipusok.add(edzes.nev);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: megjelenitendoEdzesek.length,
            itemBuilder: (context, index) {
              final edzes = megjelenitendoEdzesek[index];
              final osszSuly = _calculateTotalWeight(edzes);
              
              // Az adott típus összes edzése
              final tipusEdzesei = csoportositottEdzesek[edzes.nev]!;
              final edzesSzam = tipusEdzesei.length;

              // Előző edzés keresése a változáshoz (a típus listájában a 2. elem, ha van)
              Edzes? elozoEdzes;
              if (tipusEdzesei.length > 1) {
                elozoEdzes = tipusEdzesei[1]; // A 0. a legfrissebb, az 1. az előző
              }

              // Ha van előző edzés, számoljuk ki a változást
              Widget? valtozasWidget;
              if (elozoEdzes != null) {
                final elozoOsszSuly = _calculateTotalWeight(elozoEdzes);
                final kulonbseg = osszSuly - elozoOsszSuly;
                
                if (kulonbseg > 0) {
                  valtozasWidget = Row(
                    children: [
                      Icon(Icons.arrow_upward, color: theme.colorScheme.secondary, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '+$kulonbseg kg',
                        style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                } else if (kulonbseg < 0) {
                  valtozasWidget = Row(
                    children: [
                      Icon(Icons.arrow_downward, color: theme.colorScheme.error, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '$kulonbseg kg',
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                } else {
                  valtozasWidget = Row(
                    children: [
                      Icon(Icons.remove, color: theme.dividerColor, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '0 kg',
                        style: TextStyle(color: theme.dividerColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }
              }

              return Dismissible(
                key: Key(edzes.id ?? index.toString()),
                direction: DismissDirection.endToStart, 
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete, color: theme.colorScheme.onError, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: theme.cardColor,
                        title: Text("Törlés megerősítése", style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.titleMedium?.color)),
                        content: Text("Ez törli a legutóbbi ilyen típusú edzést. Biztos vagy benne?", style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text("Mégse", style: TextStyle(color: theme.colorScheme.onSurface)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text("Törlés", style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  if (edzes.id != null) {
                    _firestoreSzolgaltatas.edzesTorlese(edzes.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Legutóbbi edzés törölve'), backgroundColor: theme.colorScheme.primary),
                    );
                  }
                },
                child: Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
                  ),
                  child: InkWell( 
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Itt lehetne listázni az adott típus összes korábbi edzését (részletek)
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Bal oldali ikon/grafika (Újraindítás)
                          GestureDetector(
                            onTap: () => _restartWorkout(edzes),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: theme.colorScheme.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Edzés adatai
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible( 
                                      child: Text(
                                        edzes.nev.toUpperCase(),
                                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Kicsi számláló badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        'x$edzesSzam', // Itt jelenik meg a csoportosított darabszám
                                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${edzes.gyakorlatok.length} gyakorlat • ${_formatElapsedTime(edzes.duration)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Összsúly: ${osszSuly} kg',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (valtozasWidget != null) ...[
                                      const SizedBox(width: 8),
                                      valtozasWidget,
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Jobb oldali információ (pl. idő vagy státusz)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.history,
                                color: theme.dividerColor.withOpacity(0.6),
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getTimeAgo(edzes.datum.toDate()),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
