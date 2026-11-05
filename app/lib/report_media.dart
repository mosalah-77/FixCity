import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'report_actions.dart';

const sampleMedia = {
  'sample:pothole': 'Damaged road / طريق متضرر',
  'sample:trash': 'Litter / مخلفات',
  'sample:lighting': 'Broken light / إنارة معطلة',
  'sample:repaired-road': 'Repaired road / طريق تم إصلاحه',
  'sample:repaired-trash': 'Cleared litter / إزالة المخلفات',
  'sample:repaired-lighting': 'Repaired light / إنارة تم إصلاحها',
};

String imageContentType(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024)
    throw const FormatException('Choose a JPEG or PNG smaller than 5 MiB.');
  if (bytes.length >= 8 &&
      bytes.take(8).join(',') == '137,80,78,71,13,10,26,10')
    return 'image/png';
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255)
    return 'image/jpeg';
  throw const FormatException('Choose a JPEG or PNG image.');
}

Future<String> uploadReportImage(SupabaseClient client, Uint8List bytes) async {
  final type = imageContentType(bytes);
  final user = client.auth.currentUser;
  if (user == null || user.isAnonymous)
    throw const AuthException(
      'Sign in with a normal account to upload images.',
    );
  final path =
      '${user.id}/${newRequestId()}.${type == 'image/png' ? 'png' : 'jpg'}';
  await client.storage
      .from('files')
      .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
  return 'storage:$path';
}

class ReportMedia extends StatefulWidget {
  final String media;
  final double height;
  const ReportMedia(this.media, {super.key, this.height = 180});
  @override
  State<ReportMedia> createState() => _ReportMediaState();
}

class _ReportMediaState extends State<ReportMedia> {
  Future<String>? _url;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ReportMedia old) {
    super.didUpdateWidget(old);
    if (old.media != widget.media) _load();
  }

  void _load() {
    _url = widget.media.startsWith('storage:')
        ? Supabase.instance.client.storage
              .from('files')
              .createSignedUrl(widget.media.substring(8), 60)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (sampleMedia.containsKey(widget.media)) {
      final repaired = widget.media.startsWith('sample:repaired-');
      final icon = widget.media.contains('trash')
          ? Icons.delete_outline
          : widget.media.contains('lighting')
          ? Icons.lightbulb_outline
          : Icons.add_road;
      return Semantics(
        label: sampleMedia[widget.media],
        image: true,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.height),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: repaired ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                repaired ? Icons.check_circle_outline : icon,
                size: 56,
                color: repaired ? Colors.green.shade700 : Colors.brown,
              ),
              const SizedBox(height: 8),
              Text(
                sampleMedia[widget.media]!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF102D40)),
              ),
              const Text(
                'Synthetic illustration / رسم تجريبي',
                style: TextStyle(fontSize: 12, color: Color(0xFF102D40)),
              ),
            ],
          ),
        ),
      );
    }
    Widget unavailable() => SizedBox(
      height: widget.height,
      child: const Center(child: Text('Image unavailable / الصورة غير متاحة')),
    );
    if (_url == null) return unavailable();
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Column(
            children: [
              unavailable(),
              TextButton(
                onPressed: () => setState(_load),
                child: const Text('Retry / إعادة المحاولة'),
              ),
            ],
          );
        if (!snapshot.hasData)
          return SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        return Image(
          image: ResizeImage(
            NetworkImage(snapshot.data!),
            width: 1280,
            height: 1280,
            policy: ResizeImagePolicy.fit,
          ),
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => unavailable(),
        );
      },
    );
  }
}
