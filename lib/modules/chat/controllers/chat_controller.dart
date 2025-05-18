import 'package:get/get.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:easy_ride/core/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirebaseService firebaseService = Get.find<FirebaseService>();
  
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  late String rideId;
  late String receiverId;
  late String senderId;

  final RxBool isReceiverTyping = false.obs;
  final RxBool isUserOnline = false.obs;
  Timer? _typingTimer;
  StreamSubscription? _userStatusSubscription;
  
  @override
  void onInit() {
    super.onInit();
    
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    rideId = args['rideId'] as String;
    receiverId = args['receiverId'] as String;
    senderId = _authService.firebaseUser.value!.uid;
    
    _listenToMessages();
    _listenToUserStatus();
    _listenToTypingStatus();
  }
  
  @override
  void onClose() {
    _typingTimer?.cancel();
    _userStatusSubscription?.cancel();
    super.onClose();
  }
  
  void _listenToUserStatus() {
    _userStatusSubscription = firebaseService.firestore
        .collection('users')
        .doc(receiverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        isUserOnline.value = data['isOnline'] ?? false;
      }
    });
  }
  
  void _listenToTypingStatus() {
    firebaseService.firestore
        .collection('chats')
        .doc('typing')
        .collection('status')
        .doc(receiverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['receiverId'] == senderId) {
          isReceiverTyping.value = data['isTyping'] ?? false;
        }
      } else {
        isReceiverTyping.value = false;
      }
    });
  }
  
  void _listenToMessages() {
    firebaseService.collectionStream<ChatMessage>(
      path: 'chats',
      queryBuilder: (query) => query
          .where('rideId', isEqualTo: rideId)
          .orderBy('timestamp', descending: true),
      builder: (data, documentId) => ChatMessage.fromMap(data, documentId),
    ).listen((chatMessages) {
      messages.value = chatMessages;
    });
  }
  
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    isLoading.value = true;
    error.value = '';
    
    try {
      final String messageId = const Uuid().v4();
      
      final ChatMessage newMessage = ChatMessage(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        rideId: rideId,
        message: text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      await firebaseService.setData(
        path: 'chats/$messageId',
        data: newMessage.toMap(),
      );
    } catch (e) {
      print('Error sending message: $e');
      error.value = 'Failed to send message';
    } finally {
      isLoading.value = false;
    }
  }

  void updateTypingStatus(bool isTyping) {
    _typingTimer?.cancel();
    
    if (isTyping) {
      firebaseService.firestore
          .collection('chats')
          .doc('typing')
          .collection('status')
          .doc(senderId)
          .set({
        'senderId': senderId,
        'receiverId': receiverId,
        'isTyping': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      _typingTimer = Timer(const Duration(seconds: 5), () {
        firebaseService.firestore
            .collection('chats')
            .doc('typing')
            .collection('status')
            .doc(senderId)
            .update({
          'isTyping': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } else {
      firebaseService.firestore
          .collection('chats')
          .doc('typing')
          .collection('status')
          .doc(senderId)
          .update({
        'isTyping': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<void> pickImage(bool fromCamera) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        isLoading.value = true;
        
        // Upload image to storage
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child(rideId)
            .child(fileName);
        
        final UploadTask uploadTask = storageRef.putFile(File(image.path));
        final TaskSnapshot taskSnapshot = await uploadTask;
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        
        // Send message with image
        final String messageId = const Uuid().v4();
        
        final ChatMessage newMessage = ChatMessage(
          id: messageId,
          senderId: senderId,
          receiverId: receiverId,
          rideId: rideId,
          message: 'Image',
          timestamp: DateTime.now(),
          isRead: false,
          imageUrl: downloadUrl,
          messageType: 'image',
        );
        
        await firebaseService.setData(
          path: 'chats/$messageId',
          data: newMessage.toMap(),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      error.value = 'Failed to send image';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> shareLocation() async {
    try {
      isLoading.value = true;
      
      // Get current location
      final LocationService locationService = Get.find<LocationService>();
      final position = await locationService.currentLocation.value;
      
      if (position != null) {
        // Create location message
        final String messageId = const Uuid().v4();
        
        final ChatMessage newMessage = ChatMessage(
          id: messageId,
          senderId: senderId,
          receiverId: receiverId,
          rideId: rideId,
          message: 'Location',
          timestamp: DateTime.now(),
          isRead: false,
          latitude: position.latitude,
          longitude: position.longitude,
          messageType: 'location',
        );
        
        await firebaseService.setData(
          path: 'chats/$messageId',
          data: newMessage.toMap(),
        );
      }
    } catch (e) {
      print('Error sharing location: $e');
      error.value = 'Failed to share location';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> callUser() async {
    try {
      final userDoc = await firebaseService.firestore
          .collection('users')
          .doc(receiverId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final phoneNumber = userData['phoneNumber'];
        
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          final Uri url = Uri.parse('tel:$phoneNumber');
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            error.value = 'Could not launch phone app';
          }
        } else {
          error.value = 'Phone number not available';
        }
      }
    } catch (e) {
      print('Error calling user: $e');
      error.value = 'Failed to initiate call';
    }
  }
  
  Future<void> markMessagesAsRead() async {
    try {
      final unreadMessages = messages.where(
        (message) => message.receiverId == senderId && !message.isRead
      ).toList();
      
      for (var message in unreadMessages) {
        await firebaseService.updateData(
          path: 'chats/${message.id}',
          data: {'isRead': true},
        );
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
  
  Future<void> clearChat() async {
    try {
      isLoading.value = true;
      
      // Get all messages between these users for this ride
      final QuerySnapshot snapshot = await firebaseService.firestore
          .collection('chats')
          .where('rideId', isEqualTo: rideId)
          .where('senderId', whereIn: [senderId, receiverId])
          .where('receiverId', whereIn: [senderId, receiverId])
          .get();
      
      // Delete each message
      final batch = firebaseService.firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Clear local messages
      messages.clear();
      
      Get.snackbar(
        'Chat Cleared',
        'All messages have been deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error clearing chat: $e');
      error.value = 'Failed to clear chat';
    } finally {
      isLoading.value = false;
    }
  }
}
