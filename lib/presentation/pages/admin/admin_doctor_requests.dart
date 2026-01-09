// lib/presentation/pages/admin/admin_doctor_requests.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'package:intl/intl.dart';

class AdminDoctorRequestsPage extends StatefulWidget {
  const AdminDoctorRequestsPage({super.key});

  @override
  State<AdminDoctorRequestsPage> createState() => _AdminDoctorRequestsPageState();
}

class _AdminDoctorRequestsPageState extends State<AdminDoctorRequestsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  String _filterStatus = 'pending'; // pending, approved, rejected
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialisation dans initState au lieu de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes des Médecins'),
        backgroundColor: AppTheme.primaryColor,
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

  void _changeFilter(String newStatus) {
    if (!mounted) return;
    
    setState(() {
      _filterStatus = newStatus;
    });
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('doctor_requests')
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
            
            // Informations
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['email'] ?? 'Email non renseigné',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  data['phone'] ?? 'Téléphone non renseigné',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Licence: ${data['licenseNumber'] ?? 'Non renseigné'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Demande: $formattedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions (seulement si en attente)
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approuver'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green.shade300),
                      ),
                      onPressed: () => _showApproveDialog(requestId, data),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      onPressed: () => _showRejectDialog(requestId, data),
                    ),
                  ),
                ],
              ),
            ],
            
            // Si approuvé ou rejeté, afficher qui a traité
            if (!isPending) ...[
              const Divider(),
              Row(
                children: [
                  Icon(
                    status == 'approved' ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: status == 'approved' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == 'approved' ? 'Demande approuvée' : 'Demande rejetée',
                    style: TextStyle(
                      fontSize: 12,
                      color: status == 'approved' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(String requestId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approuver la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approuver la demande de ${data['name']} ?'),
            const SizedBox(height: 8),
            Text(
              'Cette action va créer un compte médecin et envoyer un email de confirmation.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _approveRequest(requestId, data),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
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
                    labelText: 'Raison du rejet (optionnel)',
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
                onPressed: () => _rejectRequest(requestId, data, reasonController.text),
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

  Future<void> _approveRequest(String requestId, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Mettre à jour le statut de la demande
      await _db.collection('doctor_requests').doc(requestId).update({
        'status': 'approved',
        'approvedBy': FirebaseAuth.instance.currentUser?.email,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // 2. Créer le compte médecin
      final appUser = await _authService.createDoctor(
        email: data['email']!,
        password: data['password']!,
        fullName: data['name']!,
        phone: data['phone']!,
        specialization: data['specialization']!,
        hospital: 'À définir', // L'admin devra compléter
        experience: 0, // Valeur par défaut
        licenseNumber: data['licenseNumber']!,
        additionalData: {
          'sourceRequestId': requestId,
          'status': 'active',
        },
      );

      // 3. Afficher un message de succès
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande approuvée et compte créé avec succès !'),
            backgroundColor: Colors.green,
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

  Future<void> _rejectRequest(String requestId, Map<String, dynamic> data, String reason) async {
    setState(() => _isLoading = true);
    
    try {
      await _db.collection('doctor_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectReason': reason.isNotEmpty ? reason : null,
        'rejectedBy': FirebaseAuth.instance.currentUser?.email,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
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

  @override
  void dispose() {
    super.dispose();
  }
}