import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/venue.dart';
import 'api_config.dart';

final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  final url = Uri.parse('$baseUrl/venues');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> body = jsonDecode(response.body);
    return body.map((dynamic item) => Venue.fromJson(item as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load venues: ${response.reasonPhrase}');
  }
});
