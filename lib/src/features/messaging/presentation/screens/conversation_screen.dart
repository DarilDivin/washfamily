import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../authentication/data/repositories/user_repository.dart';
import '../../../booking/domain/models/reservation_status_helper.dart';
import '../../data/repositories/messaging_repository.dart';
import '../widgets/message_bubble.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ConversationScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _markedAsRead = false;
  bool _sending = false;
  String? _interlocutorName;
  String? _interlocutorId;
  String? _reservationId;
  String? _reservationStatus;
  StreamSubscription? _reservationSub;

  static const _activeStatuses = {
    'PENDING', 'CONFIRMED', 'PICKED_UP', 'IN_PROGRESS', 'READY'
  };

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_markedAsRead && _uid.isNotEmpty) {
      _markedAsRead = true;
      MessagingRepository().markAsRead(
        conversationId: widget.conversationId,
        userId: _uid,
      );
      _loadConversationMeta();
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _reservationSub?.cancel();
    _scrollController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadConversationMeta() async {
    try {
      final conv = await MessagingRepository()
          .getConversationById(widget.conversationId);
      if (conv == null || !mounted) return;

      final otherId = conv.participantIds
          .firstWhere((id) => id != _uid, orElse: () => '');
      final user =
          otherId.isNotEmpty ? await UserRepository().getUser(otherId) : null;

      if (!mounted) return;
      setState(() {
        _interlocutorId = otherId.isNotEmpty ? otherId : null;
        _interlocutorName = user != null
            ? '${user.firstName} ${user.lastName}'.trim()
            : null;
        _reservationId =
            conv.reservationId.isNotEmpty ? conv.reservationId : null;
      });

      if (conv.reservationId.isNotEmpty) {
        _reservationSub = FirebaseFirestore.instance
            .collection('reservations')
            .doc(conv.reservationId)
            .snapshots()
            .listen((snap) {
          if (!mounted) return;
          final data = snap.data();
          setState(
              () => _reservationStatus = data?['status'] as String?);
        });
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await MessagingRepository().sendMessage(
        conversationId: widget.conversationId,
        senderId: _uid,
        content: text,
      );
      _ctrl.clear();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Aujourd\'hui';
    if (d == yesterday) return 'Hier';
    return DateFormat('d MMMM', 'fr').format(dt);
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final messagesAsync =
        ref.watch(messagesStreamProvider(widget.conversationId));

    // Auto-scroll à chaque nouveau message
    ref.listen(messagesStreamProvider(widget.conversationId), (_, next) {
      next.whenData((_) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      });
    });

    final isActive = _reservationStatus == null ||
        _activeStatuses.contains(_reservationStatus);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        title: Row(
          children: [
            // Avatar initiales
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(_interlocutorName),
                  style: tt.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _interlocutorName ?? '…',
                    style: tt.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_reservationStatus != null)
                    _StatusBadge(status: _reservationStatus!),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_reservationId != null)
            IconButton(
              icon: const PhosphorIcon(
                  PhosphorIconsRegular.arrowSquareOut, size: 20),
              tooltip: 'Voir la réservation',
              onPressed: () => context.push('/bookings'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Erreur : $e',
                    style: tt.bodyMedium
                        ?.copyWith(color: AppColors.error)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PhosphorIcon(PhosphorIconsRegular.chatCircle,
                            size: 40, color: AppColors.border),
                        const SizedBox(height: AppSpacing.md),
                        Text('Aucun message pour l\'instant',
                            style: tt.bodySmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                final lastSentIdx = messages.lastIndexWhere(
                    (m) => m.senderId == _uid && !m.isSystem);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final older = i > 0 ? messages[i - 1] : null;
                    final newer = i < messages.length - 1
                        ? messages[i + 1]
                        : null;

                    final showSep = older == null ||
                        !_sameDay(msg.createdAt, older.createdAt);

                    final spacingBelow = newer == null
                        ? 0.0
                        : newer.senderId == msg.senderId
                            ? 4.0
                            : 12.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showSep)
                          _DateSeparator(
                              label: _dateLabel(msg.createdAt)),
                        MessageBubble(
                          message: msg,
                          currentUserId: _uid,
                          senderName: msg.senderId != _uid
                              ? _interlocutorName
                              : null,
                          interlocutorId: _interlocutorId,
                          isLastSent: i == lastSentIdx,
                        ),
                        if (spacingBelow > 0)
                          SizedBox(height: spacingBelow),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Barre de saisie ──────────────────────────────────────
          _InputBar(
            controller: _ctrl,
            isActive: isActive,
            isSending: _sending,
            reservationStatus: _reservationStatus,
            onSend: _sendMessage,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge — statut réservation dans l'AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
      decoration: BoxDecoration(
        color: ReservationStatusHelper.backgroundColor(status),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        ReservationStatusHelper.label(status),
        style: tt.labelSmall?.copyWith(
          color: ReservationStatusHelper.textColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DateSeparator
// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            label,
            style:
                tt.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InputBar — barre de saisie
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isActive;
  final bool isSending;
  final String? reservationStatus;
  final VoidCallback onSend;
  final VoidCallback onChanged;

  const _InputBar({
    required this.controller,
    required this.isActive,
    required this.isSending,
    required this.onSend,
    required this.onChanged,
    this.reservationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (!isActive) {
      final label = reservationStatus == 'CANCELLED'
          ? 'Réservation annulée — messagerie clôturée'
          : 'Service terminé — messagerie clôturée';
      return Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const PhosphorIcon(PhosphorIconsRegular.lockSimple,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label,
                    style: tt.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic)),
              ),
            ]),
          ),
        ),
      );
    }

    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                style: tt.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  hintStyle: tt.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedOpacity(
              opacity: hasText && !isSending ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: hasText && !isSending ? onSend : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: PhosphorIcon(
                      PhosphorIconsRegular.paperPlaneTilt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
