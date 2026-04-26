import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Primary Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Emergency Contact 1
  final TextEditingController _c1Name = TextEditingController();
  final TextEditingController _c1Phone = TextEditingController();
  String _c1Relation = 'Parent';

  // Emergency Contact 2
  final TextEditingController _c2Name = TextEditingController();
  final TextEditingController _c2Phone = TextEditingController();
  String _c2Relation = 'Sibling';

  String _selectedBloodGroup = 'O+';
  bool _isVolunteer = false;
  bool _isLoading = false;

  // ── Validation helpers ─────────────────────────────────────────────────────

  static bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email.trim());

  // Accepts: +923001234567 | 923001234567 | 03001234567 | 021-XXXXXXXX (landlines)
  static bool _isValidPakistanPhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Mobile: +92/92/0 followed by 3X then 9 more digits
    if (RegExp(r'^(\+92|92|0)3[0-9]{9}$').hasMatch(cleaned)) return true;
    // Karachi landline: +9221 / 021 / 9221 followed by 7–8 digits
    if (RegExp(r'^(\+9221|9221|021)[0-9]{7,8}$').hasMatch(cleaned)) return true;
    return false;
  }

  String? _validateForm() {
    if (_nameController.text.trim().isEmpty) return 'Full name is required';
    if (!_isValidEmail(_emailController.text)) return 'Enter a valid email address';
    if (_passwordController.text.trim().length < 6) return 'Password must be at least 6 characters';
    if (_phoneController.text.trim().isNotEmpty &&
        !_isValidPakistanPhone(_phoneController.text)) {
      return 'Enter a valid Pakistan number (+923XXXXXXXXX or 03XXXXXXXXX)';
    }
    if (_c1Name.text.trim().isEmpty || _c1Phone.text.trim().isEmpty) {
      return 'Emergency contact 1 name and phone are required';
    }
    if (!_isValidPakistanPhone(_c1Phone.text)) {
      return 'Contact 1: Enter valid +92 Pakistan mobile number';
    }
    if (_c2Name.text.trim().isEmpty || _c2Phone.text.trim().isEmpty) {
      return 'Emergency contact 2 name and phone are required';
    }
    if (!_isValidPakistanPhone(_c2Phone.text)) {
      return 'Contact 2: Enter valid +92 Pakistan mobile number';
    }
    return null;
  }

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];
  final List<String> _relations = [
    'Parent',
    'Sibling',
    'Spouse',
    'Relative',
    'Friend',
  ];

  Future<void> _signUp() async {
    final validationError = _validateForm();
    if (validationError != null) {
      _showSnackBar(validationError, Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create User in Firebase Auth
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = userCredential.user!.uid;

      // 2. Save EVERYTHING to Firestore (This links to your Profile Screen)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'isVolunteer': _isVolunteer,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        // Mapping your contacts for the SOS feature
        'relative_name': _c1Name.text.trim(),
        'relative_phone': _c1Phone.text.trim(),
        'contacts': [
          {
            'name': _c1Name.text.trim(),
            'phone': _c1Phone.text.trim(),
            'relation': _c1Relation,
          },
          {
            'name': _c2Name.text.trim(),
            'phone': _c2Phone.text.trim(),
            'relation': _c2Relation,
          },
        ],
      });

      // 3. Save to SharedPreferences (for offline SMS usage)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('contact1', _c1Phone.text.trim());
      await prefs.setString('contact2', _c2Phone.text.trim());
      await prefs.setString('name1', _nameController.text.trim());
      await prefs.setString('contactName1', _c1Name.text.trim());
      await prefs.setString('contactName2', _c2Name.text.trim());

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.permissions,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Authentication failed', Colors.red);
    } catch (e) {
      _showSnackBar('Database error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Create Medical ID',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Fill in details for emergency responders.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('PERSONAL DETAILS'),
                    _buildTextField(
                      _nameController,
                      'Full Name',
                      Icons.person_outline,
                    ),
                    _buildTextField(
                      _phoneController,
                      'Phone (+923XXXXXXXXX or 03XXXXXXXXX)',
                      Icons.phone,
                      inputType: TextInputType.phone,
                    ),
                    _buildTextField(
                      _emailController,
                      'Email Address',
                      Icons.email_outlined,
                    ),
                    _buildTextField(
                      _passwordController,
                      'Password',
                      Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('MEDICAL INFO'),
                    _buildBloodGroupSelector(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('EMERGENCY CONTACT 1 (Primary)'),
                    _buildContactBox(
                      _c1Name,
                      _c1Phone,
                      _c1Relation,
                      (val) => setState(() => _c1Relation = val!),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('EMERGENCY CONTACT 2'),
                    _buildContactBox(
                      _c2Name,
                      _c2Phone,
                      _c2Relation,
                      (val) => setState(() => _c2Relation = val!),
                    ),
                    const SizedBox(height: 24),
                    _buildVolunteerSwitch(),
                    const SizedBox(height: 40),
                    _buildSignUpButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: inputType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );

  Widget _buildBloodGroupSelector() => Container(
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
                .map(
                  (g) => DropdownMenuItem(
                      value: g, child: Text('Blood Group: $g')),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedBloodGroup = val!),
          ),
        ),
      );

  Widget _buildContactBox(
    TextEditingController name,
    TextEditingController phone,
    String relation,
    Function(String?) onRelChanged,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            _buildTextField(name, 'Contact Name', Icons.badge_outlined),
            _buildTextField(
              phone,
              'Contact Phone (+92 or 03XXXXXXXXX)',
              Icons.phone_callback,
              inputType: TextInputType.phone,
            ),
            DropdownButton<String>(
              value: relation,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              items: _relations
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: onRelChanged,
            ),
          ],
        ),
      );

  Widget _buildVolunteerSwitch() => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Volunteer for MUHAFIZ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        value: _isVolunteer,
        activeThumbColor: const Color(0xFFFF5252),
        onChanged: (val) => setState(() => _isVolunteer = val),
      );

  Widget _buildSignUpButton() => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'CREATE MEDICAL ID',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
}
