import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/features/organization/providers/permissions_provider.dart';

void main() {
  group('Permissions & RBAC Unit Tests', () {
    test('Permissions constants and human-readable formatting', () {
      expect(Permissions.label(Permissions.approveTransaction), equals('Approve Transactions'));
      expect(Permissions.label(Permissions.addTransaction), equals('Add Transactions'));
      expect(Permissions.label(Permissions.editTransaction), equals('Edit Transactions'));
      expect(Permissions.label(Permissions.voidTransaction), equals('Void / Delete Transactions'));
      expect(Permissions.label(Permissions.manageMembers), equals('Manage Members & Roles'));
      expect(Permissions.label(Permissions.viewReports), equals('View Reports'));

      expect(Permissions.icon(Permissions.approveTransaction), equals('✅'));
      expect(Permissions.icon(Permissions.addTransaction), equals('➕'));
      expect(Permissions.icon(Permissions.manageMembers), equals('👥'));
    });

    test('UserPermissions model getters for Owner', () {
      final ownerPerms = UserPermissions(
        role: 'owner',
        permissions: Set.from(Permissions.all),
        isOrgCreator: true,
      );

      expect(ownerPerms.isOwner, isTrue);
      expect(ownerPerms.canApproveTransactions, isTrue);
      expect(ownerPerms.canAddTransactions, isTrue);
      expect(ownerPerms.canEditTransactions, isTrue);
      expect(ownerPerms.canVoidTransactions, isTrue);
      expect(ownerPerms.canManageMembers, isTrue);
      expect(ownerPerms.canManagePermissions, isTrue);
      expect(ownerPerms.canEditOrgSettings, isTrue);
      expect(ownerPerms.canViewAuditLogs, isTrue);
      expect(ownerPerms.canViewReports, isTrue);
      expect(ownerPerms.canExportData, isTrue);
    });

    test('UserPermissions model getters for Member without approval override', () {
      final memberPerms = UserPermissions(
        role: 'member',
        permissions: {Permissions.addTransaction, Permissions.viewReports},
        isOrgCreator: false,
      );

      expect(memberPerms.isOwner, isFalse);
      expect(memberPerms.canAddTransactions, isTrue);
      expect(memberPerms.canViewReports, isTrue);
      expect(memberPerms.canApproveTransactions, isFalse);
      expect(memberPerms.canManageMembers, isFalse);
    });

    test('UserPermissions model for Member WITH explicit approval override', () {
      final memberWithApproval = UserPermissions(
        role: 'member',
        permissions: {
          Permissions.addTransaction,
          Permissions.viewReports,
          Permissions.approveTransaction,
        },
        isOrgCreator: false,
      );

      expect(memberWithApproval.isOwner, isFalse);
      expect(memberWithApproval.canAddTransactions, isTrue);
      expect(memberWithApproval.canApproveTransactions, isTrue);
    });
  });
}
