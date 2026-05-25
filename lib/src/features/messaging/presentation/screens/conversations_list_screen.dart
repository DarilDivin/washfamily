import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/repositories/messaging_repository.dart';
import '../widgets/conversation_tile.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final conversationsAsync = ref.watch(conversationsStreamProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Messages',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            conversationsAsync.whenData((list) => list).valueOrNull != null
                ? Text(
                    _subtitle(
                        conversationsAsync.valueOrNull?.length ?? 0),
                    style: tt.labelSmall
                        ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (conversations) {
          if (conversations.isEmpty) return const _EmptyState();

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: conversations.length,
            itemBuilder: (context, index) => ConversationTile(
              conversation: conversations[index],
              currentUserId: uid,
            ),
          );
        },
      ),
    );
  }

  String _subtitle(int count) {
    if (count == 0) return '';
    return count == 1 ? '1 conversation' : '$count conversations';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// État vide
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhosphorIcon(PhosphorIconsRegular.chatCircle,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text('Aucune conversation pour l\'instant',
                style: tt.titleSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vos échanges apparaîtront ici après confirmation d\'une réservation.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Erreur
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhosphorIcon(PhosphorIconsRegular.warningCircle,
                size: 40, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Erreur de chargement',
                style: tt.titleSmall
                    ?.copyWith(color: AppColors.cancelledText)),
            const SizedBox(height: AppSpacing.xs),
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
