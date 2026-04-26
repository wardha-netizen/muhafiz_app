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
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      contact1 = prefs.getString('contact1');
      contact2 = prefs.getString('contact2');
      name1 = prefs.getString('contactName1');
      name2 = prefs.getString('contactName2');
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
          _t('Verified Contacts', 'تصدیق شدہ روابط'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isUrdu = !_isUrdu),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(_isUrdu ? 'EN' : 'اردو',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: isDark ? Colors.amber : Colors.blueGrey),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false).toggleTheme(!isDark),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: _loadSavedContacts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      'The following contacts will be notified in an emergency:',
                      'ہنگامی صورت میں درج ذیل روابط کو مطلع کیا جائے گا:',
                    ),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 25),
                  _contactTile(
                    name1 ?? _t('Primary Name Not Set', 'بنیادی نام نہیں ہے'),
                    contact1 ?? _t('No Number Saved', 'نمبر محفوظ نہیں'),
                    isDark,
                    Icons.person,
                  ),
                  const SizedBox(height: 10),
                  _contactTile(
                    name2 ?? _t('Secondary Name Not Set', 'ثانوی نام نہیں ہے'),
                    contact2 ?? _t('No Number Saved', 'نمبر محفوظ نہیں'),
                    isDark,
                    Icons.person_outline,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _t(
                              'Ensure these numbers are correct. They will receive your location during SOS alerts.',
                              'یقینی بنائیں کہ یہ نمبر درست ہیں۔ SOS الرٹ کے دوران انہیں آپ کا مقام ملے گا۔',
                            ),
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                        if (contact1 == null && contact2 == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_t(
                                'Please set at least one contact in Signup!',
                                'براہ کرم سائن اپ میں کم از کم ایک رابطہ شامل کریں!',
                              )),
                            ),
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      child: Text(
                        _t('PROCEED TO HOME', 'ہوم پر جائیں'),
                        style: const TextStyle(
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
    final notSet = name.contains('Not Set') || name.contains('نہیں');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50]!,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        subtitle: Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: Icon(
          Icons.verified,
          color: notSet ? Colors.grey : Colors.green,
          size: 20,
        ),
      ),
    );
  }
}
