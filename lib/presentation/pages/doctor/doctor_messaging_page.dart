// lib/presentation/pages/doctor/doctor_messaging_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:doctorpoint/data/models/patient_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
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
        
        if (patientId != null) {
          final patientDoc = await _db.collection('patients').doc(patientId).get();
          if (patientDoc.exists) {
            final patient = Patient.fromFirestore(patientDoc);
            
            conversations.add({
              'id': doc.id,
              'conversationId': doc.id,
              'patient': patient,
              'patientName': patient.fullName,
              'patientPhoto': patient.photoUrl,
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': (data['lastMessageTime'] as Timestamp).toDate(),
              'unreadCount': data['unreadCount'] ?? 0,
              'doctorId': data['doctorId'],
              'patientId': patientId,
            });
          }
        }
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectConversation(Map<String, dynamic> conversation) async {
    setState(() {
      _selectedConversationId = conversation['conversationId'];
      _selectedPatient = conversation['patient'];
      _messages = [];
    });

    await _loadMessages();
    await _markConversationAsRead(conversation['conversationId']);
  }

  Future<void> _loadMessages() async {
    if (_selectedConversationId == null) return;

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
          'senderId': data['senderId'],
          'senderType': data['senderType'], // 'doctor' ou 'patient'
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'read': data['read'] ?? false,
          'type': data['type'] ?? 'text', // text, image, file, prescription
        };
      }).toList();

      setState(() => _messages = messages);
    } catch (e) {
      print('Erreur chargement messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || 
        _selectedConversationId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    final messageId = _db.collection('messages').doc().id;
    final timestamp = FieldValue.serverTimestamp();

    try {
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
        'senderType': 'doctor',
        'senderName': widget.doctor.name,
        'timestamp': timestamp,
        'read': false,
        'type': 'text',
      });

      // Mettre à jour la conversation
      await _db.collection('conversations').doc(_selectedConversationId).update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': widget.doctor.id,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': timestamp,
      });

      // Envoyer une notification au patient
      await _sendNotificationToPatient(
        patientId: _selectedPatient!.id,
        message: messageText,
      );

      // Recharger les messages
      await _loadMessages();
      
      _messageController.clear();
    } catch (e) {
      print('Erreur envoi message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'envoi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotificationToPatient({
    required String patientId,
    required String message,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': patientId,
        'title': 'Nouveau message du Dr. ${widget.doctor.name}',
        'message': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        'type': 'message',
        'data': {
          'conversationId': _selectedConversationId,
          'doctorId': widget.doctor.id,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur envoi notification: $e');
    }
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    try {
      // Marquer tous les messages comme lus
      final messagesSnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderType', isEqualTo: 'patient')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.update({'read': true});
      }

      // Réinitialiser le compteur de messages non lus
      await _db.collection('conversations').doc(conversationId).update({
        'unreadCount': 0,
      });

      // Recharger les conversations
      await _loadConversations();
    } catch (e) {
      print('Erreur marquage messages comme lus: $e');
    }
  }

  Future<void> _startNewConversation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recherche de patient
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Rechercher un patient',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _searchPatients,
              ),
              const SizedBox(height: 16),
              // Liste des patients (à implémenter)
              // ...
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _searchPatients(String query) {
    // Implémenter la recherche de patients
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
        final conversation = _conversations[index];
        final isSelected = _selectedConversationId == conversation['conversationId'];
        final patient = conversation['patient'] as Patient;
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
                      patient.fullName.split(' ').map((n) => n[0]).take(2).join(),
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
                    patient.fullName,
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
                        _selectedPatient!.fullName
                            .split(' ')
                            .map((n) => n[0])
                            .take(1)
                            .join(),
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
              // Attacher un fichier
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
                  // Implémenter la sélection d'image
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Document PDF'),
                onTap: () {
                  // Implémenter la sélection de document
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.blue),
                title: const Text('Prescription'),
                onTap: () {
                  // Implémenter l'envoi de prescription
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

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Recherche de conversations
            },
          ),
        ],
      ),
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
                                        _selectedPatient!.fullName
                                            .split(' ')
                                            .map((n) => n[0])
                                            .take(1)
                                            .join(),
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
                                      _selectedPatient!.fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                              IconButton(
                                icon: const Icon(Icons.videocam),
                                onPressed: () {
                                  // Appel vidéo
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.call),
                                onPressed: () {
                                  // Appel audio
                                },
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'medical',
                                    child: Text('Dossier médical'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'appointment',
                                    child: Text('Prendre rendez-vous'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'clear',
                                    child: Text('Effacer la conversation'),
                                  ),
                                ],
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
                                  _selectedPatient!.fullName
                                      .split(' ')
                                      .map((n) => n[0])
                                      .take(1)
                                      .join(),
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
                                _selectedPatient!.fullName,
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
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Menu d'options
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