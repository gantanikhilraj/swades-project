import 'package:flutter/foundation.dart';

// Live production backend hosted on Render:
const String _productionUrl = 'https://swades-project.onrender.com';
// const String _localHostIp = '192.168.0.107'; 

final String baseUrl = () {
  if (kReleaseMode) {
    return _productionUrl;
  }
  
  // For development testing on Render, uncomment the line below:
  return _productionUrl;
  
  // Local development fallback:
  // if (kIsWeb) {
  //   return 'http://localhost:3000';
  // }
  // return 'http://$_localHostIp:3000';
}();
