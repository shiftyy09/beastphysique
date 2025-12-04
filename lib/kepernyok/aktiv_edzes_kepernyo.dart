import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beast_physique/modellek/edzes.dart';
import 'package:beast_physique/modellek/gyakorlat.dart';
import 'package:beast_physique/modellek/szett.dart';
import 'package:beast_physique/szolgaltatasok/firestore_szolgaltatas.dart';
import 'package:flutter/services.dart';

class AktivEdzesKepernyo extends StatefulWidget {
  final Edzes? sablonEdzes; // Opcionális sablon edzés újraindításhoz

  const AktivEdzesKepernyo({super.key, this.sablonEdzes});

  @override
  State<AktivEdzesKepernyo> createState() => _AktivEdzesKepernyoState();
}

class _AktivEdzesKepernyoState extends State<AktivEdzesKepernyo> {
  final TextEditingController _edzesNevController = TextEditingController();
  final List<Gyakorlat> _gyakorlatok = [];
  final List<int> _expandedGyakorlatok = [];
  final FirestoreSzolgaltatas _firestoreSzolgaltatas = FirestoreSzolgaltatas();
  Map<String, Map<int, Szett>> _elozoSettek = {};
  Map<String, double> _prs = {}; // PR-ek tárolása gyakorlatonként

  final Map<String, TextEditingController> _sulyControllers = {};
  final Map<String, TextEditingController> _ismetlesControllers = {};

  late Stopwatch _pihenoStopwatch;
  late Stopwatch _teljesEdzesStopwatch;
  Timer? _pihenoTimer;
  Timer? _teljesEdzesTimer;
  int _pihenoMasodperc = 0;
  bool _pihenoAktiv = false;
  bool _isSaving = false; // ÚJ: Megakadályozza a többszöri mentést

  @override
  void initState() {
    super.initState();
    _pihenoStopwatch = Stopwatch();
    _teljesEdzesStopwatch = Stopwatch()..start(); // Automatikus indítás
    _startTeljesEdzesTimer();
    _edzesNevController.addListener(_onEdzesNevChanged);

    // Sablon edzés betöltése, ha van
    if (widget.sablonEdzes != null) {
      _betoltSablonEdzes(widget.sablonEdzes!);
    }
  }

  void _betoltSablonEdzes(Edzes sablon) {
    _edzesNevController.text = sablon.nev;
    
    for (var gyakorlat in sablon.gyakorlatok) {
      // Új gyakorlat objektum létrehozása a sablon alapján
      List<Szett> ujSzettek = [];
      for (var szett in gyakorlat.szettek) {
        ujSzettek.add(Szett(
          suly: szett.suly,
          ismetlesek: szett.ismetlesek,
          befejezett: false, // Új edzésnél még nincs befejezve
        ));
      }
      
      _gyakorlatok.add(Gyakorlat(
        nev: gyakorlat.nev,
        szettek: ujSzettek,
      ));
    }

    // Vezérlők inicializálása az új gyakorlatokhoz
    for (int i = 0; i < _gyakorlatok.length; i++) {
      final gyakorlat = _gyakorlatok[i];
      for (int j = 0; j < gyakorlat.szettek.length; j++) {
        final szett = gyakorlat.szettek[j];
        final szettKey = '${gyakorlat.nev}_$j';
        
        _sulyControllers[szettKey] = TextEditingController(text: szett.suly.toString());
        _ismetlesControllers[szettKey] = TextEditingController(text: szett.ismetlesek.toString());
      }
    }
    
    // Az első gyakorlat kinyitása
    if (_gyakorlatok.isNotEmpty) {
      _expandedGyakorlatok.add(0);
    }
    
    // Betöltjük a PR-eket a sablon gyakorlataihoz is
    _betoltPreketSablonhoz();
  }
  
  // Külön metódus a PR-ek betöltésére sablon esetén
  Future<void> _betoltPreketSablonhoz() async {
    for (var gyakorlat in _gyakorlatok) {
        final pr = await _firestoreSzolgaltatas.getPersonalRecord(gyakorlat.nev);
        if (pr > 0) {
          _prs[gyakorlat.nev] = pr;
        }
    }
    setState(() {});
  }

  void _startTeljesEdzesTimer() {
    _teljesEdzesTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_teljesEdzesStopwatch.isRunning) {
        setState(() {});
      }
    });
  }

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${hours}h ${minutes}m ${seconds}s";
  }

  void _onEdzesNevChanged() {
    setState(() {});
    // Csak akkor töltsünk be előző adatokat, ha a név nem egyezik meg a sablonnal (vagy nincs sablon)
    if (widget.sablonEdzes == null || _edzesNevController.text != widget.sablonEdzes!.nev) {
        _betoltUtolsoEdzesAdatok();
    }
  }

  Future<void> _betoltUtolsoEdzesAdatok() async {
    final edzesNev = _edzesNevController.text.trim();
    if (edzesNev.isEmpty) {
      _elozoSettek.clear();
      _prs.clear();
      setState(() {});
      return;
    }

    try {
      // Előző edzés adatainak betöltése
      final edzes = await _firestoreSzolgaltatas.utolsoEdzesLekeresNevSzerint(edzesNev);
      if (edzes != null) {
        _elozoSettek.clear();
        _prs.clear();
        for (var gyakorlat in edzes.gyakorlatok) {
          _elozoSettek[gyakorlat.nev] = {};
          
          // PR lekérése
          final pr = await _firestoreSzolgaltatas.getPersonalRecord(gyakorlat.nev);
          if (pr > 0) {
            _prs[gyakorlat.nev] = pr;
          }

          for (int i = 0; i < gyakorlat.szettek.length; i++) {
            _elozoSettek[gyakorlat.nev]![i] = gyakorlat.szettek[i];
          }
        }
      } else {
        _elozoSettek.clear();
        _prs.clear();
      }
    } catch (e) {
      _elozoSettek.clear();
      _prs.clear();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _edzesNevController.removeListener(_onEdzesNevChanged);
    _edzesNevController.dispose();
    _pihenoStopwatch.stop();
    _teljesEdzesStopwatch.stop();
    _pihenoTimer?.cancel();
    _teljesEdzesTimer?.cancel();
    _sulyControllers.forEach((key, controller) => controller.dispose());
    _ismetlesControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _startPihenoTimer() {
    if (!_pihenoStopwatch.isRunning) {
      _pihenoStopwatch.reset();
      _pihenoStopwatch.start();
      _pihenoAktiv = true;
      _pihenoMasodperc = 0;
      _pihenoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pihenoStopwatch.isRunning) {
          setState(() {
            _pihenoMasodperc = _pihenoStopwatch.elapsed.inSeconds;
          });
        }
      });
    }
  }

  void _stopPihenoTimer() {
    _pihenoStopwatch.stop();
    _pihenoTimer?.cancel();
    _pihenoAktiv = false;
    setState(() {});
  }

  void _skipPiheno() {
    _stopPihenoTimer();
    _pihenoStopwatch.reset();
    _pihenoMasodperc = 0;
    setState(() {});
  }

  Future<void> _ujGyakorlatDialogus() async {
    final TextEditingController gyakorlatNevController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Új gyakorlat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          content: TextField(
            controller: gyakorlatNevController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: "Gyakorlat neve",
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF3B30), width: 2),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Mégse', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Hozzáad', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
              onPressed: () {
                if (gyakorlatNevController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(gyakorlatNevController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _gyakorlatok.add(Gyakorlat(nev: result.trim(), szettek: []));
        // Collapse összes gyakorlat, csak az új legyen expanded
        _expandedGyakorlatok.clear();
        _expandedGyakorlatok.add(_gyakorlatok.length - 1);
        _ujSzettHozzaadasa(_gyakorlatok.length - 1);
      });
      // Ha új gyakorlatot adunk hozzá, próbáljuk meg betölteni a PR-jét
      final pr = await _firestoreSzolgaltatas.getPersonalRecord(result!.trim());
      if (pr > 0) {
        setState(() {
          _prs[result.trim()] = pr;
        });
      }
    }
  }

  void _edzesMentese() async { // async hozzáadva
    if (_isSaving) return; // Már mentés alatt van

    if (_edzesNevController.text.trim().isEmpty || _gyakorlatok.isEmpty) {
      _showSnackBar('Add meg az edzés nevét és adj hozzá gyakorlatot!', Colors.red);
      return;
    }

    setState(() { _isSaving = true; }); // Jelöljük, hogy a mentés elkezdődött

    // Stop the total workout stopwatch before saving
    _teljesEdzesStopwatch.stop();

    final ujEdzes = Edzes(
      nev: _edzesNevController.text.trim(),
      datum: Timestamp.now(),
      duration: _teljesEdzesStopwatch.elapsed, // Save the elapsed duration
      gyakorlatok: _gyakorlatok,
    );

    try {
      await _firestoreSzolgaltatas.edzesMentes(ujEdzes);
      if (mounted) {
        _showSnackBar('Edzés mentve! 💪', const Color(0xFF10B981));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Hiba: $error', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; }); // Mindig visszaállítjuk, ha befejeződött
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _ujSzettHozzaadasa(int gyakorlatIndex) {
    setState(() {
      final newSzett = Szett(suly: 0, ismetlesek: 0, befejezett: false);
      _gyakorlatok[gyakorlatIndex].szettek.add(newSzett);

      final szettKey = '${_gyakorlatok[gyakorlatIndex].nev}_${_gyakorlatok[gyakorlatIndex].szettek.length - 1}';
      _sulyControllers[szettKey] = TextEditingController();
      _ismetlesControllers[szettKey] = TextEditingController();

      final elozoSzett = _elozoSettek[_gyakorlatok[gyakorlatIndex].nev]?[_gyakorlatok[gyakorlatIndex].szettek.length - 1];
      if (elozoSzett != null) {
        _sulyControllers[szettKey]!.text = elozoSzett.suly.toString();
        _ismetlesControllers[szettKey]!.text = elozoSzett.ismetlesek.toString();
        newSzett.suly = elozoSzett.suly;
        newSzett.ismetlesek = elozoSzett.ismetlesek;
      }
    });
  }

  void _szettBefejez(int gyakorlatIndex, int szettIndex) {
    // Focus elvétele a mentés előtt, hogy eltűnjön a billentyűzet
    FocusScope.of(context).unfocus();

    setState(() {
      final szett = _gyakorlatok[gyakorlatIndex].szettek[szettIndex];
      final szettKey = '${_gyakorlatok[gyakorlatIndex].nev}_$szettIndex';

      szett.suly = double.tryParse(_sulyControllers[szettKey]?.text ?? '0') ?? 0;
      szett.ismetlesek = int.tryParse(_ismetlesControllers[szettKey]?.text ?? '0') ?? 0;
      szett.befejezett = !szett.befejezett;

      if (szett.befejezett) {
        // Eltávolítva az automatikus _startPihenoTimer(); hívás
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _gyakorlatTorles(int index) {
    setState(() {
      for (int i = 0; i < _gyakorlatok[index].szettek.length; i++) {
        final szettKey = '${_gyakorlatok[index].nev}_$i';
        _sulyControllers[szettKey]?.dispose();
        _ismetlesControllers[szettKey]?.dispose();
        _sulyControllers.remove(szettKey);
        _ismetlesControllers.remove(szettKey);
      }
      _gyakorlatok.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _teljesEdzesStopwatch.elapsed;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      // GestureDetector hozzáadva a háttérre kattintás kezeléséhez
      body: GestureDetector(
        onTap: () {
          // Ha bárhova máshova kattintasz, eltűnik a billentyűzet
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(elapsed),
              Expanded(
                child: _gyakorlatok.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _gyakorlatok.length,
                  itemBuilder: (context, index) => _buildGyakorlatCard(index),
                ),
              ),
              if (_pihenoAktiv) _buildPihenoTimer(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Duration elapsed) {
    final isPihenoRunning = _pihenoStopwatch.isRunning;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: const Color(0xFF2A2A2A))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
              Expanded(
                child: TextField(
                  controller: _edzesNevController,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  textCapitalization: TextCapitalization.sentences,
                  // Enter lenyomásakor elrejti a billentyűzetet
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: "Edzés neve",
                    hintStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w900),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dupla Stopper Box
          Container(
            height: 75,
            child: Row(
              children: [
                // BAL oldal - Edzésidő (automatikus)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'EDZÉS',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatElapsedTime(elapsed),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // JOBB oldal - Pihenő (manuális)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: isPihenoRunning ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Play/Pause/Stop gomb
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isPihenoRunning) {
                                _stopPihenoTimer();
                              } else {
                                _startPihenoTimer();
                              }
                            });
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPihenoRunning 
                                    ? [const Color(0xFFFF3B30), const Color(0xFFFF0000)]
                                    : [const Color(0xFF00D9FF), const Color(0xFF0EA5E9)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isPihenoRunning ? const Color(0xFFFF3B30) : const Color(0xFF00D9FF)).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPihenoRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pihenő idő
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PIHENŐ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRestTime(_pihenoMasodperc),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF444444), size: 60),
          ),
          const SizedBox(height: 24),
          Text(
            'NINCS GYAKORLAT',
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Nyomd meg a + gombot',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }
  Widget _buildBrutalStatCard(String title, String value, String unit, IconData icon, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFF2A2A2A),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit.toUpperCase(),
                    style: TextStyle(
                      color: accentColor.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGyakorlatCard(int gyakorlatIndex) {
    final gyakorlat = _gyakorlatok[gyakorlatIndex];
    final isExpanded = _expandedGyakorlatok.contains(gyakorlatIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGyakorlatok.remove(gyakorlatIndex);
                } else {
                  _expandedGyakorlatok.add(gyakorlatIndex);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2A2A2A).withOpacity(0.5), Colors.transparent],
                ),
                borderRadius: isExpanded 
                    ? const BorderRadius.vertical(top: Radius.circular(18))
                    : BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFFF9500),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      gyakorlat.nev.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${gyakorlat.szettek.length} SZETT',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _gyakorlatTorles(gyakorlatIndex),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: const Color(0xFF2A2A2A)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: gyakorlat.szettek.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, szettIndex) => _buildSzettRow(gyakorlatIndex, szettIndex),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildUjSzettGomb(gyakorlatIndex),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSzettRow(int gyakorlatIndex, int szettIndex) {
    final szett = _gyakorlatok[gyakorlatIndex].szettek[szettIndex];
    final szettKey = '${_gyakorlatok[gyakorlatIndex].nev}_$szettIndex';
    final elozoSzett = _elozoSettek[_gyakorlatok[gyakorlatIndex].nev]?[szettIndex];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: szett.befejezett ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: szett.befejezett ? const Color(0xFF10B981) : const Color(0xFF2A2A2A),
          width: szett.befejezett ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Explicit GestureDetector a szett befejezéséhez a bal oldali dobozon
          GestureDetector(
            onTap: () => _szettBefejez(gyakorlatIndex, szettIndex),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: szett.befejezett ? const Color(0xFF10B981) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: szett.befejezett
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                    : Text(
                  '${szettIndex + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildInput(
                    controller: _sulyControllers[szettKey]!,
                    label: 'KG',
                    enabled: !szett.befejezett,
                    elozoErtek: elozoSzett?.suly.toString(),
                    prErtek: _prs[_gyakorlatok[gyakorlatIndex].nev]?.toString(), // Átadjuk a PR értéket
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInput(
                    controller: _ismetlesControllers[szettKey]!,
                    label: 'REPS',
                    enabled: !szett.befejezett,
                    elozoErtek: elozoSzett?.ismetlesek.toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ); // <-- Itt volt a hiba, egy extra zárójel hiányzott vagy rosszul volt elhelyezve
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    String? elozoErtek,
    String? prErtek, // Új paraméter a PR értékhez
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            if (prErtek != null && label == 'KG') // Csak a súlynál jelenítjük meg a PR-t
              Text(
                'PR: $prErtek',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          // Done gomb elrejti a billentyűzetet
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey[600],
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            hintText: elozoErtek ?? '0',
            hintStyle: TextStyle(color: Colors.grey[800]),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (elozoErtek != null) ...[
            const SizedBox(height: 4),
            Text(
              'Előző: $elozoErtek',
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
            ),
        ]
      ],
    );
  }

  Widget _buildUjSzettGomb(int gyakorlatIndex) {
    return GestureDetector(
      onTap: () => _ujSzettHozzaadasa(gyakorlatIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Color(0xFFFF9500), size: 20),
            const SizedBox(width: 8),
            Text(
              'ÚJ SZETT',
              style: const TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPihenoTimer() {
    final minutes = _pihenoMasodperc ~/ 60;
    final seconds = _pihenoMasodperc % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PIHENŐ',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: _skipPiheno,
            child: const Text(
              'KIHAGYÁS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        border: Border(top: BorderSide(color: const Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _ujGyakorlatDialogus, // Inaktív ha mentés van
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isSaving ? const Color(0xFF444444) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isSaving ? const Color(0xFF555555) : const Color(0xFF2A2A2A), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'GYAKORLAT',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _edzesMentese, // Inaktív ha mentés van
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _isSaving
                      ? const LinearGradient(colors: [Color(0xFF444444), Color(0xFF555555)]) // Szürke ha inaktív
                      : const LinearGradient(
                          colors: [Color(0xFFFF3B30), Color(0xFFFF0000)],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isSaving
                          ? Colors.transparent
                          : const Color(0xFFFF3B30).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      _isSaving ? 'MENTÉS...' : 'BEFEJEZÉS',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
