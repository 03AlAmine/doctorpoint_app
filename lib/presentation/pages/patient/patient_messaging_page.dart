// lib/presentation/pages/patient/patient_messaging_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';


class PatientMessagingPage extends StatefulWidget {
  final Patient patient;

  const PatientMessagingPage({super.key, required this.patient});

  @override
  State<PatientMessagingPage> createState() => _PatientMessagingPageState();
}

class _PatientMessagingPageState extends State<PatientMessagingPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConversationId;
  Doctor? _selectedDoctor;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    if (_selectedConversationId != null) {
      _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _loadMessages();
          _loadConversations(); // Rafraîchir la liste des conversations
        }
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      final snapshot = await _db
          .collection('conversations')
          .where('patientId', isEqualTo: widget.patient.id)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final conversations = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'];
        
        if (doctorId != null) {
          final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
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
              'lastMessageTime': (data['lastMessageTime'] as Timestamp).toDate(),
              'unreadCount': data['unreadCount'] ?? 0,
              'doctorId': data['doctorId'],
              'patientId': data['patientId'],
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
      _selectedDoctor = conversation['doctor'];
      _messages = [];
    });

    await _loadMessages();
    await _markConversationAsRead(conversation['conversationId']);
    _setupMessageListener();
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
          'senderName': data['senderName'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'read': data['read'] ?? false,
          'type': data['type'] ?? 'text', // text, image, file, prescription
          'attachment': data['attachment'],
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
        'senderId': widget.patient.id,
        'senderType': 'patient',
        'senderName': widget.patient.fullName,
        'timestamp': timestamp,
        'read': false,
        'type': 'text',
      });

      // Mettre à jour la conversation
      await _db.collection('conversations').doc(_selectedConversationId).update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': widget.patient.id,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': timestamp,
      });

      // Envoyer une notification au médecin
      await _sendNotificationctor(
        doctorId: _selectedDoctor!.id,
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

  Future<void> _sendNotificationctor({
    required String doctorId,
    required String message,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': doctorId,
        'title': 'Nouveau message de ${widget.patient.fullName}',
        'message': message.length > 50 ? '${message.substring(0, 50)}...' : message,
        'type': 'message',
        'data': {
          'conversationId': _selectedConversationId,
          'patientId': widget.patient.id,
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
      // Marquer tous les messages du médecin comme lus
      final messagesSnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderType', isEqualTo: 'doctor')
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
  }

  Future<void> _createNewConversation(String doctorId) async {
    try {
      // Vérifier si une conversation existe déjà
      final existingConversation = await _db
          .collection('conversations')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: widget.patient.id)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        // Sélectionner la conversation existante
        final conversation = existingConversation.docs.first;
        final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
        
        await _selectConversation({
          'conversationId': conversation.id,
          'doctor': Doctor.fromFirestore(doctorDoc),
        });
        Navigator.pop(context);
        return;
      }

      // Créer une nouvelle conversation
      final conversationId = _db.collection('conversations').doc().id;
      final timestamp = FieldValue.serverTimestamp();

      await _db.collection('conversations').doc(conversationId).set({
        'id': conversationId,
        'doctorId': doctorId,
        'patientId': widget.patient.id,
        'lastMessage': '',
        'lastMessageTime': timestamp,
        'lastMessageSender': '',
        'unreadCount': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      // Récupérer les infos du médecin
      final doctorDoc = await _db.collection('doctors').doc(doctorId).get();
      final doctor = Doctor.fromFirestore(doctorDoc);

      // Sélectionner la nouvelle conversation
      await _selectConversation({
        'conversationId': conversationId,
        'doctor': doctor,
      });

      Navigator.pop(context);
    } catch (e) {
      print('Erreur création conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        final isSelected = _selectedConversationId == conversation['conversationId'];
        final doctor = conversation['doctor'] as Doctor;
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
              backgroundImage: NetworkImage(doctor.imageUrl),
              child: null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dr. ${doctor.name}',
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
    final isPatient = message['senderType'] == 'patient';
    final messageTime = message['timestamp'] as DateTime;
    final isRead = message['read'] ?? false;
    final senderName = message['senderName'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isPatient
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
              crossAxisAlignment: isPatient
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
                    color: isPatient
                        ? AppTheme.primaryColor
                        : Colors.grey[200],
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
                  // : Implémenter la sélection d'image
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Document PDF'),
                onTap: () {
                  // : Implémenter la sélection de document
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
        // Supprimer tous les messages
        final messagesSnapshot = await _db
            .collection('conversations')
            .doc(_selectedConversationId)
            .collection('messages')
            .get();

        final batch = _db.batch();
        for (var doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        batch.delete(_db.collection('conversations').doc(_selectedConversationId!));
        await batch.commit();

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
      } catch (e) {
        print('Erreur suppression conversation: $e');
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
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                backgroundImage: NetworkImage(_selectedDoctor!.imageUrl),
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
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  // : Voir les détails du médecin
                                },
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
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          backgroundImage: NetworkImage(_selectedDoctor!.imageUrl),
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
                              value: 'doctor',
                              child: Text('Profil du médecin'),
                            ),
                            const PopupMenuItem(
                              value: 'clear',
                              child: Text('Effacer la conversation'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'clear') {
                              _deleteConversation();
                            } else if (value == 'doctor') {
                              // : Naviguer vers le profil du médecin
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