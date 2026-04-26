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
                if (_isVolunteer) ...[
                  const SizedBox(height: 24),
                  Text(
                    _t('Nearby Alerts', 'قریبی الرٹس'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLiveFeed(isDark),
                ],
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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        _t('Volunteer Mode', 'رضاکارانہ موڈ'),
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _t('See & respond to nearby emergencies',
            'قریبی ہنگامی صورتحال دیکھیں اور جواب دیں'),
        style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
      ),
      value: _isVolunteer,
      activeThumbColor: Colors.redAccent,
      onChanged: (v) => setState(() => _isVolunteer = v),
    );
  }

  // ── Live feed ───────────────────────────────────────────────────────────────
  Widget _buildLiveFeed(bool isDark) {
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _t('Could not load emergencies.', 'ہنگامی صورتحال لوڈ نہیں ہو سکی۔'),
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        final filtered = docs.where((d) {
          final status =
              ((d.data() as Map)['status'] ?? '').toString().trim().toLowerCase();
          return status.isEmpty || status == 'active' || status == 'critical';
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _t('No recent emergencies right now.',
                  'ابھی کوئی حالیہ ہنگامی صورتحال نہیں۔'),
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final titleColor = isDark ? Colors.white : Colors.black87;
        final subColor = isDark ? Colors.white54 : Colors.black54;
        final metaColor = isDark ? Colors.white38 : Colors.black45;

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
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.25)),
                boxShadow: isDark
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type,
                            style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '${_t('Reported by', 'رپورٹ کرنے والا')}: $reporter',
                          style: TextStyle(color: subColor, fontSize: 12),
                        ),
                        if (location.isNotEmpty)
                          Text(location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: metaColor, fontSize: 11)),
                        if (ts != null)
                          Text(
                            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: metaColor, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: user == null
                        ? null
                        : () => _volunteerForEmergency(emergencyId: d.id),
                    child: Text(
                      _t('Help', 'مدد'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
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
        final emerRef = FirebaseFirestore.instance
            .collection('emergencies')
            .doc(emergencyId);
        final volRef = emerRef.collection('volunteers').doc(uid);
        final existing = await tx.get(volRef);
        if (existing.exists) return;
        tx.set(volRef, {
          'volunteerId': uid,
          'volunteerName': _currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
        });
        tx.update(emerRef, {'volunteerCount': FieldValue.increment(1)});
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('You volunteered for this emergency.',
            'آپ نے اس ہنگامی صورتحال میں رضاکاری کی۔')),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _t('Could not volunteer: $e', 'رضاکاری نہیں ہو سکی: $e')),
        backgroundColor: Colors.red,
      ));
    }
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
