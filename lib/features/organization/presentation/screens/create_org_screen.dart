import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

/// Create Organization wizard screen connected directly to Supabase database.
class CreateOrgScreen extends ConsumerStatefulWidget {
  const CreateOrgScreen({super.key});

  @override
  ConsumerState<CreateOrgScreen> createState() => _CreateOrgScreenState();
}

class _CreateOrgScreenState extends ConsumerState<CreateOrgScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedType = 'ganesh_utsav';
  bool _isLoading = false;

  static const _orgTypes = {
    'ganesh_utsav': '🐘 Ganesh Utsav Committee',
    'durga_puja': '🪔 Durga Puja Committee',
    'general': '🏢 General Association',
    'youth_association': '⚡ Youth Association',
    'student_org': '🎓 Student Organization',
    'cultural_org': '🎨 Cultural Organization',
    'sports_club': '🏆 Sports & Youth Club',
    'apartment_assoc': '🏘️ Apartment Association',
    'charitable_org': '🤝 Charitable Organization',
    'religious_committee': '🕉️ Religious Committee',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to create an organization.'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      context.push(AppRoutes.login);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final joinCode = _generateJoinCode();
      final orgName = _nameController.text.trim();
      final slug = '${orgName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${joinCode.toLowerCase()}';

      // 1. Insert Organization record into Supabase
      final orgResponse = await SupabaseService.client
          .from('organizations')
          .insert({
            'name': orgName,
            'slug': slug,
            'org_type': _selectedType,
            'description': _descriptionController.text.trim(),
            'location': _locationController.text.trim(),
            'join_code': joinCode,
            'created_by': user.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orgId = orgResponse['id'] as String;

      // 2. Create default Admin role for this org in public.roles
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

      // 3. Insert creator as Admin in organization_members
      final memberPayload = <String, dynamic>{
        'org_id': orgId,
        'user_id': user.id,
        'role': 'owner',
        'status': 'active',
        'joined_at': DateTime.now().toIso8601String(),
      };
      if (roleId != null) {
        memberPayload['role_id'] = roleId;
      }

      await SupabaseService.client.from('organization_members').insert(memberPayload);

      // 4. Create default financial accounts
      try {
        await SupabaseService.client.from('financial_accounts').insert([
          {
            'org_id': orgId,
            'name': 'Cash Box',
            'account_type': 'cash',
            'is_default': true,
          },
          {
            'org_id': orgId,
            'name': 'Bank Account / UPI',
            'account_type': 'bank',
            'is_default': false,
          },
        ]);
      } catch (_) {}

      // 4. Update Riverpod Active Org state
      final createdOrg = OrganizationModel.fromMap(orgResponse as Map<String, dynamic>);
      ref.read(activeOrgProvider.notifier).setActiveOrg(createdOrg);
      ref.invalidate(userOrganizationsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Organization "$orgName" created! Code: $joinCode'),
          backgroundColor: AppColors.incomeLight,
          duration: const Duration(seconds: 4),
        ),
      );

      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create organization: ${e.toString()}'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Create Organization'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Banner ──
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.corporate_fare_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Your Digital Book',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Get an 8-character invite code & manage team funds',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Org Name ──
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    hintText: 'e.g., Sri Ganesh Youth Association',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Organization name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Org Type ──
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Organization / Festival Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _orgTypes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Description ──
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Brief summary of goals or celebration details',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Location ──
                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City / Location (optional)',
                    hintText: 'e.g., Hyderabad, Telangana',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Create Button ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Organization'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
