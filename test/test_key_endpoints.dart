import 'package:http/http.dart' as http;

void main() async {
  print('Testing provider verification endpoints...');

  // 1. Gemini with an invalid key to see what Google returns
  final geminiRes = await http.get(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyFakeKey1234567890'),
  );
  print('Gemini invalid key status: ${geminiRes.statusCode} -> ${geminiRes.body}');

  // 2. Groq with an invalid key
  final groqRes = await http.get(
    Uri.parse('https://api.groq.com/openai/v1/models'),
    headers: {'Authorization': 'Bearer gsk_fakeKey123'},
  );
  print('Groq invalid key status: ${groqRes.statusCode} -> ${groqRes.body}');

  // 3. OpenRouter with an invalid key
  final orRes = await http.get(
    Uri.parse('https://openrouter.ai/api/v1/auth/key'),
    headers: {
      'Authorization': 'Bearer sk-or-fake123',
      'HTTP-Referer': 'https://shirazi.ai',
      'X-Title': 'Shirazi AI',
    },
  );
  print('OpenRouter invalid key status: ${orRes.statusCode} -> ${orRes.body}');
}
