import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import 'org_providers.dart';

// ─────────────────────────────────────────────────────────────
// Permission Keys — all possible permission identifiers.
// ─────────────────────────────────────────────────────────────

abstract final class Permissions {
  static const String approveTransaction = 'approve_transaction';
  static const String addTransaction = 'add_transaction';
  static const String editTransaction = 'edit_transaction';
  static const String voidTransaction = 'void_transaction';
  static const String manageMembers = 'manage_members';
  static const String managePermissions = 'manage_permissions';
  static const String editOrgSettings = 'edit_org_settings';
  static const String viewAuditLogs = 'view_audit_logs';
  static const String viewReports = 'view_reports';
  static const String exportData = 'export_data';

  static const List<String> all = [
    approveTransaction,
    addTransaction,
    editTransaction,
    voidTransaction,
    manageMembers,
    managePermissions,
    editOrgSettings,
    viewAuditLogs,
    viewReports,
    exportData,
  ];

  /// Human-readable labels for permission keys.
  static String label(String key) {
    switch (key) {
      case approveTransaction:
        return 'Approve Transactions';
      case addTransaction:
        return 'Add Transactions';
      case editTransaction:
        return 'Edit Transactions';
      case voidTransaction:
        return 'Void / Delete Transactions';
      case manageMembers:
        return 'Manage Members & Roles';
      case managePermissions:
        return 'Manage Permission Settings';
      case editOrgSettings:
        return 'Edit Organization Settings';
      case viewAuditLogs:
        return 'View Audit Logs';
      case viewReports:
        return 'View Reports';
      case exportData:
        return 'Export Data (CSV/PDF)';
      default:
        return key;
    }
  }

  /// Icon for each permission.
  static String icon(String key) {
    switch (key) {
      case approveTransaction:
        return '✅';
      case addTransaction:
        return '➕';
      case editTransaction:
        return '✏️';
      case voidTransaction:
        return '🗑️';
      case manageMembers:
        return '👥';
      case managePermissions:
        return '🔐';
      case editOrgSettings:
        return '⚙️';
      case viewAuditLogs:
        return '📋';
      case viewReports:
        return '📊';
      case exportData:
        return '📤';
      default:
        return '🔑';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Member Role Model
// ─────────────────────────────────────────────────────────────

class MemberRole {
  final String memberId;
  final String userId;
  final String role;
  final String status;
  final String fullName;
  final String? email;
  final String? phone;
  final DateTime joinedAt;

  const MemberRole({
    required this.memberId,
    required this.userId,
    required this.role,
    required this.status,
    required this.fullName,
    this.email,
    this.phone,
    required this.joinedAt,
  });

  factory MemberRole.fromMap(Map<String, dynamic> map) {
    final userData = map['users'] as Map<String, dynamic>? ?? {};
    return MemberRole(
      memberId: map['id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'member',
      status: map['status'] as String? ?? 'active',
      fullName: userData['full_name'] as String? ?? 'Member',
      email: userData['email'] as String?,
      phone: userData['phone'] as String?,
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'])
          : DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// User Permissions State — holds current user's role & perms.
// ─────────────────────────────────────────────────────────────

class UserPermissions {
  final String role;
  final Set<String> permissions;
  final bool isOrgCreator;

  const UserPermissions({
    required this.role,
    required this.permissions,
    this.isOrgCreator = false,
  });

  static const empty = UserPermissions(
    role: 'viewer',
    permissions: {},
    isOrgCreator: false,
  );

  bool get isOwner => role == 'owner';
  bool get isPresident => role == 'president';
  bool get isTreasurer => role == 'treasurer';
  bool get isSecretary => role == 'secretary';
  bool get isAdmin => isOwner || isPresident;

  bool hasPermission(String permission) {
    // Owner always has all permissions
    if (isOwner) return true;
    return permissions.contains(permission);
  }

  bool get canApproveTransactions => hasPermission(Permissions.approveTransaction);
  bool get canAddTransactions => hasPermission(Permissions.addTransaction);
  bool get canEditTransactions => hasPermission(Permissions.editTransaction);
  bool get canVoidTransactions => hasPermission(Permissions.voidTransaction);
  bool get canManageMembers => hasPermission(Permissions.manageMembers);
  bool get canManagePermissions => hasPermission(Permissions.managePermissions);
  bool get canEditOrgSettings => hasPermission(Permissions.editOrgSettings);
  bool get canViewAuditLogs => hasPermission(Permissions.viewAuditLogs);
  bool get canViewReports => hasPermission(Permissions.viewReports);
  bool get canExportData => hasPermission(Permissions.exportData);
}

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Fetches the current user's role + permissions for the active org.
final userPermissionsProvider = FutureProvider<UserPermissions>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  final user = SupabaseService.currentUser;
  if (activeOrg == null || user == null) return UserPermissions.empty;

  try {
    // 1. Get user's membership record to determine their role
    final memberResponse = await SupabaseService.client
        .from('organization_members')
        .select('role, status')
        .eq('org_id', activeOrg.id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (memberResponse == null) return UserPermissions.empty;

    final role = memberResponse['role'] as String? ?? 'member';
    final status = memberResponse['status'] as String? ?? 'active';

    // Inactive/pending members get no permissions
    if (status != 'active') {
      return UserPermissions(
        role: role,
        permissions: {},
        isOrgCreator: activeOrg.createdBy == user.id,
      );
    }

    // 2. Get role-based permissions
    final permsResponse = await SupabaseService.client
        .from('role_permissions')
        .select('permission')
        .eq('org_id', activeOrg.id)
        .eq('role_name', role);

    final Set<String> perms = {};
    for (final row in (permsResponse as List)) {
      perms.add(row['permission'] as String);
    }

    // 3. Get individual permission overrides
    final overridesResponse = await SupabaseService.client
        .from('permission_overrides')
        .select('permission, is_granted')
        .eq('org_id', activeOrg.id)
        .eq('user_id', user.id);

    for (final row in (overridesResponse as List)) {
      final perm = row['permission'] as String;
      final isGranted = row['is_granted'] as bool? ?? true;
      if (isGranted) {
        perms.add(perm);
      } else {
        perms.remove(perm);
      }
    }

    return UserPermissions(
      role: role,
      permissions: perms,
      isOrgCreator: activeOrg.createdBy == user.id,
    );
  } catch (e) {
    // Fallback: if permissions tables don't exist yet, grant based on creator
    if (activeOrg.createdBy == user.id) {
      return UserPermissions(
        role: 'owner',
        permissions: Set.from(Permissions.all),
        isOrgCreator: true,
      );
    }
    return UserPermissions.empty;
  }
});

/// Fetches all members of the active org with their roles.
final orgMembersWithRolesProvider = FutureProvider<List<MemberRole>>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  if (activeOrg == null) return [];

  try {
    final response = await SupabaseService.client
        .from('organization_members')
        .select('id, user_id, role, status, joined_at, users(full_name, email, phone)')
        .eq('org_id', activeOrg.id)
        .order('joined_at', ascending: true);

    return (response as List)
        .map((row) => MemberRole.fromMap(row as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Fetches the role_permissions matrix for the active org.
/// Returns Map<roleName, Set<permission>>
final rolePermissionsMatrixProvider =
    FutureProvider<Map<String, Set<String>>>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  if (activeOrg == null) return {};

  try {
    final response = await SupabaseService.client
        .from('role_permissions')
        .select('role_name, permission')
        .eq('org_id', activeOrg.id);

    final Map<String, Set<String>> matrix = {};
    for (final row in (response as List)) {
      final role = row['role_name'] as String;
      final perm = row['permission'] as String;
      matrix.putIfAbsent(role, () => {}).add(perm);
    }
    return matrix;
  } catch (e) {
    return {};
  }
});

/// Fetches pending transactions count for badge display.
final pendingTransactionsCountProvider = FutureProvider<int>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  if (activeOrg == null) return 0;

  try {
    final response = await SupabaseService.client
        .from('transactions')
        .select('id')
        .eq('org_id', activeOrg.id)
        .eq('approval_status', 'pending');

    return (response as List).length;
  } catch (e) {
    return 0;
  }
});
