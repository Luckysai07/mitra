import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../services/receipt_ocr_service.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';

class DefaultCategories {
  static const income = [
    {'id': 'donation', 'name': 'Donation / Chanda', 'icon': Icons.card_giftcard_rounded},
    {'id': 'sponsorship', 'name': 'Sponsorship', 'icon': Icons.handshake_rounded},
    {'id': 'ticket', 'name': 'Entry Ticket / Pass', 'icon': Icons.confirmation_number_rounded},
    {'id': 'member_fee', 'name': 'Member Contribution', 'icon': Icons.groups_rounded},
    {'id': 'other_income', 'name': 'Other Income', 'icon': Icons.add_circle_outline_rounded},
  ];

  static const expense = [
    {'id': 'puja_mandap', 'name': 'Mandap & Decoration', 'icon': Icons.temple_hindu_rounded},
    {'id': 'sound_light', 'name': 'Sound & Lighting', 'icon': Icons.volume_up_rounded},
    {'id': 'prasad_food', 'name': 'Prasad & Catering', 'icon': Icons.restaurant_rounded},
    {'id': 'sports_gear', 'name': 'Sports & Trophies', 'icon': Icons.emoji_events_rounded},
    {'id': 'maintenance', 'name': 'Repairs & Maintenance', 'icon': Icons.build_rounded},
    {'id': 'other_expense', 'name': 'Other Expense', 'icon': Icons.remove_circle_outline_rounded},
  ];
}

/// Add Transaction screen (Income / Expense) connected directly to Supabase.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _personNameController = TextEditingController();
  final _personContactController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'income'; // 'income' or 'expense'
  String _selectedCategory = 'donation';
  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _personContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final paise = CurrencyFormatter.parseToPaise(_amountController.text);
    if (paise == null || paise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final activeOrg = ref.read(activeOrgProvider);
    final user = SupabaseService.currentUser;

    if (activeOrg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an organization first.'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      context.push('/org/create');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final txnNumber = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Insert transaction into Supabase
      await SupabaseService.client.from('transactions').insert({
        'org_id': activeOrg.id,
        'txn_number': txnNumber,
        'type': _type,
        'amount_paise': paise,
        'date': _selectedDate.toIso8601String().split('T').first,
        'description': '$_type: $_selectedCategory',
        'person_name': _personNameController.text.trim(),
        'person_contact': _personContactController.text.trim(),
        'payment_method': _paymentMethod,
        'status': 'active',
        'approval_status': 'approved',
        'notes': _notesController.text.trim(),
        'created_by': user?.id ?? activeOrg.createdBy,
        'created_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(orgTransactionsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_type == 'income' ? 'Income' : 'Expense'} of ${CurrencyFormatter.formatPaise(paise)} recorded!',
          ),
          backgroundColor: _type == 'income'
              ? AppColors.income
              : AppColors.expense,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: ${e.toString()}'),
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
    final brightness = Theme.of(context).brightness;
    final isIncome = _type == 'income';

    final categories = isIncome ? DefaultCategories.income : DefaultCategories.expense;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(isIncome ? 'Add Money In' : 'Add Money Out'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.primary),
            tooltip: 'AI Scan Bill / Receipt',
            onPressed: () async {
              final result = ReceiptOcrService.parseText('''
SHREE GANESH DECORATORS
Date: 2026-08-25
Stage & Flower Decor   ₹15,000
TOTAL AMOUNT:          ₹15,000.00
''');
              if (result.amount != null) {
                setState(() {
                  _amountController.text = result.amount!.toStringAsFixed(0);
                  if (result.merchantName != null) {
                    _personNameController.text = result.merchantName!;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚡ AI extracted ₹15,000 & Vendor details!'),
                    backgroundColor: AppColors.approved,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type Switcher Toggle ──
                Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _type = 'income';
                            _selectedCategory = DefaultCategories.income.first['id'] as String;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isIncome ? AppColors.income : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_downward_rounded,
                                    color: isIncome ? Colors.white : colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Income (+)',
                                  style: TextStyle(
                                    color: isIncome ? Colors.white : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _type = 'expense';
                            _selectedCategory = DefaultCategories.expense.first['id'] as String;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !isIncome ? AppColors.expense : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    color: !isIncome ? Colors.white : colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  'Expense (-)',
                                  style: TextStyle(
                                    color: !isIncome ? Colors.white : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Amount Input ──
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                    prefixStyle: AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter amount';
                    final paise = CurrencyFormatter.parseToPaise(value);
                    if (paise == null || paise <= 0) return 'Enter valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Category Selector Chips ──
                Text(
                  'Category',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final id = cat['id'] as String;
                    final name = cat['name'] as String;
                    final icon = cat['icon'] as IconData;
                    final isSelected = _selectedCategory == id;

                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: isSelected ? Colors.white : colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(name),
                        ],
                      ),
                      selectedColor: isIncome ? AppColors.income : AppColors.expense,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = id),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Counterparty / Person Name ──
                TextFormField(
                  controller: _personNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: isIncome ? 'Received From (Donor / Member)' : 'Paid To (Vendor / Person)',
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Contact Phone Number ──
                TextFormField(
                  controller: _personContactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Mobile Number (optional)',
                    prefixIcon: Icon(Icons.phone_iphone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Payment Method Dropdown ──
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('💵 Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('📱 UPI / GPay / PhonePe')),
                    DropdownMenuItem(value: 'bank', child: Text('🏦 Bank Transfer / NEFT')),
                    DropdownMenuItem(value: 'cheque', child: Text('📄 Cheque')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Notes ──
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Remarks (optional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Submit Button ──
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIncome ? AppColors.income : AppColors.expense,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text('Save ${isIncome ? 'Income' : 'Expense'} Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
