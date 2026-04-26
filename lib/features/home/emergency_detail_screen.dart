import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_provider.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final String emergencyId;
  final Map<String, dynamic> data;

  const EmergencyDetailScreen({
    super.key,
    required this.emergencyId,
    required this.data,
  });

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  bool get _isDark =>
      Provider.of<SettingsProvider>(context, listen: false).themeMode ==
      ThemeMode.dark;
  Color get _bg =>
      _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
  Color get _surface => _isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _appBarBg =>
      _isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _onSurface => _isDark ? Colors.white : Colors.black87;
  Color get _onMuted => _isDark ? Colors.white54 : Colors.black54;
  Color get _onFaint => _isDark ? Colors.white38 : Colors.black38;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _isPlaying = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when theme changes
    Provider.of<SettingsProvider>(context);

    final data = widget.data;
    final type = (data['type'] ?? 'Emergency').toString();
    final reporter = (data['userName'] ?? 'Unknown').toString();
    final location = (data['location'] ?? '').toString();
    final details = (data['details'] ?? '').toString();
    final contact = (data['emergencyContact'] ?? '').toString();
    final photoUrl = data['photoUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final voiceUrl = data['voiceUrl'] as String?;
    final ts = (data['timestamp'] as Timestamp?)?.toDate();
    final status = (data['status'] ?? 'active').toString();
    final bloodGroup = (data['bloodGroup'] ?? '').toString();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: _onSurface),
        title: Text(
          type,
          style: TextStyle(
              color: _onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isUrdu = !_isUrdu),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(_isUrdu ? 'EN' : 'اردو',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ),
          IconButton(
            icon: Icon(
                _isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: _isDark ? Colors.amber : Colors.blueGrey),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false)
                    .toggleTheme(!_isDark),
          ),
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status.toLowerCase() == 'critical'
                  ? Colors.red.shade800
                  : Colors.orange.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeBanner(type, ts),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.person_outline,
              label: _t('Reported By', 'رپورٹ کرنے والا'),
              value: reporter,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              label: _t('Location', 'مقام'),
              value: location.isEmpty
                  ? _t('Location not available', 'مقام دستیاب نہیں')
                  : location,
              iconColor: Colors.blueAccent,
            ),
            if (bloodGroup.isNotEmpty && bloodGroup != 'Unknown') ...[
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.bloodtype_outlined,
                label: _t('Blood Group', 'بلڈ گروپ'),
                value: bloodGroup,
                iconColor: Colors.redAccent,
              ),
            ],
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.phone_outlined,
                label: _t('Emergency Contact', 'ہنگامی رابطہ'),
                value: contact,
                iconColor: Colors.greenAccent,
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.notes,
                label: _t('Notes / Details', 'نوٹس / تفصیل'),
                value: details,
                iconColor: Colors.amberAccent,
              ),
            ],
            if (photoUrl != null || videoUrl != null || voiceUrl != null) ...[
              const SizedBox(height: 24),
              Text(
                _t('SUBMITTED EVIDENCE', 'جمع کردہ ثبوت'),
                style: TextStyle(
                    color: _onFaint,
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
            ],
            if (photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  photoUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 180,
                          color: _surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.redAccent),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => _buildMediaUnavailableCard(
                      Icons.image_not_supported,
                      _t('Photo unavailable', 'تصویر دستیاب نہیں')),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (videoUrl != null) ...[
              GestureDetector(
                onTap: () => _openVideo(videoUrl),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline,
                          color: Colors.purpleAccent, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Video Evidence', 'ویڈیو ثبوت'),
                                style: TextStyle(
                                    color: _onSurface,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                                _t('Tap to open video',
                                    'ویڈیو کھولنے کے لیے تھپتھپائیں'),
                                style: TextStyle(
                                    color: _onFaint, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new, color: _onFaint, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (voiceUrl != null) ...[
              GestureDetector(
                onTap: () => _toggleAudio(voiceUrl),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.tealAccent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.tealAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('Voice Recording', 'آواز کی ریکارڈنگ'),
                                style: TextStyle(
                                    color: _onSurface,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              _isPlaying
                                  ? _t('Playing...', 'چل رہا ہے...')
                                  : _t('Tap to play',
                                      'سننے کے لیے تھپتھپائیں'),
                              style: TextStyle(
                                  color: _onFaint, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.headphones_outlined,
                        color: _onFaint,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBanner(String type, DateTime? ts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
            child: Icon(_getEmergencyIcon(type),
                color: Colors.redAccent, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                      color: _onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (ts != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(ts),
                    style: TextStyle(color: _onMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = Colors.redAccent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: _onFaint,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: _onSurface, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUnavailableCard(IconData icon, String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _onFaint, size: 20),
            const SizedBox(width: 8),
            Text(message,
                style: TextStyle(color: _onMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  IconData _getEmergencyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.fire_truck;
      case 'accident':
        return Icons.car_crash;
      case 'medical':
        return Icons.local_hospital;
      case 'flood':
        return Icons.tsunami;
      case 'quake':
        return Icons.vibration;
      case 'robbery':
        return Icons.person_off;
      case 'assault':
        return Icons.back_hand;
      default:
        return Icons.warning_amber;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $h:$m';
  }
}
