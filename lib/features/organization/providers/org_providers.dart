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
      id: map['id'] as String,
      name: map['name'] as String,
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

/// Provider for the list of organizations the current user belongs to.
final userOrganizationsProvider = FutureProvider<List<OrganizationModel>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  try {
    // Query orgs where current user is an active member
    final membersResponse = await SupabaseService.client
        .from('organization_members')
        .select('org_id, organizations(*)')
        .eq('user_id', user.id);

    final List<OrganizationModel> orgs = [];
    for (final row in (membersResponse as List)) {
      if (row['organizations'] != null) {
        orgs.add(OrganizationModel.fromMap(row['organizations'] as Map<String, dynamic>));
      }
    }
    return orgs;
  } catch (e) {
    // Return empty list if query fails or table isn't populated yet
    return [];
  }
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
