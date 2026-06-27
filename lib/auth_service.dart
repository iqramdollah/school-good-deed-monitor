import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sriwaap/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signIn(String email, String password) async {
    print('DEBUG: attempting sign in for $email');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('DEBUG: sign in successful, uid: ${credential.user?.uid}');
    final uid = credential.user?.uid;
    if (uid == null) return null;
    final user = await getUser(uid);
    print('DEBUG: got user: $user');
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getUser(String uid) async {
    print('DEBUG: fetching user doc for uid: $uid');
    final doc = await _db.collection('users').doc(uid).get();
    print('DEBUG: doc exists: ${doc.exists}, data: ${doc.data()}');
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data()!, uid);
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }
}
