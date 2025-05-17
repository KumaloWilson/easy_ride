import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_ride/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:flutter/material.dart';
import 'package:easy_ride/routes/app_pages.dart';

import 'location_service.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();

  // Notification channels
  static const String rideChannel = 'ride_notifications';
  static const String chatChannel = 'chat_notifications';
  static const String generalChannel = 'general_notifications';

  // Notification types
  static const String rideRequest = 'ride_request';
  static const String rideAccepted = 'ride_accepted';
  static const String rideArrived = 'ride_arrived';
  static const String rideStarted = 'ride_started';
  static const String rideCompleted = 'ride_completed';
  static const String rideCancelled = 'ride_cancelled';
  static const String newMessage = 'new_message';

  // Observable properties
  final RxBool hasPermission = false.obs;
  final RxString fcmToken = ''.obs;
  final RxInt unreadNotifications = 0.obs;

  Future<NotificationService> init() async {
    DevLogs.info('Initializing NotificationService');

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    hasPermission.value = settings.authorizationStatus == AuthorizationStatus.authorized;
    DevLogs.info('User notification permission status: ${settings.authorizationStatus}');

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle message open
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      fcmToken.value = token;
      DevLogs.debug('FCM Token: $token');
      await _saveTokenToDatabase(token);
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      fcmToken.value = newToken;
      _saveTokenToDatabase(newToken);
    });

    // Set up notification categories/topics
    await _setupNotificationTopics();

    // Load unread notification count
    await _loadUnreadNotificationCount();

    return this;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    DevLogs.info('Local notifications initialized');
  }

  Future<void> _createNotificationChannels() async {
    // Only needed for Android 8.0+
    if (GetPlatform.isAndroid) {
      // Ride notifications channel
      const AndroidNotificationChannel rideNotificationChannel = AndroidNotificationChannel(
        rideChannel,
        'Ride Notifications',
        description: 'Notifications about your rides',
        importance: Importance.high,
      );

      // Chat notifications channel
      const AndroidNotificationChannel chatNotificationChannel = AndroidNotificationChannel(
        chatChannel,
        'Chat Notifications',
        description: 'Notifications about new messages',
        importance: Importance.high,
      );

      // General notifications channel
      AndroidNotificationChannel generalNotificationChannel = AndroidNotificationChannel(
        generalChannel,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(rideNotificationChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(chatNotificationChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalNotificationChannel);

      DevLogs.info('Android notification channels created');
    }
  }

  Future<void> _setupNotificationTopics() async {
    if (_authService.isLoggedIn) {
      // Subscribe to user-specific topic
      await _messaging.subscribeToTopic('user_${_authService.firebaseUser.value!.uid}');

      // Subscribe based on user type
      if (_authService.isDriver) {
        await _messaging.subscribeToTopic('drivers');
        await _messaging.unsubscribeFromTopic('riders');
      } else {
        await _messaging.subscribeToTopic('riders');
        await _messaging.unsubscribeFromTopic('drivers');
      }

      DevLogs.info('Subscribed to notification topics');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    if (_authService.firebaseUser.value != null) {
      String userId = _authService.firebaseUser.value!.uid;

      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      DevLogs.info('FCM token saved to database');
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    if (_authService.firebaseUser.value != null) {
      String userId = _authService.firebaseUser.value!.uid;

      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      unreadNotifications.value = snapshot.docs.length;
      DevLogs.debug('Unread notifications: ${unreadNotifications.value}');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    DevLogs.info('Received foreground message: ${message.messageId}');
    DevLogs.debug('Message data: ${message.data}');

    // Save notification to Firestore
    await _saveNotificationToDatabase(message);

    // Update unread count
    unreadNotifications.value++;

    // Show local notification
    if (message.notification != null) {
      DevLogs.debug('Message contains notification: ${message.notification!.title}');

      // Determine notification channel
      String channelId = generalChannel;
      if (message.data['type']?.startsWith('ride_') ?? false) {
        channelId = rideChannel;
      } else if (message.data['type'] == newMessage) {
        channelId = chatChannel;
      }

      await _showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Easy Ride',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
        channelId: channelId,
      );
    }
  }

  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    if (_authService.firebaseUser.value != null) {
      String userId = _authService.firebaseUser.value!.uid;

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      DevLogs.debug('Notification saved to database');
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channelId,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == rideChannel ? 'Ride Notifications' :
      channelId == chatChannel ? 'Chat Notifications' : 'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    DevLogs.debug('Local notification displayed: $title');
  }

  void _onSelectNotification(NotificationResponse response) {
    DevLogs.info('Notification clicked: ${response.id}');

    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationAction(data);
      } catch (e) {
        DevLogs.error('Error parsing notification payload', exception: e);
      }
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    DevLogs.info('App opened from notification: ${message.messageId}');
    _handleNotificationAction(message.data);
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    // Mark notification as read
    _markNotificationAsRead(data['notificationId']);

    // Navigate based on notification type
    switch (data['type']) {
      case rideRequest:
        if (_authService.isDriver) {
          Get.toNamed(Routes.driverHome);
        }
        break;
      case rideAccepted:
      case rideArrived:
      case rideStarted:
        if (data['rideId'] != null) {
          if (_authService.isDriver) {
            Get.toNamed('${Routes.driverRideDetails}/${data['rideId']}');
          } else {
            Get.toNamed('${Routes.rideDetails}/${data['rideId']}');
          }
        }
        break;
      case rideCompleted:
      case rideCancelled:
        if (data['rideId'] != null) {
          if (_authService.isDriver) {
            Get.toNamed(Routes.driverHome);
          } else {
            Get.toNamed(Routes.riderHome);
          }
        }
        break;
      case newMessage:
        if (data['chatId'] != null) {
          Get.toNamed('${Routes.chat}/${data['chatId']}');
        }
        break;
      default:
      // Default action - open app
        if (_authService.isDriver) {
          Get.toNamed(Routes.driverHome);
        } else {
          Get.toNamed(Routes.riderHome);
        }
    }
  }

  Future<void> _markNotificationAsRead(String? notificationId) async {
    if (notificationId != null) {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Update unread count
      if (unreadNotifications.value > 0) {
        unreadNotifications.value--;
      }

      DevLogs.debug('Notification marked as read: $notificationId');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_authService.firebaseUser.value != null) {
      String userId = _authService.firebaseUser.value!.uid;

      // Get all unread notifications
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      // Update each notification
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Reset unread count
      unreadNotifications.value = 0;

      DevLogs.info('All notifications marked as read');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications({int limit = 20}) async {
    if (_authService.firebaseUser.value != null) {
      String userId = _authService.firebaseUser.value!.uid;

      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }

    return [];
  }

  Future<void> sendNotificationToUser(String userId, String title, String body, Map<String, dynamic> data) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> fcmTokens = userData['fcmTokens'] ?? [];

        for (String token in fcmTokens.cast<String>()) {
          await sendPushNotification(token, title, body, data);
        }

        // Also save to notifications collection
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'data': data,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        DevLogs.info('Notification sent to user: $userId');
      }
    } catch (e) {
      DevLogs.error('Error sending notification to user', exception: e);
    }
  }

  Future<void> sendPushNotification(String token, String title, String body, Map<String, dynamic> data) async {
    try {
      // FCM API endpoint
      const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

      // FCM server key from Firebase console
      final String serverKey = Constants.fcmServerKey;

      // Construct the message payload
      final Map<String, dynamic> message = {
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
        'to': token,
        'priority': 'high',
      };

      // Send the HTTP request
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        DevLogs.debug('FCM notification sent successfully');
      } else {
        DevLogs.error('Failed to send FCM notification. Status code: ${response.statusCode}');
        DevLogs.error('Response body: ${response.body}');
      }
    } catch (e) {
      DevLogs.error('Error sending FCM notification', exception: e);
    }
  }

  Future<void> sendRideRequestNotification(String rideId, Map<String, dynamic> rideData) async {
    // Find nearby drivers
    List<String> nearbyDriverIds = await _findNearbyDriverIds(
      rideData['pickup']['latitude'],
      rideData['pickup']['longitude'],
    );

    if (nearbyDriverIds.isEmpty) {
      DevLogs.warning('No nearby drivers found for ride request');
      return;
    }

    // Send notification to each driver
    for (String driverId in nearbyDriverIds) {
      await sendNotificationToUser(
        driverId,
        'New Ride Request',
        'A new ride request is available nearby',
        {
          'type': rideRequest,
          'rideId': rideId,
          'pickup': rideData['pickup']['name'],
          'dropoff': rideData['dropoff']['name'],
          'fare': rideData['fare'],
        },
      );
    }

    DevLogs.info('Ride request notifications sent to ${nearbyDriverIds.length} drivers');
  }

  Future<List<String>> _findNearbyDriverIds(double lat, double lng) async {
    // Find drivers within 5km radius
    const double radiusInKm = 5.0;

    // Convert radius to degrees (approximate)
    double radiusInDegrees = radiusInKm / 111.32;

    // Calculate bounds
    double minLat = lat - radiusInDegrees;
    double maxLat = lat + radiusInDegrees;
    double minLng = lng - radiusInDegrees;
    double maxLng = lng + radiusInDegrees;

    // Query for online drivers
    QuerySnapshot snapshot = await _firestore.collection('driver_locations')
        .where('isOnline', isEqualTo: true)
        .get();

    List<String> driverIds = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      GeoPoint location = data['location'] as GeoPoint;

      // Check if driver is within bounds
      if (location.latitude >= minLat &&
          location.latitude <= maxLat &&
          location.longitude >= minLng &&
          location.longitude <= maxLng) {

        // Calculate actual distance using Haversine formula
        LocationService locationService = Get.find<LocationService>();
        double distance = locationService.calculateDistance(
          lat,
          lng,
          location.latitude,
          location.longitude,
        );

        if (distance <= radiusInKm) {
          driverIds.add(data['driverId']);
        }
      }
    }

    return driverIds;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will handle background messages
  // Note: This function runs in a separate isolate

  // We can't use GetX services here, so we need to manually initialize Firebase
  // await Firebase.initializeApp();

  // Save notification to local storage for later processing when app is opened
  // This would require a separate implementation using shared_preferences or hive

  print('Handling a background message: ${message.messageId}');
}
