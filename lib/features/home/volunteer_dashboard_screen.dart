import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_provider.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isUrdu = false;
  String? _playingId;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void initState() {
    super.initState();
    // Auto-clear playing state when track finishes
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url, String id) async {
    if (_playingId == id) {
      await _audioPlayer.stop();
      setState(() => _playingId = null);
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
      setState(() => _playingId = id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _playingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('Audio playback failed: $e', 'آڈیو چلانے میں ناکامی: $e')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> _openVideo(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('Could not open video: $e', 'ویڈیو نہیں کھل سکی: $e')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> _volunteerFor(String id) async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('emergencies').doc(id).update({
        'respondedBy': FieldValue.arrayUnion([uid]),
        'volunteerCount': FieldValue.increment(1),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(
          'You volunteered for this emergency!',
          'آپ نے اس ہنگامی صورتحال میں رضاکاری کی!',
        )),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SettingsProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F7FB);
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white70 : Colors.black54;
    final onFaint = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Volunteer Dashboard', 'رضاکارانہ ڈیش بورڈ'),
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isUrdu = !_isUrdu),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                _isUrdu ? 'EN' : 'اردو',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: isDark ? Colors.amber : Colors.blueGrey,
            ),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false)
                    .toggleTheme(!isDark),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(_user?.uid)
            .get(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            );
          }
          final userData =
              userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final isRegisteredVolunteer = userData['isVolunteer'] == true;
          final userName = (userData['name'] as String?)?.trim() ?? 'Volunteer';

          return Column(
            children: [
              // Status banner
              _buildStatusBanner(
                  isRegisteredVolunteer, userName, isDark),
              const SizedBox(height: 8),
              // Emergency stream
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('emergencies')
                      .orderBy('timestamp', descending: true)
                      .limit(30)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.redAccent),
                      );
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          _t('Could not load emergencies.',
                              'ہنگامی صورتحال لوڈ نہیں ہوئی۔'),
                          style: TextStyle(color: onMuted),
                        ),
                      );
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.green, size: 52),
                            const SizedBox(height: 14),
                            Text(
                              _t('No active emergencies right now.',
                                  'ابھی کوئی فعال ہنگامی صورتحال نہیں۔'),
                              style: TextStyle(color: onMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final respondedBy = List<String>.from(
                            data['respondedBy'] ?? []);
                        final hasVolunteered =
                            respondedBy.contains(_user?.uid);
                        return _buildCard(
                          doc: doc,
                          data: data,
                          hasVolunteered: hasVolunteered,
                          isRegisteredVolunteer:
                              isRegisteredVolunteer,
                          isDark: isDark,
                          surface: surface,
                          onSurface: onSurface,
                          onMuted: onMuted,
                          onFaint: onFaint,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(
      bool isVolunteer, String userName, bool isDark) {
    final color = isVolunteer ? Colors.green : Colors.orange;
    final icon = isVolunteer
        ? Icons.check_circle_outline
        : Icons.info_outline;
    final message = isVolunteer
        ? _t(
            'You are a registered volunteer, $userName. Tap "Volunteer" on any report below to respond.',
            'آپ رجسٹرڈ رضاکار ہیں، $userName۔ مدد کے لیے نیچے کسی رپورٹ پر "رضاکاری کریں" دبائیں۔')
        : _t(
            'You are not registered as a volunteer. Enable "Volunteer Mode" in your Profile to respond to emergencies.',
            'آپ رضاکار کے طور پر رجسٹرڈ نہیں ہیں۔ پروفائل میں "رضاکارانہ موڈ" فعال کریں۔');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required QueryDocumentSnapshot doc,
    required Map<String, dynamic> data,
    required bool hasVolunteered,
    required bool isRegisteredVolunteer,
    required bool isDark,
    required Color surface,
    required Color onSurface,
    required Color onMuted,
    required Color onFaint,
  }) {
    final type = (data['type'] ?? 'Emergency').toString();
    final reporter = (data['userName'] ?? 'Unknown').toString();
    final location = (data['location'] ?? '').toString();
    final details = (data['details'] ?? '').toString();
    final ts = (data['timestamp'] as Timestamp?)?.toDate();
    final photoUrl = data['photoUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final voiceUrl = data['voiceUrl'] as String?;
    final volunteerCount = (data['volunteerCount'] as int?) ?? 0;
    final typeColor = _typeColor(type);
    final isPlaying = _playingId == doc.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: type badge + timestamp ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(type), color: typeColor, size: 13),
                      const SizedBox(width: 4),
                      Text(type,
                          style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Spacer(),
                if (ts != null)
                  Text(
                    DateFormat('dd MMM · HH:mm').format(ts),
                    style: TextStyle(color: onFaint, fontSize: 11),
                  ),
              ],
            ),
          ),
          // ── Reporter + location ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: onFaint, size: 14),
                const SizedBox(width: 4),
                Text(reporter,
                    style: TextStyle(
                        color: onMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: Colors.redAccent, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: onFaint, fontSize: 12)),
                  ),
                ],
              ),
            ),
          // ── Description ───────────────────────────────────────────
          if (details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(details,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: onMuted, fontSize: 13, height: 1.45)),
            ),
          // ── Photo ─────────────────────────────────────────────────
          if (photoUrl != null) ...[
            const SizedBox(height: 10),
            Image.network(
              photoUrl,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      height: 190,
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Colors.redAccent, strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, __, ___) => Container(
                height: 56,
                color: isDark ? Colors.white10 : Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: onFaint, size: 18),
                    const SizedBox(width: 6),
                    Text(_t('Image unavailable', 'تصویر دستیاب نہیں'),
                        style: TextStyle(color: onFaint, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ] else if (data['hasPhoto'] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _mediaChip(
                  Icons.image_outlined,
                  _t('Photo attached', 'تصویر منسلک'),
                  onFaint,
                  isDark),
            ),
          // ── Video + Audio ─────────────────────────────────────────
          if (videoUrl != null ||
              voiceUrl != null ||
              data['hasVideo'] == true ||
              data['hasVoice'] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Video: button if URL present, chip if only flag set
                  if (videoUrl != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.blue.withValues(alpha: 0.6)),
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.play_circle_outline, size: 15),
                      label: Text(_t('Play Video', 'ویڈیو چلائیں'),
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => _openVideo(videoUrl),
                    )
                  else if (data['hasVideo'] == true)
                    _mediaChip(Icons.videocam_outlined,
                        _t('Video attached', 'ویڈیو منسلک'), onFaint, isDark),
                  // Audio: button if URL present, chip if only flag set
                  if (voiceUrl != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isPlaying
                              ? Colors.redAccent.withValues(alpha: 0.6)
                              : Colors.green.withValues(alpha: 0.6),
                        ),
                        foregroundColor:
                            isPlaying ? Colors.redAccent : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(
                          isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.mic_none,
                          size: 15),
                      label: Text(
                        isPlaying
                            ? _t('Stop', 'روکیں')
                            : _t('Play Audio', 'آواز چلائیں'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _toggleAudio(voiceUrl, doc.id),
                    )
                  else if (data['hasVoice'] == true)
                    _mediaChip(Icons.mic_outlined,
                        _t('Audio attached', 'آواز منسلک'), onFaint, isDark),
                ],
              ),
            ),
          // ── Divider ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Divider(
                height: 1,
                thickness: 0.5,
                color: isDark ? Colors.white12 : Colors.black12),
          ),
          // ── Volunteer action row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism, color: onFaint, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$volunteerCount ${_t('responding', 'جواب دے رہے ہیں')}',
                  style: TextStyle(color: onFaint, fontSize: 12),
                ),
                const Spacer(),
                if (hasVolunteered)
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _t('You volunteered', 'آپ نے رضاکاری کی'),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                else if (!isRegisteredVolunteer)
                  Text(
                    _t('Register as volunteer in Profile',
                        'پروفائل میں رضاکار بنیں'),
                    style: TextStyle(color: onFaint, fontSize: 11),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.volunteer_activism, size: 15),
                    label: Text(
                      _t('Volunteer', 'رضاکاری کریں'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _volunteerFor(doc.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.deepOrange;
      case 'flood':
        return Colors.blue;
      case 'quake':
        return Colors.brown;
      case 'medical':
        return Colors.pink;
      case 'accident':
        return Colors.amber.shade700;
      case 'robbery':
      case 'assault':
        return Colors.purple;
      default:
        return Colors.redAccent;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'flood':
        return Icons.water;
      case 'quake':
        return Icons.vibration;
      case 'medical':
        return Icons.local_hospital;
      case 'accident':
        return Icons.car_crash;
      case 'robbery':
        return Icons.person_off;
      case 'assault':
        return Icons.back_hand;
      default:
        return Icons.warning_amber;
    }
  }
}
