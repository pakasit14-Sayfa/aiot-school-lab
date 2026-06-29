import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

UserModel? currentUserModel;

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final model = UserModel.fromMap(uid, doc.data()!);
    currentUserModel = model;
    return model;
  }

  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return null;
    return getUserModel(cred.user!.uid);
  }

  static Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  static Future<void> signOut() async {
    currentUserModel = null;
    await _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<void> updateProfile({
    required String uid,
    required String name,
  }) async {
    await _db.collection('users').doc(uid).update({'name': name});
    if (currentUserModel?.uid == uid) {
      currentUserModel = currentUserModel!.copyWith(name: name);
    }
  }

  static Future<void> updateRole({
    required String uid,
    required UserRole role,
  }) async {
    await _db.collection('users').doc(uid).update({'role': role.value});
  }

  static Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}
