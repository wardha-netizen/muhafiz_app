import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Data model ─────────────────────────────────────────────────────────────

class _EmergencyCategory {
  final String id;
  final String name;
  final String nameUrdu;
  final IconData icon;
  final Color color;
  final List<String> steps;
  final List<String> doList;
  final List<String> dontList;
  final List<_Contact> contacts;
  final String smsTemplate;

  const _EmergencyCategory({
    required this.id,
    required this.name,
    required this.nameUrdu,
    required this.icon,
    required this.color,
    required this.steps,
    required this.doList,
    required this.dontList,
    required this.contacts,
    required this.smsTemplate,
  });
}

class _Contact {
  final String name;
  final String number;
  const _Contact(this.name, this.number);
}

// ── Karachi Emergency Numbers (hardcoded — works 100% offline) ─────────────

const _karachiCategories = [
  _EmergencyCategory(
    id: 'fire',
    name: 'Fire',
    nameUrdu: 'آگ',
    icon: Icons.local_fire_department,
    color: Color(0xFFE53935),
    steps: [
      '1. Shout FIRE! and alert everyone immediately.',
      '2. Call Karachi Fire Brigade: 16 or 021-32262030.',
      '3. Activate nearest fire alarm / pull station if available.',
      '4. Use stairs ONLY — never use elevators during fire.',
      '5. Close doors behind you to slow fire spread.',
      '6. Wet a cloth and cover your nose and mouth.',
      '7. Crawl low under smoke — clean air is near the floor.',
      '8. If door is hot, do NOT open — find another exit.',
      '9. If trapped: seal door gaps with clothing, signal from window.',
      '10. Assemble at designated meeting point outside building.',
      '11. If clothing catches fire: STOP — DROP — ROLL.',
      '12. Do NOT re-enter building for any reason.',
    ],
    doList: [
      'Stay low under smoke',
      'Close doors to slow spread',
      'Use fire extinguisher only if safe (PASS: Pull, Aim, Squeeze, Sweep)',
      'Help elderly and disabled evacuate first',
      'Call 16 from outside the building',
    ],
    dontList: [
      'Never use elevators',
      'Do not stop to collect belongings',
      'Do not open hot doors',
      'Do not re-enter burning building',
      'Do not hide inside (bathroom, closet)',
    ],
    contacts: [
      _Contact('Fire Brigade', '16'),
      _Contact('Edhi Ambulance', '115'),
      _Contact('Police', '15'),
      _Contact('Rescue', '1122'),
    ],
    smsTemplate: 'FIRE EMERGENCY at my location. Please send help immediately. Call 16.',
  ),
  _EmergencyCategory(
    id: 'flood',
    name: 'Flood',
    nameUrdu: 'سیلاب',
    icon: Icons.water,
    color: Color(0xFF1565C0),
    steps: [
      '1. Move IMMEDIATELY to upper floors or high ground.',
      '2. Call CDGK Emergency: 1339 or NDMA: 0800-26362.',
      '3. Disconnect all electrical appliances at the main switch.',
      '4. Do NOT walk through floodwater — open manholes + live wires.',
      '5. Do NOT drive through flooded roads — engines stall, cars sweep away.',
      '6. Move important documents, medicines, valuables to upper floor.',
      '7. Alert your neighbours — knock on doors.',
      '8. If trapped on roof: signal rescuers using bright cloth or flashlight.',
      '9. Avoid touching any water near electrical poles or transformers.',
      '10. Monitor PDMA/PMD updates (021-99251005) when internet available.',
      '11. Evacuation grounds: Karachi Race Course, Bagh Ibn Qasim, local schools/mosques.',
      '12. Keep emergency bag ready: documents, cash, torch, medicines, water.',
    ],
    doList: [
      'Move to high ground immediately',
      'Turn off electricity at main breaker',
      'Keep emergency bag packed',
      'Signal rescuers from rooftop if trapped',
      'Boil or purify all water for drinking after flood',
    ],
    dontList: [
      'Never walk in floodwater (manholes, electricity, disease)',
      'Do not drive through flooded roads',
      'Do not touch electrical equipment near water',
      'Do not re-enter flood-damaged building (structural damage)',
      'Do not drink tap water after flooding (contamination)',
    ],
    contacts: [
      _Contact('CDGK Emergency', '1339'),
      _Contact('Rescue 1122', '1122'),
      _Contact('NDMA Helpline', '0800-26362'),
      _Contact('Edhi Ambulance', '115'),
      _Contact('Police', '15'),
    ],
    smsTemplate: 'FLOOD EMERGENCY — I am trapped/in danger. Location: [ADD AREA]. Please send rescue. Call 1339.',
  ),
  _EmergencyCategory(
    id: 'earthquake',
    name: 'Earthquake',
    nameUrdu: 'زلزلہ',
    icon: Icons.show_chart,
    color: Color(0xFF6A1B9A),
    steps: [
      '1. DROP to hands and knees immediately.',
      '2. Take COVER under a sturdy desk, table, or against an interior wall.',
      '3. HOLD ON until all shaking completely stops.',
      '4. Stay away from windows, exterior walls, heavy objects.',
      '5. Do NOT run outside while shaking — most injuries from falling objects.',
      '6. If outdoors: move away from buildings, trees, and power lines.',
      '7. If in a vehicle: pull over away from bridges/overpasses. Stay inside.',
      '8. After shaking stops: check yourself and others for injuries.',
      '9. Check for gas leaks (smell), fires, and structural damage.',
      '10. If you smell gas: open windows, leave building, do NOT use switches.',
      '11. Expect aftershocks — stay away from damaged buildings.',
      '12. Do NOT use elevators. Use stairs only after checking for damage.',
    ],
    doList: [
      'DROP, COVER, HOLD ON',
      'Protect your head and neck',
      'Check for gas leaks after shaking',
      'Use text messages (saves network bandwidth)',
      'Follow official instructions from NDMA',
    ],
    dontList: [
      'Do not run outside during shaking',
      'Do not stand in doorways (not the safest place)',
      'Do not use elevators',
      'Do not light matches/candles until gas leak is ruled out',
      'Do not enter severely damaged buildings',
    ],
    contacts: [
      _Contact('NDMA Emergency', '0800-26362'),
      _Contact('Rescue 1122', '1122'),
      _Contact('Edhi Ambulance', '115'),
      _Contact('Police', '15'),
      _Contact('Aman Ambulance', '1102'),
    ],
    smsTemplate: 'EARTHQUAKE — I am safe/injured at [AREA]. Please send help. Call 1122.',
  ),
  _EmergencyCategory(
    id: 'medical',
    name: 'Medical',
    nameUrdu: 'طبی ہنگامی',
    icon: Icons.medical_services,
    color: Color(0xFFC62828),
    steps: [
      '1. Call 115 (Edhi) or 1102 (Aman) for ambulance IMMEDIATELY.',
      '2. Check: Is the person conscious? Are they breathing?',
      '3. If NOT breathing: Start CPR — 30 chest compressions, 2 rescue breaths.',
      '   — Compress hard and fast (100–120/min) in centre of chest.',
      '4. Severe bleeding: apply DIRECT PRESSURE with clean cloth. Do not remove.',
      '5. STROKE signs — FAST: Face drooping, Arm weak, Speech slurred, Time = call 115.',
      '6. Burns: Cool under running water for 20 min. No ice. No butter/oil.',
      '7. Choking (adult): 5 back blows between shoulder blades + 5 abdominal thrusts.',
      '8. Unconscious — breathing: Recovery position (on side, airway clear).',
      '9. Poisoning: Call 115. Do NOT induce vomiting unless told by doctor.',
      '10. Allergic reaction: Use epinephrine if available. Call 115 immediately.',
      '11. Heart attack: Rest, loosen clothing, chew aspirin (if available, not allergic).',
      '12. Keep person warm and calm until ambulance arrives.',
    ],
    doList: [
      'Call 115 (Edhi) or 1102 (Aman) first',
      'Keep patient calm and still',
      'Perform CPR if not breathing',
      'Keep airway clear',
      'Send someone to meet ambulance at road',
    ],
    dontList: [
      'Do not move a person with possible spinal injury',
      'Do not give food or water to unconscious person',
      'Do not remove object from deep wound',
      'Do not leave an unconscious person alone',
      'Do not apply tourniquet unless trained',
    ],
    contacts: [
      _Contact('Edhi Ambulance', '115'),
      _Contact('Aman Ambulance', '1102'),
      _Contact('AKUH Emergency', '021-111-911-911'),
      _Contact('Jinnah Hospital', '021-99201300'),
      _Contact('Civil Hospital', '021-99215740'),
      _Contact('Liaquat Hospital', '021-34412442'),
    ],
    smsTemplate: 'MEDICAL EMERGENCY at [AREA]. Person is [CONDITION]. Please send ambulance. Call 115.',
  ),
  _EmergencyCategory(
    id: 'crime',
    name: 'Crime / Robbery',
    nameUrdu: 'جرم / ڈکیتی',
    icon: Icons.local_police,
    color: Color(0xFF1B5E20),
    steps: [
      '1. Your life is more valuable than any possession — comply with armed robbers.',
      '2. Stay calm. Do not make sudden movements or provoke the attacker.',
      '3. Make eye contact briefly, then look down — not confrontational.',
      '4. When safe, call Police: 15 or Rangers: 1101.',
      '5. Note description: height, clothing, face features, vehicle number plate.',
      '6. Do NOT disturb the crime scene — preserve evidence.',
      '7. Home break-in while inside: lock bedroom door, call 15 quietly.',
      '8. If followed: go to a busy public place (mosque, petrol station, shop).',
      '9. Snatching: Do not chase — note vehicle/bike and call 15.',
      '10. Kidnapping (witness): Note direction of travel, vehicle, time.',
      '11. Anti-terrorism suspicious activity: Call 1717 (Anti-Terrorism).',
      '12. File FIR at nearest police station for insurance and legal records.',
    ],
    doList: [
      'Comply with armed attackers — safety first',
      'Stay calm and observe details',
      'Call 15 when safe',
      'File FIR at police station',
      'Note registration plate of getaway vehicle',
    ],
    dontList: [
      'Do not resist armed robbery',
      'Do not chase snatchers on a bike',
      'Do not disturb crime scene',
      'Do not share crime details publicly before police report',
      'Do not confront criminals alone',
    ],
    contacts: [
      _Contact('Police Emergency', '15'),
      _Contact('Rangers', '1101'),
      _Contact('Anti-Terrorism', '1717'),
      _Contact('Pakistan Citizens Portal', '1907'),
    ],
    smsTemplate: 'CRIME/ROBBERY at [AREA]. Please send police. Call 15.',
  ),
  _EmergencyCategory(
    id: 'gas',
    name: 'Gas Leak',
    nameUrdu: 'گیس کا اخراج',
    icon: Icons.gas_meter,
    color: Color(0xFFF57F17),
    steps: [
      '1. Do NOT turn ON or OFF any electrical switches — sparks ignite gas.',
      '2. Extinguish all flames: stove, candles, cigarettes — immediately.',
      '3. Open ALL windows and doors to ventilate.',
      '4. Leave the building IMMEDIATELY — take everyone with you.',
      '5. Call SSGC Emergency (outside building): 0800-00786 or 021-111-786-786.',
      '6. Call Police: 15 if immediate danger to others.',
      '7. Warn neighbours — knock on doors as you leave.',
      '8. Do NOT use mobile phone, elevator, or doorbell INSIDE the building.',
      '9. Turn off gas main valve at meter (if you know location and can do safely).',
      '10. Do NOT re-enter until SSGC technician gives clearance.',
      '11. If explosion occurs: treat as building fire + injury emergency (call 16 + 115).',
      '12. Move vehicles away from building (LPG can accumulate at ground level).',
    ],
    doList: [
      'Leave building immediately',
      'Open windows as you leave',
      'Call SSGC from outside: 0800-00786',
      'Warn all occupants',
      'Stay upwind from the building',
    ],
    dontList: [
      'Never switch electrical appliances on or off',
      'Do not use mobile phone inside',
      'Do not use elevator',
      'Do not light anything (matches, lighter)',
      'Do not re-enter until cleared by SSGC',
    ],
    contacts: [
      _Contact('SSGC Emergency', '0800-00786'),
      _Contact('SSGC Helpline', '021-111-786-786'),
      _Contact('Police', '15'),
      _Contact('Fire Brigade', '16'),
      _Contact('Edhi Ambulance', '115'),
    ],
    smsTemplate: 'GAS LEAK emergency at [AREA]. Building evacuated. SSGC and police needed urgently.',
  ),
  _EmergencyCategory(
    id: 'cyclone',
    name: 'Cyclone / Storm',
    nameUrdu: 'طوفان',
    icon: Icons.cyclone,
    color: Color(0xFF00838F),
    steps: [
      '1. Monitor PMD (Pakistan Met Dept): 021-99251005 or radio alerts.',
      '2. Move away from sea, coast, nullahs, and low-lying areas IMMEDIATELY.',
      '3. Secure or bring inside all loose outdoor objects.',
      '4. Stay indoors — away from windows and glass doors.',
      '5. Disconnect electrical appliances. Keep torch and batteries ready.',
      '6. Fill bathtubs and containers with clean water (supply may be cut).',
      '7. Evacuation if ordered: schools, mosques, multi-storey buildings are shelters.',
      '8. Call CDGK: 1339 or NDMA: 0800-26362 for evacuation assistance.',
      '9. If flooding starts during cyclone: move to upper floors.',
      '10. Do NOT go outside during the eye of cyclone — it will resume.',
      '11. Keep emergency bag: documents, medicines, cash, food, water (3 days).',
      '12. After cyclone: beware of fallen power lines, flooded roads, unstable structures.',
    ],
    doList: [
      'Monitor official PMD alerts',
      'Move away from coast and nullahs',
      'Stock emergency supplies (3 days)',
      'Know your nearest evacuation centre',
      'Evacuate when authorities order',
    ],
    dontList: [
      'Do not stay near coastline or beach',
      'Do not go outside during storm',
      'Do not assume eye of storm means it is over',
      'Do not drive through flooded roads',
      'Do not touch fallen power lines',
    ],
    contacts: [
      _Contact('PMD Weather', '021-99251005'),
      _Contact('CDGK Emergency', '1339'),
      _Contact('NDMA', '0800-26362'),
      _Contact('Rangers', '1101'),
      _Contact('Edhi Ambulance', '115'),
    ],
    smsTemplate: 'CYCLONE/STORM emergency. I need evacuation assistance at [AREA]. Call 1339.',
  ),
  _EmergencyCategory(
    id: 'heat',
    name: 'Heat Stroke',
    nameUrdu: 'ہیٹ اسٹروک',
    icon: Icons.thermostat,
    color: Color(0xFFE65100),
    steps: [
      '1. Move the person to shade or a cool / air-conditioned area immediately.',
      '2. Call 115 (Edhi) or 1102 (Aman) — heat stroke is life-threatening.',
      '3. Remove heavy or tight clothing.',
      '4. Cool the body FAST: wet cloth on neck, armpits, groin, forehead.',
      '5. Fan the person while applying water to speed evaporative cooling.',
      '6. If conscious: give cool water or ORS (oral rehydration salts) slowly.',
      '7. Do NOT give fluids to unconscious or confused person (choking risk).',
      '8. Heat stroke = DRY SKIN, no sweating, confused/unconscious = CRITICAL.',
      '9. Heat exhaustion = heavy sweating, weakness, dizziness = cool + hydrate.',
      '10. Place in recovery position (on side) if unconscious and breathing.',
      '11. Keep cooling until emergency services arrive or temperature drops below 39°C.',
      '12. Prevention: Avoid outdoor activity 11 AM–4 PM. Drink 1 litre/hour in heat.',
    ],
    doList: [
      'Move to cool place immediately',
      'Wet clothing and skin with cool water',
      'Fan the patient',
      'Give ORS if conscious',
      'Call 115 for heat stroke',
    ],
    dontList: [
      'Do not use ice-cold water (causes blood vessel constriction)',
      'Do not give fluids to unconscious person',
      'Do not leave person alone in hot car',
      'Do not give alcohol or caffeine',
      'Do not delay cooling — every minute matters',
    ],
    contacts: [
      _Contact('Edhi Ambulance', '115'),
      _Contact('Aman Ambulance', '1102'),
      _Contact('AKUH Emergency', '021-111-911-911'),
      _Contact('Rescue', '1122'),
    ],
    smsTemplate: 'HEAT STROKE emergency at [AREA]. Person is unconscious/confused. Please send ambulance 115.',
  ),
  _EmergencyCategory(
    id: 'accident',
    name: 'Road Accident',
    nameUrdu: 'ٹریفک حادثہ',
    icon: Icons.car_crash,
    color: Color(0xFF37474F),
    steps: [
      '1. Call 115 (ambulance) if anyone is injured — do it first.',
      '2. Call 15 (Police) for accident report and traffic management.',
      '3. Switch on hazard lights and place warning triangle if available.',
      '4. Do NOT move injured persons — possible spinal injury.',
      '5. Keep injured person warm and still. Reassure them.',
      '6. Control bleeding: apply firm direct pressure with a clean cloth.',
      '7. Check breathing — perform CPR if not breathing.',
      '8. If car is on fire and person is responsive: help them out quickly.',
      '9. Move yourself and bystanders away from traffic hazard.',
      '10. Note vehicle registration numbers of all vehicles involved.',
      '11. Take photos of the scene for insurance/FIR (only if safe).',
      '12. Do NOT leave the scene until police arrive.',
    ],
    doList: [
      'Call 115 first for injuries',
      'Switch on hazard lights',
      'Keep injured person still',
      'Apply pressure to bleeding wounds',
      'Secure the scene from oncoming traffic',
    ],
    dontList: [
      'Do not move spinal injury victims unnecessarily',
      'Do not remove helmets (possible neck injury)',
      'Do not leave scene before police arrive',
      'Do not block emergency vehicle access',
      'Do not argue at scene — exchange details calmly',
    ],
    contacts: [
      _Contact('Edhi Ambulance', '115'),
      _Contact('Police', '15'),
      _Contact('Aman Ambulance', '1102'),
      _Contact('Highway Emergency', '130'),
      _Contact('Rescue 1122', '1122'),
    ],
    smsTemplate: 'ROAD ACCIDENT at [AREA/ROAD NAME]. Injured persons. Please send ambulance and police.',
  ),
  _EmergencyCategory(
    id: 'missing',
    name: 'Missing Person',
    nameUrdu: 'لاپتہ شخص',
    icon: Icons.person_search,
    color: Color(0xFF4527A0),
    steps: [
      '1. Call Police: 15 and report missing person immediately.',
      '2. Visit nearest police station to file FIR — same day.',
      '3. Edhi Foundation Missing Persons: 021-111-369-786.',
      '4. Child missing: Call 1099 (Child Protection Bureau).',
      '5. Provide police: recent photo, age, height, clothing description, last seen location.',
      '6. Search nearby familiar places: school, friend\'s home, mosque, park.',
      '7. Check local hospitals (call first): Jinnah 021-99201300, AKUH 021-111-911-911.',
      '8. Share recent photo with WhatsApp contacts and local area groups.',
      '9. Do NOT share address or personal details publicly — safety risk.',
      '10. Submit complaint on Pakistan Citizens Portal: 1907 or online.',
      '11. Keep mobile charged and line open for calls.',
      '12. Document everything: who you contacted, times, responses.',
    ],
    doList: [
      'File FIR at police station same day',
      'Contact Edhi Foundation',
      'Share photo in local WhatsApp groups',
      'Check nearby hospitals',
      'Keep phone charged and available',
    ],
    dontList: [
      'Do not delay reporting — time is critical',
      'Do not share home address publicly',
      'Do not wait 24 hours to report (myth)',
      'Do not disturb possible crime scene',
      'Do not pay ransom without police advice (if kidnapping)',
    ],
    contacts: [
      _Contact('Police', '15'),
      _Contact('Edhi Foundation', '021-111-369-786'),
      _Contact('Child Protection', '1099'),
      _Contact('Pakistan Citizens Portal', '1907'),
      _Contact('Rangers', '1101'),
    ],
    smsTemplate: 'MISSING PERSON report filed for [NAME], last seen at [AREA/TIME]. Please help.',
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────

class OfflineGuideScreen extends StatefulWidget {
  const OfflineGuideScreen({super.key});

  @override
  State<OfflineGuideScreen> createState() => _OfflineGuideScreenState();
}

class _OfflineGuideScreenState extends State<OfflineGuideScreen> {
  String _contact1 = '';
  String _contact2 = '';
  bool _isUrdu = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contact1 = prefs.getString('contact1') ?? '';
      _contact2 = prefs.getString('contact2') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isUrdu ? 'آف لائن ہنگامی گائیڈ' : 'Offline Emergency Guide',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isUrdu = !_isUrdu),
            child: Text(
              _isUrdu ? 'EN' : 'اردو',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOfflineBanner(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _karachiCategories.length,
              itemBuilder: (context, i) => _buildCategoryCard(_karachiCategories[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.offline_bolt, color: Colors.green.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isUrdu
                  ? 'یہ گائیڈ مکمل طور پر آف لائن کام کرتی ہے۔ انٹرنیٹ کی ضرورت نہیں۔'
                  : 'This guide works 100% offline. No internet needed.',
              style: TextStyle(color: Colors.green.shade300, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_EmergencyCategory cat) {
    return GestureDetector(
      onTap: () => _openGuide(cat),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cat.color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(cat.icon, color: cat.color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              _isUrdu ? cat.nameUrdu : cat.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isUrdu)
              Text(cat.name, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _openGuide(_EmergencyCategory cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GuideDetailScreen(
          category: cat,
          contact1: _contact1,
          contact2: _contact2,
          isUrdu: _isUrdu,
        ),
      ),
    );
  }
}

// ── Detail screen ──────────────────────────────────────────────────────────

class _GuideDetailScreen extends StatelessWidget {
  final _EmergencyCategory category;
  final String contact1;
  final String contact2;
  final bool isUrdu;

  const _GuideDetailScreen({
    required this.category,
    required this.contact1,
    required this.contact2,
    required this.isUrdu,
  });

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendSOS(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final recipients = <String>[];
    if (contact1.isNotEmpty) recipients.add(contact1);
    if (contact2.isNotEmpty) recipients.add(contact2);

    if (recipients.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts saved. Add contacts in Profile.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await sendSMS(message: category.smsTemplate, recipients: recipients);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open SMS app. Call emergency contacts directly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: category.color,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(category.icon, size: 20),
            const SizedBox(width: 8),
            Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sms),
            tooltip: 'SOS SMS to contacts',
            onPressed: () => _sendSOS(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency contacts
          _buildSection(
            title: 'Emergency Numbers — Call Now',
            icon: Icons.phone_in_talk,
            color: Colors.green,
            child: Column(
              children: category.contacts
                  .map((c) => _buildCallTile(c.name, c.number))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Steps
          _buildSection(
            title: 'Step-by-Step Response',
            icon: Icons.format_list_numbered,
            color: category.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: category.steps
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        s,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Do's
          _buildSection(
            title: 'Do',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            child: Column(
              children: category.doList
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(d,
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Don'ts
          _buildSection(
            title: "Don't",
            icon: Icons.cancel_outlined,
            color: Colors.red,
            child: Column(
              children: category.dontList
                  .map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.close, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(d,
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // SOS SMS button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.sms, color: Colors.white),
              label: const Text(
                'Send SOS to My Emergency Contacts',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _sendSOS(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCallTile(String name, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _callNumber(number),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2A0D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade800),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone, color: Colors.green, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
              Text(
                number,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.call, color: Colors.green, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
