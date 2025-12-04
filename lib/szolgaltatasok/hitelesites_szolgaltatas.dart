import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HitelesitesSzolgaltatas {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Jelenlegi felhasználó lekérése
  User? get jelenlegiFelhasznalo => _firebaseAuth.currentUser;

  // Felhasználó állapot figyelése
  Stream<User?> get felhasznaloValtozas => _firebaseAuth.authStateChanges();

  // Regisztráció e-maillel és jelszóval
  Future<UserCredential?> regisztracioEmaillel(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Kezeld a specifikus hibákat, pl. gyenge jelszó, e-mail már használatban van
      print("Hiba a regisztráció során: ${e.message}");
      rethrow; // Dobjuk tovább a hibát a UI réteg felé
    } catch (e) {
      print("Általános hiba a regisztráció során: $e");
      rethrow;
    }
  }

  // Bejelentkezés e-maillel és jelszóval
  Future<UserCredential?> bejelentkezesEmaillel(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Kezeld a specifikus hibákat, pl. rossz jelszó, felhasználó nem található
      print("Hiba a bejelentkezés során: ${e.message}");
      rethrow;
    } catch (e) {
      print("Általános hiba a bejelentkezés során: $e");
      rethrow;
    }
  }

  // Bejelentkezés Google fiókkal
  Future<UserCredential?> bejelentkezesGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print("Hiba a Google bejelentkezés során: $e");
      return null;
    }
  }

  // Bejelentkezés vendégként (anonim)
  Future<UserCredential?> bejelentkezesVendegkent() async {
    try {
      return await _firebaseAuth.signInAnonymously();
    } catch (e) {
      print("Hiba az anonim bejelentkezés során: $e");
      return null;
    }
  }

  // Kijelentkezés
  Future<void> kijelentkezes() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
