import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/connect_point.dart';
import '../qshield/qshield_core.dart';

class InferenceResult {
  const InferenceResult({
    required this.success,
    this.text,
    this.error,
    this.latencyMs,
    this.usedQShield = false,
  });

  final bool success;
  final String? text;
  final String? error;
  final int? latencyMs;
  final bool usedQShield;
}

/// Bridges Shadøwnet connect points to local inference backends.
class InferenceBridge {
  InferenceBridge({QShieldCore? qshield}) : _qshield = qshield ?? QShieldCore();

  final QShieldCore _qshield;

  QShieldCore get qshield => _qshield;

  Future<bool> probeEndpoint(ConnectPoint point) async {
    try {
      final uri = Uri.parse(point.effectiveUrl);
      final response = await http
          .get(uri, headers: _headers(point))
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (_) {
      // Try health on /health or root
      try {
        final health = Uri.parse('${point.effectiveUrl.replaceAll(RegExp(r'/$'), '')}/health');
        final response = await http.get(health).timeout(const Duration(seconds: 3));
        return response.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  Future<InferenceResult> complete({
    required ConnectPoint point,
    required String prompt,
    bool sealWithQShield = true,
    String? modelName,
  }) async {
    final start = DateTime.now();
    try {
      if (sealWithQShield && !_qshield.sessionInfo.isReady) {
        await _qshield.establishSession();
      }

      final body = <String, dynamic>{
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'stream': false,
        'temperature': 0.7,
      };
      if (modelName != null && modelName.isNotEmpty) {
        body['model'] = modelName;
      } else if (point.modelPath.isNotEmpty) {
        body['model'] = point.modelPath;
      }

      String payloadJson = jsonEncode(body);
      if (sealWithQShield && _qshield.sessionInfo.isReady) {
        payloadJson = jsonEncode({
          'qshield_sealed': await _qshield.sealPayload(payloadJson),
          'hybrid': _qshield.sessionInfo.hybridProfile,
          'key_id': _qshield.sessionInfo.pqcKeyId,
        });
      }

      final uri = Uri.parse(point.chatCompletionsUrl);
      final response = await http
          .post(
            uri,
            headers: {
              ..._headers(point),
              'Content-Type': 'application/json',
              if (sealWithQShield) 'X-QShield-Session': _qshield.sessionInfo.sessionId,
            },
            body: payloadJson,
          )
          .timeout(const Duration(seconds: 120));

      final latency = DateTime.now().difference(start).inMilliseconds;

      if (response.statusCode != 200) {
        return InferenceResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
          latencyMs: latency,
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      String? text;

      if (decoded.containsKey('choices')) {
        final choices = decoded['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final msg = choices.first['message'] as Map<String, dynamic>?;
          text = msg?['content'] as String?;
        }
      } else if (decoded.containsKey('content')) {
        text = decoded['content'] as String?;
      } else if (decoded.containsKey('response')) {
        text = decoded['response'] as String?;
      }

      if (decoded.containsKey('qshield_sealed') && text == null) {
        text = await _qshield.openPayload(decoded['qshield_sealed'] as String);
      }

      return InferenceResult(
        success: true,
        text: text ?? response.body,
        latencyMs: latency,
        usedQShield: sealWithQShield && _qshield.sessionInfo.isReady,
      );
    } catch (e) {
      return InferenceResult(
        success: false,
        error: e.toString(),
        latencyMs: DateTime.now().difference(start).inMilliseconds,
      );
    }
  }

  Map<String, String> _headers(ConnectPoint point) {
    final h = <String, String>{};
    if (point.apiKey.isNotEmpty) {
      h['Authorization'] = 'Bearer ${point.apiKey}';
    }
    return h;
  }
}
