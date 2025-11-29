import 'package:flutter/material.dart';
import '../szolgaltatasok/hitelesites_szolgaltatas.dart';

class BejelentkezesKepernyo extends StatefulWidget {
  const BejelentkezesKepernyo({super.key});

  @override
  State<BejelentkezesKepernyo> createState() => _BejelentkezesKepernyoState();
}

class _BejelentkezesKepernyoState extends State<BejelentkezesKepernyo> {
  bool _betoltesAlatt = false;

  Future<void> _googleBejelentkezes() async {
    setState(() {
      _betoltesAlatt = true;
    });

    final szerviz = HitelesitesSzolgaltatas();
    final eredmeny = await szerviz.bejelentkezesGoogle();

    if (mounted) {
      setState(() {
        _betoltesAlatt = false;
      });
      
      if (eredmeny != null) {
        // Sikeres bejelentkezés - itt nem kell navigálni, mert a StreamBuilder a main.dart-ban/hitelesites_ellenorzo.dart-ban
        // automatikusan átvált a Főképernyőre
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A Google bejelentkezés sikertelen volt.')),
        );
      }
    }
  }

  Future<void> _vendegBejelentkezes() async {
    setState(() {
      _betoltesAlatt = true;
    });

    final szerviz = HitelesitesSzolgaltatas();
    final eredmeny = await szerviz.bejelentkezesVendegkent();

    if (mounted) {
      setState(() {
        _betoltesAlatt = false;
      });
      
      if (eredmeny != null) {
        // Sikeres bejelentkezés - itt sem kell navigálni
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A vendég bejelentkezés sikertelen volt.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF2C1608), // Sötét narancsos árnyalat alulra
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo helye
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Color(0xFFE65100),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BEAST PHYSICAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lépd át a határaidat!',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                
                if (_betoltesAlatt)
                  const CircularProgressIndicator(color: Color(0xFFE65100))
                else
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _googleBejelentkezes,
                        icon: const Icon(Icons.login), // Ideiglenes ikon, Google logó helyett
                        label: const Text('Bejelentkezés Google fiókkal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
                      const SizedBox(height: 16), // Térköz a gombok között
                      TextButton(
                        onPressed: _vendegBejelentkezes,
                        child: const Text(
                          'Belépés vendégként',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
