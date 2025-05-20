import 'package:easy_ride/core/values/constants.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/models/user_model.dart';
import 'package:easy_ride/routes/app_pages.dart';
import 'package:easy_ride/core/utils/logs.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isDriver => currentUser.value?.userType == 'driver';
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  
  Future<AuthService> init() async {
    DevLogs.info('Initializing AuthService');
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      firebaseUser.value = user;
      
      if (user != null) {
        DevLogs.info('User is signed in: ${user.uid}');
        // Load user data from Firestore
        await _loadUserData(user.uid);
      } else {
        DevLogs.info('User is signed out');
        currentUser.value = null;
      }
    });
    
    // Check if user is already signed in
    if (_auth.currentUser != null) {
      firebaseUser.value = _auth.currentUser;
      await _loadUserData(_auth.currentUser!.uid);
    }
    
    return this;
  }
  
  Future<void> _loadUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection(Constants.usersCollection).doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentUser.value = UserModel.fromMap(userData, userId);
        
        // Update email verification status
        if (firebaseUser.value != null) {
          await _firestore.collection(Constants.usersCollection).doc(userId).update({
            'emailVerified': firebaseUser.value!.emailVerified,
          });
          
          currentUser.value = currentUser.value!.copyWith(
            emailVerified: firebaseUser.value!.emailVerified,
          );
        }
        
        DevLogs.debug('User data loaded: ${currentUser.value?.toMap()}');
      } else {
        DevLogs.warning('User document does not exist for ID: $userId');
        currentUser.value = null;
      }
    } catch (e) {
      DevLogs.error('Error loading user data', exception: e);
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
      DevLogs.error('Error signing in with email and password', exception: e);
      rethrow;
    }
  }
  
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await userCredential.user!.sendEmailVerification();
      
      return userCredential;
    } catch (e) {
      DevLogs.error('Error signing up with email and password', exception: e);
      rethrow;
    }
  }
  
  Future<void> sendEmailVerification() async {
    try {
      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        await _auth.currentUser!.sendEmailVerification();
      }
    } catch (e) {
      DevLogs.error('Error sending email verification', exception: e);
      rethrow;
    }
  }
  
  Future<void> checkEmailVerification() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.reload();
        
        if (_auth.currentUser!.emailVerified) {
          // Update user data in Firestore
          await _firestore.collection(Constants.usersCollection).doc(_auth.currentUser!.uid).update({
            'emailVerified': true,
          });
          
          // Update local user model
          if (currentUser.value != null) {
            currentUser.value = currentUser.value!.copyWith(
              emailVerified: true,
            );
          }
        }
      }
    } catch (e) {
      DevLogs.error('Error checking email verification', exception: e);
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
      DevLogs.error('Error signing in with credential', exception: e);
      rethrow;
    }
  }
  
  Future<void> createUserInFirestore(UserModel user) async {
    try {
      await _firestore.collection(Constants.usersCollection).doc(user.id).set(user.toMap());
      currentUser.value = user;
    } catch (e) {
      DevLogs.error('Error creating user in Firestore', exception: e);
      rethrow;
    }
  }
  
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore.collection(Constants.usersCollection).doc(_auth.currentUser!.uid).update(data);
        await _loadUserData(_auth.currentUser!.uid);
      }
    } catch (e) {
      DevLogs.error('Error updating user data', exception: e);
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
    } catch (e) {
      DevLogs.error('Error signing out', exception: e);
      rethrow;
    }
  }
}
