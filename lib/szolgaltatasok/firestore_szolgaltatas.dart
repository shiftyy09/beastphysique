import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:beast_physique/modellek/edzes.dart';
import 'package:beast_physique/modellek/gyakorlat.dart';
import 'package:beast_physique/modellek/szett.dart';
import 'package:beast_physique/modellek/kuldetes.dart';

class FirestoreSzolgaltatas {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Gyűjtemények referenciái
  CollectionReference get edzesekRef => _firestore
      .collection('users')
      .doc(_firebaseAuth.currentUser?.uid)
      .collection('edzesek');

  CollectionReference get kuldetesekRef => _firestore
      .collection('users')
      .doc(_firebaseAuth.currentUser?.uid)
      .collection('kuldetesek');

  CollectionReference get prsRef => _firestore // ÚJ: Rekordok gyűjteménye
      .collection('users')
      .doc(_firebaseAuth.currentUser?.uid)
      .collection('prs');

  // Új edzés mentése
  Future<void> edzesMentes(Edzes edzes) async {
    try {
      await edzesekRef.add(edzes.toMap());
      print("Edzés sikeresen mentve!");
      
      // 1. Küldetések ellenőrzése
      await checkAndCompleteMissions(edzes.nev);
      
      // 2. Rekordok (PR) frissítése
      await updatePersonalRecords(edzes);
      
    } catch (e) {
      print("Hiba az edzés mentésekor: $e");
      rethrow;
    }
  }

  // Edzés törlése
  Future<void> edzesTorlese(String edzesId) async {
    try {
      await edzesekRef.doc(edzesId).delete();
      print("Edzés sikeresen törölve!");
    } catch (e) {
      print("Hiba az edzés törlésekor: $e");
      rethrow;
    }
  }

  // --- PR (REKORD) METÓDUSOK --- //

  // Rekordok frissítése az edzés alapján
  Future<void> updatePersonalRecords(Edzes edzes) async {
    for (var gyakorlat in edzes.gyakorlatok) {
      if (gyakorlat.nev.isEmpty) continue;
      
      // Megkeressük a legnagyobb súlyt ebben az edzésben az adott gyakorlathoz
      double maxWeightInSession = 0;
      for (var szett in gyakorlat.szettek) {
        if (szett.suly > maxWeightInSession) {
          maxWeightInSession = szett.suly;
        }
      }

      if (maxWeightInSession > 0) {
        final normalizedName = gyakorlat.nev.toLowerCase().trim();
        
        // Lekérjük a jelenlegi rekordot
        final docRef = prsRef.doc(normalizedName);
        final docSnap = await docRef.get();

        if (docSnap.exists) {
          final currentPr = (docSnap.data() as Map<String, dynamic>)['weight'] as double? ?? 0;
          // Ha az új súly nagyobb, frissítjük
          if (maxWeightInSession > currentPr) {
            await docRef.set({
              'name': gyakorlat.nev,
              'weight': maxWeightInSession,
              'date': Timestamp.now(),
            });
            print("Új PR beállítva: ${gyakorlat.nev} - $maxWeightInSession kg");
          }
        } else {
          // Ha még nincs rekord, létrehozzuk
          await docRef.set({
            'name': gyakorlat.nev,
            'weight': maxWeightInSession,
            'date': Timestamp.now(),
          });
          print("Első PR beállítva: ${gyakorlat.nev} - $maxWeightInSession kg");
        }
      }
    }
  }

  // Egy adott gyakorlat rekordjának lekérése
  Future<double> getPersonalRecord(String gyakorlatNev) async {
    if (gyakorlatNev.isEmpty) return 0;
    try {
      final normalizedName = gyakorlatNev.toLowerCase().trim();
      final docSnap = await prsRef.doc(normalizedName).get();
      
      if (docSnap.exists) {
        return (docSnap.data() as Map<String, dynamic>)['weight'] as double? ?? 0;
      }
      return 0;
    } catch (e) {
      print("Hiba a PR lekérésekor: $e");
      return 0;
    }
  }

  // --- EGYÉB METÓDUSOK (Változatlanok vagy minimálisan érintettek) --- //

  Stream<List<Edzes>> edzesekStream() {
    return edzesekRef
        .orderBy('datum', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Edzes.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        });
  }

  Future<Edzes?> utolsoEdzesLekeres() async {
    try {
      final querySnapshot = await edzesekRef
          .orderBy('datum', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Edzes.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>, querySnapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print("Hiba az utolsó edzés lekérésekor: $e");
      return null;
    }
  }

  Future<Edzes?> utolsoEdzesLekeresNevSzerint(String edzesNev) async {
    if (edzesNev.isEmpty) return null;
    try {
      final querySnapshot = await edzesekRef
          .where('nev', isEqualTo: edzesNev)
          .orderBy('datum', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Edzes.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>, querySnapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print("Hiba az edzés név szerinti lekérésekor: $e");
      return null;
    }
  }

  Future<void> hetiCelMentes(int cel) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('felhasznalok').doc(userId).set({
      'hetiCel': cel,
    }, SetOptions(merge: true));
  }

  Stream<int> hetiCelLekeres() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(5);

    return _firestore
        .collection('felhasznalok')
        .doc(userId)
        .snapshots()
        .map((docSnapshot) {
      return docSnapshot.data()?['hetiCel'] ?? 5;
    });
  }

  Stream<int> hetiEdzesekSzama() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    final now = DateTime.now();
    final hetfo = now.subtract(Duration(days: now.weekday - 1));
    final hetfoStart = DateTime(hetfo.year, hetfo.month, hetfo.day);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('edzesek')
        .where('datum', isGreaterThanOrEqualTo: Timestamp.fromDate(hetfoStart))
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.length;
    });
  }

  Stream<int> napiStreakLekeres() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('edzesek')
        .orderBy('datum', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return 0;
      }

      int streak = 0;
      Set<String> uniqueWorkoutDays = {};

      for (var doc in snapshot.docs) {
        final workoutTimestamp = doc['datum'] as Timestamp;
        final workoutDate = workoutTimestamp.toDate();
        final formattedDate = DateTime(workoutDate.year, workoutDate.month, workoutDate.day).toIso8601String().substring(0, 10);
        uniqueWorkoutDays.add(formattedDate);
      }

      if (uniqueWorkoutDays.isEmpty) {
        return 0;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayFormatted = today.toIso8601String().substring(0, 10);

      if (!uniqueWorkoutDays.contains(todayFormatted)) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayFormatted = yesterday.toIso8601String().substring(0, 10);
        if (!uniqueWorkoutDays.contains(yesterdayFormatted)) {
          return 0;
        }
      }

      DateTime currentDate = today;
      while (true) {
        final formattedCurrentDate = currentDate.toIso8601String().substring(0, 10);
        if (uniqueWorkoutDays.contains(formattedCurrentDate)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    });
  }

  Stream<Map<String, dynamic>> teljesStatisztikaStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value({});

    return edzesekRef.snapshots().map((snapshot) {
      int osszEdzes = snapshot.docs.length;
      double osszEmeltSuly = 0;
      Set<String> uniqueExercises = {};
      Duration osszEdzesIdo = Duration.zero;

      for (var doc in snapshot.docs) {
        final edzes = Edzes.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        osszEdzesIdo += edzes.duration;

        for (var gyakorlat in edzes.gyakorlatok) {
          if (gyakorlat.nev.isNotEmpty) {
            uniqueExercises.add(gyakorlat.nev.toLowerCase());
          }
          for (var szett in gyakorlat.szettek) {
            osszEmeltSuly += szett.suly * szett.ismetlesek;
          }
        }
      }
      final osszEmeltSulyTonna = osszEmeltSuly / 1000.0;

      return {
        'osszEdzes': osszEdzes,
        'osszEmeltSuly': osszEmeltSulyTonna,
        'osszPr': uniqueExercises.length,
        'osszEdzesIdo': (osszEdzesIdo.inMinutes / 60.0).toStringAsFixed(1),
      };
    });
  }

  // --- KÜLDETÉS METÓDUSOK --- //

  Future<void> kuldetesHozzaadasa(Kuldetes kuldetes) async {
    try {
      await kuldetesekRef.doc(kuldetes.id).set(kuldetes.toMap());
      print("Küldetés sikeresen hozzáadva: ${kuldetes.nev}");
    } catch (e) {
      print("Hiba a küldetés hozzáadásakor: $e");
      rethrow;
    }
  }

  Future<void> kuldetesFrissitese(Kuldetes kuldetes) async {
    try {
      await kuldetesekRef.doc(kuldetes.id).update(kuldetes.toMap());
      print("Küldetés sikeresen frissítve: ${kuldetes.nev}");
    } catch (e) {
      print("Hiba a küldetés frissítésekor: $e");
      rethrow;
    }
  }

  Stream<Kuldetes?> aktivKuldetesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return kuldetesekRef
        .where('aktiv', isEqualTo: true)
        .where('teljesitve', isEqualTo: false)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return Kuldetes.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
          }
          return null;
        });
  }

  Stream<List<Kuldetes>> osszesKuldetesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return kuldetesekRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Kuldetes.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> checkAndCompleteMissions(String completedWorkoutName) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final activeMissionsSnapshot = await kuldetesekRef
        .where('aktiv', isEqualTo: true)
        .where('teljesitve', isEqualTo: false)
        .get();

    for (var doc in activeMissionsSnapshot.docs) {
      final kuldetes = Kuldetes.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (kuldetes.targetWorkoutName.toLowerCase() == completedWorkoutName.toLowerCase()) {
        kuldetes.teljesitve = true;
        kuldetes.completedDate = Timestamp.now();
        kuldetes.aktiv = false;
        await kuldetesFrissitese(kuldetes);
        print("Küldetés teljesítve: ${kuldetes.nev}");
      }
    }
  }
}
