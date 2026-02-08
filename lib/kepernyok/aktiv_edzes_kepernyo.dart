import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // A FontFeature-höz kell
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beast_physique/modellek/edzes.dart';
import 'package:beast_physique/modellek/gyakorlat.dart';
import 'package:beast_physique/modellek/szett.dart';
import 'package:beast_physique/szolgaltatasok/firestore_szolgaltatas.dart';
import 'package:flutter/services.dart';

class AktivEdzesKepernyo extends StatefulWidget {
  final Edzes? sablonEdzes;
  const AktivEdzesKepernyo({super.key, this.sablonEdzes});

  @override
  State<AktivEdzesKepernyo> createState() => _AktivEdzesKepernyoState();
}

class _AktivEdzesKepernyoState extends State<AktivEdzesKepernyo> {
  final FirestoreSzolgaltatas _fs = FirestoreSzolgaltatas();
  String _edzesNeve = "";
  bool _nevMegadva = false;

  final List<GyakorlatData> _gyakorlatok = [];
  late Stopwatch _workoutStopwatch;
  Timer? _refreshTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch();

    if (widget.sablonEdzes != null) {
      _edzesNeve = widget.sablonEdzes!.nev;
      _nevMegadva = true;
      _betoltSablon(widget.sablonEdzes!);
      _workoutStopwatch.start();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNevValaszto());
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() {});
    });
  }

  void _betoltSablon(Edzes sablon) {
    for (var ex in sablon.gyakorlatok) {
      var ujGyak = GyakorlatData(nev: ex.nev);
      for (var sz in ex.szettek) {
        ujGyak.addSet(suly: sz.suly, reps: sz.ismetlesek);
      }
      _gyakorlatok.add(ujGyak);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    for (var g in _gyakorlatok) g.dispose();
    super.dispose();
  }

  void _showNevValaszto() {
    final TextEditingController _tempController = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Edzés Neve",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "BEAST MODE",
                      style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 4
                      )
                  ),
                  const SizedBox(height: 10),
                  const Text("Milyen napod van ma?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300)),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _tempController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "pl. MELL - TRICEPSZ",
                      hintStyle: TextStyle(color: Colors.grey[800]),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF3B30))),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_tempController.text.isNotEmpty) {
                        setState(() {
                          _edzesNeve = _tempController.text;
                          _nevMegadva = true;
                          _workoutStopwatch.start();
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("MEHET!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_nevMegadva) return const Scaffold(backgroundColor: Colors.black);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Colors.grey[900]!.withOpacity(0.5), Colors.black],
            )
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _gyakorlatok.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _gyakorlatok.length,
                  itemBuilder: (context, index) => _buildGyakorlatCard(index),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_edzesNeve.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Row(
                children: [
                  const Icon(Icons.timer, color: Color(0xFFFF3B30), size: 16),
                  const SizedBox(width: 5),
                  Text(
                      _formatDuration(_workoutStopwatch.elapsed),
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()]
                      )
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.grey, size: 30),
            onPressed: () => _showNevValaszto(),
          )
        ],
      ),
    );
  }

  Widget _buildGyakorlatCard(int gIndex) {
    final g = _gyakorlatok[gIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFFF3B30).withOpacity(0.2), Colors.transparent]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: Color(0xFFFF3B30), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(g.nev.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () => setState(() => _gyakorlatok.removeAt(gIndex))),
              ],
            ),
          ),
          _buildSetHeader(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: g.szettek.length,
            itemBuilder: (context, sIndex) => _buildSetRow(gIndex, sIndex),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => setState(() => g.addSet()),
            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
            label: const Text("SOROZAT HOZZÁADÁSA", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSetHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Expanded(flex: 1, child: Text("SET", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: Text("SÚLY (KG)", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          const Expanded(flex: 2, child: Text("ISMÉTLÉS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildSetRow(int gIndex, int sIndex) {
    final s = _gyakorlatok[gIndex].szettek[sIndex];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.isDone ? Colors.green.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("${sIndex + 1}", style: TextStyle(color: s.isDone ? Colors.green : Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
          Expanded(flex: 2, child: _buildCompactInput(s.sulyC, s.isDone)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _buildCompactInput(s.repsC, s.isDone)),
          GestureDetector(
            onTap: () {
              setState(() => s.isDone = !s.isDone);
              if (s.isDone) HapticFeedback.heavyImpact();
            },
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: s.isDone ? Colors.green : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s.isDone ? Icons.check : Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInput(TextEditingController ctrl, bool locked) {
    return Container(
      decoration: BoxDecoration(
        color: locked ? Colors.transparent : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: locked ? Colors.transparent : Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        enabled: !locked,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(color: locked ? Colors.grey : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionBtn(
                label: "GYAKORLAT +",
                color: const Color(0xFF1E1E1E),
                onTap: () => _showUjGyakorlatDialog()
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionBtn(
                label: _isSaving ? "MENTÉS..." : "BEFEJEZÉS",
                color: const Color(0xFFFF3B30),
                onTap: _isSaving ? () {} : _mentes
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (color != const Color(0xFF1E1E1E))
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, color: Colors.grey[800], size: 100),
          const SizedBox(height: 10),
          Text("ÜRES AZ EDZÉSTERVED", style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text("Adj hozzá egy gyakorlatot a kezdéshez!", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  void _showUjGyakorlatDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Új gyakorlat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Gyakorlat neve", hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("MÉGSE", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  var g = GyakorlatData(nev: controller.text);
                  g.addSet();
                  _gyakorlatok.add(g);
                });
              }
              Navigator.pop(c);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            child: const Text("HOZZÁADÁS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mentes() async {
    if (_gyakorlatok.isEmpty) return;
    setState(() => _isSaving = true);

    final edzes = Edzes(
      nev: _edzesNeve,
      datum: Timestamp.now(),
      duration: _workoutStopwatch.elapsed,
      gyakorlatok: _gyakorlatok.map((g) => Gyakorlat(
        nev: g.nev,
        szettek: g.szettek.map((s) => Szett(
            suly: double.tryParse(s.sulyC.text) ?? 0,
            ismetlesek: int.tryParse(s.repsC.text) ?? 0,
            befejezett: s.isDone
        )).toList(),
      )).toList(),
    );

    await _fs.edzesMentes(edzes);
    if (mounted) Navigator.pop(context);
  }
}

class GyakorlatData {
  final String nev;
  List<SzettData> szettek = [];
  GyakorlatData({required this.nev});

  void addSet({double? suly, int? reps}) {
    szettek.add(SzettData(
      suly: suly != null ? suly.toString() : "",
      reps: reps != null ? reps.toString() : "",
    ));
  }

  void dispose() {
    for (var s in szettek) s.dispose();
  }
}

class SzettData {
  final TextEditingController sulyC;
  final TextEditingController repsC;
  bool isDone;

  SzettData({String suly = "", String reps = "", this.isDone = false})
      : sulyC = TextEditingController(text: suly),
        repsC = TextEditingController(text: reps);

  void dispose() {
    sulyC.dispose();
    repsC.dispose();
  }
}