// ignore_for_file: unused_field

import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/services/auth_service.dart';
import 'dart:io';

class DoctorDocumentsPage extends StatefulWidget {
  final String doctorId;

  const DoctorDocumentsPage({super.key, required this.doctorId});

  @override
  State<DoctorDocumentsPage> createState() => _DoctorDocumentsPageState();
}

class _DoctorDocumentsPageState extends State<DoctorDocumentsPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  final Map<String, File?> _selectedFiles = {
    'cni': null,
    'diploma': null,
    'certificate': null,
  };
  
  final Map<String, String?> _uploadedUrls = {
    'cni': null,
    'diploma': null,
    'certificate': null,
  };
  
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
  }

  Future<void> _loadExistingDocuments() async {
    try {
      final doc = await _db.collection('doctors').doc(widget.doctorId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final roleData = data['roleData'] as Map<String, dynamic>?;
        
        if (roleData != null && roleData['documents'] != null) {
          final documents = roleData['documents'] as Map<String, dynamic>;
          
          setState(() {
            _uploadedUrls['cni'] = documents['cni']?['url'];
            _uploadedUrls['diploma'] = documents['diploma']?['url'];
            _uploadedUrls['certificate'] = documents['certificate']?['url'];
          });
        }
      }
    } catch (e) {
      print('Erreur chargement documents: $e');
    }
  }

  Future<void> _pickDocument(String documentType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFiles[documentType] = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    if (_selectedFiles[documentType] == null) return;

    setState(() => _isUploading = true);

    try {
      // En développement, simuler l'upload
      await Future.delayed(const Duration(seconds: 1));
      
      // URL fictive pour le développement
      final downloadUrl = 'https://via.placeholder.com/300x400?text=$documentType';

      // Mettre à jour Firestore
      await _authService.uploadDoctorDocument(
        doctorId: widget.doctorId,
        documentType: documentType,
        fileUrl: downloadUrl,
      );

      setState(() {
        _uploadedUrls[documentType] = downloadUrl;
        _selectedFiles[documentType] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$documentType uploadé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur upload: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _skipDocuments() async {
    setState(() => _isLoading = true);

    try {
      // Mettre à jour le statut pour passer à l'étape suivante
      await _db.collection('doctors').doc(widget.doctorId).update({
        'roleData.verification.status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'utilisateur
      await _db.collection('users').doc(widget.doctorId).update({
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Étape des documents terminée !'),
            backgroundColor: Colors.green,
          ),
        );

        // Charger les données du médecin pour le dashboard
        final doctorDoc = await _db.collection('doctors').doc(widget.doctorId).get();
        if (doctorDoc.exists) {
          final doctor = Doctor.fromFirestore(doctorDoc);
          Navigator.pushReplacementNamed(
            context,
            '/doctor-dashboard',
            arguments: doctor,
          );
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAllDocuments() async {
    setState(() => _isLoading = true);

    try {
      // Marquer le statut comme complété
      await _db.collection('doctors').doc(widget.doctorId).update({
        'roleData.verification.status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'utilisateur
      await _db.collection('users').doc(widget.doctorId).update({
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents soumis avec succès !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Charger les données du médecin pour le dashboard
      final doctorDoc = await _db.collection('doctors').doc(widget.doctorId).get();
      if (doctorDoc.exists) {
        final doctor = Doctor.fromFirestore(doctorDoc);
        Navigator.pushReplacementNamed(
          context,
          '/doctor-dashboard',
          arguments: doctor,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDocumentCard(String documentType, String title, String description) {
    final hasFile = _selectedFiles[documentType] != null;
    final hasUploaded = _uploadedUrls[documentType] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(Facultatif en développement)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUploaded)
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (hasUploaded)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Document uploadé',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Voir le document
                      },
                      child: const Text('Voir'),
                    ),
                  ],
                ),
              )
            else if (hasFile)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFiles[documentType]!.path.split('/').last,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _uploadDocument(documentType),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Uploader'),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Sélectionner'),
                    onPressed: () => _pickDocument(documentType),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents professionnels'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Documents facultatifs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'En phase de développement, les documents sont facultatifs. '
                          'Vous pouvez uploader vos documents plus tard ou passer à l\'étape suivante.',
                          style: TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Formats acceptés: JPG, PNG, PDF (max 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Documents
                  _buildDocumentCard(
                    'cni',
                    'Carte Nationale d\'Identité',
                    'Photo recto-verso de votre CNI valide',
                  ),
                  
                  _buildDocumentCard(
                    'diploma',
                    'Diplôme de Médecine',
                    'Votre diplôme de docteur en médecine',
                  ),
                  
                  _buildDocumentCard(
                    'certificate',
                    'Certificat de Spécialisation',
                    'Certificat attestant votre spécialité médicale',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Boutons d'action
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitAllDocuments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Terminer avec ou sans documents',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _skipDocuments,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                          child: const Text(
                            'Passer cette étape pour l\'instant',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vous pourrez uploader ces documents plus tard dans vos paramètres.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}