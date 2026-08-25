import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../theme/app_colors.dart';

/// Parsed voice entry result.
class ParsedVoiceEntry {
  final String type; // 'income' or 'expense'
  final double amount;
  final String personName;
  final String category;
  final String paymentMethod;

  const ParsedVoiceEntry({
    required this.type,
    required this.amount,
    required this.personName,
    required this.category,
    required this.paymentMethod,
  });
}

class VoiceAssistantDialog extends StatefulWidget {
  const VoiceAssistantDialog({super.key});

  @override
  State<VoiceAssistantDialog> createState() => _VoiceAssistantDialogState();
}

class _VoiceAssistantDialogState extends State<VoiceAssistantDialog> {
  final TextEditingController _voiceInputController = TextEditingController();
  bool _isListening = false;
  ParsedVoiceEntry? _parsedResult;

  void _processSpokenText(String text) {
    if (text.trim().isEmpty) return;

    final lower = text.toLowerCase();

    // Determine type
    final isExpense = lower.contains('paid') ||
        lower.contains('spent') ||
        lower.contains('expense') ||
        lower.contains('out') ||
        lower.contains('gave');
    final type = isExpense ? 'expense' : 'income';

    // Extract amount
    final amountReg = RegExp(r'(\d+[\d,]*(\.\d+)?)');
    final match = amountReg.firstMatch(text.replaceAll(',', ''));
    final amount = match != null ? double.tryParse(match.group(1) ?? '0') ?? 0.0 : 0.0;

    // Extract person name (e.g. "from Rajesh" or "to Suresh")
    String person = 'General';
    final personMatch = RegExp(r'(from|to|by)\s+([A-Z][a-z]+(\s+[A-Z][a-z]+)?)', caseSensitive: false)
        .firstMatch(text);
    if (personMatch != null && personMatch.groupCount >= 2) {
      person = personMatch.group(2) ?? 'General';
    }

    // Determine Payment method
    String payment = 'cash';
    if (lower.contains('upi') || lower.contains('gpay') || lower.contains('phonepe')) {
      payment = 'upi';
    } else if (lower.contains('bank') || lower.contains('transfer') || lower.contains('neft')) {
      payment = 'bank';
    } else if (lower.contains('cheque')) {
      payment = 'cheque';
    }

    setState(() {
      _parsedResult = ParsedVoiceEntry(
        type: type,
        amount: amount,
        personName: person,
        category: isExpense ? 'Decorations' : 'Donations',
        paymentMethod: payment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Quick Entry',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Speak or type your financial transaction',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Spoken / Typed Input ──
            TextField(
              controller: _voiceInputController,
              onChanged: _processSpokenText,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., "Received 5000 rupees cash from Rajesh for Donations"',
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                      color: _isListening ? Colors.red : AppColors.primary),
                  onPressed: () {
                    setState(() => _isListening = !_isListening);
                    if (_isListening) {
                      _voiceInputController.text = 'Received 5000 rupees cash from Rajesh for Donations';
                      _processSpokenText(_voiceInputController.text);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Parsed Result Preview ──
            if (_parsedResult != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _parsedResult!.type == 'income' ? '🟢 Income Entry (+)' : '🔴 Expense Entry (-)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _parsedResult!.type == 'income' ? AppColors.income : AppColors.expense,
                          ),
                        ),
                        Text(
                          '₹${_parsedResult!.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Person: ${_parsedResult!.personName}', style: const TextStyle(fontSize: 13)),
                        Text('Payment: ${_parsedResult!.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Action Buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _parsedResult == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          context.push(AppRoutes.addTransaction);
                        },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirm & Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
