// lib/services/messaging_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Créer ou récupérer une conversation
  Future<String> getOrCreateConversation({
    required String doctorId,
    required String patientId,
    required String patientName,
    required String doctorName,
  }) async {
    try {
      if (doctorId.isEmpty || patientId.isEmpty) {
        throw Exception('Doctor ID and Patient ID cannot be empty');
      }

      // Chercher une conversation existante
      final existingConversation = await _db
          .collection('conversations')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Créer une nouvelle conversation
      final conversationId = _db.collection('conversations').doc().id;
      final timestamp = FieldValue.serverTimestamp();

      await _db.collection('conversations').doc(conversationId).set({
        'id': conversationId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'patientId': patientId,
        'patientName': patientName,
        'lastMessage': '',
        'lastMessageTime': timestamp,
        'lastMessageSender': '',
        'lastMessageSenderName': '',
        'unreadCount': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      print('✅ Conversation créée: $conversationId');
      return conversationId;
    } catch (e) {
      print('❌ Erreur création conversation: $e');
      rethrow;
    }
  }

  // Envoyer un message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String text,
    String type = 'text',
    Map<String, dynamic>? attachment,
  }) async {
    try {
      if (conversationId.isEmpty) {
        throw Exception('Conversation ID cannot be empty');
      }

      final messageId = _db.collection('messages').doc().id;
      final timestamp = FieldValue.serverTimestamp();

      // Ajouter le message
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType,
        'text': text,
        'type': type,
        'attachment': attachment,
        'timestamp': timestamp,
        'read': false,
      });

      // Mettre à jour la conversation
      await _db.collection('conversations').doc(conversationId).update({
        'lastMessage': text,
        'lastMessageTime': timestamp,
        'lastMessageSender': senderId,
        'lastMessageSenderName': senderName,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': timestamp,
      });

      print('✅ Message envoyé dans conversation: $conversationId');
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      rethrow;
    }
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final messagesSnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      if (messagesSnapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();

      await _db.collection('conversations').doc(conversationId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Erreur marquage messages comme lus: $e');
    }
  }

  // Récupérer les conversations d'un médecin
  Stream<List<Map<String, dynamic>>> getDoctorConversations(String doctorId) {
    return _db
        .collection('conversations')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'];
        
        if (patientId != null && patientId.toString().isNotEmpty) {
          try {
            final patientDoc = await _db.collection('patients').doc(patientId).get();
            if (patientDoc.exists) {
              conversations.add({
                ...data,
                'patient': patientDoc.data(),
              });
            }
          } catch (e) {
            print('Erreur chargement patient $patientId: $e');
          }
        }
      }

      return conversations;
    });
  }

  // Récupérer les messages d'une conversation
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'timestamp': (doc.data()['timestamp'] as Timestamp).toDate(),
                })
            .toList());
  }

  // Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      final messagesSnapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_db.collection('conversations').doc(conversationId));

      await batch.commit();
    } catch (e) {
      print('Erreur suppression conversation: $e');
      rethrow;
    }
  }
}