import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MindMendApp());
}

const String geminiApiKey = 'AIzaSyC8oKKYaZE6eG31qNSPDrZiUs2NvUHyTJA';
const String geminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=$geminiApiKey';

const List<String> crisisKeywords = [
  'suicide', 'kill myself', 'end my life', 'want to die',
  'can\'t take it anymore', 'no reason to live', 'disappear forever',
  'everyone would be better without me', 'i give up on life',
];

bool detectCrisis(String message) {
  final lower = message.toLowerCase();
  return crisisKeywords.any((word) => lower.contains(word));
}

class MindMendApp extends StatelessWidget {
  const MindMendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindMend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C6FF7)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ── SPLASH ──
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C6FF7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.favorite_rounded, size: 80, color: Colors.white),
            SizedBox(height: 24),
            Text('MindMend',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2)),
            SizedBox(height: 12),
            Text('Say everything you couldn\'t say',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
// ── ONBOARDING ──
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late String _username;
  bool _loading = true;

  final List<String> _adjectives = [
    'Silent', 'Calm', 'Brave', 'Gentle', 'Quiet',
    'Soft', 'Bright', 'Still', 'Kind', 'Free'
  ];
  final List<String> _nouns = [
    'Moon', 'Star', 'River', 'Cloud', 'Storm',
    'Ocean', 'Forest', 'Dream', 'Sky', 'Dawn'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrGenerateUsername();
  }

  Future<void> _loadOrGenerateUsername() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('username')) {
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      HomeScreen(username: doc.data()!['username'])));
        }
        return;
      }
    }

    _generateUsername();
    setState(() => _loading = false);
  }

  void _generateUsername() {
    final rand = Random();
    final adj = _adjectives[rand.nextInt(_adjectives.length)];
    final noun = _nouns[rand.nextInt(_nouns.length)];
    final num = rand.nextInt(900) + 100;
    _username = '${adj}_${noun}_$num';
  }

  void _regenerate() {
    setState(() => _generateUsername());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF7C6FF7),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF7C6FF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.white),
              const SizedBox(height: 24),
              const Text('You are completely anonymous',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                  'No name. No photo. No judgment.\nThis is your safe space.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: Colors.white70, height: 1.6)),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  children: [
                    const Text('Your anonymous name is',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Text(_username,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _regenerate,
                      icon: const Icon(Icons.refresh,
                          color: Colors.white70, size: 18),
                      label: const Text('Generate new name',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '🔒  We will never ask your real name, phone number, or college. Ever.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => HomeScreen(username: _username))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Enter MindMend',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C6FF7))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── TREE WIDGET ──
class GrowingTree extends StatelessWidget {
  final int streak;

  const GrowingTree({super.key, required this.streak});

  String get _stageLabel {
    if (streak <= 0) return 'Plant your seed 🌱';
    if (streak <= 7) return 'Sapling • Day $streak';
    if (streak <= 14) return 'Growing • Day $streak';
    if (streak <= 21) return 'Blooming • Day $streak';
    return 'Full Bloom • Day $streak 🌸';
  }

  Color get _groundColor {
    if (streak <= 7) return const Color(0xFF8B6914);
    if (streak <= 14) return const Color(0xFF6B8E23);
    if (streak <= 21) return const Color(0xFF4CAF50);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8F5E9),
            const Color(0xFFF1F8E9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Tree',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$streak day streak 🔥',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: TreePainter(streak: streak),
              size: const Size(double.infinity, 160),
            ),
          ),
          const SizedBox(height: 12),
          Text(_stageLabel,
              style: TextStyle(
                  fontSize: 13,
                  color: _groundColor,
                  fontWeight: FontWeight.w600)),
          if (streak > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (streak % 7) / 7,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor:
                  AlwaysStoppedAnimation<Color>(_groundColor),
              borderRadius: BorderRadius.circular(10),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text('${7 - (streak % 7)} days to next stage',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}

class TreePainter extends CustomPainter {
  final int streak;

  TreePainter({required this.streak});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Ground
    final groundPaint = Paint()
      ..color = const Color(0xFF8B6914).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, size.height - 10),
            width: 80,
            height: 16),
        groundPaint);

    if (streak <= 0) {
      // Just a seed
      final seedPaint = Paint()
        ..color = const Color(0xFF8B6914)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, size.height - 18), 6, seedPaint);
      return;
    }

    // Trunk
    final trunkHeight = streak <= 7
        ? 40.0
        : streak <= 14
            ? 60.0
            : streak <= 21
                ? 75.0
                : 85.0;
    final trunkWidth = streak <= 7 ? 6.0 : streak <= 14 ? 9.0 : 12.0;

    final trunkPaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trunkWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(cx, size.height - 15),
        Offset(cx, size.height - 15 - trunkHeight),
        trunkPaint);

    final trunkBase = Offset(cx, size.height - 15 - trunkHeight);

    // Leaves based on streak
    final leafCount = streak.clamp(1, 30);
    _drawLeaves(canvas, trunkBase, leafCount, size);

    // Flowers for day 15+
    if (streak >= 15) {
      _drawFlowers(canvas, trunkBase, streak);
    }
  }

  void _drawLeaves(
      Canvas canvas, Offset base, int count, Size size) {
    final rand = Random(42); // fixed seed for consistent positions

    final leafColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF66BB6A),
      const Color(0xFF81C784),
      const Color(0xFF388E3C),
      const Color(0xFF2E7D32),
    ];

    final leafPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final radius = 20.0 + rand.nextDouble() * 35;
      final x = base.dx + cos(angle) * radius;
      final y = base.dy + sin(angle) * radius * 0.7 - 10;
      final leafSize = 8.0 + rand.nextDouble() * 10;

      leafPaint.color =
          leafColors[rand.nextInt(leafColors.length)].withOpacity(0.85);

      // Draw leaf as oval
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero,
              width: leafSize,
              height: leafSize * 1.4),
          leafPaint);
      canvas.restore();
    }
  }

  void _drawFlowers(Canvas canvas, Offset base, int streak) {
    final rand = Random(99);
    final flowerCount = ((streak - 14) * 1.5).toInt().clamp(1, 12);

    final petalPaint = Paint()
      ..color = const Color(0xFFFF80AB)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < flowerCount; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final radius = 15.0 + rand.nextDouble() * 30;
      final x = base.dx + cos(angle) * radius;
      final y = base.dy + sin(angle) * radius * 0.7 - 5;

      // Petals
      for (int p = 0; p < 5; p++) {
        final pAngle = p * 2 * pi / 5;
        canvas.drawCircle(
            Offset(x + cos(pAngle) * 5, y + sin(pAngle) * 5),
            4,
            petalPaint);
      }
      // Center
      canvas.drawCircle(Offset(x, y), 3, centerPaint);
    }
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) =>
      oldDelegate.streak != streak;
}

// ── HOME ──
// ── HOME ──
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedMood = -1;
  int _streak = 0;
  String _uid = '';

  final List<Map<String, String>> moods = [
    {'emoji': '😄', 'label': 'Happy'},
    {'emoji': '😌', 'label': 'Calm'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😤', 'label': 'Stressed'},
  ];

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    // Sign in anonymously
    UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    _uid = userCredential.user!.uid;

    // Load streak from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    int currentStreak = 0;
    String message = '';

    if (!doc.exists) {
      // First time user
      currentStreak = 1;
      message = '🌱 Welcome! Your tree is planted. Come back tomorrow to grow it!';
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'username': widget.username,
        'streak': 1,
        'last_open_date': today,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final data = doc.data()!;
      currentStreak = data['streak'] ?? 0;
      final lastOpen = data['last_open_date'] ?? '';

      if (lastOpen == today) {
        // Already opened today — just load streak
      } else {
        final last = DateTime.parse(lastOpen);
        final diff = DateTime.now().difference(last).inDays;

        if (diff == 1) {
          currentStreak += 1;
          message = _getMilestoneMessage(currentStreak);
        } else {
          final lostLeaves = (diff - 1).clamp(1, currentStreak);
          currentStreak = (currentStreak - lostLeaves).clamp(0, 999);
          message =
              '🍂 Your tree missed you for $diff days. $lostLeaves leaf fell. Keep coming back 💚';
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .update({
          'streak': currentStreak,
          'last_open_date': today,
        });
      }
    }

    setState(() => _streak = currentStreak);

    if (message.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showTreeMessage(context, message);
      });
    }
  }

  String _getMilestoneMessage(int streak) {
    if (streak == 7) return '🎉 7 days! Your sapling is growing strong!';
    if (streak == 14) return '🌿 14 days! Your tree is flourishing!';
    if (streak == 21) return '🌸 21 days! Flowers are blooming — just like you!';
    if (streak == 30) return '🌳 30 days! Full bloom! You are incredible!';
    return '🌱 Day $streak! Your tree grew a new leaf today 💚';
  }

  void _showTreeMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D2D2D),
                      height: 1.5)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6FF7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thanks 💚',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good morning 🌸',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(widget.username,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D))),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Color(0xFF7C6FF7),
                    radius: 24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GrowingTree(streak: _streak),
              const SizedBox(height: 24),
              const Text('How are you feeling?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(moods.length, (i) {
                  final selected = selectedMood == i;
                  return GestureDetector(
                    onTap: () => setState(() => selectedMood = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF7C6FF7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(moods[i]['emoji']!,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(moods[i]['label']!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text('What do you need?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D))),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ActionCard(
                    icon: Icons.book_outlined,
                    label: 'Journal',
                    color: const Color(0xFFFFE5F0),
                    iconColor: const Color(0xFFFF6B9D),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => JournalScreen(uid: _uid))),
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    color: const Color(0xFFE5F0FF),
                    iconColor: const Color(0xFF6B9DFF),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChatScreen())),
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.air_outlined,
                    label: 'Breathe',
                    color: const Color(0xFFE5FFE5),
                    iconColor: const Color(0xFF4CAF50),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BreatheScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C6FF7), Color(0xFF9B8FF9)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('💬 Daily Reminder',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 8),
                    Text(
                      '"You are not alone. Whatever you\'re feeling right now — it\'s okay. This is your safe space."',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: iconColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── JOURNAL ──
class JournalScreen extends StatefulWidget {
  final String uid;
  const JournalScreen({super.key, required this.uid});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _entries = [];

  void _saveEntry() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _entries.insert(0, {
        'text': _controller.text.trim(),
        'date': DateTime.now().toString().substring(0, 16),
      });
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FF7),
        title: const Text('My Journal',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Write your thoughts...',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C6FF7))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'What\'s on your mind? Express freely...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saveEntry,
                      icon: const Icon(Icons.save_outlined,
                          size: 18, color: Colors.white),
                      label: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C6FF7),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Past Entries',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D))),
            const SizedBox(height: 12),
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.book_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No entries yet.\nStart writing!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.04),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(_entries[i]['date']!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                              const SizedBox(height: 6),
                              Text(_entries[i]['text']!,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2D2D2D),
                                      height: 1.5)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BREATHE ──
class BreatheScreen extends StatefulWidget {
  const BreatheScreen({super.key});
  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _phase = 'Breathe In';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _phase = 'Breathe Out');
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _phase = 'Breathe In');
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running) {
      _controller.forward();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Breathe',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Take a moment for yourself',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7C6FF7).withOpacity(0.3),
                      border: Border.all(
                          color: const Color(0xFF7C6FF7), width: 2),
                    ),
                    child: Center(
                      child: Text(_phase,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w300)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: _toggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6FF7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(_running ? 'Pause' : 'Start',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '4 seconds in • 4 seconds out\nRepeat as many times as you need',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white38, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CHAT ──
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text':
          'Hey 👋 I\'m here for you. This is a safe space — no judgment, no advice unless you ask. What\'s on your mind?',
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });

    _scrollToBottom();

    if (detectCrisis(text)) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'crisis', 'text': ''});
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(geminiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''You are MindMend, a compassionate emotional support companion for Indian college students. 
Your role is to listen, validate feelings, and respond with empathy — never judgment.
Never give medical advice. Never dismiss feelings. 
Keep responses short, warm, and human. Max 3-4 sentences.
The user says: $text'''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['candidates'][0]['content']['parts'][0]['text'] ??
                'I\'m here with you. Take your time.';
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'bot', 'text': reply});
        });
      } else {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'bot',
            'text':
                'I\'m here with you. Take your time — what\'s going on?'
          });
        });
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'text': 'I\'m here. Tell me more about what you\'re feeling.'
        });
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C6FF7),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MindMend',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('Always here for you',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (_isTyping && i == _messages.length) {
                  return _TypingIndicator();
                }
                final msg = _messages[i];
                if (msg['role'] == 'crisis') {
                  return _CrisisCard();
                }
                final isUser = msg['role'] == 'user';
                return _MessageBubble(
                    text: msg['text']!, isUser: isUser);
              },
            ),
          ),
          _InputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color:
              isUser ? const Color(0xFF7C6FF7) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 14,
                color: isUser
                    ? Colors.white
                    : const Color(0xFF2D2D2D),
                height: 1.5)),
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFF6B6B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'I hear you. What you\'re feeling right now is real and it matters. You don\'t have to face this alone.\n\nPlease reach out to a real person right now 💙',
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2D2D2D),
                height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone,
                  color: Colors.white, size: 18),
              label: const Text('Call iCall — 9152987821',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8)
          ],
        ),
        child: const Text('typing...',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText:
                    'Say anything — this is your safe space...',
                hintStyle: const TextStyle(
                    color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF5F0FF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF7C6FF7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}