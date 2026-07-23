/// Centralized strings for M1.
/// Supports Arabic (default) and English via [S.setLanguage].
class S {
  S._();
  static bool _isEnglish = false;

  static void setLanguage(bool english) => _isEnglish = english;

  static String _t(String ar, [String? en]) =>
      _isEnglish && en != null ? en : ar;

  // App
  static String get appName => _t('شطب', 'Shattab');
  static String get appNameLatin => 'Shattab';
  static String get appTagline =>
      _t('مقاولين وعملاء، في مكان واحد', 'Contractors & clients, in one place');

  // Auth
  static String get enterPhone => _t('ادخل رقم تليفونك', 'Enter your phone number');
  static String get phoneHint => '+20 1XX XXX XXXX';
  static String get phoneLocalHint => '1XX XXX XXXX';
  static String get continueLabel => _t('كمّل', 'Continue');
  static String get otpTitle => _t('ادخل كود التحقق', 'Enter verification code');

  // Sign-in sheet (guest browse -> gated action)
  static String get signInSheetTitle => _t('سجّل دخولك للمتابعة', 'Sign in to continue');
  static String get signInToSave =>
      _t('سجّل دخولك لحفظ هذا المقاول', 'Sign in to save this contractor');
  static String get signInToSendRequest =>
      _t('سجّل دخولك لإرسال طلبك', 'Sign in to send your request');
  static String get signInToPost =>
      _t('سجّل دخولك لنشر طلبك', 'Sign in to post your request');
  static String get signInToInteract =>
      _t('سجّل دخولك للتفاعل مع المنشورات', 'Sign in to interact with posts');
  static String get couldNotOpenApp =>
      _t('تعذّر فتح التطبيق. تأكد إنه متثبّت.',
          "Couldn't open the app. Make sure it's installed.");
  static String get quoteSentShort => _t('عرضك مُرسل', 'Quote sent');
  static String get myQuotesTitle => _t('عروضي', 'My quotes');
  static String get myQuotesEmptyTitle =>
      _t('لسّه مفيش عروض', 'No quotes yet');
  static String get myQuotesEmptyMessage => _t(
      'العروض اللي هتبعتها للطلبات هتظهر هنا',
      'Quotes you send on jobs will show up here');
  static String get signInToSeeSaved => _t(
      'سجّل دخولك لرؤية المقاولين المحفوظين', 'Sign in to see your saved contractors');
  static String get signInToSeeRequests =>
      _t('سجّل دخولك لرؤية طلباتك', 'Sign in to see your requests');
  static String get signInOrCreateAccount =>
      _t('سجّل دخولك أو أنشئ حساب', 'Sign in or create an account');
  static String get whatsYourName => _t('إيه اسمك؟', "What's your name?");
  static String get contractorSignInLink =>
      _t('مقاول؟ سجّل دخولك من هنا', 'Contractor? Sign in here');

  // Login redesign (M4)
  static String get heroLine1 => _t('شطب بيتك', 'Finish your home');
  static String get heroLine2 => _t('من غير وجع دماغ', 'without the headache');
  static String get heroSubtitle => _t(
      'اطلب الخدمة المناسبة واستقبل عروضًا من مقاولين موثقين.',
      'Request the right service and receive quotes from verified contractors.');
  static String get phoneLabel => _t('رقم التليفون', 'Phone number');
  static String get verifyMessage =>
      _t('هنبعثلك كود تأكيد على رقم التليفون', 'We\'ll send a verification code to your phone');
  static String get dataSecure =>
      _t('بياناتك آمنة ومشفرة', 'Your data is secure and encrypted');
  static String get loginPrompt => _t('لديك حساب بالفعل؟', 'Already have an account?');
  static String get loginAction => _t('تسجيل الدخول', 'Log in');
  // Phone + password auth
  static String get passwordLabel => _t('كلمة السر', 'Password');
  static String get passwordHint => _t('٦ حروف على الأقل', 'At least 6 characters');
  static String get confirmPasswordHint =>
      _t('أكّد كلمة السر', 'Confirm password');
  static String get passwordTooShort =>
      _t('كلمة السر لازم ٦ حروف على الأقل', 'Password must be at least 6 characters');
  static String get signInAction => _t('دخول', 'Sign in');
  static String get createAccountAction => _t('إنشاء حساب', 'Create account');
  static String get noAccountPrompt => _t('معندكش حساب؟', 'No account?');
  static String get haveAccountPrompt => _t('عندك حساب؟', 'Have an account?');
  static String get forgotPassword => _t('نسيت كلمة السر؟', 'Forgot password?');
  static String get continueWithGoogle =>
      _t('المتابعة عبر Google', 'Continue with Google');
  static String get orDivider => _t('أو', 'or');
  // Homeowner profile dashboard (greetingMorning/greetingEvening already exist)
  static String get quickActionsTitle => _t('إجراءات سريعة', 'Quick actions');
  static String get accountSettingsTitle => _t('الإعدادات', 'Settings');
  static String get resetViaSms =>
      _t('هنبعتلك كود على رقمك عشان تدخل من جديد', 'We\'ll text you a code to sign back in');
  static String get taglineNew => _t('من أول فكرة لآخر لمسة', 'From first idea to final touch');
  static String get otpHint => _t('كود من ٦ أرقام', 'A 6-digit code');
  static String get resendCode => _t('ابعت الكود تاني', 'Resend code');
  static String get resendInSeconds => _t('تقدر تعيد بعد %s ث', 'Resend in %s s');
  static String get invalidPhone =>
      _t('رقم تليفون غير صحيح', 'Invalid phone number');
  static String get invalidOtp => _t('الكود اللي دخلته غير صحيح', 'The code you entered is incorrect');
  static String get otpExpired =>
      _t('الكود انتهت صلاحيته. اطلب واحد جديد.', 'Code expired. Request a new one.');
  static String get signOut => _t('تسجيل خروج', 'Sign out');
  static String get unknownErrorRetry =>
      _t('في حاجة غلط، جرّب تاني.', 'Something went wrong, please try again.');

  // Role select
  static String get chooseRoleTitle => _t('انت مين؟', 'Who are you?');
  static String get chooseRoleSubtitle =>
      _t('اختار اللي يناسبك عشان نفصّل التجربة على مزاجك',
          'Choose what fits you so we can tailor the experience');
  static String get roleHomeowner => _t('صاحب شقة', 'Homeowner');
  static String get roleHomeownerSub =>
      _t('بدور على مقاول يجدّد عندي', 'Looking for a contractor to renovate');
  static String get roleContractor => _t('مقاول', 'Contractor');
  static String get roleContractorSub =>
      _t('بدور على شغل وعملاء جداد', 'Looking for jobs and new clients');

  // Homeowner onboarding
  static String get apartmentTypeTitle =>
      _t('شقتك نوعها إيه؟', 'What type is your apartment?');
  static String get apartmentStudio => _t('استوديو', 'Studio');
  static String get apartmentOneBedroom => _t('غرفة نوم', '1 Bedroom');
  static String get apartmentTwoBedroom => _t('غرفتين نوم', '2 Bedrooms');
  static String get apartmentThreeBedroomPlus => _t('٣ غرف أو أكتر', '3+ Bedrooms');
  static String get apartmentDuplex => _t('دوبلكس', 'Duplex');
  static String get apartmentVilla => _t('فيلا', 'Villa');
  static String get apartmentPenthouse => _t('بنتهاوس', 'Penthouse');

  static String get locationTitle => _t('مكانك فين؟', 'Where are you?');
  static String get cityLabel => _t('المحافظة', 'City');
  static String get districtLabel => _t('الحي / المنطقة', 'District / Area');
  static String get cityCairo => _t('القاهرة', 'Cairo');
  static String get cityGiza => _t('الجيزة', 'Giza');
  static String get cityAlexandria => _t('الإسكندرية', 'Alexandria');
  static String get cityNewCairo => _t('القاهرة الجديدة', 'New Cairo');
  static String get city6October => _t('٦ أكتوبر', '6 October');
  static String get cityNorthCoast => _t('الساحل الشمالي', 'North Coast');

  static String get interestsTitle => _t('محتاج تجدّد إيه؟', 'What do you need to renovate?');
  static String get interestsSubtitle =>
      _t('اختار واحد أو أكتر', 'Choose one or more');
  static String get interestPaint => _t('دهانات', 'Paint');
  static String get interestFlooring => _t('أرضيات', 'Flooring');
  static String get interestKitchen => _t('مطبخ', 'Kitchen');
  static String get interestBathroom => _t('حمام', 'Bathroom');
  static String get interestElectrical => _t('كهرباء', 'Electrical');
  static String get interestPlumbing => _t('سباكة', 'Plumbing');
  static String get interestFullReno => _t('تشطيب كامل', 'Full renovation');

  // Contractor onboarding
  static String get businessNameTitle =>
      _t('اسم شركتك أو نشاطك', 'Your company or business name');
  static String get businessNameHint =>
      _t('مثال: مقاولات الفنّان', 'Example: Al-Fannan Contracting');
  static String get displayNameLabel => _t('اسم المسؤول', 'Responsible name');
  static String get specialtiesTitle => _t('تخصصاتك إيه؟', 'What are your specialties?');
  static String get specialtiesSubtitle =>
      _t('اختار كل اللي بتعمله', 'Select everything you do');
  static String get serviceAreasTitle =>
      _t('بتشتغل فين؟', 'Where do you work?');
  static String get serviceAreasSubtitle =>
      _t('اختار المحافظات اللي بتغطّيها', 'Select the governorates you cover');
  static String get logoUploadTitle =>
      _t('صورة أو لوجو لنشاطك', 'Photo or logo for your business');
  static String get logoUploadHint =>
      _t('اختياري — تقدر تتخطّاه دلوقتي', 'Optional — you can skip it for now');
  static String get chooseImage => _t('اختار صورة', 'Choose image');
  static String get experienceTitle =>
      _t('سنين خبرتك ونبذة عنك', 'Your experience and bio');
  static String get yearsExperience => _t('سنين الخبرة', 'Years of experience');
  static String get bioLabel => _t('نبذة قصيرة', 'Short bio');
  static String get bioHint =>
      _t('احكي عن شغلك في سطرين أو ٣', 'Tell us about your work in 2-3 lines');

  // Common
  static String get save => _t('احفظ', 'Save');
  static String get next => _t('التالي', 'Next');
  static String get skip => _t('تخطّى', 'Skip');
  static String get back => _t('رجوع', 'Back');
  static String get done => _t('تمام', 'Done');
  static String get comingSoon => _t('قريب…', 'Coming soon…');
  static String get comingSoonM2 =>
      _t('الميزة دي في الإصدار الجاي', 'This feature is coming in the next release');
  static String get comingSoonM3 =>
      _t('الميزة دي قيد التحضير', 'This feature is being prepared');
  static String get optional => _t('(اختياري)', '(optional)');

  // Shell tabs
  static String get tabDiscover => _t('اكتشف', 'Discover');
  static String get tabRequests => _t('طلباتي', 'My Requests');
  static String get tabSaved => _t('المحفوظات', 'Saved');
  static String get tabProfile => _t('حسابي', 'Profile');

  static String get tabDashboard => _t('لوحة التحكم', 'Dashboard');
  static String get tabOpportunities => _t('فرص شغل', 'Jobs');
  static String get tabInbox => _t('الطلبات', 'Inbox');
  static String get tabPortfolio => _t('أعمالي', 'Portfolio');
  static String get tabExplore => _t('استكشف', 'Explore');

  // Explore / Posts
  static String get exploreTitle => _t('استكشف', 'Explore');
  static String get createPost => _t('إضافة منشور', 'Create Post');
  static String get editPost => _t('تعديل المنشور', 'Edit Post');
  static String get deletePost => _t('حذف المنشور', 'Delete Post');
  static String get deletePostConfirm => _t('متأكد إنك عايز تحذف المنشور؟', 'Are you sure you want to delete this post?');
  static String get postCaptionHint => _t('اكتب تعليق...', 'Write a caption...');
  static String get postCaptionLabel => _t('الوصف', 'Caption');
  static String get addMedia => _t('أضف صور', 'Add Photos');
  static String get postTypeLabel => _t('نوع المنشور', 'Post Type');
  static String get postTypeProjectShowcase => _t('عرض مشروع', 'Project Showcase');
  static String get postTypeTip => _t('نصيحة', 'Tip');
  static String get postTypeMilestone => _t('إنجاز', 'Milestone');
  static String get postTypeRenovationUpdate => _t('تحديث', 'Renovation Update');
  static String get postCategoryLabel => _t('التصنيف', 'Category');
  static String get postLinkPortfolio => _t('اربط بمشروع في أعمالك', 'Link to portfolio project');
  static String get sharePost => _t('مشاركة', 'Share');
  static String get likeLabel => _t('إعجاب', 'Like');
  static String get commentLabel => _t('تعليق', 'Comment');
  static String get saveLabel => _t('حفظ', 'Save');
  static String get commentsTitle => _t('التعليقات', 'Comments');
  static String get commentHint => _t('اكتب تعليق...', 'Write a comment...');
  static String get postComment => _t('نشر', 'Post');
  static String get noComments => _t('لا توجد تعليقات بعد', 'No comments yet');
  static String get noPostsYet => _t('لا توجد منشورات بعد', 'No posts yet');
  static String get noPostsYetSub => _t('كن أول من ينشر في الاستكشف!', 'Be the first to post on Explore!');
  static String get myPosts => _t('منشوراتي', 'My Posts');
  static String get savedPosts => _t('المنشورات المحفوظة', 'Saved Posts');
  static String get myPostsEmpty => _t('معندكش منشورات', 'You have no posts yet');
  static String get savedPostsEmpty => _t('ما حفظتش منشورات', 'You haven\'t saved any posts');
  static String get postCreated => _t('تم نشر المنشور', 'Post created');
  static String get postDeleted => _t('تم حذف المنشور', 'Post deleted');
  static String get commentPosted => _t('تم نشر التعليق', 'Comment posted');
  static String get commentRateLimitError => _t('بتعلق بسرعة! استنى شوية', 'Commenting too fast! Please wait.');
  static String get captionRequired => _t('الوصف مطلوب', 'Caption is required');
  static String get photoCount => _t('عدد الصور: %s', 'Photos: %s');
  static String get agoNow => _t('الآن', 'Just now');
  static String get agoMin => _t('منذ دقيقة', '1 min ago');
  static String get agoMins => _t('منذ %s دقائق', '%s min ago');
  static String get agoHour => _t('منذ ساعة', '1 hour ago');
  static String get agoHours => _t('منذ %s ساعات', '%s hours ago');
  static String get agoDay => _t('منذ يوم', '1 day ago');
  static String get agoDays => _t('منذ %s أيام', '%s days ago');

  // ── M3: Quotes ──────────────────────────────────────────────────────────
  static String get quotesSectionTitle => _t('عروض الأسعار', 'Quotes');
  static String get sendQuote => _t('أرسل عرض سعر', 'Send Quote');
  static String get yourQuote => _t('عرضك الحالي', 'Your Quote');
  static String get editQuote => _t('عدّل العرض', 'Edit Quote');
  static String get submitQuote => _t('ابعت العرض', 'Submit Quote');
  static String get quoteSentSuccess =>
      _t('اتبعت العرض بنجاح', 'Quote sent successfully');
  static String get priceFromLabel => _t('السعر من', 'Price from');
  static String get priceToLabel => _t('لـ', 'To');
  static String get priceEgpHint => _t('بالجنيه', 'In EGP');
  static String get priceOnRequest =>
      _t('السعر حسب المعاينة', 'Price after inspection');
  static String get fixedPriceLabel => _t('سعر ثابت', 'Fixed price');
  static String get durationLabel => _t('المدة المتوقعة', 'Expected duration');
  static String get durationHint => _t('مثال: أسبوعين', 'Example: 2 weeks');
  static String get quoteNoteLabel => _t('تفاصيل العرض', 'Quote details');
  static String get quoteNoteHint =>
      _t('اكتب تفاصيل العرض وأي ملاحظات للعميل',
          'Write the quote details and any notes for the client');
  static String get quoteNoteRequired =>
      _t('لازم تكتب تفاصيل العرض', 'You must write the quote details');
  static String get egpUnit => _t('ج.م', 'EGP');

  static String get quoteAccept => _t('قبول', 'Accept');
  static String get quoteDecline => _t('رفض', 'Decline');
  static String get quoteAcceptConfirm => _t('تقبل العرض ده؟', 'Accept this quote?');
  static String get quoteDeclineConfirm => _t('ترفض العرض ده؟', 'Decline this quote?');
  static String get quoteStatusSent =>
      _t('في انتظار الرد', 'Awaiting response');
  static String get quoteStatusAccepted => _t('مقبول', 'Accepted');
  static String get quoteStatusDeclined => _t('مرفوض', 'Declined');
  static String get quoteStatusWithdrawn => _t('مسحوب', 'Withdrawn');
  static String get noQuoteBadge => _t('محتاج رد', 'Needs response');
  static String get noQuotesYet =>
      _t('لسه مفيش عروض على الطلب ده', 'No quotes yet for this request');
  static String get viewContractorProfile =>
      _t('شوف الملف', 'View profile');

  // ── Monetization: Pro / paywall ─────────────────────────────────────────
  static String get proPlanName => _t('برو', 'Pro');
  static String get freePlanName => _t('مجاني', 'Free');
  static String get paywallTitle => _t('باقة برو', 'Pro Plan');
  static String get paywallSubtitle =>
      _t('وصّل شغلك لعملاء أكتر واكسب أكتر.', 'Reach more clients and win more work.');
  static String get proRequiredToQuoteTitle =>
      _t('اشترك في برو عشان تبعت عروض', 'Go Pro to send quotes');
  static String get proRequiredToQuoteBody =>
      _t('العملاء مستنيين عرضك. اشترك في برو عشان تبعت عروض أسعار وتشوف تفاصيل الطلبات.',
          'Clients are waiting. Subscribe to Pro to send quotes and view request details.');
  static String get proBenefitQuotes =>
      _t('عروض أسعار غير محدودة', 'Unlimited quotes');
  static String get proBenefitRequests =>
      _t('شوف طلبات الشغل وبيانات التواصل', 'View job requests & contact details');
  static String get proBenefitRanking =>
      _t('ظهور أعلى في نتائج البحث', 'Higher ranking in search results');
  static String get proBenefitPhotos =>
      _t('صور أعمال أكتر في معرضك', 'More portfolio photos');
  static String get upgradeToProCta => _t('اشترك دلوقتي', 'Subscribe now');
  static String get upgradeToProShort => _t('اشترك في برو', 'Go Pro');
  static String get perMonth => _t('/ شهر', '/mo');
  static String get paymentComingSoon =>
      _t('الدفع هيكون متاح قريب جداً.', 'Payment is coming very soon.');
  static String get currentPlanLabel => _t('باقتك الحالية', 'Your current plan');

  // ── Pro subscription page ───────────────────────────────────────────────
  static String get proScreenTitle => _t('شطب برو', 'Shattab Pro');
  static String get proValueLine => _t(
      'خلّي شغلك ما يوقفش، عروض بلا حدود', 'Keep the work coming, quotes without limits');
  static String get proRoiLine => _t(
      'عرض واحد ممكن يرجّع اشتراك السنة كله', 'One won job can cover the whole year');
  static String get planMonthly => _t('شهري', 'Monthly');
  static String get planAnnual => _t('سنوي', 'Annual');
  static String get annualSaveBadge => _t('وفّر شهرين', 'Save 2 months');
  static String get perYear => _t('/ سنة', '/yr');
  static String get startFreeMonth => _t('ابدأ شهر مجاني', 'Start free month');
  static String get cancelAnytime => _t('تقدر تلغي في أي وقت', 'Cancel anytime');
  static String get proBenefitSeen =>
      _t('إشعار لما العميل يشوف عرضك', 'Alert when a client views your quote');
  static String get trustPaymob =>
      _t('الدفع عن طريق Paymob · آمن', 'Payments by Paymob · secure');
  static String get comparePlans => _t('المجاني وبرو', 'Free vs Pro');
  static String get cmpQuotes => _t('عروض الأسعار', 'Quotes');
  static String get cmpQuotesFree => _t('٣ في الشهر', '3 / month');
  static String get cmpUnlimited => _t('بلا حدود', 'Unlimited');
  static String get cmpRequests => _t('الطلبات المباشرة', 'Direct requests');
  static String get cmpRequestsFree => _t('قراءة بس', 'Read only');
  static String get cmpRequestsPro => _t('ردّ وابعت عرض', 'Reply & quote');
  static String get cmpRanking => _t('الترتيب في البحث', 'Search ranking');
  static String get cmpRankingFree => _t('عادي', 'Normal');
  static String get cmpRankingPro => _t('أعلى', 'Higher');
  static String get cmpPortfolio => _t('معرض الأعمال', 'Portfolio');
  static String get cmpPortfolioFree => _t('٥ أعمال', '5 projects');
  static String get cmpSeenRow => _t('إشعار «شاف عرضك»', '"Saw your quote" alert');
  static String get alreadyPro => _t('أنت مشترك في برو', "You're on Pro");
  static String proExpiresOn(String date) =>
      _t('بينتهي في $date', 'Renews on $date');

  /// Format an EGP amount with localized digits + currency unit.
  static String money(int v) {
    if (egpUnit == 'EGP') return '$v $egpUnit';
    const d = '٠١٢٣٤٥٦٧٨٩';
    final s = v.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : d[i];
    }).join();
    return '$s $egpUnit';
  }

  // ── Payment flow (InstaPay / Apple Pay) ─────────────────────────────────
  static String get choosePaymentMethod =>
      _t('اختار طريقة الدفع', 'Choose payment method');
  static String get payInstapay => _t('انستا باي', 'InstaPay');
  static String get payInstapaySub =>
      _t('تحويل فوري من أي بنك أو محفظة', 'Instant transfer from any bank or wallet');
  static String get payApplePay => _t('Apple Pay', 'Apple Pay');
  static String get paySoonBadge => _t('قريب', 'Soon');
  static String get payApplePaySub =>
      _t('بالبطاقة أو المحفظة — قريب', 'Card or wallet — coming soon');
  static String get instapayTitle =>
      _t('الدفع عن طريق انستا باي', 'Pay via InstaPay');
  static String get instapayAmountLabel => _t('المبلغ المطلوب', 'Amount due');
  static String get instapayNumberLabel =>
      _t('حوّل على رقم انستا باي ده', 'Transfer to this InstaPay number');
  static String get copyAction => _t('نسخ', 'Copy');
  static String get copiedToast => _t('اتنسخ', 'Copied');
  static String get instapayUploadLabel =>
      _t('ارفع صورة التحويل', 'Upload transfer screenshot');
  static String get instapayRefLabel =>
      _t('رقم العملية (اختياري)', 'Transfer reference (optional)');
  static String get instapaySubmit => _t('ابعت للتأكيد', 'Send for confirmation');
  static String get instapayProofRequired =>
      _t('ارفع صورة التحويل الأول', 'Upload the transfer screenshot first');
  static String get instapaySubmittedTitle =>
      _t('طلبك تحت المراجعة', 'Request under review');
  static String get instapaySubmittedBody => _t(
      'استلمنا التحويل. هنفعّل باقة برو بعد التأكيد، عادة خلال ٢٤ ساعة.',
      'We received your transfer. Pro activates after we confirm it, usually within 24 hours.');
  static String get instapayDone => _t('تمام', 'Done');
  static String get instapayError =>
      _t('حصل خطأ، حاول تاني', 'Something went wrong, try again');
  static String get applePaySoon =>
      _t('Apple Pay هيكون متاح قريب', 'Apple Pay is coming soon');

  // ── M3: Inbox ───────────────────────────────────────────────────────────
  static String get inboxTitle => _t('الطلبات المباشرة', 'Direct Requests');
  static String get inboxEmptyTitle => _t('مفيش طلبات مباشرة', 'No direct requests');
  static String get inboxEmptyMessage =>
      _t('لما عميل يبعتلك طلب مخصوص ليك هيظهر هنا على طول.',
          'When a client sends you a direct request, it will appear here.');
  static String get requestDetailTitle =>
      _t('تفاصيل الطلب', 'Request Details');
  static String get contactClient => _t('تواصل مع العميل', 'Contact Client');

  // ── M3: Portfolio management ────────────────────────────────────────────
  static String get myPortfolioTitle => _t('أعمالي', 'My Portfolio');
  static String get addWork => _t('أضف عمل', 'Add Work');
  static String get newWorkTitle => _t('عمل جديد', 'New Work');
  static String get editWorkTitle => _t('تعديل العمل', 'Edit Work');
  static String get portfolioEmptyTitle =>
      _t('لسه مضفتش أعمال', 'No works added yet');
  static String get portfolioEmptyMessage =>
      _t('اعرض شغلك عشان العملاء يشوفوا مستواك. ابدأ بإضافة أول عمل ليك.',
          'Show your work so clients can see your quality. Start by adding your first project.');
  static String get workTitleLabel => _t('عنوان العمل', 'Work title');
  static String get workTitleHint =>
      _t('مثال: تشطيب شقة في التجمع', 'Example: Apartment finishing in Tagamo3');
  static String get workCategoryLabel => _t('التصنيف', 'Category');
  static String get workCategoryHint => _t('مثال: تشطيب كامل', 'Example: Full finishing');
  static String get workYearLabel => _t('سنة التنفيذ', 'Year');
  static String get workYearHint => _t('مثال: 2025', 'Example: 2025');
  static String get workLocationLabel => _t('المكان', 'Location');
  static String get workLocationHint =>
      _t('مثال: القاهرة الجديدة', 'Example: New Cairo');
  static String get workDescriptionLabel => _t('الوصف', 'Description');
  static String get workDescriptionHint =>
      _t('اكتب نبذة قصيرة عن العمل', 'Write a short description');
  static String get coverPhotoHint =>
      _t('أول صورة هتكون صورة الغلاف', 'The first photo will be the cover');
  static String get saveWork => _t('احفظ العمل', 'Save Work');
  static String get deleteWork => _t('حذف العمل', 'Delete Work');
  static String get deleteWorkConfirm =>
      _t('متأكد إنك عايز تمسح العمل ده؟', 'Are you sure you want to delete this work?');
  static String get titleRequired => _t('لازم تكتب عنوان للعمل', 'Title is required');
  static String get coverRequired =>
      _t('لازم تضيف صورة واحدة على الأقل', 'You must add at least one photo');

  // ── Discover ─────────────────────────────────────────────────────────────
  static String get searchHint =>
      _t('ابحث عن مقاول أو شركة…', 'Search for a contractor or company…');
  static String get featuredContractors =>
      _t('مقاولين مميزين', 'Featured Contractors');
  static String get topRated => _t('الأعلى تقييمًا', 'Top Rated');
  static String get nearYou => _t('قريبين منك', 'Near You');
  static String nearYouIn(String city) => _t('قريبين منك في $city', 'Near you in $city');
  static String get browseByCategory => _t('تصفّح بالتخصص', 'Browse by category');
  static String get trendingNearYou => _t('رائج بالقرب منك', 'Trending Near You');
  static String get viewAll => _t('عرض الكل', 'View All');
  static String get verified => _t('موثوق', 'Verified');
  static String get allContractors => _t('كل المقاولين', 'All Contractors');
  static String get noContractorsTitle =>
      _t('مفيش مقاولين بالشروط دي', 'No contractors matching these criteria');
  static String get noContractorsMessage =>
      _t('جرّب تغيّر التخصص أو المحافظة', 'Try changing the specialty or city');

  // ── Profile management ────────────────────────────────────────────────────
  static String get editProfile =>
      _t('تعديل الملف الشخصي', 'Edit Profile');
  static String get profileNameLabel => _t('الاسم', 'Name');
  static String get profilePhoneLabel => _t('رقم التليفون', 'Phone number');
  static String get phoneNotEditable =>
      _t('لا يمكن تغيير رقم التليفون', 'Phone number cannot be changed');
  static String get changePhoto =>
      _t('اضغط لتغيير الصورة', 'Tap to change photo');
  static String get housingData => _t('بيانات السكن', 'Housing Data');
  static String get interestAreas => _t('مجالات الاهتمام', 'Areas of Interest');
  static String get nameRequired => _t('الاسم مطلوب', 'Name is required');
  static String get saveProfile => _t('حفظ', 'Save');
  static String get profileSaved =>
      _t('تم حفظ الملف الشخصي', 'Profile saved');
  static String get profileError =>
      _t('حصل خطأ، حاول تاني', 'An error occurred, try again');
  static String get selectCity => _t('اختار المحافظة', 'Select city');
  static String get selectDistrict => _t('اختار المنطقة', 'Select district');
  static String get editProfileButton =>
      _t('تعديل الملف', 'Edit Profile');

  // ── Common actions ──────────────────────────────────────────────────
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get delete => _t('حذف', 'Delete');
  static String get confirm => _t('تأكيد', 'Confirm');

  // ── Profile ──────────────────────────────────────────────────────────────
  static String get profileTitle => _t('حسابي', 'Profile');
  static String get signOutButton => _t('تسجيل الخروج', 'Sign Out');
  static String get signOutTitle => _t('تأكيد تسجيل الخروج', 'Confirm Sign Out');
  static String get signOutConfirmation => _t('متأكد إنك عايز تسجل خروج؟', 'Are you sure you want to sign out?');
  static String get myRequests => _t('طلباتي', 'My Requests');
  static String get mySaved => _t('المحفوظات', 'Saved');
  static String get discoverContractors =>
      _t('اكتشف المقاولين', 'Discover Contractors');
  static String get darkModeTitle => _t('الوضع الليلي', 'Dark Mode');
  static String get lightModeTitle => _t('الوضع النهاري', 'Light Mode');
  static String get motionLabel => _t('الحركة', 'Motion');
  static String get darkMode => _t('الوضع الليلي', 'Dark Mode');
  static String get lightMode => _t('الوضع النهاري', 'Light Mode');
  static String get languageTitle => _t('اللغة', 'Language');
  static String get languageArabic => _t('العربية', 'Arabic');
  static String get languageEnglish => _t('الإنجليزية', 'English');

  // ── Brief Detail ────────────────────────────────────────────────────────
  static String get briefDetailTitle => _t('تفاصيل الطلب', 'Request Details');
  static String get cancelBriefTitle =>
      _t('إلغاء الطلب؟', 'Cancel request?');
  static String get cancelBriefMessage =>
      _t('مش هيقدر يتفعّل تاني بعد ما تلغيه.',
          'It cannot be reactivated after cancellation.');
  static String get cancelBriefNo => _t('لأ، خليه', 'No, keep it');
  static String get cancelBriefYes => _t('أيوة، إلغي', 'Yes, cancel');
  static String get cancelButton => _t('إلغاء الطلب', 'Cancel Request');
  static String get briefNotFound =>
      _t('الطلب مش موجود', 'Request not found');
  static String get tryAgain => _t('حاول تاني', 'Try again');
  static String get locationDetailsLabel =>
      _t('تفاصيل المكان', 'Location Details');
  static String get lookingForLabel => _t('بدور على', 'Looking for');
  static String get statusCancelled => _t('ملغي', 'Cancelled');
  static String get statusPost => _t('بوست عام', 'Public Post');
  static String get statusDirectRequest =>
      _t('طلب مباشر', 'Direct Request');

  // ── Brief Sent ──────────────────────────────────────────────────────────
  static String get briefSentTitle =>
      _t('تم إرسال طلبك!', 'Your request has been sent!');
  static String get briefSentMessage =>
      _t('المقاول هيتلقى طلبك ويرد عليك خلال ٢٤ ساعة.',
          'The contractor will receive your request and reply within 24 hours.');
  static String get briefSentMessageNew => _t(
      'المقاول استلم تفاصيل مشروعك وهيتواصل معاك قريب.\nتقدر تكلّمه دلوقتي على واتساب لو حابب تستعجل.',
      'The contractor received your project details and will contact you soon.\nYou can call them on WhatsApp now if you want to speed things up.');
  static String get whatsappBriefGreeting =>
      _t('السلام عليكم، أنا بعتلك طلب على شطب',
          'Hello, I sent you a request on Shattab');
  static String get doneBackToDiscover =>
      _t('تمام، رجوع للاكتشاف', 'Done, back to Discover');
  static String get briefSentWhatsApp =>
      _t('تواصل مع المقاول على واتساب', 'Contact contractor on WhatsApp');
  static String get briefSentCall =>
      _t('اتصل بالمقاول', 'Call the contractor');
  static String get briefSentBackToRequests =>
      _t('رجوع لطلباتي', 'Back to my requests');

  // ── Create Post ─────────────────────────────────────────────────────────
  static String get createPostTitle => _t('عمل بوست جديد', 'New Post');
  static String get createPostSubtitle =>
      _t('اشتغل مع مقاولين من كل المحافظات', 'Work with contractors from all cities');
  static String get workTypeLabel => _t('نوع الشغل', 'Work type');
  static String get workTypeHint =>
      _t('مثال: تشطيب حمام', 'Example: Bathroom renovation');
  static String get apartmentTypeLabel => _t('نوع الوحدة', 'Unit type');
  static String get budgetLabel => _t('الميزانية التقريبية (اختياري)', 'Budget (optional)');
  static String get budgetHint => _t('مثال: ٥٠٠٠٠', 'Example: 50000');
  static String get timelineLabel => _t('الموعد المقترح', 'Timeline');
  static String get timelineHint =>
      _t('مثال: خلال أسبوعين', 'Example: Within 2 weeks');
  static String get descriptionLabel => _t('تفاصيل الشغل', 'Work details');
  static String get descriptionHint =>
      _t('اكتب أي تفاصيل تانية...', 'Write any additional details...');
  static String get photosLabel => _t('الصور (اختياري)', 'Photos (optional)');
  static String get createPostButton => _t('انشر البوستر', 'Publish Post');
  static String get writeWhatYouNeed =>
      _t('اكتب اللي محتاجه', 'Write what you need');
  static String get contractorsWillSeeMatched => _t(
      'المقاولين اللي بتخصصاتهم وأماكنهم تطابق هيشوفوا البوست.',
      'Contractors whose specialties and areas match will see the post.');
  static String get descriptionWorkHint =>
      _t('مثال: محتاج حد يدهن الشقة كاملة…',
          'Example: I need someone to paint the entire apartment…');
  static String get sectionLookingForWho =>
      _t('بدور على مين؟', 'Who are you looking for?');
  static String get phoneVisibleContractors => _t(
      'رقم تليفونك هيظهر للمقاولين اللي يشوفوا البوست.',
      'Your phone number will be visible to contractors who see the post.');
  static String get errorWriteMoreDetails =>
      _t('اكتب تفاصيل أكتر', 'Write more details');
  static String get errorFillApartmentCity =>
      _t('املا نوع الشقة والمحافظة', 'Fill in apartment type and city');
  static String get errorSelectSpecialty =>
      _t('اختار تخصص أو أكتر', 'Select one or more specialties');
  static String get errorDescriptionShort =>
      _t('اكتب وصف للشغل على الأقل من ١٠ حروف',
          'Write a description of at least 10 characters');

  // ── Send Brief ──────────────────────────────────────────────────────────
  static String get sendBriefTitle =>
      _t('ابعث طلب مباشر', 'Send Direct Request');
  static String get sendBriefSubtitle =>
      _t('اطلب عرض سعر من مقاول معين', 'Request a quote from a specific contractor');
  static String get sendBriefDescriptionLabel =>
      _t('تفاصيل الشغل', 'Work details');
  static String get sendBriefDescriptionHint =>
      _t('مثال: عايز أعمّل دهان للشقة كلها...',
          'Example: I want to paint the entire apartment...');
  static String get sendBriefPhotosLabel =>
      _t('الصور (اختياري)', 'Photos (optional)');
  static String get sendBriefButton =>
      _t('ابعت الطلب', 'Send Request');
  static String get sendBriefDefaultTitle =>
      _t('ابعت تفاصيل المشروع', 'Send project details');
  static String get sendBriefProjectDetails =>
      _t('تفاصيل مشروعك', 'Your project details');
  static String get sendBriefAllDetailsHint =>
      _t('ابعت كل التفاصيل اللي محتاج المقاول يعرفها',
          'Send all the details the contractor needs to know');
  static String get sendBriefWorkDescLabel =>
      _t('وصف الشغل المطلوب', 'Work description');
  static String get sendBriefWorkDescHint =>
      _t('مثال: محتاج تشطيب كامل…', 'Example: Need full finishing…');
  static String get phoneVisibleContractor => _t(
      'رقم تليفونك هيظهر للمقاول لما يستلم الطلب.',
      'Your phone number will be visible to the contractor when they receive the request.');

  // ── My Briefs ───────────────────────────────────────────────────────────
  static String get myBriefsTitle => _t('طلباتي', 'My Requests');
  static String get newPostButton => _t('بوست جديد', 'New Post');
  static String get noBriefsTitle => _t('مفيش طلبات لسه', 'No requests yet');
  static String get noBriefsMessage =>
      _t('لما تعمل بوست أو تبعت طلب هيظهر هنا.', 'When you post or send a request, it will appear here.');
  static String get createNewPostButton =>
      _t('اعمل بوست جديد', 'Create New Post');
  static String get noBriefsHere => _t('مفيش حاجة هنا لسه', 'Nothing here yet');
  static String get noBriefsHereMessage => _t(
      'ابعت طلب لمقاول معين من صفحته، أو اعمل بوست عام والمقاولين يتواصلوا معاك.',
      'Send a request to a specific contractor from their page, or create a public post.');
  static String get sectionOpenPosts => _t('بوستات مفتوحة', 'Open Posts');
  static String get sectionDirectRequests =>
      _t('طلبات مباشرة', 'Direct Requests');

  // ── Job Opportunities (Contractor) ──────────────────────────────────────
  static String get opportunitiesTitle => _t('فرص شغل', 'Job Opportunities');
  static String get noPostsTitle => _t('مفيش بوستات دلوقتي', 'No posts right now');
  static String get noPostsMessage => _t(
      'لو في عملاء بدورين على شغلك هتلاقي بوستاتهم هنا فور ما تتنشر.',
      'If clients are looking for your services, their posts will appear here.');

  // ── Post Detail (Contractor) ────────────────────────────────────────────
  static String get postDetailTitle => _t('تفاصيل البوستر', 'Post Details');
  static String get postDescriptionLabel =>
      _t('تفاصيل الشغل', 'Work details');
  static String get postLocationLabel => _t('الموقع', 'Location');
  static String get homeownerLabel => _t('صاحب البوستر', 'Post owner');
  static String get contactHomeowner =>
      _t('تواصل مع صاحب البوستر', 'Contact post owner');
  static String get sendQuoteButton =>
      _t('أرسل عرض سعر', 'Send Quote');
  static String get yourQuoteLabel => _t('عرضك الحالي', 'Your Quote');
  static String get postNotFound =>
      _t('البوست مش موجود', 'Post not found');
  static String get postDetailPostedPrefix =>
      _t('اتنشر: ', 'Posted: ');
  static String get whatsappPostGreeting => _t(
      'السلام عليكم، شفت بوستك على شطب وحبيت أعرف أكتر عن الشغل',
      'Hello, I saw your post on Shattab and would like to know more about the work');

  // ── Request Detail (Inbox) ──────────────────────────────────────────────
  static String get clientInfoFailed =>
      _t('تعذر تحميل بيانات العميل', 'Failed to load client data');
  static String get sendQuoteCTA => _t('أرسل عرض سعر', 'Send Quote');

  // ── Portfolio Gallery (Homeowner) ───────────────────────────────────────
  static String get portfolioGalleryTitle =>
      _t('معرض الأعمال', 'Portfolio Gallery');
  static String get noWorksTitle =>
      _t('مفيش أعمال متضافة لسه', 'No works added yet');
  static String get noWorksMessage =>
      _t('المقاول هيضيف شغله هنا قريب.', 'The contractor will add their work here soon.');

  // ── Project Detail ──────────────────────────────────────────────────────
  static String get projectDetailTitle =>
      _t('تفاصيل العمل', 'Project Details');
  static String get projectCategoryLabel => _t('التصنيف', 'Category');
  static String get projectYearLabel => _t('السنة', 'Year');
  static String get projectLocationLabel => _t('المكان', 'Location');
  static String get projectDescriptionLabel => _t('الوصف', 'Description');
  static String get projectNotFound =>
      _t('العمل مش موجود', 'Project not found');

  // ── Contractor Profile ──────────────────────────────────────────────────
  static String get contractorProfileTitle =>
      _t('ملف المقاول', 'Contractor Profile');
  static String get ratingLabel => _t('التقييم', 'Rating');
  static String get reviewsCount => _t('تقييم', 'Review');
  static String get specialtiesLabel => _t('التخصصات', 'Specialties');
  static String get serviceAreasLabel => _t('مناطق الخدمة', 'Service Areas');
  static String get saveContractor => _t('احفظ', 'Save');
  static String get savedContractor => _t('محفوظ', 'Saved');
  static String get sendBriefCTA => _t('ابعث طلب', 'Send Request');
  static String get viewPortfolio =>
      _t('شوف الأعمال', 'View Portfolio');

  // ── Reviews (M4) ────────────────────────────────────────────────────────
  static String get writeReviewTitle =>
      _t('اكتب تقييم', 'Write a Review');
  static String get reviewTitleLabel =>
      _t('عنوان التقييم', 'Review title');
  static String get reviewTitleHint =>
      _t('مثال: شغل ممتاز', 'Example: Great work');
  static String get reviewBodyLabel => _t('التفاصيل', 'Details');
  static String get reviewBodyHint =>
      _t('اكتب تجربتك مع المقاول...', 'Write about your experience...');
  static String get reviewSubmit =>
      _t('انشر التقييم', 'Submit Review');
  static String get reviewRequired =>
      _t('لازم تكتب عنوان وتفاصيل', 'Title and details are required');
  static String get reviewSuccess =>
      _t('اتباع التقييم بنجاح', 'Review submitted successfully');
  static String get rateContractor =>
      _t('قيّم المقاول', 'Rate Contractor');
  static String get yourReview => _t('رأيك (اختياري)', 'Your review (optional)');
  static String get yourReviewHint =>
      _t('احكي تجربتك مع المقاول', 'Tell us about your experience');
  static String get submitReview => _t('إرسال التقييم', 'Submit Review');
  static String get selectStarsFirst =>
      _t('اختار تقييم بالنجوم الأول', 'Select a star rating first');
  static String get editReview => _t('تعديل', 'Edit');
  static String get ratingHelpsOthers =>
      _t('تقييمك بيساعد باقي العملاء', 'Your rating helps other clients');

  // ── Contact ─────────────────────────────────────────────────────────────
  static String get contactViaWhatsApp =>
      _t('تواصل عبر واتساب', 'Contact via WhatsApp');
  static String get call => _t('اتصل', 'Call');
  static String get phone => _t('تليفون', 'Phone');

  // ── Create Post page ────────────────────────────────────────────────────
  static String get createPostPublishButton =>
      _t('انشر البوست', 'Publish Post');

  // ── Price error ─────────────────────────────────────────────────────────
  static String get priceMinLessThanMax =>
      _t('السعر من يجب أن يكون أقل من السعر إلى',
          'Price from must be less than price to');

  // ── Contractor redesign ─────────────────────────────────────────────────
  static String get greetingMorning => _t('صباح الخير', 'Good morning');
  static String get greetingAfternoon => _t('مساء الخير', 'Good afternoon');
  static String get greetingEvening => _t('مساء الخير', 'Good evening');
  static String get newJobs => _t('فرص عمل جديدة', 'New Jobs');
  static String get searchJobs => _t('ابحث عن فرصة عمل...', 'Search for a job...');
  static String get filterToday => _t('اليوم', 'Today');
  static String get filterNearest => _t('الأقرب', 'Nearest');
  static String get filterHighestBudget =>
      _t('أعلى ميزانية', 'Highest Budget');
  static String get filterVerified =>
      _t('عملاء موثوقين', 'Verified Clients');
  static String get filterUrgent => _t('عاجل', 'Urgent');
  static String get filterPainting => _t('دهانات', 'Painting');
  static String get filterElectrical => _t('كهرباء', 'Electrical');
  static String get filterPlumbing => _t('سباكة', 'Plumbing');
  static String get filterFinishing => _t('تشطيب', 'Finishing');
  static String get filterBathrooms => _t('حمامات', 'Bathrooms');
  static String get filterKitchens => _t('مطابخ', 'Kitchens');
  static String get urgentLabel => _t('عاجل', 'Urgent');
  static String get newLabel => _t('جديد', 'New');
  static String get openJobs => _t('فرص شغل', 'Open Jobs');
  static String get applicants => _t('متقدمين', 'Applicants');
  static String get budget => _t('الميزانية', 'Budget');
  static String get verifiedTrust => _t('موثق', 'Verified');
  static String get filter => _t('تصفية', 'Filter');
  static String get apply => _t('تطبيق', 'Apply');
  static String get clearAll => _t('إلغاء الكل', 'Clear All');
  static String filterWithCount(int count) =>
      _t('تصفية ($count)', 'Filter ($count)');
  static String get filterSort => _t('الترتيب', 'Sort');
  static String get filterCategory => _t('التخصص', 'Category');
  static String get filterCity => _t('المدينة', 'City');
  static String get filterTime => _t('الوقت', 'Time');
  static String get filterThisWeek => _t('هذا الأسبوع', 'This Week');
  static String get filterThisMonth => _t('هذا الشهر', 'This Month');
  static String get filterNewestFirst => _t('الأحدث', 'Newest');
  static String get noJobsTitle =>
      _t('مفيش فرص شغل دلوقتي', 'No job opportunities right now');
  static String get noJobsMessage => _t(
      'جرب تغير الفلاتر أو ارجع تاني بعدين. هتلاقي فرص جديدة باستمرار.',
      'Try changing the filters or come back later. New opportunities appear regularly.');

  // ── Debug / Demo login ───────────────────────────────────────────────────
  static String get debugMode => _t('وضع التجربة (Debug)', 'Debug Mode');
  static String get demoLoginHomeowner =>
      _t('دخول كصاحب شقة', 'Login as Homeowner');
  static String get demoLoginContractor =>
      _t('دخول كمقاول', 'Login as Contractor');

  // ── Misc / Missing Strings ────────────────────────────────────────────────
  static String get networkError =>
      _t('مفيش اتصال بالإنترنت', 'No internet connection');
  static String get somethingWentWrong =>
      _t('حصل خطأ، حاول تاني', 'Something went wrong, try again');
  static String get nameNotEnough => _t('الاسم مش كافي', 'Name is not enough');
  static String get nameExample => _t('مثال: أحمد علي', 'Example: Ahmed Ali');
  static String get refreshHint =>
      _t('اسحب للأسفل عشان التحديث', 'Pull down to refresh');
  static String get yearsExperienceInvalid =>
      _t('سنين خبرة غير صحيحة', 'Invalid years of experience');
  static String get noSavedContractors =>
      _t('مفيش مقاولين محفوظين لسه', 'No saved contractors yet');
  static String get noSavedContractorsMsg =>
      _t('اضغط على علامة الحفظ عشان تقدر ترجع تاني',
          'Tap the save icon to come back later');
  static String get contractorNotFound =>
      _t('المقاول مش موجود', 'Contractor not found');
  static String get contractorNotFoundMsg =>
      _t('يمكن يكون شال الحساب أو اتلغى', 'Account may have been deleted');
  static String get projectDetails =>
      _t('تفاصيل مشروعك', 'Your Project Details');
  static String get defaultWhatsAppMsg =>
      _t('السلام عليكم، أنا مهتم بخدماتك', 'Hello, I\'m interested in your services');
  static String get statusOpen => _t('بوست مفتوح', 'Open Post');
  static String get statusDirect => _t('طلب مباشر', 'Direct Request');
  static String get newBadge => _t('جديد', 'New');
  static String get urgentBadge => _t('عاجل', 'Urgent');
  static String get projects => _t('مشروع', 'Projects');
  static String get singleProject => _t('مشروع', 'Project');
  static String get year => _t('سنة', 'Year');
  static String get photos => _t('صور', 'Photos');
  static String get saveTooltip =>
      _t('حفظ المقاول', 'Save contractor');
  static String get unsaveTooltip =>
      _t('إزالة من المحفوظات', 'Remove from saved');
  static String get allSpecialties =>
      _t('كل التخصصات', 'All Specialties');
  static String get allCities => _t('كل المحافظات', 'All Cities');
  static String get foundContractors => _t('مقاول', 'Contractors');
  static String get editLabel => _t('تعديل', 'Edit');
  static String get deleteLabel => _t('حذف', 'Delete');
  static String get confirmDelete => _t('تأكيد الحذف', 'Confirm Delete');
  static String get confirmDeleteMsg =>
      _t('متأكد إنك عايز تحذف العنصر ده؟', 'Are you sure you want to delete this?');
  static String get retry => _t('حاول تاني', 'Retry');
  static String get noMoreResults => _t('خلصت النتائج', 'No more results');
  static String get loading => _t('جاري التحميل', 'Loading');
  static String get loadingMore => _t('بيحمل المزيد...', 'Loading more...');
  static String get noResultsFound => _t('مالقيش نتائج', 'No results found');
  static String get required => _t('مطلوب', 'Required');
  static String get minLabel => _t('أقل', 'Min');
  static String get maxLabel => _t('أكثر', 'Max');
  static String get allRightsReserved =>
      _t('جميع الحقوق محفوظة لـ', 'All rights reserved');

  // ── Activity / Feed ──────────────────────────────────────────────────────
  static String get activityPostedProject =>
      _t('نشر طلب عمل جديد', 'Posted a new work request');
  static String get activityAcceptedQuote =>
      _t('قبل عرض سعر', 'Accepted a quote');
  static String get activityPaymentCompleted =>
      _t('تم إتمام دفعة', 'Payment completed');
  static String get activityNewReview =>
      _t('تقييم جديد', 'New review');
  static String get activityDisputeOpened =>
      _t('تم فتح نزاع', 'Dispute opened');
  static String get activityVerified =>
      _t('تم التوثيق', 'Verified');

  // ── Form Validation ──────────────────────────────────────────────────────
  static String get fieldRequired =>
      _t('الحقل ده مطلوب', 'This field is required');
  static String get invalidEmail =>
      _t('البريد الإلكتروني مش صحيح', 'Invalid email');
  static String get tooShort => _t('قصير جداً', 'Too short');
  static String get tooLong => _t('طويل جداً', 'Too long');
  static String get passwordMismatch =>
      _t('كلمة السر مش متطابقة', 'Passwords do not match');

  // ── Error Mapping ────────────────────────────────────────────────────
  static String get errAuthFailed =>
      _t('فشل تسجيل الدخول، حاول تاني', 'Login failed, try again');
  static String get errOtpFailed =>
      _t('كود التأكيد غلط، حاول تاني', 'Wrong verification code, try again');
  static String get errOtpExpired =>
      _t('الكود انتهت صلاحيته، ابعت واحد جديد', 'Code expired, send a new one');
  static String get errNetwork =>
      _t('مفيش نت، اتأكد من اتصالك', 'No internet, check your connection');
  static String get errServerError =>
      _t('الخدمة مش شغالة دلوقتي، حاول تاني', 'Service unavailable, try again');
  static String get errDataLoad =>
      _t('حصل مشكلة في تحميل البيانات', 'Error loading data');
  static String get errDataSave =>
      _t('حصل مشكلة في حفظ البيانات', 'Error saving data');
  static String get errSessionExpired =>
      _t('انتهت الجلسة، سجل دخول تاني', 'Session expired, log in again');
  static String get errPermissionDenied =>
      _t('مش مسموحلك تعمل كده', 'Permission denied');
  static String get errNotFound =>
      _t('العنصر مش موجود', 'Not found');
  static String get errPhotoUpload =>
      _t('حصل مشكلة في رفع الصور', 'Error uploading photos');
  static String get errInvalidData =>
      _t('البيانات مش صحيحة، تأكد منها', 'Invalid data, please check');
  static String get errSignupDisabled => _t(
      'إنشاء حساب بالرقم مش متاح دلوقتي، سجّل بجوجل',
      'Phone sign-up is off right now, use Google');
  static String get errPhoneTaken => _t(
      'الرقم ده مسجّل قبل كده، سجّل دخول',
      'This number is already registered, sign in');

  // ── Portfolio ────────────────────────────────────────────────────────────
  static String get portfolioAdd => _t('أضف عمل', 'Add Work');
  static String get portfolioEdit => _t('تعديل العمل', 'Edit Work');
  static String get portfolioDelete => _t('حذف العمل', 'Delete Work');
  static String get portfolioDeleteError =>
      _t('حصل خطأ أثناء حذف العمل', 'Error deleting work');
  static String get postCreatedSuccess =>
      _t('تم نشر الطلب بنجاح', 'Post created successfully');
  static String get projectSavedSuccess =>
      _t('تم حفظ العمل بنجاح', 'Project saved successfully');
  static String get projectDeletedSuccess =>
      _t('تم حذف العمل بنجاح', 'Project deleted successfully');
  static String get portfolioDeleteConfirm =>
      _t('متأكد إنك عايز تحذف العمل ده؟', 'Are you sure you want to delete this work?');
  static String get portfolioTitleLabel =>
      _t('عنوان العمل', 'Work title');
  static String get portfolioTitleHint =>
      _t('مثال: تشطيب شقة ١٥٠م', 'Example: 150m² apartment finishing');
  static String get portfolioCategoryLabel =>
      _t('التصنيف', 'Category');
  static String get portfolioCategoryHint =>
      _t('مثال: تشطيب', 'Example: Finishing');
  static String get portfolioYearLabel => _t('السنة', 'Year');
  static String get portfolioYearHint =>
      _t('مثال: ٢٠٢٥', 'Example: 2025');
  static String get portfolioLocationLabel => _t('المكان', 'Location');
  static String get portfolioLocationHint =>
      _t('مثال: القاهرة', 'Example: Cairo');
  static String get portfolioDescriptionLabel =>
      _t('الوصف', 'Description');
  static String get portfolioDescriptionHint =>
      _t('وصف العمل بالتفصيل...', 'Detailed description...');
  static String get portfolioCoverLabel =>
      _t('صورة الغلاف', 'Cover photo');
  static String get portfolioPhotosLabel =>
      _t('صور العمل', 'Work photos');
  static String get portfolioSaved =>
      _t('تم حفظ العمل', 'Work saved');
  static String get portfolioSaveError =>
      _t('حصل خطأ أثناء حفظ العمل', 'Error saving work');
  static String get photoMaxReached =>
      _t('وصلت للحد الأقصى من الصور', 'Maximum photos reached');

  // ── Saved Confirmation ───────────────────────────────────────────────────
  static String get savedToast => _t('تم الحفظ', 'Saved');
  static String get unsavedToast =>
      _t('تم الإزالة من المحفوظات', 'Removed from saved');

  // ── Motion Mode ──────────────────────────────────────────────────────────
  static String get motionFull => _t('كامل', 'Full');
  static String get motionReduced => _t('مخفض', 'Reduced');
  static String get motionOff => _t('متوقف', 'Off');

  // ── Profile & Company ───────────────────────────────────────────────────
  static String get yourData => _t('بياناتك', 'Your Data');
  static String get homeownerDetailsHint => _t(
      'عشان نرشّحلك أنسب المقاولين لبيتك',
      'So we can match you with the right contractors');
  static String get apartmentType => _t('نوع الشقة', 'Apartment Type');
  static String get fillBothFields => _t('املا الحقلين', 'Fill both fields');
  static String get companyData => _t('بيانات الشركة', 'Company Data');
  static String get companyName =>
      _t('اسم الشركة / المقاول', 'Company / Contractor Name');
  static String get logo => _t('الشعار', 'Logo');
  static String get professionalTitle =>
      _t('العنوان المهني', 'Professional Title');
  static String get professionalTitleHint =>
      _t('مثال: تشطيبات وديكورات فاخرة', 'Example: Luxury finishes and decor');
  static String get bioInfo => _t('نبذة عنك', 'About You');
  static String get coverPhoto => _t('صورة الغلاف', 'Cover Photo');

  // ── Contractor Profile ──────────────────────────────────────────────────
  static String get sendProjectDetails =>
      _t('ابعت تفاصيل مشروعك', 'Send your project details');
  static String get profileGreeting => _t(
      'السلام عليكم، شفت بروفايلك على شطب وحبيت أكلمك',
      'Hello, I saw your profile on Shattab and wanted to reach out');
  static String get aboutContractor => _t('عن المقاول', 'About');
  static String get worksIn => _t('بيشتغل في', 'Works in');
  static String get newContractor => _t('مقاول جديد', 'New Contractor');
  static String get responseRate => _t('معدل الرد', 'Response Rate');
  static String get projectsCompleted =>
      _t('المشاريع المنجزة', 'Projects Completed');
  static String get experienceYears => _t('سنين الخبرة', 'Years of Experience');
  static String get share => _t('مشاركة', 'Share');
  static String get copiedData =>
      _t('تم نسخ البيانات', 'Data copied');
  static String get seeOnShattab =>
      _t('شوف الملف على شطب: %s', 'View profile on Shattab: %s');
  static String get forContact => _t('للتواصل', 'Contact');
  static String get clientsPreview =>
      _t('ده اللي بيشوفه العملاء', 'This is what clients see');

  // ── Onboarding ──────────────────────────────────────────────────────────
  static String get tellUsAboutYourself =>
      _t('قلنا عن نفسك', 'Tell us about yourself');
  static String get fullNameHint => _t('الاسم بالكامل', 'Full name');
  static String get chooseRole => _t('اختر نوع الحساب', 'Choose account type');
  static String get homeownerRole => _t('صاحب شقة', 'Homeowner');
  static String get contractorRole => _t('مقاول', 'Contractor');

  // ── Time formatting helpers ─────────────────────────────────────────────
  static String minAgo(int n) => _t('منذ $n دقيقة', '$n min ago');
  static String minsAgo(int n) => _t('منذ $n دقائق', '$n mins ago');
  static String hourAgo(int n) => _t('منذ $n ساعة', '$n hour ago');
  static String hoursAgo(int n) => _t('منذ $n ساعات', '$n hours ago');
  static String dayAgo(int n) => _t('منذ $n يوم', '$n day ago');
  static String daysAgo(int n) => _t('منذ $n أيام', '$n days ago');
  static String photosCount(int n) => _t('$n صور', '$n photos');
}
