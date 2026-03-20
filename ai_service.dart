// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  // Replace with your actual API key in production (use env vars / secure storage)
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';

  /// Ask AI to suggest symbol/emoji substitutes for each letter
  static Future<Map<String, List<String>>> suggestCipherTable() async {
    const prompt = '''
You are a cipher designer. Create a substitution cipher table for the English alphabet (a-z) and space.
For each letter, provide 2-3 unique symbol/emoji substitutes that look visually similar or thematic.
Use Unicode symbols, mathematical symbols, or emojis.
Respond ONLY with valid JSON in this exact format, no other text:
{
  "a": ["@", "🅰️", "△"],
  "b": ["β", "🅱️", "ᗷ"],
  ...continue for all letters and space...
}
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 2000,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(clean) as Map<String, dynamic>;
        return parsed.map((k, v) => MapEntry(k, List<String>.from(v as List)));
      }
    } catch (e) {
      // Fall back to defaults
    }
    return {};
  }

  /// Ask AI to suggest additional substitutes for a specific letter
  static Future<List<String>> suggestSubstitutes(String letter) async {
    final prompt =
        'Suggest 3 visually interesting Unicode symbols, mathematical symbols, or emojis that could substitute for the letter "$letter" in a secret cipher. '
        'Respond ONLY with a JSON array of strings, e.g. ["@", "⊕", "🔴"]. No other text.';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 200,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(clean) as List;
        return List<String>.from(parsed);
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
