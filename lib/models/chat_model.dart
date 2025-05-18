import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String rideId;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String messageType;
  final DateTime? deliveredAt;
  
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.rideId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.messageType = 'text',
    this.deliveredAt,
  });
  
  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      rideId: data['rideId'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['timestamp'].toString()))
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      messageType: data['messageType'] ?? 'text',
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] is Timestamp
              ? (data['deliveredAt'] as Timestamp).toDate()
              : DateTime.parse(data['deliveredAt'].toString()))
          : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'rideId': rideId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'messageType': messageType,
      'deliveredAt': deliveredAt,
    };
  }
  
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? rideId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      rideId: rideId ?? this.rideId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      messageType: messageType ?? this.messageType,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
