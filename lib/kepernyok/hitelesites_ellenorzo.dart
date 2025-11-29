import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../szolgaltatasok/hitelesites_szolgaltatas.dart';
import 'navigacio_kezelo.dart';
import 'bejelentkezes_kepernyo.dart';

class HitelesitesEllenorzo extends StatelessWidget {
  const HitelesitesEllenorzo({super.key});

  @override
  Widget build(BuildContext context) {
    final szerviz = HitelesitesSzolgaltatas();
    
    return StreamBuilder<User?>(
      stream: szerviz.felhasznaloValtozas,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Sikeres bejelentkezés esetén -> NavigacioKezelo
          return const NavigacioKezelo();
        }
        // Nincs bejelentkezve -> BejelentkezesKepernyo
        return const BejelentkezesKepernyo();
      },
    );
  }
}
