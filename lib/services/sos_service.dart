import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class SOSService with ChangeNotifier {
  bool _isSendingAlert = false;
  String _lastAlertMessage = '';
  
  // Getters
  bool get isSendingAlert => _isSendingAlert;
  String get lastAlertMessage => _lastAlertMessage;
  
  // Send SOS alert
  Future<void> sendSOSAlert(List<String> trustedContacts) async {
    if (_isSendingAlert) return;
    
    _isSendingAlert = true;
    notifyListeners();
    
    try {
      // Get current location
      final Position position = await _getCurrentLocation();
      
      // Create alert message
      final String alertMessage = 
          'EMERGENCY ALERT!\n\n'
          'I need help immediately.\n'
          'Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n'
          'Time: ${DateTime.now().toString()}';
      
      // In a real app, you would send this message to trusted contacts
      // via SMS, email, or a messaging service
      
      // For demo purposes, we'll just show a message
      _lastAlertMessage = 'SOS alert sent to ${trustedContacts.length} contacts';
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      print('SOS Alert Sent: $alertMessage');
    } catch (e) {
      _lastAlertMessage = 'Failed to send SOS alert: $e';
      print('Error sending SOS alert: $e');
    } finally {
      _isSendingAlert = false;
      notifyListeners();
    }
  }
  
  // Get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception('Location permissions are permanently denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
  
  // Add trusted contact
  Future<void> addTrustedContact(String contact) async {
    // In a real app, you would save this to secure storage
    // For demo purposes, we'll just print it
    print('Added trusted contact: $contact');
  }
  
  // Remove trusted contact
  Future<void> removeTrustedContact(String contact) async {
    // In a real app, you would remove this from secure storage
    // For demo purposes, we'll just print it
    print('Removed trusted contact: $contact');
  }
}