import 'package:flutter/material.dart';
import 'admin_login.dart';
import 'services/queue_service.dart';
import 'profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _avgTimeController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _queueLimitController = TextEditingController();
  final QueueService _queueService = QueueService();
  bool _showTokenLogs = false;


  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _avgTimeController.dispose();
    _announcementController.dispose();
    _queueLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FAFB), Color(0xFFEFF6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TokenGen Admin Panel',
                        style: const TextStyle(
                          color: Color(0xFF05264E),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF2DD4BF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') {
                          _handleLogout();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 120),
                      icon: const Icon(Icons.more_vert, size: 20),
                    ),
                  ],
                ),
              ),
              // Body Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _queueService.streamAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final tickets = snapshot.data?.docs ?? [];
                    
                    // Derive state from tickets list
                    final servingTicket = tickets.where((doc) => doc.get('status') == 'serving').firstOrNull;
                    final waitingTickets = tickets.where((doc) => doc.get('status') == 'waiting').toList();
                    
                    final currentToken = servingTicket != null 
                        ? 'T-${servingTicket.get('tokenNumber').toString().padLeft(2, '0')}'
                        : 'NONE';
                    
                    final nextTicket = waitingTickets.isNotEmpty 
                        ? 'T-${waitingTickets.first.get('tokenNumber').toString().padLeft(2, '0')}'
                        : 'NONE';
                    
                    // Find highest token number for total
                    int lastTokenNum = 0;
                    if (tickets.isNotEmpty) {
                      lastTokenNum = tickets.fold<int>(0, (max, doc) {
                        final num = doc.get('tokenNumber') as int;
                        return num > max ? num : max;
                      });
                    }

                    return StreamBuilder<DocumentSnapshot>(
                      stream: _queueService.streamSettings(),
                      builder: (context, settingsSnapshot) {
                        final settings = settingsSnapshot.data?.data() ?? {};
                        final isPaused = settings['isPaused'] ?? false;
                        final isAcceptingTokens = settings['isAcceptingTokens'] ?? true;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Call Next Student - Primary Action
                              _buildPrimaryActionButton(currentToken, nextTicket, servingTicket, isPaused),

                              const SizedBox(height: 24),

                              // Dashboard Summary Cards
                              _buildSummaryCards(isMobile, currentToken, nextTicket, lastTokenNum.toString(), waitingTickets.length.toString()),

                              const SizedBox(height: 24),

                              // Secondary Action Buttons
                              _buildSecondaryActionButtons(servingTicket?.id, isPaused, isAcceptingTokens, settings),

                              const SizedBox(height: 24),

                              // Average Processing Time
                              _buildAvgTimeCard(),

                              const SizedBox(height: 24),

                              // Token Logs Section
                              _buildTokenLogsSection(isMobile, tickets),

                              const SizedBox(height: 24),

                              // Announcements Panel
                              _buildAnnouncementsPanel(),

                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      }
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile, String current, String next, String total, String waiting) {
    final cards = [
      {
        'title': 'Current Token',
        'value': current,
        'icon': Icons.confirmation_num,
        'color': const Color(0xFF2DD4BF),
      },
      {
        'title': 'Next Token',
        'value': next,
        'icon': Icons.arrow_forward,
        'color': const Color(0xFF60A5FA),
      },
      {
        'title': 'Total Tokens Today',
        'value': total,
        'icon': Icons.bar_chart,
        'color': const Color(0xFFFFA726),
      },
      {
        'title': 'Students Waiting',
        'value': waiting,
        'icon': Icons.people,
        'color': const Color(0xFFEF5350),
      },
      {
        'title': 'Avg Processing Time',
        'value': '3 mins',
        'icon': Icons.timer,
        'color': const Color(0xFF9C27B0),
      },
    ];

    return isMobile
        ? SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final card = cards[index];
                return SizedBox(
                  width: 180,
                  child: _buildSummaryCard(card),
                );
              },
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 5;
              if (constraints.maxWidth < 1200) crossAxisCount = 4;
              if (constraints.maxWidth < 900) crossAxisCount = 3;
              if (constraints.maxWidth < 600) crossAxisCount = 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: cards.map((card) => _buildSummaryCard(card)).toList(),
              );
            },
          );
  }

  Widget _buildSummaryCard(Map<String, dynamic> card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (card['color'] as Color).withOpacity(0.12),
            (card['color'] as Color).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (card['color'] as Color).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (card['color'] as Color).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (card['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              card['icon'],
              color: card['color'],
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card['title'],
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card['value'],
            style: TextStyle(
              color: card['color'],
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(String current, String next, QueryDocumentSnapshot? servingTicket, bool isPaused) {
    final servingTicketId = servingTicket?.id;
    final data = servingTicket?.data();
    final userName = data?['userName'] ?? 'Unknown';
    final prn = data?['prn'] ?? 'N/A';
    final year = data?['year'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Current Status Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cashier Station',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (servingTicketId != null)
                      Text(
                        'Serving: $userName',
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isPaused ? Colors.orange : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isPaused ? Colors.orange : Colors.green).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: isPaused ? Colors.orange : Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      isPaused ? 'Queue Paused' : 'Counter Active',
                      style: TextStyle(
                        color: isPaused ? Colors.orange : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (servingTicketId != null) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildDetailItem('PRN', prn, Icons.badge_outlined),
                _buildDetailItem('YEAR', year, Icons.school_outlined),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Main Call Button
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton(
              onPressed: isPaused ? null : () async {
                await _queueService.callNextStudent();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📢 Moving to next student'),
                    backgroundColor: Color(0xFF2DD4BF),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPaused 
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [const Color(0xFF2DD4BF), const Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isPaused ? [] : [
                    BoxShadow(
                      color: const Color(0xFF2DD4BF).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPaused ? Icons.pause_circle_outline : Icons.notifications_active_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaused ? 'QUEUE IS PAUSED' : 'CALL NEXT STUDENT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPaused ? 'Resume from controls below' : 'Next in line: $next',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Secondary Controls (Recall / Done)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: servingTicketId == null ? null : () async {
                    await _queueService.recallTicket(servingTicketId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recalling Token: $current')),
                    );
                  },
                  icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                  label: const Text('Recall'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF60A5FA),
                    side: BorderSide(color: const Color(0xFF60A5FA).withOpacity(0.3)),
                    backgroundColor: const Color(0xFF60A5FA).withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: servingTicketId == null ? null : () async {
                    await _queueService.markAsDone(servingTicketId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Marked $current as Done')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Done'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.green.withOpacity(0.3)),
                    backgroundColor: Colors.green.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButtons(String? servingTicketId, bool isPaused, bool isAcceptingTokens, Map<String, dynamic> settings) {
    final int queueLimit = (settings['queueLimit'] ?? 0) as int;
    final limitLabel = queueLimit > 0 ? 'Limit: $queueLimit' : 'No Limit';

    final buttons = [
      {
        'label': 'Skip Token',
        'icon': Icons.skip_next,
        'color': const Color(0xFFFFA726),
        'onPressed': servingTicketId == null ? null : () async {
          await _queueService.skipTicket(servingTicketId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token skipped')),
          );
        },
      },
      {
        'label': 'Recall Last Token',
        'icon': Icons.replay,
        'color': const Color(0xFF60A5FA),
        'onPressed': servingTicketId == null ? null : () async {
          await _queueService.recallTicket(servingTicketId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recalling current token')),
          );
        },
      },
      {
        'label': isPaused ? 'Resume Queue' : 'Pause Queue',
        'icon': isPaused ? Icons.play_circle : Icons.pause_circle,
        'color': isPaused ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        'onPressed': () async {
          await _queueService.updateSettings({'isPaused': !isPaused});
        },
      },
      {
        'label': isAcceptingTokens ? 'Stop Accepting Tokens' : 'Start Accepting Tokens',
        'icon': isAcceptingTokens ? Icons.stop_circle : Icons.check_circle,
        'color': isAcceptingTokens ? const Color(0xFF9C27B0) : const Color(0xFF2DD4BF),
        'onPressed': () async {
          await _queueService.updateSettings({'isAcceptingTokens': !isAcceptingTokens});
        },
      },
      {
        'label': 'Reset All (Fresh Start)',
        'icon': Icons.refresh,
        'color': Colors.red,
        'onPressed': () => _showResetDialog(context),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Queue Controls',
                style: TextStyle(
                  color: Color(0xFF05264E),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: buttons.map((btn) => _buildSecondaryButton(btn)).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          // Queue Limit Tile
          InkWell(
            onTap: () => _showSetQueueLimitDialog(context, queueLimit),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.group_outlined, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Queue Limit',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$limitLabel · Notify waitlist when ≤ 4 remain',
                          style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _queueService.streamWaitlist(),
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE047)),
                        ),
                        child: Text(
                          '$count waiting',
                          style: const TextStyle(
                            color: Color(0xFF854D0E),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  const Icon(Icons.edit_outlined, color: Color(0xFF16A34A), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetQueueLimitDialog(BuildContext context, int currentLimit) {
    _queueLimitController.text = currentLimit > 0 ? currentLimit.toString() : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.group_outlined, color: Color(0xFF16A34A)),
            SizedBox(width: 10),
            Text('Set Queue Limit', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the maximum number of people allowed in the queue at once. Set to 0 for unlimited.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queueLimitController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '0 = Unlimited',
                prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF94A3B8), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(_queueLimitController.text.trim()) ?? 0;
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await _queueService.updateSettings({'queueLimit': val < 0 ? 0 : val});
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(val <= 0 ? 'Queue limit removed (unlimited)' : 'Queue limit set to $val'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Queue?'),
        content: const Text('This will delete all current tokens and reset everything. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _queueService.resetQueue();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Queue reset successfully')),
              );
            },
            child: const Text('Reset Everything', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(Map<String, dynamic> btn) {
    return ElevatedButton.icon(
      onPressed: btn['onPressed'],
      icon: Icon(btn['icon'], size: 18),
      label: Text(
        btn['label'],
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: (btn['color'] as Color).withOpacity(0.12),
        foregroundColor: btn['color'],
        elevation: 0,
        disabledBackgroundColor: Colors.grey.withOpacity(0.05),
        disabledForegroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: (btn['color'] as Color).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAvgTimeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Processing Time',
                      style: TextStyle(
                        color: Color(0xFF05264E),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Set the average time per student to calculate queue wait times',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _avgTimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '3',
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                    prefixIcon: const Icon(
                      Icons.access_time,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    suffixText: 'mins',
                    suffixStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2DD4BF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_avgTimeController.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Average time set to ${_avgTimeController.text} minutes',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF60A5FA),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF60A5FA),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcements',
                      style: TextStyle(
                        color: Color(0xFF05264E),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Send notifications to all users in real-time',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _announcementController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type announcement...',
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                    prefixIcon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2DD4BF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_announcementController.text.isNotEmpty) {
                    final message = _announcementController.text.trim();
                    try {
                      await _queueService.sendAnnouncement(message);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📣 Announcement broadcasted!'),
                          backgroundColor: Color(0xFF2DD4BF),
                        ),
                      );
                      _announcementController.clear();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text(
                  'Send',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenLogsSection(bool isMobile, List<QueryDocumentSnapshot> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Service Logs',
                      style: TextStyle(
                        color: Color(0xFF05264E),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Today\'s service history and queue management',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _showTokenLogs = !_showTokenLogs);
              },
              icon: Icon(
                _showTokenLogs ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                _showTokenLogs ? 'Hide Logs' : 'View Logs',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateColor.resolveWith(
                    (_) => const Color(0xFFF1F5F9),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Token',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Student',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'PRN',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Year',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Phone',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  rows: tickets
                      .map(
                        (doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'waiting';
                          final isCompleted = status == 'completed';
                          final isServing = status == 'serving';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (isServing) return const Color(0xFFE0F2FE).withOpacity(0.5);
                              if (isCompleted) return Colors.grey.withOpacity(0.1);
                              return null;
                            }),
                            cells: [
                              DataCell(
                                Text(
                                  'T-${(data['tokenNumber'] ?? 0).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isCompleted ? Colors.grey : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w600,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['userName'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: isCompleted ? Colors.grey : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['prn'] ?? 'N/A',
                                  style: TextStyle(
                                    color: isCompleted ? Colors.grey : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['year'] ?? 'N/A',
                                  style: TextStyle(
                                    color: isCompleted ? Colors.grey : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  data['phone'] ?? 'N/A',
                                  style: TextStyle(
                                    color: isCompleted ? Colors.grey : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFFF1F5F9)
                                        : isServing
                                            ? const Color(0xFFFEF08A)
                                            : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: TextStyle(
                                      color: isCompleted
                                          ? const Color(0xFF64748B)
                                          : isServing
                                              ? const Color(0xFF854D0E)
                                              : const Color(0xFF991B1B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                isServing 
                                  ? TextButton(
                                      onPressed: () => _queueService.markAsDone(doc.id),
                                      child: const Text('Complete'),
                                    )
                                  : const Text('-'),
                              ),
                            ],
                          );
                        }
                      )
                      .toList(),
                ),
              ),
            ),
            crossFadeState:
                _showTokenLogs ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}