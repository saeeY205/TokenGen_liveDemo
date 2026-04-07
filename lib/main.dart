import 'package:flutter/material.dart';
import 'user_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PhonePreview(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TokenGen Queue (Demo)',
        home: const SplashScreen(),
      ),
    );
  }
}

class PhonePreview extends StatelessWidget {
  final Widget child;

  const PhonePreview({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen is narrow (mobile-like), just show the app normally
        if (constraints.maxWidth < 600) {
          return child;
        }

        // If screen is wide (desktop/web), show the app inside a phone frame
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 375,
                      height: 750,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(44),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF0F172A),
                          width: 10,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // App Content
                          ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: child,
                          ),
                          // Top Notch
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 160,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(18),
                                  bottomRight: Radius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Live Demo Mode',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // start fade-in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _opacity = 1.0);
    });

    // after short delay navigate to HomeScreen
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const UserLoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -0.6),
            end: Alignment(0.8, 0.6),
            colors: [Color(0xFFEAF5FF), Color(0xFFF7FCFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _opacity,
                    child: SizedBox(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                      child: CustomPaint(painter: QueueIconPainter()),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _opacity,
                  child: const Text(
                    'TokenGen Queue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QueueIconPainter extends CustomPainter {
  final Color baseColor;

  QueueIconPainter({this.baseColor = const Color(0xFF0F172A)});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // subtle platform/queue bar behind the figures
    final barPaint = Paint()..color = baseColor.withOpacity(0.06);
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.62, w * 0.88, h * 0.22),
      const Radius.circular(14),
    );
    canvas.drawRRect(barRect, barPaint);

    // People figures (3) arranged in a light queue perspective
    final double headR = w * 0.14;
    final double bodyW = headR * 1.6;
    final double bodyH = headR * 1.1;

    final List<Offset> centers = [
      Offset(w * 0.28, h * 0.42),
      Offset(w * 0.5, h * 0.5),
      Offset(w * 0.72, h * 0.42),
    ];

    for (int i = 0; i < centers.length; i++) {
      final double depthFactor =
          (i == 1) ? 1.0 : 0.94; // middle slightly bigger
      final Offset c = centers[i];

      final bodyPaint = Paint()..color = baseColor.withOpacity(0.92 - i * 0.18);
      final headPaint = Paint()..color = baseColor.withOpacity(1.0 - i * 0.08);

      // body
      final Rect bodyRect = Rect.fromCenter(
        center: Offset(c.dx, c.dy + headR * 0.75),
        width: bodyW * depthFactor,
        height: bodyH * depthFactor,
      );
      final RRect bodyR = RRect.fromRectAndRadius(
        bodyRect,
        const Radius.circular(10),
      );
      canvas.drawRRect(bodyR, bodyPaint);

      // head
      final Offset headCenter = Offset(c.dx, c.dy - headR * 0.08);
      canvas.drawCircle(headCenter, headR * depthFactor, headPaint);
    }

    // small minimal separator line to suggest queue direction
    final linePaint =
        Paint()
          ..color = baseColor.withOpacity(0.08)
          ..strokeWidth = h * 0.012
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.12, h * 0.78),
      Offset(w * 0.88, h * 0.78),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}