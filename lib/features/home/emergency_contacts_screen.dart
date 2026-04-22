import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  String? contact1, contact2, name1, name2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
  }

  // Fetches data saved from your Signup or Profile screens
  Future<void> _loadSavedContacts() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      // IMPORTANT: These keys must match the ones used in your _signUp() method
      contact1 = prefs.getString('contact1');
      contact2 = prefs.getString('contact2');
      name1 = prefs.getString('name1');
      name2 = prefs.getString('name2');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SettingsProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Verified Contacts',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: _loadSavedContacts, // Manual refresh if update is missed
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The following contacts will be notified in an emergency:',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 25),

                  // Contact 1
                  _contactTile(
                    name1 ?? 'Primary Name Not Set',
                    contact1 ?? 'No Number Saved',
                    isDark,
                    Icons.person,
                  ),

                  const SizedBox(height: 10),

                  // Contact 2
                  _contactTile(
                    name2 ?? 'Secondary Name Not Set',
                    contact2 ?? 'No Number Saved',
                    isDark,
                    Icons.person_outline,
                  ),

                  const Spacer(),

                  // Verification Note
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ensure these numbers are correct. They will receive your location during SOS alerts.',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        // Check if contacts exist before proceeding
                        if (contact1 == null && contact2 == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please set at least one contact in Signup!',
                              ),
                            ),
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      child: const Text(
                        'PROCEED TO HOME',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _contactTile(String name, String phone, bool isDark, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50]!,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
          child: Icon(icon, color: Colors.redAccent),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          phone,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Icon(
          Icons.verified,
          color: (name.contains('Not Set')) ? Colors.grey : Colors.green,
          size: 20,
        ),
      ),
    );
  }
}
