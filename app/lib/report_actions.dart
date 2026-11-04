import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

String newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class ReportActions {
  final SupabaseClient client;
  ReportActions(this.client);

  Future<Map<String, dynamic>> createReport({
    required String requestId,
    required Map<String, dynamic> report,
  }) async {
    final result = await client.rpc(
      'create_report',
      params: {'p_request_id': requestId, 'p_report': report},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> transitionReport({
    required String requestId,
    required String reportId,
    required String status,
    required String note,
    String? fixPhotoUrl,
  }) async {
    await client.rpc(
      'transition_report',
      params: {
        'p_request_id': requestId,
        'p_report_id': reportId,
        'p_status': status,
        'p_note': note,
        'p_fix_photo_url': fixPhotoUrl,
      },
    );
  }
}
