// lib/presentation/pages/doctor/doctor_messaging_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'dart:async';

class DoctorMessagingPage extends StatefulWidget {
  final Doctor doctor;

  const DoctorMessagingPage({super.key, required this.doctor});

  @override
  State<DoctorMessagingPage> createState() => _DoctorMessagingPageState();
}

class _DoctorMessagingPageState extends State<DoctorMessagingPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConversationId;
  Patient? _selectedPatient;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _isInitialized = false;
  
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Vérifier que le docteur a un ID valide
      if (widget.doctor.id.isEmpty) {
        throw Exception('Doctor ID is empty');
      }
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Charger les conversations
      _loadConversations();
      _setupConversationsListener();
      
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _setupConversationsListener() {
    if (!_isInitialized) return;
    
    _conversationsSubscription = _db
        .collection('conversations')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            _loadConversations();
          }
        }, onError: (error) {
          print('Erreur listener conversations: $error');
        });
  }

  void _setupMessagesListener(String conversationId) {
    _messagesSubscription?.cancel();
    
    _messagesSubscription = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            _loadMessages();
            _markConversationAsRead(conversationId);
          }
        }, onError: (error) {
          print('Erreur listener messages: $error');
        });
  }

  Future<void> _loadConversations() async {
    if (!_isInitialized) return;
    
    try {
      final snapshot = await _db
          .collection('conversations')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final conversations = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'];
        
        if (patientId != null && patientId.toString().isNotEmpty) {
          try {
            final patientDoc = await _db.collection('patients').doc(patientId).get();
            final userDoc = await _db.collection('users').doc(patientId).get();
            
            if (patientDoc.exists || userDoc.exists) {
              // Créer un objet Patient avec les données disponibles
              final patient = Patient(
                id: patientId,
                uid: patientId,
                email: userDoc.data()?['email'] ?? '',
                fullName: userDoc.data()?['fullName'] ?? 
                          patientDoc.data()?['fullName'] ?? 
                          'Patient',
                phone: userDoc.data()?['phone'] ?? '',
                photoUrl: patientDoc.data()?['photoUrl'] ?? userDoc.data()?['photoUrl'],
                profileCompleted: patientDoc.data()?['profileCompleted'] ?? false,
                emailVerified: false,
                createdAt: DateTime.now(),
              );
              
              conversations.add({
                'id': doc.id,
                'conversationId': doc.id,
                'patient': patient,
                'patientName': patient.fullName,
                'patientPhoto': patient.photoUrl,
                'lastMessage': data['lastMessage'] ?? '',
                'lastMessageTime': data['lastMessageTime'] != null
                    ? (data['lastMessageTime'] as Timestamp).toDate()
                    : DateTime.now(),
                'unreadCount': data['unreadCount'] ?? 0,
                'doctorId': data['doctorId'],
                'patientId': patientId,
              });
            }
          } catch (e) {
            print('Erreur chargement patient $patientId: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectConversation(Map<String, dynamic> conversation) async {
    final conversationId = conversation['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      print('Erreur: ID de conversation invalide');
      return;
    }

    if (mounted) {
      setState(() {
        _selectedConversationId = conversationId;
        _selectedPatient = conversation['patient'];
        _messages = [];
      });
    }

    _setupMessagesListener(conversationId);
    await _loadMessages();
    await _markConversationAsRead(conversationId);
  }

  Future<void> _loadMessages() async {
    if (_selectedConversationId == null || _selectedConversationId!.isEmpty) {
      return;
    }

    try {
      final snapshot = await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'senderId': data['senderId'] ?? '',
          'senderType': data['senderType'] ?? '',
          'senderName': data['senderName'] ?? '',
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'read': data['read'] ?? false,
          'type': data['type'] ?? 'text',
        };
      }).toList();

      if (mounted) {
        setState(() => _messages = messages);
      }
    } catch (e) {
      print('Erreur chargement messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_selectedConversationId == null || _selectedConversationId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune conversation sélectionnée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient non identifié'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    final messageId = _db.collection('messages').doc().id;
    final timestamp = FieldValue.serverTimestamp();

    try {
      // Vérifier que la conversation existe
      final conversationDoc = await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .get();
      
      if (!conversationDoc.exists) {
        throw Exception('Conversation non trouvée');
      }

      // Envoyer le message
      await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'text': messageText,
        'senderId': widget.doctor.id,
        'senderName': widget.doctor.name,
        'senderType': 'doctor',
        'timestamp': timestamp,
        'read': false,
        'type': 'text',
      });

      // Mettre à jour la conversation
      await _db.collection('conversations').doc(_selectedConversationId).update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': widget.doctor.id,
        'lastMessageSenderName': widget.doctor.name,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': timestamp,
      });

      _messageController.clear();
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    if (conversationId.isEmpty) return;

    try {
      final messagesSnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderType', isEqualTo: 'patient')
          .get();

      if (messagesSnapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      batch.update(
        _db.collection('conversations').doc(conversationId),
        {'unreadCount': 0},
      );

      await batch.commit();
      await _loadConversations();
    } catch (e) {
      print('Erreur marquage messages comme lus: $e');
    }
  }

  Future<void> _deleteConversation() async {
    if (_selectedConversationId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text('Voulez-vous vraiment supprimer cette conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = _db.batch();
        
        // Supprimer tous les messages
        final messagesSnapshot = await _db
            .collection('conversations')
            .doc(_selectedConversationId)
            .collection('messages')
            .get();

        for (var doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        batch.delete(_db.collection('conversations').doc(_selectedConversationId!));
        await batch.commit();

        if (mounted) {
          setState(() {
            _selectedConversationId = null;
            _selectedPatient = null;
            _messages.clear();
          });
          await _loadConversations();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Erreur suppression conversation: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildConversationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppTheme.greyColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _startNewConversation,
              child: const Text('Démarrer une conversation'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        // Vérification que l'index est valide
        if (index >= _conversations.length) {
          return const SizedBox.shrink();
        }
        
        final conversation = _conversations[index];
        final isSelected = _selectedConversationId == conversation['conversationId'];
        final patient = conversation['patient'] as Patient?;
        
        if (patient == null) {
          return const SizedBox.shrink();
        }
        
        final unreadCount = conversation['unreadCount'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
            border: isSelected
                ? Border(left: BorderSide(color: AppTheme.primaryColor, width: 3))
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: patient.photoUrl != null
                  ? NetworkImage(patient.photoUrl!)
                  : null,
              child: patient.photoUrl == null
                  ? Text(
                      patient.fullName.isNotEmpty
                          ? patient.fullName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    patient.fullName.isNotEmpty ? patient.fullName : 'Patient',
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  conversation['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.black : AppTheme.greyColor,
                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(conversation['lastMessageTime']),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
            onTap: () => _selectConversation(conversation),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isDoctor = message['senderType'] == 'doctor';
    final messageTime = message['timestamp'] as DateTime;
    final isRead = message['read'] ?? false;
    final senderName = message['senderName'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isDoctor
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isDoctor && _selectedPatient != null)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: _selectedPatient!.photoUrl != null
                    ? NetworkImage(_selectedPatient!.photoUrl!)
                    : null,
                child: _selectedPatient!.photoUrl == null
                    ? Text(
                        _selectedPatient!.fullName.isNotEmpty
                            ? _selectedPatient!.fullName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isDoctor
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isDoctor && senderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDoctor
                        ? AppTheme.primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(
                      color: isDoctor ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: isDoctor
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(messageTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.greyColor,
                      ),
                    ),
                    if (isDoctor && isRead)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.done_all,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_selectedConversationId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: 80,
              color: AppTheme.greyColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez une conversation',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _startNewConversation,
              child: const Text('Démarrer une conversation'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Aucun message',
          style: TextStyle(
            color: AppTheme.greyColor,
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // Vérification que l'index est valide
        if (index >= _messages.length) {
          return const SizedBox.shrink();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageInput() {
    if (_selectedConversationId == null) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentMenu,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppTheme.primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.green),
                title: const Text('Image'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Document PDF'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.blue),
                title: const Text('Prescription'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startNewConversation() {
    // TODO: Implémenter la recherche de patients
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité à venir'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur d\'initialisation'),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                // Liste des conversations
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: _startNewConversation,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle conversation'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                      Expanded(child: _buildConversationList()),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: Column(
                    children: [
                      // En-tête de conversation
                      if (_selectedPatient != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                backgroundImage: _selectedPatient!.photoUrl != null
                                    ? NetworkImage(_selectedPatient!.photoUrl!)
                                    : null,
                                child: _selectedPatient!.photoUrl == null
                                    ? Text(
                                        _selectedPatient!.fullName.isNotEmpty
                                            ? _selectedPatient!.fullName[0].toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedPatient!.fullName.isNotEmpty
                                          ? _selectedPatient!.fullName
                                          : 'Patient',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedPatient!.age > 0)
                                      Text(
                                        '${_selectedPatient!.age} ans • ${_selectedPatient!.gender ?? 'Non spécifié'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.greyColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'clear',
                                    child: Text('Effacer la conversation'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'clear') {
                                    _deleteConversation();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      // Messages
                      Expanded(child: _buildMessagesList()),
                      // Champ de saisie
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // En-tête de conversation (sur mobile)
                if (_selectedPatient != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              _selectedConversationId = null;
                              _selectedPatient = null;
                            });
                          },
                        ),
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: _selectedPatient!.photoUrl != null
                              ? NetworkImage(_selectedPatient!.photoUrl!)
                              : null,
                          child: _selectedPatient!.photoUrl == null
                              ? Text(
                                  _selectedPatient!.fullName.isNotEmpty
                                      ? _selectedPatient!.fullName[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPatient!.fullName.isNotEmpty
                                    ? _selectedPatient!.fullName
                                    : 'Patient',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'En ligne',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'clear',
                              child: Text('Effacer la conversation'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'clear') {
                              _deleteConversation();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                // Liste des conversations ou messages
                Expanded(
                  child: _selectedConversationId == null
                      ? _buildConversationList()
                      : _buildMessagesList(),
                ),
                // Champ de saisie
                _buildMessageInput(),
              ],
            ),
      floatingActionButton: _selectedConversationId == null
          ? FloatingActionButton(
              onPressed: _startNewConversation,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add_comment),
            )
          : null,
    );
  }
}