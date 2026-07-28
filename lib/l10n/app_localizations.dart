import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @tierHowGold.
  ///
  /// In ar, this message translates to:
  /// **'ذهبي: حساب موثّق + ١٠ مشاريع منجزة أو ٥ تقييمات.'**
  String get tierHowGold;

  /// No description provided for @tierHowSilver.
  ///
  /// In ar, this message translates to:
  /// **'فضي: ٣ مشاريع منجزة أو حساب موثّق.'**
  String get tierHowSilver;

  /// No description provided for @tierNotForSale.
  ///
  /// In ar, this message translates to:
  /// **'المستوى بيتكسب بالشغل المنجز — مش بيتباع ومش جزء من اشتراك برو.'**
  String get tierNotForSale;

  /// No description provided for @quotesLeftThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'باقي لك {remaining} عروض مجانية الشهر ده'**
  String quotesLeftThisMonth(int remaining);

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'شطب'**
  String get appName;

  /// No description provided for @appNameLatin.
  ///
  /// In ar, this message translates to:
  /// **'Shattab'**
  String get appNameLatin;

  /// No description provided for @enterPhone.
  ///
  /// In ar, this message translates to:
  /// **'ادخل رقم تليفونك'**
  String get enterPhone;

  /// No description provided for @phoneHint.
  ///
  /// In ar, this message translates to:
  /// **'+20 1XX XXX XXXX'**
  String get phoneHint;

  /// No description provided for @phoneLocalHint.
  ///
  /// In ar, this message translates to:
  /// **'1XX XXX XXXX'**
  String get phoneLocalHint;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'كمّل'**
  String get continueLabel;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'ادخل كود التحقق'**
  String get otpTitle;

  /// No description provided for @signInSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك للمتابعة'**
  String get signInSheetTitle;

  /// No description provided for @signInToSave.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لحفظ هذا المحترف'**
  String get signInToSave;

  /// No description provided for @signInToSendRequest.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لإرسال طلبك'**
  String get signInToSendRequest;

  /// No description provided for @signInToPost.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لنشر طلبك'**
  String get signInToPost;

  /// No description provided for @signInToInteract.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك للتفاعل مع المنشورات'**
  String get signInToInteract;

  /// No description provided for @quoteSentShort.
  ///
  /// In ar, this message translates to:
  /// **'عرضك مُرسل'**
  String get quoteSentShort;

  /// No description provided for @myQuotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'عروضي'**
  String get myQuotesTitle;

  /// No description provided for @myQuotesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسّه مفيش عروض'**
  String get myQuotesEmptyTitle;

  /// No description provided for @signInToSeeRequests.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لرؤية طلباتك'**
  String get signInToSeeRequests;

  /// No description provided for @signInOrCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك أو أنشئ حساب'**
  String get signInOrCreateAccount;

  /// No description provided for @contractorSignInLink.
  ///
  /// In ar, this message translates to:
  /// **'محترف؟ سجّل دخولك من هنا'**
  String get contractorSignInLink;

  /// No description provided for @heroLine1.
  ///
  /// In ar, this message translates to:
  /// **'شطب بيتك'**
  String get heroLine1;

  /// No description provided for @heroLine2.
  ///
  /// In ar, this message translates to:
  /// **'من غير وجع دماغ'**
  String get heroLine2;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم التليفون'**
  String get phoneLabel;

  /// No description provided for @dataSecure.
  ///
  /// In ar, this message translates to:
  /// **'بياناتك آمنة ومشفرة'**
  String get dataSecure;

  /// No description provided for @loginPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get loginPrompt;

  /// No description provided for @loginAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginAction;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'٦ حروف على الأقل'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'أكّد كلمة السر'**
  String get confirmPasswordHint;

  /// No description provided for @signInAction.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signInAction;

  /// No description provided for @createAccountAction.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccountAction;

  /// No description provided for @noAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'معندكش حساب؟'**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب؟'**
  String get haveAccountPrompt;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة السر؟'**
  String get forgotPassword;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر Google'**
  String get continueWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get orDivider;

  /// No description provided for @quickActionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActionsTitle;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get accountSettingsTitle;

  /// No description provided for @taglineNew.
  ///
  /// In ar, this message translates to:
  /// **'من أول فكرة لآخر لمسة'**
  String get taglineNew;

  /// No description provided for @otpHint.
  ///
  /// In ar, this message translates to:
  /// **'كود من ٦ أرقام'**
  String get otpHint;

  /// No description provided for @resendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الكود تاني'**
  String get resendCode;

  /// No description provided for @resendInSeconds.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تعيد بعد %s ث'**
  String get resendInSeconds;

  /// No description provided for @invalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفون غير صحيح'**
  String get invalidPhone;

  /// No description provided for @invalidOtp.
  ///
  /// In ar, this message translates to:
  /// **'الكود اللي دخلته غير صحيح'**
  String get invalidOtp;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل خروج'**
  String get signOut;

  /// No description provided for @unknownErrorRetry.
  ///
  /// In ar, this message translates to:
  /// **'في حاجة غلط، جرّب تاني.'**
  String get unknownErrorRetry;

  /// No description provided for @chooseRoleTitle.
  ///
  /// In ar, this message translates to:
  /// **'انت مين؟'**
  String get chooseRoleTitle;

  /// No description provided for @roleHomeowner.
  ///
  /// In ar, this message translates to:
  /// **'صاحب شقة'**
  String get roleHomeowner;

  /// No description provided for @roleHomeownerSub.
  ///
  /// In ar, this message translates to:
  /// **'بدور على محترف يجدّد عندي'**
  String get roleHomeownerSub;

  /// No description provided for @roleProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف'**
  String get roleProfessional;

  /// No description provided for @roleContractorSub.
  ///
  /// In ar, this message translates to:
  /// **'بدور على شغل وعملاء جداد'**
  String get roleContractorSub;

  /// No description provided for @apartmentTypeTitle.
  ///
  /// In ar, this message translates to:
  /// **'شقتك نوعها إيه؟'**
  String get apartmentTypeTitle;

  /// No description provided for @apartmentStudio.
  ///
  /// In ar, this message translates to:
  /// **'استوديو'**
  String get apartmentStudio;

  /// No description provided for @apartmentOneBedroom.
  ///
  /// In ar, this message translates to:
  /// **'غرفة نوم'**
  String get apartmentOneBedroom;

  /// No description provided for @apartmentTwoBedroom.
  ///
  /// In ar, this message translates to:
  /// **'غرفتين نوم'**
  String get apartmentTwoBedroom;

  /// No description provided for @apartmentThreeBedroomPlus.
  ///
  /// In ar, this message translates to:
  /// **'٣ غرف أو أكتر'**
  String get apartmentThreeBedroomPlus;

  /// No description provided for @apartmentDuplex.
  ///
  /// In ar, this message translates to:
  /// **'دوبلكس'**
  String get apartmentDuplex;

  /// No description provided for @apartmentVilla.
  ///
  /// In ar, this message translates to:
  /// **'فيلا'**
  String get apartmentVilla;

  /// No description provided for @apartmentPenthouse.
  ///
  /// In ar, this message translates to:
  /// **'بنتهاوس'**
  String get apartmentPenthouse;

  /// No description provided for @locationTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكانك فين؟'**
  String get locationTitle;

  /// No description provided for @cityLabel.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get cityLabel;

  /// No description provided for @districtLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحي / المنطقة'**
  String get districtLabel;

  /// No description provided for @cityCairo.
  ///
  /// In ar, this message translates to:
  /// **'القاهرة'**
  String get cityCairo;

  /// No description provided for @cityGiza.
  ///
  /// In ar, this message translates to:
  /// **'الجيزة'**
  String get cityGiza;

  /// No description provided for @cityAlexandria.
  ///
  /// In ar, this message translates to:
  /// **'الإسكندرية'**
  String get cityAlexandria;

  /// No description provided for @cityNewCairo.
  ///
  /// In ar, this message translates to:
  /// **'القاهرة الجديدة'**
  String get cityNewCairo;

  /// No description provided for @city6October.
  ///
  /// In ar, this message translates to:
  /// **'٦ أكتوبر'**
  String get city6October;

  /// No description provided for @cityNorthCoast.
  ///
  /// In ar, this message translates to:
  /// **'الساحل الشمالي'**
  String get cityNorthCoast;

  /// No description provided for @interestsTitle.
  ///
  /// In ar, this message translates to:
  /// **'محتاج تجدّد إيه؟'**
  String get interestsTitle;

  /// No description provided for @interestsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار واحد أو أكتر'**
  String get interestsSubtitle;

  /// No description provided for @interestPaint.
  ///
  /// In ar, this message translates to:
  /// **'دهانات'**
  String get interestPaint;

  /// No description provided for @interestFlooring.
  ///
  /// In ar, this message translates to:
  /// **'أرضيات'**
  String get interestFlooring;

  /// No description provided for @interestKitchen.
  ///
  /// In ar, this message translates to:
  /// **'مطبخ'**
  String get interestKitchen;

  /// No description provided for @interestBathroom.
  ///
  /// In ar, this message translates to:
  /// **'حمام'**
  String get interestBathroom;

  /// No description provided for @interestElectrical.
  ///
  /// In ar, this message translates to:
  /// **'كهرباء'**
  String get interestElectrical;

  /// No description provided for @interestPlumbing.
  ///
  /// In ar, this message translates to:
  /// **'سباكة'**
  String get interestPlumbing;

  /// No description provided for @interestFullReno.
  ///
  /// In ar, this message translates to:
  /// **'تشطيب كامل'**
  String get interestFullReno;

  /// No description provided for @businessNameTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم شركتك أو نشاطك'**
  String get businessNameTitle;

  /// No description provided for @businessNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مقاولات الفنّان'**
  String get businessNameHint;

  /// No description provided for @displayNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم المسؤول'**
  String get displayNameLabel;

  /// No description provided for @specialtiesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصصاتك إيه؟'**
  String get specialtiesTitle;

  /// No description provided for @specialtiesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار كل اللي بتعمله'**
  String get specialtiesSubtitle;

  /// No description provided for @serviceAreasTitle.
  ///
  /// In ar, this message translates to:
  /// **'بتشتغل فين؟'**
  String get serviceAreasTitle;

  /// No description provided for @serviceAreasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار المحافظات اللي بتغطّيها'**
  String get serviceAreasSubtitle;

  /// No description provided for @logoUploadTitle.
  ///
  /// In ar, this message translates to:
  /// **'صورة أو لوجو لنشاطك'**
  String get logoUploadTitle;

  /// No description provided for @logoUploadHint.
  ///
  /// In ar, this message translates to:
  /// **'اختياري — تقدر تتخطّاه دلوقتي'**
  String get logoUploadHint;

  /// No description provided for @chooseImage.
  ///
  /// In ar, this message translates to:
  /// **'اختار صورة'**
  String get chooseImage;

  /// No description provided for @experienceTitle.
  ///
  /// In ar, this message translates to:
  /// **'سنين خبرتك ونبذة عنك'**
  String get experienceTitle;

  /// No description provided for @yearsExperience.
  ///
  /// In ar, this message translates to:
  /// **'سنين الخبرة'**
  String get yearsExperience;

  /// No description provided for @bioLabel.
  ///
  /// In ar, this message translates to:
  /// **'نبذة قصيرة'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In ar, this message translates to:
  /// **'احكي عن شغلك في سطرين أو ٣'**
  String get bioHint;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get save;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطّى'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get done;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريب…'**
  String get comingSoon;

  /// No description provided for @comingSoonM3.
  ///
  /// In ar, this message translates to:
  /// **'الميزة دي قيد التحضير'**
  String get comingSoonM3;

  /// No description provided for @optional.
  ///
  /// In ar, this message translates to:
  /// **'(اختياري)'**
  String get optional;

  /// No description provided for @tabDiscover.
  ///
  /// In ar, this message translates to:
  /// **'المحترفين'**
  String get tabDiscover;

  /// No description provided for @tabRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get tabRequests;

  /// No description provided for @tabSaved.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get tabSaved;

  /// No description provided for @tabProfile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabProfile;

  /// No description provided for @tabDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get tabDashboard;

  /// No description provided for @tabOpportunities.
  ///
  /// In ar, this message translates to:
  /// **'فرص شغل'**
  String get tabOpportunities;

  /// No description provided for @tabInbox.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get tabInbox;

  /// No description provided for @tabPortfolio.
  ///
  /// In ar, this message translates to:
  /// **'أعمالي'**
  String get tabPortfolio;

  /// No description provided for @tabExplore.
  ///
  /// In ar, this message translates to:
  /// **'أعمال'**
  String get tabExplore;

  /// No description provided for @exploreTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعمال'**
  String get exploreTitle;

  /// No description provided for @createPost.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منشور'**
  String get createPost;

  /// No description provided for @editPost.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنشور'**
  String get editPost;

  /// No description provided for @deletePost.
  ///
  /// In ar, this message translates to:
  /// **'حذف المنشور'**
  String get deletePost;

  /// No description provided for @postCaptionHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تعليق...'**
  String get postCaptionHint;

  /// No description provided for @postCaptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get postCaptionLabel;

  /// No description provided for @addMedia.
  ///
  /// In ar, this message translates to:
  /// **'أضف صور'**
  String get addMedia;

  /// No description provided for @postTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع المنشور'**
  String get postTypeLabel;

  /// No description provided for @postTypeProjectShowcase.
  ///
  /// In ar, this message translates to:
  /// **'عرض مشروع'**
  String get postTypeProjectShowcase;

  /// No description provided for @postTypeTip.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة'**
  String get postTypeTip;

  /// No description provided for @postTypeMilestone.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز'**
  String get postTypeMilestone;

  /// No description provided for @postTypeRenovationUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get postTypeRenovationUpdate;

  /// No description provided for @postCategoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get postCategoryLabel;

  /// No description provided for @postLinkPortfolio.
  ///
  /// In ar, this message translates to:
  /// **'اربط بمشروع في أعمالك'**
  String get postLinkPortfolio;

  /// No description provided for @sharePost.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get sharePost;

  /// No description provided for @likeLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب'**
  String get likeLabel;

  /// No description provided for @commentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get commentLabel;

  /// No description provided for @saveLabel.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveLabel;

  /// No description provided for @commentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get commentsTitle;

  /// No description provided for @commentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تعليق...'**
  String get commentHint;

  /// No description provided for @postComment.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get postComment;

  /// No description provided for @noComments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تعليقات بعد'**
  String get noComments;

  /// No description provided for @noPostsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات بعد'**
  String get noPostsYet;

  /// No description provided for @noPostsYetSub.
  ///
  /// In ar, this message translates to:
  /// **'كن أول من ينشر في الاستكشف!'**
  String get noPostsYetSub;

  /// No description provided for @myPosts.
  ///
  /// In ar, this message translates to:
  /// **'منشوراتي'**
  String get myPosts;

  /// No description provided for @savedPosts.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات المحفوظة'**
  String get savedPosts;

  /// No description provided for @myPostsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'معندكش منشورات'**
  String get myPostsEmpty;

  /// No description provided for @savedPostsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'ما حفظتش منشورات'**
  String get savedPostsEmpty;

  /// No description provided for @postUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المنشور مش موجود'**
  String get postUnavailable;

  /// No description provided for @postCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر المنشور'**
  String get postCreated;

  /// No description provided for @postDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المنشور'**
  String get postDeleted;

  /// No description provided for @commentPosted.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر التعليق'**
  String get commentPosted;

  /// No description provided for @commentRateLimitError.
  ///
  /// In ar, this message translates to:
  /// **'بتعلق بسرعة! استنى شوية'**
  String get commentRateLimitError;

  /// No description provided for @captionRequired.
  ///
  /// In ar, this message translates to:
  /// **'الوصف مطلوب'**
  String get captionRequired;

  /// No description provided for @photoCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الصور: %s'**
  String get photoCount;

  /// No description provided for @agoNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get agoNow;

  /// No description provided for @agoMin.
  ///
  /// In ar, this message translates to:
  /// **'منذ دقيقة'**
  String get agoMin;

  /// No description provided for @agoMins.
  ///
  /// In ar, this message translates to:
  /// **'منذ %s دقائق'**
  String get agoMins;

  /// No description provided for @agoHour.
  ///
  /// In ar, this message translates to:
  /// **'منذ ساعة'**
  String get agoHour;

  /// No description provided for @agoHours.
  ///
  /// In ar, this message translates to:
  /// **'منذ %s ساعات'**
  String get agoHours;

  /// No description provided for @agoDay.
  ///
  /// In ar, this message translates to:
  /// **'منذ يوم'**
  String get agoDay;

  /// No description provided for @agoDays.
  ///
  /// In ar, this message translates to:
  /// **'منذ %s أيام'**
  String get agoDays;

  /// No description provided for @quotesSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'عروض الأسعار'**
  String get quotesSectionTitle;

  /// No description provided for @sendQuote.
  ///
  /// In ar, this message translates to:
  /// **'أرسل عرض سعر'**
  String get sendQuote;

  /// No description provided for @yourQuote.
  ///
  /// In ar, this message translates to:
  /// **'عرضك الحالي'**
  String get yourQuote;

  /// No description provided for @editQuote.
  ///
  /// In ar, this message translates to:
  /// **'عدّل العرض'**
  String get editQuote;

  /// No description provided for @submitQuote.
  ///
  /// In ar, this message translates to:
  /// **'ابعت العرض'**
  String get submitQuote;

  /// No description provided for @quoteSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت العرض بنجاح'**
  String get quoteSentSuccess;

  /// No description provided for @priceFromLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر من'**
  String get priceFromLabel;

  /// No description provided for @priceToLabel.
  ///
  /// In ar, this message translates to:
  /// **'لـ'**
  String get priceToLabel;

  /// No description provided for @priceEgpHint.
  ///
  /// In ar, this message translates to:
  /// **'بالجنيه'**
  String get priceEgpHint;

  /// No description provided for @priceOnRequest.
  ///
  /// In ar, this message translates to:
  /// **'السعر حسب المعاينة'**
  String get priceOnRequest;

  /// No description provided for @fixedPriceLabel.
  ///
  /// In ar, this message translates to:
  /// **'سعر ثابت'**
  String get fixedPriceLabel;

  /// No description provided for @durationLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدة المتوقعة'**
  String get durationLabel;

  /// No description provided for @durationHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: أسبوعين'**
  String get durationHint;

  /// No description provided for @quoteNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العرض'**
  String get quoteNoteLabel;

  /// No description provided for @quoteNoteRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم تكتب تفاصيل العرض'**
  String get quoteNoteRequired;

  /// No description provided for @egpUnit.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get egpUnit;

  /// No description provided for @quoteAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get quoteAccept;

  /// No description provided for @quoteDecline.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get quoteDecline;

  /// No description provided for @quoteAcceptConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تقبل العرض ده؟'**
  String get quoteAcceptConfirm;

  /// No description provided for @quoteDeclineConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ترفض العرض ده؟'**
  String get quoteDeclineConfirm;

  /// No description provided for @quoteStatusSent.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار الرد'**
  String get quoteStatusSent;

  /// No description provided for @quoteStatusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get quoteStatusAccepted;

  /// No description provided for @quoteStatusDeclined.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get quoteStatusDeclined;

  /// No description provided for @quoteStatusWithdrawn.
  ///
  /// In ar, this message translates to:
  /// **'مسحوب'**
  String get quoteStatusWithdrawn;

  /// No description provided for @noQuoteBadge.
  ///
  /// In ar, this message translates to:
  /// **'محتاج رد'**
  String get noQuoteBadge;

  /// No description provided for @noQuotesYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش عروض على الطلب ده'**
  String get noQuotesYet;

  /// No description provided for @viewContractorProfile.
  ///
  /// In ar, this message translates to:
  /// **'شوف الملف'**
  String get viewContractorProfile;

  /// No description provided for @proPlanName.
  ///
  /// In ar, this message translates to:
  /// **'برو'**
  String get proPlanName;

  /// No description provided for @freePlanName.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get freePlanName;

  /// No description provided for @paywallTitle.
  ///
  /// In ar, this message translates to:
  /// **'باقة برو'**
  String get paywallTitle;

  /// No description provided for @proRequiredToQuoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'اشترك في برو عشان تبعت عروض'**
  String get proRequiredToQuoteTitle;

  /// No description provided for @proBenefitQuotes.
  ///
  /// In ar, this message translates to:
  /// **'عروض أسعار غير محدودة'**
  String get proBenefitQuotes;

  /// No description provided for @proBenefitRanking.
  ///
  /// In ar, this message translates to:
  /// **'ظهور أعلى في نتائج البحث'**
  String get proBenefitRanking;

  /// No description provided for @proBenefitPhotos.
  ///
  /// In ar, this message translates to:
  /// **'صور أعمال أكتر في معرضك'**
  String get proBenefitPhotos;

  /// No description provided for @upgradeToProCta.
  ///
  /// In ar, this message translates to:
  /// **'اشترك دلوقتي'**
  String get upgradeToProCta;

  /// No description provided for @upgradeToProShort.
  ///
  /// In ar, this message translates to:
  /// **'اشترك في برو'**
  String get upgradeToProShort;

  /// No description provided for @perMonth.
  ///
  /// In ar, this message translates to:
  /// **'/ شهر'**
  String get perMonth;

  /// No description provided for @paymentComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'الدفع هيكون متاح قريب جداً.'**
  String get paymentComingSoon;

  /// No description provided for @currentPlanLabel.
  ///
  /// In ar, this message translates to:
  /// **'باقتك الحالية'**
  String get currentPlanLabel;

  /// No description provided for @previewPublicProfile.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الملف'**
  String get previewPublicProfile;

  /// No description provided for @memberSinceLabel.
  ///
  /// In ar, this message translates to:
  /// **'عضو منذ'**
  String get memberSinceLabel;

  /// No description provided for @proActiveLine.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك برو مفعّل'**
  String get proActiveLine;

  /// No description provided for @tierGold.
  ///
  /// In ar, this message translates to:
  /// **'ذهبي'**
  String get tierGold;

  /// No description provided for @tierSilver.
  ///
  /// In ar, this message translates to:
  /// **'فضي'**
  String get tierSilver;

  /// No description provided for @tierBronze.
  ///
  /// In ar, this message translates to:
  /// **'برونزي'**
  String get tierBronze;

  /// No description provided for @tierLevelPrefix.
  ///
  /// In ar, this message translates to:
  /// **'مستوى'**
  String get tierLevelPrefix;

  /// No description provided for @tierHowTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزاي بتتحسب المستويات؟'**
  String get tierHowTitle;

  /// No description provided for @trustSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'ليه تثق في المحترف ده؟'**
  String get trustSectionTitle;

  /// No description provided for @verifiedIdentity.
  ///
  /// In ar, this message translates to:
  /// **'هوية موثّقة'**
  String get verifiedIdentity;

  /// No description provided for @verifiedBusiness.
  ///
  /// In ar, this message translates to:
  /// **'نشاط تجاري موثّق'**
  String get verifiedBusiness;

  /// No description provided for @highlightTopRated.
  ///
  /// In ar, this message translates to:
  /// **'الأعلى تقييماً'**
  String get highlightTopRated;

  /// No description provided for @highlightRecommended.
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get highlightRecommended;

  /// No description provided for @highlightEstablished.
  ///
  /// In ar, this message translates to:
  /// **'سجل أعمال طويل'**
  String get highlightEstablished;

  /// No description provided for @responseTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الرد'**
  String get responseTimeLabel;

  /// No description provided for @completionRateLabel.
  ///
  /// In ar, this message translates to:
  /// **'نسبة إنجاز المشاريع'**
  String get completionRateLabel;

  /// No description provided for @withinMinutes.
  ///
  /// In ar, this message translates to:
  /// **'خلال {n} دقيقة'**
  String withinMinutes(int n);

  /// No description provided for @withinHours.
  ///
  /// In ar, this message translates to:
  /// **'خلال {n} ساعة'**
  String withinHours(int n);

  /// No description provided for @withinDays.
  ///
  /// In ar, this message translates to:
  /// **'خلال {n} يوم'**
  String withinDays(int n);

  /// No description provided for @reviewVerifiedChip.
  ///
  /// In ar, this message translates to:
  /// **'تقييم موثّق'**
  String get reviewVerifiedChip;

  /// No description provided for @ratingBreakdownTitle.
  ///
  /// In ar, this message translates to:
  /// **'توزيع التقييمات'**
  String get ratingBreakdownTitle;

  /// No description provided for @reviewsBasedOn.
  ///
  /// In ar, this message translates to:
  /// **'محسوبة من آخر {n} تقييم'**
  String reviewsBasedOn(int n);

  /// No description provided for @reviewSortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get reviewSortNewest;

  /// No description provided for @reviewSortHighest.
  ///
  /// In ar, this message translates to:
  /// **'الأعلى'**
  String get reviewSortHighest;

  /// No description provided for @reviewSortLowest.
  ///
  /// In ar, this message translates to:
  /// **'الأقل'**
  String get reviewSortLowest;

  /// No description provided for @reviewFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get reviewFilterAll;

  /// No description provided for @reviewFilterWithText.
  ///
  /// In ar, this message translates to:
  /// **'فيها تعليق'**
  String get reviewFilterWithText;

  /// No description provided for @reviewFilterWithPhotos.
  ///
  /// In ar, this message translates to:
  /// **'فيها صور'**
  String get reviewFilterWithPhotos;

  /// No description provided for @reviewsNoMatch.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تقييمات بالفلتر ده'**
  String get reviewsNoMatch;

  /// No description provided for @reviewsClearFilter.
  ///
  /// In ar, this message translates to:
  /// **'امسح الفلتر'**
  String get reviewsClearFilter;

  /// No description provided for @ratingOutOfFive.
  ///
  /// In ar, this message translates to:
  /// **'من ٥'**
  String get ratingOutOfFive;

  /// No description provided for @projectDurationLabel.
  ///
  /// In ar, this message translates to:
  /// **'مدة التنفيذ'**
  String get projectDurationLabel;

  /// No description provided for @projectDurationMonths.
  ///
  /// In ar, this message translates to:
  /// **'{n} شهر'**
  String projectDurationMonths(int n);

  /// No description provided for @accountWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك'**
  String get accountWelcome;

  /// No description provided for @ratingCaption.
  ///
  /// In ar, this message translates to:
  /// **'تقييم العملاء'**
  String get ratingCaption;

  /// No description provided for @statJobs.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأعمال'**
  String get statJobs;

  /// No description provided for @statLevel.
  ///
  /// In ar, this message translates to:
  /// **'مستوى'**
  String get statLevel;

  /// No description provided for @proBannerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مميزات حصرية تنمّي شغلك'**
  String get proBannerSubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والدعم'**
  String get helpSupport;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مظهر داكن مريح للعين'**
  String get darkModeSubtitle;

  /// No description provided for @verifySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكسب علامة موثّق الذهبية'**
  String get verifySubtitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'العربية أو الإنجليزية'**
  String get languageSubtitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كلّمنا على واتساب'**
  String get helpSubtitle;

  /// No description provided for @verifyTileLabel.
  ///
  /// In ar, this message translates to:
  /// **'توثيق الحساب'**
  String get verifyTileLabel;

  /// No description provided for @verifyStateVerified.
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get verifyStateVerified;

  /// No description provided for @verifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'توثيق الحساب'**
  String get verifyTitle;

  /// No description provided for @verifyBenefitTrust.
  ///
  /// In ar, this message translates to:
  /// **'علامة موثّق ذهبية على ملفك'**
  String get verifyBenefitTrust;

  /// No description provided for @verifyBenefitRanking.
  ///
  /// In ar, this message translates to:
  /// **'ظهور أعلى في نتائج البحث'**
  String get verifyBenefitRanking;

  /// No description provided for @verifyBenefitFree.
  ///
  /// In ar, this message translates to:
  /// **'مجاني تماماً، مرة واحدة'**
  String get verifyBenefitFree;

  /// No description provided for @verifyUploadLabel.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صور المستندات'**
  String get verifyUploadLabel;

  /// No description provided for @verifyNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get verifyNoteLabel;

  /// No description provided for @verifySubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال للمراجعة'**
  String get verifySubmit;

  /// No description provided for @verifyDocsRequired.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صورة مستند واحدة على الأقل'**
  String get verifyDocsRequired;

  /// No description provided for @verifyError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الإرسال، حاول تاني'**
  String get verifyError;

  /// No description provided for @verifyPendingTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبك قيد المراجعة'**
  String get verifyPendingTitle;

  /// No description provided for @verifyApprovedTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابك موثّق'**
  String get verifyApprovedTitle;

  /// No description provided for @verifyDone.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get verifyDone;

  /// No description provided for @proScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'شطب برو'**
  String get proScreenTitle;

  /// No description provided for @planMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get planMonthly;

  /// No description provided for @planAnnual.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get planAnnual;

  /// No description provided for @annualSaveBadge.
  ///
  /// In ar, this message translates to:
  /// **'وفّر شهرين'**
  String get annualSaveBadge;

  /// No description provided for @perYear.
  ///
  /// In ar, this message translates to:
  /// **'/ سنة'**
  String get perYear;

  /// No description provided for @startFreeMonth.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ شهر مجاني'**
  String get startFreeMonth;

  /// No description provided for @cancelAnytime.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تلغي في أي وقت'**
  String get cancelAnytime;

  /// No description provided for @proBenefitSeen.
  ///
  /// In ar, this message translates to:
  /// **'إشعار لما العميل يشوف عرضك'**
  String get proBenefitSeen;

  /// No description provided for @trustPaymob.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عن طريق Paymob · آمن'**
  String get trustPaymob;

  /// No description provided for @comparePlans.
  ///
  /// In ar, this message translates to:
  /// **'المجاني وبرو'**
  String get comparePlans;

  /// No description provided for @cmpQuotes.
  ///
  /// In ar, this message translates to:
  /// **'عروض الأسعار'**
  String get cmpQuotes;

  /// No description provided for @cmpQuotesFree.
  ///
  /// In ar, this message translates to:
  /// **'٣ في الشهر'**
  String get cmpQuotesFree;

  /// No description provided for @cmpUnlimited.
  ///
  /// In ar, this message translates to:
  /// **'بلا حدود'**
  String get cmpUnlimited;

  /// No description provided for @cmpRequests.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المباشرة'**
  String get cmpRequests;

  /// No description provided for @cmpRequestsFree.
  ///
  /// In ar, this message translates to:
  /// **'قراءة بس'**
  String get cmpRequestsFree;

  /// No description provided for @cmpRequestsPro.
  ///
  /// In ar, this message translates to:
  /// **'ردّ وابعت عرض'**
  String get cmpRequestsPro;

  /// No description provided for @cmpRanking.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب في البحث'**
  String get cmpRanking;

  /// No description provided for @cmpRankingFree.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get cmpRankingFree;

  /// No description provided for @cmpRankingPro.
  ///
  /// In ar, this message translates to:
  /// **'أعلى'**
  String get cmpRankingPro;

  /// No description provided for @cmpPortfolio.
  ///
  /// In ar, this message translates to:
  /// **'معرض الأعمال'**
  String get cmpPortfolio;

  /// No description provided for @cmpPortfolioFree.
  ///
  /// In ar, this message translates to:
  /// **'٥ أعمال'**
  String get cmpPortfolioFree;

  /// No description provided for @cmpSeenRow.
  ///
  /// In ar, this message translates to:
  /// **'إشعار «شاف عرضك»'**
  String get cmpSeenRow;

  /// No description provided for @proExpiresOn.
  ///
  /// In ar, this message translates to:
  /// **'بينتهي في {date}'**
  String proExpiresOn(String date);

  /// No description provided for @choosePaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'اختار طريقة الدفع'**
  String get choosePaymentMethod;

  /// No description provided for @payInstapay.
  ///
  /// In ar, this message translates to:
  /// **'انستا باي'**
  String get payInstapay;

  /// No description provided for @payApplePay.
  ///
  /// In ar, this message translates to:
  /// **'Apple Pay'**
  String get payApplePay;

  /// No description provided for @paySoonBadge.
  ///
  /// In ar, this message translates to:
  /// **'قريب'**
  String get paySoonBadge;

  /// No description provided for @payApplePaySub.
  ///
  /// In ar, this message translates to:
  /// **'بالبطاقة أو المحفظة — قريب'**
  String get payApplePaySub;

  /// No description provided for @instapayTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عن طريق انستا باي'**
  String get instapayTitle;

  /// No description provided for @instapayAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المطلوب'**
  String get instapayAmountLabel;

  /// No description provided for @instapayNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'حوّل على رقم انستا باي ده'**
  String get instapayNumberLabel;

  /// No description provided for @copyAction.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copyAction;

  /// No description provided for @copiedToast.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ'**
  String get copiedToast;

  /// No description provided for @instapayUploadLabel.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صورة التحويل'**
  String get instapayUploadLabel;

  /// No description provided for @instapayRefLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم العملية (اختياري)'**
  String get instapayRefLabel;

  /// No description provided for @instapaySubmit.
  ///
  /// In ar, this message translates to:
  /// **'ابعت للتأكيد'**
  String get instapaySubmit;

  /// No description provided for @instapayProofRequired.
  ///
  /// In ar, this message translates to:
  /// **'ارفع صورة التحويل الأول'**
  String get instapayProofRequired;

  /// No description provided for @instapaySubmittedTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبك تحت المراجعة'**
  String get instapaySubmittedTitle;

  /// No description provided for @instapayDone.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get instapayDone;

  /// No description provided for @instapayError.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ، حاول تاني'**
  String get instapayError;

  /// No description provided for @applePaySoon.
  ///
  /// In ar, this message translates to:
  /// **'Apple Pay هيكون متاح قريب'**
  String get applePaySoon;

  /// No description provided for @inboxTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المباشرة'**
  String get inboxTitle;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طلبات مباشرة'**
  String get inboxEmptyTitle;

  /// No description provided for @requestDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get requestDetailTitle;

  /// No description provided for @contactClient.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع العميل'**
  String get contactClient;

  /// No description provided for @myPortfolioTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعمالي'**
  String get myPortfolioTitle;

  /// No description provided for @addWork.
  ///
  /// In ar, this message translates to:
  /// **'أضف عمل'**
  String get addWork;

  /// No description provided for @newWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمل جديد'**
  String get newWorkTitle;

  /// No description provided for @editWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العمل'**
  String get editWorkTitle;

  /// No description provided for @portfolioEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مضفتش أعمال'**
  String get portfolioEmptyTitle;

  /// No description provided for @workTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان العمل'**
  String get workTitleLabel;

  /// No description provided for @workCategoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get workCategoryLabel;

  /// No description provided for @workCategoryHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تشطيب كامل'**
  String get workCategoryHint;

  /// No description provided for @workYearLabel.
  ///
  /// In ar, this message translates to:
  /// **'سنة التنفيذ'**
  String get workYearLabel;

  /// No description provided for @workYearHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 2025'**
  String get workYearHint;

  /// No description provided for @workLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get workLocationLabel;

  /// No description provided for @workLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: القاهرة الجديدة'**
  String get workLocationHint;

  /// No description provided for @workDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get workDescriptionLabel;

  /// No description provided for @workDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب نبذة قصيرة عن العمل'**
  String get workDescriptionHint;

  /// No description provided for @coverPhotoHint.
  ///
  /// In ar, this message translates to:
  /// **'أول صورة هتكون صورة الغلاف'**
  String get coverPhotoHint;

  /// No description provided for @saveWork.
  ///
  /// In ar, this message translates to:
  /// **'احفظ العمل'**
  String get saveWork;

  /// No description provided for @deleteWork.
  ///
  /// In ar, this message translates to:
  /// **'حذف العمل'**
  String get deleteWork;

  /// No description provided for @titleRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم تكتب عنوان للعمل'**
  String get titleRequired;

  /// No description provided for @coverRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم تضيف صورة واحدة على الأقل'**
  String get coverRequired;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن محترف أو شركة…'**
  String get searchHint;

  /// No description provided for @featuredContractors.
  ///
  /// In ar, this message translates to:
  /// **'محترفين مميزين'**
  String get featuredContractors;

  /// No description provided for @topRated.
  ///
  /// In ar, this message translates to:
  /// **'الأعلى تقييمًا'**
  String get topRated;

  /// No description provided for @recentWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعمال حديثة'**
  String get recentWorkTitle;

  /// No description provided for @nearYou.
  ///
  /// In ar, this message translates to:
  /// **'قريبين منك'**
  String get nearYou;

  /// No description provided for @nearYouIn.
  ///
  /// In ar, this message translates to:
  /// **'قريبين منك في {city}'**
  String nearYouIn(String city);

  /// No description provided for @browseByCategory.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح بالتخصص'**
  String get browseByCategory;

  /// No description provided for @trendingNearYou.
  ///
  /// In ar, this message translates to:
  /// **'رائج بالقرب منك'**
  String get trendingNearYou;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @verified.
  ///
  /// In ar, this message translates to:
  /// **'موثوق'**
  String get verified;

  /// No description provided for @allProfessionals.
  ///
  /// In ar, this message translates to:
  /// **'كل المحترفين'**
  String get allProfessionals;

  /// No description provided for @noContractorsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش محترفين بالشروط دي'**
  String get noContractorsTitle;

  /// No description provided for @noContractorsMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تغيّر التخصص أو المحافظة'**
  String get noContractorsMessage;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get editProfile;

  /// No description provided for @profileNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get profileNameLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم التليفون'**
  String get profilePhoneLabel;

  /// No description provided for @phoneNotEditable.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغيير رقم التليفون'**
  String get phoneNotEditable;

  /// No description provided for @changePhoto.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتغيير الصورة'**
  String get changePhoto;

  /// No description provided for @housingData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات السكن'**
  String get housingData;

  /// No description provided for @interestAreas.
  ///
  /// In ar, this message translates to:
  /// **'مجالات الاهتمام'**
  String get interestAreas;

  /// No description provided for @nameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get nameRequired;

  /// No description provided for @saveProfile.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملف الشخصي'**
  String get profileSaved;

  /// No description provided for @profileError.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ، حاول تاني'**
  String get profileError;

  /// No description provided for @selectCity.
  ///
  /// In ar, this message translates to:
  /// **'اختار المحافظة'**
  String get selectCity;

  /// No description provided for @selectDistrict.
  ///
  /// In ar, this message translates to:
  /// **'اختار المنطقة'**
  String get selectDistrict;

  /// No description provided for @editProfileButton.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف'**
  String get editProfileButton;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسنًا'**
  String get ok;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// No description provided for @signOutButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOutButton;

  /// No description provided for @signOutTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تسجيل الخروج'**
  String get signOutTitle;

  /// No description provided for @signOutConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'متأكد إنك عايز تسجل خروج؟'**
  String get signOutConfirmation;

  /// No description provided for @myRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myRequests;

  /// No description provided for @mySaved.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get mySaved;

  /// No description provided for @discoverContractors.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف المحترفين'**
  String get discoverContractors;

  /// No description provided for @darkModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get darkModeTitle;

  /// No description provided for @lightModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get lightModeTitle;

  /// No description provided for @motionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحركة'**
  String get motionLabel;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get lightMode;

  /// No description provided for @languageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageTitle;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get languageEnglish;

  /// No description provided for @briefDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get briefDetailTitle;

  /// No description provided for @cancelBriefTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب؟'**
  String get cancelBriefTitle;

  /// No description provided for @cancelBriefNo.
  ///
  /// In ar, this message translates to:
  /// **'لأ، خليه'**
  String get cancelBriefNo;

  /// No description provided for @cancelBriefYes.
  ///
  /// In ar, this message translates to:
  /// **'أيوة، إلغي'**
  String get cancelBriefYes;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelButton;

  /// No description provided for @briefNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الطلب مش موجود'**
  String get briefNotFound;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get tryAgain;

  /// No description provided for @locationDetailsLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المكان'**
  String get locationDetailsLabel;

  /// No description provided for @lookingForLabel.
  ///
  /// In ar, this message translates to:
  /// **'بدور على'**
  String get lookingForLabel;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @statusPost.
  ///
  /// In ar, this message translates to:
  /// **'بوست عام'**
  String get statusPost;

  /// No description provided for @statusDirectRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب مباشر'**
  String get statusDirectRequest;

  /// No description provided for @briefSentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك!'**
  String get briefSentTitle;

  /// No description provided for @doneBackToDiscover.
  ///
  /// In ar, this message translates to:
  /// **'تمام، رجوع للاكتشاف'**
  String get doneBackToDiscover;

  /// No description provided for @briefSentWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع المحترف على واتساب'**
  String get briefSentWhatsApp;

  /// No description provided for @briefSentCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بالمحترف'**
  String get briefSentCall;

  /// No description provided for @briefSentBackToRequests.
  ///
  /// In ar, this message translates to:
  /// **'رجوع لطلباتي'**
  String get briefSentBackToRequests;

  /// No description provided for @createPostTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمل بوست جديد'**
  String get createPostTitle;

  /// No description provided for @workTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الشغل'**
  String get workTypeLabel;

  /// No description provided for @workTypeHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تشطيب حمام'**
  String get workTypeHint;

  /// No description provided for @apartmentTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوحدة'**
  String get apartmentTypeLabel;

  /// No description provided for @budgetLabel.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية التقريبية (اختياري)'**
  String get budgetLabel;

  /// No description provided for @budgetHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: ٥٠٠٠٠'**
  String get budgetHint;

  /// No description provided for @timelineLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموعد المقترح'**
  String get timelineLabel;

  /// No description provided for @timelineHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: خلال أسبوعين'**
  String get timelineHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الشغل'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب أي تفاصيل تانية...'**
  String get descriptionHint;

  /// No description provided for @photosLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصور (اختياري)'**
  String get photosLabel;

  /// No description provided for @createPostButton.
  ///
  /// In ar, this message translates to:
  /// **'انشر البوستر'**
  String get createPostButton;

  /// No description provided for @writeWhatYouNeed.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اللي محتاجه'**
  String get writeWhatYouNeed;

  /// No description provided for @sectionLookingForWho.
  ///
  /// In ar, this message translates to:
  /// **'بدور على مين؟'**
  String get sectionLookingForWho;

  /// No description provided for @errorWriteMoreDetails.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تفاصيل أكتر'**
  String get errorWriteMoreDetails;

  /// No description provided for @errorFillApartmentCity.
  ///
  /// In ar, this message translates to:
  /// **'املا نوع الشقة والمحافظة'**
  String get errorFillApartmentCity;

  /// No description provided for @errorSelectSpecialty.
  ///
  /// In ar, this message translates to:
  /// **'اختار تخصص أو أكتر'**
  String get errorSelectSpecialty;

  /// No description provided for @sendBriefTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابعث طلب مباشر'**
  String get sendBriefTitle;

  /// No description provided for @sendBriefDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الشغل'**
  String get sendBriefDescriptionLabel;

  /// No description provided for @sendBriefPhotosLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصور (اختياري)'**
  String get sendBriefPhotosLabel;

  /// No description provided for @sendBriefButton.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الطلب'**
  String get sendBriefButton;

  /// No description provided for @sendBriefDefaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابعت تفاصيل المشروع'**
  String get sendBriefDefaultTitle;

  /// No description provided for @sendBriefProjectDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل مشروعك'**
  String get sendBriefProjectDetails;

  /// No description provided for @sendBriefWorkDescLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصف الشغل المطلوب'**
  String get sendBriefWorkDescLabel;

  /// No description provided for @sendBriefWorkDescHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: محتاج تشطيب كامل…'**
  String get sendBriefWorkDescHint;

  /// No description provided for @myBriefsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myBriefsTitle;

  /// No description provided for @newPostButton.
  ///
  /// In ar, this message translates to:
  /// **'بوست جديد'**
  String get newPostButton;

  /// No description provided for @noBriefsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طلبات لسه'**
  String get noBriefsTitle;

  /// No description provided for @createNewPostButton.
  ///
  /// In ar, this message translates to:
  /// **'اعمل بوست جديد'**
  String get createNewPostButton;

  /// No description provided for @noBriefsHere.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة هنا لسه'**
  String get noBriefsHere;

  /// No description provided for @sectionOpenPosts.
  ///
  /// In ar, this message translates to:
  /// **'بوستات مفتوحة'**
  String get sectionOpenPosts;

  /// No description provided for @sectionDirectRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مباشرة'**
  String get sectionDirectRequests;

  /// No description provided for @opportunitiesTitle.
  ///
  /// In ar, this message translates to:
  /// **'فرص شغل'**
  String get opportunitiesTitle;

  /// No description provided for @noPostsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش بوستات دلوقتي'**
  String get noPostsTitle;

  /// No description provided for @postDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل البوستر'**
  String get postDetailTitle;

  /// No description provided for @postDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الشغل'**
  String get postDescriptionLabel;

  /// No description provided for @postLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get postLocationLabel;

  /// No description provided for @homeownerLabel.
  ///
  /// In ar, this message translates to:
  /// **'صاحب البوستر'**
  String get homeownerLabel;

  /// No description provided for @contactHomeowner.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع صاحب البوستر'**
  String get contactHomeowner;

  /// No description provided for @sendQuoteButton.
  ///
  /// In ar, this message translates to:
  /// **'أرسل عرض سعر'**
  String get sendQuoteButton;

  /// No description provided for @yourQuoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرضك الحالي'**
  String get yourQuoteLabel;

  /// No description provided for @postNotFound.
  ///
  /// In ar, this message translates to:
  /// **'البوست مش موجود'**
  String get postNotFound;

  /// No description provided for @postDetailPostedPrefix.
  ///
  /// In ar, this message translates to:
  /// **'اتنشر: '**
  String get postDetailPostedPrefix;

  /// No description provided for @clientInfoFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات العميل'**
  String get clientInfoFailed;

  /// No description provided for @sendQuoteCTA.
  ///
  /// In ar, this message translates to:
  /// **'أرسل عرض سعر'**
  String get sendQuoteCTA;

  /// No description provided for @portfolioGalleryTitle.
  ///
  /// In ar, this message translates to:
  /// **'معرض الأعمال'**
  String get portfolioGalleryTitle;

  /// No description provided for @noWorksTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أعمال متضافة لسه'**
  String get noWorksTitle;

  /// No description provided for @projectDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العمل'**
  String get projectDetailTitle;

  /// No description provided for @projectCategoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get projectCategoryLabel;

  /// No description provided for @projectYearLabel.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get projectYearLabel;

  /// No description provided for @projectLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get projectLocationLabel;

  /// No description provided for @projectDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get projectDescriptionLabel;

  /// No description provided for @projectNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العمل مش موجود'**
  String get projectNotFound;

  /// No description provided for @contractorProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف المحترف'**
  String get contractorProfileTitle;

  /// No description provided for @ratingLabel.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get ratingLabel;

  /// No description provided for @reviewsCount.
  ///
  /// In ar, this message translates to:
  /// **'تقييم'**
  String get reviewsCount;

  /// No description provided for @specialtiesLabel.
  ///
  /// In ar, this message translates to:
  /// **'التخصصات'**
  String get specialtiesLabel;

  /// No description provided for @serviceAreasLabel.
  ///
  /// In ar, this message translates to:
  /// **'مناطق الخدمة'**
  String get serviceAreasLabel;

  /// No description provided for @saveContractor.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get saveContractor;

  /// No description provided for @savedContractor.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ'**
  String get savedContractor;

  /// No description provided for @sendBriefCTA.
  ///
  /// In ar, this message translates to:
  /// **'ابعث طلب'**
  String get sendBriefCTA;

  /// No description provided for @viewPortfolio.
  ///
  /// In ar, this message translates to:
  /// **'شوف الأعمال'**
  String get viewPortfolio;

  /// No description provided for @writeReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تقييم'**
  String get writeReviewTitle;

  /// No description provided for @reviewTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التقييم'**
  String get reviewTitleLabel;

  /// No description provided for @reviewTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: شغل ممتاز'**
  String get reviewTitleHint;

  /// No description provided for @reviewBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get reviewBodyLabel;

  /// No description provided for @reviewBodyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تجربتك مع المحترف...'**
  String get reviewBodyHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In ar, this message translates to:
  /// **'انشر التقييم'**
  String get reviewSubmit;

  /// No description provided for @reviewRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم تكتب عنوان وتفاصيل'**
  String get reviewRequired;

  /// No description provided for @reviewSuccess.
  ///
  /// In ar, this message translates to:
  /// **'اتباع التقييم بنجاح'**
  String get reviewSuccess;

  /// No description provided for @rateContractor.
  ///
  /// In ar, this message translates to:
  /// **'قيّم المحترف'**
  String get rateContractor;

  /// No description provided for @yourReview.
  ///
  /// In ar, this message translates to:
  /// **'رأيك (اختياري)'**
  String get yourReview;

  /// No description provided for @yourReviewHint.
  ///
  /// In ar, this message translates to:
  /// **'احكي تجربتك مع المحترف'**
  String get yourReviewHint;

  /// No description provided for @submitReview.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التقييم'**
  String get submitReview;

  /// No description provided for @selectStarsFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختار تقييم بالنجوم الأول'**
  String get selectStarsFirst;

  /// No description provided for @editReview.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editReview;

  /// No description provided for @ratingHelpsOthers.
  ///
  /// In ar, this message translates to:
  /// **'تقييمك بيساعد باقي العملاء'**
  String get ratingHelpsOthers;

  /// No description provided for @contactViaWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'تواصل عبر واتساب'**
  String get contactViaWhatsApp;

  /// No description provided for @call.
  ///
  /// In ar, this message translates to:
  /// **'اتصل'**
  String get call;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'تليفون'**
  String get phone;

  /// No description provided for @createPostPublishButton.
  ///
  /// In ar, this message translates to:
  /// **'انشر البوست'**
  String get createPostPublishButton;

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingEvening;

  /// No description provided for @newJobs.
  ///
  /// In ar, this message translates to:
  /// **'فرص عمل جديدة'**
  String get newJobs;

  /// No description provided for @searchJobs.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن فرصة عمل...'**
  String get searchJobs;

  /// No description provided for @filterToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get filterToday;

  /// No description provided for @filterNearest.
  ///
  /// In ar, this message translates to:
  /// **'الأقرب'**
  String get filterNearest;

  /// No description provided for @filterHighestBudget.
  ///
  /// In ar, this message translates to:
  /// **'أعلى ميزانية'**
  String get filterHighestBudget;

  /// No description provided for @filterVerified.
  ///
  /// In ar, this message translates to:
  /// **'عملاء موثوقين'**
  String get filterVerified;

  /// No description provided for @filterUrgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجل'**
  String get filterUrgent;

  /// No description provided for @filterPainting.
  ///
  /// In ar, this message translates to:
  /// **'دهانات'**
  String get filterPainting;

  /// No description provided for @filterElectrical.
  ///
  /// In ar, this message translates to:
  /// **'كهرباء'**
  String get filterElectrical;

  /// No description provided for @filterPlumbing.
  ///
  /// In ar, this message translates to:
  /// **'سباكة'**
  String get filterPlumbing;

  /// No description provided for @filterFinishing.
  ///
  /// In ar, this message translates to:
  /// **'تشطيب'**
  String get filterFinishing;

  /// No description provided for @filterBathrooms.
  ///
  /// In ar, this message translates to:
  /// **'حمامات'**
  String get filterBathrooms;

  /// No description provided for @filterKitchens.
  ///
  /// In ar, this message translates to:
  /// **'مطابخ'**
  String get filterKitchens;

  /// No description provided for @urgentLabel.
  ///
  /// In ar, this message translates to:
  /// **'عاجل'**
  String get urgentLabel;

  /// No description provided for @newLabel.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newLabel;

  /// No description provided for @openJobs.
  ///
  /// In ar, this message translates to:
  /// **'فرص شغل'**
  String get openJobs;

  /// No description provided for @applicants.
  ///
  /// In ar, this message translates to:
  /// **'متقدمين'**
  String get applicants;

  /// No description provided for @budget.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية'**
  String get budget;

  /// No description provided for @verifiedTrust.
  ///
  /// In ar, this message translates to:
  /// **'موثق'**
  String get verifiedTrust;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @apply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get apply;

  /// No description provided for @clearAll.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكل'**
  String get clearAll;

  /// No description provided for @filterWithCount.
  ///
  /// In ar, this message translates to:
  /// **'تصفية ({count})'**
  String filterWithCount(int count);

  /// No description provided for @filterSort.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get filterSort;

  /// No description provided for @filterCategory.
  ///
  /// In ar, this message translates to:
  /// **'التخصص'**
  String get filterCategory;

  /// No description provided for @filterCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get filterCity;

  /// No description provided for @filterTime.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get filterTime;

  /// No description provided for @filterThisWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get filterThisWeek;

  /// No description provided for @filterThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get filterThisMonth;

  /// No description provided for @filterNewestFirst.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get filterNewestFirst;

  /// No description provided for @noJobsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش فرص شغل دلوقتي'**
  String get noJobsTitle;

  /// No description provided for @noJobsMatchSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش فرصة بالاسم ده'**
  String get noJobsMatchSearchTitle;

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'امسح البحث'**
  String get clearSearch;

  /// No description provided for @editedMarker.
  ///
  /// In ar, this message translates to:
  /// **'تم التعديل'**
  String get editedMarker;

  /// No description provided for @withdrawQuote.
  ///
  /// In ar, this message translates to:
  /// **'اسحب العرض'**
  String get withdrawQuote;

  /// No description provided for @quoteWithdrawn.
  ///
  /// In ar, this message translates to:
  /// **'تم سحب العرض'**
  String get quoteWithdrawn;

  /// No description provided for @withdrawQuoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسحب العرض؟'**
  String get withdrawQuoteTitle;

  /// No description provided for @deleteBriefTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمسح الطلب ده؟'**
  String get deleteBriefTitle;

  /// No description provided for @briefDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح الطلب'**
  String get briefDeleted;

  /// No description provided for @briefCancelledInstead.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب'**
  String get briefCancelledInstead;

  /// No description provided for @editBriefTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الطلب'**
  String get editBriefTitle;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'احفظ التعديلات'**
  String get saveChanges;

  /// No description provided for @changesSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت التعديلات'**
  String get changesSaved;

  /// No description provided for @markWorkDone.
  ///
  /// In ar, this message translates to:
  /// **'خلصت الشغل'**
  String get markWorkDone;

  /// No description provided for @confirmWorkDone.
  ///
  /// In ar, this message translates to:
  /// **'تم التنفيذ'**
  String get confirmWorkDone;

  /// No description provided for @awaitingHomeownerConfirm.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار تأكيد صاحب البيت'**
  String get awaitingHomeownerConfirm;

  /// No description provided for @confirmCompletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشغل خلص فعلاً؟'**
  String get confirmCompletionTitle;

  /// No description provided for @workCompletedNow.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل إن الشغل خلص'**
  String get workCompletedNow;

  /// No description provided for @completedLabel.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completedLabel;

  /// No description provided for @workTypeSpecLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الشغل'**
  String get workTypeSpecLabel;

  /// No description provided for @publishedSpecLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم النشر'**
  String get publishedSpecLabel;

  /// No description provided for @closePhotoViewer.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الصورة'**
  String get closePhotoViewer;

  /// No description provided for @openPhotoViewer.
  ///
  /// In ar, this message translates to:
  /// **'افتح الصورة'**
  String get openPhotoViewer;

  /// No description provided for @photoIndexOf.
  ///
  /// In ar, this message translates to:
  /// **'{index} / {total}'**
  String photoIndexOf(int index, int total);

  /// No description provided for @morePhotosCount.
  ///
  /// In ar, this message translates to:
  /// **'+{count}'**
  String morePhotosCount(int count);

  /// No description provided for @debugMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التجربة (Debug)'**
  String get debugMode;

  /// No description provided for @demoLoginHomeowner.
  ///
  /// In ar, this message translates to:
  /// **'دخول كصاحب شقة'**
  String get demoLoginHomeowner;

  /// No description provided for @demoLoginContractor.
  ///
  /// In ar, this message translates to:
  /// **'دخول كمحترف'**
  String get demoLoginContractor;

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت'**
  String get networkError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ، حاول تاني'**
  String get somethingWentWrong;

  /// No description provided for @nameNotEnough.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مش كافي'**
  String get nameNotEnough;

  /// No description provided for @nameExample.
  ///
  /// In ar, this message translates to:
  /// **'مثال: أحمد علي'**
  String get nameExample;

  /// No description provided for @refreshHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للأسفل عشان التحديث'**
  String get refreshHint;

  /// No description provided for @yearsExperienceInvalid.
  ///
  /// In ar, this message translates to:
  /// **'سنين خبرة غير صحيحة'**
  String get yearsExperienceInvalid;

  /// No description provided for @noSavedContractors.
  ///
  /// In ar, this message translates to:
  /// **'مفيش محترفين محفوظين لسه'**
  String get noSavedContractors;

  /// No description provided for @contractorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'المحترف مش موجود'**
  String get contractorNotFound;

  /// No description provided for @contractorNotFoundMsg.
  ///
  /// In ar, this message translates to:
  /// **'يمكن يكون شال الحساب أو اتلغى'**
  String get contractorNotFoundMsg;

  /// No description provided for @projectDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل مشروعك'**
  String get projectDetails;

  /// No description provided for @statusOpen.
  ///
  /// In ar, this message translates to:
  /// **'بوست مفتوح'**
  String get statusOpen;

  /// No description provided for @statusDirect.
  ///
  /// In ar, this message translates to:
  /// **'طلب مباشر'**
  String get statusDirect;

  /// No description provided for @newBadge.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newBadge;

  /// No description provided for @urgentBadge.
  ///
  /// In ar, this message translates to:
  /// **'عاجل'**
  String get urgentBadge;

  /// No description provided for @projects.
  ///
  /// In ar, this message translates to:
  /// **'مشروع'**
  String get projects;

  /// No description provided for @singleProject.
  ///
  /// In ar, this message translates to:
  /// **'مشروع'**
  String get singleProject;

  /// No description provided for @year.
  ///
  /// In ar, this message translates to:
  /// **'سنة'**
  String get year;

  /// No description provided for @photos.
  ///
  /// In ar, this message translates to:
  /// **'صور'**
  String get photos;

  /// No description provided for @removePhoto.
  ///
  /// In ar, this message translates to:
  /// **'احذف الصورة'**
  String get removePhoto;

  /// No description provided for @saveTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حفظ المحترف'**
  String get saveTooltip;

  /// No description provided for @unsaveTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المحفوظات'**
  String get unsaveTooltip;

  /// No description provided for @allSpecialties.
  ///
  /// In ar, this message translates to:
  /// **'كل التخصصات'**
  String get allSpecialties;

  /// No description provided for @allCities.
  ///
  /// In ar, this message translates to:
  /// **'كل المحافظات'**
  String get allCities;

  /// No description provided for @foundProfessionals.
  ///
  /// In ar, this message translates to:
  /// **'محترف'**
  String get foundProfessionals;

  /// No description provided for @editLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteLabel;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get confirmDelete;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get retry;

  /// No description provided for @noMoreResults.
  ///
  /// In ar, this message translates to:
  /// **'خلصت النتائج'**
  String get noMoreResults;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل'**
  String get loading;

  /// No description provided for @loadingMore.
  ///
  /// In ar, this message translates to:
  /// **'بيحمل المزيد...'**
  String get loadingMore;

  /// No description provided for @noResultsFound.
  ///
  /// In ar, this message translates to:
  /// **'مالقيش نتائج'**
  String get noResultsFound;

  /// No description provided for @required.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get required;

  /// No description provided for @minLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقل'**
  String get minLabel;

  /// No description provided for @maxLabel.
  ///
  /// In ar, this message translates to:
  /// **'أكثر'**
  String get maxLabel;

  /// No description provided for @allRightsReserved.
  ///
  /// In ar, this message translates to:
  /// **'جميع الحقوق محفوظة لـ'**
  String get allRightsReserved;

  /// No description provided for @activityPostedProject.
  ///
  /// In ar, this message translates to:
  /// **'نشر طلب عمل جديد'**
  String get activityPostedProject;

  /// No description provided for @activityAcceptedQuote.
  ///
  /// In ar, this message translates to:
  /// **'قبل عرض سعر'**
  String get activityAcceptedQuote;

  /// No description provided for @activityPaymentCompleted.
  ///
  /// In ar, this message translates to:
  /// **'تم إتمام دفعة'**
  String get activityPaymentCompleted;

  /// No description provided for @activityNewReview.
  ///
  /// In ar, this message translates to:
  /// **'تقييم جديد'**
  String get activityNewReview;

  /// No description provided for @activityDisputeOpened.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح نزاع'**
  String get activityDisputeOpened;

  /// No description provided for @activityVerified.
  ///
  /// In ar, this message translates to:
  /// **'تم التوثيق'**
  String get activityVerified;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'الحقل ده مطلوب'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مش صحيح'**
  String get invalidEmail;

  /// No description provided for @tooShort.
  ///
  /// In ar, this message translates to:
  /// **'قصير جداً'**
  String get tooShort;

  /// No description provided for @tooLong.
  ///
  /// In ar, this message translates to:
  /// **'طويل جداً'**
  String get tooLong;

  /// No description provided for @passwordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر مش متطابقة'**
  String get passwordMismatch;

  /// No description provided for @errAuthFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول، حاول تاني'**
  String get errAuthFailed;

  /// No description provided for @errOtpFailed.
  ///
  /// In ar, this message translates to:
  /// **'كود التأكيد غلط، حاول تاني'**
  String get errOtpFailed;

  /// No description provided for @errOtpExpired.
  ///
  /// In ar, this message translates to:
  /// **'الكود انتهت صلاحيته، ابعت واحد جديد'**
  String get errOtpExpired;

  /// No description provided for @errNetwork.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نت، اتأكد من اتصالك'**
  String get errNetwork;

  /// No description provided for @errServerError.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة مش شغالة دلوقتي، حاول تاني'**
  String get errServerError;

  /// No description provided for @errDataLoad.
  ///
  /// In ar, this message translates to:
  /// **'حصل مشكلة في تحميل البيانات'**
  String get errDataLoad;

  /// No description provided for @errDataSave.
  ///
  /// In ar, this message translates to:
  /// **'حصل مشكلة في حفظ البيانات'**
  String get errDataSave;

  /// No description provided for @errSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة، سجل دخول تاني'**
  String get errSessionExpired;

  /// No description provided for @errPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'مش مسموحلك تعمل كده'**
  String get errPermissionDenied;

  /// No description provided for @errNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العنصر مش موجود'**
  String get errNotFound;

  /// No description provided for @errPhotoUpload.
  ///
  /// In ar, this message translates to:
  /// **'حصل مشكلة في رفع الصور'**
  String get errPhotoUpload;

  /// No description provided for @errInvalidData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات مش صحيحة، تأكد منها'**
  String get errInvalidData;

  /// No description provided for @portfolioAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف عمل'**
  String get portfolioAdd;

  /// No description provided for @portfolioEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العمل'**
  String get portfolioEdit;

  /// No description provided for @portfolioDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف العمل'**
  String get portfolioDelete;

  /// No description provided for @portfolioDeleteError.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ أثناء حذف العمل'**
  String get portfolioDeleteError;

  /// No description provided for @postCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الطلب بنجاح'**
  String get postCreatedSuccess;

  /// No description provided for @projectSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العمل بنجاح'**
  String get projectSavedSuccess;

  /// No description provided for @projectDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف العمل بنجاح'**
  String get projectDeletedSuccess;

  /// No description provided for @portfolioTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان العمل'**
  String get portfolioTitleLabel;

  /// No description provided for @portfolioTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تشطيب شقة ١٥٠م'**
  String get portfolioTitleHint;

  /// No description provided for @portfolioCategoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get portfolioCategoryLabel;

  /// No description provided for @portfolioCategoryHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تشطيب'**
  String get portfolioCategoryHint;

  /// No description provided for @portfolioYearLabel.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get portfolioYearLabel;

  /// No description provided for @portfolioYearHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: ٢٠٢٥'**
  String get portfolioYearHint;

  /// No description provided for @portfolioLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get portfolioLocationLabel;

  /// No description provided for @portfolioLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: القاهرة'**
  String get portfolioLocationHint;

  /// No description provided for @portfolioDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get portfolioDescriptionLabel;

  /// No description provided for @portfolioDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'وصف العمل بالتفصيل...'**
  String get portfolioDescriptionHint;

  /// No description provided for @portfolioCoverLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة الغلاف'**
  String get portfolioCoverLabel;

  /// No description provided for @portfolioPhotosLabel.
  ///
  /// In ar, this message translates to:
  /// **'صور العمل'**
  String get portfolioPhotosLabel;

  /// No description provided for @portfolioSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العمل'**
  String get portfolioSaved;

  /// No description provided for @portfolioSaveError.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ أثناء حفظ العمل'**
  String get portfolioSaveError;

  /// No description provided for @photoMaxReached.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للحد الأقصى من الصور'**
  String get photoMaxReached;

  /// No description provided for @savedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get savedToast;

  /// No description provided for @unsavedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم الإزالة من المحفوظات'**
  String get unsavedToast;

  /// No description provided for @motionFull.
  ///
  /// In ar, this message translates to:
  /// **'كامل'**
  String get motionFull;

  /// No description provided for @motionReduced.
  ///
  /// In ar, this message translates to:
  /// **'مخفض'**
  String get motionReduced;

  /// No description provided for @motionOff.
  ///
  /// In ar, this message translates to:
  /// **'متوقف'**
  String get motionOff;

  /// No description provided for @yourData.
  ///
  /// In ar, this message translates to:
  /// **'بياناتك'**
  String get yourData;

  /// No description provided for @apartmentType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الشقة'**
  String get apartmentType;

  /// No description provided for @fillBothFields.
  ///
  /// In ar, this message translates to:
  /// **'املا الحقلين'**
  String get fillBothFields;

  /// No description provided for @companyData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الشركة'**
  String get companyData;

  /// No description provided for @companyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة / المحترف'**
  String get companyName;

  /// No description provided for @logo.
  ///
  /// In ar, this message translates to:
  /// **'الشعار'**
  String get logo;

  /// No description provided for @professionalTitle.
  ///
  /// In ar, this message translates to:
  /// **'العنوان المهني'**
  String get professionalTitle;

  /// No description provided for @professionalTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تشطيبات وديكورات فاخرة'**
  String get professionalTitleHint;

  /// No description provided for @bioInfo.
  ///
  /// In ar, this message translates to:
  /// **'نبذة عنك'**
  String get bioInfo;

  /// No description provided for @coverPhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة الغلاف'**
  String get coverPhoto;

  /// No description provided for @sendProjectDetails.
  ///
  /// In ar, this message translates to:
  /// **'ابعت تفاصيل مشروعك'**
  String get sendProjectDetails;

  /// No description provided for @aboutProfessional.
  ///
  /// In ar, this message translates to:
  /// **'عن المحترف'**
  String get aboutProfessional;

  /// No description provided for @worksIn.
  ///
  /// In ar, this message translates to:
  /// **'بيشتغل في'**
  String get worksIn;

  /// No description provided for @newProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف جديد'**
  String get newProfessional;

  /// No description provided for @noRatingsYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش تقييمات'**
  String get noRatingsYet;

  /// No description provided for @responseRate.
  ///
  /// In ar, this message translates to:
  /// **'معدل الرد'**
  String get responseRate;

  /// No description provided for @projectsCompleted.
  ///
  /// In ar, this message translates to:
  /// **'المشاريع المنجزة'**
  String get projectsCompleted;

  /// No description provided for @experienceYears.
  ///
  /// In ar, this message translates to:
  /// **'سنين الخبرة'**
  String get experienceYears;

  /// No description provided for @continueWithApple.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول باستخدام Apple'**
  String get continueWithApple;

  /// No description provided for @professionals.
  ///
  /// In ar, this message translates to:
  /// **'محترفين'**
  String get professionals;

  /// No description provided for @professionalSingular.
  ///
  /// In ar, this message translates to:
  /// **'محترف'**
  String get professionalSingular;

  /// No description provided for @providerKindContractor.
  ///
  /// In ar, this message translates to:
  /// **'مقاول'**
  String get providerKindContractor;

  /// No description provided for @providerKindEngineer.
  ///
  /// In ar, this message translates to:
  /// **'مهندس'**
  String get providerKindEngineer;

  /// No description provided for @providerKindEngineeringOffice.
  ///
  /// In ar, this message translates to:
  /// **'مكتب هندسي'**
  String get providerKindEngineeringOffice;

  /// No description provided for @providerKindFinishingCompany.
  ///
  /// In ar, this message translates to:
  /// **'شركة تشطيبات'**
  String get providerKindFinishingCompany;

  /// No description provided for @providerKindInteriorDesigner.
  ///
  /// In ar, this message translates to:
  /// **'مصمم داخلي'**
  String get providerKindInteriorDesigner;

  /// No description provided for @providerKindTradesman.
  ///
  /// In ar, this message translates to:
  /// **'فني متخصص'**
  String get providerKindTradesman;

  /// No description provided for @providerKindQuestion.
  ///
  /// In ar, this message translates to:
  /// **'إنت إيه بالظبط؟'**
  String get providerKindQuestion;

  /// No description provided for @quotaReachedTitle.
  ///
  /// In ar, this message translates to:
  /// **'خلصت عروضك المجانية'**
  String get quotaReachedTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsOfService;

  /// No description provided for @legalSectionLabel.
  ///
  /// In ar, this message translates to:
  /// **'قانوني'**
  String get legalSectionLabel;

  /// No description provided for @reportTitle.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ'**
  String get reportTitle;

  /// No description provided for @reportPostAction.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ عن البوست'**
  String get reportPostAction;

  /// No description provided for @reportSent.
  ///
  /// In ar, this message translates to:
  /// **'وصلنا بلاغك، شكراً'**
  String get reportSent;

  /// No description provided for @reportAlreadySent.
  ///
  /// In ar, this message translates to:
  /// **'أنت مبلّغ عن ده قبل كده'**
  String get reportAlreadySent;

  /// No description provided for @reportReasonSpam.
  ///
  /// In ar, this message translates to:
  /// **'سبام أو إعلانات'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonScam.
  ///
  /// In ar, this message translates to:
  /// **'نصب أو احتيال'**
  String get reportReasonScam;

  /// No description provided for @reportReasonOffensive.
  ///
  /// In ar, this message translates to:
  /// **'محتوى مسيء'**
  String get reportReasonOffensive;

  /// No description provided for @reportReasonSexual.
  ///
  /// In ar, this message translates to:
  /// **'محتوى جنسي'**
  String get reportReasonSexual;

  /// No description provided for @reportReasonViolence.
  ///
  /// In ar, this message translates to:
  /// **'عنف'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonImpersonation.
  ///
  /// In ar, this message translates to:
  /// **'انتحال شخصية'**
  String get reportReasonImpersonation;

  /// No description provided for @reportReasonOther.
  ///
  /// In ar, this message translates to:
  /// **'سبب تاني'**
  String get reportReasonOther;

  /// No description provided for @blockUser.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get blockUser;

  /// No description provided for @blockUserTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحظر الحساب ده؟'**
  String get blockUserTitle;

  /// No description provided for @blockUserBody.
  ///
  /// In ar, this message translates to:
  /// **'مش هتشوف بوستاته وهو مش هيشوف بوستاتك. تقدر تلغي الحظر في أي وقت.'**
  String get blockUserBody;

  /// No description provided for @userBlocked.
  ///
  /// In ar, this message translates to:
  /// **'تم الحظر'**
  String get userBlocked;

  /// No description provided for @unblockUser.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحظر'**
  String get unblockUser;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف حسابك نهائياً؟'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ar, this message translates to:
  /// **'ده هيمسح حسابك وكل بياناتك: بوستاتك، طلباتك، عروض الأسعار، الصور والتقييمات. مفيش رجوع في ده.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountConfirmHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب \"حذف\" عشان تأكد'**
  String get deleteAccountConfirmHint;

  /// No description provided for @accountDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف حسابك'**
  String get accountDeleted;

  /// No description provided for @reviewsSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get reviewsSheetTitle;

  /// No description provided for @noReviewsYet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش تقييمات لسه'**
  String get noReviewsYet;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @copiedData.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ البيانات'**
  String get copiedData;

  /// No description provided for @seeOnShattab.
  ///
  /// In ar, this message translates to:
  /// **'شوف الملف على شطب: %s'**
  String get seeOnShattab;

  /// No description provided for @forContact.
  ///
  /// In ar, this message translates to:
  /// **'للتواصل'**
  String get forContact;

  /// No description provided for @clientsPreview.
  ///
  /// In ar, this message translates to:
  /// **'ده اللي بيشوفه العملاء'**
  String get clientsPreview;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In ar, this message translates to:
  /// **'قلنا عن نفسك'**
  String get tellUsAboutYourself;

  /// No description provided for @fullNameHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل'**
  String get fullNameHint;

  /// No description provided for @chooseRole.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الحساب'**
  String get chooseRole;

  /// No description provided for @minAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} دقيقة'**
  String minAgo(int n);

  /// No description provided for @minsAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} دقائق'**
  String minsAgo(int n);

  /// No description provided for @hourAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} ساعة'**
  String hourAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} ساعات'**
  String hoursAgo(int n);

  /// No description provided for @dayAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} يوم'**
  String dayAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {n} أيام'**
  String daysAgo(int n);

  /// No description provided for @photosCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} صور'**
  String photosCount(int n);

  /// No description provided for @briefSentMessageNew.
  ///
  /// In ar, this message translates to:
  /// **'المحترف استلم تفاصيل مشروعك وهيتواصل معاك قريب.\\nتقدر تكلّمه دلوقتي على واتساب لو حابب تستعجل.'**
  String get briefSentMessageNew;

  /// No description provided for @cancelBriefMessage.
  ///
  /// In ar, this message translates to:
  /// **'مش هيقدر يتفعّل تاني بعد ما تلغيه.'**
  String get cancelBriefMessage;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار اللي يناسبك عشان نفصّل التجربة على مزاجك'**
  String get chooseRoleSubtitle;

  /// No description provided for @confirmCompletionBody.
  ///
  /// In ar, this message translates to:
  /// **'لما تأكد، هيتسجل إن الشغل خلص وهتقدر تقيم المحترف. مش هينفع ترجع في ده.'**
  String get confirmCompletionBody;

  /// No description provided for @contractorSaysDone.
  ///
  /// In ar, this message translates to:
  /// **'المحترف قال إنه خلص الشغل'**
  String get contractorSaysDone;

  /// No description provided for @contractorsWillSeeMatched.
  ///
  /// In ar, this message translates to:
  /// **'المحترفين اللي بتخصصاتهم وأماكنهم تطابق هيشوفوا البوست.'**
  String get contractorsWillSeeMatched;

  /// No description provided for @couldNotOpenApp.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح التطبيق. تأكد إنه متثبّت.'**
  String get couldNotOpenApp;

  /// No description provided for @deleteBriefBody.
  ///
  /// In ar, this message translates to:
  /// **'مش هينفع ترجع فيه.'**
  String get deleteBriefBody;

  /// No description provided for @deleteBriefWithQuotesBody.
  ///
  /// In ar, this message translates to:
  /// **'فيه محترفين بعتوا عروض على الطلب ده، فهيتلغي بدل ما يتمسح عشان عروضهم ما تضيعش.'**
  String get deleteBriefWithQuotesBody;

  /// No description provided for @deletePostConfirm.
  ///
  /// In ar, this message translates to:
  /// **'متأكد إنك عايز تحذف المنشور؟'**
  String get deletePostConfirm;

  /// No description provided for @deleteWorkConfirm.
  ///
  /// In ar, this message translates to:
  /// **'متأكد إنك عايز تمسح العمل ده؟'**
  String get deleteWorkConfirm;

  /// No description provided for @descriptionWorkHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: محتاج حد يدهن الشقة كاملة…'**
  String get descriptionWorkHint;

  /// No description provided for @errorDescriptionShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وصف للشغل على الأقل من ١٠ حروف'**
  String get errorDescriptionShort;

  /// No description provided for @heroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اطلب الخدمة المناسبة واستقبل عروضًا من محترفين موثقين.'**
  String get heroSubtitle;

  /// No description provided for @homeownerDetailsHint.
  ///
  /// In ar, this message translates to:
  /// **'عشان نرشّحلك أنسب المحترفين لبيتك'**
  String get homeownerDetailsHint;

  /// No description provided for @inboxEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'لما عميل يبعتلك طلب مخصوص ليك هيظهر هنا على طول.'**
  String get inboxEmptyMessage;

  /// No description provided for @instapaySubmittedBody.
  ///
  /// In ar, this message translates to:
  /// **'استلمنا التحويل. هنفعّل باقة برو بعد التأكيد، عادة خلال ٢٤ ساعة.'**
  String get instapaySubmittedBody;

  /// No description provided for @myPostsEmptySub.
  ///
  /// In ar, this message translates to:
  /// **'اللي بتنشره في الاستكشف بيظهر هنا، وتقدر تعدله أو تمسحه في أي وقت.'**
  String get myPostsEmptySub;

  /// No description provided for @myQuotesEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'العروض اللي هتبعتها للطلبات هتظهر هنا'**
  String get myQuotesEmptyMessage;

  /// No description provided for @noBriefsHereMessage.
  ///
  /// In ar, this message translates to:
  /// **'ابعت طلب لمحترف معين من صفحته، أو اعمل بوست عام والمحترفين يتواصلوا معاك.'**
  String get noBriefsHereMessage;

  /// No description provided for @noJobsMatchSearchMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرب كلمة تانية، أو امسح البحث وشوف كل الفرص المتاحة.'**
  String get noJobsMatchSearchMessage;

  /// No description provided for @noJobsMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرب تغير الفلاتر أو ارجع تاني بعدين. هتلاقي فرص جديدة باستمرار.'**
  String get noJobsMessage;

  /// No description provided for @noReviewsYetSub.
  ///
  /// In ar, this message translates to:
  /// **'أول تقييم بيجي بعد أول شغلانة تخلص'**
  String get noReviewsYetSub;

  /// No description provided for @noSavedContractorsMsg.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على علامة الحفظ عشان تقدر ترجع تاني'**
  String get noSavedContractorsMsg;

  /// No description provided for @noWorksMessage.
  ///
  /// In ar, this message translates to:
  /// **'المحترف هيضيف شغله هنا قريب.'**
  String get noWorksMessage;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر لازم ٦ حروف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @payInstapaySub.
  ///
  /// In ar, this message translates to:
  /// **'تحويل فوري من أي بنك أو محفظة'**
  String get payInstapaySub;

  /// No description provided for @paywallSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'وصّل شغلك لعملاء أكتر واكسب أكتر.'**
  String get paywallSubtitle;

  /// No description provided for @phoneVisibleContractor.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفونك هيظهر للمحترف لما يستلم الطلب.'**
  String get phoneVisibleContractor;

  /// No description provided for @phoneVisibleContractors.
  ///
  /// In ar, this message translates to:
  /// **'رقم تليفونك هيظهر للمحترفين اللي يشوفوا البوست.'**
  String get phoneVisibleContractors;

  /// No description provided for @portfolioEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'اعرض شغلك عشان العملاء يشوفوا مستواك. ابدأ بإضافة أول عمل ليك.'**
  String get portfolioEmptyMessage;

  /// No description provided for @portfolioLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحمل الأعمال السابقة'**
  String get portfolioLoadFailed;

  /// No description provided for @postUnavailableSub.
  ///
  /// In ar, this message translates to:
  /// **'يمكن يكون اتمسح أو صاحبه خلاه خاص.'**
  String get postUnavailableSub;

  /// No description provided for @priceMinLessThanMax.
  ///
  /// In ar, this message translates to:
  /// **'السعر من يجب أن يكون أقل من السعر إلى'**
  String get priceMinLessThanMax;

  /// No description provided for @proBenefitRequests.
  ///
  /// In ar, this message translates to:
  /// **'شوف طلبات الشغل وبيانات التواصل'**
  String get proBenefitRequests;

  /// No description provided for @profileGreeting.
  ///
  /// In ar, this message translates to:
  /// **'السلام عليكم، شفت بروفايلك على شطب وحبيت أكلمك'**
  String get profileGreeting;

  /// No description provided for @proRoiLine.
  ///
  /// In ar, this message translates to:
  /// **'عرض واحد ممكن يرجّع اشتراك السنة كله'**
  String get proRoiLine;

  /// No description provided for @proValueLine.
  ///
  /// In ar, this message translates to:
  /// **'خلّي شغلك ما يوقفش، عروض بلا حدود'**
  String get proValueLine;

  /// No description provided for @providerKindHelp.
  ///
  /// In ar, this message translates to:
  /// **'ده اللي هيظهر على ملفك. تقدر تغيّره في أي وقت.'**
  String get providerKindHelp;

  /// No description provided for @quoteNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تفاصيل العرض وأي ملاحظات للعميل'**
  String get quoteNoteHint;

  /// No description provided for @reportSheetSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار سبب البلاغ. كل بلاغ بيتراجع يدوي.'**
  String get reportSheetSubtitle;

  /// No description provided for @reviewAfterCompletionHint.
  ///
  /// In ar, this message translates to:
  /// **'هتقدر تقيم المحترف بعد ما تأكد إن الشغل خلص'**
  String get reviewAfterCompletionHint;

  /// No description provided for @savedPostsEmptySub.
  ///
  /// In ar, this message translates to:
  /// **'اضغط علامة الحفظ على أي منشور عشان ترجعله بسرعة من هنا.'**
  String get savedPostsEmptySub;

  /// No description provided for @sendBriefAllDetailsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابعت كل التفاصيل اللي محتاج المحترف يعرفها'**
  String get sendBriefAllDetailsHint;

  /// No description provided for @signInEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'حسابك بيحفظ شغلك وطلباتك، وترجعلك على أي جهاز تدخل منه.'**
  String get signInEmptyMessage;

  /// No description provided for @signInToSeeSaved.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لرؤية المحترفين المحفوظين'**
  String get signInToSeeSaved;

  /// No description provided for @verifyApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'علامة التوثيق ظاهرة على ملفك دلوقتي.'**
  String get verifyApprovedBody;

  /// No description provided for @verifyHeadline.
  ///
  /// In ar, this message translates to:
  /// **'وثّق حسابك وكسب ثقة العملاء'**
  String get verifyHeadline;

  /// No description provided for @verifyPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'بنراجع مستنداتك وهنفعّل التوثيق خلال ٤٨ ساعة.'**
  String get verifyPendingBody;

  /// No description provided for @verifyPrivacyNote.
  ///
  /// In ar, this message translates to:
  /// **'مستنداتك سرية وتُستخدم للتحقق فقط.'**
  String get verifyPrivacyNote;

  /// No description provided for @verifyUploadHint.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة الرقم القومي، والسجل التجاري أو رخصة المهنة إن وجدت.'**
  String get verifyUploadHint;

  /// No description provided for @whatsappBriefGreeting.
  ///
  /// In ar, this message translates to:
  /// **'السلام عليكم، أنا بعتلك طلب على شطب'**
  String get whatsappBriefGreeting;

  /// No description provided for @whatsappPostGreeting.
  ///
  /// In ar, this message translates to:
  /// **'السلام عليكم، شفت بوستك على شطب وحبيت أعرف أكتر عن الشغل'**
  String get whatsappPostGreeting;

  /// No description provided for @whatsYourName.
  ///
  /// In ar, this message translates to:
  /// **'إيه اسمك؟'**
  String get whatsYourName;

  /// No description provided for @withdrawQuoteBody.
  ///
  /// In ar, this message translates to:
  /// **'صاحب البيت مش هيقدر يقبل العرض ده بعد ما تسحبه. تقدر تبعت عرض جديد بعدين.'**
  String get withdrawQuoteBody;

  /// No description provided for @workDoneRequested.
  ///
  /// In ar, this message translates to:
  /// **'بلغنا صاحب البيت إنك خلصت'**
  String get workDoneRequested;

  /// No description provided for @workTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تشطيب شقة في التجمع'**
  String get workTitleHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
