import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'services/queue_service.dart';
import 'services/auth_service.dart';
import 'services/queue_notification_service.dart';

class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  const PulseAnimation({
    super.key,
    required this.child,
    required this.pulseColor,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class WaitingDots extends StatefulWidget {
  const WaitingDots({super.key});

  @override
  State<WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<WaitingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double opacity = ((_controller.value * 3 - index) % 3) / 3;
            if (opacity < 0) opacity = 0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF06B6D4,
                ).withOpacity(opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class QueueShimmer extends StatelessWidget {
  const QueueShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder:
                    (_, __) => Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QueueDotConnector extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 5;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VisualQueueView extends StatelessWidget {
  final List<QueryDocumentSnapshot> tickets;
  final String? currentUid;
  final double animationValue;

  const VisualQueueView({
    super.key,
    required this.tickets,
    this.currentUid,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const Center(
        child: Text('Queue is empty', style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Modern Office Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'OFFICE ENTRENCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final doc = tickets[index];
                final status = doc.get('status');
                final isServing = status == 'serving';
                final isMe = doc.get('userId') == currentUid;
                final token = doc.get('tokenNumber').toString().padLeft(2, '0');

                return Column(
                  children: [
                    // === SERVING CARD (bold orange gradient) ===
                    if (isServing)
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'T-$token',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (isMe)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(
                                              color: Color(0xFFF97316),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Now inside the office',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await QueueService().callNextStudent();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFEA580C),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black26,
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Token Served',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              const PulseAnimation(
                                pulseColor: Colors.white,
                                child: Icon(
                                  Icons.stars_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      )
                    // === WAITING CARD (subtle, muted) ===
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isMe
                                    ? const Color(0xFF2DD4BF).withOpacity(0.4)
                                    : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Position Number
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? const Color(0xFFCCFBF1)
                                        : Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isMe
                                            ? const Color(0xFF0D9488)
                                            : Colors.grey.shade400,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'T-$token',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              isMe
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                      if (isMe)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2DD4BF),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Waiting in line',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.hourglass_empty,
                              color: Colors.grey.shade300,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                    // Connecting Dotted Line
                    if (index < tickets.length - 1)
                      SizedBox(
                        height: 30,
                        width: 40,
                        child: CustomPaint(painter: QueueDotConnector()),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ViewQueueScreen extends StatefulWidget {
  final String? myToken;
  const ViewQueueScreen({super.key, this.myToken});

  get child => null;

  @override
  State<ViewQueueScreen> createState() => _ViewQueueScreenState();
}

class _ViewQueueScreenState extends State<ViewQueueScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QueueService queueService = QueueService();
    final AuthService authService = AuthService();
    final String? currentUid = authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF05264E),
        title: const Text(
          'Queue Status',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.list,
              color: _currentIndex == 0 ? const Color(0xFF2DD4BF) : Colors.grey,
            ),
            onPressed:
                () => _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
          ),
          IconButton(
            icon: Icon(
              Icons.accessibility_new,
              color: _currentIndex == 1 ? const Color(0xFF2DD4BF) : Colors.grey,
            ),
            onPressed:
                () => _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFFF0FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Sliding hint
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _currentIndex == 0
                    ? 'Slide left for Visual View ←'
                    : '→ Slide right for List View',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: queueService.streamQueue(),
                builder: (context, snapshot) {
                  // Keep PageView persistent, only its content relative to data
                  final tickets = snapshot.data?.docs ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      tickets.isEmpty) {
                    return const QueueShimmer();
                  }

                  return PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      if (mounted) setState(() => _currentIndex = index);
                    },
                    children: [
                      _buildListView(tickets, currentUid),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return VisualQueueView(
                            tickets: tickets,
                            currentUid: currentUid,
                            animationValue: _controller.value,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    List<QueryDocumentSnapshot> tickets,
    String? currentUid,
  ) {
    final servingDoc =
        tickets.where((doc) => doc.get('status') == 'serving').firstOrNull;
    final waitingTickets =
        tickets.where((doc) => doc.get('status') == 'waiting').toList();

    final currentToken =
        servingDoc != null
            ? 'T-${servingDoc.get('tokenNumber').toString().padLeft(2, '0')}'
            : 'WAITING';

    int myWaitPosition = -1;
    bool isMyTurnServing = false;
    String? myFormattedToken;

    if (currentUid != null) {
      final myTicket =
          tickets.where((doc) => doc.get('userId') == currentUid).firstOrNull;
      if (myTicket != null) {
        myFormattedToken =
            'T-${myTicket.get('tokenNumber').toString().padLeft(2, '0')}';
        if (myTicket.get('status') == 'serving') {
          isMyTurnServing = true;
        } else {
          myWaitPosition = waitingTickets.indexWhere(
            (doc) => doc.get('userId') == currentUid,
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isMyTurnServing
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [const Color(0xFF2DD4BF), const Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isMyTurnServing
                          ? Colors.orange
                          : const Color(0xFF2DD4BF))
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  isMyTurnServing ? 'IT IS YOUR TURN!' : 'NOW SERVING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                PulseAnimation(
                  pulseColor: Colors.white,
                  child: Text(
                    currentToken,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseAnimation(
                        pulseColor: Colors.white,
                        child: const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live Updates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (myFormattedToken != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: isMyTurnServing ? const Color(0xFFFFFBEB) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Token',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          myFormattedToken,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isMyTurnServing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const PulseAnimation(
                            pulseColor: Color(0xFFF59E0B),
                            child: Icon(
                              Icons.check_circle,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const Text(
                            'Being Served',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await QueueService().callNextStudent();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: Colors.orange.shade200,
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Token Served',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (myWaitPosition >= 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Position: ${myWaitPosition + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                'waiting',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(width: 4),
                              WaitingDots(),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Queue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${waitingTickets.length} students waiting',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child:
                tickets.isEmpty
                    ? const Center(child: Text('Queue is empty'))
                    : ListView.separated(
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final ticketDoc = tickets[index];
                        final data = ticketDoc.data();
                        final tokenNum = data['tokenNumber'] ?? 0;
                        final token =
                            'T-${tokenNum.toString().padLeft(2, '0')}';
                        final status = data['status'] ?? 'waiting';
                        final userId = data['userId'] ?? '';
                        final isMine = userId == currentUid;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color:
                                isMine ? const Color(0xFFF0FDFA) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border:
                                isMine
                                    ? Border.all(
                                      color: const Color(0xFF2DD4BF),
                                      width: 1.4,
                                    )
                                    : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    isMine
                                        ? const Color(0xFF2DD4BF)
                                        : const Color(0xFFF1F5F9),
                                child: Text(
                                  status == 'serving'
                                      ? '★'
                                      : '${tickets.indexOf(ticketDoc) + 1}',
                                  style: TextStyle(
                                    color:
                                        isMine ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      token,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isMine
                                                ? const Color(0xFF05264E)
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMine
                                          ? 'YOU'
                                          : (data['userName'] ?? 'Student'),
                                      style: TextStyle(
                                        color:
                                            isMine
                                                ? const Color(0xFF2DD4BF)
                                                : Colors.black54,
                                        fontSize: 13,
                                        fontWeight:
                                            isMine
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: TextStyle(
                                      color:
                                          status == 'serving'
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 90,
                                    child: LinearProgressIndicator(
                                      value: status == 'serving' ? 1.0 : 0.0,
                                      backgroundColor: Colors.grey.shade200,
                                      color:
                                          status == 'serving'
                                              ? Colors.green[400]
                                              : Colors.orange[300],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
