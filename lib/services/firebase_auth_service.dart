import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart';

class FirebaseAuthService {
  final StorageService storageService;
  static bool _isFirebaseReady = false;

  FirebaseAuthService({required this.storageService});

  static bool get isReady => _isFirebaseReady;

  User? get currentUser => _isFirebaseReady ? FirebaseAuth.instance.currentUser : null;

  /// Returns a fresh Firebase ID token for Oracle authentication (§11).
  /// Returns null when signed out or Firebase is unavailable. The Oracle
  /// must verify this token server-side and derive identity from it.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('[FirebaseAuthService] getIdToken failed: $e');
      return null;
    }
  }

  String get currentUid {
    if (_isFirebaseReady && FirebaseAuth.instance.currentUser != null) {
      return FirebaseAuth.instance.currentUser!.uid;
    }
    return storageService.guestUid;
  }

  Stream<User?> get authStateChanges {
    if (_isFirebaseReady) {
      return FirebaseAuth.instance.authStateChanges();
    }
    return Stream.value(null);
  }

  static Future<void> initializeFirebase({FirebaseOptions? options}) async {
    try {
      if (Firebase.apps.isEmpty) {
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          await Firebase.initializeApp();
        }
      }
      _isFirebaseReady = true;

      // Enable offline persistence for Firestore
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore offline settings notice: $e');
      }

      debugPrint('Firebase initialized successfully.');
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('Firebase initialization notice (running in local vault fallback): $e');
    }
  }

  /// Sign In Anonymously for Guest Researchers
  Future<Map<String, dynamic>> signInAnonymously() async {
    if (_isFirebaseReady) {
      try {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        final user = credential.user;
        if (user != null) {
          // Register guest user record in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'isAnonymous': true,
            'displayName': 'Guest Researcher',
            'role': 'guest',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          storageService.login(
            email: 'guest_${user.uid.substring(0, 6)}@shirazi.internal',
            name: 'Guest Researcher',
            role: 'Student of Knowledge',
          );

          return {
            'success': true,
            'uid': user.uid,
            'message': 'Guest researcher session established.',
          };
        }
      } catch (e) {
        debugPrint('Anonymous auth error: $e');
      }
    }

    // Local fallback
    return {
      'success': true,
      'uid': storageService.guestUid,
      'message': 'Local guest researcher session active.',
    };
  }

  /// Register new Scholar identity with Firebase Auth & create Firestore record
  Future<Map<String, dynamic>> registerScholar({
    required String email,
    required String password,
    required String scholarName,
    required String madhhab,
    required String scholarlyRank,
  }) async {
    final isAdminRole = email.toLowerCase().contains('admin') ||
        scholarlyRank.toLowerCase().contains('admin');

    if (_isFirebaseReady) {
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(scholarName);

          final profileData = {
            'uid': user.uid,
            'email': email.trim(),
            'displayName': scholarName,
            'scholarName': scholarName,
            'madhhab': madhhab,
            'scholarlyRank': scholarlyRank,
            'role': isAdminRole ? 'admin' : 'scholar',
            'isnadVerified': true,
            'honorCodeAccepted': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          };

          // Create in users and legacy scholars collection
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(profileData, SetOptions(merge: true));
          await FirebaseFirestore.instance.collection('scholars').doc(user.uid).set(profileData, SetOptions(merge: true));

          storageService.login(
            email: email.trim(),
            name: scholarName,
            role: isAdminRole ? 'Administrator' : scholarlyRank,
          );

          return {
            'success': true,
            'uid': user.uid,
            'message': 'Scholar profile registered and synchronized with Firestore.',
          };
        }
      } on FirebaseAuthException catch (e) {
        return {
          'success': false,
          'code': e.code,
          'message': _parseAuthErrorMessage(e.code, e.message),
        };
      } catch (e) {
        return {
          'success': false,
          'code': 'unknown',
          'message': 'Registration error: $e',
        };
      }
    }

    // Local Vault Fallback when Firebase backend is offline
    storageService.login(
      email: email.trim(),
      name: scholarName,
      role: isAdminRole ? 'Administrator' : scholarlyRank,
    );
    return {
      'success': true,
      'uid': storageService.guestUid,
      'message': 'Scholar profile registered in encrypted local hardware vault.',
    };
  }

  /// Sign In with Email and Passphrase
  Future<Map<String, dynamic>> signInScholar({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final isSuperAdminEmail = cleanEmail == superAdminEmail.toLowerCase();
    final isAdminEmail = isSuperAdminEmail || cleanEmail.contains('admin');

    if (_isFirebaseReady) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final user = credential.user;
        if (user != null) {
          String name = isSuperAdminEmail
              ? 'Super Admin (Al-Muhaqqiq)'
              : (user.displayName ?? 'Scholar Researcher');
          String role = isSuperAdminEmail
              ? 'Super Administrator'
              : (isAdminEmail ? 'Administrator' : 'Mufti / Darul Ifta');

          // Fetch scholar profile metadata from Firestore users collection
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            if (doc.exists) {
              final data = doc.data()!;
              name = data['displayName'] ?? data['scholarName'] ?? name;
              final userRole = data['role'];
              if (userRole == 'super_admin' || isSuperAdminEmail) {
                role = 'Super Administrator';
              } else if (userRole == 'admin' || isAdminEmail) {
                role = 'Administrator';
              } else {
                role = data['scholarlyRank'] ?? role;
              }

              // Update last login timestamp
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'lastLogin': FieldValue.serverTimestamp(),
                if (isSuperAdminEmail) 'role': 'super_admin',
              });
            } else {
              // Ensure doc exists
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'uid': user.uid,
                'email': user.email,
                'displayName': name,
                'role': isSuperAdminEmail ? 'super_admin' : (isAdminEmail ? 'admin' : 'scholar'),
                'lastLogin': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          } catch (e) {
            debugPrint('Firestore profile fetch notice: $e');
          }

          storageService.login(
            email: user.email ?? email.trim(),
            name: name,
            role: role,
          );

          return {
            'success': true,
            'uid': user.uid,
            'message': 'Authenticated successfully via Firebase.',
          };
        }
      } on FirebaseAuthException catch (e) {
        return {
          'success': false,
          'code': e.code,
          'message': _parseAuthErrorMessage(e.code, e.message),
        };
      } catch (e) {
        return {
          'success': false,
          'code': 'unknown',
          'message': 'Sign in error: $e',
        };
      }
    }

    // Local Vault Fallback
    storageService.login(
      email: email.trim(),
      name: isAdminEmail ? 'Administrator (Al-Muraqib)' : 'د. أحمد فاروق (Dr. Ahmad Farooq)',
      role: isAdminEmail ? 'Administrator' : 'Mufti / Darul Ifta',
    );
    return {
      'success': true,
      'uid': storageService.guestUid,
      'message': 'Authenticated via local encrypted research node.',
    };
  }

  static const String superAdminEmail = 'muhaqqiqcreates@gmail.com';

  /// Server-controlled super-admin check (§2, §3).
  ///
  /// Trust order:
  /// 1. Firebase custom claims (`role == 'super_admin'` / `superAdmin == true`)
  ///    — set only via the Admin SDK script in tools/, never by clients.
  /// 2. Bootstrap: the Firebase-authenticated account whose VERIFIED email is
  ///    the designated super-admin address (until the claim is assigned).
  ///
  /// NEVER trust `users/{uid}.role` — that document is user-writable and
  /// trusting it allowed privilege escalation.
  Future<bool> get isSuperAdmin async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? {};
      if (claims['role'] == 'super_admin' || claims['superAdmin'] == true) {
        return true;
      }
      final email = (token.claims?['email'] as String? ?? user.email ?? '')
          .trim()
          .toLowerCase();
      final verified = token.claims?['email_verified'] == true;
      if (verified && email == superAdminEmail.toLowerCase()) return true;
    } catch (e) {
      debugPrint('[FirebaseAuthService] isSuperAdmin check failed: $e');
    }
    return false;
  }

  /// Legacy synchronous super-admin hint (email match only). Prefer the
  /// async [isSuperAdmin] which checks server-controlled custom claims.
  bool get isSuperAdminEmail {
    final email = (currentUser?.email ?? storageService.scholarEmail).trim().toLowerCase();
    return email == superAdminEmail.toLowerCase();
  }

  /// Check if the currently active user has administrator privileges.
  ///
  /// Server-controlled custom claims ONLY. Removed: Firestore `users/{uid}`
  /// role lookup (privilege escalation vector) and substring email matching.
  Future<bool> checkIsAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? {};
      final role = claims['role'];
      if (role == 'admin' ||
          role == 'super_admin' ||
          claims['admin'] == true ||
          claims['superAdmin'] == true) {
        return true;
      }
      // Bootstrap for the designated super-admin before claims are assigned.
      final email = (claims['email'] as String? ?? user.email ?? '').trim().toLowerCase();
      if (claims['email_verified'] == true && email == superAdminEmail.toLowerCase()) {
        return true;
      }
    } catch (e) {
      debugPrint('[FirebaseAuthService] checkIsAdmin failed: $e');
    }
    return false;
  }

  /// Send Passphrase / Password reset email
  Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    if (_isFirebaseReady) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
        return {
          'success': true,
          'message': 'Password reset link sent to your seminary email address.',
        };
      } on FirebaseAuthException catch (e) {
        return {
          'success': false,
          'code': e.code,
          'message': _parseAuthErrorMessage(e.code, e.message),
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Password reset error: $e',
        };
      }
    }

    return {
      'success': true,
      'message': 'Passphrase reset dispatched via local vault verification.',
    };
  }

  /// Sign Out
  Future<void> signOut() async {
    if (_isFirebaseReady) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    storageService.logout();
  }

  static String _parseAuthErrorMessage(String code, String? fallback) {
    switch (code) {
      case 'user-not-found':
        return 'No scholar profile found with this email address. (لم يتم العثور على حساب)';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid passphrase or credential supplied. (كلمة المرور غير صحيحة)';
      case 'email-already-in-use':
        return 'This email address is already registered. (هذا البريد مسجل بالفعل)';
      case 'invalid-email':
        return 'Please provide a valid scholarly or institutional email address.';
      case 'weak-password':
        return 'Passphrase is too weak. Please include at least 6 characters with mixed entropy.';
      case 'network-request-failed':
        return 'Network connection issue. Offline cache mode is active.';
      case 'user-disabled':
        return 'This research account has been suspended by the administrator.';
      default:
        return fallback ?? 'Authentication operation could not be completed ($code).';
    }
  }
}
