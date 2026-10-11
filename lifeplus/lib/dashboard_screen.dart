import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'health_profile_screen.dart';
import 'health_history_screen.dart';
import 'health_insights_screen.dart';
import 'reminders_screen.dart';
import 'health_assessment_screen.dart';
import 'emergency_health_card_screen.dart';
import 'emergency_qr_scanner_screen.dart';

const Color primaryTeal = Color(0xFF087F8C);
const Color deepTeal = Color(0xFF07545B);
const Color paleMint = Color(0xFFEAF8F5);
const Color pageBackground = Color(0xFFF5F8FA);
const Color darkText = Color(0xFF172B36);
const Color mutedText = Color(0xFF81919B);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of LifePlus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in again.')));
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};

            final name = (data['name'] as String?)?.trim();
            final displayName = name != null && name.isNotEmpty
                ? name.split(' ').first
                : 'there';

            final metrics =
                data['latestMetrics'] as Map<String, dynamic>? ?? {};

            final height = _toDouble(data['height']);
            final weight = _toDouble(data['weight']);

            double? bmi;
            if (height != null && weight != null && height > 0 && weight > 0) {
              bmi = weight / ((height / 100) * (height / 100));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 32 : 20,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(context, logout),
                          const SizedBox(height: 28),

                          _buildWelcome(displayName),
                          const SizedBox(height: 24),

                          _buildHealthBanner(context, data),
                          const SizedBox(height: 30),

                          _sectionTitle(
                            'Your health at a glance',
                            'Based on your saved information',
                          ),
                          const SizedBox(height: 16),

                          GridView.count(
                            crossAxisCount: wide ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: wide ? 1.15 : 1.08,
                            children: [
                              _metricCard(
                                context,
                                title: 'Blood Pressure',
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFFE46C79),
                                value: _metricValue(
                                  metrics,
                                  'bloodPressure',
                                  '—',
                                ),
                                unit: 'mmHg',
                                onTap: () => _addMetric(
                                  context,
                                  user.uid,
                                  'bloodPressure',
                                  'Blood Pressure',
                                  'e.g. 120/80',
                                  'mmHg',
                                ),
                              ),
                              _metricCard(
                                context,
                                title: 'Heart Rate',
                                icon: Icons.monitor_heart_rounded,
                                color: const Color(0xFFDF9151),
                                value: _metricValue(metrics, 'heartRate', '—'),
                                unit: 'bpm',
                                onTap: () => _addMetric(
                                  context,
                                  user.uid,
                                  'heartRate',
                                  'Heart Rate',
                                  'e.g. 72',
                                  'bpm',
                                ),
                              ),
                              _metricCard(
                                context,
                                title: 'Blood Sugar',
                                icon: Icons.water_drop_rounded,
                                color: const Color(0xFF6184DB),
                                value: _metricValue(metrics, 'bloodSugar', '—'),
                                unit: 'mg/dL',
                                onTap: () => _addMetric(
                                  context,
                                  user.uid,
                                  'bloodSugar',
                                  'Blood Sugar',
                                  'e.g. 95',
                                  'mg/dL',
                                ),
                              ),
                              _metricCard(
                                context,
                                title: 'Body Mass Index',
                                icon: Icons.accessibility_new_rounded,
                                color: primaryTeal,
                                value: bmi == null
                                    ? '—'
                                    : bmi.toStringAsFixed(1),
                                unit: bmi == null
                                    ? 'Add height & weight'
                                    : 'BMI',
                                onTap: () => _openProfile(context),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          _sectionTitle(
                            'Your health, simplified',
                            'Everything you need in one place',
                          ),
                          const SizedBox(height: 16),

                          GridView.count(
                            crossAxisCount: wide ? 3 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: wide ? 1.65 : 1.30,
                            children: [
                              _actionCard(
                                icon: Icons.qr_code_scanner_rounded,
                                title: 'Scan Emergency QR',
                                subtitle: 'Read medical details offline',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const EmergencyQrScannerScreen(),
                                    ),
                                  );
                                },
                              ),
                              _actionCard(
                                icon: Icons.person_rounded,
                                title: 'My Profile',
                                subtitle: 'Personal details',
                                onTap: () => _openProfile(context),
                              ),
                              _actionCard(
                                icon: Icons.add_chart_rounded,
                                title: 'Add Reading',
                                subtitle: 'Track your health',
                                onTap: () =>
                                    _showReadingOptions(context, user.uid),
                              ),
                              _actionCard(
                                icon: Icons.history_rounded,
                                title: 'Health History',
                                subtitle: 'View charts and past readings',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HealthHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              _actionCard(
                                icon: Icons.notifications_active_rounded,
                                title: 'Reminders',
                                subtitle: 'Stay on track',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RemindersScreen(),
                                    ),
                                  );
                                },
                              ),
                              _actionCard(
                                icon: Icons.lightbulb_rounded,
                                title: 'Health Insights',
                                subtitle: 'Understand your data',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HealthInsightsScreen(),
                                    ),
                                  );
                                },
                              ),

                              _actionCard(
                                icon: Icons.health_and_safety_rounded,
                                title: 'Health Assessment',
                                subtitle: 'Personalized wellness overview',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const HealthAssessmentScreen(),
                                    ),
                                  );
                                },
                              ),

                              _actionCard(
                                icon: Icons.emergency_rounded,
                                title: 'Emergency Health Card',
                                subtitle: 'Medical ID and offline QR',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const EmergencyHealthCardScreen(),
                                    ),
                                  );
                                },
                              ),

                              _actionCard(
                                icon: Icons.local_hospital_rounded,
                                title: 'Find a Doctor',
                                subtitle: 'Discover care options',
                                onTap: () =>
                                    _showComingSoon(context, 'Doctor finder'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          _buildFooter(context, logout),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    Future<void> Function(BuildContext) logout,
  ) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryTeal, deepTeal]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LifePlus',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: darkText,
                letterSpacing: -0.7,
              ),
            ),
            Text(
              'YOUR PERSONAL HEALTH COMPANION',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.1,
                color: mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Log out',
          onPressed: () => logout(context),
          icon: const Icon(Icons.logout_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: darkText,
            padding: const EdgeInsets.all(13),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR WELLNESS JOURNEY',
          style: TextStyle(
            color: primaryTeal,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hello, $name 👋',
          style: const TextStyle(
            color: darkText,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Small steps today. A healthier tomorrow.',
          style: TextStyle(fontSize: 14, color: mutedText),
        ),
      ],
    );
  }

  Widget _buildHealthBanner(
    BuildContext context,
    Map<String, dynamic> profile,
  ) {
    final completed = profile['profileCompleted'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryTeal, deepTeal],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.spa_rounded, color: Color(0xFFA8F0D6), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'YOUR HEALTH MATTERS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                completed
                    ? 'Make your health a priority.'
                    : 'Complete your health profile.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                completed
                    ? 'Keep your health information up to date and track your readings over time.'
                    : 'Add your basic details to personalize your LifePlus experience.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => _openProfile(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: deepTeal,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      completed ? 'View my profile' : 'Complete profile',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 17),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: darkText,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: mutedText)),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECF0F3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 39,
                width: 39,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: mutedText, fontSize: 10),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Update reading',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
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

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFECF0F3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primaryTeal, size: 25),
              const SizedBox(height: 11),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: mutedText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    Future<void> Function(BuildContext) logout,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: paleMint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: primaryTeal, size: 21),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your health journey, your data. LifePlus provides '
              'health-tracking support, not a medical diagnosis. '
              'Consult a qualified healthcare professional for medical advice.',
              style: TextStyle(fontSize: 11, color: deepTeal, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthProfileScreen()),
    );
  }

  Future<void> _addMetric(
    BuildContext context,
    String uid,
    String key,
    String title,
    String hint,
    String unit,
  ) async {
    final controller = TextEditingController();

    try {
      final inputValue = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Record $title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: key == 'bloodPressure'
                ? TextInputType.text
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: title,
              hintText: hint,
              suffixText: key == 'bloodPressure' ? null : unit,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final input = controller.text.trim();

                if (key == 'bloodPressure') {
                  final parts = input.split('/');

                  if (parts.length != 2 ||
                      int.tryParse(parts[0].trim()) == null ||
                      int.tryParse(parts[1].trim()) == null ||
                      int.parse(parts[0].trim()) <= 0 ||
                      int.parse(parts[1].trim()) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter valid blood pressure like 120/80.',
                        ),
                      ),
                    );
                    return;
                  }
                } else {
                  final number = double.tryParse(input);

                  if (number == null || !number.isFinite || number <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid positive number.'),
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(dialogContext, input);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (inputValue == null || inputValue.isEmpty) return;

      final metricUnit = key == 'bloodPressure' ? 'mmHg' : unit;

      // The chart needs a number. For BP, use systolic pressure.
      double chartValue;

      if (key == 'bloodPressure') {
        chartValue = double.parse(inputValue.split('/')[0].trim());
      } else {
        chartValue = double.parse(inputValue);
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final historyRef = userRef.collection('health_readings').doc();

      // Save the latest reading and a separate history record together.
      final batch = FirebaseFirestore.instance.batch();

      batch.set(userRef, {
        'latestMetrics': {
          key: {
            'value': inputValue,
            'unit': metricUnit,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
      }, SetOptions(merge: true));

      batch.set(historyRef, {
        'type': key,
        'value': chartValue,
        'displayValue': inputValue,
        'unit': metricUnit,
        'recordedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title saved to your health history!')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving health reading: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  void _showReadingOptions(BuildContext context, String uid) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a health reading',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE46C79),
                ),
                title: const Text('Blood Pressure'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addMetric(
                    context,
                    uid,
                    'bloodPressure',
                    'Blood Pressure',
                    'e.g. 120/80',
                    'mmHg',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Color(0xFFDF9151),
                ),
                title: const Text('Heart Rate'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addMetric(
                    context,
                    uid,
                    'heartRate',
                    'Heart Rate',
                    'e.g. 72',
                    'bpm',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF6184DB),
                ),
                title: const Text('Blood Sugar'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addMetric(
                    context,
                    uid,
                    'bloodSugar',
                    'Blood Sugar',
                    'e.g. 95',
                    'mg/dL',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, Map<String, dynamic> metrics) {
    final names = {
      'bloodPressure': 'Blood Pressure',
      'heartRate': 'Heart Rate',
      'bloodSugar': 'Blood Sugar',
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Latest saved readings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),
              ...names.entries.map((entry) {
                final metric = metrics[entry.key];
                final value = metric is Map
                    ? metric['value']?.toString() ?? '—'
                    : '—';
                final unit = metric is Map
                    ? metric['unit']?.toString() ?? ''
                    : '';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.monitor_heart_outlined,
                    color: primaryTeal,
                  ),
                  title: Text(entry.value),
                  trailing: Text(
                    value == '—' ? value : '$value $unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'This view shows the latest saved value for each metric, '
                'not a complete historical log.',
                style: TextStyle(color: mutedText, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsights(
    BuildContext context,
    double? bmi,
    Map<String, dynamic> metrics,
  ) {
    String bmiMessage;

    if (bmi == null) {
      bmiMessage =
          'Complete your height and weight in your profile to calculate BMI.';
    } else if (bmi < 18.5) {
      bmiMessage =
          'Your calculated BMI is ${bmi.toStringAsFixed(1)}. '
          'For adults, this is below the usual BMI reference range.';
    } else if (bmi < 25) {
      bmiMessage =
          'Your calculated BMI is ${bmi.toStringAsFixed(1)}. '
          'For adults, this is within the usual BMI reference range.';
    } else if (bmi < 30) {
      bmiMessage =
          'Your calculated BMI is ${bmi.toStringAsFixed(1)}. '
          'For adults, this is above the usual BMI reference range.';
    } else {
      bmiMessage =
          'Your calculated BMI is ${bmi.toStringAsFixed(1)}. '
          'For adults, this is in a higher BMI category.';
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lightbulb_rounded, color: primaryTeal, size: 34),
        title: const Text('Your health insights'),
        content: SingleChildScrollView(
          child: Text(
            '$bmiMessage\n\n'
            'BMI is a screening measure, not a diagnosis. '
            'It does not account for every factor affecting health.\n\n'
            'Your saved readings can help you track changes over time. '
            'A single reading cannot determine your overall health risk.',
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature module will be added next.')),
    );
  }

  String _metricValue(
    Map<String, dynamic> metrics,
    String key,
    String fallback,
  ) {
    final metric = metrics[key];

    if (metric is Map && metric['value'] != null) {
      return metric['value'].toString();
    }

    return fallback;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
