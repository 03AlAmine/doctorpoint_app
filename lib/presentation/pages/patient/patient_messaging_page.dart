// lib/presentation/pages/patient/patient_messaging_page.dart
// REDESIGN COMPLET - Style cohérent avec doctor_messaging_page

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:doctorpoint/core/theme/app_theme.dart';
import 'package:doctorpoint/data/models/patient_model.dart';
import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PatientMessagingPage extends StatefulWidget {
  final Patient? patient;

  const PatientMessagingPage({super.key, this.patient});

  @override
  State<PatientMessagingPage> createState() => _PatientMessagingPageState();
}

class _PatientMessagingPageState extends State<PatientMessagingPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Patient _patient;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConversationId;
  Doctor? _selectedDoctor;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  bool _isInitialized = false;

  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  late AnimationController _typingAnimationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _initializePatient();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializePatient() async {
    try {
      if (widget.patient != null && widget.patient!.id.isNotEmpty) {
        _patient = widget.patient!;
      } else {
        final user = _auth.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');

        final userDoc = await _db.collection('users').doc(user.uid).get();
        final patientDoc =
            await _db.collection('patients').doc(user.uid).get();

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

      await _loadConversations();
      _setupConversationsListener();
      _fadeController.forward();
    } catch (e) {
      print('❌ Erreur initialisation patient: $e');
      setState(() => _isLoading = false);
      if (mounted) _showErrorSnackBar('Erreur: $e');
    }
  }

  void _setupConversationsListener() {
    if (!_isInitialized) return;
    _conversationsSubscription = _db
        .collection('conversations')
        .where('patientId', isEqualTo: _patient.id)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) _loadConversations();
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
                'isOnline': data['isOnline'] ?? false,
              });
            }
          } catch (e) {
            print('❌ Erreur chargement docteur $doctorId: $e');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectConversation(Map<String, dynamic> conversation) async {
    final conversationId = conversation['conversationId']?.toString();
    if (conversationId == null || conversationId.isEmpty) return;

    setState(() {
      _selectedConversationId = conversationId;
      _selectedDoctor = conversation['doctor'];
      _messages = [];
      _isLoadingMessages = true;
    });

    _setupMessagesListener(conversationId);
    await _loadMessages();
    await _markConversationAsRead(conversationId);

    setState(() => _isLoadingMessages = false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

      if (mounted) setState(() => _messages = messages);
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    if (_selectedConversationId == null || _selectedConversationId!.isEmpty) {
      _showErrorSnackBar('Aucune conversation sélectionnée');
      return;
    }
    if (_selectedDoctor == null) {
      _showErrorSnackBar('Médecin non identifié');
      return;
    }

    final messageText = _messageController.text.trim();
    final messageId = _db.collection('messages').doc().id;
    final timestamp = FieldValue.serverTimestamp();

    setState(() => _isSending = true);

    try {
      final conversationDoc = await _db
          .collection('conversations')
          .doc(_selectedConversationId)
          .get();
      if (!conversationDoc.exists) throw Exception('Conversation non trouvée');

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
        'delivered': true,
      });

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
      _scrollToBottom();
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      if (mounted) _showErrorSnackBar('Erreur d\'envoi: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
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
    } catch (e) {
      print('❌ Erreur marquage lu: $e');
    }
  }

  Future<void> _deleteConversation() async {
    if (_selectedConversationId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Supprimer la conversation',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Cette action est irréversible. Tous les messages seront supprimés.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
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
          setState(() {
            _selectedConversationId = null;
            _selectedDoctor = null;
            _messages.clear();
          });
          await _loadConversations();
          _showSuccessSnackBar('Conversation supprimée');
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Erreur: $e');
      }
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
        return Doctor.fromFirestore(doc);
      }).toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildNewConversationSheet(doctors),
      );
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<void> _createNewConversation(String doctorId) async {
    Navigator.pop(context);
    try {
      // Vérifier si une conversation existe déjà
      final existingSnapshot = await _db
          .collection('conversations')
          .where('patientId', isEqualTo: _patient.id)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      String conversationId;
      if (existingSnapshot.docs.isNotEmpty) {
        conversationId = existingSnapshot.docs.first.id;
      } else {
        final newConv = await _db.collection('conversations').add({
          'patientId': _patient.id,
          'doctorId': doctorId,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        conversationId = newConv.id;
      }

      await _loadConversations();
      final conv = _conversations.firstWhere(
        (c) => c['conversationId'] == conversationId,
        orElse: () => {},
      );
      if (conv.isNotEmpty) {
        await _selectConversation(conv);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur création conversation: $e');
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (!_isInitialized) return _buildErrorState();

    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ── Loading ──
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement de vos messages...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text('Erreur d\'initialisation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _initializePatient,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop layout ──
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar conversations
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildConversationListHeader(),
              Expanded(child: _buildConversationList()),
            ],
          ),
        ),
        // Zone messages
        Expanded(
          child: Column(
            children: [
              _buildMessagesHeader(),
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F7FA),
                  child: _buildMessagesList(),
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ──
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: _selectedConversationId == null
              ? _buildConversationList()
              : Container(
                  color: const Color(0xFFF5F7FA),
                  child: _buildMessagesList(),
                ),
        ),
        if (_selectedConversationId != null) _buildMessageInput(),
        if (_selectedConversationId == null)
          _buildNewConversationFAB(),
      ],
    );
  }

  // ── Header conversation list ──
  Widget _buildConversationListHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Messagerie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_comment_outlined,
                      color: Colors.white, size: 20),
                  onPressed: _startNewConversation,
                  tooltip: 'Nouvelle conversation',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un médecin...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile header ──
  Widget _buildMobileHeader() {
    if (_selectedConversationId != null && _selectedDoctor != null) {
      // Header conversation active
      return Container(
        padding: EdgeInsets.fromLTRB(
          8,
          MediaQuery.of(context).padding.top + 8,
          16,
          12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.85)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedConversationId = null;
                    _selectedDoctor = null;
                    _messages.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            _buildDoctorAvatar(_selectedDoctor!, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${_selectedDoctor!.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _selectedDoctor!.specialization,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildConversationActions(),
          ],
        ),
      );
    }

    // Header liste conversations
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.85)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Messagerie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _loadConversations,
                  tooltip: 'Rafraîchir',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un médecin...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header messages (desktop) ──
  Widget _buildMessagesHeader() {
    if (_selectedDoctor == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline,
                color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sélectionnez une conversation',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildDoctorAvatar(_selectedDoctor!, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${_selectedDoctor!.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _selectedDoctor!.specialization,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          _buildConversationActions(),
        ],
      ),
    );
  }

  Widget _buildConversationActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Text('Voir le profil'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'appointments',
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green, size: 20),
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
                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Supprimer',
                    style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'clear') _deleteConversation();
        },
      ),
    );
  }

  // ── Liste conversations ──
  Widget _buildConversationList() {
    final filtered = _searchController.text.isEmpty
        ? _conversations
        : _conversations.where((conv) {
            final doctor = conv['doctor'] as Doctor;
            return doctor.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
          }).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filtered.isEmpty) {
      return _buildEmptyConversations();
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final conversation = filtered[index];
        final isSelected =
            _selectedConversationId == conversation['conversationId'];
        final doctor = conversation['doctor'] as Doctor;
        final unreadCount = conversation['unreadCount'] ?? 0;
        final isOnline = conversation['isOnline'] ?? false;
        final lastMessageTime = conversation['lastMessageTime'] as DateTime;

        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.08)
                : Colors.transparent,
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
                _buildDoctorAvatar(doctor, radius: 26),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dr. ${doctor.name}',
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                const SizedBox(height: 2),
                Text(
                  doctor.specialization,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? Colors.black87
                              : Colors.grey.shade500,
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
                        color: Colors.grey.shade400,
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
    );
  }

  Widget _buildEmptyConversations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 46,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par contacter un médecin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: const Text('Nouvelle conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Liste messages ──
  Widget _buildMessagesList() {
    if (_selectedConversationId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_rounded,
                size: 46,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sélectionnez une conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingMessages) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 36,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Envoyez le premier message',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isPatient = message['senderType'] == 'patient';
    final messageTime = message['timestamp'] as DateTime;
    final isRead = message['read'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isPatient && _selectedDoctor != null) ...[
            _buildDoctorAvatar(_selectedDoctor!, radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isPatient
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isPatient)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      'Dr. ${_selectedDoctor?.name ?? "Médecin"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: isPatient
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.85),
                            ],
                          )
                        : null,
                    color: isPatient ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isPatient ? 20 : 4),
                      bottomRight: Radius.circular(isPatient ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isPatient
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isPatient ? Colors.white : Colors.black87,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: isPatient
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(messageTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    if (isPatient) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 13,
                        color: isRead
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input message ──
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.attach_file_rounded,
                  color: Colors.grey.shade500, size: 20),
              onPressed: _showAttachmentMenu,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Tapez votre message...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14.5),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (value) {
                  if (!HardwareKeyboard.instance.isShiftPressed) {
                    _sendMessage();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                    padding: const EdgeInsets.all(12),
                  ),
          ),
        ],
      ),
    );
  }

  // ── FAB nouvelle conversation (mobile) ──
  Widget _buildNewConversationFAB() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startNewConversation,
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text('Nouvelle conversation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ── Sheet nouvelle conversation ──
  Widget _buildNewConversationSheet(List<Doctor> doctors) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.add_comment_outlined,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nouvelle conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: doctors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'Aucun médecin disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        leading: _buildDoctorAvatar(doctor, radius: 26),
                        title: Text(
                          'Dr. ${doctor.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          doctor.specialization,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.85)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () =>
                                _createNewConversation(doctor.id),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Message',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: Colors.green, size: 22),
                ),
                title: const Text('Image'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.red, size: 22),
                ),
                title: const Text('Document PDF'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ──

  Widget _buildDoctorAvatar(Doctor doctor, {double radius = 24}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      backgroundImage:
          doctor.imageUrl.isNotEmpty ? NetworkImage(doctor.imageUrl) : null,
      child: doctor.imageUrl.isEmpty
          ? Text(
              doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            )
          : null,
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inHours < 1) return '${difference.inMinutes} min';
    if (difference.inDays < 1) return DateFormat('HH:mm').format(time);
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return DateFormat('EEE', 'fr_FR').format(time);
    return DateFormat('dd/MM').format(time);
  }
}