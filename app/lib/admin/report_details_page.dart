import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../report_actions.dart';
import '../report_media.dart';

class ReportDetailsPage extends StatefulWidget {
  final String reportId;
  final bool districtView;
  const ReportDetailsPage({
    super.key,
    required this.reportId,
    this.districtView = false,
  });
  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final _client = Supabase.instance.client;
  final _note = TextEditingController();
  Map<String, dynamic>? _report;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true, _busy = false;
  String? _error, _updateMedia, _lastPayload;
  String _requestId = newRequestId();
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  bool _resolve = false;
  String label(String status) => statusLabel(status, _ar ? 'ar' : 'en');
  String? get _next {
    final status = _report?['status'];
    if (!widget.districtView) return status == 'pending' ? 'assigned' : null;
    if (status == 'assigned') return 'in_progress';
    if (status == 'in_progress') return _resolve ? 'resolved' : 'in_progress';
    return null;
  }

  String get _actionLabel => switch (_next) {
    'assigned' => _ar ? 'إحالة إلى فريق الحي' : 'Send to district',
    'resolved' => _ar ? 'تأكيد إتمام الإصلاح' : 'Mark resolved',
    _ =>
      _report?['status'] == 'assigned'
          ? (_ar ? 'بدء الإصلاح' : 'Start repair')
          : (_ar ? 'حفظ تحديث العمل' : 'Save progress update'),
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row = await _client
          .from('reports')
          .select()
          .eq('id', widget.reportId)
          .maybeSingle();
      if (!mounted) return;
      if (row == null) {
        setState(() {
          _report = null;
          _loading = false;
          _error = _ar
              ? 'البلاغ غير متاح لهذا الحساب'
              : 'Report unavailable for this account';
        });
        return;
      }
      final history = await _client
          .from('status_updates')
          .select()
          .eq('report_id', widget.reportId)
          .order('updated_at');
      if (!mounted) return;
      setState(() {
        _report = row;
        _history = List<Map<String, dynamic>>.from(history);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = _ar
              ? 'تعذر تحميل البلاغ. حاول مجدداً.'
              : 'Could not load this report. Please retry.';
        });
    }
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    if (_report?['workspace_id'] != null) {
      final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(_ar ? 'اختر صورة تجريبية' : 'Choose a sample photo'),
          children: sampleMedia.entries
              .where(
                (e) =>
                    _next != 'resolved' || e.key.startsWith('sample:repaired-'),
              )
              .map(
                (e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.key),
                  child: Text(e.value),
                ),
              )
              .toList(),
        ),
      );
      if (mounted && chosen != null) setState(() => _updateMedia = chosen);
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final media = await uploadReportImage(_client, bytes);
      if (!mounted) return;
      setState(() => _updateMedia = media);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = _ar
              ? 'تعذر رفع الصورة. اختر JPEG أو PNG أقل من 5 ميجابايت.'
              : 'Could not upload. Choose a JPEG or PNG smaller than 5 MiB.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _next == null) return;
    final status = _next!;
    final note = _note.text.trim();
    if (note.isEmpty || note.length > 2000) {
      setState(
        () => _error = _ar
            ? 'اكتب تحديثاً بين 1 و2000 حرف.'
            : 'Write an update of 1–2000 characters.',
      );
      return;
    }
    if (status == 'resolved' && _updateMedia == null) {
      setState(
        () => _error = _ar
            ? 'أرفق صورة الإصلاح أولاً.'
            : 'Please attach a repair photo first.',
      );
      return;
    }
    final payload = jsonEncode([status, note, _updateMedia]);
    if (payload != _lastPayload) {
      _requestId = newRequestId();
      _lastPayload = payload;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ReportActions(_client).transitionReport(
        requestId: _requestId,
        reportId: widget.reportId,
        status: status,
        note: note,
        fixPhotoUrl: _updateMedia,
      );
      if (!mounted) return;
      _note.clear();
      _updateMedia = null;
      _resolve = false;
      _lastPayload = null;
      // Keep the confirmed status even if the subsequent refresh fails.
      setState(() => _report = {..._report!, 'status': status});
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ar ? 'تم تحديث الحالة' : 'Status updated')),
        );
    } catch (_) {
      if (mounted)
        setState(
          () => _error = _ar
              ? 'تعذر تأكيد الحفظ. النص محفوظ؛ أعد المحاولة.'
              : 'Could not confirm the update. Your note is kept; retry safely.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = _report;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.districtView
              ? (_ar ? 'إصلاحات الحي' : 'District repair')
              : (_ar ? 'مراجعة البلاغ' : 'Staff review'),
        ),
        actions: [
          IconButton(
            tooltip: _ar ? 'تحديث' : 'Refresh',
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (row == null)
                    TextButton(
                      onPressed: _load,
                      child: Text(_ar ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  if (row != null) ...[
                    Text(
                      row['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(row['report_code'] ?? ''),
                    Text(label(row['status'])),
                    const SizedBox(height: 8),
                    Text(
                      widget.districtView
                          ? (_ar
                                ? 'سجّل بدء العمل وتقدمه، وأرفق دليل الإصلاح عند الانتهاء.'
                                : 'Record repair progress and attach evidence when the work is complete.')
                          : (_ar
                                ? 'راجع المعلومات والأدلة ثم أحل البلاغ إلى فريق الحي.'
                                : 'Check the details and evidence, then send the report to its district team.'),
                    ),
                    if (_next == null && row['status'] != 'resolved')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.districtView
                              ? (_ar
                                    ? 'بانتظار مراجعة الموظف وإحالة البلاغ.'
                                    : 'Waiting for staff review and handoff.')
                              : (_ar
                                    ? 'تمت الإحالة. فريق الحي مسؤول عن تحديث العمل وإتمام الإصلاح.'
                                    : 'Handed off. The district team now records progress and completes the repair.'),
                        ),
                      ),
                    Text(row['district'] ?? ''),
                    const SizedBox(height: 12),
                    Text(row['description'] ?? ''),
                    const SizedBox(height: 12),
                    if (row['photo_url'] != null) ReportMedia(row['photo_url']),
                    if (row['fix_photo_url'] != null) ...[
                      const SizedBox(height: 12),
                      ReportMedia(row['fix_photo_url']),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            (row['latitude'] as num).toDouble(),
                            (row['longitude'] as num).toDouble(),
                          ),
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                            userAgentPackageName: 'dev.mosalah.fixcity',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  (row['latitude'] as num).toDouble(),
                                  (row['longitude'] as num).toDouble(),
                                ),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: kPrimary,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_next != null) ...[
                      if (widget.districtView && row['status'] == 'in_progress')
                        DropdownButtonFormField<bool>(
                          value: _resolve,
                          decoration: InputDecoration(
                            labelText: _ar ? 'نوع التحديث' : 'Update type',
                          ),
                          items: [
                            DropdownMenuItem(
                              value: false,
                              child: Text(
                                _ar ? 'تحديث سير العمل' : 'Progress update',
                              ),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text(
                                _ar ? 'إتمام الإصلاح' : 'Resolve report',
                              ),
                            ),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) => setState(() {
                                  _resolve = value ?? false;
                                  _updateMedia = null;
                                  _error = null;
                                }),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        '${_ar ? 'الخطوة التالية' : 'Next step'}: $_actionLabel',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _note,
                        enabled: !_busy,
                        maxLines: 3,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: _ar ? 'نص التحديث' : 'Update text',
                        ),
                      ),
                      ...[
                        if (_updateMedia != null) ReportMedia(_updateMedia!),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _pickPhoto,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _next == 'resolved'
                                ? (_ar
                                      ? 'إرفاق صورة الإصلاح'
                                      : 'Attach repair photo')
                                : (_ar
                                      ? 'إرفاق صورة (اختياري)'
                                      : 'Attach photo (optional)'),
                          ),
                        ),
                      ],
                      if (_updateMedia != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _updateMedia = null),
                          child: Text(_ar ? 'إزالة الصورة' : 'Remove photo'),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(
                          _busy
                              ? (_ar ? 'جارٍ الحفظ...' : 'Saving…')
                              : _actionLabel,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      _ar ? 'سجل التحديثات' : 'Update History',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (final item in _history) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['text'] ?? ''),
                        subtitle: Text(
                          '${item['updated_by']} · ${DateTime.parse(item['updated_at']).toLocal()}',
                        ),
                      ),
                      if (item['photo_url'] != null)
                        ReportMedia(item['photo_url']),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
