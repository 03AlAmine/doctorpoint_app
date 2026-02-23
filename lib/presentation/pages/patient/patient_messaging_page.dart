// lib/presentation/pages/patient/patient_messaging_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PatientMessagingPage extends StatefulWidget {
  final Patient? patient; // Rendre optionnel

  const PatientMessagingPage({super.key, this.patient});

  @override
  State<PatientMessagingPage> createState() => _PatientMessagingPageState();
}

class _PatientMessagingPageState extends State<PatientMessagingPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Patient _patient;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConversationId;
  Doctor? _selectedDoctor;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _isInitialized = false;

  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializePatient();
  }

  Future<void> _initializePatient() async {
    try {
      // 1. Essayer d'utiliser le patient passé en paramètre
      if (widget.patient != null && widget.patient!.id.isNotEmpty) {
        _patient = widget.patient!;
      }
      // 2. Sinon, récupérer depuis Firebase Auth
      else {
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Récupérer depuis Firestore
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final patientDoc = await _db.collection('patients').doc(user.uid).get();

        _patient = Patient(
          id: user.uid,
          uid: user.uid,
          email: user.email ?? '',
          fullName:
              userDoc.data()?['fullName'] ?? user.displayName ?? 'Patient',
          phone: userDoc.data()?['phone'] ?? user.phoneNumber ?? '',
          profileCompleted: patientDoc.data()?['profileCompleted'] ?? false,
          emailVerified: user.emailVerified,
          createdAt: DateTime.now(),
        );
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Charger les conversations
      _loadConversations();
      _setupConversationsListener();
    } catch (e) {
      print('❌ Erreur initialisation patient: $e');
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

// Ajoutez cette méthode dans la classe _PatientMessagingPageState
  Future<void> _deleteConversation() async {
    if (_selectedConversationId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content:
            const Text('Voulez-vous vraiment supprimer cette conversation ?'),
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

        batch.delete(
            _db.collection('conversations').doc(_selectedConversationId!));
        await batch.commit();

        if (mounted) {
          setState(() {
            _selectedConversationId = null;
            _selectedDoctor = null;
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
        .where('patientId', isEqualTo: _patient.id)
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
          .where('patientId', isEqualTo: _patient.id)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final conversations = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'];

        if (doctorId != null && doctorId.toString().isNotEmpty) {
          try {
            final doctorDoc =
                await _db.collection('doctors').doc(doctorId).get();
            if (doctorDoc.exists) {
              final doctor = Doctor.fromFirestore(doctorDoc);

              conversations.add({
                'id': doc.id,
                'conversationId': doc.id,
                'doctor': doctor,
                'doctorName': doctor.name,
                'doctorSpecialization': doctor.specialization,
                'doctorPhoto': doctor.imageUrl,
                'lastMessage': data['lastMessage'] ?? '',
                'lastMessageTime': data['lastMessageTime'] != null
                    ? (data['lastMessageTime'] as Timestamp).toDate()
                    : DateTime.now(),
                'unreadCount': data['unreadCount'] ?? 0,
                'doctorId': data['doctorId'],
                'patientId': data['patientId'],
              });
            }
          } catch (e) {
            print('Erreur chargement docteur $doctorId: $e');
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
        _selectedDoctor = conversation['doctor'];
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

    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Médecin non identifié'),
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
        'senderId': _patient.id,
        'senderName':
            _patient.fullName.isNotEmpty ? _patient.fullName : 'Patient',
        'senderType': 'patient',
        'timestamp': timestamp,
        'read': false,
        'type': 'text',
      });

      // Mettre à jour la conversation
      await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': _patient.id,
        'lastMessageSenderName': _patient.fullName,
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
          .where('senderType', isEqualTo: 'doctor')
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

  Future<void> _startNewConversation() async {
    try {
      final doctorsSnapshot = await _db
          .collection('doctors')
          .where('accountStatus', isEqualTo: 'active')
          .orderBy('name')
          .get();

      final doctors = doctorsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'specialization': data['specialization'] ?? '',
          'imageUrl': data['imageUrl'],
          'hospital': data['hospital'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nouvelle conversation'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: doctor['imageUrl'] != null
                        ? NetworkImage(doctor['imageUrl']!)
                        : null,
                    child: doctor['imageUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(doctor['name']),
                  subtitle: Text(doctor['specialization']),
                  trailing: ElevatedButton(
                    onPressed: () => _createNewConversation(doctor['id']),
                    child: const Text('Message'),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erreur chargement médecins: $e');
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

  Future<void> _createNewConversation(String doctorId) async {
    try {
      if (_patient.id.isEmpty) {
        throw Exception('Patient ID is empty');
      }

      final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
      if (!doctorDoc.exists) {
        throw Exception('Doctor not found');
      }

      final doctor = Doctor.fromFirestore(doctorDoc);

      // Vérifier si une conversation existe déjà
      final existingConversation = await _db
          .collection('conversations')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: _patient.id)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        final conversation = existingConversation.docs.first;
        await _selectConversation({
          'conversationId': conversation.id,
          'doctor': doctor,
        });
        if (mounted) Navigator.pop(context);
        return;
      }

      // Créer une nouvelle conversation
      final conversationId = _db.collection('conversations').doc().id;
      final timestamp = FieldValue.serverTimestamp();

      final conversationData = {
        'id': conversationId,
        'doctorId': doctorId,
        'doctorName': doctor.name,
        'patientId': _patient.id,
        'patientName':
            _patient.fullName.isNotEmpty ? _patient.fullName : 'Patient',
        'lastMessage': '',
        'lastMessageTime': timestamp,
        'lastMessageSender': '',
        'lastMessageSenderName': '',
        'unreadCount': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      await _db
          .collection('conversations')
          .doc(conversationId)
          .set(conversationData);

      await _selectConversation({
        'conversationId': conversationId,
        'doctor': doctor,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ Erreur création conversation: $e');
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
      appBar: AppBar(
        title: const Text('Messagerie'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    border:
                        Border(right: BorderSide(color: AppTheme.borderColor)),
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
                Expanded(
                  child: Column(
                    children: [
                      if (_selectedDoctor != null)
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
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.1),
                                backgroundImage:
                                    NetworkImage(_selectedDoctor!.imageUrl),
                                child: null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${_selectedDoctor!.name}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedDoctor!.specialization,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.greyColor,
                                      ),
                                    ),
                                    Text(
                                      _selectedDoctor!.hospital,
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
                      Expanded(child: _buildMessagesList()),
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                if (_selectedDoctor != null)
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
                              _selectedDoctor = null;
                            });
                          },
                        ),
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage:
                              NetworkImage(_selectedDoctor!.imageUrl),
                          child: null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${_selectedDoctor!.name}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedDoctor!.specialization,
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
                Expanded(
                  child: _selectedConversationId == null
                      ? _buildConversationList()
                      : _buildMessagesList(),
                ),
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
              child: const Text('Nouvelle conversation'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final isSelected =
            _selectedConversationId == conversation['conversationId'];
        final doctor = conversation['doctor'] as Doctor;
        final unreadCount = conversation['unreadCount'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
            border: isSelected
                ? Border(
                    left: BorderSide(color: AppTheme.primaryColor, width: 3))
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: NetworkImage(doctor.imageUrl),
              child: null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dr. ${doctor.name}',
                    style: TextStyle(
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  doctor.specialization,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  conversation['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.black : AppTheme.greyColor,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
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
    final isPatient = message['senderType'] == 'patient';
    final messageTime = message['timestamp'] as DateTime;
    final isRead = message['read'] ?? false;
    final senderName = message['senderName'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isPatient && _selectedDoctor != null)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: NetworkImage(_selectedDoctor!.imageUrl),
                child: null,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isPatient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isPatient)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      senderName.isNotEmpty ? 'Dr. $senderName' : 'Médecin',
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
                    color: isPatient ? AppTheme.primaryColor : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(
                      color: isPatient ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: isPatient
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
                    if (isPatient && isRead)
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
              child: const Text('Nouvelle conversation'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
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
              'Envoyez le premier message',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
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
            onPressed: () {
              _showAttachmentMenu();
            },
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
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Document PDF'),
                onTap: () {
                  Navigator.pop(context);
                },
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

}
