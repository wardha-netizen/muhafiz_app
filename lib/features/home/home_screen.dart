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
import 'emergency_contacts_screen.dart';
import 'madgar_portal_screen.dart';
import 'report_emergency_screen.dart';
import 'profile_screen.dart';
import 'volunteer_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
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
      final name = (snap.data()?['name'] as String?)?.trim();
      setState(() =>
          _currentUserName = (name == null || name.isEmpty) ? 'MUHAFIZ User' : name);
    } catch (_) {}
  }

  List<Widget> _getScreens() {
    return [
      _buildHomeMainContent(),
      const ReportEmergencyScreen(),
      const EmergencyContactsScreen(),
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

  // ── Main content ────────────────────────────────────────────────────────────
  Widget _buildHomeMainContent() {
    return Consumer<SettingsProvider>(
      builder: (context, themeProvider, _) {
        final bool isDark = themeProvider.themeMode == ThemeMode.dark;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(themeProvider, isDark),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    _t('TAP FOR REPORT · HOLD FOR INSTANT SOS',
                        'رپورٹ کے لیے دبائیں · فوری SOS کے لیے ہولڈ کریں'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSOSButton(),
                const SizedBox(height: 32),
                _buildQuickActions(isDark),
                const SizedBox(height: 16),
                _buildMadgarPortalCard(),
                const SizedBox(height: 24),
                _buildVolunteerSection(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header with toggles ─────────────────────────────────────────────────────
  Widget _buildHeader(SettingsProvider themeProvider, bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        final name = (data['name'] as String?)?.trim() ?? _currentUserName;
        final blood = (data['bloodGroup'] as String?) ?? '--';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name + blood group
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Hello, $name', 'ہیلو، $name'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_t('Blood Group', 'بلڈ گروپ')}: $blood',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Language pill
            GestureDetector(
              onTap: () => setState(() => _isUrdu = !_isUrdu),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _isUrdu ? 'EN' : 'اردو',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Theme toggle
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              icon: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: isDark ? Colors.amber : Colors.blueGrey,
                size: 22,
              ),
              onPressed: () => themeProvider.toggleTheme(!isDark),
            ),
          ],
        );
      },
    );
  }

  // ── SOS button ──────────────────────────────────────────────────────────────
  Widget _buildSOSButton() {
    return Center(
      child: GestureDetector(
        onTap: _navigateToReport,
        onLongPress: _triggerQuickSOS,
        child: LayoutBuilder(
          builder: (context, _) {
            final size = (MediaQuery.of(context).size.width * 0.48)
                .clamp(140.0, 200.0);
            return Container(
              height: size,
              width: size,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.redAccent, blurRadius: 24, spreadRadius: 2)
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      (
        icon: Icons.offline_bolt,
        label: _t('Offline\nGuide', 'آف لائن\nگائیڈ'),
        color: Colors.green.shade600,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OfflineGuideScreen())),
      ),
      (
        icon: Icons.analytics,
        label: _t('Disaster\nAnalysis', 'آفات\nتجزیہ'),
        color: Colors.orange.shade600,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DisasterPredictionScreen())),
      ),
      (
        icon: Icons.map,
        label: _t('Emergency\nMap', 'ہنگامی\nنقشہ'),
        color: Colors.blue.shade600,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const KarachiEmergencyMapScreen())),
      ),
      (
        icon: Icons.bluetooth_searching,
        label: _t('BT\nAlerts', 'بلوٹوتھ\nالرٹ'),
        color: Colors.purple.shade600,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BluetoothScreen())),
      ),
    ];

    final surface =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F7FB);
    final onSurface = isDark ? Colors.white70 : Colors.black87;
    final labelColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Quick Actions', 'فوری اقدامات'),
          style: TextStyle(
              color: labelColor, fontSize: 11, letterSpacing: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.black12.withValues(alpha: 0.05),
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: actions.map((a) {
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: a.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, color: a.color, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Madgar portal card ──────────────────────────────────────────────────────
  Widget _buildMadgarPortalCard() {
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

  // ── Volunteer section ───────────────────────────────────────────────────────
  Widget _buildVolunteerSection(bool isDark) {
    final surface = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F7FB);
    final onFaint = isDark ? Colors.white38 : Colors.black45;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final isVolunteer = data['isVolunteer'] == true;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const VolunteerDashboardScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isVolunteer
                    ? Colors.green.withValues(alpha: 0.45)
                    : isDark
                        ? Colors.white12
                        : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isVolunteer
                        ? Colors.green.withValues(alpha: 0.14)
                        : Colors.grey.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    color: isVolunteer ? Colors.green : Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _t('Volunteer Mode', 'رضاکارانہ موڈ'),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isVolunteer) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _t('Active', 'فعال'),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isVolunteer
                            ? _t('View & respond to emergency reports',
                                'ہنگامی رپورٹس دیکھیں اور جواب دیں')
                            : _t(
                                'View emergency feed — register as volunteer in Profile to respond',
                                'ہنگامی فیڈ دیکھیں — جواب دینے کے لیے پروفائل میں رضاکار بنیں'),
                        style: TextStyle(color: onFaint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: onFaint),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────────────
  Widget _buildBottomNav(bool isDark) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: _t('Home', 'ہوم')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.report_outlined),
            activeIcon: const Icon(Icons.report),
            label: _t('Report', 'رپورٹ')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.contacts_outlined),
            activeIcon: const Icon(Icons.contacts),
            label: _t('Contacts', 'روابط')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: _t('Profile', 'پروفائل')),
      ],
    );
  }
}
