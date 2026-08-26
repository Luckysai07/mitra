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
}

/// Provider for all transactions of the currently active organization.
final orgTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  if (activeOrg == null) return [];

  try {
    final response = await SupabaseService.client
        .from('transactions')
        .select()
        .eq('org_id', activeOrg.id)
        .order('date', ascending: false);

    return (response as List).map((row) => TransactionModel.fromMap(row as Map<String, dynamic>)).toList();
  } catch (e) {
    return [];
  }
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

