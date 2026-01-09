import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctor_requests.dart';
import 'package:doctorpoint/presentation/pages/admin/admin_doctors_page.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statistiques avec données réelles
            _buildStatsRow(),
            const SizedBox(height: 30),

            // Actions principales
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // Carte pour les demandes de médecins
                  _buildActionCardWithBadge(
                    icon: Icons.pending_actions,
                    title: 'Demandes',
                    subtitle: 'Valider les médecins',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDoctorRequestsPage(),
                        ),
                      );
                    },
                  ),

                  _buildActionCard(
                    icon: Icons.medical_services,
                    title: 'Médecins',
                    subtitle: 'Gérer les médecins',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDoctorsPage(),
                        ),
                      );
                    },
                  ),

                  _buildActionCard(
                    icon: Icons.calendar_today,
                    title: 'Rendez-vous',
                    subtitle: 'Voir tous les RDV',
                    color: Colors.green,
                    onTap: () {
                      // TODO: Implémenter la page des rendez-vous
                    },
                  ),

                  _buildActionCard(
                    icon: Icons.person,
                    title: 'Patients',
                    subtitle: 'Gérer les patients',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Implémenter la page des patients
                    },
                  ),

                  _buildActionCard(
                    icon: Icons.bar_chart,
                    title: 'Statistiques',
                    subtitle: 'Voir les rapports',
                    color: Colors.indigo,
                    onTap: () {
                      // TODO: Implémenter la page des statistiques
                    },
                  ),

                  _buildActionCard(
                    icon: Icons.settings,
                    title: 'Paramètres',
                    subtitle: 'Configurer l\'app',
                    color: Colors.grey,
                    onTap: () {
                      // TODO: Implémenter les paramètres
                    },
                  ),

                  _buildActionCard(
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    subtitle: 'Quitter l\'admin',
                    color: Colors.red,
                    onTap: () {
                      _showLogoutConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode avec badge pour les demandes
  Widget _buildActionCardWithBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.size ?? 0;

        return Stack(
          children: [
            _buildActionCard(
              icon: icon,
              title: title,
              subtitle: subtitle,
              color: color,
              onTap: onTap,
            ),
            if (pendingCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Méthode de base pour les cartes d'action
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Statistiques avec données réelles
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Médecins (total)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('doctors')
              .where('hasAccount', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            final doctorsCount = snapshot.data?.size ?? 0;
            return _buildStatCard(
              title: 'Médecins',
              value: doctorsCount.toString(),
              icon: Icons.medical_services,
              color: Colors.blue,
              badge: false,
            );
          },
        ),

        // Rendez-vous aujourd'hui
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('date', isEqualTo: DateTime.now().toString().split(' ')[0])
              .snapshots(),
          builder: (context, snapshot) {
            final appointmentsToday = snapshot.data?.size ?? 0;
            return _buildStatCard(
              title: 'RDV Aujourd\'hui',
              value: appointmentsToday.toString(),
              icon: Icons.calendar_today,
              color: Colors.green,
              badge: false,
            );
          },
        ),

        // Patients (total)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'patient')
              .snapshots(),
          builder: (context, snapshot) {
            final patientsCount = snapshot.data?.size ?? 0;
            return _buildStatCard(
              title: 'Patients',
              value: patientsCount.toString(),
              icon: Icons.person,
              color: Colors.purple,
              badge: false,
            );
          },
        ),

        // Demandes en attente
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('doctor_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            final pendingRequests = snapshot.data?.size ?? 0;
            return _buildStatCard(
              title: 'Demandes',
              value: pendingRequests.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
              badge: pendingRequests > 0,
            );
          },
        ),
      ],
    );
  }

  // Carte de statistique
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool badge = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (badge && value != '0')
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Confirmation de déconnexion
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => _performLogout(context),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Déconnexion
  Future<void> _performLogout(BuildContext context) async {
    try {
      // Fermer la boîte de dialogue
      Navigator.pop(context);

      // Montrer un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Effectuer la déconnexion
      final authService = AuthService();
      await authService.signOut();

      // Fermer l'indicateur de chargement
      Navigator.pop(context);

      // Rediriger vers la page de connexion
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      Navigator.pop(context);

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}