
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color insightTeal = Color(0xFF087F8C);
const Color insightBackground = Color(0xFFF5F8FA);
const Color insightDark = Color(0xFF172B36);

class HealthInsightsScreen extends StatelessWidget {
  const HealthInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in again.')),
      );
    }

    final readingsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('health_readings')
        .orderBy('recordedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: insightBackground,
      appBar: AppBar(
        title: const Text(
          'Health Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: insightDark,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: readingsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load your health data. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: insightTeal),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          final heartReadings = _getReadings(documents, 'heartRate');
          final bpReadings = _getReadings(documents, 'bloodPressure');
          final sugarReadings = _getReadings(documents, 'bloodSugar');

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Understand your health data',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: insightDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review recent measurements and changes over time.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              _buildSummary(
                icon: Icons.monitor_heart_rounded,
                title: 'Heart Rate',
                readings: heartReadings,
                unit: 'bpm',
                color: const Color(0xFFDF9151),
              ),
              const SizedBox(height: 14),

              _buildSummary(
                icon: Icons.favorite_rounded,
                title: 'Blood Pressure',
                readings: bpReadings,
                unit: 'mmHg',
                color: const Color(0xFFE46C79),
              ),
              const SizedBox(height: 14),

              _buildSummary(
                icon: Icons.water_drop_rounded,
                title: 'Blood Sugar',
                readings: sugarReadings,
                unit: 'mg/dL',
                color: const Color(0xFF6184DB),
              ),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: insightTeal,
                          size: 25,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'How to use your insights',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: insightDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Record measurements consistently to observe trends.\n'
                      '• Compare readings taken under similar conditions.\n'
                      '• One reading or a short trend cannot establish a diagnosis.\n'
                      '• Discuss concerning or repeatedly unusual readings '
                      'with a qualified healthcare professional.',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        height: 1.7,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'LifePlus supports health tracking and education. '
                  'These comparisons are descriptive, not a medical '
                  'assessment or emergency service.',
                  style: TextStyle(
                    color: Color(0xFF07545B),
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getReadings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    String type,
  ) {
    return documents
        .where((doc) {
          final data = doc.data();
          return data['type'] == type && data['value'] is num;
        })
        .map((doc) => doc.data())
        .toList();
  }

  Widget _buildSummary({
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> readings,
    required String unit,
    required Color color,
  }) {
    final hasReading = readings.isNotEmpty;
    final current = hasReading ? readings.first : null;
    final previous = readings.length >= 2 ? readings[1] : null;

    final currentValue = current?['displayValue']?.toString() ??
        current?['value']?.toString() ??
        '—';

    String changeTitle = 'Not enough data for comparison';
    String changeDescription =
        'Record at least two readings to compare changes.';

    if (previous != null && current != null) {
      final currentNumber = (current['value'] as num).toDouble();
      final previousNumber = (previous['value'] as num).toDouble();
      final difference = currentNumber - previousNumber;
      final differenceText = difference.abs().toStringAsFixed(1);

      if (difference.abs() < 0.0001) {
        changeTitle = 'No numerical change';
        changeDescription =
            'The two most recent recorded values are equal.';
      } else if (difference > 0) {
        changeTitle = 'Increased by $differenceText $unit';
        changeDescription =
            'The latest recorded value is higher than the previous one.';
      } else {
        changeTitle = 'Decreased by $differenceText $unit';
        changeDescription =
            'The latest recorded value is lower than the previous one.';
      }

      if (title == 'Blood Pressure') {
        changeDescription =
            'Comparison uses systolic (upper) pressure only.';
      }
    }

    String dateLabel = 'No reading recorded';

    if (current?['recordedAt'] is Timestamp) {
      final date = (current!['recordedAt'] as Timestamp).toDate();
      dateLabel =
          'Last recorded: ${date.day}/${date.month}/${date.year}';
    } else if (hasReading) {
      dateLabel = 'Reading saved; timestamp is not available yet.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECF0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: insightDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${readings.length} readings',
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'LATEST READING',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasReading ? '$currentValue $unit' : 'No data yet',
            style: const TextStyle(
              color: insightDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            dateLabel,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FA),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  changeTitle,
                  style: TextStyle(
                    color: insightDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  changeDescription,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
