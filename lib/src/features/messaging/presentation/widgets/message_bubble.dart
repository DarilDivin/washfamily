import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final String? senderName;
  final String? interlocutorId;
  final bool isLastSent;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.senderName,
    this.interlocutorId,
    this.isLastSent = false,
  });

  static String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // ── Système ──────────────────────────────────────────────────────
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.content,
            style: tt.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isSelf = message.senderId == currentUserId;
    final isRead = interlocutorId != null &&
        message.readBy.contains(interlocutorId);

    if (isSelf) {
      return _SentBubble(
        message: message,
        isLastSent: isLastSent,
        isRead: isRead,
      );
    } else {
      return _ReceivedBubble(
        message: message,
        senderName: senderName,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Envoyé — droite, fond AppColors.primary
// ─────────────────────────────────────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  final MessageModel message;
  final bool isLastSent;
  final bool isRead;

  const _SentBubble({
    required this.message,
    required this.isLastSent,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(left: size.width * 0.2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: tt.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      MessageBubble.formatTime(message.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    if (isLastSent) ...[
                      const SizedBox(width: 3),
                      PhosphorIcon(
                        isRead
                            ? PhosphorIconsFill.checks
                            : PhosphorIconsRegular.check,
                        size: 12,
                        color: isRead
                            ? AppColors.confirmedText
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reçu — gauche, fond AppColors.inputBackground
// ─────────────────────────────────────────────────────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  final MessageModel message;
  final String? senderName;

  const _ReceivedBubble({
    required this.message,
    this.senderName,
  });

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
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(right: size.width * 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar initiales
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(senderName),
                style: tt.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senderName != null && senderName!.isNotEmpty) ...[
                  Text(
                    senderName!,
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: tt.bodyMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          MessageBubble.formatTime(message.createdAt),
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
