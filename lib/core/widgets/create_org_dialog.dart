import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

/// Modal dialog popup to create an Organization / Committee / Trust.
class CreateOrgDialog extends ConsumerStatefulWidget {
  const CreateOrgDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const CreateOrgDialog(),
    );
  }

  @override
  ConsumerState<CreateOrgDialog> createState() => _CreateOrgDialogState();
}

class _CreateOrgDialogState extends ConsumerState<CreateOrgDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedOrgType = 'Ganesh Utsav Committee';
  String _selectedEmojiLogo = '🐘';
  bool _isLoading = false;

  final List<String> _orgTypes = [
    'Ganesh Utsav Committee',
    'Diwali Dhamaka Trust',
    'Durga Puja Samiti',
    'Navratri Garba Club',
    'Housing Society Trust',
    'Sports & Youth Club',
    'Charitable Foundation',
    'Other Festival Group',
  ];

  final List<String> _logoEmojis = ['🐘', '🪔', '🚩', '🏆', '🕌', '🏛️', '🎉', '🌟', '☸️', '🏵️'];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final code = StringBuffer('MTR');
    for (int i = 0; i < 5; i++) {
      code.write(chars[int.parse(random[i % random.length]) % chars.length]);
    }
    return code.toString();
  }

  Future<void> _handleCreateOrg() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseService.currentUser;
    if (user == null) {
      Navigator.pop(context);
      context.push('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final joinCode = _generateJoinCode();
      final orgName = _nameController.text.trim();
      final slug = '${orgName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${joinCode.toLowerCase()}';

      // 1. Insert Organization into Supabase
      final orgResponse = await SupabaseService.client
          .from('organizations')
          .insert({
            'name': orgName,
            'slug': slug,
            'org_type': _selectedOrgType,
            'description': _descriptionController.text.trim(),
            'location': _locationController.text.trim(),
            'join_code': joinCode,
            'logo_url': _selectedEmojiLogo,
            'created_by': user.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orgId = orgResponse['id'] as String;

      // 2. Create default Admin role in public.roles
      String? roleId;
      try {
        final roleResponse = await SupabaseService.client
            .from('roles')
            .insert({
              'org_id': orgId,
              'name': 'admin',
              'display_name': 'Administrator',
              'is_system': true,
              'priority': 100,
            })
            .select('id')
            .single();
        roleId = roleResponse['id'] as String;
      } catch (_) {}

      // 3. Add creator to organization_members
      final memberMap = <String, dynamic>{
        'org_id': orgId,
        'user_id': user.id,
        'status': 'active',
        'joined_at': DateTime.now().toIso8601String(),
      };
      if (roleId != null) memberMap['role_id'] = roleId;
      await SupabaseService.client.from('organization_members').insert(memberMap);

      // 4. Create default financial accounts
      try {
        await SupabaseService.client.from('financial_accounts').insert([
          {'org_id': orgId, 'name': 'Cash Box', 'account_type': 'cash', 'is_default': true},
          {'org_id': orgId, 'name': 'Bank / UPI', 'account_type': 'bank', 'is_default': false},
        ]);
      } catch (_) {}

      // 5. Update Riverpod Active Org state & refresh
      final createdOrg = OrganizationModel.fromMap(orgResponse as Map<String, dynamic>);
      ref.read(activeOrgProvider.notifier).setActiveOrg(createdOrg);
      ref.invalidate(userOrganizationsProvider);

      if (!mounted) return;

      Navigator.pop(context); // Close modal dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 "${createdOrg.name}" created successfully! Invite Code: ${createdOrg.joinCode}'),
          backgroundColor: AppColors.income,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create organization: ${e.toString()}'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dialog Header Banner ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Organization / Trust',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Setup your digital ledger & invite team members',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Organization Name ──
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Organization / Committee Name *',
                    hintText: 'e.g. Bal Ganesh Utsav Samiti 2026',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter organization name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Logo Emoji Picker ──
                const Text('Select Organization Logo Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _logoEmojis.map((emoji) {
                    final isSelected = _selectedEmojiLogo == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmojiLogo = emoji),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Type Dropdown ──
                DropdownButtonFormField<String>(
                  value: _selectedOrgType,
                  decoration: const InputDecoration(
                    labelText: 'Type / Festival Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _orgTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedOrgType = val);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Location ──
                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Place / Location (City, Area)',
                    hintText: 'e.g. Dadar, Mumbai',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Description ──
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. Annual Ganesh Utsav celebration & community welfare',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Create Action Button ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateOrg,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('🚀 Create & Open Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
