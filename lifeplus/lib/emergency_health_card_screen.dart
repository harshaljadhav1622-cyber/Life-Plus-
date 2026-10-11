import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lifeplus/emergency_qr_scanner_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

const Color emergencyTeal = Color(0xFF087F8C);
const Color emergencyBackground = Color(0xFFF5F8FA);

class EmergencyHealthCardScreen extends StatefulWidget {
  const EmergencyHealthCardScreen({super.key});

  @override
  State<EmergencyHealthCardScreen> createState() =>
      _EmergencyHealthCardScreenState();
}

class _EmergencyHealthCardScreenState extends State<EmergencyHealthCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicinesController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  // Users choose which fields will be included in the QR code.
  final Map<String, bool> _includeInQr = {
    'Name': true,
    'Blood group': true,
    'Allergies': true,
    'Medical conditions': true,
    'Current medicines': false,
    'Emergency contact': true,
  };

  DocumentReference<Map<String, dynamic>>? get _cardRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('emergency_card')
        .doc('details');
  }

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final ref = _cardRef;

      if (ref == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};

        _nameController.text = data['name']?.toString() ?? '';
        _bloodGroupController.text = data['bloodGroup']?.toString() ?? '';
        _allergiesController.text = data['allergies']?.toString() ?? '';
        _conditionsController.text = data['conditions']?.toString() ?? '';
        _medicinesController.text = data['medicines']?.toString() ?? '';
        _contactNameController.text = data['contactName']?.toString() ?? '';
        _contactPhoneController.text = data['contactPhone']?.toString() ?? '';

        final savedSelection = data['includeInQr'];
        if (savedSelection is Map) {
          for (final key in _includeInQr.keys) {
            final value = savedSelection[key];
            if (value is bool) {
              _includeInQr[key] = value;
            }
          }
        }
      } else {
        // Use the name already saved in the user's profile, if available.
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final profile = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          _nameController.text = profile.data()?['name']?.toString() ?? '';
        }
      }
    } catch (e) {
      _showMessage('Could not load your emergency card.');
      debugPrint('Emergency card load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final ref = _cardRef;
    if (ref == null) {
      _showMessage('Please log in again.');
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.set({
        'name': _nameController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'conditions': _conditionsController.text.trim(),
        'medicines': _medicinesController.text.trim(),
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'includeInQr': Map<String, bool>.from(_includeInQr),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {});
      _showMessage('Emergency health card saved!');
    } catch (e) {
      debugPrint('Emergency card save error: $e');
      _showMessage('Could not save the card. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _buildQrText() {
    final fields = <String>[];

    void addField(String label, String value, String key) {
      if (_includeInQr[key] == true && value.trim().isNotEmpty) {
        fields.add('$label: ${value.trim()}');
      }
    }

    addField('Name', _nameController.text, 'Name');
    addField('Blood group', _bloodGroupController.text, 'Blood group');
    addField('Allergies', _allergiesController.text, 'Allergies');
    addField(
      'Medical conditions',
      _conditionsController.text,
      'Medical conditions',
    );
    addField(
      'Current medicines',
      _medicinesController.text,
      'Current medicines',
    );

    if (_includeInQr['Emergency contact'] == true) {
      final contactName = _contactNameController.text.trim();
      final contactPhone = _contactPhoneController.text.trim();

      if (contactName.isNotEmpty || contactPhone.isNotEmpty) {
        fields.add(
          'Emergency contact: '
          '${contactName.isEmpty ? "Not provided" : contactName}'
          '${contactPhone.isEmpty ? "" : " - $contactPhone"}',
        );
      }
    }

    return 'LIFEPLUS EMERGENCY HEALTH CARD\n'
        '${fields.join('\n')}\n'
        'Please contact a healthcare professional for medical care.';
  }

  bool get _hasMedicalDetails {
    return (_includeInQr['Name'] == true &&
            _nameController.text.trim().isNotEmpty) ||
        (_includeInQr['Blood group'] == true &&
            _bloodGroupController.text.trim().isNotEmpty) ||
        (_includeInQr['Allergies'] == true &&
            _allergiesController.text.trim().isNotEmpty) ||
        (_includeInQr['Medical conditions'] == true &&
            _conditionsController.text.trim().isNotEmpty) ||
        (_includeInQr['Current medicines'] == true &&
            _medicinesController.text.trim().isNotEmpty) ||
        (_includeInQr['Emergency contact'] == true &&
            (_contactNameController.text.trim().isNotEmpty ||
                _contactPhoneController.text.trim().isNotEmpty));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicinesController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final qrText = _buildQrText();

    return Scaffold(
      backgroundColor: emergencyBackground,
      appBar: AppBar(
        title: const Text('Emergency Health Card'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172B36),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: emergencyTeal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Be prepared for emergencies.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Save essential medical details and create a QR '
                            'card that can be scanned without internet.',
                            style: TextStyle(color: Colors.white, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Medical information',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _nameController,
                      'Full name',
                      icon: Icons.person_outline,
                    ),
                    _field(
                      _bloodGroupController,
                      'Blood group',
                      hint: 'e.g. B+',
                      icon: Icons.bloodtype_outlined,
                    ),
                    _field(
                      _allergiesController,
                      'Allergies',
                      hint: 'e.g. Penicillin, or None known',
                      icon: Icons.warning_amber_rounded,
                      maxLines: 2,
                    ),
                    _field(
                      _conditionsController,
                      'Medical conditions',
                      hint: 'Optional',
                      icon: Icons.medical_information_outlined,
                      maxLines: 2,
                    ),
                    _field(
                      _medicinesController,
                      'Current medicines',
                      hint: 'Optional',
                      icon: Icons.medication_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency contact',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _contactNameController,
                      'Contact person name',
                      icon: Icons.contact_phone_outlined,
                    ),
                    _field(
                      _contactPhoneController,
                      'Contact phone number',
                      hint: 'Include country code if possible',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveCard,
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving ? 'Saving...' : 'Save emergency details',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: emergencyTeal,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 14),
                    const Text(
                      'Emergency QR Card',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose which details you want to share when someone '
                      'scans your QR code.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    ..._includeInQr.keys.map((key) {
                      return CheckboxListTile(
                        value: _includeInQr[key],
                        activeColor: emergencyTeal,
                        contentPadding: EdgeInsets.zero,
                        title: Text(key),
                        onChanged: (value) {
                          setState(() => _includeInQr[key] = value ?? false);
                        },
                      );
                    }),
                    const SizedBox(height: 12),

                    // Always render the QR area. The previous version hid the
                    // entire QR card unless enough newline-separated fields
                    // existed, which could make the QR seem to be missing.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFDCE8E8),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'LIFEPLUS',
                            style: TextStyle(
                              color: emergencyTeal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          QrImageView(
                            data: qrText,
                            version: QrVersions.auto,
                            size: 250,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Scan with the LifePlus scanner or a compatible '
                            'QR reader.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          if (!_hasMedicalDetails)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Add at least one medical detail above. '
                                'The QR is visible, but currently contains '
                                'no personal medical details.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.deepOrange),
                              ),
                            ),
                          SelectableText(
                            qrText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EmergencyQrScannerScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan Emergency QR'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3DC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Privacy warning: anyone who scans this QR can read '
                        'the information encoded in it. Do not include details '
                        'you do not want to share. Save your details before '
                        'leaving this screen. This QR contains text; it does '
                        'not open an online webpage.',
                        style: TextStyle(height: 1.5, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        // Rebuild the QR immediately as the user edits the text.
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
