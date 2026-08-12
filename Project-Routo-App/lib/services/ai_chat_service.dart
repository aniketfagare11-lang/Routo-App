import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  AiChatService();

  Future<String> sendMessage(String message) async {
    try {
      // Pointing directly to your FREE Vercel Backend
      // This is safe to expose in the frontend because the Vercel backend handles the secret API key.
      const String baseUrl = 'https://projectroutoapp.vercel.app/api/chat';
      final uri = Uri.parse(baseUrl);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Sorry, I received an empty response.';
      } else {
        debugPrint('Backend error: ${response.statusCode} - ${response.body}');
        return 'I encountered a server error. Please try again later.';
      }
    } catch (e) {
      debugPrint('Error sending message to backend: $e');
      return 'Connection Error: $e';
    }
  }
}
