import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';

class BhashiniService {
  static final _googleTranslator = GoogleTranslator();

  /// Map internal app locales ('en', 'hi', 'mr', 'gu') to standard language codes
  static String _mapLangCode(String locale) {
    if (locale == 'en') return 'en';
    if (locale == 'hi') return 'hi';
    if (locale == 'mr') return 'mr';
    if (locale == 'gu') return 'gu';
    return 'en';
  }

  /// Translates [text] from [sourceLang] to [targetLang].
  /// Tries Bhashini API first, falls back to Google Translate automatically.
  static Future<String> translate(
      String text, String sourceLang, String targetLang) async {
    if (sourceLang == targetLang) return text;
    if (text.trim().isEmpty || text == '•' || text == '-') return text;

    final userId = dotenv.env['BHASHINI_USER_ID'];
    final apiKey = dotenv.env['BHASHINI_API_KEY'];
    final pipelineId = dotenv.env['BHASHINI_PIPELINE_ID'];

    // If Bhashini is not configured, seamlessly fallback to translation package
    if (userId == null || apiKey == null || pipelineId == null) {
      return _fallbackTranslate(text, sourceLang, targetLang);
    }

    try {
      final response = await http.post(
        Uri.parse('https://dhruva-api.bhashini.gov.in/services/inference/pipeline'),
        headers: {
          'Content-Type': 'application/json',
          'userID': userId,
          'ulcaApiKey': apiKey,
        },
        body: jsonEncode({
          "pipelineTasks": [
            {
              "taskType": "translation",
              "config": {
                "language": {
                  "sourceLanguage": _mapLangCode(sourceLang),
                  "targetLanguage": _mapLangCode(targetLang)
                }
              }
            }
          ],
          "inputData": {
            "input": [
              {"source": text}
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final output = data['pipelineResponse']?[0]?['output']?[0]?['target'];
        if (output != null && output.toString().isNotEmpty) {
          return output.toString();
        }
      }
      
      return _fallbackTranslate(text, sourceLang, targetLang);
    } catch (e) {
      return _fallbackTranslate(text, sourceLang, targetLang);
    }
  }

  static Future<String> _fallbackTranslate(
      String text, String sourceLang, String targetLang) async {
    try {
      final translation = await _googleTranslator.translate(
        text,
        from: sourceLang,
        to: targetLang,
      );
      return translation.text;
    } catch (_) {
      // Ultimate safety net: return original text
      return text;
    }
  }
}
