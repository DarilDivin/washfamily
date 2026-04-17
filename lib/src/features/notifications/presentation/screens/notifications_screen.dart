import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final uid = authSnapshot.data?.uid;
        if (uid == null) return const _LoadingView();

        final repo = NotificationRepository();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
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
              final today = all.where((n) => n.createdAt.isAfter(todayStart)).toList();
              final earlier = all.where((n) => !n.createdAt.isAfter(todayStart)).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        unread.isEmpty
                            ? 'Tout est lu'
                            : '${unread.length} non lue${unread.length > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const Spacer(),
                      if (unread.isNotEmpty)
                        GestureDetector(
                          onTap: () => repo.markAllAsRead(uid),
                          child: Text(
                            'Tout marquer lu',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── Aujourd'hui ──────────────────────────────────────────
                  if (today.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _GroupLabel("Aujourd'hui"),
                    const SizedBox(height: 8),
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

                  // ── Plus tôt ─────────────────────────────────────────────
                  if (earlier.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _GroupLabel('Plus tôt'),
                    const SizedBox(height: 8),
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

// ── Group label ────────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFCBD5E1),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Icône par type (monochrome) ────────────────────────────────────────────────

IconData _iconFor(String title) {
  if (title.contains('Nouvelle') || title.contains('demande')) {
    return Icons.local_laundry_service_outlined;
  }
  if (title.contains('confirmée') || title.contains('✅')) {
    return Icons.check_circle_outline_rounded;
  }
  if (title.contains('refusée') || title.contains('❌')) {
    return Icons.cancel_outlined;
  }
  if (title.contains('Rappel') || title.contains('⏰')) {
    return Icons.alarm_outlined;
  }
  return Icons.notifications_none_rounded;
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(n.title),
                size: 20,
                color: isUnread
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 13),

            // Content
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
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isUnread
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isUnread
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(n.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFCBD5E1),
                    ),
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

// ── États ──────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune notification',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez notifié lors de nouvelles réservations ou de changements de statut.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.6,
              ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
