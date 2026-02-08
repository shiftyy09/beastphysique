import 'package:flutter/material.dart';
import '../tema/theme_controller.dart';
import 'package:flutter/services.dart';

class BeallitasokKepernyo extends StatelessWidget {
  const BeallitasokKepernyo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Colors.black, // Mindig fekete a Beast vibe miatt
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'BEÁLLÍTÁSOK',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader('FIÓK ÉS PROFIL'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Profil szerkesztése',
              subtitle: 'Név, magasság, testsúly frissítése',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.cloud_sync_outlined,
              title: 'Adatok szinkronizálása',
              subtitle: 'Minden edzés mentve a felhőbe',
              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
              onTap: () {},
            ),
          ]),

          _buildSectionHeader('EDZÉS BEÁLLÍTÁSOK'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: Icons.timer_outlined,
              title: 'Alapértelmezett pihenő',
              subtitle: '90 másodperc',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.scale_outlined,
              title: 'Mértékegység',
              subtitle: 'Kilogramm (kg)',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.vibration,
              title: 'Haptikus visszajelzés',
              subtitle: 'Rezgés a szettek végén',
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: const Color(0xFFFF3B30),
              ),
              onTap: () {},
            ),
          ]),

          _buildSectionHeader('MEGJELENÉS'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: isLight ? Icons.light_mode : Icons.dark_mode,
              title: 'Sötét mód',
              subtitle: isLight ? 'Világos téma aktív' : 'Sötét téma aktív',
              trailing: Switch(
                value: !isLight,
                onChanged: (value) => toggleTheme(),
                activeColor: const Color(0xFFFF3B30),
              ),
              onTap: () => toggleTheme(),
            ),
          ]),

          _buildSectionHeader('EGYÉB'),
          _buildSettingsCard(context, [
            _buildSettingsTile(
              icon: Icons.notifications_none_outlined,
              title: 'Értesítések',
              subtitle: 'Emlékeztetők és motiváció',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.security_outlined,
              title: 'Adatvédelem',
              subtitle: 'Személyes adatok kezelése',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'Rólunk',
              subtitle: 'Verzió 1.0.0 (Beast Build)',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 30),

          // KIJELENTKEZÉS GOMB
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              // Kijelentkezési logika helye
            },
            child: const Text(
              'KIJELENTKEZÉS',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- UI ÉPÍTŐ ELEMEK ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 25, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFFF3B30), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[800]),
    );
  }
}