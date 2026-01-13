import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:intl/intl.dart';

class AdminDoctorRequestsPage extends StatefulWidget {
  const AdminDoctorRequestsPage({super.key});

  @override
  State<AdminDoctorRequestsPage> createState() =>
      _AdminDoctorRequestsPageState();
}

class _AdminDoctorRequestsPageState extends State<AdminDoctorRequestsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _filterStatus = 'pending';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes des Médecins'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/doctor-form');
            },
            tooltip: 'Créer un médecin manuellement',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtres
                _buildFilterBar(),

                // Liste des demandes
                Expanded(
                  child: _buildRequestsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterStatus,
              decoration: InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('En attente'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'approved',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Approuvées'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'rejected',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Rejetées'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null && value != _filterStatus) {
                  _changeFilter(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('doctor_requests')
          .where('status', isEqualTo: _filterStatus)
          .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _filterStatus == 'pending'
                      ? 'Aucune demande en attente'
                      : _filterStatus == 'approved'
                          ? 'Aucune demande approuvée'
                          : 'Aucune demande rejetée',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final requestId = request.id;

            return _buildRequestCard(requestId, data);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    final date = data['requestDate'] != null
        ? (data['requestDate'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final status = data['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(requestId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Nom non renseigné',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['specialization'] ?? 'Spécialité non renseignée',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      status == 'pending'
                          ? 'En attente'
                          : status == 'approved'
                              ? 'Approuvé'
                              : 'Rejeté',
                    ),
                    backgroundColor: status == 'pending'
                        ? Colors.orange.shade100
                        : status == 'approved'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    labelStyle: TextStyle(
                      color: status == 'pending'
                          ? Colors.orange.shade800
                          : status == 'approved'
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations de base
              _buildInfoRow(Icons.email, data['email'] ?? 'Email non renseigné'),
              _buildInfoRow(
                  Icons.phone, data['phone'] ?? 'Téléphone non renseigné'),
              _buildInfoRow(Icons.badge,
                  'Licence: ${data['licenseNumber'] ?? 'Non renseigné'}'),

              // Informations supplémentaires si disponibles
              if (data['hospital'] != null && data['hospital'].toString().isNotEmpty)
                _buildInfoRow(Icons.local_hospital, 'Hôpital: ${data['hospital']}'),
              
              if (data['experience'] != null && data['experience'] > 0)
                _buildInfoRow(Icons.work, 'Expérience: ${data['experience']} ans'),

              // Description
              if (data['description'] != null && data['description'].toString().isNotEmpty)
                _buildDescriptionSection(data['description']),

              const SizedBox(height: 8),

              _buildInfoRow(Icons.calendar_today, 'Demande: $formattedDate'),

              // Informations d'approbation/rejet
              if (!isPending) _buildApprovalInfo(data),

              const SizedBox(height: 16),

              // Actions (seulement si en attente)
              if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _approveRequest(requestId, data),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showRejectDialog(requestId, data),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Présentation:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalInfo(Map<String, dynamic> data) {
    final status = data['status'];
    final isApproved = status == 'approved';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isApproved ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApproved ? 'Demande approuvée' : 'Demande rejetée',
                  style: TextStyle(
                    fontSize: 12,
                    color: isApproved
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (data['approvedBy'] != null)
                  Text(
                    'Par: ${data['approvedBy']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                if (data['approvedAt'] != null)
                  Text(
                    'Le: ${DateFormat('dd/MM/yyyy').format((data['approvedAt'] as Timestamp).toDate())}',
                    style: const TextStyle(fontSize: 11),
                  ),
                if (data['rejectReason'] != null &&
                    data['rejectReason'].toString().isNotEmpty)
                  Text(
                    'Raison: ${data['rejectReason']}',
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(String requestId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${data['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Nom complet:', data['name']),
              _buildDetailItem('Email:', data['email']),
              _buildDetailItem('Téléphone:', data['phone']),
              _buildDetailItem('Spécialité:', data['specialization']),
              _buildDetailItem('Numéro de licence:', data['licenseNumber']),
              _buildDetailItem('Hôpital/Clinique:', data['hospital'] ?? 'Non renseigné'),
              _buildDetailItem('Expérience:', '${data['experience'] ?? 0} ans'),
              
              if (data['description'] != null && data['description'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Présentation professionnelle:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(data['description']),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              _buildDetailItem('Date de demande:', 
                DateFormat('dd/MM/yyyy HH:mm').format(
                  (data['requestDate'] as Timestamp).toDate()
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (data['status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveRequest(requestId, data);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approuver'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(
      String requestId, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    try {
      final approvedBy = _auth.currentUser?.email ?? 'Admin';

      await _authService.approveDoctorRequest(
        requestId: requestId,
        requestData: data,
        approvedBy: approvedBy,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${data['name']} a été approuvé et peut maintenant se connecter',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRejectDialog(String requestId, Map<String, dynamic> data) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rejeter la demande'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rejeter la demande de ${data['name']} ?'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison du rejet (recommandé)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () =>
                    _rejectRequest(requestId, data, reasonController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Rejeter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _rejectRequest(
      String requestId, Map<String, dynamic> data, String reason) async {
    setState(() => _isLoading = true);

    try {
      final rejectedBy = _auth.currentUser?.email ?? 'Admin';

      await _authService.rejectDoctorRequest(
        requestId: requestId,
        requestData: data,
        rejectedBy: rejectedBy,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande rejetée avec succès'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeFilter(String newStatus) {
    if (!mounted) return;

    setState(() {
      _filterStatus = newStatus;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}