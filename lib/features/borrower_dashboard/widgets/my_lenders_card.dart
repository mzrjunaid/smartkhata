import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/borrower_connection_model.dart';
import '../../../core/providers/profile_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../lender_dashboard/widgets/section_header.dart';

class MyLendersCard extends ConsumerWidget {
  const MyLendersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (connections) {
        if (connections.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY LENDERS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: connections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final c = entry.value;
                    return Column(
                      children: [
                        _LenderCard(connection: c),
                        if (index < connections.length - 1)
                          Divider(
                            height: 1, 
                            indent: 84, 
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LenderCard extends ConsumerWidget {
  const _LenderCard({required this.connection});
  final BorrowerConnectionModel connection;

  Future<void> _launchWhatsApp(
    BuildContext context,
    String? borrowerName,
    String? borrowerCnic,
    String? borrowerPhone,
  ) async {
    final phone = connection.lenderPhone?.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lender phone number is not available')),
        );
      }
      return;
    }

    final totalBorrowed = connection.loans.fold<double>(
      0,
      (s, l) => s + l.principal,
    );
    final activeLoansCount = connection.loans
        .where((l) => l.status == 'active' || l.status == 'overdue')
        .length;
    final loanProfile =
        '$activeLoansCount active loans, total: PKR ${totalBorrowed.toStringAsFixed(0)}';

    final message =
        'Borrower Name: ${borrowerName ?? 'Unknown'}\n'
        'CNIC: ${borrowerCnic ?? 'Unknown'}\n'
        'Contact Number: ${borrowerPhone ?? 'Unknown'}\n'
        'Loan Profile: $loanProfile\n\n'
        'Message: ';

    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanCount = connection.loans.length;
    final initial = connection.lenderName.isNotEmpty
        ? connection.lenderName[0].toUpperCase()
        : 'L';

    final profileAsync = ref.watch(currentProfileProvider);
    final borrowerName = profileAsync.value?['full_name'] as String?;
    final borrowerCnic = profileAsync.value?['cnic'] as String?;
    final borrowerPhone = profileAsync.value?['phone'] as String?;

    final hasPendingLoan = connection.loans.any(
      (l) =>
          l.status == 'draft' ||
          l.status == 'pending_disbursement' ||
          l.status == 'pending',
    );
    final isPendingConnection = connection.status == 'pending';
    final isPending =
        isPendingConnection || connection.hasPendingInvitation || hasPendingLoan;

    String pendingText = 'Pending';
    if (isPendingConnection) {
      pendingText = 'Pending Connection';
    } else if (connection.hasPendingInvitation) {
      pendingText = 'Pending Invitation';
    } else if (hasPendingLoan) {
      pendingText = 'Pending Loan';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/borrower-profile/${connection.connectionId}'),
        splashColor: AppTheme.colors(context).primary.withValues(alpha: 0.05),
        highlightColor: AppTheme.colors(context).primary.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFF2C3E50), const Color(0xFF3498DB)]
                        : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            connection.lenderName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colors(context).textPrimary,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.colors(context).warningSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.colors(context).warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              pendingText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.colors(context).warning,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).infoSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 12,
                            color: AppTheme.colors(context).info,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$loanCount Loan${loanCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.colors(context).textSecondary,
                          ),
                        ),
                        if (connection.lenderPhone != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.colors(context).successSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.phone_iphone_rounded,
                              size: 12,
                              color: AppTheme.colors(context).success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connection.lenderPhone!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.colors(context).textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (connection.lenderPhone != null) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _launchWhatsApp(
                        context,
                        borrowerName,
                        borrowerCnic,
                        borrowerPhone,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

