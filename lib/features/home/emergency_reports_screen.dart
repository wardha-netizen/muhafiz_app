import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class EmergencyReportsScreen extends StatefulWidget {
  const EmergencyReportsScreen({super.key});

  @override
  State<EmergencyReportsScreen> createState() => _EmergencyReportsScreenState();
}

class _EmergencyReportsScreenState extends State<EmergencyReportsScreen> {
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F7FB);
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _t('My Emergency Reports', 'میری ہنگامی رپورٹیں'),
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
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
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: isDark ? Colors.amber : Colors.blueGrey),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false)
                    .toggleTheme(!isDark),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergencies')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(_t('Something went wrong', 'کچھ غلط ہو گیا'),
                  style: TextStyle(color: onSurface)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent));
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(_t('No reports found.', 'کوئی رپورٹ نہیں ملی۔'),
                  style: TextStyle(color: onSurface)),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final report =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final DateTime? date =
                  (report['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                color: surface,
                child: ListTile(
                  leading: report['imageUrl'] != null
                      ? Image.network(
                          report['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.report_problem,
                          color: Colors.redAccent),
                  title: Text(
                    "${report['type']} - ${report['status']}",
                    style: TextStyle(color: onSurface),
                  ),
                  subtitle: Text(
                    date != null
                        ? DateFormat('jm').format(date)
                        : _t('Recent', 'حالیہ'),
                    style: TextStyle(color: onMuted),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: onMuted),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
