import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inquiry.dart';
import '../models/chat_models.dart';
import 'firebase_auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory fallback for offline/guest nodes
  static final List<ShiraziConversation> _localConversations = [];
  static final Map<String, List<ShiraziChatMessage>> _localMessages = {};

  // -------------------------------------------------------------
  // USER ISOLATED CONVERSATIONS & CHAT
  // -------------------------------------------------------------

  /// Returns true only if Firebase is initialized AND an authenticated user session exists.
  static bool get _hasAuth =>
      FirebaseAuthService.isReady && FirebaseAuth.instance.currentUser != null;

  /// Stream conversations strictly isolated to the authenticated user.
  /// No other user's conversations will ever be returned or queried.
  static Stream<List<ShiraziConversation>> streamUserConversations(String uid) {
    if (!_hasAuth || uid.isEmpty) {
      final userFiltered = _localConversations.where((c) => c.ownerUid == uid).toList();
      userFiltered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Stream.value(userFiltered);
    }

    try {
      return _db
          .collection('conversations')
          .where('ownerUid', isEqualTo: uid)
          .snapshots(includeMetadataChanges: false)
          .map((snapshot) {
        final convs = snapshot.docs.map((doc) => ShiraziConversation.fromFirestore(doc)).toList();
        // Client-side sort fallback to prevent missing Firestore composite index crashes
        convs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return convs;
      }).handleError((e) {
        debugPrint('Firestore streamUserConversations error: $e');
        final userFiltered = _localConversations.where((c) => c.ownerUid == uid).toList();
        return userFiltered;
      });
    } catch (e) {
      debugPrint('Firestore query initialization failed: $e');
      return Stream.value([]);
    }
  }

  /// Stream messages for a specific conversation in chronological order
  static Stream<List<ShiraziChatMessage>> streamConversationMessages(String conversationId) {
    if (!_hasAuth || conversationId.isEmpty) {
      final msgs = _localMessages[conversationId] ?? [];
      return Stream.value(List<ShiraziChatMessage>.from(msgs));
    }

    try {
      return _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(includeMetadataChanges: false)
          .map((snapshot) {
        return snapshot.docs.map((doc) => ShiraziChatMessage.fromFirestore(doc)).toList();
      }).handleError((e) {
        debugPrint('Firestore streamConversationMessages error: $e');
        return _localMessages[conversationId] ?? <ShiraziChatMessage>[];
      });
    } catch (e) {
      debugPrint('Firestore messages stream error: $e');
      return Stream.value([]);
    }
  }

  /// Create a new conversation document bound strictly to the owner UID
  static Future<ShiraziConversation> createConversation({
    required String ownerUid,
    required String initialTitle,
    String language = 'en',
    String madhhab = 'Hanafi',
    String persona = 'muhaqqiq',
    String? ownerEmail,
    String? ownerName,
  }) async {
    final now = DateTime.now();
    final convId = 'conv_${now.millisecondsSinceEpoch}_${ownerUid.hashCode.abs() % 10000}';

    final conversation = ShiraziConversation(
      id: convId,
      ownerUid: ownerUid,
      title: initialTitle.trim().isEmpty ? 'New Research Inquiry' : initialTitle.trim(),
      createdAt: now,
      updatedAt: now,
      language: language,
      madhhab: madhhab,
      persona: persona,
      lastMessagePreview: '',
      messageCount: 0,
      ownerEmail: ownerEmail,
      ownerName: ownerName,
    );

    // Save locally first
    _localConversations.removeWhere((c) => c.id == convId);
    _localConversations.insert(0, conversation);

    if (_hasAuth) {
      try {
        await _db.collection('conversations').doc(convId).set(
          conversation.toFirestore(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Error syncing new conversation to cloud: $e');
      }
    }

    return conversation;
  }

  /// Add a message to a conversation and update conversation metadata
  static Future<bool> addMessage({
    required String conversationId,
    required ShiraziChatMessage message,
  }) async {
    // Cache locally
    _localMessages.putIfAbsent(conversationId, () => []);
    _localMessages[conversationId]!.add(message);

    // Update local conversation preview
    final idx = _localConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final existing = _localConversations[idx];
      _localConversations[idx] = existing.copyWith(
        lastMessagePreview: message.content.length > 80
            ? '${message.content.substring(0, 80)}...'
            : message.content,
        updatedAt: message.timestamp,
        messageCount: existing.messageCount + 1,
      );
    }

    if (!_hasAuth) return true;

    try {
      final batch = _db.batch();
      final msgRef = _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(message.id);
      batch.set(msgRef, message.toFirestore());

      final convRef = _db.collection('conversations').doc(conversationId);
      final preview = message.content.length > 80
          ? '${message.content.substring(0, 80)}...'
          : message.content;

      batch.update(convRef, {
        'lastMessagePreview': preview,
        'updatedAt': Timestamp.fromDate(message.timestamp),
        'messageCount': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Firestore addMessage error: $e');
      return false;
    }
  }

  /// Delete a single message from a conversation
  static Future<bool> deleteMessage(String conversationId, String messageId) async {
    if (_localMessages.containsKey(conversationId)) {
      _localMessages[conversationId]!.removeWhere((m) => m.id == messageId);
    }
    if (!_hasAuth) return true;
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteMessage error: $e');
      return false;
    }
  }

  /// Delete a conversation and its messages
  static Future<bool> deleteConversation(String conversationId) async {
    _localConversations.removeWhere((c) => c.id == conversationId);
    _localMessages.remove(conversationId);

    if (!_hasAuth) return true;

    try {
      // Delete subcollection messages
      final msgsSnap = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _db.batch();
      for (var doc in msgsSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection('conversations').doc(conversationId));
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteConversation error: $e');
      return false;
    }
  }

  /// Rename a conversation
  static Future<bool> renameConversation(String conversationId, String newTitle) async {
    final idx = _localConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _localConversations[idx] = _localConversations[idx].copyWith(title: newTitle);
    }

    if (!_hasAuth) return true;

    try {
      await _db.collection('conversations').doc(conversationId).update({
        'title': newTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Firestore renameConversation error: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // ADMIN RESEARCH DASHBOARD (CENTRALIZED OVERSIGHT)
  // -------------------------------------------------------------

  /// Stream all conversations across all users — strictly for authorized administrators.
  static Stream<List<ShiraziConversation>> streamAllConversationsAdmin() {
    if (!_hasAuth) {
      final copy = List<ShiraziConversation>.from(_localConversations);
      copy.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Stream.value(copy);
    }

    try {
      return _db
          .collection('conversations')
          .snapshots(includeMetadataChanges: false)
          .map((snapshot) {
        final convs = snapshot.docs.map((doc) => ShiraziConversation.fromFirestore(doc)).toList();
        convs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return convs;
      }).handleError((e) {
        debugPrint('Admin streamAllConversations error: $e');
        return _localConversations;
      });
    } catch (e) {
      debugPrint('Admin conversations stream failed: $e');
      return Stream.value([]);
    }
  }

  /// Stream all registered researcher profiles for admin analysis
  static Stream<List<Map<String, dynamic>>> streamUsersAdmin() {
    if (!_hasAuth) {
      return Stream.value([]);
    }

    try {
      return _db
          .collection('users')
          .snapshots(includeMetadataChanges: false)
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      }).handleError((e) {
        debugPrint('Admin streamUsers error: $e');
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // -------------------------------------------------------------
  // LEGACY BACKWARD COMPATIBILITY
  // -------------------------------------------------------------

  /// Sync inquiry to Firestore under the scholar's profile
  static Future<bool> saveInquiryToCloud(Inquiry inquiry) async {
    if (!FirebaseAuthService.isReady) return false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final docRef = _db
          .collection('scholars')
          .doc(user.uid)
          .collection('inquiries')
          .doc(inquiry.id);

      final data = inquiry.toJson();
      data['serverTimestamp'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Firestore save error: $e');
      return false;
    }
  }

  /// Stream inquiries with Spark quota optimization (limit to latest 20)
  static Stream<List<Inquiry>> getInquiriesStream({int limit = 20}) {
    if (!FirebaseAuthService.isReady) {
      return Stream.value([]);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('scholars')
        .doc(user.uid)
        .collection('inquiries')
        .orderBy('serverTimestamp', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Inquiry.fromJson(doc.data());
      }).toList();
    });
  }

  /// Delete inquiry from cloud
  static Future<bool> deleteInquiry(String inquiryId) async {
    if (!FirebaseAuthService.isReady) return false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _db
          .collection('scholars')
          .doc(user.uid)
          .collection('inquiries')
          .doc(inquiryId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Firestore delete error: $e');
      return false;
    }
  }
}
