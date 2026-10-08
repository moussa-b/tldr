import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../models/models.dart';

/// One chat-style call returning a JSON object that follows [schema].
class LlmRequest {
  const LlmRequest({
    required this.model,
    required this.apiKey,
    required this.system,
    required this.user,
    required this.schema,
    required this.geminiSchema,
    required this.toolName,
    this.timeout = const Duration(seconds: 75),
  });

  final String model;
  final String apiKey;
  final String system;
  final String user;
  final Map<String, dynamic> schema;
  final Map<String, dynamic> geminiSchema;
  final String toolName;
  final Duration timeout;
}

/// Calls an LLM provider directly over REST (no SDK).
abstract interface class LlmClient {
  Future<Map<String, dynamic>> generateJson(LlmRequest request, {CancelToken? cancelToken});

  /// Cheapest authenticated call (list models). Returns false on 401/403.
  Future<bool> validateKey(String apiKey);
}

LlmClient llmClientFor(ProviderId provider, Dio dio) => switch (provider) {
      ProviderId.gemini => GeminiClient(dio),
      ProviderId.anthropic => AnthropicClient(dio),
      ProviderId.openai => OpenAiClient(dio),
    };

abstract class _RestLlmClient implements LlmClient {
  _RestLlmClient(this.dio);

  final Dio dio;

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
    Map<String, String> headers,
    Duration timeout,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        data: body,
        options: Options(
          headers: headers,
          contentType: Headers.jsonContentType,
          receiveTimeout: timeout,
          sendTimeout: const Duration(seconds: 15),
        ),
        cancelToken: cancelToken,
      );
      return response.data!;
    } on DioException catch (e) {
      throw mapProviderError(e);
    }
  }

  Future<bool> probe(String url, Map<String, String> headers) async {
    try {
      await dio.get<dynamic>(url,
          options: Options(headers: headers, receiveTimeout: const Duration(seconds: 15)));
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) return false;
      throw mapProviderError(e);
    }
  }
}

/// Provider HTTP failure → contract error code (spec « Révision 2026-10-09 »).
/// Never includes the raw provider body (it may echo part of the key).
ApiError mapProviderError(DioException e) {
  switch (e.type) {
    case DioExceptionType.cancel:
      return ApiError.cancelled;
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiError.timeout;
    case DioExceptionType.connectionError:
      return ApiError.network;
    default:
      break;
  }
  final status = e.response?.statusCode ?? 0;
  if (status == 401 || status == 403) {
    return const ApiError(
        code: 'LLM_KEY_INVALID', message: 'Key refused by provider', retryable: false);
  }
  if (status == 404) {
    return const ApiError(
        code: 'LLM_MODEL_UNAVAILABLE', message: 'Model not available', retryable: false);
  }
  if (status == 429) {
    final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '');
    return ApiError(
        code: 'LLM_QUOTA_EXCEEDED',
        message: 'Provider quota exceeded',
        retryable: true,
        retryAfterSeconds: retryAfter);
  }
  if (status == 400) {
    // Gemini answers 400 API_KEY_INVALID for a bad key.
    final body = e.response?.data;
    if (body is Map && jsonEncode(body).contains('API_KEY_INVALID')) {
      return const ApiError(
          code: 'LLM_KEY_INVALID', message: 'Key refused by provider', retryable: false);
    }
    return const ApiError(
        code: 'LLM_OUTPUT_INVALID', message: 'Request rejected by provider', retryable: true);
  }
  return const ApiError(
      code: 'LLM_UNAVAILABLE', message: 'Provider unavailable', retryable: true);
}

Map<String, dynamic> _decodeObject(String text) {
  final cleaned = text
      .trim()
      .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
      .replaceFirst(RegExp(r'\s*```$'), '');
  final decoded = jsonDecode(cleaned);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Output is not a JSON object');
  }
  return decoded;
}

class GeminiClient extends _RestLlmClient {
  GeminiClient(super.dio);

  static const _base = 'https://generativelanguage.googleapis.com/v1beta';

  @override
  Future<Map<String, dynamic>> generateJson(LlmRequest r, {CancelToken? cancelToken}) async {
    final data = await post(
      '$_base/models/${r.model}:generateContent',
      {
        'systemInstruction': {
          'parts': [
            {'text': r.system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': r.user},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 8192,
          'responseMimeType': 'application/json',
          'responseSchema': r.geminiSchema,
        },
      },
      {'x-goog-api-key': r.apiKey},
      r.timeout,
      cancelToken,
    );
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('No candidate in Gemini response');
    }
    final parts = (candidates.first['content']?['parts'] as List?) ?? const [];
    final text = parts.map((p) => (p as Map)['text'] ?? '').join();
    return _decodeObject(text);
  }

  @override
  Future<bool> validateKey(String apiKey) =>
      probe('$_base/models?pageSize=1', {'x-goog-api-key': apiKey});
}

class OpenAiClient extends _RestLlmClient {
  OpenAiClient(super.dio);

  static const _base = 'https://api.openai.com/v1';

  @override
  Future<Map<String, dynamic>> generateJson(LlmRequest r, {CancelToken? cancelToken}) async {
    final data = await post(
      '$_base/chat/completions',
      {
        'model': r.model,
        // GPT-5 family models only accept the default temperature.
        'messages': [
          {'role': 'system', 'content': r.system},
          {'role': 'user', 'content': r.user},
        ],
        'response_format': {
          'type': 'json_schema',
          'json_schema': {'name': r.toolName, 'strict': true, 'schema': r.schema},
        },
      },
      {'Authorization': 'Bearer ${r.apiKey}'},
      r.timeout,
      cancelToken,
    );
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('No choice in OpenAI response');
    }
    final content = (choices.first['message'] as Map?)?['content'];
    if (content is! String) throw const FormatException('Empty OpenAI message');
    return _decodeObject(content);
  }

  @override
  Future<bool> validateKey(String apiKey) =>
      probe('$_base/models', {'Authorization': 'Bearer $apiKey'});
}

class AnthropicClient extends _RestLlmClient {
  AnthropicClient(super.dio);

  static const _base = 'https://api.anthropic.com/v1';
  static const _version = '2023-06-01';

  @override
  Future<Map<String, dynamic>> generateJson(LlmRequest r, {CancelToken? cancelToken}) async {
    final data = await post(
      '$_base/messages',
      {
        'model': r.model,
        'max_tokens': 8192,
        'temperature': 0.2,
        'system': r.system,
        'messages': [
          {'role': 'user', 'content': r.user},
        ],
        'tools': [
          {
            'name': r.toolName,
            'description': 'Submit the structured result.',
            'input_schema': r.schema,
          },
        ],
        'tool_choice': {'type': 'tool', 'name': r.toolName},
      },
      {'x-api-key': r.apiKey, 'anthropic-version': _version},
      r.timeout,
      cancelToken,
    );
    final content = data['content'];
    if (content is List) {
      for (final block in content) {
        if (block is Map && block['type'] == 'tool_use' && block['input'] is Map) {
          return Map<String, dynamic>.from(block['input'] as Map);
        }
      }
    }
    throw const FormatException('No tool_use block in Anthropic response');
  }

  @override
  Future<bool> validateKey(String apiKey) =>
      probe('$_base/models?limit=1', {'x-api-key': apiKey, 'anthropic-version': _version});
}
