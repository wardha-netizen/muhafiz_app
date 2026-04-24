import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class ReportMisuseScreen extends StatefulWidget {
  const ReportMisuseScreen({super.key});

  @override
  State<ReportMisuseScreen> createState() => _ReportMisuseScreenState();
}

class _ReportMisuseScreenState extends State<ReportMisuseScreen> {
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const List<String> _reasons = [
    'Fake Emergency Alert',
    'Fake Help/Trolling',
    'Inappropriate/Graphic Media',
    'Spam/Harassment',
  ];

  String _selectedReason = 'Fake Emergency Alert';
  File? _evidenceImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _evidenceImage = File(picked.path));
  }

  Future<String?> _uploadEvidence(File file) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final name = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('misuse_reports/$name');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Evidence upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? evidenceUrl;
      if (_evidenceImage != null) {
        evidenceUrl = await _uploadEvidence(_evidenceImage!);
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': uid,
        'reportCategory': _selectedReason,
        'description': _descController.text.trim(),
        'evidenceUrl': evidenceUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Report submitted. Thank you for keeping Muhafiz safe.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Report Misuse',
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Help us keep Muhafiz safe',
              style: TextStyle(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'All reports are reviewed by our team and kept confidential.',
              style: TextStyle(color: hintColor, fontSize: 13),
            ),
            Divider(color: dividerColor, height: 32),

            // Reason for Report
            _sectionLabel('Reason for Report', textColor),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  dropdownColor:
                      isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: textColor, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.redAccent),
                  items: _reasons
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Description
            _sectionLabel('Description', textColor),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 5,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 22),

            // Evidence image
            _sectionLabel('Attach Evidence (optional)', textColor),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: _evidenceImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(
                              _evidenceImage!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _evidenceImage = null),
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 28),
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.redAccent, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to attach image',
                            style: TextStyle(color: hintColor, fontSize: 13),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 36),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  disabledBackgroundColor:
                      Colors.redAccent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      );
}
