import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/settings_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../core/localization/app_localizations.dart';
import '../alerts/other_emergency_screen.dart';
import 'relative_alert_status_screen.dart';
import 'verification_bot.dart';

class ReportEmergencyScreen extends StatefulWidget {
  const ReportEmergencyScreen({super.key});

  @override
  State<ReportEmergencyScreen> createState() => _ReportEmergencyScreenState();
}

class _ReportEmergencyScreenState extends State<ReportEmergencyScreen> {
  String selectedType = 'Fire';
  bool _isUrdu = false;
  String _currentAddress = 'Fetching location...';
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSubmitting = false;
  XFile? _photoProof;
  XFile? _videoProof;
  String? _voiceProofPath;

  // Siren: 3 s ON → 5 s OFF → max 3 cycles, then auto-stops.
  static const int _maxSirenCycles = 3;
  Timer? _sirenTimer;
  int _sirenCycle = 0;

  void _startSirenCycle() {
    if (_sirenCycle >= _maxSirenCycles) {
      _stopSiren();
      return;
    }
    _sirenCycle++;
    _audioPlayer.play(AssetSource('siren.mp3'));
    Vibration.vibrate(pattern: [500, 200, 500, 200]);
    _sirenTimer = Timer(const Duration(seconds: 3), () async {
      await _audioPlayer.stop();
      Vibration.cancel();
      _sirenTimer = Timer(const Duration(seconds: 5), _startSirenCycle);
    });
  }

  void _stopSiren() {
    _sirenTimer?.cancel();
    _sirenTimer = null;
    _sirenCycle = 0;
    _audioPlayer.stop();
    Vibration.cancel();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _stopSiren();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _t(String eng, String ur) =>
      AppLocalizations.text(isUrdu: _isUrdu, english: eng, urdu: ur);

  // --- LOCATION LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(
      () => _currentAddress = _t(
        'Updating location...',
        'مقام اپ ڈیٹ ہو رہا ہے...',
      ),
    );

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}';
        });
      } catch (e) {
        setState(() => _currentAddress = 'Location Error: $e');
      }
    }
  }

  // --- VOICE RECORDING LOGIC ---
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _voiceProofPath = path;
      }
      _showSnackBar(
        _t('Recording Saved', 'ریکارڈنگ محفوظ ہوگئی'),
        Colors.green,
      );
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/emergency_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      } else {
        _showPermissionAlert();
      }
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() => _photoProof = photo);
    _showSnackBar('Photo attached', Colors.green);
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.camera);
    if (video == null) return;
    setState(() => _videoProof = video);
    _showSnackBar('Video attached', Colors.green);
  }

  // --- EMERGENCY PROTOCOL ---
  Future<void> _executeProtocol(String type) async {
    final bool isStealth = ['Robbery', 'Assault', 'Other'].contains(type);

    if (isStealth) {
      await ScreenBrightness().setScreenBrightness(0.05);
      _stopSiren();
    } else {
      await ScreenBrightness().resetScreenBrightness();
      _stopSiren();
      _sirenCycle = 0;
      _startSirenCycle();
    }

    await _saveEmergencyReport(type);
  }

  Future<String?> _uploadMedia(String filePath) async {
    return CloudinaryService.uploadFile(File(filePath));
  }

  Future<void> _saveEmergencyReport(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('name1') ?? 'Unknown User';
    final contactPhone = prefs.getString('contact1') ?? '';
    final contactName = prefs.getString('contactName1') ?? '';
    final emergencyContact = contactPhone.isNotEmpty
        ? (contactName.isNotEmpty ? '$contactName ($contactPhone)' : contactPhone)
        : '';

    final photoUrl = _photoProof != null
        ? await _uploadMedia(_photoProof!.path)
        : null;
    final videoUrl = _videoProof != null
        ? await _uploadMedia(_videoProof!.path)
        : null;
    final voiceUrl = _voiceProofPath != null
        ? await _uploadMedia(_voiceProofPath!)
        : null;

    await FirebaseFirestore.instance.collection('emergencies').add({
      'userId': user?.uid,
      'userName': userName,
      'emergencyContact': emergencyContact,
      'type': type,
      'status': 'active',
      'location': _currentAddress,
      'details': _descController.text.trim(),
      'hasPhoto': _photoProof != null,
      'hasVideo': _videoProof != null,
      'hasVoice': _voiceProofPath != null,
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'voiceUrl': voiceUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> _showContactAlertSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('name1') ?? 'MUHAFIZ User';
    final c1Phone = prefs.getString('contact1') ?? '';
    final c1Name = prefs.getString('contactName1') ?? 'Contact 1';
    final c2Phone = prefs.getString('contact2') ?? '';
    final c2Name = prefs.getString('contactName2') ?? 'Contact 2';

    final msg = '🚨 EMERGENCY ALERT 🚨\n'
        'User: $userName\n'
        'Type: $selectedType\n'
        'Location: $_currentAddress\n'
        '${_descController.text.trim().isNotEmpty ? 'Info: ${_descController.text.trim()}' : ''}';

    final contacts = <({String name, String phone})>[];
    if (c1Phone.isNotEmpty) contacts.add((name: c1Name, phone: c1Phone));
    if (c2Phone.isNotEmpty) contacts.add((name: c2Name, phone: c2Phone));

    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No emergency contacts found. Please add them in Profile.'),
          backgroundColor: Colors.orange,
        ));
      }
      return [];
    }

    if (!mounted) return [];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactAlertSheet(contacts: contacts, message: msg),
    );

    return contacts.map((c) => c.phone).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SettingsProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color cardBorder = isDark ? Colors.white12 : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          _t('Report Emergency', 'ہنگامی رپورٹ'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Language pill
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
          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: isDark ? Colors.amber : Colors.blueGrey,
            ),
            onPressed: () => Provider.of<SettingsProvider>(context, listen: false)
                .toggleTheme(!isDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGrid(textColor, isDark),
            const SizedBox(height: 25),
            Text(
              _t('Location', 'مقام'),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            _buildLocationCard(cardBorder, textColor),
            const SizedBox(height: 25),
            _buildProofRow(cardBorder),
            const SizedBox(height: 25),
            TextField(
              controller: _descController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: _t('Add details...', 'مزید تفصیلات...'),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(Color textColor, bool isDark) {
    final List<Map<String, dynamic>> items = [
      {'name': 'Fire', 'icon': Icons.fire_truck, 'ur': 'آگ'},
      {'name': 'Accident', 'icon': Icons.car_crash, 'ur': 'حادثہ'},
      {'name': 'Medical', 'icon': Icons.local_hospital, 'ur': 'طبی'},
      {'name': 'Flood', 'icon': Icons.tsunami, 'ur': 'سیلاب'},
      {'name': 'Quake', 'icon': Icons.vibration, 'ur': 'زلزلہ'},
      {'name': 'Robbery', 'icon': Icons.person_off, 'ur': 'ڈکیتی'},
      {'name': 'Assault', 'icon': Icons.back_hand, 'ur': 'حملہ'},
      {'name': 'Other', 'icon': Icons.more_horiz, 'ur': 'دیگر'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final bool sel = selectedType == items[i]['name'];
        return GestureDetector(
          onTap: () {
            if (items[i]['name'] == 'Other') {
              _openOtherTriage();
              return;
            }
            setState(() => selectedType = items[i]['name']);
          },
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: sel
                    ? Colors.red
                    : (isDark ? Colors.white10 : Colors.grey[100]),
                child: Icon(
                  items[i]['icon'],
                  color: sel ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _t(items[i]['name'], items[i]['ur']),
                style: TextStyle(fontSize: 11, color: textColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(Color border, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _currentAddress,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildProofRow(Color border) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _proofItem(
          Icons.camera_alt,
          _t('Photo', 'تصویر'),
          border,
          _pickPhoto,
          _photoProof != null,
        ),
        _proofItem(
          Icons.videocam,
          _t('Video', 'ویڈیو'),
          border,
          _pickVideo,
          _videoProof != null,
        ),
        _proofItem(
          _isRecording ? Icons.stop : Icons.mic,
          _isRecording ? _t('Stop', 'روکیں') : _t('Voice', 'آواز'),
          border,
          _toggleRecording,
          _voiceProofPath != null || _isRecording,
        ),
      ],
    );
  }

  Widget _proofItem(
    IconData icon,
    String label,
    Color border,
    VoidCallback onTap,
    bool isAttached,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAttached ? Icons.check_circle : icon,
              color: isAttached ? Colors.green : Colors.red,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isAttached ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isSubmitting ? null : _handleSubmit,
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _t('SUBMIT REPORT', 'رپورٹ جمع کریں'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _showPermissionAlert() {
    _showSnackBar(
      _t(
        'Please enable permissions in settings',
        'براہ کرم سیٹنگز میں اجازت دیں',
      ),
      Colors.red,
    );
  }

  bool _requiresVerification(String type) =>
      type == 'Fire' || type == 'Quake' || type == 'Flood' || type == 'Medical';

  Future<bool> _startVerification(String type) async {
    final isConfirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => VerificationBot(disasterType: type),
    );
    return isConfirmed == true;
  }

  Future<void> _handleSubmit() async {
    if (_requiresVerification(selectedType)) {
      final confirmed = await _startVerification(selectedType);
      if (!mounted) return;
      if (!confirmed) {
        _showSnackBar(
          _t(
            'Verification not confirmed. Report saved for monitoring.',
            'تصدیق مکمل نہیں ہوئی۔ رپورٹ نگرانی کے لئے محفوظ کی گئی ہے۔',
          ),
          Colors.orange,
        );
        return;
      }

      final confirmationText =
          'Confirmed $selectedType emergency via verification bot.';
      if (_descController.text.trim().isEmpty) {
        _descController.text = confirmationText;
      } else if (!_descController.text.contains(confirmationText)) {
        _descController.text = '${_descController.text}\n$confirmationText';
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await _executeProtocol(selectedType);
      if (!mounted) return;

      _showSnackBar(
        _t('Report submitted successfully!', 'رپورٹ کامیابی سے جمع ہو گئی!'),
        Colors.green,
      );

      final recipients = await _showContactAlertSheet();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RelativeAlertStatusScreen(
            recipients: recipients,
            emergencyType: selectedType,
            locationText: _currentAddress,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        _t('Submission failed: $e', 'جمع کرانے میں ناکامی: $e'),
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openOtherTriage() async {
    final result = await Navigator.push<OtherEmergencyResult>(
      context,
      MaterialPageRoute(builder: (_) => const OtherEmergencyScreen()),
    );

    if (result == null) return;

    setState(() {
      selectedType = result.suggestedType;
    });

    final triageNote =
        'Triage: ${result.category}. Suggested type: ${result.suggestedType}. ${result.summary}';
    if (_descController.text.trim().isEmpty) {
      _descController.text = triageNote;
    } else if (!_descController.text.contains(triageNote)) {
      _descController.text = '${_descController.text}\n$triageNote';
    }

    _showSnackBar(
      'Triage completed. You can attach media and submit your report.',
      Colors.green,
    );
  }
}

// ── Contact alert bottom sheet ────────────────────────────────────────────────

class _ContactAlertSheet extends StatefulWidget {
  final List<({String name, String phone})> contacts;
  final String message;

  const _ContactAlertSheet({required this.contacts, required this.message});

  @override
  State<_ContactAlertSheet> createState() => _ContactAlertSheetState();
}

class _ContactAlertSheetState extends State<_ContactAlertSheet> {
  // tracks which (contactIndex, channel) pairs have been tapped
  final Set<String> _sent = {};

  static String _toWaNumber(String phone) {
    final c = phone.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
    if (c.startsWith('92')) return c;
    if (c.startsWith('0')) return '92${c.substring(1)}';
    return '92$c';
  }

  Future<void> _launchSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone,
        queryParameters: {'body': widget.message});
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final waNum = _toWaNumber(phone);
    final encoded = Uri.encodeComponent(widget.message);
    final uri = Uri.parse('https://wa.me/$waNum?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.notification_important, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text('Alert Emergency Contacts',
                  style: TextStyle(color: onSurface,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Choose how to notify each contact',
              style: TextStyle(color: onMuted, fontSize: 12)),
          const SizedBox(height: 16),
          ...List.generate(widget.contacts.length, (i) {
            final c = widget.contacts[i];
            final smsSent = _sent.contains('${i}_sms');
            final waSent  = _sent.contains('${i}_wa');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: TextStyle(
                                    color: onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text(c.phone,
                                style: TextStyle(
                                    color: onMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: smsSent
                                    ? Colors.green
                                    : Colors.blue.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(
                            smsSent ? Icons.check : Icons.sms_outlined,
                            color: smsSent ? Colors.green : Colors.blue,
                            size: 16,
                          ),
                          label: Text(
                            smsSent ? 'SMS Sent' : 'Send SMS',
                            style: TextStyle(
                                color: smsSent ? Colors.green : Colors.blue,
                                fontSize: 13),
                          ),
                          onPressed: smsSent
                              ? null
                              : () async {
                                  await _launchSms(c.phone);
                                  setState(() => _sent.add('${i}_sms'));
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: waSent
                                    ? Colors.green
                                    : Colors.green.withValues(alpha: 0.7)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(
                            waSent ? Icons.check : Icons.chat_outlined,
                            color: waSent ? Colors.green : Colors.green.shade600,
                            size: 16,
                          ),
                          label: Text(
                            waSent ? 'Sent' : 'WhatsApp',
                            style: TextStyle(
                                color: waSent
                                    ? Colors.green
                                    : Colors.green.shade600,
                                fontSize: 13),
                          ),
                          onPressed: waSent
                              ? null
                              : () async {
                                  await _launchWhatsApp(c.phone);
                                  setState(() => _sent.add('${i}_wa'));
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done — Help is Coming',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
