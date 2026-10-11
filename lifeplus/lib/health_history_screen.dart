
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const Color historyTeal = Color(0xFF087F8C);
const Color historyBackground = Color(0xFFF5F8FA);

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() =>
      _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  String selectedMetric = 'heartRate';

  final Map<String, String> metricNames = {
    'heartRate': 'Heart Rate',
    'bloodPressure': 'Blood Pressure',
    'bloodSugar': 'Blood Sugar',
  };

  final Map<String, String> metricUnits = {
    'heartRate': 'bpm',
    'bloodPressure': 'mmHg',
    'bloodSugar': 'mg/dL',
  };

  CollectionReference<Map<String, dynamic>> get historyCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('health_readings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: historyBackground,
      appBar: AppBar(
        title: const Text(
          'Health History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172B36),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: historyCollection
            .orderBy('recordedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load health history.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: historyTeal),
            );
          }

          final allReadings = snapshot.data?.docs ?? [];

          final readings = allReadings.where((doc) {
            return doc.data()['type'] == selectedMetric;
          }).toList();

          // The chart displays the 7 most recent readings,
          // ordered from oldest to newest.
          final chartReadings = readings.take(7).toList().reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Track your progress',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B36),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review your recorded measurements over time.',
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 20),

              // Metric selector
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metricNames.entries.map((entry) {
                  final isSelected = selectedMetric == entry.key;

                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: const Color(0xFFD8F2EE),
                    onSelected: (_) {
                      setState(() {
                        selectedMetric = entry.key;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Chart card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metricNames[selectedMetric]} trend',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last ${chartReadings.length} recorded readings',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 210,
                      child: chartReadings.isEmpty
                          ? const Center(
                              child: Text(
                                'No readings yet.\nAdd a reading from your dashboard.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                minY: 0,
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();

                                        if (index < 0 ||
                                            index >= chartReadings.length) {
                                          return const SizedBox.shrink();
                                        }

                                        final timestamp =
                                            chartReadings[index]
                                                .data()['recordedAt'];

                                        String label = '';

                                        if (timestamp is Timestamp) {
                                          final date = timestamp.toDate();
                                          label =
                                              '${date.day}/${date.month}';
                                        }

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    isCurved: true,
                                    color: historyTeal,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: historyTeal.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    spots: chartReadings
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final data = entry.value.data();
                                      final value = data['value'];

                                      return FlSpot(
                                        entry.key.toDouble(),
                                        (value as num).toDouble(),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (selectedMetric == 'bloodPressure')
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Blood pressure chart uses systolic '
                          '(upper) values. Both numbers appear in history.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Previous readings',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (readings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Your saved readings will appear here.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...readings.map((doc) {
                  final data = doc.data();
                  final timestamp = data['recordedAt'];

                  String dateLabel = 'Date unavailable';

                  if (timestamp is Timestamp) {
                    final date = timestamp.toDate();
                    dateLabel =
                        '${date.day}/${date.month}/${date.year} '
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.monitor_heart_outlined,
                            color: historyTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metricNames[selectedMetric]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${data['displayValue'] ?? data['value']} '
                          '${data['unit'] ?? metricUnits[selectedMetric]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
