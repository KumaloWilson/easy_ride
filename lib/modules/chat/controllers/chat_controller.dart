import 'package:get/get.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:easy_ride/core/services/firebase_service.dart';
import 'package:easy_ride/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirebaseService firebaseService = Get.find<FirebaseService>();
  
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  late String rideId;
  late String receiverId;
  late String senderId;
  
  @override
  void onInit() {
    super.onInit();
    
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    rideId = args['rideId'] as String;
    receiverId = args['receiverId'] as String;
    senderId = _authService.firebaseUser.value!.uid;
    
    _listenToMessages();
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
}
