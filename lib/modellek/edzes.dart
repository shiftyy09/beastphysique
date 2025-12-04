import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beast_physique/modellek/gyakorlat.dart';

class Edzes {
  String? id;
  String nev;
  Timestamp datum;
  Duration duration;
  List<Gyakorlat> gyakorlatok;

  Edzes({
    this.id,
    required this.nev,
    required this.datum,
    required this.duration,
    required this.gyakorlatok,
  });

  // Firebase-ből való betöltés
  factory Edzes.fromMap(Map<String, dynamic> data, String id) {
    var gyakorlatokList = data['gyakorlatok'] as List?;
    List<Gyakorlat> gyakorlatokObj = gyakorlatokList != null
        ? gyakorlatokList.map((gyakorlatData) => Gyakorlat.fromMap(gyakorlatData as Map<String, dynamic>)).toList()
        : [];

    return Edzes(
      id: id,
      nev: data['nev'] ?? '',
      datum: data['datum'] as Timestamp? ?? Timestamp.now(),
      duration: Duration(microseconds: data['duration'] ?? 0), // duration tárolása int-ként microszekundumban
      gyakorlatok: gyakorlatokObj,
    );
  }

  // Firebase-be való mentés
  Map<String, dynamic> toMap() {
    return {
      'nev': nev,
      'datum': datum,
      'duration': duration.inMicroseconds, // duration mentése microszekundumban
      'gyakorlatok': gyakorlatok.map((gyakorlat) => gyakorlat.toMap()).toList(),
    };
  }
}
