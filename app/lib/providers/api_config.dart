import 'package:flutter/foundation.dart';

// FOR PHYSICAL DEVICES & EMULATORS:
// Set this to your development machine's local IP address (e.g. 192.168.X.X).
// Make sure both your development machine and your physical device are connected to the exact same Wi-Fi network.
const String _localHostIp = '192.168.0.107'; 

final String baseUrl = () {
  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  
  // Using the development machine's local IP address works for both physical devices (on the same Wi-Fi)
  // and emulators/simulators.
  // Note: If you are using an Android Emulator and experience connection issues,
  // you can fall back to 'http://10.0.2.2:3000'.
  return 'http://$_localHostIp:3000';
}();

