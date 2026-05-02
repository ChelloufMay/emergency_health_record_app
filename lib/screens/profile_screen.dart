import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;

  // one controller per text field
  final _firstNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  // use dropdowns/pickers instead of free text
  String _selectedSex = 'unknown';
  DateTime? _selectedDOB;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // need the app-level user id (from public.users), not the auth id, because patient_profiles.user_id references public.users
  String? _appUserId;

  // tracks whether we insert or update on save
  bool _profileExists = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final authId = _supabase.auth.currentUser?.id;

      // if no auth session, send back to login instead of freezing
      if (authId == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }

      // get the row from public.users using the auth id
      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (userRow == null) {
        setState(() => _errorMessage = 'User profile not found. Please log out and register again.');
        return;
      }

      _appUserId = userRow['id'] as String;

      // check if a patient profile already exists for this user
      final profileRow = await _supabase
          .from('patient_profiles')
          .select()
          .eq('user_id', _appUserId!)
          .maybeSingle();

      if (profileRow != null) {
        // profile exists --> fill the form with the saved data
        _profileExists = true;
        _firstNameController.text = profileRow['first_name'] ?? '';
        _familyNameController.text = profileRow['family_name'] ?? '';
        _bloodTypeController.text = profileRow['blood_type'] ?? '';
        _emergencyContactNameController.text =
            profileRow['emergency_contact_name'] ?? '';
        _emergencyContactPhoneController.text =
            profileRow['emergency_contact_phone'] ?? '';
        _selectedSex = profileRow['sex'] ?? 'unknown';

        // use .toString() before parsing to avoid type errors because Supabase may return date columns as String or as dynamic
        final dobValue = profileRow['date_of_birth'];
        if (dobValue != null) {
          _selectedDOB = DateTime.tryParse(dobValue.toString());
        }
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Failed to load profile: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error while loading profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // opens the system date picker and stores the picked date
  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDOB = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _familyNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'First name and family name are required.');
      return;
    }

    if (_appUserId == null) {
      setState(() => _errorMessage =
      'User session not found. Please log out and back in.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // date is stored as YYYY-MM-DD string in Postgres
    final profileData = {
      'user_id': _appUserId,
      'first_name': _firstNameController.text.trim(),
      'family_name': _familyNameController.text.trim(),
      'blood_type': _bloodTypeController.text.trim().isEmpty
          ? null
          : _bloodTypeController.text.trim(),
      'sex': _selectedSex,
      'date_of_birth': _selectedDOB?.toIso8601String().split('T').first,
      'emergency_contact_name':
      _emergencyContactNameController.text.trim().isEmpty
          ? null
          : _emergencyContactNameController.text.trim(),
      'emergency_contact_phone':
      _emergencyContactPhoneController.text.trim().isEmpty
          ? null
          : _emergencyContactPhoneController.text.trim(),
    };

    try {
      if (_profileExists) {
        // profile already exists --> update the existing row
        await _supabase
            .from('patient_profiles')
            .update(profileData)
            .eq('user_id', _appUserId!);
      } else {
        // first time --> insert a new row
        await _supabase.from('patient_profiles').insert(profileData);
        _profileExists = true;
      }

      setState(() => _successMessage = 'Profile saved successfully.');
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = 'Database error: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong while saving.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _familyNameController.dispose();
    _bloodTypeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // show a spinner while loading the existing profile from Supabase
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Personal information ----------------------------
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'First Name *'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _familyNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Family Name *'),
            ),
            const SizedBox(height: 16),

            // maps directly to the sex_type enum in the database
            DropdownButtonFormField<String>(
              value: _selectedSex,
              decoration: const InputDecoration(labelText: 'Sex'),
              items: const [
                DropdownMenuItem(value: 'unknown', child: Text('Prefer not to say')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedSex = value);
              },
            ),
            const SizedBox(height: 16),

            // date picker instead of free text to avoid format errors
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDOB == null
                        ? 'Date of Birth: not set'
                        : 'Date of Birth: ${_selectedDOB!.toIso8601String().split('T').first}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: _pickDateOfBirth,
                  child: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(
                labelText: 'Blood Type',
                hintText: 'e.g. O+, A-, B+',
              ),
            ),
            const Divider(height: 40),

            // Emergency contact ----------------------------
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emergencyContactNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emergencyContactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
            ),
            const SizedBox(height: 32),

            // Feedback messages ----------------------------
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            if (_successMessage != null) ...[
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            // Save button ----------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}