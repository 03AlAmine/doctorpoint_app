import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/auth/doctor_auth_service.dart';

class DoctorDashboard extends StatefulWidget {
  final Doctor doctor;

  const DoctorDashboard({super.key, required this.doctor});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final DoctorAuthService _authService = DoctorAuthService();
  int _selectedIndex = 0;

  // Pages du dashboard
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    
    // Initialiser les pages
    _pages.addAll([
      _buildOverviewPage(),
      _buildAppointmentsPage(),
      _buildPatientsPage(),
      _buildProfilePage(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenue
          Text(
            'Bonjour, Dr. ${widget.doctor.name.split(' ').last}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.doctor.specialization,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Statistiques
          const Text(
            'Aujourd\'hui',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: 'Rendez-vous',
                value: '12',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Patients',
                value: '8',
                icon: Icons.people,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'En attente',
                value: '3',
                icon: Icons.access_time,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Revenus',
                value: '€850',
                icon: Icons.euro,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Prochains rendez-vous
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prochains rendez-vous',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildNextAppointments(),
          
          const SizedBox(height: 30),
          
          // Actions rapides
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildQuickAction(
                title: 'Voir agenda',
                icon: Icons.calendar_month,
                color: Colors.blue,
                onTap: () {},
              ),
              _buildQuickAction(
                title: 'Mes patients',
                icon: Icons.group,
                color: Colors.green,
                onTap: () {},
              ),
              _buildQuickAction(
                title: 'Prescriptions',
                icon: Icons.medication,
                color: Colors.orange,
                onTap: () {},
              ),
              _buildQuickAction(
                title: 'Statistiques',
                icon: Icons.bar_chart,
                color: Colors.purple,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointments() {
    // Données mockées - à remplacer par Firebase
    final appointments = [
      {
        'patient': 'Marie Dupont',
        'time': '10:00',
        'type': 'Vidéo',
        'status': 'Confirmé',
      },
      {
        'patient': 'Jean Martin',
        'time': '11:30',
        'type': 'Présentiel',
        'status': 'Confirmé',
      },
      {
        'patient': 'Sophie Leroy',
        'time': '14:00',
        'type': 'Audio',
        'status': 'En attente',
      },
    ];

    return Column(
      children: appointments.map((appointment) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                appointment['type'] == 'Vidéo'
                    ? Icons.videocam
                    : appointment['type'] == 'Audio'
                        ? Icons.call
                        : Icons.person,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(appointment['patient']!),
            subtitle: Text('${appointment['time']} - ${appointment['type']}'),
            trailing: Chip(
              label: Text(appointment['status']!),
              backgroundColor: appointment['status'] == 'Confirmé'
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              labelStyle: TextStyle(
                color: appointment['status'] == 'Confirmé'
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
            ),
            onTap: () {
              // Voir les détails du rendez-vous
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsPage() {
    return Center(
      child: Text('Page Rendez-vous - À implémenter'),
    );
  }

  Widget _buildPatientsPage() {
    return Center(
      child: Text('Page Patients - À implémenter'),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Photo de profil
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.lightGrey,
                backgroundImage: widget.doctor.imageUrl.isNotEmpty
                    ? NetworkImage(widget.doctor.imageUrl)
                    : null,
                child: widget.doctor.imageUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Text(
            widget.doctor.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.doctor.specialization,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          
          Text(
            widget.doctor.hospital,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Informations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildProfileInfo(
                    'Email',
                    widget.doctor.email ?? 'Non renseigné',
                    Icons.email,
                  ),
                  
                  _buildProfileInfo(
                    'Téléphone',
                    widget.doctor.phoneNumber ?? 'Non renseigné',
                    Icons.phone,
                  ),
                  
                  _buildProfileInfo(
                    'Expérience',
                    '${widget.doctor.experience} ans',
                    Icons.work,
                  ),
                  
                  _buildProfileInfo(
                    'Tarif consultation',
                    '€${widget.doctor.consultationFee}',
                    Icons.euro,
                  ),
                  
                  _buildProfileInfo(
                    'Langues',
                    widget.doctor.languages.join(', '),
                    Icons.language,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Actions
          Column(
            children: [
              ListTile(
                leading: Icon(Icons.settings, color: AppTheme.primaryColor),
                title: const Text('Paramètres du compte'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              
              ListTile(
                leading: Icon(Icons.lock, color: AppTheme.primaryColor),
                title: const Text('Changer le mot de passe'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showChangePasswordDialog();
                },
              ),
              
              ListTile(
                leading: Icon(Icons.notifications, color: AppTheme.primaryColor),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              
              ListTile(
                leading: Icon(Icons.help, color: AppTheme.primaryColor),
                title: const Text('Aide & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showPasswords = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Changer le mot de passe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: !showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe actuel',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: !showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !showPasswords,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPasswords
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPasswords = !showPasswords;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Les mots de passe ne correspondent pas'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _authService.changePassword(
                        currentPasswordController.text,
                        newPasswordController.text,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mot de passe changé avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Changer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Médecin'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Rendez-vous',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}