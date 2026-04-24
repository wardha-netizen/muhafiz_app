import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          type,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              label: 'Reported By',
              value: reporter,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: location.isEmpty ? 'Location not available' : location,
              iconColor: Colors.blueAccent,
            ),
            if (bloodGroup.isNotEmpty && bloodGroup != 'Unknown') ...[
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.bloodtype_outlined,
                label: 'Blood Group',
                value: bloodGroup,
                iconColor: Colors.redAccent,
              ),
            ],
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.phone_outlined,
                label: 'Emergency Contact',
                value: contact,
                iconColor: Colors.greenAccent,
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoCard(
                icon: Icons.notes,
                label: 'Notes / Details',
                value: details,
                iconColor: Colors.amberAccent,
              ),
            ],
            if (photoUrl != null || videoUrl != null || voiceUrl != null) ...[
              const SizedBox(height: 24),
              const Text(
                'SUBMITTED EVIDENCE',
                style: TextStyle(
                    color: Colors.white38,
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
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.redAccent),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => _buildMediaUnavailableCard(
                      Icons.image_not_supported, 'Photo unavailable'),
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
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_circle_outline,
                          color: Colors.purpleAccent, size: 32),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Video Evidence',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Tap to open video',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new,
                          color: Colors.white38, size: 18),
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
                    color: const Color(0xFF1E1E1E),
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
                            const Text('Voice Recording',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              _isPlaying ? 'Playing...' : 'Tap to play',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.headphones_outlined,
                        color: Colors.white38,
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
        border:
            Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
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
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (ts != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(ts),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
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
        color: const Color(0xFF1A1A1A),
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
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.4)),
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white24, size: 20),
            const SizedBox(width: 8),
            Text(message,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
