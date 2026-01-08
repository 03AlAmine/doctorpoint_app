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
            // Statistiques
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
                    onTap: () {},
                  ),
                  _buildActionCard(
                    icon: Icons.person,
                    title: 'Patients',
                    subtitle: 'Gérer les patients',
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  _buildActionCard(
                    icon: Icons.bar_chart,
                    title: 'Statistiques',
                    subtitle: 'Voir les rapports',
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _buildActionCard(
                    icon: Icons.settings,
                    title: 'Paramètres',
                    subtitle: 'Configurer l\'app',
                    color: Colors.grey,
                    onTap: () {},
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

// Ajoutez ces méthodes dans votre classe AdminDashboard :
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
            child:
                const Text('Déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
        '/login', // Remplacez par votre route de connexion
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

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          title: 'Médecins',
          value: '24',
          icon: Icons.medical_services,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'RDV Aujourd\'hui',
          value: '15',
          icon: Icons.calendar_today,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Patients',
          value: '156',
          icon: Icons.person,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
    );
  }

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
}
