import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const testUserId = '11111111-1111-4111-8111-111111111111';

Map<String, dynamic> testUser() => {
  'id': testUserId,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'citizen@example.test',
  'app_metadata': {
    'provider': 'email',
    'providers': ['email'],
  },
  'user_metadata': {'full_name': 'Demo Citizen'},
  'created_at': '2026-01-01T00:00:00Z',
};

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response sessionResponse() {
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': testUserId,
            'exp': 4102444800,
            'role': 'authenticated',
          }),
        ),
      )
      .replaceAll('=', '');
  return jsonResponse({
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.test',
    'refresh_token': 'synthetic-refresh-token',
    'expires_in': 3600,
    'expires_at': 4102444800,
    'token_type': 'bearer',
    'user': testUser(),
  });
}

Future<void> initializeBackend(
  FutureOr<http.Response> Function(http.Request) handle,
) async {
  await Supabase.initialize(
    url: 'https://fixcity.example.test',
    anonKey: 'synthetic-test-key',
    httpClient: MockClient((request) async {
      final response = await handle(request);
      return http.Response.bytes(
        response.bodyBytes,
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    }),
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: false,
      detectSessionInUri: false,
      localStorage: const EmptyLocalStorage(),
      pkceAsyncStorage: _MemoryStorage(),
    ),
    debug: false,
  );
}

class _MemoryStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _items[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _items[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _items.remove(key);
  }
}

http.Response unexpectedRequest(http.Request request) => jsonResponse({
  'message': 'Unexpected test request: ${request.method} ${request.url.path}',
  'code': 'TEST_UNEXPECTED_REQUEST',
}, 400);
