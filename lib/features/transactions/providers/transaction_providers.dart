import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../../organization/providers/org_providers.dart';

/// Transaction Model representing a financial entry in an organization.
class TransactionModel {
  final String id;
  final String orgId;
  final String txnNumber;
  final String type; // 'income' or 'expense'
  final int amountPaise;
  final DateTime date;
  final String? categoryId;
  final String? description;
  final String? personName;
  final String? personContact;
  final String paymentMethod; // 'cash', 'upi', 'bank', 'cheque'
  final String approvalStatus; // 'approved', 'pending', 'rejected'
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.orgId,
    required this.txnNumber,
    required this.type,
    required this.amountPaise,
    required this.date,
    this.categoryId,
    this.description,
    this.personName,
    this.personContact,
    required this.paymentMethod,
    this.approvalStatus = 'approved',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      orgId: map['org_id'] as String,
      txnNumber: map['txn_number'] ?? 'TXN-000',
      type: map['type'] as String,
      amountPaise: (map['amount_paise'] as num).toInt(),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      categoryId: map['category_id'] as String?,
      description: map['description'] as String?,
      personName: map['person_name'] as String?,
      personContact: map['person_contact'] as String?,
      paymentMethod: map['payment_method'] ?? 'cash',
      approvalStatus: map['approval_status'] as String? ?? 'approved',
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      rejectionReason: map['rejection_reason'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String? ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    );
  }

  TransactionModel copyWith({
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return TransactionModel(
      id: id,
      orgId: orgId,
      txnNumber: txnNumber,
      type: type,
      amountPaise: amountPaise,
      date: date,
      categoryId: categoryId,
      description: description,
      personName: personName,
      personContact: personContact,
      paymentMethod: paymentMethod,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

/// In-memory override map for transactions approved/rejected during current app session.
class ApprovalOverridesNotifier extends StateNotifier<Map<String, String>> {
  ApprovalOverridesNotifier() : super({});

  void markStatus(String txnId, String status) {
    state = {...state, txnId: status};
  }

  void clear() {
    state = {};
  }
}

/// Provider tracking session approval status overrides.
final approvalOverridesProvider =
    StateNotifierProvider<ApprovalOverridesNotifier, Map<String, String>>((ref) {
  return ApprovalOverridesNotifier();
});

/// Provider for all transactions of the currently active organization with session override protection.
final orgTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  final overrides = ref.watch(approvalOverridesProvider);
  if (activeOrg == null) return [];

  List<TransactionModel> txns = [];
  try {
    final response = await SupabaseService.client
        .from('transactions')
        .select()
        .eq('org_id', activeOrg.id)
        .order('date', ascending: false);

    txns = (response as List).map((row) => TransactionModel.fromMap(row as Map<String, dynamic>)).toList();
  } catch (e) {
    txns = [];
  }

  // Apply in-memory approval overrides so Net Balance and UI state update immediately
  if (overrides.isNotEmpty) {
    txns = txns.map((t) {
      if (overrides.containsKey(t.id)) {
        return t.copyWith(approvalStatus: overrides[t.id]);
      }
      return t;
    }).toList();
  }

  return txns;
});

/// Provider for ONLY APPROVED transactions (for ledger totals and dashboard calculations).
final approvedTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final txns = await ref.watch(orgTransactionsProvider.future);
  return txns.where((t) => t.approvalStatus == 'approved').toList();
});

/// Provider for ONLY PENDING transactions.
final pendingTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final txns = await ref.watch(orgTransactionsProvider.future);
  return txns.where((t) => t.approvalStatus == 'pending').toList();
});

