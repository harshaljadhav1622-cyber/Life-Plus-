import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'notification_service.dart';

const Color reminderTeal = Color(0xFF087F8C);
const Color reminderBackground = Color(0xFFF5F8FA);
const Color reminderDark = Color(0xFF172B36);

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _remindersRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reminders');

  Future<void> _addReminder() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedType = 'Medicine';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine or checkup name',
                        hintText: 'e.g. Vitamin tablet',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Reminder type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Medicine',
                          child: Text('Medicine'),
                        ),
                        DropdownMenuItem(
                          value: 'Checkup',
                          child: Text('Doctor checkup'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month,
                        color: reminderTeal,
                      ),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')}/'
                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                        '${selectedDate.year}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time,
                        color: reminderTeal,
                      ),
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: reminderTeal),
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a reminder name.'),
                        ),
                      );
                      return;
                    }

                    final reminderDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (reminderDateTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a future date and time.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final reminderRef = _remindersRef.doc();

                      await reminderRef.set({
                        'title': title,
                        'notes': notesController.text.trim(),
                        'type': selectedType,
                        'reminderAt': Timestamp.fromDate(reminderDateTime),
                        'isCompleted': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // Schedule a local notification on Android.
                      try {
                        await NotificationService.scheduleReminder(
                          reminderId: reminderRef.id,
                          title: title,
                          type: selectedType,
                          reminderAt: reminderDateTime,
                        );
                      } catch (notificationError) {
                        debugPrint(
                          'Notification scheduling failed: $notificationError',
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder saved successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Could not save reminder: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    notesController.dispose();
  }

  Future<void> _toggleCompleted(String reminderId, bool isCompleted) async {
    try {
      await _remindersRef.doc(reminderId).update({'isCompleted': !isCompleted});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update reminder: $e')));
    }
  }

  Future<void> _deleteReminder(String reminderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: const Text('This reminder will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _remindersRef.doc(reminderId).delete();

      try {
        await NotificationService.cancelReminder(reminderId);
      } catch (notificationError) {
        debugPrint('Notification cancellation failed: $notificationError');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete reminder: $e')));
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';

    final time = TimeOfDay.fromDateTime(dateTime).format(context);

    return '$date • $time';
  }

  Widget _buildReminderCard(String id, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Untitled reminder';
    final notes = data['notes'] as String? ?? '';
    final type = data['type'] as String? ?? 'Other';
    final isCompleted = data['isCompleted'] as bool? ?? false;

    final timestamp = data['reminderAt'] as Timestamp?;
    final reminderDate = timestamp?.toDate();

    final isPast =
        reminderDate != null &&
        reminderDate.isBefore(DateTime.now()) &&
        !isCompleted;

    final icon = type == 'Medicine'
        ? Icons.medication_outlined
        : type == 'Checkup'
        ? Icons.medical_services_outlined
        : Icons.notifications_none_rounded;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5ECEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isCompleted,
              activeColor: reminderTeal,
              onChanged: (_) => _toggleCompleted(id, isCompleted),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: reminderTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: reminderDark,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(
                      color: reminderTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (reminderDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(reminderDate),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(notes, style: const TextStyle(color: Colors.black54)),
                  ],
                  if (isPast)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Past due',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (isCompleted)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete reminder',
              onPressed: () => _deleteReminder(id),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view reminders.')),
      );
    }

    return Scaffold(
      backgroundColor: reminderBackground,
      appBar: AppBar(
        title: const Text(
          'My Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: reminderDark,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        backgroundColor: reminderTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _remindersRef
            .orderBy('reminderAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load reminders:\n${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: reminderTeal),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      size: 72,
                      color: reminderTeal,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No reminders yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: reminderDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a medicine or checkup reminder to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _addReminder,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Reminder'),
                      style: FilledButton.styleFrom(
                        backgroundColor: reminderTeal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final pending = documents
              .where((doc) => doc.data()['isCompleted'] != true)
              .toList();

          final completed = documents
              .where((doc) => doc.data()['isCompleted'] == true)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              Text(
                'Upcoming & Pending (${pending.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: reminderDark,
                ),
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text('No pending reminders.'),
                )
              else
                ...pending.map((doc) => _buildReminderCard(doc.id, doc.data())),
              const SizedBox(height: 12),
              Text(
                'Completed (${completed.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: reminderDark,
                ),
              ),
              const SizedBox(height: 12),
              if (completed.isEmpty)
                const Text('Completed reminders will appear here.')
              else
                ...completed.map(
                  (doc) => _buildReminderCard(doc.id, doc.data()),
                ),
            ],
          );
        },
      ),
    );
  }
}
