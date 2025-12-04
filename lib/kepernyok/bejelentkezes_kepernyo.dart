import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Szükséges a FirebaseAuthException-hez
import '../szolgaltatasok/hitelesites_szolgaltatas.dart';

class BejelentkezesKepernyo extends StatefulWidget {
  const BejelentkezesKepernyo({super.key});

  @override
  State<BejelentkezesKepernyo> createState() => _BejelentkezesKepernyoState();
}

class _BejelentkezesKepernyoState extends State<BejelentkezesKepernyo> {
  final HitelesitesSzolgaltatas _authSzerviz = HitelesitesSzolgaltatas();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _betoltesAlatt = false;
  bool _isLoginView = true;
  bool _showEmailFields = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _emailJelszoMuvelet() async {
    if (_betoltesAlatt) return;
    setState(() { _betoltesAlatt = true; });

    try {
      if (_isLoginView) {
        await _authSzerviz.bejelentkezesEmaillel(
            _emailController.text.trim(), _passwordController.text.trim());
        // A navigációt a HitelesitesEllenorzo kezeli
      } else {
        await _authSzerviz.regisztracioEmaillel(
            _emailController.text.trim(), _passwordController.text.trim());
        
        // Sikeres regisztráció után visszajelzés és nézetváltás
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sikeres regisztráció! Most már bejelentkezhetsz.')),
          );
          _toggleView(); // Váltás a bejelentkezési nézetre
        }
      }
    } on FirebaseAuthException catch (e) {
      // Specifikus hibakezelés a jobb felhasználói élményért
      String hibaUzenet = 'Ismeretlen hiba történt.';
      if (e.code == 'weak-password') {
        hibaUzenet = 'A jelszó túl gyenge.';
      } else if (e.code == 'email-already-in-use') {
        hibaUzenet = 'Ez az e-mail cím már foglalt.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        hibaUzenet = 'Helytelen e-mail cím vagy jelszó.';
      } else if (e.code == 'invalid-email') {
        hibaUzenet = 'Érvénytelen e-mail cím formátum.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hibaUzenet)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _betoltesAlatt = false; });
      }
    }
  }

  Future<void> _googleBejelentkezes() async {
    if (_betoltesAlatt) return;
    setState(() { _betoltesAlatt = true; });

    final eredmeny = await _authSzerviz.bejelentkezesGoogle();

    if (mounted) {
      if (eredmeny == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A Google bejelentkezés sikertelen volt.')),
        );
      }
      setState(() { _betoltesAlatt = false; });
    }
  }

  void _toggleView() {
    setState(() {
      _isLoginView = !_isLoginView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bejelentkezes_hatter.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_betoltesAlatt)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else if (_showEmailFields) ...[
                    _buildTextField(_emailController, 'Email cím', false),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Jelszó', true),
                    const SizedBox(height: 24),
                    _buildEmailAuthButton(),
                    const SizedBox(height: 12),
                    _buildToggleViewButton(),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildGoogleButton(),
                    const SizedBox(height: 12),
                    _buildEmailLoginOptionButton(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmailLoginOptionButton() {
    return _buildAuthButton(
      onTap: () {
        setState(() {
          _showEmailFields = true;
          _isLoginView = true;
        });
      },
      label: 'BEJELENTKEZÉS E-MAILLEL',
      icon: Icons.email,
      gradientColors: [Colors.blueGrey[700]!, Colors.blueGrey[900]!],
    );
  }

  Widget _buildEmailAuthButton() {
    return _buildAuthButton(
      onTap: _emailJelszoMuvelet,
      label: _isLoginView ? 'BEJELENTKEZÉS' : 'REGISZTRÁCIÓ',
      icon: _isLoginView ? Icons.login : Icons.person_add,
      gradientColors: [const Color(0xFF007BFF), const Color(0xFF0056b3)],
    );
  }

  Widget _buildGoogleButton() {
    return _buildAuthButton(
      onTap: _googleBejelentkezes,
      label: 'BEJELENTKEZÉS GOOGLE',
      icon: Icons.login,
      gradientColors: [const Color(0xFFB71C1C), const Color(0xFFC62828)],
    );
  }
  
  Widget _buildAuthButton({required VoidCallback onTap, required String label, required IconData icon, required List<Color> gradientColors}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildToggleViewButton() {
    return TextButton(
      onPressed: _toggleView,
      child: Text(
        _isLoginView ? 'Nincs fiókod? Regisztrálj itt!' : 'Már van fiókod? Jelentkezz be!',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
