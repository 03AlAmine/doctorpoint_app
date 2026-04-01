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

class _DoctorMessagingPageState extends State<DoctorMessagingPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConversationId;
  Patient? _selectedPatient;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  bool _isInitialized = false;
  bool _isSending = false;

  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      if (widget.doctor.id.isEmpty) {
        throw Exception('ID du docteur invalide');
      }

      setState(() {
        _isInitialized = true;
      });

      await _loadConversations();
      _setupConversationsListener();
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        _showErrorSnackBar('Erreur de chargement: $e');
      }
    }
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
      print('❌ Erreur listener conversations: $error');
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
      print('❌ Erreur listener messages: $error');
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
            final patientDoc =
                await _db.collection('patients').doc(patientId).get();
            final userDoc = await _db.collection('users').doc(patientId).get();

            if (patientDoc.exists || userDoc.exists) {
              final patient = Patient(
                id: patientId,
                uid: patientId,
                email: userDoc.data()?['email'] ?? '',
                fullName: userDoc.data()?['fullName'] ??
                    patientDoc.data()?['fullName'] ??
                    'Patient',
                phone: userDoc.data()?['phone'] ?? '',
                photoUrl: patientDoc.data()?['photoUrl'] ??
                    userDoc.data()?['photoUrl'],
                profileCompleted:
                    patientDoc.data()?['profileCompleted'] ?? false,
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
                'isOnline': data['isOnline'] ?? false,
                'lastSeen': data['lastSeen'] != null
                    ? (data['lastSeen'] as Timestamp).toDate()
                    : null,
              });
            }
          } catch (e) {
            print('❌ Erreur chargement patient $patientId: $e');
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
      print('❌ Erreur chargement conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur de chargement des conversations');
      }
    }
  }

  Future<void> _selectConversation(Map<String, dynamic> conversation) async {
    final conversationId = conversation['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      _showErrorSnackBar('ID de conversation invalide');
      return;
    }

    setState(() {
      _selectedConversationId = conversationId;
      _selectedPatient = conversation['patient'];
      _messages = [];
      _isLoadingMessages = true;
    });

    _setupMessagesListener(conversationId);
    await _loadMessages();
    await _markConversationAsRead(conversationId);

    setState(() => _isLoadingMessages = false);

    // Scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
          'delivered': data['delivered'] ?? false,
        };
      }).toList();

      if (mounted) {
        setState(() => _messages = messages);
      }
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
      if (mounted) {
        _showErrorSnackBar('Erreur de chargement des messages');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    if (_selectedConversationId == null || _selectedConversationId!.isEmpty) {
      _showErrorSnackBar('Aucune conversation sélectionnée');
      return;
    }

    if (_selectedPatient == null) {
      _showErrorSnackBar('Patient non identifié');
      return;
    }

    final messageText = _messageController.text.trim();
    final messageId = _db.collection('messages').doc().id;
    final timestamp = FieldValue.serverTimestamp();

    setState(() {
      _isSending = true;
    });

    try {
      final conversationDoc = await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .get();

      if (!conversationDoc.exists) {
        throw Exception('Conversation non trouvée');
      }

      // Ajouter le message
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
        'delivered': true,
        'type': 'text',
      });

      // Mettre à jour la conversation
      await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': widget.doctor.id,
        'lastMessageSenderName': widget.doctor.name,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': timestamp,
      });

      _messageController.clear();

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      _showErrorSnackBar("Échec de l'envoi du message");
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
      print('❌ Erreur marquage messages comme lus: $e');
    }
  }

  Future<void> _deleteConversation() async {
    if (_selectedConversationId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette conversation ? Cette action est irréversible.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showLoadingDialog('Suppression en cours...');

        final batch = _db.batch();

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
          Navigator.pop(context); // Fermer le dialogue de chargement
          setState(() {
            _selectedConversationId = null;
            _selectedPatient = null;
            _messages.clear();
          });
          await _loadConversations();

          _showSuccessSnackBar('Conversation supprimée');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Fermer le dialogue de chargement
          _showErrorSnackBar('Erreur lors de la suppression');
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des conversations...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez patienter',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Erreur d\'initialisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les conversations',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initialize,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversations() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: AppTheme.greyColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Vous n\'avez pas encore de messages. Commencez une conversation avec vos patients.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add),
              label: const Text('Démarrer une conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message_outlined,
              size: 60,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez la conversation en envoyant un message',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    if (_conversations.isEmpty) {
      return _buildEmptyConversations();
    }

    final filteredConversations = _searchController.text.isEmpty
        ? _conversations
        : _conversations.where((conv) {
            final patient = conv['patient'] as Patient;
            return patient.fullName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un patient...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredConversations.length,
            itemBuilder: (context, index) {
              if (index >= filteredConversations.length) {
                return const SizedBox.shrink();
              }

              final conversation = filteredConversations[index];
              final isSelected =
                  _selectedConversationId == conversation['conversationId'];
              final patient = conversation['patient'] as Patient?;

              if (patient == null) {
                return const SizedBox.shrink();
              }

              final unreadCount = conversation['unreadCount'] ?? 0;
              final isOnline = conversation['isOnline'] ?? false;
              final lastMessageTime =
                  conversation['lastMessageTime'] as DateTime;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : null,
                  border: isSelected
                      ? Border(
                          left: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 4,
                          ),
                        )
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: patient.photoUrl != null
                            ? NetworkImage(patient.photoUrl!)
                            : null,
                        child: patient.photoUrl == null
                            ? Text(
                                patient.fullName.isNotEmpty
                                    ? patient.fullName[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.fullName.isNotEmpty
                              ? patient.fullName
                              : 'Patient',
                          style: TextStyle(
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation['lastMessage'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0
                                    ? AppTheme.textColor
                                    : AppTheme.greyColor,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatMessageTime(lastMessageTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _selectConversation(conversation),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isDoctor = message['senderType'] == 'doctor';
    final messageTime = message['timestamp'] as DateTime;
    final isRead = message['read'] ?? false;
    final senderName = message['senderName'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isDoctor ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isDoctor && _selectedPatient != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: _selectedPatient!.photoUrl != null
                    ? NetworkImage(_selectedPatient!.photoUrl!)
                    : null,
                child: _selectedPatient!.photoUrl == null
                    ? Text(
                        _selectedPatient!.fullName.isNotEmpty
                            ? _selectedPatient!.fullName[0].toUpperCase()
                            : 'P',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isDoctor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isDoctor && senderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 11,
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
                    color: isDoctor ? AppTheme.primaryColor : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message['text'],
                    style: TextStyle(
                      color: isDoctor ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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
                    if (isDoctor) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color:
                            isRead ? AppTheme.primaryColor : AppTheme.greyColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isDoctor) const SizedBox(width: 40), // Espace pour aligner
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
              size: 100,
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez une conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez un patient pour commencer à discuter',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyMessages();
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
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
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
          ),
        ),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showAttachmentMenu,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tapez votre message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withBlue(200),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              color: Colors.white,
              onPressed: _isSending ? null : _sendMessage,
            ),
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Joindre un fichier',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image, color: Colors.green),
                ),
                title: const Text('Image'),
                subtitle: const Text('Photo ou galerie'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text('Document PDF'),
                subtitle: const Text('Fichier PDF'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.blue),
                ),
                title: const Text('Prescription'),
                subtitle: const Text('Ordonnance médicale'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle conversation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rechercher un patient...'),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Nom du patient',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar('Conversation démarrée');
              },
              child: const Text('Démarrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (!_isInitialized) {
      return _buildErrorState();
    }

    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;

    return isDesktop
        ? Row(
            children: [
              // Liste des conversations
              Container(
                width: 380,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: AppTheme.borderColor.withOpacity(0.5),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.borderColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Conversations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _startNewConversation,
                              color: AppTheme.primaryColor,
                              tooltip: 'Nouvelle conversation',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildConversationList(),
                    ),
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
                            bottom: BorderSide(
                              color: AppTheme.borderColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: _selectedPatient!.photoUrl !=
                                      null
                                  ? NetworkImage(_selectedPatient!.photoUrl!)
                                  : null,
                              child: _selectedPatient!.photoUrl == null
                                  ? Text(
                                      _selectedPatient!.fullName.isNotEmpty
                                          ? _selectedPatient!.fullName[0]
                                              .toUpperCase()
                                          : 'P',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'En ligne',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.greyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (context) =>
                                    <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'profile',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.blue),
                                        SizedBox(width: 12),
                                        Text('Voir le profil'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'appointments',
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: Colors.green),
                                        SizedBox(width: 12),
                                        Text('Historique RDV'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'prescriptions',
                                    child: Row(
                                      children: [
                                        Icon(Icons.medical_services,
                                            color: Colors.orange),
                                        SizedBox(width: 12),
                                        Text('Prescriptions'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'clear',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Supprimer',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'clear') {
                                    _deleteConversation();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Messages
                    Expanded(
                      child: Container(
                        color: Colors.grey[50],
                        child: _buildMessagesList(),
                      ),
                    ),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderColor.withOpacity(0.5),
                      ),
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
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: _selectedPatient!.photoUrl != null
                            ? NetworkImage(_selectedPatient!.photoUrl!)
                            : null,
                        child: _selectedPatient!.photoUrl == null
                            ? Text(
                                _selectedPatient!.fullName.isNotEmpty
                                    ? _selectedPatient!.fullName[0]
                                        .toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
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
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'En ligne',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue),
                                SizedBox(width: 12),
                                Text('Voir le profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'appointments',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.green),
                                SizedBox(width: 12),
                                Text('Historique RDV'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'clear',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Supprimer',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
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
                    : Container(
                        color: Colors.grey[50],
                        child: _buildMessagesList(),
                      ),
              ),
              // Champ de saisie
              _buildMessageInput(),
            ],
          );
  }
}
