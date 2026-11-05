const Map<String, Map<String, String>> _localizedValues = {
  'ar': {
    // --- General ---
    'app_title': 'فيكس سيتي',
    'switch_lang': 'English',
    'admin_tooltip': 'دخول المشرفين',
    'logout': 'تسجيل الخروج',
    'snack_logout': 'تم تسجيل الخروج',

    // --- Home Page ---
    'welcome_title': 'مرحباً بك في FixCity',
    'welcome_subtitle': 'بلّغ عن مشكلة وتابع إصلاحها',
    'submit_report': 'تقديم بلاغ',
    'report_subtitle': 'أبلغ عن مشكلة في المرافق العامة',
    'track_report': 'متابعة البلاغات',
    'track_subtitle': 'تابع حالة البلاغ المقدم بالكود',
    'login': 'تسجيل الدخول',
    'login_subtitle': 'سجل الدخول لمتابعة بلاغاتك',
    'my_reports': 'بلاغاتي',
    'my_reports_subtitle': 'عرض كل البلاغات التي قدمتها',
    'snack_construction': 'صفحة بلاغاتي (تحت الإنشاء)',

    // --- Login/Signup ---
    'signup': 'إنشاء حساب',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'full_name': 'الاسم الكامل',
    'phone': 'رقم الهاتف',
    'have_account': 'لديك حساب بالفعل؟ سجل الدخول',

    // --- Report Page ---
    'report_page_title': 'تقديم بلاغ جديد',
    'problem_desc': 'وصف المشكلة',
    'problem_type': 'نوع المشكلة (طرق، إنارة، نظافة...)',
    'location_link': 'رابط الموقع (Google Maps)',
    'get_location': 'جلب موقعي الحالي',
    'submit_btn': 'إرسال البلاغ',
    'success_message': 'تم إرسال البلاغ بنجاح! الكود: ',
    'error_message': 'فشل الإرسال: ',
    'fill_fields_error': 'يرجى تعبئة جميع الحقول المطلوبة',
    'cat_pothole': 'الطرق',
    'cat_trash': 'النظافة',
    'cat_lighting': 'الإنارة',
    'cat_sewage': 'الصرف الصحي',
    'cat_water': 'المياه',
    'cat_other': 'أخرى',
    'pick_image': 'إرفاق صورة',
    'problem_title': 'عنوان المشكلة',
    'select_category': 'اختر الفئة',
    'location_title': 'تحديد الموقع',

    // --- Track Page ---
    'track_page_title': 'متابعة حالة البلاغ',
    'enter_code': 'أدخل كود البلاغ',
    'search_btn': 'بحث',
    'report_status': 'حالة البلاغ',
    'admin_reply': 'رد المسؤول',
    'not_found': 'لم يتم العثور على بلاغ بهذا الكود',

    // --- Statuses (Database values) ---
    'pending': 'قيد الانتظار',
    'in_progress': 'جارٍ العمل',
    'resolved': 'تم الحل',
  },
  'en': {
    // --- General ---
    'app_title': 'Fixcity',
    'switch_lang': 'عربي',
    'admin_tooltip': 'Admin Login',
    'logout': 'Logout',
    'snack_logout': 'Logged out successfully',

    // --- Home Page ---
    'welcome_title': 'Welcome to Fixcity',
    'welcome_subtitle': 'Report a problem and follow the repair',
    'submit_report': 'Submit Report',
    'report_subtitle': 'Report a public utility issue',
    'track_report': 'Track Reports',
    'track_subtitle': 'Track your report status by code',
    'login': 'Login',
    'login_subtitle': 'Log in to track your reports',
    'my_reports': 'My Reports',
    'my_reports_subtitle': 'View all your submitted reports',
    'snack_construction': 'My Reports page (Under Construction)',

    // --- Login/Signup ---
    'signup': 'Sign Up',
    'email': 'Email',
    'password': 'Password',
    'full_name': 'Full Name',
    'phone': 'Phone Number',
    'have_account': 'Already have an account? Log in',

    // --- Report Page ---
    'report_page_title': 'New report',
    'problem_desc': 'Problem description',
    'problem_type': 'Problem Type (Roads, Lighting, etc.)',
    'location_link': 'Location Link (Google Maps)',
    'get_location': 'Get Current Location',
    'submit_btn': 'Submit Report',
    'success_message': 'Report Submitted! Code: ',
    'error_message': 'Submission Failed: ',
    'fill_fields_error': 'Please fill all required fields',
    'cat_pothole': 'Roads',
    'cat_trash': 'Cleanliness',
    'cat_lighting': 'Lighting',
    'cat_sewage': 'Sewage',
    'cat_water': 'Water',
    'cat_other': 'Other',
    'pick_image': 'Attach a photo',
    'problem_title': 'Problem Title',
    'select_category': 'Choose a category',
    'location_title': 'Set location',

    // --- Track Page ---
    'track_page_title': 'Track a report',
    'enter_code': 'Enter report code',
    'search_btn': 'Search',
    'report_status': 'Status',
    'admin_reply': 'Staff reply',
    'not_found': 'No report found with this code',

    // --- Statuses ---
    'pending': 'Pending',
    'in_progress': 'In Progress',
    'resolved': 'Resolved',
  },
};

String t(String key, {String lang = 'ar'}) {
  return _localizedValues[lang]?[key] ?? key;
}
