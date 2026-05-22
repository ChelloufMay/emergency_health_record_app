import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/guardian_profile_model.dart';
import '../services/guardian_profile_service.dart';

class GuardianProfileScreen extends StatefulWidget {
  const GuardianProfileScreen({super.key});

  @override
  State<GuardianProfileScreen> createState() => _GuardianProfileScreenState();
}

class _GuardianProfileScreenState extends State<GuardianProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GuardianProfileService _service = GuardianProfileService();

  final _fullNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _legalAuthorityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  final _countryController = TextEditingController();
  final _governorateController = TextEditingController();
  final _cityController = TextEditingController();
  final _avenueController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _extraDetailsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _profileId;
  String? _addressId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _relationshipController.dispose();
    _legalAuthorityController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _countryController.dispose();
    _governorateController.dispose();
    _cityController.dispose();
    _avenueController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _extraDetailsController.dispose();
    super.dispose();
  }

  Future<String?> _currentAppUserId() async {
    final value = await _supabase.rpc('current_app_user_id');
    return value?.toString();
  }

  Future<void> _load() async {
    final profile = await _service.fetchMine();

    if (profile != null) {
      _profileId = profile.id;
      _addressId = profile.addressId;
      _fullNameController.text = profile.fullName;
      _relationshipController.text = profile.relationshipToPatient ?? '';
      _legalAuthorityController.text = profile.legalAuthorityNote ?? '';
      _phoneController.text = profile.phone ?? '';
      _notesController.text = profile.notes ?? '';
    }

    if (_addressId != null) {
      final addressRow = await _supabase
          .from('addresses')
          .select()
          .eq('id', _addressId!)
          .maybeSingle();

      if (addressRow != null) {
        final address = Map<String, dynamic>.from(addressRow as Map);
        _countryController.text = address['country']?.toString() ?? '';
        _governorateController.text = address['governorate']?.toString() ?? '';
        _cityController.text = address['city']?.toString() ?? '';
        _avenueController.text = address['avenue']?.toString() ?? '';
        _streetController.text = address['street']?.toString() ?? '';
        _postalCodeController.text = address['postal_code']?.toString() ?? '';
        _extraDetailsController.text =
            address['extra_details']?.toString() ?? '';
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<String?> _saveAddress() async {
    final country = _countryController.text.trim();
    final hasAnyAddressData = [
      country,
      _governorateController.text.trim(),
      _cityController.text.trim(),
      _avenueController.text.trim(),
      _streetController.text.trim(),
      _postalCodeController.text.trim(),
      _extraDetailsController.text.trim(),
    ].any((value) => value.isNotEmpty);

    if (!hasAnyAddressData) {
      return _addressId;
    }

    if (country.isEmpty) {
      throw Exception('Country is required when saving an address');
    }

    final payload = <String, dynamic>{
      'country': country,
      'governorate': _governorateController.text.trim().isEmpty
          ? null
          : _governorateController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'avenue': _avenueController.text.trim().isEmpty
          ? null
          : _avenueController.text.trim(),
      'street': _streetController.text.trim().isEmpty
          ? null
          : _streetController.text.trim(),
      'postal_code': _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      'extra_details': _extraDetailsController.text.trim().isEmpty
          ? null
          : _extraDetailsController.text.trim(),
    };

    if (_addressId == null) {
      final inserted = await _supabase
          .from('addresses')
          .insert(payload)
          .select('id')
          .single();
      return inserted['id']?.toString();
    }

    await _supabase.from('addresses').update(payload).eq('id', _addressId!);
    return _addressId;
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final addressId = await _saveAddress();

      final appUserId = await _currentAppUserId();

      final model = GuardianProfileModel(
        id: _profileId,
        userId: appUserId ?? '',
        fullName: _fullNameController.text.trim(),
        relationshipToPatient: _relationshipController.text.trim().isEmpty
            ? null
            : _relationshipController.text.trim(),
        legalAuthorityNote: _legalAuthorityController.text.trim().isEmpty
            ? null
            : _legalAuthorityController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        addressId: addressId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      _profileId = await _service.saveMine(model);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guardian profile saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await _service.deleteMine();

      _profileId = null;
      _addressId = null;

      _fullNameController.clear();
      _relationshipController.clear();
      _legalAuthorityController.clear();
      _phoneController.clear();
      _notesController.clear();
      _countryController.clear();
      _governorateController.clear();
      _cityController.clear();
      _avenueController.clear();
      _streetController.clear();
      _postalCodeController.clear();
      _extraDetailsController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardian profile deleted.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian profile'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (_profileId != null)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // This screen mirrors public.guardian_profiles.
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship to patient',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _legalAuthorityController,
                  decoration: const InputDecoration(
                    labelText: 'Legal authority note',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const Divider(height: 32),
                const Text(
                  'Address',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _governorateController,
                  decoration: const InputDecoration(labelText: 'Governorate'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _avenueController,
                  decoration: const InputDecoration(labelText: 'Avenue'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Street'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(labelText: 'Postal code'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _extraDetailsController,
                  decoration: const InputDecoration(labelText: 'Extra details'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save guardian profile'),
                ),
              ],
            ),
    );
  }
}

