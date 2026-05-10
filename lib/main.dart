import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CleftTuneAdminApp());
}

class CleftTuneAdminApp extends StatelessWidget {
  const CleftTuneAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CleftTune Admin',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const int premiumPrice = 99;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C12),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E6C3),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            final int totalUsers = docs.length;

            final int freeUsers = docs.where((doc) {
              final data = doc.data();
              return data['subscription'] == 'free';
            }).length;

            final int premiumUsers = docs.where((doc) {
              final data = doc.data();
              return data['subscription'] == 'premium';
            }).length;

            final int income = premiumUsers * premiumPrice;

            final double freePercent =
                totalUsers == 0 ? 0 : freeUsers / totalUsers;

            final double premiumPercent =
                totalUsers == 0 ? 0 : premiumUsers / totalUsers;

            final recentUsers = docs.take(5).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeaderSection(),

                  const SizedBox(height: 22),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(
                        title: 'Total Users',
                        value: '$totalUsers',
                        icon: Icons.people_alt_rounded,
                        subtitle: 'All registered users',
                        iconColor: const Color(0xFF00E6C3),
                      ),
                      StatCard(
                        title: 'Free Users',
                        value: '$freeUsers',
                        icon: Icons.star_rounded,
                        subtitle:
                            '${(freePercent * 100).toStringAsFixed(1)}% of users',
                        iconColor: const Color(0xFF9B6DFF),
                      ),
                      StatCard(
                        title: 'Premium',
                        value: '$premiumUsers',
                        icon: Icons.diamond_rounded,
                        subtitle:
                            '${(premiumPercent * 100).toStringAsFixed(1)}% of users',
                        iconColor: const Color(0xFF2D9CFF),
                      ),
                      StatCard(
                        title: 'Income',
                        value: '₱$income',
                        icon: Icons.account_balance_wallet_rounded,
                        subtitle: 'Premium × ₱$premiumPrice',
                        iconColor: const Color(0xFF00E6C3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          icon: Icons.pie_chart_rounded,
                          title: 'Subscription Overview',
                        ),
                        const SizedBox(height: 18),
                        ProgressRow(
                          label: 'Free Users',
                          count: freeUsers,
                          percent: freePercent,
                          color: const Color(0xFF00E6C3),
                        ),
                        const SizedBox(height: 16),
                        ProgressRow(
                          label: 'Premium Users',
                          count: premiumUsers,
                          percent: premiumPercent,
                          color: const Color(0xFF2D9CFF),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          icon: Icons.trending_up_rounded,
                          title: 'Income Overview',
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '₱$income',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Estimated income from premium subscribers',
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 90,
                          child: CustomPaint(
                            painter: LineChartPainter(),
                            child: Container(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          icon: Icons.group_rounded,
                          title: 'Recent Users',
                        ),
                        const SizedBox(height: 12),

                        if (recentUsers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No users found in the database.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),

                        for (final user in recentUsers)
                          RecentUserTile(
                            name: user.data()['name'] ?? 'No name',
                            email: user.data()['email'] ?? 'No email',
                            plan: user.data()['subscription'] ?? 'unknown',
                            color: user.data()['subscription'] == 'premium'
                                ? const Color(0xFF00E6C3)
                                : const Color(0xFF9B6DFF),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          icon: Icons.analytics_rounded,
                          title: 'Plan Performance',
                        ),
                        const SizedBox(height: 16),
                        PlanRow(
                          plan: 'Free',
                          users: freeUsers,
                          revenue: '₱0',
                          percent: freePercent,
                          color: const Color(0xFF9B6DFF),
                        ),
                        const SizedBox(height: 14),
                        PlanRow(
                          plan: 'Premium',
                          users: premiumUsers,
                          revenue: '₱$income',
                          percent: premiumPercent,
                          color: const Color(0xFF2D9CFF),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Center(
                    child: Text(
                      '© 2026 CleftTune Admin',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF00E6C3).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E6C3)),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Color(0xFF00E6C3),
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CleftTune Admin',
                style: TextStyle(
                  color: Color(0xFF00E6C3),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Database dashboard overview',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: null,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.18),
            child: Icon(icon, color: iconColor),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: iconColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF0B2E39).withOpacity(0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E6C3).withOpacity(0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E6C3).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E6C3)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;

  const ProgressRow({
    super.key,
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Text(
              '$count users',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 12,
            backgroundColor: Colors.white12,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(percent * 100).toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

class RecentUserTile extends StatelessWidget {
  final String name;
  final String email;
  final String plan;
  final Color color;

  const RecentUserTile({
    super.key,
    required this.name,
    required this.email,
    required this.plan,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Text(
          firstLetter,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        email,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.7)),
        ),
        child: Text(
          plan,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ),
    );
  }
}

class PlanRow extends StatelessWidget {
  final String plan;
  final int users;
  final String revenue;
  final double percent;
  final Color color;

  const PlanRow({
    super.key,
    required this.plan,
    required this.users,
    required this.revenue,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            plan,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white12,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 55,
          child: Text(
            '$users',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            revenue,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF00E6C3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF00E6C3).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * 0.80),
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.45, size.height * 0.45),
      Offset(size.width * 0.60, size.height * 0.55),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width, size.height * 0.18),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF00E6C3)
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}