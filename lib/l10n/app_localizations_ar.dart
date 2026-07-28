// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tierHowGold => 'ذهبي: حساب موثّق + ١٠ مشاريع منجزة أو ٥ تقييمات.';

  @override
  String get tierHowSilver => 'فضي: ٣ مشاريع منجزة أو حساب موثّق.';

  @override
  String get tierNotForSale =>
      'المستوى بيتكسب بالشغل المنجز — مش بيتباع ومش جزء من اشتراك برو.';

  @override
  String quotesLeftThisMonth(int remaining) {
    return 'باقي لك $remaining عروض مجانية الشهر ده';
  }

  @override
  String get appName => 'شطب';

  @override
  String get appNameLatin => 'Shattab';

  @override
  String get enterPhone => 'ادخل رقم تليفونك';

  @override
  String get phoneHint => '+20 1XX XXX XXXX';

  @override
  String get phoneLocalHint => '1XX XXX XXXX';

  @override
  String get continueLabel => 'كمّل';

  @override
  String get otpTitle => 'ادخل كود التحقق';

  @override
  String get signInSheetTitle => 'سجّل دخولك للمتابعة';

  @override
  String get signInToSave => 'سجّل دخولك لحفظ هذا المحترف';

  @override
  String get signInToSendRequest => 'سجّل دخولك لإرسال طلبك';

  @override
  String get signInToPost => 'سجّل دخولك لنشر طلبك';

  @override
  String get signInToInteract => 'سجّل دخولك للتفاعل مع المنشورات';

  @override
  String get quoteSentShort => 'عرضك مُرسل';

  @override
  String get myQuotesTitle => 'عروضي';

  @override
  String get myQuotesEmptyTitle => 'لسّه مفيش عروض';

  @override
  String get signInToSeeRequests => 'سجّل دخولك لرؤية طلباتك';

  @override
  String get signInOrCreateAccount => 'سجّل دخولك أو أنشئ حساب';

  @override
  String get contractorSignInLink => 'محترف؟ سجّل دخولك من هنا';

  @override
  String get heroLine1 => 'شطب بيتك';

  @override
  String get heroLine2 => 'من غير وجع دماغ';

  @override
  String get phoneLabel => 'رقم التليفون';

  @override
  String get dataSecure => 'بياناتك آمنة ومشفرة';

  @override
  String get loginPrompt => 'لديك حساب بالفعل؟';

  @override
  String get loginAction => 'تسجيل الدخول';

  @override
  String get passwordLabel => 'كلمة السر';

  @override
  String get passwordHint => '٦ حروف على الأقل';

  @override
  String get confirmPasswordHint => 'أكّد كلمة السر';

  @override
  String get signInAction => 'دخول';

  @override
  String get createAccountAction => 'إنشاء حساب';

  @override
  String get noAccountPrompt => 'معندكش حساب؟';

  @override
  String get haveAccountPrompt => 'عندك حساب؟';

  @override
  String get forgotPassword => 'نسيت كلمة السر؟';

  @override
  String get continueWithGoogle => 'المتابعة عبر Google';

  @override
  String get orDivider => 'أو';

  @override
  String get quickActionsTitle => 'إجراءات سريعة';

  @override
  String get accountSettingsTitle => 'الإعدادات';

  @override
  String get taglineNew => 'من أول فكرة لآخر لمسة';

  @override
  String get otpHint => 'كود من ٦ أرقام';

  @override
  String get resendCode => 'ابعت الكود تاني';

  @override
  String get resendInSeconds => 'تقدر تعيد بعد %s ث';

  @override
  String get invalidPhone => 'رقم تليفون غير صحيح';

  @override
  String get invalidOtp => 'الكود اللي دخلته غير صحيح';

  @override
  String get signOut => 'تسجيل خروج';

  @override
  String get unknownErrorRetry => 'في حاجة غلط، جرّب تاني.';

  @override
  String get chooseRoleTitle => 'انت مين؟';

  @override
  String get roleHomeowner => 'صاحب شقة';

  @override
  String get roleHomeownerSub => 'بدور على محترف يجدّد عندي';

  @override
  String get roleProfessional => 'محترف';

  @override
  String get roleContractorSub => 'بدور على شغل وعملاء جداد';

  @override
  String get apartmentTypeTitle => 'شقتك نوعها إيه؟';

  @override
  String get apartmentStudio => 'استوديو';

  @override
  String get apartmentOneBedroom => 'غرفة نوم';

  @override
  String get apartmentTwoBedroom => 'غرفتين نوم';

  @override
  String get apartmentThreeBedroomPlus => '٣ غرف أو أكتر';

  @override
  String get apartmentDuplex => 'دوبلكس';

  @override
  String get apartmentVilla => 'فيلا';

  @override
  String get apartmentPenthouse => 'بنتهاوس';

  @override
  String get locationTitle => 'مكانك فين؟';

  @override
  String get cityLabel => 'المحافظة';

  @override
  String get districtLabel => 'الحي / المنطقة';

  @override
  String get cityCairo => 'القاهرة';

  @override
  String get cityGiza => 'الجيزة';

  @override
  String get cityAlexandria => 'الإسكندرية';

  @override
  String get cityNewCairo => 'القاهرة الجديدة';

  @override
  String get city6October => '٦ أكتوبر';

  @override
  String get cityNorthCoast => 'الساحل الشمالي';

  @override
  String get interestsTitle => 'محتاج تجدّد إيه؟';

  @override
  String get interestsSubtitle => 'اختار واحد أو أكتر';

  @override
  String get interestPaint => 'دهانات';

  @override
  String get interestFlooring => 'أرضيات';

  @override
  String get interestKitchen => 'مطبخ';

  @override
  String get interestBathroom => 'حمام';

  @override
  String get interestElectrical => 'كهرباء';

  @override
  String get interestPlumbing => 'سباكة';

  @override
  String get interestFullReno => 'تشطيب كامل';

  @override
  String get businessNameTitle => 'اسم شركتك أو نشاطك';

  @override
  String get businessNameHint => 'مثال: مقاولات الفنّان';

  @override
  String get displayNameLabel => 'اسم المسؤول';

  @override
  String get specialtiesTitle => 'تخصصاتك إيه؟';

  @override
  String get specialtiesSubtitle => 'اختار كل اللي بتعمله';

  @override
  String get serviceAreasTitle => 'بتشتغل فين؟';

  @override
  String get serviceAreasSubtitle => 'اختار المحافظات اللي بتغطّيها';

  @override
  String get logoUploadTitle => 'صورة أو لوجو لنشاطك';

  @override
  String get logoUploadHint => 'اختياري — تقدر تتخطّاه دلوقتي';

  @override
  String get chooseImage => 'اختار صورة';

  @override
  String get experienceTitle => 'سنين خبرتك ونبذة عنك';

  @override
  String get yearsExperience => 'سنين الخبرة';

  @override
  String get bioLabel => 'نبذة قصيرة';

  @override
  String get bioHint => 'احكي عن شغلك في سطرين أو ٣';

  @override
  String get save => 'احفظ';

  @override
  String get next => 'التالي';

  @override
  String get skip => 'تخطّى';

  @override
  String get back => 'رجوع';

  @override
  String get done => 'تمام';

  @override
  String get comingSoon => 'قريب…';

  @override
  String get comingSoonM3 => 'الميزة دي قيد التحضير';

  @override
  String get optional => '(اختياري)';

  @override
  String get tabDiscover => 'المحترفين';

  @override
  String get tabRequests => 'طلباتي';

  @override
  String get tabSaved => 'المحفوظات';

  @override
  String get tabProfile => 'حسابي';

  @override
  String get tabDashboard => 'لوحة التحكم';

  @override
  String get tabOpportunities => 'فرص شغل';

  @override
  String get tabInbox => 'الطلبات';

  @override
  String get tabPortfolio => 'أعمالي';

  @override
  String get tabExplore => 'أعمال';

  @override
  String get exploreTitle => 'أعمال';

  @override
  String get createPost => 'إضافة منشور';

  @override
  String get editPost => 'تعديل المنشور';

  @override
  String get deletePost => 'حذف المنشور';

  @override
  String get postCaptionHint => 'اكتب تعليق...';

  @override
  String get postCaptionLabel => 'الوصف';

  @override
  String get addMedia => 'أضف صور';

  @override
  String get postTypeLabel => 'نوع المنشور';

  @override
  String get postTypeProjectShowcase => 'عرض مشروع';

  @override
  String get postTypeTip => 'نصيحة';

  @override
  String get postTypeMilestone => 'إنجاز';

  @override
  String get postTypeRenovationUpdate => 'تحديث';

  @override
  String get postCategoryLabel => 'التصنيف';

  @override
  String get postLinkPortfolio => 'اربط بمشروع في أعمالك';

  @override
  String get sharePost => 'مشاركة';

  @override
  String get likeLabel => 'إعجاب';

  @override
  String get commentLabel => 'تعليق';

  @override
  String get saveLabel => 'حفظ';

  @override
  String get commentsTitle => 'التعليقات';

  @override
  String get commentHint => 'اكتب تعليق...';

  @override
  String get postComment => 'نشر';

  @override
  String get noComments => 'لا توجد تعليقات بعد';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد';

  @override
  String get noPostsYetSub => 'كن أول من ينشر في الاستكشف!';

  @override
  String get myPosts => 'منشوراتي';

  @override
  String get savedPosts => 'المنشورات المحفوظة';

  @override
  String get myPostsEmpty => 'معندكش منشورات';

  @override
  String get savedPostsEmpty => 'ما حفظتش منشورات';

  @override
  String get postUnavailable => 'المنشور مش موجود';

  @override
  String get postCreated => 'تم نشر المنشور';

  @override
  String get postDeleted => 'تم حذف المنشور';

  @override
  String get commentPosted => 'تم نشر التعليق';

  @override
  String get commentRateLimitError => 'بتعلق بسرعة! استنى شوية';

  @override
  String get captionRequired => 'الوصف مطلوب';

  @override
  String get photoCount => 'عدد الصور: %s';

  @override
  String get agoNow => 'الآن';

  @override
  String get agoMin => 'منذ دقيقة';

  @override
  String get agoMins => 'منذ %s دقائق';

  @override
  String get agoHour => 'منذ ساعة';

  @override
  String get agoHours => 'منذ %s ساعات';

  @override
  String get agoDay => 'منذ يوم';

  @override
  String get agoDays => 'منذ %s أيام';

  @override
  String get quotesSectionTitle => 'عروض الأسعار';

  @override
  String get sendQuote => 'أرسل عرض سعر';

  @override
  String get yourQuote => 'عرضك الحالي';

  @override
  String get editQuote => 'عدّل العرض';

  @override
  String get submitQuote => 'ابعت العرض';

  @override
  String get quoteSentSuccess => 'اتبعت العرض بنجاح';

  @override
  String get priceFromLabel => 'السعر من';

  @override
  String get priceToLabel => 'لـ';

  @override
  String get priceEgpHint => 'بالجنيه';

  @override
  String get priceOnRequest => 'السعر حسب المعاينة';

  @override
  String get fixedPriceLabel => 'سعر ثابت';

  @override
  String get durationLabel => 'المدة المتوقعة';

  @override
  String get durationHint => 'مثال: أسبوعين';

  @override
  String get quoteNoteLabel => 'تفاصيل العرض';

  @override
  String get quoteNoteRequired => 'لازم تكتب تفاصيل العرض';

  @override
  String get egpUnit => 'ج.م';

  @override
  String get quoteAccept => 'قبول';

  @override
  String get quoteDecline => 'رفض';

  @override
  String get quoteAcceptConfirm => 'تقبل العرض ده؟';

  @override
  String get quoteDeclineConfirm => 'ترفض العرض ده؟';

  @override
  String get quoteStatusSent => 'في انتظار الرد';

  @override
  String get quoteStatusAccepted => 'مقبول';

  @override
  String get quoteStatusDeclined => 'مرفوض';

  @override
  String get quoteStatusWithdrawn => 'مسحوب';

  @override
  String get noQuoteBadge => 'محتاج رد';

  @override
  String get noQuotesYet => 'لسه مفيش عروض على الطلب ده';

  @override
  String get viewContractorProfile => 'شوف الملف';

  @override
  String get proPlanName => 'برو';

  @override
  String get freePlanName => 'مجاني';

  @override
  String get paywallTitle => 'باقة برو';

  @override
  String get proRequiredToQuoteTitle => 'اشترك في برو عشان تبعت عروض';

  @override
  String get proBenefitQuotes => 'عروض أسعار غير محدودة';

  @override
  String get proBenefitRanking => 'ظهور أعلى في نتائج البحث';

  @override
  String get proBenefitPhotos => 'صور أعمال أكتر في معرضك';

  @override
  String get upgradeToProCta => 'اشترك دلوقتي';

  @override
  String get upgradeToProShort => 'اشترك في برو';

  @override
  String get perMonth => '/ شهر';

  @override
  String get paymentComingSoon => 'الدفع هيكون متاح قريب جداً.';

  @override
  String get currentPlanLabel => 'باقتك الحالية';

  @override
  String get previewPublicProfile => 'معاينة الملف';

  @override
  String get memberSinceLabel => 'عضو منذ';

  @override
  String get proActiveLine => 'اشتراك برو مفعّل';

  @override
  String get tierGold => 'ذهبي';

  @override
  String get tierSilver => 'فضي';

  @override
  String get tierBronze => 'برونزي';

  @override
  String get tierLevelPrefix => 'مستوى';

  @override
  String get tierHowTitle => 'إزاي بتتحسب المستويات؟';

  @override
  String get trustSectionTitle => 'ليه تثق في المحترف ده؟';

  @override
  String get verifiedIdentity => 'هوية موثّقة';

  @override
  String get verifiedBusiness => 'نشاط تجاري موثّق';

  @override
  String get highlightTopRated => 'الأعلى تقييماً';

  @override
  String get highlightRecommended => 'موصى به';

  @override
  String get highlightEstablished => 'سجل أعمال طويل';

  @override
  String get responseTimeLabel => 'متوسط الرد';

  @override
  String get completionRateLabel => 'نسبة إنجاز المشاريع';

  @override
  String withinMinutes(int n) {
    return 'خلال $n دقيقة';
  }

  @override
  String withinHours(int n) {
    return 'خلال $n ساعة';
  }

  @override
  String withinDays(int n) {
    return 'خلال $n يوم';
  }

  @override
  String get reviewVerifiedChip => 'تقييم موثّق';

  @override
  String get ratingBreakdownTitle => 'توزيع التقييمات';

  @override
  String reviewsBasedOn(int n) {
    return 'محسوبة من آخر $n تقييم';
  }

  @override
  String get reviewSortNewest => 'الأحدث';

  @override
  String get reviewSortHighest => 'الأعلى';

  @override
  String get reviewSortLowest => 'الأقل';

  @override
  String get reviewFilterAll => 'الكل';

  @override
  String get reviewFilterWithText => 'فيها تعليق';

  @override
  String get reviewFilterWithPhotos => 'فيها صور';

  @override
  String get reviewsNoMatch => 'مفيش تقييمات بالفلتر ده';

  @override
  String get reviewsClearFilter => 'امسح الفلتر';

  @override
  String get ratingOutOfFive => 'من ٥';

  @override
  String get projectDurationLabel => 'مدة التنفيذ';

  @override
  String projectDurationMonths(int n) {
    return '$n شهر';
  }

  @override
  String get accountWelcome => 'أهلاً بك';

  @override
  String get ratingCaption => 'تقييم العملاء';

  @override
  String get statJobs => 'عدد الأعمال';

  @override
  String get statLevel => 'مستوى';

  @override
  String get proBannerSubtitle => 'مميزات حصرية تنمّي شغلك';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get darkModeSubtitle => 'مظهر داكن مريح للعين';

  @override
  String get verifySubtitle => 'اكسب علامة موثّق الذهبية';

  @override
  String get languageSubtitle => 'العربية أو الإنجليزية';

  @override
  String get helpSubtitle => 'كلّمنا على واتساب';

  @override
  String get verifyTileLabel => 'توثيق الحساب';

  @override
  String get verifyStateVerified => 'موثّق';

  @override
  String get verifyTitle => 'توثيق الحساب';

  @override
  String get verifyBenefitTrust => 'علامة موثّق ذهبية على ملفك';

  @override
  String get verifyBenefitRanking => 'ظهور أعلى في نتائج البحث';

  @override
  String get verifyBenefitFree => 'مجاني تماماً، مرة واحدة';

  @override
  String get verifyUploadLabel => 'ارفع صور المستندات';

  @override
  String get verifyNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get verifySubmit => 'إرسال للمراجعة';

  @override
  String get verifyDocsRequired => 'ارفع صورة مستند واحدة على الأقل';

  @override
  String get verifyError => 'تعذّر الإرسال، حاول تاني';

  @override
  String get verifyPendingTitle => 'طلبك قيد المراجعة';

  @override
  String get verifyApprovedTitle => 'حسابك موثّق';

  @override
  String get verifyDone => 'تمام';

  @override
  String get proScreenTitle => 'شطب برو';

  @override
  String get planMonthly => 'شهري';

  @override
  String get planAnnual => 'سنوي';

  @override
  String get annualSaveBadge => 'وفّر شهرين';

  @override
  String get perYear => '/ سنة';

  @override
  String get startFreeMonth => 'ابدأ شهر مجاني';

  @override
  String get cancelAnytime => 'تقدر تلغي في أي وقت';

  @override
  String get proBenefitSeen => 'إشعار لما العميل يشوف عرضك';

  @override
  String get trustPaymob => 'الدفع عن طريق Paymob · آمن';

  @override
  String get comparePlans => 'المجاني وبرو';

  @override
  String get cmpQuotes => 'عروض الأسعار';

  @override
  String get cmpQuotesFree => '٣ في الشهر';

  @override
  String get cmpUnlimited => 'بلا حدود';

  @override
  String get cmpRequests => 'الطلبات المباشرة';

  @override
  String get cmpRequestsFree => 'قراءة بس';

  @override
  String get cmpRequestsPro => 'ردّ وابعت عرض';

  @override
  String get cmpRanking => 'الترتيب في البحث';

  @override
  String get cmpRankingFree => 'عادي';

  @override
  String get cmpRankingPro => 'أعلى';

  @override
  String get cmpPortfolio => 'معرض الأعمال';

  @override
  String get cmpPortfolioFree => '٥ أعمال';

  @override
  String get cmpSeenRow => 'إشعار «شاف عرضك»';

  @override
  String proExpiresOn(String date) {
    return 'بينتهي في $date';
  }

  @override
  String get choosePaymentMethod => 'اختار طريقة الدفع';

  @override
  String get payInstapay => 'انستا باي';

  @override
  String get payApplePay => 'Apple Pay';

  @override
  String get paySoonBadge => 'قريب';

  @override
  String get payApplePaySub => 'بالبطاقة أو المحفظة — قريب';

  @override
  String get instapayTitle => 'الدفع عن طريق انستا باي';

  @override
  String get instapayAmountLabel => 'المبلغ المطلوب';

  @override
  String get instapayNumberLabel => 'حوّل على رقم انستا باي ده';

  @override
  String get copyAction => 'نسخ';

  @override
  String get copiedToast => 'اتنسخ';

  @override
  String get instapayUploadLabel => 'ارفع صورة التحويل';

  @override
  String get instapayRefLabel => 'رقم العملية (اختياري)';

  @override
  String get instapaySubmit => 'ابعت للتأكيد';

  @override
  String get instapayProofRequired => 'ارفع صورة التحويل الأول';

  @override
  String get instapaySubmittedTitle => 'طلبك تحت المراجعة';

  @override
  String get instapayDone => 'تمام';

  @override
  String get instapayError => 'حصل خطأ، حاول تاني';

  @override
  String get applePaySoon => 'Apple Pay هيكون متاح قريب';

  @override
  String get inboxTitle => 'الطلبات المباشرة';

  @override
  String get inboxEmptyTitle => 'مفيش طلبات مباشرة';

  @override
  String get requestDetailTitle => 'تفاصيل الطلب';

  @override
  String get contactClient => 'تواصل مع العميل';

  @override
  String get myPortfolioTitle => 'أعمالي';

  @override
  String get addWork => 'أضف عمل';

  @override
  String get newWorkTitle => 'عمل جديد';

  @override
  String get editWorkTitle => 'تعديل العمل';

  @override
  String get portfolioEmptyTitle => 'لسه مضفتش أعمال';

  @override
  String get workTitleLabel => 'عنوان العمل';

  @override
  String get workCategoryLabel => 'التصنيف';

  @override
  String get workCategoryHint => 'مثال: تشطيب كامل';

  @override
  String get workYearLabel => 'سنة التنفيذ';

  @override
  String get workYearHint => 'مثال: 2025';

  @override
  String get workLocationLabel => 'المكان';

  @override
  String get workLocationHint => 'مثال: القاهرة الجديدة';

  @override
  String get workDescriptionLabel => 'الوصف';

  @override
  String get workDescriptionHint => 'اكتب نبذة قصيرة عن العمل';

  @override
  String get coverPhotoHint => 'أول صورة هتكون صورة الغلاف';

  @override
  String get saveWork => 'احفظ العمل';

  @override
  String get deleteWork => 'حذف العمل';

  @override
  String get titleRequired => 'لازم تكتب عنوان للعمل';

  @override
  String get coverRequired => 'لازم تضيف صورة واحدة على الأقل';

  @override
  String get searchHint => 'ابحث عن محترف أو شركة…';

  @override
  String get featuredContractors => 'محترفين مميزين';

  @override
  String get topRated => 'الأعلى تقييمًا';

  @override
  String get recentWorkTitle => 'أعمال حديثة';

  @override
  String get nearYou => 'قريبين منك';

  @override
  String nearYouIn(String city) {
    return 'قريبين منك في $city';
  }

  @override
  String get browseByCategory => 'تصفّح بالتخصص';

  @override
  String get trendingNearYou => 'رائج بالقرب منك';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get verified => 'موثوق';

  @override
  String get allProfessionals => 'كل المحترفين';

  @override
  String get noContractorsTitle => 'مفيش محترفين بالشروط دي';

  @override
  String get noContractorsMessage => 'جرّب تغيّر التخصص أو المحافظة';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get profileNameLabel => 'الاسم';

  @override
  String get profilePhoneLabel => 'رقم التليفون';

  @override
  String get phoneNotEditable => 'لا يمكن تغيير رقم التليفون';

  @override
  String get changePhoto => 'اضغط لتغيير الصورة';

  @override
  String get housingData => 'بيانات السكن';

  @override
  String get interestAreas => 'مجالات الاهتمام';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get saveProfile => 'حفظ';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get profileError => 'حصل خطأ، حاول تاني';

  @override
  String get selectCity => 'اختار المحافظة';

  @override
  String get selectDistrict => 'اختار المنطقة';

  @override
  String get editProfileButton => 'تعديل الملف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get confirm => 'تأكيد';

  @override
  String get ok => 'حسنًا';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get signOutButton => 'تسجيل الخروج';

  @override
  String get signOutTitle => 'تأكيد تسجيل الخروج';

  @override
  String get signOutConfirmation => 'متأكد إنك عايز تسجل خروج؟';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get mySaved => 'المحفوظات';

  @override
  String get discoverContractors => 'اكتشف المحترفين';

  @override
  String get darkModeTitle => 'الوضع الليلي';

  @override
  String get lightModeTitle => 'الوضع النهاري';

  @override
  String get motionLabel => 'الحركة';

  @override
  String get darkMode => 'الوضع الليلي';

  @override
  String get lightMode => 'الوضع النهاري';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get briefDetailTitle => 'تفاصيل الطلب';

  @override
  String get cancelBriefTitle => 'إلغاء الطلب؟';

  @override
  String get cancelBriefNo => 'لأ، خليه';

  @override
  String get cancelBriefYes => 'أيوة، إلغي';

  @override
  String get cancelButton => 'إلغاء الطلب';

  @override
  String get briefNotFound => 'الطلب مش موجود';

  @override
  String get tryAgain => 'حاول تاني';

  @override
  String get locationDetailsLabel => 'تفاصيل المكان';

  @override
  String get lookingForLabel => 'بدور على';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get statusPost => 'بوست عام';

  @override
  String get statusDirectRequest => 'طلب مباشر';

  @override
  String get briefSentTitle => 'تم إرسال طلبك!';

  @override
  String get doneBackToDiscover => 'تمام، رجوع للاكتشاف';

  @override
  String get briefSentWhatsApp => 'تواصل مع المحترف على واتساب';

  @override
  String get briefSentCall => 'اتصل بالمحترف';

  @override
  String get briefSentBackToRequests => 'رجوع لطلباتي';

  @override
  String get createPostTitle => 'عمل بوست جديد';

  @override
  String get workTypeLabel => 'نوع الشغل';

  @override
  String get workTypeHint => 'مثال: تشطيب حمام';

  @override
  String get apartmentTypeLabel => 'نوع الوحدة';

  @override
  String get budgetLabel => 'الميزانية التقريبية (اختياري)';

  @override
  String get budgetHint => 'مثال: ٥٠٠٠٠';

  @override
  String get timelineLabel => 'الموعد المقترح';

  @override
  String get timelineHint => 'مثال: خلال أسبوعين';

  @override
  String get descriptionLabel => 'تفاصيل الشغل';

  @override
  String get descriptionHint => 'اكتب أي تفاصيل تانية...';

  @override
  String get photosLabel => 'الصور (اختياري)';

  @override
  String get createPostButton => 'انشر البوستر';

  @override
  String get writeWhatYouNeed => 'اكتب اللي محتاجه';

  @override
  String get sectionLookingForWho => 'بدور على مين؟';

  @override
  String get errorWriteMoreDetails => 'اكتب تفاصيل أكتر';

  @override
  String get errorFillApartmentCity => 'املا نوع الشقة والمحافظة';

  @override
  String get errorSelectSpecialty => 'اختار تخصص أو أكتر';

  @override
  String get sendBriefTitle => 'ابعث طلب مباشر';

  @override
  String get sendBriefDescriptionLabel => 'تفاصيل الشغل';

  @override
  String get sendBriefPhotosLabel => 'الصور (اختياري)';

  @override
  String get sendBriefButton => 'ابعت الطلب';

  @override
  String get sendBriefDefaultTitle => 'ابعت تفاصيل المشروع';

  @override
  String get sendBriefProjectDetails => 'تفاصيل مشروعك';

  @override
  String get sendBriefWorkDescLabel => 'وصف الشغل المطلوب';

  @override
  String get sendBriefWorkDescHint => 'مثال: محتاج تشطيب كامل…';

  @override
  String get myBriefsTitle => 'طلباتي';

  @override
  String get newPostButton => 'بوست جديد';

  @override
  String get noBriefsTitle => 'مفيش طلبات لسه';

  @override
  String get createNewPostButton => 'اعمل بوست جديد';

  @override
  String get noBriefsHere => 'مفيش حاجة هنا لسه';

  @override
  String get sectionOpenPosts => 'بوستات مفتوحة';

  @override
  String get sectionDirectRequests => 'طلبات مباشرة';

  @override
  String get opportunitiesTitle => 'فرص شغل';

  @override
  String get noPostsTitle => 'مفيش بوستات دلوقتي';

  @override
  String get postDetailTitle => 'تفاصيل البوستر';

  @override
  String get postDescriptionLabel => 'تفاصيل الشغل';

  @override
  String get postLocationLabel => 'الموقع';

  @override
  String get homeownerLabel => 'صاحب البوستر';

  @override
  String get contactHomeowner => 'تواصل مع صاحب البوستر';

  @override
  String get sendQuoteButton => 'أرسل عرض سعر';

  @override
  String get yourQuoteLabel => 'عرضك الحالي';

  @override
  String get postNotFound => 'البوست مش موجود';

  @override
  String get postDetailPostedPrefix => 'اتنشر: ';

  @override
  String get clientInfoFailed => 'تعذر تحميل بيانات العميل';

  @override
  String get sendQuoteCTA => 'أرسل عرض سعر';

  @override
  String get portfolioGalleryTitle => 'معرض الأعمال';

  @override
  String get noWorksTitle => 'مفيش أعمال متضافة لسه';

  @override
  String get projectDetailTitle => 'تفاصيل العمل';

  @override
  String get projectCategoryLabel => 'التصنيف';

  @override
  String get projectYearLabel => 'السنة';

  @override
  String get projectLocationLabel => 'المكان';

  @override
  String get projectDescriptionLabel => 'الوصف';

  @override
  String get projectNotFound => 'العمل مش موجود';

  @override
  String get contractorProfileTitle => 'ملف المحترف';

  @override
  String get ratingLabel => 'التقييم';

  @override
  String get reviewsCount => 'تقييم';

  @override
  String get specialtiesLabel => 'التخصصات';

  @override
  String get serviceAreasLabel => 'مناطق الخدمة';

  @override
  String get saveContractor => 'احفظ';

  @override
  String get savedContractor => 'محفوظ';

  @override
  String get sendBriefCTA => 'ابعث طلب';

  @override
  String get viewPortfolio => 'شوف الأعمال';

  @override
  String get writeReviewTitle => 'اكتب تقييم';

  @override
  String get reviewTitleLabel => 'عنوان التقييم';

  @override
  String get reviewTitleHint => 'مثال: شغل ممتاز';

  @override
  String get reviewBodyLabel => 'التفاصيل';

  @override
  String get reviewBodyHint => 'اكتب تجربتك مع المحترف...';

  @override
  String get reviewSubmit => 'انشر التقييم';

  @override
  String get reviewRequired => 'لازم تكتب عنوان وتفاصيل';

  @override
  String get reviewSuccess => 'اتباع التقييم بنجاح';

  @override
  String get rateContractor => 'قيّم المحترف';

  @override
  String get yourReview => 'رأيك (اختياري)';

  @override
  String get yourReviewHint => 'احكي تجربتك مع المحترف';

  @override
  String get submitReview => 'إرسال التقييم';

  @override
  String get selectStarsFirst => 'اختار تقييم بالنجوم الأول';

  @override
  String get editReview => 'تعديل';

  @override
  String get ratingHelpsOthers => 'تقييمك بيساعد باقي العملاء';

  @override
  String get contactViaWhatsApp => 'تواصل عبر واتساب';

  @override
  String get call => 'اتصل';

  @override
  String get phone => 'تليفون';

  @override
  String get createPostPublishButton => 'انشر البوست';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get newJobs => 'فرص عمل جديدة';

  @override
  String get searchJobs => 'ابحث عن فرصة عمل...';

  @override
  String get filterToday => 'اليوم';

  @override
  String get filterNearest => 'الأقرب';

  @override
  String get filterHighestBudget => 'أعلى ميزانية';

  @override
  String get filterVerified => 'عملاء موثوقين';

  @override
  String get filterUrgent => 'عاجل';

  @override
  String get filterPainting => 'دهانات';

  @override
  String get filterElectrical => 'كهرباء';

  @override
  String get filterPlumbing => 'سباكة';

  @override
  String get filterFinishing => 'تشطيب';

  @override
  String get filterBathrooms => 'حمامات';

  @override
  String get filterKitchens => 'مطابخ';

  @override
  String get urgentLabel => 'عاجل';

  @override
  String get newLabel => 'جديد';

  @override
  String get openJobs => 'فرص شغل';

  @override
  String get applicants => 'متقدمين';

  @override
  String get budget => 'الميزانية';

  @override
  String get verifiedTrust => 'موثق';

  @override
  String get filter => 'تصفية';

  @override
  String get apply => 'تطبيق';

  @override
  String get clearAll => 'إلغاء الكل';

  @override
  String filterWithCount(int count) {
    return 'تصفية ($count)';
  }

  @override
  String get filterSort => 'الترتيب';

  @override
  String get filterCategory => 'التخصص';

  @override
  String get filterCity => 'المدينة';

  @override
  String get filterTime => 'الوقت';

  @override
  String get filterThisWeek => 'هذا الأسبوع';

  @override
  String get filterThisMonth => 'هذا الشهر';

  @override
  String get filterNewestFirst => 'الأحدث';

  @override
  String get noJobsTitle => 'مفيش فرص شغل دلوقتي';

  @override
  String get noJobsMatchSearchTitle => 'مفيش فرصة بالاسم ده';

  @override
  String get clearSearch => 'امسح البحث';

  @override
  String get editedMarker => 'تم التعديل';

  @override
  String get withdrawQuote => 'اسحب العرض';

  @override
  String get quoteWithdrawn => 'تم سحب العرض';

  @override
  String get withdrawQuoteTitle => 'تسحب العرض؟';

  @override
  String get deleteBriefTitle => 'تمسح الطلب ده؟';

  @override
  String get briefDeleted => 'تم مسح الطلب';

  @override
  String get briefCancelledInstead => 'تم إلغاء الطلب';

  @override
  String get editBriefTitle => 'تعديل الطلب';

  @override
  String get saveChanges => 'احفظ التعديلات';

  @override
  String get changesSaved => 'اتحفظت التعديلات';

  @override
  String get markWorkDone => 'خلصت الشغل';

  @override
  String get confirmWorkDone => 'تم التنفيذ';

  @override
  String get awaitingHomeownerConfirm => 'في انتظار تأكيد صاحب البيت';

  @override
  String get confirmCompletionTitle => 'الشغل خلص فعلاً؟';

  @override
  String get workCompletedNow => 'تم تسجيل إن الشغل خلص';

  @override
  String get completedLabel => 'مكتمل';

  @override
  String get workTypeSpecLabel => 'نوع الشغل';

  @override
  String get publishedSpecLabel => 'تم النشر';

  @override
  String get closePhotoViewer => 'إغلاق الصورة';

  @override
  String get openPhotoViewer => 'افتح الصورة';

  @override
  String photoIndexOf(int index, int total) {
    return '$index / $total';
  }

  @override
  String morePhotosCount(int count) {
    return '+$count';
  }

  @override
  String get debugMode => 'وضع التجربة (Debug)';

  @override
  String get demoLoginHomeowner => 'دخول كصاحب شقة';

  @override
  String get demoLoginContractor => 'دخول كمحترف';

  @override
  String get networkError => 'مفيش اتصال بالإنترنت';

  @override
  String get somethingWentWrong => 'حصل خطأ، حاول تاني';

  @override
  String get nameNotEnough => 'الاسم مش كافي';

  @override
  String get nameExample => 'مثال: أحمد علي';

  @override
  String get refreshHint => 'اسحب للأسفل عشان التحديث';

  @override
  String get yearsExperienceInvalid => 'سنين خبرة غير صحيحة';

  @override
  String get noSavedContractors => 'مفيش محترفين محفوظين لسه';

  @override
  String get contractorNotFound => 'المحترف مش موجود';

  @override
  String get contractorNotFoundMsg => 'يمكن يكون شال الحساب أو اتلغى';

  @override
  String get projectDetails => 'تفاصيل مشروعك';

  @override
  String get statusOpen => 'بوست مفتوح';

  @override
  String get statusDirect => 'طلب مباشر';

  @override
  String get newBadge => 'جديد';

  @override
  String get urgentBadge => 'عاجل';

  @override
  String get projects => 'مشروع';

  @override
  String get singleProject => 'مشروع';

  @override
  String get year => 'سنة';

  @override
  String get photos => 'صور';

  @override
  String get removePhoto => 'احذف الصورة';

  @override
  String get saveTooltip => 'حفظ المحترف';

  @override
  String get unsaveTooltip => 'إزالة من المحفوظات';

  @override
  String get allSpecialties => 'كل التخصصات';

  @override
  String get allCities => 'كل المحافظات';

  @override
  String get foundProfessionals => 'محترف';

  @override
  String get editLabel => 'تعديل';

  @override
  String get deleteLabel => 'حذف';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String get retry => 'حاول تاني';

  @override
  String get noMoreResults => 'خلصت النتائج';

  @override
  String get loading => 'جاري التحميل';

  @override
  String get loadingMore => 'بيحمل المزيد...';

  @override
  String get noResultsFound => 'مالقيش نتائج';

  @override
  String get required => 'مطلوب';

  @override
  String get minLabel => 'أقل';

  @override
  String get maxLabel => 'أكثر';

  @override
  String get allRightsReserved => 'جميع الحقوق محفوظة لـ';

  @override
  String get activityPostedProject => 'نشر طلب عمل جديد';

  @override
  String get activityAcceptedQuote => 'قبل عرض سعر';

  @override
  String get activityPaymentCompleted => 'تم إتمام دفعة';

  @override
  String get activityNewReview => 'تقييم جديد';

  @override
  String get activityDisputeOpened => 'تم فتح نزاع';

  @override
  String get activityVerified => 'تم التوثيق';

  @override
  String get fieldRequired => 'الحقل ده مطلوب';

  @override
  String get invalidEmail => 'البريد الإلكتروني مش صحيح';

  @override
  String get tooShort => 'قصير جداً';

  @override
  String get tooLong => 'طويل جداً';

  @override
  String get passwordMismatch => 'كلمة السر مش متطابقة';

  @override
  String get errAuthFailed => 'فشل تسجيل الدخول، حاول تاني';

  @override
  String get errOtpFailed => 'كود التأكيد غلط، حاول تاني';

  @override
  String get errOtpExpired => 'الكود انتهت صلاحيته، ابعت واحد جديد';

  @override
  String get errNetwork => 'مفيش نت، اتأكد من اتصالك';

  @override
  String get errServerError => 'الخدمة مش شغالة دلوقتي، حاول تاني';

  @override
  String get errDataLoad => 'حصل مشكلة في تحميل البيانات';

  @override
  String get errDataSave => 'حصل مشكلة في حفظ البيانات';

  @override
  String get errSessionExpired => 'انتهت الجلسة، سجل دخول تاني';

  @override
  String get errPermissionDenied => 'مش مسموحلك تعمل كده';

  @override
  String get errNotFound => 'العنصر مش موجود';

  @override
  String get errPhotoUpload => 'حصل مشكلة في رفع الصور';

  @override
  String get errInvalidData => 'البيانات مش صحيحة، تأكد منها';

  @override
  String get portfolioAdd => 'أضف عمل';

  @override
  String get portfolioEdit => 'تعديل العمل';

  @override
  String get portfolioDelete => 'حذف العمل';

  @override
  String get portfolioDeleteError => 'حصل خطأ أثناء حذف العمل';

  @override
  String get postCreatedSuccess => 'تم نشر الطلب بنجاح';

  @override
  String get projectSavedSuccess => 'تم حفظ العمل بنجاح';

  @override
  String get projectDeletedSuccess => 'تم حذف العمل بنجاح';

  @override
  String get portfolioTitleLabel => 'عنوان العمل';

  @override
  String get portfolioTitleHint => 'مثال: تشطيب شقة ١٥٠م';

  @override
  String get portfolioCategoryLabel => 'التصنيف';

  @override
  String get portfolioCategoryHint => 'مثال: تشطيب';

  @override
  String get portfolioYearLabel => 'السنة';

  @override
  String get portfolioYearHint => 'مثال: ٢٠٢٥';

  @override
  String get portfolioLocationLabel => 'المكان';

  @override
  String get portfolioLocationHint => 'مثال: القاهرة';

  @override
  String get portfolioDescriptionLabel => 'الوصف';

  @override
  String get portfolioDescriptionHint => 'وصف العمل بالتفصيل...';

  @override
  String get portfolioCoverLabel => 'صورة الغلاف';

  @override
  String get portfolioPhotosLabel => 'صور العمل';

  @override
  String get portfolioSaved => 'تم حفظ العمل';

  @override
  String get portfolioSaveError => 'حصل خطأ أثناء حفظ العمل';

  @override
  String get photoMaxReached => 'وصلت للحد الأقصى من الصور';

  @override
  String get savedToast => 'تم الحفظ';

  @override
  String get unsavedToast => 'تم الإزالة من المحفوظات';

  @override
  String get motionFull => 'كامل';

  @override
  String get motionReduced => 'مخفض';

  @override
  String get motionOff => 'متوقف';

  @override
  String get yourData => 'بياناتك';

  @override
  String get apartmentType => 'نوع الشقة';

  @override
  String get fillBothFields => 'املا الحقلين';

  @override
  String get companyData => 'بيانات الشركة';

  @override
  String get companyName => 'اسم الشركة / المحترف';

  @override
  String get logo => 'الشعار';

  @override
  String get professionalTitle => 'العنوان المهني';

  @override
  String get professionalTitleHint => 'مثال: تشطيبات وديكورات فاخرة';

  @override
  String get bioInfo => 'نبذة عنك';

  @override
  String get coverPhoto => 'صورة الغلاف';

  @override
  String get sendProjectDetails => 'ابعت تفاصيل مشروعك';

  @override
  String get aboutProfessional => 'عن المحترف';

  @override
  String get worksIn => 'بيشتغل في';

  @override
  String get newProfessional => 'محترف جديد';

  @override
  String get noRatingsYet => 'لسه مفيش تقييمات';

  @override
  String get responseRate => 'معدل الرد';

  @override
  String get projectsCompleted => 'المشاريع المنجزة';

  @override
  String get experienceYears => 'سنين الخبرة';

  @override
  String get continueWithApple => 'تسجيل الدخول باستخدام Apple';

  @override
  String get professionals => 'محترفين';

  @override
  String get professionalSingular => 'محترف';

  @override
  String get providerKindContractor => 'مقاول';

  @override
  String get providerKindEngineer => 'مهندس';

  @override
  String get providerKindEngineeringOffice => 'مكتب هندسي';

  @override
  String get providerKindFinishingCompany => 'شركة تشطيبات';

  @override
  String get providerKindInteriorDesigner => 'مصمم داخلي';

  @override
  String get providerKindTradesman => 'فني متخصص';

  @override
  String get providerKindQuestion => 'إنت إيه بالظبط؟';

  @override
  String get quotaReachedTitle => 'خلصت عروضك المجانية';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfService => 'الشروط والأحكام';

  @override
  String get legalSectionLabel => 'قانوني';

  @override
  String get reportTitle => 'إبلاغ';

  @override
  String get reportPostAction => 'إبلاغ عن البوست';

  @override
  String get reportSent => 'وصلنا بلاغك، شكراً';

  @override
  String get reportAlreadySent => 'أنت مبلّغ عن ده قبل كده';

  @override
  String get reportReasonSpam => 'سبام أو إعلانات';

  @override
  String get reportReasonScam => 'نصب أو احتيال';

  @override
  String get reportReasonOffensive => 'محتوى مسيء';

  @override
  String get reportReasonSexual => 'محتوى جنسي';

  @override
  String get reportReasonViolence => 'عنف';

  @override
  String get reportReasonImpersonation => 'انتحال شخصية';

  @override
  String get reportReasonOther => 'سبب تاني';

  @override
  String get blockUser => 'حظر';

  @override
  String get blockUserTitle => 'تحظر الحساب ده؟';

  @override
  String get blockUserBody =>
      'مش هتشوف بوستاته وهو مش هيشوف بوستاتك. تقدر تلغي الحظر في أي وقت.';

  @override
  String get userBlocked => 'تم الحظر';

  @override
  String get unblockUser => 'إلغاء الحظر';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'تحذف حسابك نهائياً؟';

  @override
  String get deleteAccountBody =>
      'ده هيمسح حسابك وكل بياناتك: بوستاتك، طلباتك، عروض الأسعار، الصور والتقييمات. مفيش رجوع في ده.';

  @override
  String get deleteAccountConfirmWord => 'حذف';

  @override
  String get deleteAccountConfirmHint => 'اكتب \"حذف\" عشان تأكد';

  @override
  String get accountDeleted => 'تم حذف حسابك';

  @override
  String get reviewsSheetTitle => 'التقييمات';

  @override
  String get noReviewsYet => 'مفيش تقييمات لسه';

  @override
  String get share => 'مشاركة';

  @override
  String get copiedData => 'تم نسخ البيانات';

  @override
  String get seeOnShattab => 'شوف الملف على شطب: %s';

  @override
  String get forContact => 'للتواصل';

  @override
  String get clientsPreview => 'ده اللي بيشوفه العملاء';

  @override
  String get tellUsAboutYourself => 'قلنا عن نفسك';

  @override
  String get fullNameHint => 'الاسم بالكامل';

  @override
  String get chooseRole => 'اختر نوع الحساب';

  @override
  String minAgo(int n) {
    return 'منذ $n دقيقة';
  }

  @override
  String minsAgo(int n) {
    return 'منذ $n دقائق';
  }

  @override
  String hourAgo(int n) {
    return 'منذ $n ساعة';
  }

  @override
  String hoursAgo(int n) {
    return 'منذ $n ساعات';
  }

  @override
  String dayAgo(int n) {
    return 'منذ $n يوم';
  }

  @override
  String daysAgo(int n) {
    return 'منذ $n أيام';
  }

  @override
  String photosCount(int n) {
    return '$n صور';
  }

  @override
  String get briefSentMessageNew =>
      'المحترف استلم تفاصيل مشروعك وهيتواصل معاك قريب.\\nتقدر تكلّمه دلوقتي على واتساب لو حابب تستعجل.';

  @override
  String get cancelBriefMessage => 'مش هيقدر يتفعّل تاني بعد ما تلغيه.';

  @override
  String get chooseRoleSubtitle =>
      'اختار اللي يناسبك عشان نفصّل التجربة على مزاجك';

  @override
  String get confirmCompletionBody =>
      'لما تأكد، هيتسجل إن الشغل خلص وهتقدر تقيم المحترف. مش هينفع ترجع في ده.';

  @override
  String get contractorSaysDone => 'المحترف قال إنه خلص الشغل';

  @override
  String get contractorsWillSeeMatched =>
      'المحترفين اللي بتخصصاتهم وأماكنهم تطابق هيشوفوا البوست.';

  @override
  String get couldNotOpenApp => 'تعذّر فتح التطبيق. تأكد إنه متثبّت.';

  @override
  String get deleteBriefBody => 'مش هينفع ترجع فيه.';

  @override
  String get deleteBriefWithQuotesBody =>
      'فيه محترفين بعتوا عروض على الطلب ده، فهيتلغي بدل ما يتمسح عشان عروضهم ما تضيعش.';

  @override
  String get deletePostConfirm => 'متأكد إنك عايز تحذف المنشور؟';

  @override
  String get deleteWorkConfirm => 'متأكد إنك عايز تمسح العمل ده؟';

  @override
  String get descriptionWorkHint => 'مثال: محتاج حد يدهن الشقة كاملة…';

  @override
  String get errorDescriptionShort => 'اكتب وصف للشغل على الأقل من ١٠ حروف';

  @override
  String get heroSubtitle =>
      'اطلب الخدمة المناسبة واستقبل عروضًا من محترفين موثقين.';

  @override
  String get homeownerDetailsHint => 'عشان نرشّحلك أنسب المحترفين لبيتك';

  @override
  String get inboxEmptyMessage =>
      'لما عميل يبعتلك طلب مخصوص ليك هيظهر هنا على طول.';

  @override
  String get instapaySubmittedBody =>
      'استلمنا التحويل. هنفعّل باقة برو بعد التأكيد، عادة خلال ٢٤ ساعة.';

  @override
  String get myPostsEmptySub =>
      'اللي بتنشره في الاستكشف بيظهر هنا، وتقدر تعدله أو تمسحه في أي وقت.';

  @override
  String get myQuotesEmptyMessage => 'العروض اللي هتبعتها للطلبات هتظهر هنا';

  @override
  String get noBriefsHereMessage =>
      'ابعت طلب لمحترف معين من صفحته، أو اعمل بوست عام والمحترفين يتواصلوا معاك.';

  @override
  String get noJobsMatchSearchMessage =>
      'جرب كلمة تانية، أو امسح البحث وشوف كل الفرص المتاحة.';

  @override
  String get noJobsMessage =>
      'جرب تغير الفلاتر أو ارجع تاني بعدين. هتلاقي فرص جديدة باستمرار.';

  @override
  String get noReviewsYetSub => 'أول تقييم بيجي بعد أول شغلانة تخلص';

  @override
  String get noSavedContractorsMsg =>
      'اضغط على علامة الحفظ عشان تقدر ترجع تاني';

  @override
  String get noWorksMessage => 'المحترف هيضيف شغله هنا قريب.';

  @override
  String get passwordTooShort => 'كلمة السر لازم ٦ حروف على الأقل';

  @override
  String get payInstapaySub => 'تحويل فوري من أي بنك أو محفظة';

  @override
  String get paywallSubtitle => 'وصّل شغلك لعملاء أكتر واكسب أكتر.';

  @override
  String get phoneVisibleContractor =>
      'رقم تليفونك هيظهر للمحترف لما يستلم الطلب.';

  @override
  String get phoneVisibleContractors =>
      'رقم تليفونك هيظهر للمحترفين اللي يشوفوا البوست.';

  @override
  String get portfolioEmptyMessage =>
      'اعرض شغلك عشان العملاء يشوفوا مستواك. ابدأ بإضافة أول عمل ليك.';

  @override
  String get portfolioLoadFailed => 'مقدرناش نحمل الأعمال السابقة';

  @override
  String get postUnavailableSub => 'يمكن يكون اتمسح أو صاحبه خلاه خاص.';

  @override
  String get priceMinLessThanMax => 'السعر من يجب أن يكون أقل من السعر إلى';

  @override
  String get proBenefitRequests => 'شوف طلبات الشغل وبيانات التواصل';

  @override
  String get profileGreeting =>
      'السلام عليكم، شفت بروفايلك على شطب وحبيت أكلمك';

  @override
  String get proRoiLine => 'عرض واحد ممكن يرجّع اشتراك السنة كله';

  @override
  String get proValueLine => 'خلّي شغلك ما يوقفش، عروض بلا حدود';

  @override
  String get providerKindHelp =>
      'ده اللي هيظهر على ملفك. تقدر تغيّره في أي وقت.';

  @override
  String get quoteNoteHint => 'اكتب تفاصيل العرض وأي ملاحظات للعميل';

  @override
  String get reportSheetSubtitle => 'اختار سبب البلاغ. كل بلاغ بيتراجع يدوي.';

  @override
  String get reviewAfterCompletionHint =>
      'هتقدر تقيم المحترف بعد ما تأكد إن الشغل خلص';

  @override
  String get savedPostsEmptySub =>
      'اضغط علامة الحفظ على أي منشور عشان ترجعله بسرعة من هنا.';

  @override
  String get sendBriefAllDetailsHint =>
      'ابعت كل التفاصيل اللي محتاج المحترف يعرفها';

  @override
  String get signInEmptyMessage =>
      'حسابك بيحفظ شغلك وطلباتك، وترجعلك على أي جهاز تدخل منه.';

  @override
  String get signInToSeeSaved => 'سجّل دخولك لرؤية المحترفين المحفوظين';

  @override
  String get verifyApprovedBody => 'علامة التوثيق ظاهرة على ملفك دلوقتي.';

  @override
  String get verifyHeadline => 'وثّق حسابك وكسب ثقة العملاء';

  @override
  String get verifyPendingBody =>
      'بنراجع مستنداتك وهنفعّل التوثيق خلال ٤٨ ساعة.';

  @override
  String get verifyPrivacyNote => 'مستنداتك سرية وتُستخدم للتحقق فقط.';

  @override
  String get verifyUploadHint =>
      'بطاقة الرقم القومي، والسجل التجاري أو رخصة المهنة إن وجدت.';

  @override
  String get whatsappBriefGreeting => 'السلام عليكم، أنا بعتلك طلب على شطب';

  @override
  String get whatsappPostGreeting =>
      'السلام عليكم، شفت بوستك على شطب وحبيت أعرف أكتر عن الشغل';

  @override
  String get whatsYourName => 'إيه اسمك؟';

  @override
  String get withdrawQuoteBody =>
      'صاحب البيت مش هيقدر يقبل العرض ده بعد ما تسحبه. تقدر تبعت عرض جديد بعدين.';

  @override
  String get workDoneRequested => 'بلغنا صاحب البيت إنك خلصت';

  @override
  String get workTitleHint => 'مثال: تشطيب شقة في التجمع';
}
