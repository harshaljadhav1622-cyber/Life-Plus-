
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color assessmentTeal = Color(0xFF087F8C);
const Color assessmentBackground = Color(0xFFF5F8FA);
const Color assessmentDark = Color(0xFF172B36);

class HealthAssessmentScreen extends StatelessWidget {
  const HealthAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in again.')),
      );
    }

    final firestore = FirebaseFirestore.instance;
    final profileStream = firestore
        .collection('users')
        .doc(user.uid)
        .snapshots();

    final readingsStream = firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_readings')
        .orderBy('recordedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: assessmentBackground,
      appBar: AppBar(
        title: const Text(
          'Personal Health Assessment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: assessmentDark,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return const Center(
              child: Text('Could not load your health profile.'),
            );
          }

          if (profileSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: assessmentTeal,
              ),
            );
          }

          final profile = profileSnapshot.data?.data() ?? {};

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: readingsStream,
            builder: (context, readingsSnapshot) {
              if (readingsSnapshot.hasError) {
                return const Center(
                  child: Text('Could not load your health readings.'),
                );
              }

              if (readingsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: assessmentTeal,
                  ),
                );
              }

              final documents =
                  readingsSnapshot.data?.docs ?? [];

              final readings = documents
                  .map((doc) => doc.data())
                  .toList();

              final age = _number(profile['age']);
              final height = _number(profile['height']);
              final weight = _number(profile['weight']);

              final validHeight =
                  height != null && height > 0 && height < 300;
              final validWeight =
                  weight != null && weight > 0 && weight < 700;

              final bmi = validHeight && validWeight
                  ? weight! /
                      ((height! / 100) * (height / 100))
                  : null;

              final heartRate =
                  _latestReading(readings, 'heartRate');
              final bloodPressure =
                  _latestReading(readings, 'bloodPressure');
              final bloodSugar =
                  _latestReading(readings, 'bloodSugar');

              final completedSections = [
                age != null && age > 0,
                bmi != null,
                heartRate != null,
                bloodPressure != null,
                bloodSugar != null,
              ].where((value) => value).length;

              final suggestions = _buildSuggestions(
                age: age,
                bmi: bmi,
                heartRate: heartRate,
                bloodPressure: bloodPressure,
                bloodSugar: bloodSugar,
              );

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF087F8C),
                          Color(0xFF07545B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hello, ${_displayName(profile['name'])}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your personal wellness overview, '
                          'based on the information you have recorded.',
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(
                              Icons.dataset_rounded,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$completedSections of 5 '
                                'assessment sections have data',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: completedSections / 5,
                            minHeight: 7,
                            backgroundColor:
                                Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Your health snapshot',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: assessmentDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          icon: Icons.monitor_weight_outlined,
                          title: 'BMI',
                          value: bmi == null
                              ? '—'
                              : bmi.toStringAsFixed(1),
                          subtitle: bmi == null
                              ? 'Add height & weight'
                              : _bmiLabel(bmi, age),
                          color: const Color(0xFF6184DB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          icon: Icons.favorite_rounded,
                          title: 'Heart rate',
                          value: heartRate == null
                              ? '—'
                              : _displayValue(heartRate),
                          subtitle: heartRate == null
                              ? 'No reading yet'
                              : _readingDate(heartRate),
                          color: const Color(0xFFE46C79),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _readingCard(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Blood pressure',
                    reading: bloodPressure,
                    unit: 'mmHg',
                    color: const Color(0xFFDF9151),
                  ),
                  const SizedBox(height: 12),
                  _readingCard(
                    icon: Icons.water_drop_rounded,
                    title: 'Blood sugar',
                    reading: bloodSugar,
                    unit: 'mg/dL',
                    color: const Color(0xFF6184DB),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Personalized wellness suggestions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: assessmentDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Suggestions are educational and based on '
                    'the profile and readings currently available.',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  ...suggestions.map(
                    (suggestion) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: _suggestionCard(
                        icon: suggestion.icon,
                        title: suggestion.title,
                        description:
                            suggestion.description,
                        color: suggestion.color,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF07545B),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This feature provides wellness '
                            'education, not a diagnosis or '
                            'medical risk prediction. BMI is a '
                            'screening measure, and a single '
                            'reading cannot establish a health '
                            'condition. Blood sugar interpretation '
                            'depends on when and how it was measured. '
                            'Discuss concerns with a qualified '
                            'healthcare professional.',
                            style: TextStyle(
                              color: Color(0xFF07545B),
                              height: 1.6,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static String _displayName(dynamic value) {
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'there' : name;
  }

  static Map<String, dynamic>? _latestReading(
    List<Map<String, dynamic>> readings,
    String type,
  ) {
    for (final reading in readings) {
      if (reading['type'] == type &&
          reading['value'] is num) {
        return reading;
      }
    }
    return null;
  }

  static String _displayValue(
    Map<String, dynamic> reading,
  ) {
    return reading['displayValue']?.toString() ??
        reading['value'].toString();
  }

  static String _readingDate(
    Map<String, dynamic> reading,
  ) {
    final timestamp = reading['recordedAt'];

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Date unavailable';
  }

  static String _bmiLabel(double bmi, double? age) {
    if (age != null && age < 20) {
      return 'Adult ranges not applicable';
    }

    if (bmi < 18.5) return 'Below adult reference range';
    if (bmi < 25) return 'Within adult reference range';
    if (bmi < 30) return 'Above adult reference range';
    return 'Higher adult BMI range';
  }

  static List<_Suggestion> _buildSuggestions({
    required double? age,
    required double? bmi,
    required Map<String, dynamic>? heartRate,
    required Map<String, dynamic>? bloodPressure,
    required Map<String, dynamic>? bloodSugar,
  }) {
    final suggestions = <_Suggestion>[];

    if (age == null || age <= 0) {
      suggestions.add(
        _Suggestion(
          Icons.person_outline_rounded,
          'Complete your health profile',
          'Add your age to make your wellness overview '
              'more informative.',
          const Color(0xFF6184DB),
        ),
      );
    }

    if (bmi == null) {
      suggestions.add(
        _Suggestion(
          Icons.monitor_weight_outlined,
          'Add height and weight',
          'Your profile needs valid height and weight '
              'measurements before BMI can be calculated.',
          const Color(0xFF6184DB),
        ),
      );
    } else if (age != null && age >= 20) {
      if (bmi < 18.5) {
        suggestions.add(
          _Suggestion(
            Icons.restaurant_outlined,
            'Review your nutrition',
            'Your BMI is below the commonly used adult '
                'reference range. Consider discussing your '
                'nutrition and weight history with a clinician.',
            const Color(0xFFDF9151),
          ),
        );
      } else if (bmi >= 25) {
        suggestions.add(
          _Suggestion(
            Icons.directions_walk_rounded,
            'Build sustainable habits',
            'Your BMI is above the commonly used adult '
                'reference range. BMI alone does not determine '
                'health; consider your overall health and '
                'discuss concerns with a clinician.',
            const Color(0xFF087F8C),
          ),
        );
      } else {
        suggestions.add(
          _Suggestion(
            Icons.eco_outlined,
            'Maintain balanced routines',
            'Continue focusing on balanced meals, regular '
                'movement, sleep and consistent health tracking.',
            const Color(0xFF087F8C),
          ),
        );
      }
    } else if (bmi != null) {
      suggestions.add(
        _Suggestion(
          Icons.info_outline_rounded,
          'Interpret BMI by age',
          'Adult BMI categories are not intended for children '
              'and teenagers. Ask a qualified healthcare '
              'professional about age-appropriate assessment.',
          const Color(0xFF6184DB),
        ),
      );
    }

    if (heartRate == null) {
      suggestions.add(
        _Suggestion(
          Icons.favorite_border_rounded,
          'Record your heart rate',
          'Add a measurement when appropriate and note the '
              'circumstances, such as whether you were resting '
              'or had recently exercised.',
          const Color(0xFFE46C79),
        ),
      );
    }

    if (bloodPressure == null) {
      suggestions.add(
        _Suggestion(
          Icons.monitor_heart_outlined,
          'Track blood pressure',
          'Record blood pressure with both systolic and '
              'diastolic values. Consistent measurement '
              'conditions make comparisons more useful.',
          const Color(0xFFDF9151),
        ),
      );
    }

    if (bloodSugar == null) {
      suggestions.add(
        _Suggestion(
          Icons.water_drop_outlined,
          'Add a blood sugar reading',
          'If you monitor blood sugar, record the value and '
              'whether it was fasting or taken after a meal. '
              'Interpret it using appropriate clinical guidance.',
          const Color(0xFF6184DB),
        ),
      );
    }

    if (heartRate != null ||
        bloodPressure != null ||
        bloodSugar != null) {
      suggestions.add(
        _Suggestion(
          Icons.calendar_month_rounded,
          'Keep your records up to date',
          'Record measurements consistently and compare '
              'readings taken under similar conditions. '
              'Repeated or concerning results deserve '
              'professional review.',
          const Color(0xFF087F8C),
        ),
      );
    }

    return suggestions;
  }

  static Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECF0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: assessmentDark,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _readingCard({
    required IconData icon,
    required String title,
    required Map<String, dynamic>? reading,
    required String unit,
    required Color color,
  }) {
    final value = reading == null
        ? 'No reading recorded'
        : '${_displayValue(reading)} $unit';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECF0F3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: assessmentDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: assessmentDark,
                  ),
                ),
                if (reading != null)
                  Text(
                    'Recorded: ${_readingDate(reading)}',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _suggestionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECF0F3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: assessmentDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    height: 1.5,
                    fontSize: 12,
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

class _Suggestion {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Suggestion(
    this.icon,
    this.title,
    this.description,
    this.color,
  );
}
