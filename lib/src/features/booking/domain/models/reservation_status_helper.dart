import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class ReservationStatusHelper {
  static String label(String status) {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'CONFIRMED':
        return 'Confirmée';
      case 'PICKED_UP':
        return 'Linge récupéré';
      case 'IN_PROGRESS':
        return 'Lavage en cours';
      case 'READY':
        return 'Prêt';
      case 'COMPLETED':
        return 'Terminée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  static Color backgroundColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.pendingBg;
      case 'CONFIRMED':
        return AppColors.confirmedBg;
      case 'PICKED_UP':
        return const Color(0xFFEFF6FF); // Blue 50
      case 'IN_PROGRESS':
        return const Color(0xFFFAF5FF); // Purple 50
      case 'READY':
        return const Color(0xFFF0FDF4); // Green 50
      case 'COMPLETED':
        return AppColors.completedBg;
      case 'CANCELLED':
        return AppColors.cancelledBg;
      default:
        return AppColors.inputBackground;
    }
  }

  static Color textColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.pendingText;
      case 'CONFIRMED':
        return AppColors.confirmedText;
      case 'PICKED_UP':
        return const Color(0xFF1E40AF); // Blue 800
      case 'IN_PROGRESS':
        return const Color(0xFF6B21A8); // Purple 800
      case 'READY':
        return const Color(0xFF166534); // Green 800
      case 'COMPLETED':
        return AppColors.completedText;
      case 'CANCELLED':
        return AppColors.cancelledText;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case 'PENDING':
        return PhosphorIconsRegular.clock;
      case 'CONFIRMED':
        return PhosphorIconsRegular.checkCircle;
      case 'PICKED_UP':
        return PhosphorIconsRegular.package;
      case 'IN_PROGRESS':
        return PhosphorIconsRegular.washingMachine;
      case 'READY':
        return PhosphorIconsRegular.sparkle;
      case 'COMPLETED':
        return PhosphorIconsRegular.sealCheck;
      case 'CANCELLED':
        return PhosphorIconsRegular.xCircle;
      default:
        return PhosphorIconsRegular.question;
    }
  }
}
