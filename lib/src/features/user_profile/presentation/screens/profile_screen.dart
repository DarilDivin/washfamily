import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:washfamily/src/features/authentication/data/repositories/user_repository.dart';
import 'package:washfamily/src/features/authentication/domain/models/user_model.dart';
import 'package:washfamily/src/features/authentication/data/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final user = await UserRepository().getUser(uid);
    if (mounted) {
      setState(() {
        _userModel = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRole(bool value) async {
    if (_userModel == null) return;
    final newRole = value ? 'OWNER' : 'USER';
    setState(() => _isLoading = true);
    
    try {
      await UserRepository().updateUserRole(_userModel!.uid, newRole);
      await _loadUser(); // Recharger les données
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de mise à jour du rôle"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userModel == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Utilisateur introuvable. Veuillez vous reconnecter.", textAlign: TextAlign.center),
              TextButton(onPressed: _logout, child: const Text("Se déconnecter")),
            ],
          ),
        ),
      );
    }

    final isOwner = _userModel!.isOwner;
    final isAdmin = _userModel!.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark background matching Figma frame ? Wait, looking closely at the Figma background, it's actually white/grey inside the frame. 
      // The image shows the mobile frame has a slightly blue border. The actual background is White or #F8FAFC.
      body: Container(
        color: const Color(0xFFF8FAFC), // Farground
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // APP BAR
            SliverAppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
                onPressed: () {},
              ),
              title: Text(
                "Profile",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Color(0xFF0F172A)),
                  onPressed: () {},
                ),
              ],
            ),

            // HEADER (AVATAR)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026024d'), // Dummy avatar
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_userModel!.firstName} ${_userModel!.lastName}",
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? "Sans contact",
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Badge Identité
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  "IDENTITÉ VÉRIFIÉE",
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A), letterSpacing: 0.5),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TOGGLE SWITCH
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 4)]),
                        child: Icon(isOwner ? Icons.vpn_key_rounded : Icons.local_laundry_service_rounded, color: const Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          isOwner ? "Gérer mes machines" : "Passer en mode\nPropriétaire",
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                        ),
                      ),
                      _isLoading 
                        ? const SizedBox(width: 48, height: 24, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
                        : Switch(
                            value: isOwner,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF2563EB),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            onChanged: _toggleRole,
                          ),
                    ],
                  ),
                ),
              ),
            ),

            // MENU SECTIONS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isAdmin) ...[
                      _buildSectionHeader("ADMINISTRATION"),
                      _MenuTile(icon: Icons.admin_panel_settings_rounded, title: "Tableau de Bord Admin", onTap: () => context.push('/admin/dashboard')),
                      const SizedBox(height: 24),
                    ],
                    
                    _buildSectionHeader("ACTIVITÉ"),
                    if (!isOwner) ...[
                      _MenuTile(icon: Icons.history_rounded, title: "Mes réservations", onTap: () => context.go('/bookings')),
                      const SizedBox(height: 8),
                      _MenuTile(icon: Icons.bookmark_border_rounded, title: "Favoris", onTap: () => context.push('/profile/favorites')),
                    ] else ...[
                      _MenuTile(icon: Icons.local_laundry_service_outlined, title: "Mes machines", onTap: () => context.push('/profile/my-machines')),
                      const SizedBox(height: 8),
                      _MenuTile(icon: Icons.notifications_outlined, title: "Demandes en attente", onTap: () => context.push('/profile/owner-bookings')),
                      const SizedBox(height: 8),
                      _MenuTile(icon: Icons.bar_chart_rounded, title: "Revenus & Statistiques", onTap: () => context.push('/profile/revenue')),
                    ],
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader("MON COMPTE"),
                    _MenuTile(icon: Icons.person_outline_rounded, title: "Informations personnelles", onTap: () => context.push('/profile/personal-info')),
                    const SizedBox(height: 8),
                    if (!isOwner)
                      _MenuTile(icon: Icons.account_balance_wallet_outlined, title: "Paiements et réductions", onTap: () => context.push('/profile/payments'))
                    else
                      _MenuTile(icon: Icons.account_balance_outlined, title: "Coordonnées bancaires", onTap: () => context.push('/profile/bank-details')),

                    const SizedBox(height: 24),
                    _buildSectionHeader("ASSISTANCE"),
                    _MenuTile(icon: Icons.help_outline_rounded, title: "Centre d'aide", onTap: () => context.push('/profile/help')),
                    const SizedBox(height: 8),
                    _MenuTile(icon: Icons.shield_outlined, title: "Sécurité et signalement", onTap: () => context.push('/profile/security')),
                    
                    const SizedBox(height: 48),
                    
                    // LOUGOUT AND FOOTER
                    Center(
                      child: TextButton(
                        onPressed: _logout,
                        child: Text(
                          "Se déconnecter",
                          style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        "WASHFAMILY V1.0.0",
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader("MODE DÉVELOPPEUR"),
                    _MenuTile(
                      icon: Icons.data_object_rounded,
                      title: "Outils Dev (Seed Data)",

                      onTap: () => context.push('/dev/seed'),
                    ),
                    const SizedBox(height: 64), // Safe offset
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF475569), size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
