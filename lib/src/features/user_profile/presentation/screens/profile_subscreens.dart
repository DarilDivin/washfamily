import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: Colors.blue[300]),
            const SizedBox(height: 24),
            Text(
              "Page en construction",
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Text(
              "Cette fonctionnalité arrivera très bientôt.",
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget { const FavoritesScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Mes Favoris"); }
class PersonalInfoScreen extends StatelessWidget { const PersonalInfoScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Informations personnelles"); }
class PaymentsScreen extends StatelessWidget { const PaymentsScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Paiements et réductions"); }
class HelpCenterScreen extends StatelessWidget { const HelpCenterScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Centre d'aide"); }
class SecurityReportScreen extends StatelessWidget { const SecurityReportScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Sécurité et signalement"); }
class PendingRequestsScreen extends StatelessWidget { const PendingRequestsScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Demandes en attente"); }
class RevenueStatsScreen extends StatelessWidget { const RevenueStatsScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Revenus & Statistiques"); }
class BankDetailsScreen extends StatelessWidget { const BankDetailsScreen({super.key}); @override Widget build(BuildContext context) => const _PlaceholderScreen("Coordonnées bancaires"); }
