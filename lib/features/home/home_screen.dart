import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../maps/karachi_emergency_map_screen.dart';
import '../offline/offline_guide_screen.dart';
import '../bluetooth/bluetooth_screen.dart';
import '../disaster/disaster_prediction_screen.dart';
import 'madgar_portal_screen.dart';
import 'permissions_screen.dart';
import 'report_emergency_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isVolunteer = false;
  bool _isUrdu = false;
  final User? user = FirebaseAuth.instance.currentUser;
  String _currentUserName = 'MUHAFIZ User';

  String _t(String eng, String ur) =>
      AppLocalizations.text(isUrdu: _isUrdu, english: eng, urdu: ur);

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final uid = user?.uid;
    if (uid == null) return;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      final data = snap.data();
      final name = (data?['name'] as String?)?.trim();
      setState(() => _currentUserName = (name == null || name.isEmpty) ? 'MUHAFIZ User' : name);
    } catch (_) {
      // Keep fallback
    }
  }

  List<Widget> _getScreens() {
    return [
      _buildHomeMainContent(),
      const ReportEmergencyScreen(),
      const PermissionsScreen(),
      const ProfileScreen(),
    ];
  }

  void _navigateToReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportEmergencyScreen()),
    );
  }

  Future<void> _triggerQuickSOS() async {
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        await FirebaseFirestore.instance.collection('emergencies').add({
          'userId': user!.uid,
          'userName': userData['name'] ?? 'Anonymous',
          'bloodGroup': userData['bloodGroup'] ?? 'Unknown',
          'type': 'IMMEDIATE SOS',
          'status': 'Critical',
          'timestamp': FieldValue.serverTimestamp(),
          'location': userData['lastLocation'],
        });
      }
      if (!mounted) return;
      setState(() => _selectedIndex = 1);
    } catch (e) {
      debugPrint('SOS Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SettingsProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: _getScreens()[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHomeMainContent() {
    return Consumer<SettingsProvider>(
      builder: (context, themeProvider, _) {
        final bool isDark = themeProvider.themeMode == ThemeMode.dark;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isUrdu = !_isUrdu),
                      child: Text(
                        _isUrdu ? 'English' : 'اردو',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                _buildMedicalHeader(themeProvider),
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    _t('TAP OR HOLD SOS IN DANGER',
                        'خطرے میں SOS کو دبائیں یا ہولڈ کریں'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSOSButton(),
                const SizedBox(height: 32),
                _buildQuickActions(isDark),
                const SizedBox(height: 16),
                _buildMadgarPortalCard(isDark),
                const SizedBox(height: 32),
                _buildVolunteerSection(isDark),
                if (_isVolunteer) ...[
                  const SizedBox(height: 30),
                  Text(
                    _t('Nearby Alerts', 'قریبی الرٹس'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildLiveFeed(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicalHeader(SettingsProvider themeProvider) {
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'User';
          final blood = data['bloodGroup'] ?? '--';
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Hello, $name', 'ہیلو، $name'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Blood Group: $blood',
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Switch(
                value: isDark,
                onChanged: (v) => themeProvider.toggleTheme(v),
              ),
            ],
          );
        }
        return const LinearProgressIndicator(color: Colors.redAccent);
      },
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: GestureDetector(
        onTap: _navigateToReport,
        onLongPress: _triggerQuickSOS,
        child: Container(
          height: 200,
          width: 200,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 20)],
          ),
          child: const Center(
            child: Text(
              'SOS',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = [
      (
        icon: Icons.offline_bolt,
        label: _t('Offline Guide', 'آف لائن گائیڈ'),
        color: Colors.green.shade700,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OfflineGuideScreen())),
      ),
      (
        icon: Icons.analytics,
        label: _t('Disaster Analysis', 'آفات تجزیہ'),
        color: Colors.orange.shade700,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DisasterPredictionScreen())),
      ),
      (
        icon: Icons.map,
        label: _t('Emergency Map', 'ہنگامی نقشہ'),
        color: Colors.blue.shade700,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const KarachiEmergencyMapScreen())),
      ),
      (
        icon: Icons.bluetooth_searching,
        label: _t('BT Alerts', 'بلوٹوتھ الرٹ'),
        color: Colors.purple.shade700,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BluetoothScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Quick Actions', 'فوری اقدامات'),
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: a.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: a.color.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, color: a.color, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMadgarPortalCard(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MadgarPortalScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.emergency_share, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Madgar Portal', 'مددگار پورٹل'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _t(
                      'Police · Edhi · Chipa · Fire · Rangers · NDMA',
                      'پولیس · ایدھی · چھیپا · فائر · رینجرز · این ڈی ایم اے',
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerSection(bool isDark) {
    return SwitchListTile(
      title: Text(
        _t('Volunteer Mode', 'رضاکارانہ موڈ'),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      value: _isVolunteer,
      activeThumbColor: Colors.redAccent,
      onChanged: (v) => setState(() => _isVolunteer = v),
    );
  }

  Widget _buildLiveFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergencies')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Could not load emergencies.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No recent emergencies right now.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        // Keep UI robust even if older documents have inconsistent `status` values.
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          if (status.isEmpty) return true; // legacy docs
          return status == 'active' || status == 'critical';
        }).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No recent emergencies right now.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return Column(
          children: filtered.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final type = (data['type'] ?? 'Emergency').toString();
            final reporter = (data['userName'] ?? 'Unknown').toString();
            final location = (data['location'] ?? '').toString();
            final ts = (data['timestamp'] as Timestamp?)?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reported by: $reporter',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        if (location.isNotEmpty)
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        if (ts != null)
                          Text(
                            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white24, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: user == null
                        ? null
                        : () => _volunteerForEmergency(emergencyId: d.id),
                    child: const Text(
                      'Volunteer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _volunteerForEmergency({required String emergencyId}) async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final emerRef =
            FirebaseFirestore.instance.collection('emergencies').doc(emergencyId);
        final volRef = emerRef.collection('volunteers').doc(uid);

        final existing = await tx.get(volRef);
        if (existing.exists) return;

        tx.set(volRef, {
          'volunteerId': uid,
          'volunteerName': _currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        tx.update(emerRef, {
          'volunteerCount': FieldValue.increment(1),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You volunteered for this emergency.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not volunteer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBottomNav(bool isDark) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home), label: _t('Home', 'ہوم')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.report), label: _t('Report', 'رپورٹ')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.security),
            label: _t('Permissions', 'اجازتیں')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person), label: _t('Profile', 'پروفائل')),
      ],
    );
  }
}
