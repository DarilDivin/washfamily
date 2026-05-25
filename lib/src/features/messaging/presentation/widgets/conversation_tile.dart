import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../authentication/data/repositories/user_repository.dart';
import '../../domain/models/conversation_model.dart';

class ConversationTile extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  late Future<_TileData> _tileData;

  @override
  void initState() {
    super.initState();
    _tileData = _loadTileData();
  }

  @override
  void didUpdateWidget(ConversationTile old) {
    super.didUpdateWidget(old);
    if (old.conversation.id != widget.conversation.id ||
        old.currentUserId != widget.currentUserId) {
      setState(() => _tileData = _loadTileData());
    }
  }

  Future<_TileData> _loadTileData() async {
    final interlocutorId = widget.conversation.participantIds
        .firstWhere((id) => id != widget.currentUserId, orElse: () => '');

    // Les deux fetches démarrent en parallèle
    final userFuture = interlocutorId.isNotEmpty
        ? UserRepository().getUser(interlocutorId)
        : Future.value(null);

    final laundryFuture = widget.conversation.laundryId.isNotEmpty
        ? FirebaseFirestore.instance
            .collection('laundries')
            .doc(widget.conversation.laundryId)
            .get()
        : Future<DocumentSnapshot?>.value(null);

    final user = await userFuture;
    final laundrySnap = await laundryFuture;

    String name = 'Utilisateur';
    String initials = '?';
    if (user != null) {
      final first =
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '';
      final last =
          user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : '';
      name = '${user.firstName} ${user.lastName}'.trim();
      initials = '$first$last';
      if (initials.trim().isEmpty) initials = '?';
    }

    String laundryName = '';
    if (laundrySnap != null && laundrySnap.exists) {
      laundryName =
          ((laundrySnap.data() as Map<String, dynamic>?)?['name']) as String? ??
              '';
    }

    return _TileData(name: name, initials: initials, laundryName: laundryName);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final unread =
        widget.conversation.unreadCount[widget.currentUserId] ?? 0;
    final isUnread = unread > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => context.push('/messages/${widget.conversation.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: FutureBuilder<_TileData>(
              future: _tileData,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Avatar ──────────────────────────────────────
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                data?.initials ?? '?',
                                style: tt.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // ── Nom + laverie + dernier message ──────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoading
                                ? 'Chargement…'
                                : (data?.name ?? 'Utilisateur'),
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isLoading &&
                              data != null &&
                              data.laundryName.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              data.laundryName,
                              style: tt.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            widget.conversation.lastMessage,
                            style: tt.bodyMedium?.copyWith(
                              color: isUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // ── Heure + badge ────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(widget.conversation.lastMessageAt),
                          style: tt.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (isUnread) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: tt.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _TileData {
  final String name;
  final String initials;
  final String laundryName;

  const _TileData({
    required this.name,
    required this.initials,
    required this.laundryName,
  });
}
