import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final uid = authSnapshot.data?.uid;
        if (uid == null) return const _LoadingView();

        final repo = NotificationRepository();

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.textPrimary,
            leading: IconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft,
                  size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('Notifications', style: tt.titleLarge),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          body: StreamBuilder<List<NotificationModel>>(
            stream: repo.streamUserNotifications(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingView();
              }
              if (snapshot.hasError) {
                return _ErrorView(message: snapshot.error.toString());
              }

              final all = snapshot.data ?? [];
              if (all.isEmpty) return const _EmptyView();

              final unread = all.where((n) => !n.isRead).toList();
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final today =
                  all.where((n) => n.createdAt.isAfter(todayStart)).toList();
              final earlier =
                  all.where((n) => !n.createdAt.isAfter(todayStart)).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 80),
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        unread.isEmpty
                            ? 'Tout est lu'
                            : '${unread.length} non lue${unread.length > 1 ? 's' : ''}',
                        style: tt.labelSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      if (unread.isNotEmpty)
                        GestureDetector(
                          onTap: () => repo.markAllAsRead(uid),
                          child: Text(
                            'Tout marquer lu',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),

                  // ── Aujourd'hui ───────────────────────────────────────
                  if (today.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _GroupLabel("Aujourd'hui"),
                    const SizedBox(height: AppSpacing.sm),
                    ...today.map((n) => _NotificationCard(
                          notification: n,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotificationDetailScreen(notification: n),
                            ),
                          ),
                        )),
                  ],

                  // ── Plus tôt ──────────────────────────────────────────
                  if (earlier.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _GroupLabel('Plus tôt'),
                    const SizedBox(height: AppSpacing.sm),
                    ...earlier.map((n) => _NotificationCard(
                          notification: n,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotificationDetailScreen(notification: n),
                            ),
                          ),
                        )),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GroupLabel
// ─────────────────────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Text(
      text.toUpperCase(),
      style: tt.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.border,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icône par type de notification
// ─────────────────────────────────────────────────────────────────────────────

PhosphorIconData _iconFor(String title) {
  if (title.contains('Nouvelle') || title.contains('demande')) {
    return PhosphorIconsRegular.washingMachine;
  }
  if (title.contains('confirmée') || title.contains('✅')) {
    return PhosphorIconsRegular.checkCircle;
  }
  if (title.contains('refusée') || title.contains('❌')) {
    return PhosphorIconsRegular.xCircle;
  }
  if (title.contains('Rappel') || title.contains('⏰')) {
    return PhosphorIconsRegular.bellRinging;
  }
  return PhosphorIconsRegular.bell;
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotificationCard
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final n = notification;
    final isUnread = !n.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surface : AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isUnread ? AppColors.border : AppColors.inputBackground,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.inputBackground
                    : AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: PhosphorIcon(
                  _iconFor(n.title),
                  size: 20,
                  color: isUnread
                      ? AppColors.textSecondary
                      : AppColors.border,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: isUnread
                          ? AppColors.textSecondary
                          : AppColors.border,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(n.createdAt),
                    style: tt.labelSmall?.copyWith(color: AppColors.border),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return DateFormat('d MMM à HH:mm', 'fr').format(date);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// États
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PhosphorIcon(PhosphorIconsRegular.bell,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text('Aucune notification',
                style: tt.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vous serez notifié lors de nouvelles réservations ou de changements de statut.',
              textAlign: TextAlign.center,
              style:
                  tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PhosphorIcon(PhosphorIconsRegular.warning,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text('Une erreur est survenue',
                style: tt.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: tt.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
