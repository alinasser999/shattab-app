// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get opportunityPostedBy => 'صاحب الطلب';

  @override
  String get viewHomeownerProfile => 'عرض ملف صاحب الطلب';

  @override
  String get homeownerProfileTitle => 'ملف صاحب الطلب';

  @override
  String get homeownerProfileSubtitle => 'تفاصيل عامة عن صاحب الطلب';

  @override
  String get homeownerProfileDetailsTitle => 'تفاصيل صاحب الطلب';

  @override
  String get homeownerLocationLabel => 'منطقة المشروع';

  @override
  String get homeownerApartmentLabel => 'نوع الوحدة';

  @override
  String get homeownerInterestsLabel => 'اهتمامات التشطيب';

  @override
  String get homeownerProfileUnavailable =>
      'بيانات صاحب الطلب مش متاحة دلوقتي.';

  @override
  String get homeownerProfileNoDetails =>
      'لسه ما أضافش تفاصيل إضافية عن بيته أو احتياجاته.';

  @override
  String get homeownerProfilePrivacyHint => 'بيانات التواصل لا تظهر في الملف.';

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
  String get appName => 'شطّب';

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
  String get signupNeedsConfirmation =>
      'اتعمل الحساب. أكّد رقمك من الرسالة وبعدين سجّل دخولك.';

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
  String get roleSwitcherOwner => 'مالك';

  @override
  String get roleSwitcherContractor => 'مقاول';

  @override
  String get nextStepsTitle => 'ابدأ هنا';

  @override
  String get performanceTitle => 'أداؤك خلال آخر 30 يوم';

  @override
  String get personalizeTitle => 'تخصيص تجربتك';

  @override
  String get areasNotAdded => 'مناطق الشغل لسه مش مضافة';

  @override
  String get verifiedStatus => 'موثّق';

  @override
  String get unverifiedStatus => 'غير موثّق';

  @override
  String get profileCompletionTitle => 'اكتمال الملف';

  @override
  String profileCompletionPercent(int value) {
    return 'اكتمال الملف $value%';
  }

  @override
  String get profileCompleteMessage => 'ملفك جاهز يعرّف العملاء بشغلك.';

  @override
  String get profileIncompleteMessage => 'كمّل ملفك عشان تظهر لعملاء أكتر.';

  @override
  String get completeProfileAction => 'كمّل ملفك';

  @override
  String get editProfileImage => 'تعديل صورة الحساب';

  @override
  String get addFirstProject => 'أضف أول مشروع';

  @override
  String get addFirstProjectSubtitle => 'اعرض شغلك واجذب عملاء جدد';

  @override
  String get verifyAccount => 'وثّق حسابك';

  @override
  String get verifyAccountSubtitle => 'زوّد ثقة العملاء في حسابك';

  @override
  String get addWorkAreas => 'حدّد مناطق الشغل';

  @override
  String get addWorkAreasSubtitle => 'خلّي فرص الشغل المناسبة توصلك';

  @override
  String get verificationPending => 'قيد المراجعة';

  @override
  String get performanceEmptyTitle => 'أداؤك هيظهر هنا';

  @override
  String get performanceEmptyMessage =>
      'كمّل ملفك وأضف أول مشروع عشان تبدأ تتابع تفاعل العملاء.';

  @override
  String get proCardTitle => 'شطّب Pro';

  @override
  String get proCardSubtitle => 'خلّي ملفك يظهر لعملاء أكتر، وابرز شغلك بوضوح.';

  @override
  String get proLearnMore => 'اعرف أكتر';

  @override
  String get proManageSubtitle => 'إدارة اشتراكك ومزاياك المفعّلة.';

  @override
  String get settingsEntryTitle => 'الإعدادات والتفضيلات';

  @override
  String get settingsEntrySubtitle => 'تحكّم في إعدادات التطبيق';

  @override
  String get settingsAccountSection => 'الحساب';

  @override
  String get settingsPreferencesSection => 'التفضيلات';

  @override
  String get settingsSupportSection => 'الدعم والقانون';

  @override
  String get settingsAccountManagementSection => 'إدارة الحساب';

  @override
  String get appearanceTitle => 'المظهر';

  @override
  String get appearanceSubtitle => 'اختار الشكل المناسب ليك';

  @override
  String get appearanceDay => 'نهاري';

  @override
  String get appearanceDark => 'داكن';

  @override
  String get appearanceSystem => 'تلقائي';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsSubtitle => 'إدارة تفضيلات الإشعارات';

  @override
  String get notificationsRequests => 'طلبات الشغل';

  @override
  String get notificationsMessages => 'الرسائل والتحديثات';

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
  String get tabRequests => 'الطلبات';

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
  String get tabHome => 'الرئيسية';

  @override
  String get tabCommunity => 'المجتمع';

  @override
  String get sampleImagesLabel => 'صور تجريبية';

  @override
  String get workInspirationTitle => 'إلهام للشغل';

  @override
  String get imageUnavailable => 'الصورة غير متاحة';

  @override
  String get exploreTitle => 'أعمال';

  @override
  String get communityTitle => 'مجتمع شطّب';

  @override
  String get communitySubtitle => 'شارك تجربتك واستلهم من غيرك.';

  @override
  String get communityNotificationsLabel => 'الإشعارات';

  @override
  String get communityFiltersLabel => 'تصفية المنشورات';

  @override
  String get communityFilterAll => 'الكل';

  @override
  String get communityFilterBeforeAfter => 'قبل وبعد';

  @override
  String get communityFilterTips => 'نصائح';

  @override
  String get communityFilterExperiences => 'تجارب';

  @override
  String get communityFilterRequests => 'طلبات';

  @override
  String get communityCreatePrompt => 'إيه اللي شاغل بالك في التشطيب؟';

  @override
  String get communityCreatePost => 'إنشاء منشور';

  @override
  String get communityCreatePostTypeTitle => 'اختار نوع المنشور';

  @override
  String get communityPostKindStandard => 'مشاركة';

  @override
  String get communityPostKindStandardDescription =>
      'شارك تجربة أو تحديث من شغلك';

  @override
  String get communityPostKindBeforeAfter => 'قبل وبعد';

  @override
  String get communityPostKindBeforeAfterDescription =>
      'اعرض الفرق في شغلك بصورتين';

  @override
  String get communityPostKindQuestion => 'سؤال';

  @override
  String get communityPostKindQuestionDescription =>
      'اسأل المجتمع وخد آراء مفيدة';

  @override
  String get communityPostKindTips => 'نصائح';

  @override
  String get communityPostKindTipsDescription => 'شارك خطوة أو خامة فرقت معاك';

  @override
  String get communityPostKindExperiences => 'تجارب';

  @override
  String get communityPostKindExperiencesDescription =>
      'احكي اللي اتعلمته من رحلة التشطيب';

  @override
  String get communityCreatePostTypeSubtitle =>
      'اختار الطريقة اللي تحب تشارك بيها';

  @override
  String get communityWritePostTitle => 'اكتبها بطريقتك';

  @override
  String get communityPublishCta => 'انشر في مجتمع شطّب';

  @override
  String get communityBeforeAfterNeedsImages => 'أضف صورتين عشان تعرض قبل وبعد';

  @override
  String get communityPhotoAction => 'صورة';

  @override
  String get communityBeforeAfterAction => 'قبل وبعد';

  @override
  String get communityBeforeLabel => 'قبل';

  @override
  String get communityAfterLabel => 'بعد';

  @override
  String get communityQuestionAction => 'سؤال';

  @override
  String get communityPostMenuLabel => 'إجراءات المنشور';

  @override
  String get communityLikePost => 'إعجاب';

  @override
  String get communityUnlikePost => 'إلغاء الإعجاب';

  @override
  String get communityCommentPost => 'التعليقات';

  @override
  String get communitySharePost => 'مشاركة';

  @override
  String get communitySavePost => 'حفظ المنشور';

  @override
  String get communityUnsavePost => 'إزالة حفظ المنشور';

  @override
  String get communityNoPostsTitle => 'مفيش منشورات هنا لسه';

  @override
  String get communityNoPostsMessage =>
      'كن أول واحد يشارك تجربة أو نصيحة في مجتمع شطّب.';

  @override
  String get communityPostsTitle => 'منشوراته في المجتمع';

  @override
  String get communityPostsEmptyTitle => 'لسه ما شاركش منشورات';

  @override
  String get communityPostsEmptyMessage =>
      'تجاربه ونصايحه هتظهر هنا لما يشاركها في مجتمع شطّب.';

  @override
  String get communityPostsLoadError => 'مش قادرين نحمّل منشوراته دلوقتي';

  @override
  String get communityFeedErrorTitle => 'مش قادرين نجيب منشورات المجتمع دلوقتي';

  @override
  String get communityFeedErrorMessage =>
      'حصلت مشكلة مؤقتة في تحميل المنشورات. جرّب تاني بعد لحظات.';

  @override
  String get communityFeedGuestErrorTitle => 'سجّل دخولك عشان تفتح المجتمع';

  @override
  String get communityFeedGuestErrorMessage =>
      'تسجيل الدخول بيخليك تشوف المنشورات وتتفاعل مع أهل الخبرة وتحفظ اللي يعجبك.';

  @override
  String get communityClearFilter => 'عرض كل المنشورات';

  @override
  String get communityLoadingMore => 'جارٍ تحميل منشورات إضافية';

  @override
  String communityFilterAnnouncement(String filter) {
    return 'فلتر المنشورات: $filter';
  }

  @override
  String get communityAuthorHomeowner => 'صاحب شقة';

  @override
  String get communityAuthorProfessional => 'محترف موثّق';

  @override
  String get communityMemberFallback => 'عضو في المجتمع';

  @override
  String communityTimePublic(String time) {
    return 'منشور منذ $time';
  }

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
  String get commentReply => 'رد';

  @override
  String get commentLike => 'إعجاب بالتعليق';

  @override
  String get commentUnlike => 'إلغاء الإعجاب بالتعليق';

  @override
  String get editComment => 'تعديل التعليق';

  @override
  String get deleteComment => 'حذف التعليق';

  @override
  String get deleteCommentConfirm => 'متأكد إنك عايز تحذف التعليق؟';

  @override
  String get commentUpdated => 'تم تعديل التعليق';

  @override
  String get commentDeleted => 'تم حذف التعليق';

  @override
  String get replyingToComment => 'بترد على تعليق';

  @override
  String get commentEditedLabel => 'تم التعديل';

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
  String get sponsoredProfessionals => 'محترفين مميزين';

  @override
  String get paidPlacementLabel => 'إعلان مدفوع';

  @override
  String get specialProTitle => 'ظهور مميز';

  @override
  String get specialProSubtitle =>
      'خلّي ملفك يظهر في بداية النتائج المناسبة ليك';

  @override
  String get specialProValueLine =>
      'مساحة واضحة لشغلك، من غير ما نخلط الإعلان بالثقة';

  @override
  String get specialProBenefit =>
      'ظهور مميز لمدة ٧ أيام في النتائج المناسبة لمجالك ومناطق شغلك';

  @override
  String get specialProFairness =>
      'التقييم والتوثيق والأعمال المنجزة تفضل مستقلة عن الدفع';

  @override
  String get specialProPriceLine => '١٩٩ جنيه لمدة ٧ أيام';

  @override
  String get specialProCta => 'اطلب الظهور المميز';

  @override
  String get specialProActive => 'الظهور المميز شغال';

  @override
  String specialProExpiresOn(String date) {
    return 'الظهور المميز مستمر لحد $date';
  }

  @override
  String get specialProPending => 'طلب الظهور قيد المراجعة';

  @override
  String get specialProPendingBody =>
      'هنراجع التحويل ونفعّل الظهور بعد الموافقة.';

  @override
  String get specialProActivationNote =>
      'بعد رفع إيصال التحويل، فريقنا يراجع الطلب يدويًا.';

  @override
  String get specialProManage => 'إدارة الظهور المميز';

  @override
  String get specialProNoGuarantee =>
      'الظهور يساعد العملاء يلاقوك، لكنه لا يضمن طلبات أو تقييمات.';

  @override
  String get specialProScreenTitle => 'ظهورك المميز';

  @override
  String get paymentWeekly => 'أسبوعي';

  @override
  String get paySpecialPlacement => 'اطلب الظهور المميز';

  @override
  String get paySpecialPlacementSub =>
      '١٩٩ جنيه لمدة ٧ أيام بعد مراجعة التحويل';

  @override
  String get specialPlacementSubmittedTitle => 'طلب الظهور اتبعت';

  @override
  String get specialPlacementSubmittedBody =>
      'هنراجع التحويل ونفعّل الظهور بعد الموافقة.';

  @override
  String get specialPlacementDone => 'رجوع';

  @override
  String get specialPlacementAmountLabel => 'قيمة الظهور المميز';

  @override
  String get specialPlacementUploadLabel => 'ارفع إيصال التحويل';

  @override
  String get specialPlacementReferenceLabel => 'رقم العملية (اختياري)';

  @override
  String get specialPlacementSubmit => 'إرسال الطلب';

  @override
  String get specialPlacementTitle => 'إرسال طلب ظهور مميز';

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
  String get verifiedIdentityTitle => 'إيه معنى موثّق؟';

  @override
  String get verifiedIdentityBody =>
      'فريق شطّب راجع مستندات الهوية اللي قدمها المحترف. العلامة دي لا تعني ضمان نتيجة كل مشروع أو إن كل أعماله اتراجعت.';

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
  String get requestsPageTitle => 'الطلبات';

  @override
  String requestsUsage(String used, String limit) {
    return 'استخدمت $used من $limit عروضك المجانية خلال آخر ٣٠ يوم';
  }

  @override
  String get requestsProStatus => 'اشتراك برو مفعّل — عروضك وطلباتك متاحة';

  @override
  String get requestsPlanRefreshError => 'مش قادرين نحدّث حالة باقتك دلوقتي.';

  @override
  String get requestsPlanRetry => 'حدّث حالة الباقة';

  @override
  String get requestsOpenDetails => 'شوف تفاصيل الطلب';

  @override
  String get requestsQuoteType => 'مطلوب عرض سعر';

  @override
  String requestsPublishedOn(String date) {
    return 'نُشر في $date';
  }

  @override
  String get requestsLockedWithPro => 'متاح مع برو';

  @override
  String get requestsProContactAvailable => 'بيانات التواصل متاحة مع برو';

  @override
  String get requestsProtectedContact => 'بيانات التواصل محمية';

  @override
  String get requestsLocationVisible => 'بيانات الطلب ظاهرة ليك';

  @override
  String get requestsOtherTitle => 'طلبات تانية';

  @override
  String get requestsProHeadline => 'الطلب ده مناسب لشغلك؟';

  @override
  String get requestsProEmphasis => 'متسيبوش يروح.';

  @override
  String get requestsProDescription =>
      'برو بيفتحلك بيانات التواصل ويخليك تقدم عروض من غير حد.';

  @override
  String get requestsBenefitContact => 'بيانات التواصل';

  @override
  String get requestsBenefitUnlimited => 'عروض من غير حد';

  @override
  String get requestsBenefitRanking => 'ظهور أعلى في البحث';

  @override
  String requestsAnnualSaving(String amount) {
    return 'وفّرت $amount ج.م مع الخطة السنوية';
  }

  @override
  String get requestsTrialBilling => 'ابدأ شهر مجاني، وبعده أول خصم حسب الخطة';

  @override
  String get requestsPaidBilling => 'اشتراك مدفوع — التفعيل بعد تأكيد التحويل';

  @override
  String get requestsCtaTrial => 'افتح الطلب وابدأ شهر مجاني';

  @override
  String get requestsCtaPaid => 'افتح الطلب واشترك في برو';

  @override
  String get requestsPaymentNote => 'دفع آمن — التفعيل بعد مراجعة التحويل';

  @override
  String get requestsCheckoutFailed => 'حصلت مشكلة في فتح الدفع، حاول تاني.';

  @override
  String get requestsProUnlocked => 'برو مفعّل — تقدر تتابع الطلب وتقدّم عرضك';

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
  String get searchHint => 'بتدور على مين أو محتاج تعمل إيه؟';

  @override
  String get discoverHeroKicker => 'اختار الصح لبيتك';

  @override
  String get discoverHeroTitle => 'المحترفين';

  @override
  String get discoverHeroSubtitle => 'محترفين موثوقين وشغل واضح';

  @override
  String get professionalsDirectorySubtitle => 'اختار محترف مناسب لمشروعك';

  @override
  String get professionalsDirectoryHint => 'محترفين موثوقين قريبين منك';

  @override
  String professionalsAvailable(int count) {
    return '$count محترف متاح ليك';
  }

  @override
  String get trustedProfessionals => 'محترفين موثوقين';

  @override
  String get trustedProfessionalsHint => 'بناءً على تقييمات وشغل حقيقي';

  @override
  String get changeBrowseLocationShort => 'تغيير المكان';

  @override
  String get discoverPageTitle => 'المحترفين';

  @override
  String get discoverSearchHint => 'بتدور على مين؟';

  @override
  String get featuredProfessional => 'محترف مميز';

  @override
  String get customerReviews => 'تقييمات العملاء';

  @override
  String get completedProjectsShort => 'مشروع مكتمل';

  @override
  String get verifiedByShattab => 'موثوق من شطب';

  @override
  String get featuredContractors => 'محترفين مميزين';

  @override
  String get topRated => 'الأعلى تقييمًا';

  @override
  String get topRatedCollectionDescription =>
      'محترفين عندهم تقييمات حقيقية من العملاء';

  @override
  String get noRatedProfessionalsMessage =>
      'لسه مفيش محترفين عندهم تقييمات منشورة.';

  @override
  String get recentWorkTitle => 'شغل اتعمل بجد';

  @override
  String get allProfessionalsCollectionDescription =>
      'كل المحترفين المتاحين على شطّب';

  @override
  String get nearbyProfessionalsCollectionDescription =>
      'محترفين بيخدموا منطقتك';

  @override
  String get nearYou => 'قريبين منك';

  @override
  String nearYouIn(String city) {
    return 'قريبين منك في $city';
  }

  @override
  String get browseByCategory => 'تصفّح بالتخصص';

  @override
  String get homeServicesTitle => 'خدماتنا';

  @override
  String get more => 'المزيد';

  @override
  String get specialtyPaint => 'دهانات';

  @override
  String get specialtyFlooring => 'أرضيات';

  @override
  String get specialtyKitchen => 'مطابخ';

  @override
  String get specialtyBathroom => 'حمامات';

  @override
  String get specialtyElectrical => 'كهرباء';

  @override
  String get specialtyPlumbing => 'سباكة';

  @override
  String get specialtyCarpentry => 'نجارة';

  @override
  String get specialtyDesign => 'تصميم داخلي';

  @override
  String get specialtyFullRenovation => 'تشطيبات كاملة';

  @override
  String get shattabVerifiedProfessional => 'محترف موثّق من شطّب';

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
  String get briefLifecycleTitle => 'رحلة طلبك';

  @override
  String get briefLifecycleRequestPosted => 'تم نشر الطلب';

  @override
  String get briefLifecycleRequestPostedBody =>
      'تفاصيل طلبك اتسجلت وتقدر تتابع تحديثاته هنا.';

  @override
  String get briefLifecycleWaitingForQuotes => 'في انتظار العروض';

  @override
  String get briefLifecycleWaitingForQuotesBody =>
      'العروض هتظهر هنا أول ما يوصل عرض جديد.';

  @override
  String get briefLifecycleQuotesReceived => 'وصلت عروض';

  @override
  String get briefLifecycleQuotesReceivedBody =>
      'راجع العروض واختار المحترف الأنسب ليك.';

  @override
  String get briefLifecycleQuotesLoading => 'بنحدّث حالة العروض...';

  @override
  String get briefLifecycleQuotesError =>
      'مش قادرين نحدّث العروض دلوقتي. افتح قسم العروض وحاول تاني.';

  @override
  String get briefLifecycleWorkStarted => 'بدأ التنفيذ';

  @override
  String get briefLifecycleWorkStartedBody =>
      'اتقبل العرض، والخطوة الجاية متابعة التنفيذ.';

  @override
  String get briefLifecycleConfirmCompletion => 'أكد اكتمال الشغل';

  @override
  String get briefLifecycleConfirmCompletionBody =>
      'راجع النتيجة وأكد إن الشغل خلص.';

  @override
  String get briefLifecycleCompleted => 'اكتمل الشغل';

  @override
  String get briefLifecycleCompletedBody => 'تقدر تسيب تقييم موثّق عن تجربتك.';

  @override
  String get briefLifecycleCancelled => 'تم إلغاء الطلب';

  @override
  String get briefLifecycleCancelledBody =>
      'الطلب ده مش متاح لاستقبال عروض جديدة.';

  @override
  String get briefNextStepQuotes => 'راجع العروض واختار المحترف';

  @override
  String get briefNextStepFollowWork => 'تابع تنفيذ الشغل';

  @override
  String get briefNextStepConfirmWork => 'راجع وأكد اكتمال الشغل';

  @override
  String get briefNextStepReview => 'شارك تقييمك الموثّق';

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
  String get contactViaWhatsApp => 'التواصل من واتساب';

  @override
  String get whatsappShort => 'واتساب';

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
  String greetingPersonalized(String greeting, String name) {
    return '$greeting يا $name';
  }

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
  String get requestPriceQuote => 'اطلب عرض سعر';

  @override
  String get contactThroughShattab => 'تواصل من خلال شطّب';

  @override
  String get professionalWorkTitle => 'شغل اتعمل بجد';

  @override
  String get fromOurClients => 'من عملائنا';

  @override
  String get viewAllReviews => 'شوف كل التقييمات';

  @override
  String get shattabClient => 'عميل من شطّب';

  @override
  String get verifiedReviewFromCompletedJob => 'تقييم موثّق بعد شغل مكتمل';

  @override
  String get noPublicWorkYet => 'المحترف لسه مضافش أعمال للعرض.';

  @override
  String get contactPrivacyShareHint => 'ابدأ التواصل بأمان من خلال شطّب.';

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
  String get deleteAccountConfirmHint => 'اكتب \\\"حذف\\\" عشان تأكد';

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
      'المحترف استلم تفاصيل مشروعك وهيتواصل معاك قريب.\\\nتقدر تكلّمه دلوقتي على واتساب لو حابب تستعجل.';

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

  @override
  String get adjustOpportunityPreferences => 'اضبط تفضيلات فرصك';

  @override
  String get budgetAndTimingTitle => 'الميزانية وموعد البدء';

  @override
  String get budgetAndTimingUnavailable =>
      'صاحب الطلب لسه محددش الميزانية أو موعد البدء. تقدر تسأل عنهم داخل عرضك.';

  @override
  String get clearFilters => 'امسح الفلاتر';

  @override
  String get competitionUnavailableHint =>
      'مستوى المنافسة هيظهر لما يتوفر عدد العروض على الفرصة.';

  @override
  String get completeOpportunityPreferencesHint =>
      'حدّد تخصصك ومناطق شغلك عشان نرشحلك فرص أنسب.';

  @override
  String get completeProfileBeforeApplying => 'كمّل بياناتك الأول';

  @override
  String get distanceUnavailableHint =>
      'بنطابق على مناطق شغلك المحفوظة. المسافة بالكيلومتر هتتوفر بعد تفعيل الموقع.';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterAllLocations => 'كل المناطق';

  @override
  String get filterAnyTime => 'أي وقت';

  @override
  String get filterFresh => 'جديدة';

  @override
  String get filterLocation => 'الموقع';

  @override
  String get filterNearYou => 'مناطق شغلك';

  @override
  String get filterNotApplied => 'لم أقدّم عليها';

  @override
  String get filterHideApplied => 'إخفاء الفرص اللي قدّمت عليها';

  @override
  String get filterPublishedTime => 'وقت النشر';

  @override
  String get filtersApplyHint => 'هيتم تطبيق الفلاتر على الفرص المتاحة.';

  @override
  String get followQuoteAction => 'متابعة العرض';

  @override
  String get jobRadarTitle => 'رادار الشغل';

  @override
  String get opportunitySummaryTitle => 'ملخص فرص الشغل';

  @override
  String get opportunitySummaryHeading => 'ملخص فرصك';

  @override
  String get opportunityCountLabel => 'فرصة مناسبة';

  @override
  String get opportunityFreshCount => 'جديدة';

  @override
  String get opportunityAreaCount => 'في مناطق شغلك';

  @override
  String get opportunityWeekCount => 'هذا الأسبوع';

  @override
  String get searchForMatchingOpportunities => 'دور على فرص مناسبة لشغلك';

  @override
  String get opportunitySortTitle => 'ترتيب الفرص';

  @override
  String get opportunitySortRecommended => 'الأكثر مناسبة';

  @override
  String get opportunitySortNewest => 'الأحدث';

  @override
  String opportunitySortLabel(String sort) {
    return 'ترتيب الفرص حسب $sort';
  }

  @override
  String opportunityFilterAction(int count) {
    return 'تصفية الفرص، $count فلاتر مفعّلة';
  }

  @override
  String matchingOpportunitiesHeader(int count) {
    return 'عندك $count فرص مناسبة لشغلك';
  }

  @override
  String opportunityCompactSummary(int count, int fresh, int area) {
    return '$count مناسبة · $fresh جديدة النهارده · $area في مناطق شغلك';
  }

  @override
  String get projectPhotoLabel => 'صورة مشروع';

  @override
  String get projectPhotoLoading => 'جاري تحميل صورة المشروع';

  @override
  String get opportunityMediaUnavailable => 'صورة المشروع غير متاحة';

  @override
  String get loadMoreProgress => 'جاري تحميل فرص تانية';

  @override
  String get loadMoreError => 'حصلت مشكلة في تحميل فرص تانية';

  @override
  String latestOpportunityTime(String time) {
    return 'آخر فرصة مناسبة نزلت $time';
  }

  @override
  String get makeOpportunitiesMoreAccurate => 'خلّي فرصك أدق';

  @override
  String get matchDataInsufficient =>
      'كمّل تخصصاتك ومناطق شغلك عشان نوضح سبب الترشيح بدقة أكبر.';

  @override
  String get matchReasonFresh => 'فرصة جديدة ولسه نازلة';

  @override
  String get matchReasonPhotos => 'فيها صور واضحة للمشروع';

  @override
  String get matchReasonPortfolio => 'شبه أعمال موجودة في ملفك';

  @override
  String get matchReasonServiceArea => 'المنطقة ضمن نطاق شغلك';

  @override
  String get matchReasonSpecialty => 'تخصصك يطابق المطلوب';

  @override
  String get moreMatchingOpportunities => 'فرص تانية مناسبة';

  @override
  String get newOpportunitiesForYou => 'فرص جديدة مناسبة ليك';

  @override
  String get noOpportunityMatches => 'ملقيناش فرص بالفلاتر دي';

  @override
  String get noOpportunityMatchesHint =>
      'جرّب توسّع نطاق البحث أو تمسح بعض الفلاتر، وهنعرضلك الفرص الجديدة أول ما تنزل.';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get opportunityAcceptingOffers => 'تستقبل عروض';

  @override
  String get opportunityClosed => 'الفرصة اتقفلت';

  @override
  String get opportunityDetailsTitle => 'تفاصيل الفرصة';

  @override
  String get opportunityFiltersTitle => 'تصفية الفرص';

  @override
  String get opportunityOpen => 'الفرصة مفتوحة';

  @override
  String get opportunityQuality => 'جودة الفرصة';

  @override
  String get opportunityRemovedFromSaved => 'تمت إزالة الفرصة من المحفوظات';

  @override
  String get opportunitySaved => 'تم حفظ الفرصة';

  @override
  String get opportunityTimeline => 'خط زمني للفرصة';

  @override
  String get opportunityViewed => 'شفتها قبل كده';

  @override
  String get ownerNoteTitle => 'ملاحظة صاحب الطلب';

  @override
  String get ownerPrivacyHint =>
      'بيانات التواصل بتفضل خاصة لحد ما يبدأ التواصل من خلال العرض.';

  @override
  String get projectDetailsTitle => 'تفاصيل المشروع';

  @override
  String get quoteAlreadySent => 'قدّمت عرضك';

  @override
  String get radarFresh => 'جديدة اليوم';

  @override
  String get radarInYourAreas => 'في مناطق شغلك';

  @override
  String get radarMatchesThisWeek => 'مناسبة هذا الأسبوع';

  @override
  String get recommendedForYou => 'موصى بيها ليك';

  @override
  String get relevantOpportunity => 'فرصة مناسبة';

  @override
  String get removeOpportunityFromSaved => 'إزالة الفرصة من المحفوظات';

  @override
  String get resetFilters => 'إعادة تعيين';

  @override
  String get clearAllFilters => 'مسح كل الفلاتر';

  @override
  String get saveOpportunity => 'حفظ الفرصة';

  @override
  String searchPreferencesCompletion(int percent) {
    return 'اكتمال تفضيلات البحث $percent%';
  }

  @override
  String showOpportunityCount(int count) {
    return 'عرض $count فرصة';
  }

  @override
  String get strongMatch => 'توافق قوي';

  @override
  String get submitYourQuote => 'قدّم عرضك';

  @override
  String get timelineAcceptOffers => 'استقبال العروض';

  @override
  String get timelineChooseContractor => 'اختيار المقاول';

  @override
  String get timelineStartWork => 'بدء التنفيذ';

  @override
  String get viewOpportunityDetails => 'شوف التفاصيل';

  @override
  String get whyOpportunityMatches => 'ليه الفرصة دي مناسبة ليك؟';

  @override
  String get youHaveNewOpportunities => 'عندك';

  @override
  String get homeownerAccountRole => 'صاحب شقة';

  @override
  String get homeownerAreaFallback => 'موقعك المفضل';

  @override
  String get homeownerQuickActions => 'إجراءات سريعة';

  @override
  String get homeownerSettingsPreview => 'إعداداتك';

  @override
  String get homeownerAccountExperienceSection => 'تجربة حسابك';

  @override
  String get homeownerEditProfileAction => 'تعديل الملف الشخصي';

  @override
  String get homeownerDiscoverSubtitle => 'ابحث عن الأفضل';

  @override
  String get homeownerRequestsSubtitle => 'تابع طلباتك';

  @override
  String get homeownerSavedSubtitle => 'المحترفين المحفوظين';

  @override
  String get homeownerAppearanceRow => 'الوضع النهاري';

  @override
  String get homeownerMotionRow => 'الحركة';

  @override
  String get homeownerLanguageRow => 'اللغة';

  @override
  String get homeownerSettingsRow => 'الإعدادات والتفضيلات';

  @override
  String get homeownerSettingsSubtitle => 'تحكّم في إعدادات التطبيق';

  @override
  String get homeownerLogoutSubtitle => 'تقدر ترجع في أي وقت';

  @override
  String get homeownerSettingsExperienceSection => 'تجربة التطبيق';

  @override
  String get homeownerAppearanceAndMotionTitle => 'المظهر والحركة';

  @override
  String get homeownerAppearanceAndMotionSubtitle =>
      'اختار الشكل والحركة المناسبين ليك';

  @override
  String get homeownerLegalSection => 'الخصوصية والقانون';

  @override
  String get homeownerPrivacySubtitle => 'اعرف إزاي بنحمي بياناتك';

  @override
  String get homeownerTermsSubtitle => 'راجع شروط استخدام شطّب';

  @override
  String get homeownerAccountSection => 'الحساب';

  @override
  String get homeownerDeleteSubtitle => 'حذف نهائي لكل بيانات الحساب';

  @override
  String get homeownerMotionTitle => 'الحركة';

  @override
  String get homeownerMotionSubtitle => 'تحكّم في حركة واجهات التطبيق';

  @override
  String get homeownerMotionAccessibility =>
      'لو الحركة بتتعبك، اختار مخفّضة أو بدون حركة لواجهة أهدى.';

  @override
  String get homeownerSaveSettings => 'حفظ الإعدادات';

  @override
  String get homeownerLanguageChoose => 'اختار لغة التطبيق';

  @override
  String get homeownerLanguageArabicHint => 'العربية';

  @override
  String get homeownerLanguageEnglishHint => 'English';

  @override
  String get homeownerLanguagePreview => 'معاينة اتجاه النص';

  @override
  String get homeownerLanguageLtr => 'LTR';

  @override
  String get homeownerLanguageRtl => 'RTL';

  @override
  String get homeownerSaveLanguage => 'حفظ اللغة';

  @override
  String get homeownerPrivacyIntro =>
      'بنحافظ على بياناتك ونستخدمها عشان نقدملك تجربة آمنة وأنسب ترشيحات للتشطيب.';

  @override
  String get homeownerTermsIntro =>
      'باستخدام شطّب، أنت بتوافق على القواعد اللي بتنظّم استخدام المنصة والتواصل مع المحترفين.';

  @override
  String get homeownerPrivacySection1Title => 'البيانات اللي بنجمعها';

  @override
  String get homeownerPrivacySection1Body =>
      'بنستخدم بيانات الحساب الأساسية، ومعلومات السكن واهتمامات التشطيب اللي تختار تشاركها عشان نشغّل الخدمة.';

  @override
  String get homeownerPrivacySection2Title => 'إزاي بنستخدم بياناتك';

  @override
  String get homeownerPrivacySection2Body =>
      'بنستخدم بياناتك لعرض محترفين مناسبين، وتنظيم طلباتك، وتحسين أداء التطبيق وتقديم الدعم.';

  @override
  String get homeownerPrivacySection3Title => 'حماية بياناتك';

  @override
  String get homeownerPrivacySection3Body =>
      'بنطبّق ضوابط وصول وحماية مناسبة، ومش بنعرض بيانات التواصل في الملفات العامة بدون سبب واضح.';

  @override
  String get homeownerPrivacySection4Title => 'اختياراتك';

  @override
  String get homeownerPrivacySection4Body =>
      'تقدر تعدّل بيانات ملفك، وتتحكّم في الإشعارات، وتطلب حذف حسابك من إعدادات الحساب.';

  @override
  String get homeownerPrivacySection5Title => 'التواصل معنا';

  @override
  String get homeownerPrivacySection5Body =>
      'لو عندك سؤال عن بياناتك أو الخصوصية، تواصل مع فريق الدعم من الزر الموجود أسفل الصفحة.';

  @override
  String get homeownerTermsSection1Title => 'استخدام شطّب';

  @override
  String get homeownerTermsSection1Body =>
      'استخدم شطّب بطريقة قانونية ومحترمة، وقدّم معلومات حقيقية تساعد المحترفين على فهم طلبك.';

  @override
  String get homeownerTermsSection2Title => 'الطلبات والتواصل';

  @override
  String get homeownerTermsSection2Body =>
      'المنصة بتنظّم الوصول للمحترفين، لكن الاتفاق النهائي وتفاصيل التنفيذ مسؤولية الأطراف المعنية.';

  @override
  String get homeownerTermsSection3Title => 'المحتوى والصور';

  @override
  String get homeownerTermsSection3Body =>
      'اتأكد إن عندك الحق في الصور والمعلومات اللي ترفعها، وماتضيفش محتوى مخالف أو يعرّض حد للضرر.';

  @override
  String get homeownerTermsSection4Title => 'المحترفون المستقلون';

  @override
  String get homeownerTermsSection4Body =>
      'المحترفون بيقدّموا خدماتهم بشكل مستقل، فراجع ملفهم وتقييماتهم واتفق على التفاصيل قبل بدء العمل.';

  @override
  String get homeownerTermsSection5Title => 'تحديث الشروط';

  @override
  String get homeownerTermsSection5Body =>
      'ممكن نحدّث الشروط لما تتغير الخدمة. هنوضح أي تغييرات مهمة داخل التطبيق.';

  @override
  String get homeownerContactSupport => 'تواصل مع الدعم';

  @override
  String get homeownerLogoutTitle => 'تسجيل الخروج؟';

  @override
  String get homeownerLogoutBody =>
      'تقدر تسجّل دخولك تاني في أي وقت من غير ما تفقد طلباتك أو المحترفين المحفوظين.';

  @override
  String get homeownerStaySignedIn => 'البقاء في الحساب';

  @override
  String get homeownerOrdersAll => 'الكل';

  @override
  String get homeownerOrdersNew => 'جديدة';

  @override
  String get homeownerOrdersActive => 'جارية';

  @override
  String get homeownerOrdersCompleted => 'مكتملة';

  @override
  String get homeownerOrdersEmptyTitle => 'لسه مفيش طلبات';

  @override
  String get homeownerOrdersEmptyMessage =>
      'أول ما تبعت طلب لمحترف، هتقدر تتابع تفاصيله من هنا.';

  @override
  String get homeownerOrdersDiscoverAction => 'اكتشف المحترفين';

  @override
  String get homeownerOrdersBackToAccount => 'الرجوع لحسابي';

  @override
  String get homeownerSavedEmptyTitle => 'المحترفين المحفوظين فاضية';

  @override
  String get homeownerSavedEmptyMessage =>
      'احفظ المحترفين اللي عجبوك عشان ترجع لهم بسهولة.';

  @override
  String get homeownerSavedDiscoverAction => 'اكتشف المحترفين';

  @override
  String get homeownerSavedHint =>
      'اضغط علامة الحفظ على أي محترف عشان يظهر هنا.';

  @override
  String get changeLocation => 'غيّر مكان التصفح';

  @override
  String get changeLocationDescription =>
      'اختار محافظة عشان تشوف المحترفين فيها';

  @override
  String get useProfileLocation => 'استخدم موقع الملف';

  @override
  String get notificationInboxTitle => 'الإشعارات';

  @override
  String get notificationMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationEmptyTitle => 'مفيش إشعارات جديدة';

  @override
  String get notificationEmptyBody =>
      'هنبلغك هنا بأي تحديثات تخص طلباتك وشغلك.';

  @override
  String get notificationNewQuoteTitle => 'عرض سعر جديد';

  @override
  String get notificationNewQuoteBody => 'وصلك عرض جديد على طلبك.';

  @override
  String get notificationQuoteDecisionTitle => 'تحديث على عرضك';

  @override
  String get notificationQuoteAcceptedBody => 'صاحب الطلب وافق على عرضك.';

  @override
  String get notificationQuoteDeclinedBody =>
      'صاحب الطلب اختار عرضًا آخر للطلب.';

  @override
  String get notificationCompletionTitle => 'تحديث على الشغل';

  @override
  String get notificationCompletionRequestedBody =>
      'المحترف بيقول إن الشغل خلص. راجع تفاصيل الطلب.';

  @override
  String get notificationJobCompletedBody => 'تم تأكيد اكتمال المشروع.';

  @override
  String get notificationNewReviewTitle => 'تقييم جديد';

  @override
  String get notificationNewReviewBody =>
      'العميل أضاف تقييمًا جديدًا على شغلك.';

  @override
  String get notificationVerificationTitle => 'تحديث التوثيق';

  @override
  String get notificationVerificationApprovedBody => 'حسابك اتوثق بنجاح.';

  @override
  String get notificationVerificationRejectedBody =>
      'راجع ملاحظات التوثيق وقدّم الطلب مرة تانية.';

  @override
  String get notificationPaymentTitle => 'تحديث الاشتراك';

  @override
  String get notificationPaymentApprovedBody => 'تم تفعيل اشتراكك.';

  @override
  String get notificationPaymentRejectedBody => 'طلب الدفع محتاج مراجعة.';

  @override
  String get notificationCommunityTitle => 'تفاعل جديد';

  @override
  String get notificationPostLikedBody => 'حد عمل إعجاب على منشورك.';

  @override
  String get notificationPostCommentedBody => 'حد كتب تعليق على منشورك.';

  @override
  String get notificationCommentRepliedBody => 'حد رد على تعليقك.';

  @override
  String get notificationCommentLikedBody => 'حد عمل إعجاب على تعليقك.';

  @override
  String get homeHeroTitleLead => 'بيتك';

  @override
  String get homeHeroTitleRest => 'يستاهل حد يتقنه';

  @override
  String get homeHeroSubtitle => 'محترفين موثوقين، قريبين من بيتك';

  @override
  String get homeSearchHint => 'ابحث عن خدمة أو محترف...';

  @override
  String get homeQuickStartTitle => 'ابدأ طلبك بسرعة';

  @override
  String get homeQuickNearbyTitle => 'محترفون قريبون منك';

  @override
  String get homeQuickNearbySubtitle => 'تواصل أسهل وأسرع';

  @override
  String get homeQuickRequestsTitle => 'تابع طلباتك';

  @override
  String get homeQuickRequestsSubtitle => 'كلها في مكان واحد';

  @override
  String get homeQuickQuoteTitle => 'اطلب عرض سعر';

  @override
  String get homeQuickQuoteSubtitle => 'مجانًا وسريعة';

  @override
  String get homeActiveRequestTitle => 'طلبك الحالي';

  @override
  String get homeActiveRequestFallback => 'طلبك جاهز للمتابعة مع المحترفين.';

  @override
  String get homeViewProfile => 'عرض الملف';

  @override
  String get homeContactWhatsApp => 'تواصل واتساب';

  @override
  String get homeStartTitle => 'ابدأ من هنا';

  @override
  String get homeStartDiscoverTitle => 'اكتشف المحترفين';

  @override
  String get homeStartDiscoverSubtitle => 'اعرف مين يناسب بيتك';

  @override
  String get homeStartQuoteTitle => 'اطلب عرض سعر';

  @override
  String get homeStartQuoteSubtitle => 'احكي لنا عن اللي محتاجه';

  @override
  String get homeStartWorkTitle => 'شوف شغل اتعمل';

  @override
  String get homeStartWorkSubtitle => 'مشاريع حقيقية قبل وبعد';

  @override
  String get homeStartCommunityTitle => 'اسأل أهل الخبرة';

  @override
  String get homeStartCommunitySubtitle => 'تجارب ونصايح من مجتمعنا';

  @override
  String get homeProcessTitle => 'من الفكرة للتنفيذ';

  @override
  String get homeProcessStepOne => 'احكي عن احتياجك';

  @override
  String get homeProcessStepOneBody => 'قول لنا عايز تشطب إيه';

  @override
  String get homeProcessStepTwo => 'اختار المناسب ليك';

  @override
  String get homeProcessStepTwoBody => 'شوف شغل حقيقي وتواصل';

  @override
  String get homeProcessStepThree => 'ابدأ بثقة';

  @override
  String get homeProcessStepThreeBody => 'تابع طلبك خطوة بخطوة';

  @override
  String get homeCommunityInviteTitle => 'اسأل أهل الخبرة';

  @override
  String get homeCommunityInviteBody =>
      'شوف تجارب حقيقية من ناس بدأت من نفس المكان.';

  @override
  String get homeClosingCtaTitle => 'جاهز تبدأ؟';

  @override
  String get homeClosingCtaBody => 'احكي لنا عن بيتك وخلي الاختيار أسهل.';

  @override
  String get homeClosingCtaAction => 'ابدأ طلبك';

  @override
  String get profileVerifiedStat => 'موثوق ومعتمد';

  @override
  String get profileAboutCompany => 'نبذة عن الشركة';

  @override
  String get profileShowMore => 'عرض المزيد';

  @override
  String get profileShowLess => 'عرض أقل';

  @override
  String get profileServicesTitle => 'خدماتنا';

  @override
  String get profileHighlightsTitle => 'أبرز الأعمال';

  @override
  String get profileProjectsTitle => 'مشاريع منفذة';

  @override
  String get profileTabAbout => 'نبذة';

  @override
  String get profileTabWork => 'أعمالنا';

  @override
  String get profileTabReviews => 'التقييمات';

  @override
  String get profileClosingTitle => 'جاهز نبدأ مشروعك؟';

  @override
  String get profileClosingBody => 'تواصل معه الآن واحصل على عرض سعر مجاني.';

  @override
  String get profileClosingAction => 'اطلب عرض سعر الآن';

  @override
  String get profileDirectCall => 'اتصال مباشر';

  @override
  String get profileFilterAll => 'الكل';

  @override
  String get homeLiveActivityTitle => 'آخر تحديثات طلبك';

  @override
  String get homeLiveLatestActivity => 'آخر نشاط';

  @override
  String get homeLiveEmptyTitle => 'لسه مابدأتش';

  @override
  String get homeLiveEmptyMessage =>
      'ابدأ بطلب سريع، وخلي المحترفين يشوفوا احتياجك.';

  @override
  String get homeLiveStartAction => 'ابدأ طلبك';

  @override
  String get homeLiveOpenRequests => 'شوف طلباتك';

  @override
  String get homeLiveOpenNotifications => 'شوف الإشعارات';

  @override
  String get homeLiveErrorTitle => 'مش قادرين نجيب آخر تحديث';

  @override
  String get homeLiveAwaitingOffers => 'مستنيين العروض';

  @override
  String get homeLiveWorkInProgress => 'الشغل شغال';

  @override
  String get homeLiveReviewCompletion => 'راجع الانتهاء';

  @override
  String get homeLiveCompleted => 'المشروع اكتمل';

  @override
  String get homeLiveRequestPosted => 'اتنشر';

  @override
  String homeLiveUnreadCount(int count) {
    return '$count إشعار';
  }

  @override
  String get quoteSentTitle => 'عرضك اتبعت';

  @override
  String get quoteSentMessage =>
      'صاحب الطلب استلم تفاصيل عرضك. هتوصلك أي تحديثات هنا.';

  @override
  String get draftRestored => 'رجعنا لك المسودة اللي حفظتها';

  @override
  String get draftSavedAutomatically => 'اتحفظ تلقائياً على الجهاز ده';

  @override
  String get trustEvidenceTitle => 'علامات واضحة تساعدك تختار';

  @override
  String get trustEvidenceBody =>
      'راجع الأدلة اللي نقدر نثبتها قبل ما تبدأ كلامك مع المحترف.';

  @override
  String get trustNewProfessional => 'محترف جديد على شطب';

  @override
  String get trustSafetyBody =>
      'لو حاجة مش واضحة، راجع التفاصيل أو كلّم شطب قبل ما تاخد قرار.';

  @override
  String get profileSafetyTitle => 'اختيارك على وضوح';

  @override
  String get profileSafetyBody =>
      'تقدر تبلغ عن الحساب أو تحظره، وفريق شطب موجود لو احتجت مساعدة.';

  @override
  String get reportProfileAction => 'إبلاغ عن الحساب';

  @override
  String get blockProfileAction => 'حظر الحساب';

  @override
  String get homeFeaturedEmptyTitle => 'هنرشح لك محترف مناسب قريب';

  @override
  String get homeFeaturedEmptyMessage =>
      'لما تتوفر بيانات أكتر، هنظهر لك اختيار مبني على التقييمات والشغل المنشور.';

  @override
  String get homeProjectsLoadErrorTitle => 'مش قادرين نعرض الشغل دلوقتي';

  @override
  String get homeProjectsLoadErrorMessage =>
      'حاول تاني عشان تشوف أعمال حقيقية من محترفين شطب.';

  @override
  String get homeProjectsEmptyTitle => 'الشغل الحقيقي هيظهر هنا';

  @override
  String get homeProjectsEmptyMessage =>
      'استكشف أعمال المحترفين وشوف تفاصيل التنفيذ قبل ما تختار.';
}
