import 'package:flutter/material.dart';
import 'viewq.dart';
import 'services/queue_service.dart';
import 'services/auth_service.dart';

class JoinQueueScreen extends StatefulWidget {
  const JoinQueueScreen({super.key});

  @override
  State<JoinQueueScreen> createState() => _JoinQueueScreenState();
}

class _JoinQueueScreenState extends State<JoinQueueScreen> {
  String? _token;
  final QueueService _queueService = QueueService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _onWaitlist = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyOnWaitlist();
  }

  Future<void> _checkIfAlreadyOnWaitlist() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final doc = await _queueService.streamMyWaitlistEntry(user.uid).first;
    if (doc.exists && mounted) {
      setState(() => _onWaitlist = true);
    }
  }

  void _confirmJoin() async {
    if (_token != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already joined with token $_token')),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final int tokenNumber = await _queueService.joinQueue(
        user.uid,
        user.displayName ?? 'Student',
      );

      final String formattedToken =
          'T-${tokenNumber.toString().padLeft(2, '0')}';

      // If they were on the waitlist, remove them
      if (_onWaitlist) {
        await _queueService.leaveWaitlist(user.uid);
      }

      setState(() {
        _token = formattedToken;
        _onWaitlist = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Success! Your token is $formattedToken'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();

      if (errMsg.contains('QUEUE_FULL')) {
        _showQueueFullBottomSheet(user.uid, user.displayName ?? 'Student');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join queue: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQueueFullBottomSheet(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_off_outlined,
                    color: Color(0xFFEA580C),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Queue is Full',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The queue has reached its limit right now.\nWe\'ll notify you here when a spot opens up!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await _queueService.joinWaitlist(userId, userName);
                      if (!mounted) return;
                      setState(() => _onWaitlist = true);
                      nav.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "You're on the waitlist! We'll alert you when space opens.",
                          ),
                          backgroundColor: Color(0xFFD97706),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text(
                      'Notify Me When Space Opens',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF05264E),
        title: const Text(
          'Get Your Token',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // subtitle
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Confirm to receive your token and join the queue',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 14),
                ),
              ),

              const SizedBox(height: 12),

              // --- Notification banner: notified from waitlist ---
              if (_onWaitlist && user != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: _queueService.streamMyWaitlistEntry(user.uid),
                  builder: (context, snap) {
                    final data = snap.data?.data();
                    final notified = data?['notified'] == true;

                    if (notified) {
                      // Space is open — show join now banner
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.celebration_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎉 Queue has space!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'A spot just opened up — join now!',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _confirmJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF16A34A),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Join Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Still waiting on waitlist
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "You're on the waitlist — we'll alert you here when a spot opens.",
                                style: TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await _queueService.leaveWaitlist(user.uid);
                                if (mounted)
                                  setState(() => _onWaitlist = false);
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFFD97706),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),

              // big card (token display)
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2DD4BF), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_token == null) ...[
                          const Text(
                            'Ready to join',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap confirm to generate your token',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Icon(
                            Icons.confirmation_num_outlined,
                            size: 56,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ] else ...[
                          const Text(
                            'Your token',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _token!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Please wait to be called',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // confirm button (custom gradient InkWell)
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _isLoading ? null : _confirmJoin,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient:
                            _token == null
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFF60A5FA),
                                    Color(0xFF2DD4BF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : LinearGradient(
                                  colors: [
                                    Colors.green[700]!,
                                    Colors.green[600]!,
                                  ],
                                ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _token == null
                                    ? const Color(0x3322A7FF)
                                    : Colors.green.withOpacity(0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child:
                          _isLoading
                              ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _token == null
                                        ? 'Got it! Confirm & Join'
                                        : 'You are in — $_token',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // cancel text + view queue status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel & Go Back',
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ViewQueueScreen(myToken: _token),
                          ),
                        ),
                    child: const Text(
                      'View Queue Status',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
