import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/user_model.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  bool get isLoggedIn => _auth.currentUser != null;
  bool get isDriver => currentUser.value?.userType == 'driver';

  Rx<User?> firebaseUser = Rx<User?>(null);


  Future<AuthService> init() async {
    print('Initializing AuthService');
    firebaseUser.value = _auth.currentUser;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      firebaseUser.value = user;
      if (user != null) {
        print('User is signed in: ${user.uid}');
        // Load user data from Firestore
        await _loadUserData(user.uid);
      } else {
        print('User is signed out');
        currentUser.value = null;
      }
    });

    // Check if user is already signed in
    if (_auth.currentUser != null) {
      await _loadUserData(_auth.currentUser!.uid);
    }

    return this;
  }

  Future<void> _loadUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentUser.value = UserModel.fromMap(userData, userId);
        print('User data loaded: ${currentUser.value?.toMap()}');
      } else {
        print('User document does not exist for ID: $userId');
        currentUser.value = null;
      }
    } catch (e) {
      print('Error loading user data: $e');
      currentUser.value = null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserData(userCredential.user!.uid);
      return userCredential;
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } catch (e) {
      print('Error signing up with email and password: $e');
      rethrow;
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with credential: $e');
      rethrow;
    }
  }

  Future<void> createUserInFirestore(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      currentUser.value = user;
    } catch (e) {
      print('Error creating user in Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(data);
        await _loadUserData(_auth.currentUser!.uid);
      }
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
