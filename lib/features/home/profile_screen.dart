import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_routes.dart';

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

  // State Variables
  String _selectedBloodGroup = 'O+';
  bool _isVolunteer = false;
  bool _isEditing = false;
  bool _loaded = false;
  File? _imageFile;
  String? _profileImageUrl;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relativeNameController.dispose();
    _relativePhoneController.dispose();
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
    _loaded = true;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      // TODO: Upload _imageFile to Firebase Storage and update 'profile_pic' in Firestore
    }
  }

  Future<void> _changePassword() async {
    if (user?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Navigate to login and clear all previous routes
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'isVolunteer': _isVolunteer,
        'contacts': [
          {
            'name': _relativeNameController.text.trim(),
            'phone': _relativePhoneController.text.trim(),
            'relation': 'Guardian',
          },
        ],
      });
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Safety Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.redAccent),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('Profile not found.', style: TextStyle(color: Colors.white)),
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          _loadData(userData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Picture Section
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[900],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null),
                      child: (_imageFile == null && _profileImageUrl == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.white24)
                          : null,
                    ),
                    if (_isEditing)
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
                _buildTextField('Full Name', _nameController, Icons.person_outline, enabled: _isEditing),
                _buildTextField('My Phone', _phoneController, Icons.phone_android, enabled: _isEditing),
                _buildTextField('Email', _emailController, Icons.email_outlined, enabled: false),
                const Divider(color: Colors.white10, height: 40),
                _buildBloodGroupDropdown(enabled: _isEditing),
                _buildVolunteerSwitch(enabled: _isEditing),
                const SizedBox(height: 20),
                _headerText('Guardian Details'),
                _buildTextField('Guardian Name', _relativeNameController, Icons.security, enabled: _isEditing),
                _buildTextField('Guardian Phone', _relativePhoneController, Icons.contact_phone, enabled: _isEditing),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_reset, color: Colors.redAccent),
                  label: const Text('Change Password', style: TextStyle(color: Colors.redAccent)),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: _updateProfile,
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerText(String text) => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(color: enabled ? Colors.white : Colors.white38),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: enabled ? Colors.redAccent : Colors.white24),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown({required bool enabled}) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBloodGroup,
              dropdownColor: const Color(0xFF1E1E1E),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: _bloodGroups
                  .map((g) => DropdownMenuItem(value: g, child: Text('Blood Group: $g')))
                  .toList(),
              onChanged: enabled ? (val) => setState(() => _selectedBloodGroup = val!) : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteerSwitch({required bool enabled}) => SwitchListTile(
    title: const Text('Volunteer Mode', style: TextStyle(color: Colors.white)),
    value: _isVolunteer,
    onChanged: enabled ? (v) => setState(() => _isVolunteer = v) : null,
    activeThumbColor: Colors.redAccent,
  );
}
