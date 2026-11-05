import 'theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'login_page.dart';
import 'translations.dart';
import 'demo.dart';
import 'report_actions.dart';
import 'report_media.dart';

// ── District model ─────────────────────────────────────────────────────────

class District {
  final String nameAr;
  final String nameEn;
  final String governorName;
  final String governorPhone;
  const District({
    required this.nameAr,
    required this.nameEn,
    required this.governorName,
    required this.governorPhone,
  });
}

const List<District> kDemoDistricts = [
  District(
    nameAr: 'الحي التجريبي الشمالي',
    nameEn: 'Demo North',
    governorName: 'فريق تجريبي / Demo team',
    governorPhone: '',
  ),
  District(
    nameAr: 'الحي التجريبي الجنوبي',
    nameEn: 'Demo South',
    governorName: 'فريق تجريبي / Demo team',
    governorPhone: '',
  ),
];
List<District> get availableDistricts => demoMode ? kDemoDistricts : kDistricts;

const List<District> kDistricts = [
  // ── التجمع الأول ──
  District(
    nameAr: 'الياسمين – شرق الأكاديمية',
    nameEn: 'Yasmin – East Academy',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الأربع مجاورات والميراج',
    nameEn: 'Al-Arba Mogarawet & Mirage',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'المستثمرين الشمالية والرحاب',
    nameEn: 'North Mostasmerin & Rehab',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'شمال الرحاب',
    nameEn: 'North Rehab',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الشباب الشمالي',
    nameEn: 'North Shabab',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الشباب الجنوبي',
    nameEn: 'South Shabab',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'البنفسج',
    nameEn: 'Al-Banafseg',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'القرنفل',
    nameEn: 'Al-Qaranful',
    governorName: '',
    governorPhone: '',
  ),
  // ── التجمع الثالث ──
  District(
    nameAr: 'النقابات',
    nameEn: 'Al-Niqabat',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'المحليات',
    nameEn: 'Al-Mahalliyat',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'بيت الوطن 1-4',
    nameEn: 'Beit Al-Watan 1-4',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'بيت الوطن 5-8',
    nameEn: 'Beit Al-Watan 5-8',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'تمر حنة',
    nameEn: 'Tamar Hanna',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الأندلس',
    nameEn: 'Al-Andalus',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'حي الشباب',
    nameEn: 'Hay Al-Shabab',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'حي الجولف',
    nameEn: 'Golf District',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'المنطقة الصناعية',
    nameEn: 'Industrial Zone',
    governorName: '',
    governorPhone: '',
  ),
  // ── التجمع الخامس ──
  District(
    nameAr: 'النرجس',
    nameEn: 'Al-Narjis',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'اللوتس',
    nameEn: 'Al-Lotus',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'المستثمرين الجنوبية',
    nameEn: 'South Mostasmerin',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'مركز المدينة',
    nameEn: 'City Center',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الحي الخامس والشويفات',
    nameEn: 'District 5 & Shweifat',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'جنوب الأكاديمية',
    nameEn: 'South Academy',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الحي الرابع',
    nameEn: 'Fourth District',
    governorName: '',
    governorPhone: '',
  ),
  District(
    nameAr: 'الحي الثالث',
    nameEn: 'Third District',
    governorName: '',
    governorPhone: '',
  ),
];

// ── Page ───────────────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  final String? initialCategory;
  const ReportPage({super.key, this.initialCategory});
  @override
  ReportPageState createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();

  String? _samplePhoto, _uploadedMedia, _lastPayload, _submitError;
  String _requestId = newRequestId();

  final List<String> _categories = [
    'cat_pothole',
    'cat_trash',
    'cat_lighting',
    'cat_sewage',
    'cat_water',
    'cat_other',
  ];
  String? _selectedCategory;
  District? _selectedDistrict;
  Uint8List? _selectedImageData;
  LatLng _selectedLocation = const LatLng(30.0444, 31.2357);
  bool _isLoading = false;
  bool _locationLoading = false;
  final bool _aiLoading = false;
  String? _aiSuggestion;

  @override
  void initState() {
    super.initState();
    // Pre-select category if passed from home grid
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check route arguments (when pushed via pushNamed with arguments)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _selectedCategory == null) {
      setState(() => _selectedCategory = args);
    }
  }

  // ── AI Classification ─────────────────────────────────────────────────────

  String _keywordClassify(String text) {
    final t = text.toLowerCase();
    if (RegExp(
      r'road|pothole|crack|pavement|asphalt|street damage|طريق|حفرة|رصيف|شقوق|تلف الطريق|مشاكل الطرق',
    ).hasMatch(t))
      return 'cat_pothole';
    if (RegExp(
      r'trash|garbage|waste|litter|dump|smell|dirty|قمامة|نفايات|زبالة|قذارة|روائح|نظافة|مشاكل النظافة',
    ).hasMatch(t))
      return 'cat_trash';
    if (RegExp(
      r'light|lamp|dark|electricity|power|bulb|إنارة|كهرباء|مصباح|ظلام|نور|تيار|مشاكل الكهرباء',
    ).hasMatch(t))
      return 'cat_lighting';
    if (RegExp(
      r'sewage|sewer|drain|overflow|مجاري|بالوعة|فيضان|مشاكل الصرف',
    ).hasMatch(t))
      return 'cat_sewage';
    if (RegExp(
      r'water|pipe|leak|flood|مياه|ماء|تسريب|أنبوب|مشاكل المياه',
    ).hasMatch(t))
      return 'cat_water';
    return 'cat_other';
  }

  Future<void> _classifyWithAI() async {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'اكتب وصف المشكلة أولاً' : 'Write a description first',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final matched = _keywordClassify(description);
    setState(() {
      _aiSuggestion = matched;
      _selectedCategory = matched;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'اقتراح محلي للفئة: ${t(matched, lang: lang)}'
              : 'Local category suggestion: ${t(matched, lang: lang)}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Image & Location ──────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    if (demoMode) {
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(
            isAr ? 'اختر صورة تجريبية' : 'Choose a synthetic illustration',
          ),
          children: sampleMedia.entries
              .where((e) => !e.key.startsWith('sample:repaired-'))
              .map(
                (e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.key),
                  child: Text(e.value),
                ),
              )
              .toList(),
        ),
      );
      if (mounted && selected != null) setState(() => _samplePhoto = selected);
      return;
    }
    // Show camera vs gallery choice
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'اختر مصدر الصورة' : 'Choose photo source',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: kPrimary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'الكاميرا' : 'Camera',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            color: Colors.grey.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'المعرض' : 'Gallery',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (pickedFile == null || !mounted) return;
      final bytes = await pickedFile.readAsBytes();
      imageContentType(bytes);
      if (!mounted) return;
      setState(() {
        _selectedImageData = bytes;
        _uploadedMedia = null;
      });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'اختر JPEG أو PNG أقل من 5 ميجابايت.'
                  : 'Choose a JPEG or PNG smaller than 5 MiB.',
            ),
          ),
        );
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_locationLoading) return;
    setState(() => _locationLoading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw StateError('Location disabled');
      if (!mounted) return;
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        throw StateError('Permission denied');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(
        () => _selectedLocation = LatLng(position.latitude, position.longitude),
      );
      _mapController.move(_selectedLocation, 15);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'الموقع غير متاح؛ حدد النقطة على الخريطة.'
                  : 'Location unavailable; choose a point on the map.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    if (_isLoading) return;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    if (!_formKey.currentState!.validate()) return;
    if (_descriptionController.text.trim().length < 5 ||
        _descriptionController.text.trim().length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'اكتب وصفاً بين 5 و2000 حرف.'
                : 'Write a description of 5–2000 characters.',
          ),
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'الرجاء اختيار فئة' : 'Please select a category',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'الرجاء اختيار الحي' : 'Please select a district',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_selectedImageData == null && _samplePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'الرجاء إرفاق صورة' : 'Please attach a photo'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _submitError = null;
    });
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_outlined,
                  color: kPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'مراجعة البلاغ' : 'Review your report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'راجع الفئة والحي قبل الإرسال.'
                    : 'Check the category and district before sending.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfirmRow(
                      label: isAr ? 'الفئة' : 'Category',
                      value: t(_selectedCategory!, lang: lang),
                    ),
                    _ConfirmRow(
                      label: isAr ? 'الحي' : 'District',
                      value: isAr
                          ? _selectedDistrict!.nameAr
                          : _selectedDistrict!.nameEn,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(isAr ? 'إلغاء' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: Text(isAr ? 'إرسال' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (!demoMode)
        _uploadedMedia ??= await uploadReportImage(
          supabase,
          _selectedImageData!,
        );
      if (!mounted) return;
      final report = {
        // Language changes must not create a new operation after an uncertain save.
        'title': demoMode
            ? _selectedDistrict!.nameEn
            : _selectedDistrict!.nameAr,
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!,
        'district': demoMode
            ? _selectedDistrict!.nameEn
            : _selectedDistrict!.nameAr,
        'photo_url': demoMode ? _samplePhoto! : _uploadedMedia!,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
      };
      final payload = jsonEncode(report);
      if (payload != _lastPayload) {
        _requestId = newRequestId();
        _lastPayload = payload;
      }
      final saved = await ReportActions(
        supabase,
      ).createReport(requestId: _requestId, report: report);
      if (!mounted) return;
      await _showSuccessDialog(saved['report_code'] as String, lang);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        setState(
          () => _submitError = isAr
              ? 'تعذر تأكيد حفظ البلاغ. التفاصيل محفوظة؛ أعد المحاولة.'
              : 'Could not confirm the save. Your details are kept; retry safely.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(String code, String lang) async {
    final isAr = lang == 'ar';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF388E3C),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'تم إرسال البلاغ' : 'Report submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'كود البلاغ الخاص بك:' : 'Your report code:',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kBlue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SelectableText(
                        code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: isAr ? 'نسخ كود البلاغ' : 'Copy report code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr ? 'تم نسخ الكود' : 'Report code copied',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_outlined,
                        size: 18,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'احفظ هذا الكود لمتابعة بلاغك'
                    : 'Save this code to track your report',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FixGreenButton(
                  label: isAr ? 'حسناً' : 'Done',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          t('report_page_title', lang: lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const _ReportSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'أخبرنا بما يحتاج إلى إصلاح'
                          : 'Tell us what needs fixing',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'الحقول التالية مطلوبة. ستراجع التفاصيل قبل الإرسال.'
                          : 'All sections are required. You can review the details before sending.',
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      label: isAr
                          ? '1. تفاصيل المشكلة'
                          : '1. Describe the problem',
                    ),
                    const SizedBox(height: 12),
                    // ── 1. Description ─────────────────────────────────
                    _SectionLabel(label: t('problem_desc', lang: lang)),
                    const SizedBox(height: 8),
                    FixField(
                      controller: _descriptionController,
                      label: '',
                      hint: isAr
                          ? 'مثال: عمود إنارة لا يعمل بجوار المدخل.'
                          : 'For example: the streetlight beside the entrance is not working.',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),

                    // AI button
                    _AIClassifyButton(
                      isLoading: _aiLoading,
                      isAr: isAr,
                      onTap: _classifyWithAI,
                    ),
                    const SizedBox(height: 20),

                    // Category grid
                    _SectionLabel(label: t('select_category', lang: lang)),
                    const SizedBox(height: 8),
                    _CategoryGrid(
                      categories: _categories,
                      selected: _selectedCategory,
                      aiSuggestion: _aiSuggestion,
                      lang: lang,
                      onSelect: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      label: isAr
                          ? '2. المكان والصورة'
                          : '2. Add the place and photo',
                    ),
                    const SizedBox(height: 12),
                    // ── 2. District ────────────────────────────────────
                    _SectionLabel(label: isAr ? 'اسم الحي' : 'District'),
                    const SizedBox(height: 8),
                    _DistrictDropdown(
                      selected: _selectedDistrict,
                      isAr: isAr,
                      onSelect: (d) => setState(() => _selectedDistrict = d),
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Photo ───────────────────────────────────────
                    _SectionLabel(label: isAr ? 'إرفاق صورة' : 'Attach Photo'),
                    const SizedBox(height: 8),
                    if (demoMode) ...[
                      if (_samplePhoto != null) ReportMedia(_samplePhoto!),
                      OutlinedButton(
                        onPressed: _pickImage,
                        child: Text(
                          isAr ? 'استخدام صورة تجريبية' : 'Use sample photo',
                        ),
                      ),
                    ] else
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: _selectedImageData != null ? null : 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedImageData != null
                                  ? kPrimary
                                  : Colors.grey.shade300,
                              width: _selectedImageData != null ? 2 : 1.5,
                            ),
                          ),
                          child: _selectedImageData != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Stack(
                                    children: [
                                      Image(
                                        image: ResizeImage(
                                          MemoryImage(_selectedImageData!),
                                          width: 1280,
                                          height: 1280,
                                          policy: ResizeImagePolicy.fit,
                                        ),
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: kPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 36,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isAr
                                          ? 'انقر لاختيار صورة'
                                          : 'Tap to choose a photo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── 4. Location ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionLabel(label: t('location_title', lang: lang)),
                        if (!demoMode)
                          TextButton.icon(
                            onPressed: _locationLoading
                                ? null
                                : _getCurrentLocation,
                            icon: _locationLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location,
                                    size: 16,
                                    color: kPrimary,
                                  ),
                            label: Text(
                              isAr ? 'موقعي الحالي' : 'My location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 260,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 13.0,
                            onTap: (_, point) =>
                                setState(() => _selectedLocation = point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

                              userAgentPackageName: 'dev.mosalah.fixcity',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 50,
                                  height: 50,
                                  point: _selectedLocation,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: kPrimary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: kPrimary,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                        child: Text(
                          isAr
                              ? 'حدد نقطة · © OpenStreetMap contributors'
                              : 'Choose a point · © OpenStreetMap contributors',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Divider(),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      label: isAr ? '3. مراجعة وإرسال' : '3. Review and send',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'تأكد من أن الموقع والصورة يوضحان المشكلة.'
                          : 'Check that the location and photo show the problem clearly.',
                    ),
                    const SizedBox(height: 16),
                    // ── Submit ─────────────────────────────────────────
                    if (_submitError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _submitError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    FixGreenButton(
                      label: t('submit_btn', lang: lang),
                      onPressed: _submitReport,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── District Dropdown ──────────────────────────────────────────────────────

class _DistrictDropdown extends StatelessWidget {
  final District? selected;
  final bool isAr;
  final ValueChanged<District> onSelect;
  const _DistrictDropdown({
    required this.selected,
    required this.isAr,
    required this.onSelect,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_city_outlined,
                      color: kPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAr ? 'اختر الحي' : 'Select a District',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: availableDistricts.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) {
                    final d = availableDistricts[i];
                    final isSelected = selected == d;
                    return InkWell(
                      onTap: () {
                        onSelect(d);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        color: isSelected
                            ? kPrimary.withValues(alpha: 0.05)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? d.nameAr : d.nameEn,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (!demoMode && d.governorName.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          d.governorName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          d.governorPhone,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: kPrimary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null ? kPrimary : Colors.grey.shade300,
            width: selected != null ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_city_outlined,
              color: selected != null ? kPrimary : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: selected != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? selected!.nameAr : selected!.nameEn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (!demoMode && selected!.governorName.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 11,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selected!.governorName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.phone_outlined,
                                size: 11,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selected!.governorPhone,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    )
                  : Text(
                      isAr ? 'اختر الحي' : 'Select a district',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: selected != null ? kPrimary : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Classify Button ─────────────────────────────────────────────────────

class _AIClassifyButton extends StatelessWidget {
  final bool isLoading;
  final bool isAr;
  final VoidCallback onTap;
  const _AIClassifyButton({
    required this.isLoading,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_fix_high_outlined),
      label: Text(
        isLoading
            ? (isAr ? 'جارٍ اقتراح الفئة...' : 'Choosing a category...')
            : (isAr ? 'اقتراح الفئة' : 'Suggest a category'),
      ),
    ),
  );
}

// ── Category Grid ──────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final String? aiSuggestion;
  final String lang;
  final ValueChanged<String> onSelect;
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.aiSuggestion,
    required this.lang,
    required this.onSelect,
  });

  static const _meta = {
    'cat_pothole': {
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFF59E0B),
    },
    'cat_trash': {'icon': Icons.delete_outline, 'color': Color(0xFFEF4444)},
    'cat_lighting': {'icon': Icons.bolt_outlined, 'color': Color(0xFF6366F1)},
    'cat_sewage': {
      'icon': Icons.water_damage_outlined,
      'color': Color(0xFF8B5CF6),
    },
    'cat_water': {
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF0EA5E9),
    },
    'cat_other': {'icon': Icons.more_horiz, 'color': Color(0xFF64748B)},
  };

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final category in categories)
        ChoiceChip(
          avatar: Icon(
            _meta[category]?['icon'] as IconData? ?? Icons.help_outline,
            size: 20,
          ),
          label: Text(t(category, lang: lang)),
          selected: selected == category,
          onSelected: (_) => onSelect(category),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
    ],
  );
}

// ── Skeleton ───────────────────────────────────────────────────────────────

class _ReportSkeleton extends StatefulWidget {
  const _ReportSkeleton();
  @override
  State<_ReportSkeleton> createState() => _ReportSkeletonState();
}

class _ReportSkeletonState extends State<_ReportSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bone({double h = 16, double? w, double r = 8}) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bone(h: 14, w: 120),
          const SizedBox(height: 8),
          _bone(h: 100, r: 10),
          const SizedBox(height: 12),
          _bone(h: 48, r: 12),
          const SizedBox(height: 20),
          _bone(h: 14, w: 120),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _bone(h: 80, r: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _bone(h: 14, w: 100),
          const SizedBox(height: 8),
          _bone(h: 60, r: 12),
          const SizedBox(height: 20),
          _bone(h: 14, w: 100),
          const SizedBox(height: 8),
          _bone(h: 120, r: 12),
          const SizedBox(height: 20),
          _bone(h: 260, r: 16),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(color: kPrimary),
                const SizedBox(height: 12),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'جارٍ إرسال البلاغ...'
                      : 'Submitting report...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  const _ConfirmRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
