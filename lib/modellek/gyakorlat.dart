import 'package:beast_physique/modellek/szett.dart';

class Gyakorlat {
  String nev;
  List<Szett> szettek;

  Gyakorlat({
    required this.nev,
    required this.szettek,
  });

  // Firebase-ből való olvasáshoz
  factory Gyakorlat.fromMap(Map<String, dynamic> data) {
    var szettekList = data['szettek'] as List<dynamic>?;
    List<Szett> szettekObj = szettekList != null
        ? szettekList.map((szettData) => Szett.fromMap(szettData as Map<String, dynamic>)).toList()
        : [];

    return Gyakorlat(
      nev: data['nev'] as String,
      szettek: szettekObj,
    );
  }

  // Firebase-be való íráshoz
  Map<String, dynamic> toMap() {
    return {
      'nev': nev,
      'szettek': szettek.map((szett) => szett.toMap()).toList(),
    };
  }
}
