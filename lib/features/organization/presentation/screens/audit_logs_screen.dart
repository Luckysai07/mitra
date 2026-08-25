import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

class AuditLogItem {
  final String id;
  final String action;
  final String entityType;
  final String details;
  final DateTime performedAt;

  const AuditLogItem({
    required this.id,
    required this.action,
    required this.entityType,
    required this.details,
    required this.performedAt,
  });
}

/// Audit Logs screen displaying immutable record of financial edits & org activity.
class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  Future<List<AuditLogItem>> _fetchAuditLogs(String orgId) async {
    try {
      final response = await SupabaseService.client
          .from('audit_logs')
          .select()
          .eq('org_id', orgId)
          .order('performed_at', ascending: false);

      final List<AuditLogItem> logs = [];
      for (final row in (response as List)) {
        logs.add(
          AuditLogItem(
            id: row['id'] as String,
            action: (row['action'] as String? ?? 'action').toUpperCase(),
            entityType: row['entity_type'] as String? ?? 'transaction',
            details: row['reason'] as String? ?? 'Financial entry processed',
            performedAt: row['performed_at'] != null ? DateTime.parse(row['performed_at']) : DateTime.now(),
          ),
        );
      }
      return logs;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Immutable Audit Logs'),
      ),
      body: SafeArea(
        child: activeOrg == null
            ? const Center(child: Text('No active organization selected.'))
            : FutureBuilder<List<AuditLogItem>>(
                future: _fetchAuditLogs(activeOrg.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data ?? [];

                  if (logs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 64, color: colorScheme.primary.withOpacity(0.5)),
                            const SizedBox(height: AppSpacing.md),
                            Text('Audit Trail Active', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Every financial entry, approval, and member edit in ${activeOrg.name} is permanently logged here for 100% transparency.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: logs.length,
                    itemBuilder: (context, idx) {
                      final log = logs[idx];

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Icons.history_rounded, color: colorScheme.primary, size: 20),
                          ),
                          title: Text('${log.action} • ${log.entityType}', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text(log.details, style: AppTypography.bodySmall),
                          trailing: Text(
                            log.performedAt.toString().split('.')[0],
                            style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
