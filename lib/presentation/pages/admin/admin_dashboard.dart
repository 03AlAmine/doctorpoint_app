import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tableau de Bord Admin',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: false,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor.withOpacity(0.3),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                ),
                child: Text(
                  'Aperçu du système',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                ),
                child: Text(
                  'Gérez votre plateforme médicale en temps réel',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Statistiques avec données réelles
              _buildStatsSection(isMobile, isTablet),
              const SizedBox(height: 40),

              // Actions principales
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                ),
                child: Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildActionsGrid(isMobile, isTablet),
              const SizedBox(height: 40),

              // Activité récente
              _buildRecentActivity(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').snapshots(),
        builder: (context, usersSnapshot) {
          final usersData = usersSnapshot.data;
          final patientsCount = usersData?.docs
                  .where((doc) => doc['role'] == 'patient')
                  .length ??
              0;
          final doctorsCount = usersData?.docs
                  .where((doc) => doc['role'] == 'doctor')
                  .length ??
              0;

          return StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('doctor_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, requestsSnapshot) {
              final pendingRequests = requestsSnapshot.data?.size ?? 0;

              return StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('appointments')
                    .where('date',
                        isEqualTo: DateTime.now().toString().split(' ')[0])
                    .snapshots(),
                builder: (context, appointmentsSnapshot) {
                  final appointmentsToday = appointmentsSnapshot.data?.size ?? 0;

                  final stats = [
                    {
                      'title': 'Médecins',
                      'value': doctorsCount.toString(),
                      'icon': Icons.medical_services_outlined,
                      'color': Colors.blue,
                      'gradient': LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                    },
                    {
                      'title': 'Patients',
                      'value': patientsCount.toString(),
                      'icon': Icons.people_outline,
                      'color': Colors.purple,
                      'gradient': LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600,
                        ],
                      ),
                    },
                    {
                      'title': 'RDV Auj.',
                      'value': appointmentsToday.toString(),
                      'icon': Icons.calendar_today_outlined,
                      'color': Colors.green,
                      'gradient': LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                    },
                    {
                      'title': 'Demandes',
                      'value': pendingRequests.toString(),
                      'icon': Icons.pending_actions_outlined,
                      'color': Colors.orange,
                      'gradient': LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      'badge': pendingRequests > 0,
                    },
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile
                          ? 2
                          : isTablet
                              ? 4
                              : 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isMobile ? 1.0 : 1.0,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      return _buildStatCard(stat, isMobile);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isMobile) {
    final hasBadge = stat['badge'] == true;
    final badgeValue = stat['value'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: stat['gradient'] as Gradient,
        boxShadow: [
          BoxShadow(
            color: stat['color'].withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'].toString(),
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['title'].toString(),
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasBadge && badgeValue != '0' && badgeValue != '0')
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  badgeValue.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(bool isMobile, bool isTablet) {
    final actions = [
      {
        'title': 'Demandes',
        'subtitle': 'Valider les médecins',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'route': '/admin/doctor-requests',
      },
      {
        'title': 'Médecins',
        'subtitle': 'Gérer les médecins',
        'icon': Icons.medical_services,
        'color': Colors.blue,
        'route': '/admin/doctors',
      },
      {
        'title': 'Patients',
        'subtitle': 'Gérer les patients',
        'icon': Icons.people,
        'color': Colors.purple,
        'route': '/admin/patients',
      },
      {
        'title': 'Rendez-vous',
        'subtitle': 'Voir les RDV',
        'icon': Icons.calendar_today,
        'color': Colors.green,
        'route': '/appointments',
      },
      {
        'title': 'Statistiques',
        'subtitle': 'Voir rapports',
        'icon': Icons.bar_chart,
        'color': Colors.indigo,
        'route': '',
        'onTap': () {
          _showStatisticsDialog();
        },
      },
      {
        'title': 'Paramètres',
        'subtitle': 'Configurer app',
        'icon': Icons.settings,
        'color': Colors.grey,
        'route': '',
        'onTap': () {
          _showSettingsDialog();
        },
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile
              ? 2
              : isTablet
                  ? 3
                  : 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.1 : 1.2,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return _buildActionCard(actions[index], isMobile);
        },
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (action['route'] != null && action['route'].isNotEmpty) {
              Navigator.pushNamed(context, action['route'] as String);
            } else if (action['onTap'] != null) {
              (action['onTap'] as Function)();
            }
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: action['color'].withOpacity(0.1),
          highlightColor: action['color'].withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        action['color'].withOpacity(0.1),
                        action['color'].withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action['title'].toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  action['subtitle'].toString(),
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Activité récente',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _showActivityDetails();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.withOpacity(0.7),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune activité récente',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return Column(
                  children: users.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildActivityItem(data, isMobile);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> data, bool isMobile) {
    final name = data['fullName'] ?? 'Utilisateur';
    final role = data['role'] ?? 'utilisateur';
    final roleText = role == 'doctor' ? 'médecin' : 'patient';
    final email = data['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            radius: 20,
            child: Icon(
              role == 'doctor' ? Icons.medical_services : Icons.person,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Nouveau $roleText inscrit',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: AppTheme.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            'Aujourd\'hui',
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: AppTheme.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques avancées'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Statistiques détaillées',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: _db.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final users = snapshot.data!.docs;
                          final patients =
                              users.where((doc) => doc['role'] == 'patient').length;
                          final doctors =
                              users.where((doc) => doc['role'] == 'doctor').length;

                          return Column(
                            children: [
                              _buildStatItem('Patients total', patients),
                              _buildStatItem('Médecins total', doctors),
                              _buildStatItem('Taux de croissance', '12%'),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Sécurité'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Langue'),
                  trailing: const Text('Français'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activité détaillée'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Aucune activité'),
                );
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        data['role'] == 'doctor'
                            ? Icons.medical_services
                            : Icons.person,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(data['fullName'] ?? 'Utilisateur'),
                    subtitle: Text(
                      '${data['role'] == 'doctor' ? 'Médecin' : 'Patient'} • ${data['email'] ?? ''}',
                    ),
                    trailing: Text(
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
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
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}