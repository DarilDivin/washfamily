import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

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

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.notification.isRead) {
      NotificationRepository().markAsRead(widget.notification.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final date = DateFormat("d MMMM yyyy 'à' HH:mm", 'fr').format(n.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notification',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ────────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _iconFor(n.title),
                      size: 28,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    n.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 28),

            // ── Message ──────────────────────────────────────────────────────
            Text(
              'Message',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFCBD5E1),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              n.message,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF374151),
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
