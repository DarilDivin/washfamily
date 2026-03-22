import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/machine_model.dart';

class MachineDetailSheet extends StatelessWidget {
  final MachineModel machine;

  const MachineDetailSheet({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        // Le rendu de la bordure et de l'arrondi est géré par le app_theme
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Petite "poignée" en haut
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // En-tête : Titre et Prix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Machine à Laver ${machine.brand}",
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${machine.capacityKg} kg · À 300m", // Distance mockée pour le moment
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: colorScheme.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: Text(
                   "${machine.pricePerWash.toStringAsFixed(2)} €",
                   style: textTheme.titleLarge?.copyWith(
                     color: colorScheme.primary,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Rating et statut
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber[600], size: 20),
              const SizedBox(width: 4),
              Text(
                machine.rating.toString(),
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                "(${machine.reviewCount} avis)",
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),
              _buildStatusBadge(machine.status, theme),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            machine.description,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Bouton Réserver
          FilledButton(
            onPressed: machine.status == 'AVAILABLE' 
              ? () {
                 // On ferme le BottomSheet
                 Navigator.pop(context);
                 // On envoie vers le tunnel
                 context.push('/booking-date', extra: machine);
              } 
              : null,
            child: const Text("Réserver cette machine"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color color;
    String text;
    
    switch (status) {
      case 'AVAILABLE':
        color = Colors.green;
        text = 'Disponible';
        break;
      case 'IN_USE':
        color = Colors.orange;
        text = 'En cours';
        break;
      case 'MAINTENANCE':
        color = Colors.red;
        text = 'En maintenance';
        break;
      default:
        color = Colors.grey;
        text = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
