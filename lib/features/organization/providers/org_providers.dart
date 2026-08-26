import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';

/// Representation of an Organization model.
class OrganizationModel {
  final String id;
  final String name;
  final String orgType;
  final String? description;
  final String? location;
  final String? logoUrl;
  final String joinCode;
  final String createdBy;
  final DateTime createdAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.orgType,
    this.description,
    this.location,
    this.logoUrl,
    required this.joinCode,
    required this.createdBy,
    required this.createdAt,
  });

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Committee',
      orgType: map['org_type'] ?? 'general',
      description: map['description'] as String?,
      location: map['location'] as String?,
      logoUrl: map['logo_url'] as String?,
      joinCode: map['join_code'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}

/// Provider for the list of all organizations created by or joined by the current user.
final userOrganizationsProvider = FutureProvider<List<OrganizationModel>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final Map<String, OrganizationModel> orgMap = {};

  // 1. Direct query: All organizations created by this user
  try {
    final createdResponse = await SupabaseService.client
        .from('organizations')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);

    for (final row in (createdResponse as List)) {
      final org = OrganizationModel.fromMap(row as Map<String, dynamic>);
      orgMap[org.id] = org;
    }
  } catch (_) {}

  // 2. Member query: All organizations where current user is a member
  try {
    final membersResponse = await SupabaseService.client
        .from('organization_members')
        .select('org_id, organizations(*)')
        .eq('user_id', user.id);

    for (final row in (membersResponse as List)) {
      if (row['organizations'] != null) {
        final org = OrganizationModel.fromMap(row['organizations'] as Map<String, dynamic>);
        orgMap[org.id] = org;
      }
    }
  } catch (_) {}

  // 3. Fallback query: All active organizations if user has authenticated role
  if (orgMap.isEmpty) {
    try {
      final allOrgs = await SupabaseService.client
          .from('organizations')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      for (final row in (allOrgs as List)) {
        final org = OrganizationModel.fromMap(row as Map<String, dynamic>);
        orgMap[org.id] = org;
      }
    } catch (_) {}
  }

  final list = orgMap.values.toList();
  return list;
});

/// StateNotifier for the currently selected active Organization.
class ActiveOrgNotifier extends StateNotifier<OrganizationModel?> {
  ActiveOrgNotifier() : super(null);

  void setActiveOrg(OrganizationModel org) {
    state = org;
  }

  void clear() {
    state = null;
  }
}

/// Provider for the active organization.
final activeOrgProvider = StateNotifierProvider<ActiveOrgNotifier, OrganizationModel?>((ref) {
  return ActiveOrgNotifier();
});
