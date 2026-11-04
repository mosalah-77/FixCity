import 'dart:convert';
import 'dart:typed_data';
import 'package:fixcity/report_actions.dart';
import 'package:fixcity/report_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async => Supabase.instance.dispose());
  test(
    'save errors propagate without points, notification or storage writes',
    () async {
      final paths = <String>[];
      await initializeBackend((request) {
        paths.add(request.url.path);
        return jsonResponse({'code': '08006', 'message': 'Unavailable'}, 503);
      });
      await expectLater(
        ReportActions(
          Supabase.instance.client,
        ).createReport(requestId: newRequestId(), report: {'title': 'Example'}),
        throwsA(isA<PostgrestException>()),
      );
      expect(paths, ['/rest/v1/rpc/create_report']);
    },
  );
  test(
    'image upload preserves PNG type and uses a private user-owned path',
    () async {
      String? uploadPath, contentType, uploadBody;
      await initializeBackend((request) {
        if (request.url.path == '/auth/v1/token') return sessionResponse();
        uploadPath = request.url.path;
        contentType = request.headers['content-type'];
        uploadBody = utf8.decode(request.bodyBytes, allowMalformed: true);
        return jsonResponse({'Key': 'files/example', 'Id': 'test'});
      });
      final client = Supabase.instance.client;
      await client.auth.signInWithPassword(
        email: 'citizen@example.test',
        password: 'test-password',
      );
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
      );
      final media = await uploadReportImage(client, png);
      expect(contentType, startsWith('multipart/form-data'));
      expect(uploadBody!.toLowerCase(), contains('content-type: image/png'));
      expect(uploadPath, startsWith('/storage/v1/object/files/$testUserId/'));
      expect(media, startsWith('storage:$testUserId/'));
      expect(media, endsWith('.png'));
    },
  );
  test('invalid and oversized images fail before any upload', () async {
    var calls = 0;
    await initializeBackend((request) {
      calls++;
      return unexpectedRequest(request);
    });
    expect(
      () => imageContentType(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    expect(
      () => imageContentType(Uint8List(5 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
    expect(calls, 0);
    expect(
      newRequestId(),
      matches(
        RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ),
      ),
    );
  });
}
