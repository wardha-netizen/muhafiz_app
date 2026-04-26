import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_routes.dart';
import '../../services/settings_provider.dart';
import '../../services/cloudinary_service.dart';
import 'report_misuse_screen.dart';
import 'permissions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _relativeNameController = TextEditingController();
  final TextEditingController _relativePhoneController = TextEditingController();
  final TextEditingController _relative2NameController = TextEditingController();
  final TextEditingController _relative2PhoneController = TextEditingController();

  // State
  String _selectedBloodGroup = 'O+';
  bool _isVolunteer = false;
  bool _isEditing = false;
  bool _loaded = false;
  bool _isUrdu = false;
  bool _isUploading = false;
  File? _imageFile;
  String? _profileImageUrl;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relativeNameController.dispose();
    _relativePhoneController.dispose();
    _relative2NameController.dispose();
    _relative2PhoneController.dispose();
    super.dispose();
  }

  void _loadData(Map<String, dynamic> userData) {
    if (_loaded) return;
    _nameController.text = userData['name'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _selectedBloodGroup = userData['bloodGroup'] ?? 'O+';
    _isVolunteer = userData['isVolunteer'] ?? false;
    _profileImageUrl = userData['profile_pic'];

    final contacts = userData['contacts'] as List? ?? [];
    if (contacts.isNotEmpty) {
      _relativeNameController.text = (contacts[0] as Map)['name'] ?? '';
      _relativePhoneController.text = (contacts[0] as Map)['phone'] ?? '';
    }
    if (contacts.length > 1) {
      _relative2NameController.text = (contacts[1] as Map)['name'] ?? '';
      _relative2PhoneController.text = (contacts[1] as Map)['phone'] ?? '';
    }
    _loaded = true;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (pickedFile == null) return;
      final file = File(pickedFile.path);
      setState(() => _imageFile = file);
      await _uploadProfilePhoto(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Could not open gallery: $e', 'گیلری نہیں کھل سکی: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfilePhoto(File file) async {
    if (user == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await CloudinaryService.uploadFile(file);
      if (url == null) throw Exception('Cloudinary returned no URL');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profile_pic': url});

      if (!mounted) return;
      setState(() => _profileImageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Profile photo updated!', 'تصویر اپ ڈیٹ ہو گئی!')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _changePassword() async {
    if (user?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Password reset email sent!', 'پاس ورڈ ری سیٹ ای میل بھیج دی!')),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    try {
      final c1Name = _relativeNameController.text.trim();
      final c1Phone = _relativePhoneController.text.trim();
      final c2Name = _relative2NameController.text.trim();
      final c2Phone = _relative2PhoneController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'isVolunteer': _isVolunteer,
        'relative_name': c1Name,
        'relative_phone': c1Phone,
        'contacts': [
          {'name': c1Name, 'phone': c1Phone, 'relation': 'Emergency Contact 1'},
          {'name': c2Name, 'phone': c2Phone, 'relation': 'Emergency Contact 2'},
        ],
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name1', _nameController.text.trim());
      await prefs.setString('contact1', c1Phone);
      await prefs.setString('contactName1', c1Name);
      await prefs.setString('contact2', c2Phone);
      await prefs.setString('contactName2', c2Name);

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Profile updated!', 'پروفائل اپ ڈیٹ ہو گئی!')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Error: $e', 'خرابی: $e')),
          backgroundColor: Colors.red,
        ),
      );
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
    final dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _t('Safety Profile', 'حفاظتی پروفائل'),
          style: TextStyle(color: onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
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
          // Edit toggle
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.redAccent,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          // Logout
          IconButton(
            icon: Icon(Icons.logout, color: onSurface),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return Center(
              child: Text(
                _t('Profile not found.', 'پروفائل نہیں ملی۔'),
                style: TextStyle(color: onSurface),
              ),
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          _loadData(userData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null),
                      child: (_imageFile == null && _profileImageUrl == null)
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: isDark ? Colors.white24 : Colors.black26,
                            )
                          : null,
                    ),
                    // Upload loading overlay
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      ),
                    if (_isEditing && !_isUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  _t('Full Name', 'پورا نام'),
                  _nameController,
                  Icons.person_outline,
                  enabled: _isEditing,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                _buildTextField(
                  _t('My Phone', 'میرا فون'),
                  _phoneController,
                  Icons.phone_android,
                  enabled: _isEditing,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                _buildTextField(
                  _t('Email', 'ای میل'),
                  _emailController,
                  Icons.email_outlined,
                  enabled: false,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                Divider(color: dividerColor, height: 40),
                _buildBloodGroupDropdown(
                  enabled: _isEditing,
                  isDark: isDark,
                  surface: surface,
                  onSurface: onSurface,
                ),
                _buildVolunteerSwitch(
                  enabled: _isEditing,
                  onSurface: onSurface,
                ),
                const SizedBox(height: 20),
                _headerText(_t('Emergency Contact 1', 'ہنگامی رابطہ 1'), color: onMuted),
                _buildTextField(
                  _t('Contact 1 Name', 'رابطہ 1 کا نام'),
                  _relativeNameController,
                  Icons.security,
                  enabled: _isEditing,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                _buildTextField(
                  _t('Contact 1 Phone', 'رابطہ 1 کا فون'),
                  _relativePhoneController,
                  Icons.contact_phone,
                  enabled: _isEditing,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                const SizedBox(height: 8),
                _headerText(_t('Emergency Contact 2', 'ہنگامی رابطہ 2'), color: onMuted),
                _buildTextField(
                  _t('Contact 2 Name', 'رابطہ 2 کا نام'),
                  _relative2NameController,
                  Icons.security_outlined,
                  enabled: _isEditing,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                _buildTextField(
                  _t('Contact 2 Phone', 'رابطہ 2 کا فون'),
                  _relative2PhoneController,
                  Icons.contact_phone_outlined,
                  enabled: _isEditing,
                  surface: surface,
                  onSurface: onSurface,
                  onFaint: onFaint,
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_reset, color: Colors.redAccent),
                  label: Text(
                    _t('Change Password', 'پاس ورڈ تبدیل کریں'),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                Divider(color: dividerColor, height: 8),
                // Manage Permissions tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.security, color: Colors.blueAccent),
                  title: Text(
                    _t('Manage Permissions', 'اجازتیں منظم کریں'),
                    style: TextStyle(color: onSurface, fontSize: 14),
                  ),
                  subtitle: Text(
                    _t('Location, Camera, Bluetooth & more',
                        'مقام، کیمرہ، بلوٹوتھ اور مزید'),
                    style: TextStyle(color: onFaint, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right, color: onFaint),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                  ),
                ),
                Divider(color: dividerColor, height: 8),
                // Report Misuse tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
                  title: Text(
                    _t('Report App Misuse', 'ایپ کے غلط استعمال کی اطلاع'),
                    style: TextStyle(color: onSurface, fontSize: 14),
                  ),
                  subtitle: Text(
                    _t('Report fake alerts or inappropriate content',
                        'جھوٹے الرٹ یا نامناسب مواد کی اطلاع دیں'),
                    style: TextStyle(color: onFaint, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right, color: onFaint),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportMisuseScreen()),
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _updateProfile,
                      child: Text(
                        _t('Save Changes', 'تبدیلیاں محفوظ کریں'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerText(String text, {required Color color}) => Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    required Color surface,
    required Color onSurface,
    required Color onFaint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(color: enabled ? onSurface : onFaint),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: enabled ? Colors.redAccent : onFaint,
          ),
          labelText: label,
          labelStyle: TextStyle(color: onFaint),
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown({
    required bool enabled,
    required bool isDark,
    required Color surface,
    required Color onSurface,
  }) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBloodGroup,
              dropdownColor: surface,
              isExpanded: true,
              style: TextStyle(color: onSurface, fontSize: 16),
              items: _bloodGroups
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          '${_t('Blood Group', 'بلڈ گروپ')}: $g',
                        ),
                      ))
                  .toList(),
              onChanged: enabled ? (val) => setState(() => _selectedBloodGroup = val!) : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteerSwitch({
    required bool enabled,
    required Color onSurface,
  }) =>
      SwitchListTile(
        title: Text(
          _t('Volunteer Mode', 'رضاکارانہ موڈ'),
          style: TextStyle(color: onSurface),
        ),
        value: _isVolunteer,
        onChanged: enabled ? (v) => setState(() => _isVolunteer = v) : null,
        activeThumbColor: Colors.redAccent,
      );
}
