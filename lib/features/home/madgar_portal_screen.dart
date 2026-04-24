import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

// ── Service model ───────────────────────────────────────────────────────────

class _Service {
  final String name;
  final String nameUrdu;
  final String number;
  final IconData icon;
  final Color color;
  final String description;
  final String Function(String userName, String time, String location)
      draftMessage;

  const _Service({
    required this.name,
    required this.nameUrdu,
    required this.number,
    required this.icon,
    required this.color,
    required this.description,
    required this.draftMessage,
  });
}

// ── Buzzer logic ─────────────────────────────────────────────────────────────
// Criteria: plays siren 3 s ON → 5 s OFF → repeat up to 5 cycles, then stops.
// Stops early when: user taps "Stop" or "Acknowledged".

class _BuzzerController {
  static const int maxCycles = 5;
  static const Duration onDuration = Duration(seconds: 3);
  static const Duration offDuration = Duration(seconds: 5);

  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  int _cycle = 0;
  bool _active = false;
  VoidCallback? onStateChanged;

  bool get isActive => _active;
  int get cycle => _cycle;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    _cycle = 0;
    await _player.setReleaseMode(ReleaseMode.release);
    _playOneCycle();
  }

  void _playOneCycle() {
    if (!_active || _cycle >= maxCycles) {
      stop();
      return;
    }
    _cycle++;
    _player.play(AssetSource('siren.mp3'));
    Vibration.vibrate(duration: 2800);
    onStateChanged?.call();

    // After ON duration, stop sound and wait OFF duration
    _timer = Timer(onDuration, () async {
      await _player.stop();
      onStateChanged?.call();
      if (!_active) return;
      _timer = Timer(offDuration, _playOneCycle);
    });
  }

  void stop() {
    _active = false;
    _cycle = 0;
    _timer?.cancel();
    _timer = null;
    _player.stop();
    Vibration.cancel();
    onStateChanged?.call();
  }

  void dispose() {
    stop();
    _player.dispose();
  }
}

// ── Karachi emergency services ───────────────────────────────────────────────

final _services = [
  _Service(
    name: 'Police (15)',
    nameUrdu: 'پولیس',
    number: '15',
    icon: Icons.local_police,
    color: Colors.blue.shade700,
    description: 'Crime, robbery, assault, threats',
    draftMessage: (u, t, l) =>
        'EMERGENCY COMPLAINT\n\nDate/Time: $t\nReporter: $u\nLocation: $l\n\n'
        'I am reporting a crime/emergency at the above location. '
        'Immediate police assistance required. '
        'Please dispatch a patrol car urgently.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'Edhi Ambulance (115)',
    nameUrdu: 'ایدھی ایمبولینس',
    number: '115',
    icon: Icons.emergency,
    color: Colors.green.shade700,
    description: 'Medical emergencies, accident victims',
    draftMessage: (u, t, l) =>
        'MEDICAL EMERGENCY — AMBULANCE NEEDED\n\nTime: $t\nRequested by: $u\nLocation: $l\n\n'
        'A medical emergency has occurred. Patient requires immediate ambulance response. '
        'Please dispatch ambulance to above location urgently.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'Chipa Welfare (1020)',
    nameUrdu: 'چھیپا ویلفیئر',
    number: '1020',
    icon: Icons.volunteer_activism,
    color: Colors.orange.shade700,
    description: 'Ambulance, funeral, blood bank, disaster relief',
    draftMessage: (u, t, l) =>
        'CHIPA WELFARE ASSISTANCE REQUEST\n\nTime: $t\nRequested by: $u\nLocation: $l\n\n'
        'Emergency welfare assistance required at above location. '
        'Please send your team urgently.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'Fire Brigade (16)',
    nameUrdu: 'فائر بریگیڈ',
    number: '16',
    icon: Icons.fire_truck,
    color: Colors.red.shade700,
    description: 'Fire, explosion, structural collapse',
    draftMessage: (u, t, l) =>
        'FIRE EMERGENCY REPORT\n\nTime: $t\nReported by: $u\nLocation: $l\n\n'
        'Active fire / explosion reported at above location. '
        'Immediate fire brigade response required. '
        'Building evacuation in progress.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'JDC Foundation',
    nameUrdu: 'جے ڈی سی فاؤنڈیشن',
    number: '03317826288',
    icon: Icons.handshake,
    color: Colors.teal.shade700,
    description: 'Disaster relief, food, shelter, flood rescue',
    draftMessage: (u, t, l) =>
        'JDC DISASTER RELIEF REQUEST\n\nTime: $t\nRequested by: $u\nLocation: $l\n\n'
        'Disaster relief assistance urgently needed at above location. '
        'Affected families require food/shelter/rescue support.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'Rangers (1101)',
    nameUrdu: 'رینجرز',
    number: '1101',
    icon: Icons.security,
    color: Colors.green.shade900,
    description: 'Security threats, terrorism, law enforcement',
    draftMessage: (u, t, l) =>
        'SECURITY EMERGENCY — RANGERS NEEDED\n\nTime: $t\nLocation: $l\nReported by: $u\n\n'
        'A serious security threat / incident has been observed at the above location. '
        'Immediate Ranger response required.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'NDMA (0800-26362)',
    nameUrdu: 'این ڈی ایم اے',
    number: '0800-26362',
    icon: Icons.flood,
    color: Colors.indigo.shade700,
    description: 'Natural disasters: floods, earthquakes, cyclones',
    draftMessage: (u, t, l) =>
        'NDMA DISASTER REPORT\n\nTime: $t\nLocation: $l\nReported by: $u\n\n'
        'Natural disaster situation reported at above location. '
        'Immediate NDMA response and relief coordination required.\n\nMUHAFIZ Emergency App',
  ),
  _Service(
    name: 'K-Electric (118)',
    nameUrdu: 'کے الیکٹرک',
    number: '118',
    icon: Icons.electric_bolt,
    color: Colors.yellow.shade800,
    description: 'Power emergency, fallen lines, electrocution',
    draftMessage: (u, t, l) =>
        'ELECTRICAL EMERGENCY\n\nTime: $t\nLocation: $l\nReported by: $u\n\n'
        'Electrical emergency at above location — possible downed power line / electrocution risk. '
        'Immediate K-Electric response required.\n\nMUHAFIZ Emergency App',
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class MadgarPortalScreen extends StatefulWidget {
  const MadgarPortalScreen({super.key});

  @override
  State<MadgarPortalScreen> createState() => _MadgarPortalScreenState();
}

class _MadgarPortalScreenState extends State<MadgarPortalScreen> {
  final _buzzer = _BuzzerController();
  String _userName = 'MUHAFIZ User';
  String _location = 'Fetching location…';
  Position? _lastPosition;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _buzzer.onStateChanged = () { if (mounted) setState(() {}); };
    _loadUserData();
    _fetchLocation();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('name1') ?? 'MUHAFIZ User');
    }
  }

  Future<void> _fetchLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _location = 'Karachi, Pakistan');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      _lastPosition = pos;
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = marks.first;
      if (mounted) {
        setState(() => _location =
            '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? 'Karachi'}');
      }
    } catch (_) {
      if (mounted) setState(() => _location = 'Karachi, Pakistan');
    }
  }

  String get _nowFormatted {
    final n = DateTime.now();
    return '${n.day}/${n.month}/${n.year} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _buzzer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F7FB);
    final surface = _isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final onSurface = _isDark ? Colors.white : Colors.black87;
    final onSurfaceMuted = _isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Madgar Portal',
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'مددگار پورٹل — Emergency Services',
              style: TextStyle(color: onSurfaceMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [_buildBuzzerToggle()],
      ),
      body: Column(
        children: [
          _buildContextBanner(surface: surface, onSurface: onSurface, onMuted: onSurfaceMuted),
          if (_buzzer.isActive) _buildBuzzerStatus(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: _services.length,
              itemBuilder: (ctx, i) => _buildServiceCard(
                _services[i],
                surface: surface,
                onSurface: onSurface,
                onMuted: _isDark ? Colors.white38 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuzzerToggle() {
    final onMuted = _isDark ? Colors.white54 : Colors.black54;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () async {
          if (_buzzer.isActive) {
            _buzzer.stop();
          } else {
            await _buzzer.start();
          }
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _buzzer.isActive
                ? Colors.red.withValues(alpha: 0.25)
                : (_isDark ? Colors.white12 : Colors.black12.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _buzzer.isActive
                  ? Colors.red
                  : (_isDark ? Colors.white24 : Colors.black12.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _buzzer.isActive ? Icons.volume_up : Icons.volume_off,
                size: 16,
                color: _buzzer.isActive ? Colors.red : onMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _buzzer.isActive ? 'BUZZER ON' : 'BUZZER',
                style: TextStyle(
                  color: _buzzer.isActive ? Colors.red : onMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextBanner({
    required Color surface,
    required Color onSurface,
    required Color onMuted,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: _isDark ? 0.3 : 0.18)),
        boxShadow: _isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_circle, color: Colors.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName,
                    style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(_location,
                    style: TextStyle(color: onMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue, size: 18),
            onPressed: _fetchLocation,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBuzzerStatus() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buzzer active — Cycle ${_buzzer.cycle}/${_BuzzerController.maxCycles} '
              '(3 s ON · 5 s OFF · stops automatically)',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () { _buzzer.stop(); setState(() {}); },
            child: const Text('STOP',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    _Service svc, {
    required Color surface,
    required Color onSurface,
    required Color onMuted,
  }) {
    return GestureDetector(
      onTap: () => _openServiceSheet(svc),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: svc.color.withValues(alpha: 0.45)),
          boxShadow: _isDark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: svc.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(svc.icon, color: svc.color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: svc.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    svc.number,
                    style: TextStyle(
                        color: svc.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(svc.name,
                style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(svc.description,
                style: TextStyle(color: onMuted, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _openServiceSheet(_Service svc) {
    final draft = svc.draftMessage(_userName, _nowFormatted, _location);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => _ServiceSheet(
          service: svc,
          draft: draft,
          onCallPressed: () => _callService(svc),
          onStreetLocPressed: _openStreetLocation,
          onBuzzerToggle: () async {
            if (_buzzer.isActive) {
              _buzzer.stop();
            } else {
              await _buzzer.start();
            }
            setState(() {});
          },
          isBuzzerActive: _buzzer.isActive,
          scrollController: scroll,
        ),
      ),
    );
  }

  Future<void> _callService(_Service svc) async {
    // Pause buzzer while calling (user will hear the call)
    if (_buzzer.isActive) _buzzer.stop();
    final uri = Uri(scheme: 'tel', path: svc.number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openStreetLocation() async {
    // Best-effort: use last known position; if missing, fetch quickly.
    Position? pos = _lastPosition;
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 6));
        _lastPosition = pos;
      } catch (_) {}
    }

    final lat = pos?.latitude;
    final lng = pos?.longitude;
    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch GPS location. Please enable Location and try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prefer geo: (Android), otherwise OpenStreetMap externally.
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(MUHAFIZ%20Location)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }

    final osm = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng',
    );
    if (await canLaunchUrl(osm)) {
      await launchUrl(osm, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Service bottom sheet ─────────────────────────────────────────────────────

class _ServiceSheet extends StatelessWidget {
  final _Service service;
  final String draft;
  final VoidCallback onCallPressed;
  final VoidCallback onStreetLocPressed;
  final VoidCallback onBuzzerToggle;
  final bool isBuzzerActive;
  final ScrollController scrollController;

  const _ServiceSheet({
    required this.service,
    required this.draft,
    required this.onCallPressed,
    required this.onStreetLocPressed,
    required this.onBuzzerToggle,
    required this.isBuzzerActive,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: service.color,
              radius: 24,
              child: Icon(service.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text(service.nameUrdu,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Call button (primary action)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: service.color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.call, color: Colors.white),
            label: Text(
              'Call ${service.number}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            onPressed: onCallPressed,
          ),
        ),
        const SizedBox(height: 12),

        // Street location (secondary action)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: service.color.withValues(alpha: 0.55)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(Icons.location_on_outlined, color: service.color),
          label: Text(
            'Street Location',
            style: TextStyle(color: service.color, fontWeight: FontWeight.bold),
          ),
          onPressed: onStreetLocPressed,
        ),
        const SizedBox(height: 14),

        // Buzzer toggle
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: isBuzzerActive ? Colors.red : Colors.white24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(
            isBuzzerActive ? Icons.volume_off : Icons.volume_up,
            color: isBuzzerActive ? Colors.red : Colors.white54,
          ),
          label: Text(
            isBuzzerActive
                ? 'Stop Buzzer Alert'
                : 'Start Buzzer Alert (5 cycles)',
            style: TextStyle(
                color: isBuzzerActive ? Colors.red : Colors.white54),
          ),
          onPressed: onBuzzerToggle,
        ),
        const SizedBox(height: 20),

        // Pre-drafted message
        Row(
          children: [
            const Icon(Icons.description_outlined,
                color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            const Text('Pre-Drafted Message',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: draft));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Message copied to clipboard'),
                  backgroundColor: Colors.green,
                ));
              },
              icon: const Icon(Icons.copy, size: 14, color: Colors.white38),
              label: const Text('Copy',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: service.color.withValues(alpha: 0.3)),
          ),
          child: Text(
            draft,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),

        // Send via SMS
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.sms_outlined, color: Colors.white54),
          label: const Text('Send via SMS',
              style: TextStyle(color: Colors.white54)),
          onPressed: () async {
            final uri = Uri(
              scheme: 'sms',
              path: service.number,
              queryParameters: {'body': draft},
            );
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
        ),

        const SizedBox(height: 12),

        // Acknowledged button — stops buzzer, closes sheet
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade800,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (isBuzzerActive) onBuzzerToggle();
            Navigator.pop(context);
          },
          child: const Text('Acknowledged — Help is Coming',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
