import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_provider.dart';

// ── Data model ─────────────────────────────────────────────────────────────

class _EmergencyCategory {
  final String id;
  final String name;
  final String nameUrdu;
  final IconData icon;
  final Color color;
  final List<String> steps;
  final List<String> stepsUrdu;
  final List<String> doList;
  final List<String> doListUrdu;
  final List<String> dontList;
  final List<String> dontListUrdu;
  final List<_Contact> contacts;
  final String smsTemplate;

  const _EmergencyCategory({
    required this.id,
    required this.name,
    required this.nameUrdu,
    required this.icon,
    required this.color,
    required this.steps,
    required this.stepsUrdu,
    required this.doList,
    required this.doListUrdu,
    required this.dontList,
    required this.dontListUrdu,
    required this.contacts,
    required this.smsTemplate,
  });
}

class _Contact {
  final String name;
  final String number;
  const _Contact(this.name, this.number);
}

// ── Data ───────────────────────────────────────────────────────────────────

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
    stepsUrdu: [
      '١. فوری آواز لگائیں اور سب کو خبردار کریں۔',
      '٢. فائر بریگیڈ کو کال کریں: 16 یا 021-32262030۔',
      '٣. قریبی فائر الارم چالو کریں۔',
      '٤. صرف سیڑھیاں استعمال کریں — لفٹ ہرگز نہیں۔',
      '٥. آگ کو پھیلنے سے روکنے کے لیے دروازے بند کریں۔',
      '٦. کپڑا گیلا کر کے ناک و منہ ڈھانپیں۔',
      '٧. دھوئیں میں نیچے جھک کر چلیں — فرش کے قریب صاف ہوا ہے۔',
      '٨. اگر دروازہ گرم ہو تو مت کھولیں — دوسرا راستہ تلاش کریں۔',
      '٩. پھنسے ہوں تو: دروازے کے شگاف بند کریں، کھڑکی سے اشارہ دیں۔',
      '١٠. عمارت سے باہر مقررہ جگہ پر جمع ہوں۔',
      '١١. کپڑوں میں آگ لگے تو: رکیں — گریں — لڑھکیں۔',
      '١٢. کسی وجہ سے بھی عمارت میں واپس نہ جائیں۔',
    ],
    doList: [
      'Stay low under smoke',
      'Close doors to slow spread',
      'Use fire extinguisher only if safe (PASS: Pull, Aim, Squeeze, Sweep)',
      'Help elderly and disabled evacuate first',
      'Call 16 from outside the building',
    ],
    doListUrdu: [
      'دھوئیں میں نیچے رہیں',
      'آگ روکنے کے لیے دروازے بند کریں',
      'صرف اگر محفوظ ہو تو آگ بجھانے والا استعمال کریں',
      'بزرگوں اور معذور افراد کو پہلے نکالیں',
      'عمارت سے باہر سے 16 پر کال کریں',
    ],
    dontList: [
      'Never use elevators',
      'Do not stop to collect belongings',
      'Do not open hot doors',
      'Do not re-enter burning building',
      'Do not hide inside (bathroom, closet)',
    ],
    dontListUrdu: [
      'لفٹ ہرگز استعمال نہ کریں',
      'سامان اٹھانے کے لیے نہ رکیں',
      'گرم دروازہ نہ کھولیں',
      'جلتی عمارت میں واپس نہ جائیں',
      'باتھ روم یا الماری میں نہ چھپیں',
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
    stepsUrdu: [
      '١. فوری اوپری منزل یا اونچی جگہ چلے جائیں۔',
      '٢. CDGK کو کال کریں: 1339 یا NDMA: 0800-26362۔',
      '٣. مرکزی سوئچ سے تمام بجلی کے آلات بند کریں۔',
      '٤. سیلابی پانی میں نہ چلیں — کھلے مین ہول اور برقی تار خطرناک ہیں۔',
      '٥. پانی بھری سڑک پر گاڑی نہ چلائیں — انجن بند ہو سکتا ہے۔',
      '٦. ضروری دستاویزات، دوائیں، قیمتی اشیاء اوپری منزل پر منتقل کریں۔',
      '٧. پڑوسیوں کو خبردار کریں — دروازے کھٹکھٹائیں۔',
      '٨. چھت پر پھنسے ہوں تو روشن کپڑے یا ٹارچ سے اشارہ دیں۔',
      '٩. بجلی کے کھمبوں یا ٹرانسفارمر کے قریب پانی کو نہ چھوئیں۔',
      '١٠. انٹرنیٹ دستیاب ہو تو PDMA/PMD کی اپڈیٹس دیکھیں۔',
      '١١. انخلاء مراکز: کراچی ریس کورس، باغ ابن قاسم، مقامی اسکول/مساجد۔',
      '١٢. ہنگامی تھیلا تیار رکھیں: دستاویزات، نقد، ٹارچ، دوائیں، پانی۔',
    ],
    doList: [
      'Move to high ground immediately',
      'Turn off electricity at main breaker',
      'Keep emergency bag packed',
      'Signal rescuers from rooftop if trapped',
      'Boil or purify all water for drinking after flood',
    ],
    doListUrdu: [
      'فوری اونچی جگہ جائیں',
      'مرکزی بریکر سے بجلی بند کریں',
      'ہنگامی تھیلا تیار رکھیں',
      'چھت سے بچاؤ کارکنوں کو اشارہ دیں',
      'سیلاب کے بعد پانی ابال کر یا صاف کر کے پیئیں',
    ],
    dontList: [
      'Never walk in floodwater (manholes, electricity, disease)',
      'Do not drive through flooded roads',
      'Do not touch electrical equipment near water',
      'Do not re-enter flood-damaged building (structural damage)',
      'Do not drink tap water after flooding (contamination)',
    ],
    dontListUrdu: [
      'سیلابی پانی میں ہرگز نہ چلیں (مین ہول، بجلی، بیماری)',
      'پانی بھری سڑک پر گاڑی نہ چلائیں',
      'پانی کے قریب بجلی کے آلات کو نہ چھوئیں',
      'سیلاب سے متاثرہ عمارت میں واپس نہ جائیں',
      'سیلاب کے بعد نل کا پانی نہ پیئیں',
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
    stepsUrdu: [
      '١. فوری گھٹنوں کے بل گر جائیں۔',
      '٢. مضبوط میز، ڈیسک کے نیچے یا اندرونی دیوار کے ساتھ چھپیں۔',
      '٣. جھٹکے مکمل بند ہونے تک پکڑے رہیں۔',
      '٤. کھڑکیوں، بیرونی دیواروں اور بھاری اشیاء سے دور رہیں۔',
      '٥. جھٹکوں کے دوران باہر نہ بھاگیں — زیادہ تر چوٹیں گرتی اشیاء سے لگتی ہیں۔',
      '٦. باہر ہوں تو عمارتوں، درختوں اور بجلی کے تاروں سے دور جائیں۔',
      '٧. گاڑی میں ہوں تو پل سے دور کنارے پر روکیں اور اندر رہیں۔',
      '٨. جھٹکے بند ہوں تو اپنے آپ اور دوسروں کو چوٹوں کے لیے چیک کریں۔',
      '٩. گیس کا رساؤ، آگ اور ساختی نقصان چیک کریں۔',
      '١٠. گیس محسوس ہو تو کھڑکیاں کھولیں، عمارت چھوڑیں، سوئچ استعمال نہ کریں۔',
      '١١. آفٹر شاکس آ سکتے ہیں — خراب عمارتوں سے دور رہیں۔',
      '١٢. لفٹ استعمال نہ کریں۔ نقصان چیک کرنے کے بعد سیڑھیاں استعمال کریں۔',
    ],
    doList: [
      'DROP, COVER, HOLD ON',
      'Protect your head and neck',
      'Check for gas leaks after shaking',
      'Use text messages (saves network bandwidth)',
      'Follow official instructions from NDMA',
    ],
    doListUrdu: [
      'گریں، چھپیں، پکڑیں',
      'اپنے سر اور گردن کی حفاظت کریں',
      'جھٹکوں کے بعد گیس کا رساؤ چیک کریں',
      'ٹیکسٹ میسج استعمال کریں (نیٹ ورک بچائیں)',
      'NDMA کی ہدایات پر عمل کریں',
    ],
    dontList: [
      'Do not run outside during shaking',
      'Do not stand in doorways (not the safest place)',
      'Do not use elevators',
      'Do not light matches/candles until gas leak is ruled out',
      'Do not enter severely damaged buildings',
    ],
    dontListUrdu: [
      'جھٹکوں کے دوران باہر نہ بھاگیں',
      'دروازے میں کھڑے نہ ہوں (محفوظ جگہ نہیں)',
      'لفٹ استعمال نہ کریں',
      'گیس رساؤ مسترد ہونے تک ماچس/موم بتی نہ جلائیں',
      'بری طرح خراب عمارتوں میں نہ جائیں',
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
    stepsUrdu: [
      '١. فوری 115 (ایدھی) یا 1102 (امان) پر ایمبولینس کے لیے کال کریں۔',
      '٢. چیک کریں: کیا شخص ہوش میں ہے؟ کیا سانس لے رہا ہے؟',
      '٣. سانس نہ ہو تو CPR شروع کریں — 30 سینے کے دباؤ، 2 سانس۔',
      '   — سینے کے بیچ میں تیز اور زور سے دبائیں (100-120/منٹ)۔',
      '٤. شدید خون بہنا: صاف کپڑے سے براہ راست دباؤ ڈالیں۔ مت ہٹائیں۔',
      '٥. فالج کی علامات — FAST: منہ ٹیڑھا، بازو کمزور، بولنے میں دشواری، وقت = 115۔',
      '٦. جلنا: 20 منٹ بہتے پانی میں ٹھنڈا کریں۔ برف نہیں۔ مکھن/تیل نہیں۔',
      '٧. گلے میں پھنسنا (بالغ): کندھوں کے بیچ 5 دھکے + 5 پیٹ کے دھکے۔',
      '٨. بے ہوش لیکن سانس لے رہا ہو: بازیابی پوزیشن (پہلو پر، سانس کا راستہ صاف)۔',
      '٩. زہر: 115 کو کال کریں۔ ڈاکٹر کی ہدایت کے بغیر قے نہ کروائیں۔',
      '١٠. الرجی: اگر دستیاب ہو تو ایپی نیفرین استعمال کریں۔ فوری 115 کال کریں۔',
      '١١. دل کا دورہ: آرام کریں، کپڑے ڈھیلے کریں، اسپرین چبائیں (اگر الرجی نہ ہو)۔',
      '١٢. ایمبولینس آنے تک شخص کو گرم اور پرسکون رکھیں۔',
    ],
    doList: [
      'Call 115 (Edhi) or 1102 (Aman) first',
      'Keep patient calm and still',
      'Perform CPR if not breathing',
      'Keep airway clear',
      'Send someone to meet ambulance at road',
    ],
    doListUrdu: [
      'پہلے 115 یا 1102 کال کریں',
      'مریض کو پرسکون اور ساکن رکھیں',
      'سانس نہ ہو تو CPR کریں',
      'سانس کا راستہ صاف رکھیں',
      'کسی کو سڑک پر ایمبولینس لینے بھیجیں',
    ],
    dontList: [
      'Do not move a person with possible spinal injury',
      'Do not give food or water to unconscious person',
      'Do not remove object from deep wound',
      'Do not leave an unconscious person alone',
      'Do not apply tourniquet unless trained',
    ],
    dontListUrdu: [
      'ممکنہ ریڑھ کی ہڈی کی چوٹ والے کو مت ہلائیں',
      'بے ہوش شخص کو کھانا یا پانی نہ دیں',
      'گہرے زخم سے چیز نہ نکالیں',
      'بے ہوش شخص کو اکیلا نہ چھوڑیں',
      'تربیت کے بغیر ٹورنیکیٹ نہ لگائیں',
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
    stepsUrdu: [
      '١. آپ کی جان کسی بھی چیز سے زیادہ قیمتی ہے — مسلح ڈاکوؤں کا ساتھ دیں۔',
      '٢. پرسکون رہیں۔ اچانک حرکت نہ کریں اور حملہ آور کو نہ بھڑکائیں۔',
      '٣. تھوڑی دیر آنکھ ملائیں پھر نظر جھکا لیں۔',
      '٤. محفوظ ہوں تو پولیس کو کال کریں: 15 یا رینجرز: 1101۔',
      '٥. یاد رکھیں: قد، لباس، چہرہ، گاڑی کا نمبر پلیٹ۔',
      '٦. جرم کی جگہ کو نہ ہلائیں — ثبوت محفوظ رکھیں۔',
      '٧. گھر میں زبردستی گھسنا: کمرے کا دروازہ بند کریں، خاموشی سے 15 کال کریں۔',
      '٨. پیچھا کیا جائے تو کسی ہجوم والی جگہ (مسجد، پٹرول پمپ، دکان) جائیں۔',
      '٩. چھیننا: پیچھا نہ کریں — گاڑی/بائک نوٹ کریں اور 15 کال کریں۔',
      '١٠. اغوا (گواہ): سفر کی سمت، گاڑی اور وقت نوٹ کریں۔',
      '١١. دہشت گردانہ سرگرمی: 1717 (انسداد دہشت گردی) کال کریں۔',
      '١٢. قریبی پولیس اسٹیشن میں FIR درج کروائیں۔',
    ],
    doList: [
      'Comply with armed attackers — safety first',
      'Stay calm and observe details',
      'Call 15 when safe',
      'File FIR at police station',
      'Note registration plate of getaway vehicle',
    ],
    doListUrdu: [
      'مسلح حملہ آوروں کا ساتھ دیں — حفاظت پہلے',
      'پرسکون رہیں اور تفصیلات یاد رکھیں',
      'محفوظ ہو کر 15 کال کریں',
      'پولیس اسٹیشن میں FIR درج کروائیں',
      'فرار ہونے والی گاڑی کا نمبر نوٹ کریں',
    ],
    dontList: [
      'Do not resist armed robbery',
      'Do not chase snatchers on a bike',
      'Do not disturb crime scene',
      'Do not share crime details publicly before police report',
      'Do not confront criminals alone',
    ],
    dontListUrdu: [
      'مسلح ڈکیتی کی مزاحمت نہ کریں',
      'بائک پر چھیننے والوں کا پیچھا نہ کریں',
      'جرم کی جگہ کو نہ ہلائیں',
      'پولیس رپورٹ سے پہلے تفصیلات عوامی طور پر نہ بتائیں',
      'اکیلے مجرموں کا سامنا نہ کریں',
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
    stepsUrdu: [
      '١. کوئی بھی بجلی کا سوئچ آن یا آف نہ کریں — چنگاری گیس جلا سکتی ہے۔',
      '٢. تمام شعلے فوری بجھائیں: چولہا، موم بتیاں، سگریٹ۔',
      '٣. تمام کھڑکیاں اور دروازے کھول دیں۔',
      '٤. فوری عمارت چھوڑیں — سب کو ساتھ لے جائیں۔',
      '٥. SSGC کو کال کریں (باہر سے): 0800-00786 یا 021-111-786-786۔',
      '٦. دوسروں کو فوری خطرہ ہو تو پولیس: 15 کال کریں۔',
      '٧. پڑوسیوں کو خبردار کریں — نکلتے وقت دروازے کھٹکھٹائیں۔',
      '٨. عمارت کے اندر موبائل، لفٹ یا گھنٹی استعمال نہ کریں۔',
      '٩. گیس کا مین والو بند کریں (اگر جگہ معلوم ہو اور محفوظ ہو)۔',
      '١٠. SSGC ٹیکنیشن کی اجازت ملنے تک واپس نہ جائیں۔',
      '١١. دھماکہ ہو تو: عمارت میں آگ + زخمی (16 + 115 کال کریں)۔',
      '١٢. گاڑیاں عمارت سے دور لے جائیں (LPG زمین کی سطح پر جمع ہو سکتی ہے)۔',
    ],
    doList: [
      'Leave building immediately',
      'Open windows as you leave',
      'Call SSGC from outside: 0800-00786',
      'Warn all occupants',
      'Stay upwind from the building',
    ],
    doListUrdu: [
      'فوری عمارت چھوڑیں',
      'نکلتے وقت کھڑکیاں کھولیں',
      'باہر سے SSGC کو کال کریں: 0800-00786',
      'تمام مکینوں کو خبردار کریں',
      'عمارت سے ہوا کی سمت میں رہیں',
    ],
    dontList: [
      'Never switch electrical appliances on or off',
      'Do not use mobile phone inside',
      'Do not use elevator',
      'Do not light anything (matches, lighter)',
      'Do not re-enter until cleared by SSGC',
    ],
    dontListUrdu: [
      'بجلی کے آلات آن یا آف ہرگز نہ کریں',
      'اندر موبائل استعمال نہ کریں',
      'لفٹ استعمال نہ کریں',
      'کچھ بھی نہ جلائیں (ماچس، لائٹر)',
      'SSGC کی اجازت تک واپس نہ جائیں',
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
    stepsUrdu: [
      '١. PMD کی اپڈیٹس یا ریڈیو الرٹس سنیں: 021-99251005۔',
      '٢. سمندر، ساحل، نالوں اور نشیبی علاقوں سے فوری دور جائیں۔',
      '٣. باہر کی تمام ڈھیلی اشیاء اندر لے آئیں یا محفوظ کریں۔',
      '٤. گھر کے اندر رہیں — کھڑکیوں اور شیشے کے دروازوں سے دور۔',
      '٥. بجلی کے آلات بند کریں۔ ٹارچ اور بیٹریاں تیار رکھیں۔',
      '٦. بالٹیاں اور برتنوں میں صاف پانی بھر لیں (سپلائی بند ہو سکتی ہے)۔',
      '٧. انخلاء کا حکم ہو تو: اسکول، مساجد، کثیر منزلہ عمارتیں پناہ گاہیں ہیں۔',
      '٨. انخلاء کی مدد کے لیے CDGK: 1339 یا NDMA: 0800-26362 کال کریں۔',
      '٩. طوفان کے دوران سیلاب آئے تو اوپری منزل پر جائیں۔',
      '١٠. طوفان کی آنکھ (خاموشی) کے دوران باہر نہ جائیں — دوبارہ شروع ہوگا۔',
      '١١. ہنگامی تھیلا: دستاویزات، دوائیں، نقد، خوراک، پانی (3 دن)۔',
      '١٢. طوفان کے بعد: گرے ہوئے تار، پانی بھری سڑکیں اور غیر مستحکم عمارتوں سے بچیں۔',
    ],
    doList: [
      'Monitor official PMD alerts',
      'Move away from coast and nullahs',
      'Stock emergency supplies (3 days)',
      'Know your nearest evacuation centre',
      'Evacuate when authorities order',
    ],
    doListUrdu: [
      'PMD کی سرکاری اپڈیٹس سنیں',
      'ساحل اور نالوں سے دور جائیں',
      'ہنگامی سامان ذخیرہ کریں (3 دن)',
      'قریب ترین انخلاء مرکز جانیں',
      'حکام کے حکم پر انخلاء کریں',
    ],
    dontList: [
      'Do not stay near coastline or beach',
      'Do not go outside during storm',
      'Do not assume eye of storm means it is over',
      'Do not drive through flooded roads',
      'Do not touch fallen power lines',
    ],
    dontListUrdu: [
      'ساحل کے قریب نہ رہیں',
      'طوفان کے دوران باہر نہ جائیں',
      'طوفان کی آنکھ کو ختم نہ سمجھیں',
      'پانی بھری سڑکوں پر گاڑی نہ چلائیں',
      'گرے ہوئے بجلی کے تاروں کو نہ چھوئیں',
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
    stepsUrdu: [
      '١. شخص کو فوری سایہ یا ٹھنڈی/ایئرکنڈیشنڈ جگہ پر لے جائیں۔',
      '٢. 115 یا 1102 کال کریں — ہیٹ اسٹروک جان لیوا ہے۔',
      '٣. بھاری یا تنگ کپڑے اتاریں۔',
      '٤. جسم کو تیزی سے ٹھنڈا کریں: گردن، بغل، کمر، پیشانی پر گیلا کپڑا۔',
      '٥. پانی لگاتے ہوئے پنکھا چلائیں تاکہ بخارات سے ٹھنڈک آئے۔',
      '٦. ہوش میں ہو تو آہستہ ٹھنڈا پانی یا ORS پلائیں۔',
      '٧. بے ہوش یا الجھے ہوئے شخص کو مائع نہ دیں (دم گھٹنے کا خطرہ)۔',
      '٨. ہیٹ اسٹروک = خشک جلد، پسینہ نہیں، الجھن/بے ہوشی = خطرناک۔',
      '٩. ہیٹ ایگزاسٹن = زیادہ پسینہ، کمزوری، چکر = ٹھنڈا کریں + پانی پلائیں۔',
      '١٠. بے ہوش لیکن سانس لے رہا ہو تو بازیابی پوزیشن میں رکھیں۔',
      '١١. ہنگامی خدمات آنے یا درجہ حرارت 39°C سے نیچے آنے تک ٹھنڈا کرتے رہیں۔',
      '١٢. احتیاط: صبح 11 سے 4 بجے تک باہر نہ جائیں۔ گرمی میں ہر گھنٹے 1 لیٹر پانی پیئیں۔',
    ],
    doList: [
      'Move to cool place immediately',
      'Wet clothing and skin with cool water',
      'Fan the patient',
      'Give ORS if conscious',
      'Call 115 for heat stroke',
    ],
    doListUrdu: [
      'فوری ٹھنڈی جگہ پر لے جائیں',
      'کپڑوں اور جلد کو ٹھنڈے پانی سے تر کریں',
      'پنکھا چلائیں',
      'ہوش میں ہو تو ORS دیں',
      'ہیٹ اسٹروک کے لیے 115 کال کریں',
    ],
    dontList: [
      'Do not use ice-cold water (causes blood vessel constriction)',
      'Do not give fluids to unconscious person',
      'Do not leave person alone in hot car',
      'Do not give alcohol or caffeine',
      'Do not delay cooling — every minute matters',
    ],
    dontListUrdu: [
      'برف کا پانی نہ استعمال کریں (خون کی نالیاں سکڑ جاتی ہیں)',
      'بے ہوش شخص کو مائع نہ دیں',
      'گرم گاڑی میں اکیلا نہ چھوڑیں',
      'الکوحل یا کیفین نہ دیں',
      'ٹھنڈا کرنے میں دیر نہ کریں — ہر منٹ اہم ہے',
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
    stepsUrdu: [
      '١. کوئی زخمی ہو تو پہلے 115 کال کریں۔',
      '٢. حادثے کی رپورٹ اور ٹریفک کنٹرول کے لیے 15 کال کریں۔',
      '٣. ہیزرڈ لائٹس آن کریں اور وارننگ ٹرائی اینگل رکھیں۔',
      '٤. زخمیوں کو نہ ہلائیں — ریڑھ کی ہڈی کی چوٹ ہو سکتی ہے۔',
      '٥. زخمی کو گرم اور ساکن رکھیں۔ حوصلہ دیں۔',
      '٦. خون روکیں: صاف کپڑے سے مضبوطی سے دباؤ ڈالیں۔',
      '٧. سانس چیک کریں — نہ ہو تو CPR کریں۔',
      '٨. گاڑی میں آگ ہو اور شخص ہوش میں ہو تو جلدی نکالیں۔',
      '٩. خود اور دیکھنے والوں کو ٹریفک کے خطرے سے دور کریں۔',
      '١٠. تمام گاڑیوں کے رجسٹریشن نمبر نوٹ کریں۔',
      '١١. انشورنس/FIR کے لیے تصاویر لیں (صرف اگر محفوظ ہو)۔',
      '١٢. پولیس کے آنے تک جائے حادثہ نہ چھوڑیں۔',
    ],
    doList: [
      'Call 115 first for injuries',
      'Switch on hazard lights',
      'Keep injured person still',
      'Apply pressure to bleeding wounds',
      'Secure the scene from oncoming traffic',
    ],
    doListUrdu: [
      'زخموں کے لیے پہلے 115 کال کریں',
      'ہیزرڈ لائٹس آن کریں',
      'زخمی کو ساکن رکھیں',
      'خون بہنے والے زخموں پر دباؤ ڈالیں',
      'آتی ٹریفک سے جائے حادثہ محفوظ کریں',
    ],
    dontList: [
      'Do not move spinal injury victims unnecessarily',
      'Do not remove helmets (possible neck injury)',
      'Do not leave scene before police arrive',
      'Do not block emergency vehicle access',
      'Do not argue at scene — exchange details calmly',
    ],
    dontListUrdu: [
      'ریڑھ کی ہڈی کے زخمیوں کو بلاوجہ نہ ہلائیں',
      'ہیلمٹ نہ اتاریں (گردن کی چوٹ ہو سکتی ہے)',
      'پولیس کے آنے سے پہلے نہ جائیں',
      'ہنگامی گاڑی کا راستہ نہ روکیں',
      'جائے حادثہ پر بحث نہ کریں — پرسکونی سے تفصیلات لیں',
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
      "6. Search nearby familiar places: school, friend's home, mosque, park.",
      '7. Check local hospitals (call first): Jinnah 021-99201300, AKUH 021-111-911-911.',
      '8. Share recent photo with WhatsApp contacts and local area groups.',
      '9. Do NOT share address or personal details publicly — safety risk.',
      '10. Submit complaint on Pakistan Citizens Portal: 1907 or online.',
      '11. Keep mobile charged and line open for calls.',
      '12. Document everything: who you contacted, times, responses.',
    ],
    stepsUrdu: [
      '١. پولیس کو فوری کال کریں: 15 اور لاپتہ شخص کی اطلاع دیں۔',
      '٢. اسی دن قریبی پولیس اسٹیشن میں FIR درج کروائیں۔',
      '٣. ایدھی فاؤنڈیشن لاپتہ افراد: 021-111-369-786۔',
      '٤. بچہ لاپتہ ہو: 1099 (چائلڈ پروٹیکشن) کال کریں۔',
      '٥. پولیس کو دیں: حالیہ تصویر، عمر، قد، لباس، آخری بار دیکھنے کی جگہ۔',
      '٦. قریبی جانی پہچانی جگہوں پر تلاش کریں: اسکول، دوست کا گھر، مسجد، پارک۔',
      '٧. مقامی اسپتال چیک کریں (پہلے کال کریں): جناح 021-99201300، AKUH 021-111-911-911۔',
      '٨. واٹس ایپ گروپس میں حالیہ تصویر شیئر کریں۔',
      '٩. گھر کا پتہ یا ذاتی تفصیلات عوامی طور پر نہ بتائیں — حفاظتی خطرہ۔',
      '١٠. پاکستان سٹیزنز پورٹل پر شکایت درج کروائیں: 1907۔',
      '١١. موبائل چارج رکھیں اور لائن کالز کے لیے کھلی رکھیں۔',
      '١٢. سب کچھ دستاویز کریں: کس سے رابطہ کیا، وقت، جواب۔',
    ],
    doList: [
      'File FIR at police station same day',
      'Contact Edhi Foundation',
      'Share photo in local WhatsApp groups',
      'Check nearby hospitals',
      'Keep phone charged and available',
    ],
    doListUrdu: [
      'اسی دن پولیس اسٹیشن میں FIR درج کروائیں',
      'ایدھی فاؤنڈیشن سے رابطہ کریں',
      'مقامی واٹس ایپ گروپس میں تصویر شیئر کریں',
      'قریبی اسپتالوں کو چیک کریں',
      'فون چارج اور دستیاب رکھیں',
    ],
    dontList: [
      'Do not delay reporting — time is critical',
      'Do not share home address publicly',
      'Do not wait 24 hours to report (myth)',
      'Do not disturb possible crime scene',
      'Do not pay ransom without police advice (if kidnapping)',
    ],
    dontListUrdu: [
      'اطلاع دینے میں دیر نہ کریں — وقت انتہائی اہم ہے',
      'گھر کا پتہ عوامی طور پر نہ بتائیں',
      'اطلاع کے لیے 24 گھنٹے انتظار نہ کریں (غلط فہمی)',
      'ممکنہ جرم کی جگہ کو نہ ہلائیں',
      'پولیس کے مشورے کے بغیر تاوان نہ دیں',
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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
    final bg = _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F7FB);
    final onSurface = _isDark ? Colors.white : Colors.black87;
    final onMuted = _isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isUrdu ? 'آف لائن ہنگامی گائیڈ' : 'Offline Emergency Guide',
              style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              _isUrdu ? 'انٹرنیٹ کے بغیر کام کرتا ہے' : 'Works without internet',
              style: TextStyle(color: onMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Language toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _isUrdu = !_isUrdu),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isUrdu
                      ? Colors.green.withValues(alpha: 0.18)
                      : (_isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isUrdu
                        ? Colors.green.withValues(alpha: 0.6)
                        : (_isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
                child: Text(
                  _isUrdu ? 'EN' : 'اردو',
                  style: TextStyle(
                    color: _isUrdu ? Colors.green : onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => Provider.of<SettingsProvider>(context, listen: false)
                  .toggleTheme(!_isDark),
              icon: Icon(
                _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: onSurface,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOfflineBanner(onMuted: onMuted),
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
              itemBuilder: (context, i) =>
                  _buildCategoryCard(_karachiCategories[i], onSurface: onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner({required Color onMuted}) {
    final bg = _isDark ? const Color(0xFF1A2A1A) : const Color(0xFFE8F5E9);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.offline_bolt, color: Colors.green.shade600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isUrdu
                  ? 'یہ گائیڈ مکمل طور پر آف لائن کام کرتی ہے۔ انٹرنیٹ کی ضرورت نہیں۔'
                  : 'This guide works 100% offline. No internet needed.',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_EmergencyCategory cat,
      {required Color onSurface}) {
    final surface = _isDark ? const Color(0xFF1A1A1A) : Colors.white;
    return GestureDetector(
      onTap: () => _openGuide(cat),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cat.color.withValues(alpha: 0.5)),
          boxShadow: _isDark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
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
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isUrdu)
              Text(cat.name,
                  style: TextStyle(
                      color: _isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10)),
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
          isDark: _isDark,
        ),
      ),
    );
  }
}

// ── Detail screen ──────────────────────────────────────────────────────────

class _GuideDetailScreen extends StatefulWidget {
  final _EmergencyCategory category;
  final String contact1;
  final String contact2;
  final bool isUrdu;
  final bool isDark;

  const _GuideDetailScreen({
    required this.category,
    required this.contact1,
    required this.contact2,
    required this.isUrdu,
    required this.isDark,
  });

  @override
  State<_GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<_GuideDetailScreen> {
  late bool _isUrdu;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isUrdu = widget.isUrdu;
    _isDark = widget.isDark;
  }

  Color get _bg => _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F7FB);
  Color get _surface => _isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _onMuted => _isDark ? Colors.white70 : Colors.black54;
  Color get _divider => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendSOS(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final recipients = <String>[];
    if (widget.contact1.isNotEmpty) recipients.add(widget.contact1);
    if (widget.contact2.isNotEmpty) recipients.add(widget.contact2);

    if (recipients.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isUrdu
            ? 'کوئی ہنگامی رابطہ محفوظ نہیں۔ پروفائل میں رابطہ شامل کریں۔'
            : 'No emergency contacts saved. Add contacts in Profile.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      await sendSMS(
          message: widget.category.smsTemplate, recipients: recipients);
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isUrdu
            ? 'SMS ایپ نہیں کھل سکی۔ ہنگامی رابطوں کو براہ راست کال کریں۔'
            : 'Could not open SMS app. Call emergency contacts directly.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: cat.color,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(cat.icon, size: 20),
            const SizedBox(width: 8),
            Text(
              _isUrdu ? cat.nameUrdu : cat.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () => setState(() => _isUrdu = !_isUrdu),
            child: Text(
              _isUrdu ? 'EN' : 'اردو',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          // Theme toggle
          IconButton(
            icon: Icon(
              _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              Provider.of<SettingsProvider>(context, listen: false)
                  .toggleTheme(!_isDark);
              setState(() => _isDark = !_isDark);
            },
          ),
          // SOS SMS
          IconButton(
            icon: const Icon(Icons.sms),
            tooltip: 'SOS SMS',
            onPressed: () => _sendSOS(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: _isUrdu ? 'ہنگامی نمبر — ابھی کال کریں' : 'Emergency Numbers — Call Now',
            icon: Icons.phone_in_talk,
            color: Colors.green,
            child: Column(
              children: cat.contacts
                  .map((c) => _buildCallTile(c.name, c.number))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: _isUrdu ? 'مرحلہ وار ردعمل' : 'Step-by-Step Response',
            icon: Icons.format_list_numbered,
            color: cat.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (_isUrdu ? cat.stepsUrdu : cat.steps)
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          s,
                          style: TextStyle(
                              color: _onMuted, fontSize: 13, height: 1.5),
                          textDirection: _isUrdu
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: _isUrdu ? 'کیا کریں' : 'Do',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            child: Column(
              children: (_isUrdu ? cat.doListUrdu : cat.doList)
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(d,
                                  style: TextStyle(
                                      color: _onMuted, fontSize: 13),
                                  textDirection: _isUrdu
                                      ? TextDirection.rtl
                                      : TextDirection.ltr),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: _isUrdu ? 'کیا نہ کریں' : "Don't",
            icon: Icons.cancel_outlined,
            color: Colors.red,
            child: Column(
              children: (_isUrdu ? cat.dontListUrdu : cat.dontList)
                  .map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.close,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(d,
                                  style: TextStyle(
                                      color: _onMuted, fontSize: 13),
                                  textDirection: _isUrdu
                                      ? TextDirection.rtl
                                      : TextDirection.ltr),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.sms, color: Colors.white),
              label: Text(
                _isUrdu
                    ? 'ہنگامی رابطوں کو SOS بھیجیں'
                    : 'Send SOS to My Emergency Contacts',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
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
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: _isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
          Divider(height: 1, color: _divider),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCallTile(String name, String number) {
    final tileBg = _isDark ? const Color(0xFF0D2A0D) : const Color(0xFFE8F5E9);
    final tileBorder =
        _isDark ? Colors.green.shade800 : Colors.green.shade400;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _callNumber(number),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tileBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone, color: Colors.green, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                    style: TextStyle(color: _onMuted, fontSize: 13)),
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
