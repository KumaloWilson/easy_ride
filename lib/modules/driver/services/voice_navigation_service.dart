import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

enum NavigationVoiceType {
  turnByTurn,
  arrivalAtPickup,
  arrivalAtDestination,
  trafficAlert,
  rideStart,
  rideEnd,
}

class VoiceNavigationService extends GetxService {
  final FlutterTts _flutterTts = FlutterTts();
  final RxBool isEnabled = true.obs;
  final RxBool isSpeaking = false.obs;
  final RxDouble volume = 1.0.obs;
  final RxDouble pitch = 1.0.obs;
  final RxDouble rate = 0.5.obs;

  Future<VoiceNavigationService> init() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(rate.value);
    await _flutterTts.setVolume(volume.value);
    await _flutterTts.setPitch(pitch.value);
    
    _flutterTts.setStartHandler(() {
      isSpeaking.value = true;
    });
    
    _flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
    });
    
    _flutterTts.setErrorHandler((error) {
      isSpeaking.value = false;
      print('TTS Error: $error');
    });
    
    return this;
  }

  Future<void> speak(String text) async {
    if (!isEnabled.value) return;
    
    if (isSpeaking.value) {
      await _flutterTts.stop();
    }
    
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    isSpeaking.value = false;
  }

  Future<void> setVolume(double value) async {
    volume.value = value;
    await _flutterTts.setVolume(value);
  }

  Future<void> setPitch(double value) async {
    pitch.value = value;
    await _flutterTts.setPitch(value);
  }

  Future<void> setRate(double value) async {
    rate.value = value;
    await _flutterTts.setSpeechRate(value);
  }

  Future<void> toggleEnabled() async {
    isEnabled.value = !isEnabled.value;
    if (!isEnabled.value && isSpeaking.value) {
      await stop();
    }
  }

  Future<void> speakNavigationInstruction(NavigationVoiceType type, {Map<String, dynamic>? data}) async {
    if (!isEnabled.value) return;
    
    String text = '';
    
    switch (type) {
      case NavigationVoiceType.turnByTurn:
        final String maneuver = data?['maneuver'] ?? '';
        final String distance = data?['distance'] ?? '';
        final String street = data?['street'] ?? '';
        
        if (maneuver.toLowerCase().contains('turn right')) {
          text = 'In $distance, turn right onto $street';
        } else if (maneuver.toLowerCase().contains('turn left')) {
          text = 'In $distance, turn left onto $street';
        } else if (maneuver.toLowerCase().contains('straight')) {
          text = 'Continue straight for $distance on $street';
        } else if (maneuver.toLowerCase().contains('destination')) {
          text = 'You have arrived at your destination';
        } else {
          text = '$maneuver in $distance';
        }
        break;
        
      case NavigationVoiceType.arrivalAtPickup:
        text = 'You have arrived at the pickup location. Your rider is waiting.';
        break;
        
      case NavigationVoiceType.arrivalAtDestination:
        text = 'You have arrived at the destination. The ride is complete.';
        break;
        
      case NavigationVoiceType.trafficAlert:
        final String condition = data?['condition'] ?? '';
        text = 'Traffic alert: $condition ahead';
        break;
        
      case NavigationVoiceType.rideStart:
        final String destination = data?['destination'] ?? 'your destination';
        text = 'Starting ride to $destination';
        break;
        
      case NavigationVoiceType.rideEnd:
        text = 'Ride completed. Thank you for using Easy Ride.';
        break;
    }
    
    await speak(text);
  }

  @override
  void onClose() {
    _flutterTts.stop();
    super.onClose();
  }
}
