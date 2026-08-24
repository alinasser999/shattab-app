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

  /// No description provided for @opportunityPostedBy.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الطلب'**
  String get opportunityPostedBy;

  /// No description provided for @viewHomeownerProfile.
  ///
  /// In ar, this message translates to:
  /// **'عرض ملف صاحب الطلب'**
  String get viewHomeownerProfile;

  /// No description provided for @homeownerProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف صاحب الطلب'**
  String get homeownerProfileTitle;

  /// No description provided for @homeownerProfileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل عامة عن صاحب الطلب'**
  String get homeownerProfileSubtitle;

  /// No description provided for @homeownerProfileDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل صاحب الطلب'**
  String get homeownerProfileDetailsTitle;

  /// No description provided for @homeownerLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'منطقة المشروع'**
  String get homeownerLocationLabel;

  /// No description provided for @homeownerApartmentLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوحدة'**
  String get homeownerApartmentLabel;

  /// No description provided for @homeownerInterestsLabel.
  ///
  /// In ar, this message translates to:
  /// **'اهتمامات التشطيب'**
  String get homeownerInterestsLabel;

  /// No description provided for @homeownerProfileUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'بيانات صاحب الطلب مش متاحة دلوقتي.'**
  String get homeownerProfileUnavailable;

  /// No description provided for @homeownerProfileNoDetails.
  ///
  /// In ar, this message translates to:
  /// **'لسه ما أضافش تفاصيل إضافية عن بيته أو احتياجاته.'**
  String get homeownerProfileNoDetails;

  /// No description provided for @homeownerProfilePrivacyHint.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل لا تظهر في الملف.'**
  String get homeownerProfilePrivacyHint;

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
  /// **'شطّب'**
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

  /// No description provided for @signupNeedsConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'اتعمل الحساب. أكّد رقمك من الرسالة وبعدين سجّل دخولك.'**
  String get signupNeedsConfirmation;

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

  /// No description provided for @roleSwitcherOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get roleSwitcherOwner;

  /// No description provided for @roleSwitcherContractor.
  ///
  /// In ar, this message translates to:
  /// **'مقاول'**
  String get roleSwitcherContractor;

  /// No description provided for @nextStepsTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ هنا'**
  String get nextStepsTitle;

  /// No description provided for @performanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'أداؤك خلال آخر 30 يوم'**
  String get performanceTitle;

  /// No description provided for @personalizeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص تجربتك'**
  String get personalizeTitle;

  /// No description provided for @areasNotAdded.
  ///
  /// In ar, this message translates to:
  /// **'مناطق الشغل لسه مش مضافة'**
  String get areasNotAdded;

  /// No description provided for @verifiedStatus.
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get verifiedStatus;

  /// No description provided for @unverifiedStatus.
  ///
  /// In ar, this message translates to:
  /// **'غير موثّق'**
  String get unverifiedStatus;

  /// No description provided for @profileCompletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال الملف'**
  String get profileCompletionTitle;

  /// No description provided for @profileCompletionPercent.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال الملف {value}%'**
  String profileCompletionPercent(int value);

  /// No description provided for @profileCompleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'ملفك جاهز يعرّف العملاء بشغلك.'**
  String get profileCompleteMessage;

  /// No description provided for @profileIncompleteMessage.
  ///
  /// In ar, this message translates to:
  /// **'كمّل ملفك عشان تظهر لعملاء أكتر.'**
  String get profileIncompleteMessage;

  /// No description provided for @completeProfileAction.
  ///
  /// In ar, this message translates to:
  /// **'كمّل ملفك'**
  String get completeProfileAction;

  /// No description provided for @editProfileImage.
  ///
  /// In ar, this message translates to:
  /// **'تعديل صورة الحساب'**
  String get editProfileImage;

  /// No description provided for @addFirstProject.
  ///
  /// In ar, this message translates to:
  /// **'أضف أول مشروع'**
  String get addFirstProject;

  /// No description provided for @addFirstProjectSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اعرض شغلك واجذب عملاء جدد'**
  String get addFirstProjectSubtitle;

  /// No description provided for @verifyAccount.
  ///
  /// In ar, this message translates to:
  /// **'وثّق حسابك'**
  String get verifyAccount;

  /// No description provided for @verifyAccountSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'زوّد ثقة العملاء في حسابك'**
  String get verifyAccountSubtitle;

  /// No description provided for @addWorkAreas.
  ///
  /// In ar, this message translates to:
  /// **'حدّد مناطق الشغل'**
  String get addWorkAreas;

  /// No description provided for @addWorkAreasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خلّي فرص الشغل المناسبة توصلك'**
  String get addWorkAreasSubtitle;

  /// No description provided for @verificationPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get verificationPending;

  /// No description provided for @performanceEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'أداؤك هيظهر هنا'**
  String get performanceEmptyTitle;

  /// No description provided for @performanceEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'كمّل ملفك وأضف أول مشروع عشان تبدأ تتابع تفاعل العملاء.'**
  String get performanceEmptyMessage;

  /// No description provided for @proCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'شطّب Pro'**
  String get proCardTitle;

  /// No description provided for @proCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خلّي ملفك يظهر لعملاء أكتر، وابرز شغلك بوضوح.'**
  String get proCardSubtitle;

  /// No description provided for @proLearnMore.
  ///
  /// In ar, this message translates to:
  /// **'اعرف أكتر'**
  String get proLearnMore;

  /// No description provided for @proManageSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة اشتراكك ومزاياك المفعّلة.'**
  String get proManageSubtitle;

  /// No description provided for @settingsEntryTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات والتفضيلات'**
  String get settingsEntryTitle;

  /// No description provided for @settingsEntrySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحكّم في إعدادات التطبيق'**
  String get settingsEntrySubtitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccountSection;

  /// No description provided for @settingsPreferencesSection.
  ///
  /// In ar, this message translates to:
  /// **'التفضيلات'**
  String get settingsPreferencesSection;

  /// No description provided for @settingsSupportSection.
  ///
  /// In ar, this message translates to:
  /// **'الدعم والقانون'**
  String get settingsSupportSection;

  /// No description provided for @settingsAccountManagementSection.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحساب'**
  String get settingsAccountManagementSection;

  /// No description provided for @appearanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار الشكل المناسب ليك'**
  String get appearanceSubtitle;

  /// No description provided for @appearanceDay.
  ///
  /// In ar, this message translates to:
  /// **'نهاري'**
  String get appearanceDay;

  /// No description provided for @appearanceDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get appearanceDark;

  /// No description provided for @appearanceSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get appearanceSystem;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة تفضيلات الإشعارات'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الشغل'**
  String get notificationsRequests;

  /// No description provided for @notificationsMessages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل والتحديثات'**
  String get notificationsMessages;

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
  /// **'الطلبات'**
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

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabCommunity.
  ///
  /// In ar, this message translates to:
  /// **'المجتمع'**
  String get tabCommunity;

  /// No description provided for @sampleImagesLabel.
  ///
  /// In ar, this message translates to:
  /// **'صور تجريبية'**
  String get sampleImagesLabel;

  /// No description provided for @workInspirationTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلهام للشغل'**
  String get workInspirationTitle;

  /// No description provided for @imageUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الصورة غير متاحة'**
  String get imageUnavailable;

  /// No description provided for @exploreTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعمال'**
  String get exploreTitle;

  /// No description provided for @communityTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجتمع شطّب'**
  String get communityTitle;

  /// No description provided for @communitySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'شارك تجربتك واستلهم من غيرك.'**
  String get communitySubtitle;

  /// No description provided for @communityNotificationsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get communityNotificationsLabel;

  /// No description provided for @communityFiltersLabel.
  ///
  /// In ar, this message translates to:
  /// **'تصفية المنشورات'**
  String get communityFiltersLabel;

  /// No description provided for @communityFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get communityFilterAll;

  /// No description provided for @communityFilterBeforeAfter.
  ///
  /// In ar, this message translates to:
  /// **'قبل وبعد'**
  String get communityFilterBeforeAfter;

  /// No description provided for @communityFilterTips.
  ///
  /// In ar, this message translates to:
  /// **'نصائح'**
  String get communityFilterTips;

  /// No description provided for @communityFilterExperiences.
  ///
  /// In ar, this message translates to:
  /// **'تجارب'**
  String get communityFilterExperiences;

  /// No description provided for @communityFilterRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات'**
  String get communityFilterRequests;

  /// No description provided for @communityCreatePrompt.
  ///
  /// In ar, this message translates to:
  /// **'إيه اللي شاغل بالك في التشطيب؟'**
  String get communityCreatePrompt;

  /// No description provided for @communityCreatePost.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منشور'**
  String get communityCreatePost;

  /// No description provided for @communityCreatePostTypeTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار نوع المنشور'**
  String get communityCreatePostTypeTitle;

  /// No description provided for @communityPostKindStandard.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get communityPostKindStandard;

  /// No description provided for @communityPostKindStandardDescription.
  ///
  /// In ar, this message translates to:
  /// **'شارك تجربة أو تحديث من شغلك'**
  String get communityPostKindStandardDescription;

  /// No description provided for @communityPostKindBeforeAfter.
  ///
  /// In ar, this message translates to:
  /// **'قبل وبعد'**
  String get communityPostKindBeforeAfter;

  /// No description provided for @communityPostKindBeforeAfterDescription.
  ///
  /// In ar, this message translates to:
  /// **'اعرض الفرق في شغلك بصورتين'**
  String get communityPostKindBeforeAfterDescription;

  /// No description provided for @communityPostKindQuestion.
  ///
  /// In ar, this message translates to:
  /// **'سؤال'**
  String get communityPostKindQuestion;

  /// No description provided for @communityPostKindQuestionDescription.
  ///
  /// In ar, this message translates to:
  /// **'اسأل المجتمع وخد آراء مفيدة'**
  String get communityPostKindQuestionDescription;

  /// No description provided for @communityPostKindTips.
  ///
  /// In ar, this message translates to:
  /// **'نصائح'**
  String get communityPostKindTips;

  /// No description provided for @communityPostKindTipsDescription.
  ///
  /// In ar, this message translates to:
  /// **'شارك خطوة أو خامة فرقت معاك'**
  String get communityPostKindTipsDescription;

  /// No description provided for @communityPostKindExperiences.
  ///
  /// In ar, this message translates to:
  /// **'تجارب'**
  String get communityPostKindExperiences;

  /// No description provided for @communityPostKindExperiencesDescription.
  ///
  /// In ar, this message translates to:
  /// **'احكي اللي اتعلمته من رحلة التشطيب'**
  String get communityPostKindExperiencesDescription;

  /// No description provided for @communityCreatePostTypeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار الطريقة اللي تحب تشارك بيها'**
  String get communityCreatePostTypeSubtitle;

  /// No description provided for @communityWritePostTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتبها بطريقتك'**
  String get communityWritePostTitle;

  /// No description provided for @communityPublishCta.
  ///
  /// In ar, this message translates to:
  /// **'انشر في مجتمع شطّب'**
  String get communityPublishCta;

  /// No description provided for @communityBeforeAfterNeedsImages.
  ///
  /// In ar, this message translates to:
  /// **'أضف صورتين عشان تعرض قبل وبعد'**
  String get communityBeforeAfterNeedsImages;

  /// No description provided for @communityPhotoAction.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get communityPhotoAction;

  /// No description provided for @communityBeforeAfterAction.
  ///
  /// In ar, this message translates to:
  /// **'قبل وبعد'**
  String get communityBeforeAfterAction;

  /// No description provided for @communityBeforeLabel.
  ///
  /// In ar, this message translates to:
  /// **'قبل'**
  String get communityBeforeLabel;

  /// No description provided for @communityAfterLabel.
  ///
  /// In ar, this message translates to:
  /// **'بعد'**
  String get communityAfterLabel;

  /// No description provided for @communityQuestionAction.
  ///
  /// In ar, this message translates to:
  /// **'سؤال'**
  String get communityQuestionAction;

  /// No description provided for @communityPostMenuLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات المنشور'**
  String get communityPostMenuLabel;

  /// No description provided for @communityLikePost.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب'**
  String get communityLikePost;

  /// No description provided for @communityUnlikePost.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الإعجاب'**
  String get communityUnlikePost;

  /// No description provided for @communityCommentPost.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get communityCommentPost;

  /// No description provided for @communitySharePost.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get communitySharePost;

  /// No description provided for @communitySavePost.
  ///
  /// In ar, this message translates to:
  /// **'حفظ المنشور'**
  String get communitySavePost;

  /// No description provided for @communityUnsavePost.
  ///
  /// In ar, this message translates to:
  /// **'إزالة حفظ المنشور'**
  String get communityUnsavePost;

  /// No description provided for @communityNoPostsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش منشورات هنا لسه'**
  String get communityNoPostsTitle;

  /// No description provided for @communityNoPostsMessage.
  ///
  /// In ar, this message translates to:
  /// **'كن أول واحد يشارك تجربة أو نصيحة في مجتمع شطّب.'**
  String get communityNoPostsMessage;

  /// No description provided for @communityPostsTitle.
  ///
  /// In ar, this message translates to:
  /// **'منشوراته في المجتمع'**
  String get communityPostsTitle;

  /// No description provided for @communityPostsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه ما شاركش منشورات'**
  String get communityPostsEmptyTitle;

  /// No description provided for @communityPostsEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'تجاربه ونصايحه هتظهر هنا لما يشاركها في مجتمع شطّب.'**
  String get communityPostsEmptyMessage;

  /// No description provided for @communityPostsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نحمّل منشوراته دلوقتي'**
  String get communityPostsLoadError;

  /// No description provided for @communityFeedErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب منشورات المجتمع دلوقتي'**
  String get communityFeedErrorTitle;

  /// No description provided for @communityFeedErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة مؤقتة في تحميل المنشورات. جرّب تاني بعد لحظات.'**
  String get communityFeedErrorMessage;

  /// No description provided for @communityFeedGuestErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك عشان تفتح المجتمع'**
  String get communityFeedGuestErrorTitle;

  /// No description provided for @communityFeedGuestErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بيخليك تشوف المنشورات وتتفاعل مع أهل الخبرة وتحفظ اللي يعجبك.'**
  String get communityFeedGuestErrorMessage;

  /// No description provided for @communityClearFilter.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل المنشورات'**
  String get communityClearFilter;

  /// No description provided for @communityLoadingMore.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل منشورات إضافية'**
  String get communityLoadingMore;

  /// No description provided for @communityFilterAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'فلتر المنشورات: {filter}'**
  String communityFilterAnnouncement(String filter);

  /// No description provided for @communityAuthorHomeowner.
  ///
  /// In ar, this message translates to:
  /// **'صاحب شقة'**
  String get communityAuthorHomeowner;

  /// No description provided for @communityAuthorProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف موثّق'**
  String get communityAuthorProfessional;

  /// No description provided for @communityMemberFallback.
  ///
  /// In ar, this message translates to:
  /// **'عضو في المجتمع'**
  String get communityMemberFallback;

  /// No description provided for @communityTimePublic.
  ///
  /// In ar, this message translates to:
  /// **'منشور منذ {time}'**
  String communityTimePublic(String time);

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

  /// No description provided for @commentReply.
  ///
  /// In ar, this message translates to:
  /// **'رد'**
  String get commentReply;

  /// No description provided for @commentLike.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب بالتعليق'**
  String get commentLike;

  /// No description provided for @commentUnlike.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الإعجاب بالتعليق'**
  String get commentUnlike;

  /// No description provided for @editComment.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التعليق'**
  String get editComment;

  /// No description provided for @deleteComment.
  ///
  /// In ar, this message translates to:
  /// **'حذف التعليق'**
  String get deleteComment;

  /// No description provided for @deleteCommentConfirm.
  ///
  /// In ar, this message translates to:
  /// **'متأكد إنك عايز تحذف التعليق؟'**
  String get deleteCommentConfirm;

  /// No description provided for @commentUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تعديل التعليق'**
  String get commentUpdated;

  /// No description provided for @commentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف التعليق'**
  String get commentDeleted;

  /// No description provided for @replyingToComment.
  ///
  /// In ar, this message translates to:
  /// **'بترد على تعليق'**
  String get replyingToComment;

  /// No description provided for @commentEditedLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم التعديل'**
  String get commentEditedLabel;

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

  /// No description provided for @sponsoredProfessionals.
  ///
  /// In ar, this message translates to:
  /// **'محترفين مميزين'**
  String get sponsoredProfessionals;

  /// No description provided for @paidPlacementLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعلان مدفوع'**
  String get paidPlacementLabel;

  /// No description provided for @specialProTitle.
  ///
  /// In ar, this message translates to:
  /// **'ظهور مميز'**
  String get specialProTitle;

  /// No description provided for @specialProSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خلّي ملفك يظهر في بداية النتائج المناسبة ليك'**
  String get specialProSubtitle;

  /// No description provided for @specialProValueLine.
  ///
  /// In ar, this message translates to:
  /// **'مساحة واضحة لشغلك، من غير ما نخلط الإعلان بالثقة'**
  String get specialProValueLine;

  /// No description provided for @specialProBenefit.
  ///
  /// In ar, this message translates to:
  /// **'ظهور مميز لمدة ٧ أيام في النتائج المناسبة لمجالك ومناطق شغلك'**
  String get specialProBenefit;

  /// No description provided for @specialProFairness.
  ///
  /// In ar, this message translates to:
  /// **'التقييم والتوثيق والأعمال المنجزة تفضل مستقلة عن الدفع'**
  String get specialProFairness;

  /// No description provided for @specialProPriceLine.
  ///
  /// In ar, this message translates to:
  /// **'١٩٩ جنيه لمدة ٧ أيام'**
  String get specialProPriceLine;

  /// No description provided for @specialProCta.
  ///
  /// In ar, this message translates to:
  /// **'اطلب الظهور المميز'**
  String get specialProCta;

  /// No description provided for @specialProActive.
  ///
  /// In ar, this message translates to:
  /// **'الظهور المميز شغال'**
  String get specialProActive;

  /// No description provided for @specialProExpiresOn.
  ///
  /// In ar, this message translates to:
  /// **'الظهور المميز مستمر لحد {date}'**
  String specialProExpiresOn(String date);

  /// No description provided for @specialProPending.
  ///
  /// In ar, this message translates to:
  /// **'طلب الظهور قيد المراجعة'**
  String get specialProPending;

  /// No description provided for @specialProPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'هنراجع التحويل ونفعّل الظهور بعد الموافقة.'**
  String get specialProPendingBody;

  /// No description provided for @specialProActivationNote.
  ///
  /// In ar, this message translates to:
  /// **'بعد رفع إيصال التحويل، فريقنا يراجع الطلب يدويًا.'**
  String get specialProActivationNote;

  /// No description provided for @specialProManage.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الظهور المميز'**
  String get specialProManage;

  /// No description provided for @specialProNoGuarantee.
  ///
  /// In ar, this message translates to:
  /// **'الظهور يساعد العملاء يلاقوك، لكنه لا يضمن طلبات أو تقييمات.'**
  String get specialProNoGuarantee;

  /// No description provided for @specialProScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'ظهورك المميز'**
  String get specialProScreenTitle;

  /// No description provided for @paymentWeekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعي'**
  String get paymentWeekly;

  /// No description provided for @paySpecialPlacement.
  ///
  /// In ar, this message translates to:
  /// **'اطلب الظهور المميز'**
  String get paySpecialPlacement;

  /// No description provided for @paySpecialPlacementSub.
  ///
  /// In ar, this message translates to:
  /// **'١٩٩ جنيه لمدة ٧ أيام بعد مراجعة التحويل'**
  String get paySpecialPlacementSub;

  /// No description provided for @specialPlacementSubmittedTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب الظهور اتبعت'**
  String get specialPlacementSubmittedTitle;

  /// No description provided for @specialPlacementSubmittedBody.
  ///
  /// In ar, this message translates to:
  /// **'هنراجع التحويل ونفعّل الظهور بعد الموافقة.'**
  String get specialPlacementSubmittedBody;

  /// No description provided for @specialPlacementDone.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get specialPlacementDone;

  /// No description provided for @specialPlacementAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الظهور المميز'**
  String get specialPlacementAmountLabel;

  /// No description provided for @specialPlacementUploadLabel.
  ///
  /// In ar, this message translates to:
  /// **'ارفع إيصال التحويل'**
  String get specialPlacementUploadLabel;

  /// No description provided for @specialPlacementReferenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم العملية (اختياري)'**
  String get specialPlacementReferenceLabel;

  /// No description provided for @specialPlacementSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get specialPlacementSubmit;

  /// No description provided for @specialPlacementTitle.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب ظهور مميز'**
  String get specialPlacementTitle;

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

  /// No description provided for @verifiedIdentityTitle.
  ///
  /// In ar, this message translates to:
  /// **'إيه معنى موثّق؟'**
  String get verifiedIdentityTitle;

  /// No description provided for @verifiedIdentityBody.
  ///
  /// In ar, this message translates to:
  /// **'فريق شطّب راجع مستندات الهوية اللي قدمها المحترف. العلامة دي لا تعني ضمان نتيجة كل مشروع أو إن كل أعماله اتراجعت.'**
  String get verifiedIdentityBody;

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

  /// No description provided for @requestsPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get requestsPageTitle;

  /// No description provided for @requestsUsage.
  ///
  /// In ar, this message translates to:
  /// **'استخدمت {used} من {limit} عروضك المجانية خلال آخر ٣٠ يوم'**
  String requestsUsage(String used, String limit);

  /// No description provided for @requestsProStatus.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك برو مفعّل — عروضك وطلباتك متاحة'**
  String get requestsProStatus;

  /// No description provided for @requestsPlanRefreshError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نحدّث حالة باقتك دلوقتي.'**
  String get requestsPlanRefreshError;

  /// No description provided for @requestsPlanRetry.
  ///
  /// In ar, this message translates to:
  /// **'حدّث حالة الباقة'**
  String get requestsPlanRetry;

  /// No description provided for @requestsOpenDetails.
  ///
  /// In ar, this message translates to:
  /// **'شوف تفاصيل الطلب'**
  String get requestsOpenDetails;

  /// No description provided for @requestsQuoteType.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب عرض سعر'**
  String get requestsQuoteType;

  /// No description provided for @requestsPublishedOn.
  ///
  /// In ar, this message translates to:
  /// **'نُشر في {date}'**
  String requestsPublishedOn(String date);

  /// No description provided for @requestsLockedWithPro.
  ///
  /// In ar, this message translates to:
  /// **'متاح مع برو'**
  String get requestsLockedWithPro;

  /// No description provided for @requestsProContactAvailable.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل متاحة مع برو'**
  String get requestsProContactAvailable;

  /// No description provided for @requestsProtectedContact.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل محمية'**
  String get requestsProtectedContact;

  /// No description provided for @requestsLocationVisible.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الطلب ظاهرة ليك'**
  String get requestsLocationVisible;

  /// No description provided for @requestsOtherTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات تانية'**
  String get requestsOtherTitle;

  /// No description provided for @requestsProHeadline.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده مناسب لشغلك؟'**
  String get requestsProHeadline;

  /// No description provided for @requestsProEmphasis.
  ///
  /// In ar, this message translates to:
  /// **'متسيبوش يروح.'**
  String get requestsProEmphasis;

  /// No description provided for @requestsProDescription.
  ///
  /// In ar, this message translates to:
  /// **'برو بيفتحلك بيانات التواصل ويخليك تقدم عروض من غير حد.'**
  String get requestsProDescription;

  /// No description provided for @requestsBenefitContact.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل'**
  String get requestsBenefitContact;

  /// No description provided for @requestsBenefitUnlimited.
  ///
  /// In ar, this message translates to:
  /// **'عروض من غير حد'**
  String get requestsBenefitUnlimited;

  /// No description provided for @requestsBenefitRanking.
  ///
  /// In ar, this message translates to:
  /// **'ظهور أعلى في البحث'**
  String get requestsBenefitRanking;

  /// No description provided for @requestsAnnualSaving.
  ///
  /// In ar, this message translates to:
  /// **'وفّرت {amount} ج.م مع الخطة السنوية'**
  String requestsAnnualSaving(String amount);

  /// No description provided for @requestsTrialBilling.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ شهر مجاني، وبعده أول خصم حسب الخطة'**
  String get requestsTrialBilling;

  /// No description provided for @requestsPaidBilling.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك مدفوع — التفعيل بعد تأكيد التحويل'**
  String get requestsPaidBilling;

  /// No description provided for @requestsCtaTrial.
  ///
  /// In ar, this message translates to:
  /// **'افتح الطلب وابدأ شهر مجاني'**
  String get requestsCtaTrial;

  /// No description provided for @requestsCtaPaid.
  ///
  /// In ar, this message translates to:
  /// **'افتح الطلب واشترك في برو'**
  String get requestsCtaPaid;

  /// No description provided for @requestsPaymentNote.
  ///
  /// In ar, this message translates to:
  /// **'دفع آمن — التفعيل بعد مراجعة التحويل'**
  String get requestsPaymentNote;

  /// No description provided for @requestsCheckoutFailed.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة في فتح الدفع، حاول تاني.'**
  String get requestsCheckoutFailed;

  /// No description provided for @requestsProUnlocked.
  ///
  /// In ar, this message translates to:
  /// **'برو مفعّل — تقدر تتابع الطلب وتقدّم عرضك'**
  String get requestsProUnlocked;

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
  /// **'بتدور على مين أو محتاج تعمل إيه؟'**
  String get searchHint;

  /// No description provided for @discoverHeroKicker.
  ///
  /// In ar, this message translates to:
  /// **'اختار الصح لبيتك'**
  String get discoverHeroKicker;

  /// No description provided for @discoverHeroTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحترفين'**
  String get discoverHeroTitle;

  /// No description provided for @discoverHeroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'محترفين موثوقين وشغل واضح'**
  String get discoverHeroSubtitle;

  /// No description provided for @professionalsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'{count} محترف متاح ليك'**
  String professionalsAvailable(int count);

  /// No description provided for @trustedProfessionals.
  ///
  /// In ar, this message translates to:
  /// **'محترفين موثوقين'**
  String get trustedProfessionals;

  /// No description provided for @trustedProfessionalsHint.
  ///
  /// In ar, this message translates to:
  /// **'بناءً على تقييمات وشغل حقيقي'**
  String get trustedProfessionalsHint;

  /// No description provided for @changeBrowseLocationShort.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المكان'**
  String get changeBrowseLocationShort;

  /// No description provided for @discoverPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحترفين'**
  String get discoverPageTitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بتدور على مين؟'**
  String get discoverSearchHint;

  /// No description provided for @featuredProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف مميز'**
  String get featuredProfessional;

  /// No description provided for @customerReviews.
  ///
  /// In ar, this message translates to:
  /// **'تقييمات العملاء'**
  String get customerReviews;

  /// No description provided for @completedProjectsShort.
  ///
  /// In ar, this message translates to:
  /// **'مشروع مكتمل'**
  String get completedProjectsShort;

  /// No description provided for @verifiedByShattab.
  ///
  /// In ar, this message translates to:
  /// **'موثوق من شطب'**
  String get verifiedByShattab;

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

  /// No description provided for @topRatedCollectionDescription.
  ///
  /// In ar, this message translates to:
  /// **'محترفين عندهم تقييمات حقيقية من العملاء'**
  String get topRatedCollectionDescription;

  /// No description provided for @noRatedProfessionalsMessage.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش محترفين عندهم تقييمات منشورة.'**
  String get noRatedProfessionalsMessage;

  /// No description provided for @recentWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'شغل اتعمل بجد'**
  String get recentWorkTitle;

  /// No description provided for @allProfessionalsCollectionDescription.
  ///
  /// In ar, this message translates to:
  /// **'كل المحترفين المتاحين على شطّب'**
  String get allProfessionalsCollectionDescription;

  /// No description provided for @nearbyProfessionalsCollectionDescription.
  ///
  /// In ar, this message translates to:
  /// **'محترفين بيخدموا منطقتك'**
  String get nearbyProfessionalsCollectionDescription;

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

  /// No description provided for @homeServicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'خدماتنا'**
  String get homeServicesTitle;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @specialtyPaint.
  ///
  /// In ar, this message translates to:
  /// **'دهانات'**
  String get specialtyPaint;

  /// No description provided for @specialtyFlooring.
  ///
  /// In ar, this message translates to:
  /// **'أرضيات'**
  String get specialtyFlooring;

  /// No description provided for @specialtyKitchen.
  ///
  /// In ar, this message translates to:
  /// **'مطابخ'**
  String get specialtyKitchen;

  /// No description provided for @specialtyBathroom.
  ///
  /// In ar, this message translates to:
  /// **'حمامات'**
  String get specialtyBathroom;

  /// No description provided for @specialtyElectrical.
  ///
  /// In ar, this message translates to:
  /// **'كهرباء'**
  String get specialtyElectrical;

  /// No description provided for @specialtyPlumbing.
  ///
  /// In ar, this message translates to:
  /// **'سباكة'**
  String get specialtyPlumbing;

  /// No description provided for @specialtyCarpentry.
  ///
  /// In ar, this message translates to:
  /// **'نجارة'**
  String get specialtyCarpentry;

  /// No description provided for @specialtyDesign.
  ///
  /// In ar, this message translates to:
  /// **'تصميم داخلي'**
  String get specialtyDesign;

  /// No description provided for @specialtyFullRenovation.
  ///
  /// In ar, this message translates to:
  /// **'تشطيبات كاملة'**
  String get specialtyFullRenovation;

  /// No description provided for @shattabVerifiedProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف موثّق من شطّب'**
  String get shattabVerifiedProfessional;

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

  /// No description provided for @briefLifecycleTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة طلبك'**
  String get briefLifecycleTitle;

  /// No description provided for @briefLifecycleRequestPosted.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الطلب'**
  String get briefLifecycleRequestPosted;

  /// No description provided for @briefLifecycleRequestPostedBody.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل طلبك اتسجلت وتقدر تتابع تحديثاته هنا.'**
  String get briefLifecycleRequestPostedBody;

  /// No description provided for @briefLifecycleWaitingForQuotes.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار العروض'**
  String get briefLifecycleWaitingForQuotes;

  /// No description provided for @briefLifecycleWaitingForQuotesBody.
  ///
  /// In ar, this message translates to:
  /// **'العروض هتظهر هنا أول ما يوصل عرض جديد.'**
  String get briefLifecycleWaitingForQuotesBody;

  /// No description provided for @briefLifecycleQuotesReceived.
  ///
  /// In ar, this message translates to:
  /// **'وصلت عروض'**
  String get briefLifecycleQuotesReceived;

  /// No description provided for @briefLifecycleQuotesReceivedBody.
  ///
  /// In ar, this message translates to:
  /// **'راجع العروض واختار المحترف الأنسب ليك.'**
  String get briefLifecycleQuotesReceivedBody;

  /// No description provided for @briefLifecycleQuotesLoading.
  ///
  /// In ar, this message translates to:
  /// **'بنحدّث حالة العروض...'**
  String get briefLifecycleQuotesLoading;

  /// No description provided for @briefLifecycleQuotesError.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نحدّث العروض دلوقتي. افتح قسم العروض وحاول تاني.'**
  String get briefLifecycleQuotesError;

  /// No description provided for @briefLifecycleWorkStarted.
  ///
  /// In ar, this message translates to:
  /// **'بدأ التنفيذ'**
  String get briefLifecycleWorkStarted;

  /// No description provided for @briefLifecycleWorkStartedBody.
  ///
  /// In ar, this message translates to:
  /// **'اتقبل العرض، والخطوة الجاية متابعة التنفيذ.'**
  String get briefLifecycleWorkStartedBody;

  /// No description provided for @briefLifecycleConfirmCompletion.
  ///
  /// In ar, this message translates to:
  /// **'أكد اكتمال الشغل'**
  String get briefLifecycleConfirmCompletion;

  /// No description provided for @briefLifecycleConfirmCompletionBody.
  ///
  /// In ar, this message translates to:
  /// **'راجع النتيجة وأكد إن الشغل خلص.'**
  String get briefLifecycleConfirmCompletionBody;

  /// No description provided for @briefLifecycleCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الشغل'**
  String get briefLifecycleCompleted;

  /// No description provided for @briefLifecycleCompletedBody.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تسيب تقييم موثّق عن تجربتك.'**
  String get briefLifecycleCompletedBody;

  /// No description provided for @briefLifecycleCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب'**
  String get briefLifecycleCancelled;

  /// No description provided for @briefLifecycleCancelledBody.
  ///
  /// In ar, this message translates to:
  /// **'الطلب ده مش متاح لاستقبال عروض جديدة.'**
  String get briefLifecycleCancelledBody;

  /// No description provided for @briefNextStepQuotes.
  ///
  /// In ar, this message translates to:
  /// **'راجع العروض واختار المحترف'**
  String get briefNextStepQuotes;

  /// No description provided for @briefNextStepFollowWork.
  ///
  /// In ar, this message translates to:
  /// **'تابع تنفيذ الشغل'**
  String get briefNextStepFollowWork;

  /// No description provided for @briefNextStepConfirmWork.
  ///
  /// In ar, this message translates to:
  /// **'راجع وأكد اكتمال الشغل'**
  String get briefNextStepConfirmWork;

  /// No description provided for @briefNextStepReview.
  ///
  /// In ar, this message translates to:
  /// **'شارك تقييمك الموثّق'**
  String get briefNextStepReview;

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
  /// **'التواصل من واتساب'**
  String get contactViaWhatsApp;

  /// No description provided for @whatsappShort.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsappShort;

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

  /// No description provided for @greetingPersonalized.
  ///
  /// In ar, this message translates to:
  /// **'{greeting} يا {name}'**
  String greetingPersonalized(String greeting, String name);

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

  /// No description provided for @requestPriceQuote.
  ///
  /// In ar, this message translates to:
  /// **'اطلب عرض سعر'**
  String get requestPriceQuote;

  /// No description provided for @contactThroughShattab.
  ///
  /// In ar, this message translates to:
  /// **'تواصل من خلال شطّب'**
  String get contactThroughShattab;

  /// No description provided for @professionalWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'شغل اتعمل بجد'**
  String get professionalWorkTitle;

  /// No description provided for @fromOurClients.
  ///
  /// In ar, this message translates to:
  /// **'من عملائنا'**
  String get fromOurClients;

  /// No description provided for @viewAllReviews.
  ///
  /// In ar, this message translates to:
  /// **'شوف كل التقييمات'**
  String get viewAllReviews;

  /// No description provided for @shattabClient.
  ///
  /// In ar, this message translates to:
  /// **'عميل من شطّب'**
  String get shattabClient;

  /// No description provided for @verifiedReviewFromCompletedJob.
  ///
  /// In ar, this message translates to:
  /// **'تقييم موثّق بعد شغل مكتمل'**
  String get verifiedReviewFromCompletedJob;

  /// No description provided for @noPublicWorkYet.
  ///
  /// In ar, this message translates to:
  /// **'المحترف لسه مضافش أعمال للعرض.'**
  String get noPublicWorkYet;

  /// No description provided for @contactPrivacyShareHint.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التواصل بأمان من خلال شطّب.'**
  String get contactPrivacyShareHint;

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
  /// **'اكتب \\\"حذف\\\" عشان تأكد'**
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
  /// **'المحترف استلم تفاصيل مشروعك وهيتواصل معاك قريب.\\\nتقدر تكلّمه دلوقتي على واتساب لو حابب تستعجل.'**
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

  /// No description provided for @adjustOpportunityPreferences.
  ///
  /// In ar, this message translates to:
  /// **'اضبط تفضيلات فرصك'**
  String get adjustOpportunityPreferences;

  /// No description provided for @budgetAndTimingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية وموعد البدء'**
  String get budgetAndTimingTitle;

  /// No description provided for @budgetAndTimingUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الطلب لسه محددش الميزانية أو موعد البدء. تقدر تسأل عنهم داخل عرضك.'**
  String get budgetAndTimingUnavailable;

  /// No description provided for @clearFilters.
  ///
  /// In ar, this message translates to:
  /// **'امسح الفلاتر'**
  String get clearFilters;

  /// No description provided for @competitionUnavailableHint.
  ///
  /// In ar, this message translates to:
  /// **'مستوى المنافسة هيظهر لما يتوفر عدد العروض على الفرصة.'**
  String get competitionUnavailableHint;

  /// No description provided for @completeOpportunityPreferencesHint.
  ///
  /// In ar, this message translates to:
  /// **'حدّد تخصصك ومناطق شغلك عشان نرشحلك فرص أنسب.'**
  String get completeOpportunityPreferencesHint;

  /// No description provided for @completeProfileBeforeApplying.
  ///
  /// In ar, this message translates to:
  /// **'كمّل بياناتك الأول'**
  String get completeProfileBeforeApplying;

  /// No description provided for @distanceUnavailableHint.
  ///
  /// In ar, this message translates to:
  /// **'بنطابق على مناطق شغلك المحفوظة. المسافة بالكيلومتر هتتوفر بعد تفعيل الموقع.'**
  String get distanceUnavailableHint;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @filterAllLocations.
  ///
  /// In ar, this message translates to:
  /// **'كل المناطق'**
  String get filterAllLocations;

  /// No description provided for @filterAnyTime.
  ///
  /// In ar, this message translates to:
  /// **'أي وقت'**
  String get filterAnyTime;

  /// No description provided for @filterFresh.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get filterFresh;

  /// No description provided for @filterLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get filterLocation;

  /// No description provided for @filterNearYou.
  ///
  /// In ar, this message translates to:
  /// **'مناطق شغلك'**
  String get filterNearYou;

  /// No description provided for @filterNotApplied.
  ///
  /// In ar, this message translates to:
  /// **'لم أقدّم عليها'**
  String get filterNotApplied;

  /// No description provided for @filterHideApplied.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الفرص اللي قدّمت عليها'**
  String get filterHideApplied;

  /// No description provided for @filterPublishedTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت النشر'**
  String get filterPublishedTime;

  /// No description provided for @filtersApplyHint.
  ///
  /// In ar, this message translates to:
  /// **'هيتم تطبيق الفلاتر على الفرص المتاحة.'**
  String get filtersApplyHint;

  /// No description provided for @followQuoteAction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة العرض'**
  String get followQuoteAction;

  /// No description provided for @jobRadarTitle.
  ///
  /// In ar, this message translates to:
  /// **'رادار الشغل'**
  String get jobRadarTitle;

  /// No description provided for @opportunitySummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص فرص الشغل'**
  String get opportunitySummaryTitle;

  /// No description provided for @opportunitySummaryHeading.
  ///
  /// In ar, this message translates to:
  /// **'ملخص فرصك'**
  String get opportunitySummaryHeading;

  /// No description provided for @opportunityCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'فرصة مناسبة'**
  String get opportunityCountLabel;

  /// No description provided for @opportunityFreshCount.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get opportunityFreshCount;

  /// No description provided for @opportunityAreaCount.
  ///
  /// In ar, this message translates to:
  /// **'في مناطق شغلك'**
  String get opportunityAreaCount;

  /// No description provided for @opportunityWeekCount.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get opportunityWeekCount;

  /// No description provided for @searchForMatchingOpportunities.
  ///
  /// In ar, this message translates to:
  /// **'دور على فرص مناسبة لشغلك'**
  String get searchForMatchingOpportunities;

  /// No description provided for @opportunitySortTitle.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الفرص'**
  String get opportunitySortTitle;

  /// No description provided for @opportunitySortRecommended.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر مناسبة'**
  String get opportunitySortRecommended;

  /// No description provided for @opportunitySortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get opportunitySortNewest;

  /// No description provided for @opportunitySortLabel.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الفرص حسب {sort}'**
  String opportunitySortLabel(String sort);

  /// No description provided for @opportunityFilterAction.
  ///
  /// In ar, this message translates to:
  /// **'تصفية الفرص، {count} فلاتر مفعّلة'**
  String opportunityFilterAction(int count);

  /// No description provided for @matchingOpportunitiesHeader.
  ///
  /// In ar, this message translates to:
  /// **'عندك {count} فرص مناسبة لشغلك'**
  String matchingOpportunitiesHeader(int count);

  /// No description provided for @opportunityCompactSummary.
  ///
  /// In ar, this message translates to:
  /// **'{count} مناسبة · {fresh} جديدة النهارده · {area} في مناطق شغلك'**
  String opportunityCompactSummary(int count, int fresh, int area);

  /// No description provided for @projectPhotoLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة مشروع'**
  String get projectPhotoLabel;

  /// No description provided for @projectPhotoLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل صورة المشروع'**
  String get projectPhotoLoading;

  /// No description provided for @opportunityMediaUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'صورة المشروع غير متاحة'**
  String get opportunityMediaUnavailable;

  /// No description provided for @loadMoreProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل فرص تانية'**
  String get loadMoreProgress;

  /// No description provided for @loadMoreError.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة في تحميل فرص تانية'**
  String get loadMoreError;

  /// No description provided for @latestOpportunityTime.
  ///
  /// In ar, this message translates to:
  /// **'آخر فرصة مناسبة نزلت {time}'**
  String latestOpportunityTime(String time);

  /// No description provided for @makeOpportunitiesMoreAccurate.
  ///
  /// In ar, this message translates to:
  /// **'خلّي فرصك أدق'**
  String get makeOpportunitiesMoreAccurate;

  /// No description provided for @matchDataInsufficient.
  ///
  /// In ar, this message translates to:
  /// **'كمّل تخصصاتك ومناطق شغلك عشان نوضح سبب الترشيح بدقة أكبر.'**
  String get matchDataInsufficient;

  /// No description provided for @matchReasonFresh.
  ///
  /// In ar, this message translates to:
  /// **'فرصة جديدة ولسه نازلة'**
  String get matchReasonFresh;

  /// No description provided for @matchReasonPhotos.
  ///
  /// In ar, this message translates to:
  /// **'فيها صور واضحة للمشروع'**
  String get matchReasonPhotos;

  /// No description provided for @matchReasonPortfolio.
  ///
  /// In ar, this message translates to:
  /// **'شبه أعمال موجودة في ملفك'**
  String get matchReasonPortfolio;

  /// No description provided for @matchReasonServiceArea.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة ضمن نطاق شغلك'**
  String get matchReasonServiceArea;

  /// No description provided for @matchReasonSpecialty.
  ///
  /// In ar, this message translates to:
  /// **'تخصصك يطابق المطلوب'**
  String get matchReasonSpecialty;

  /// No description provided for @moreMatchingOpportunities.
  ///
  /// In ar, this message translates to:
  /// **'فرص تانية مناسبة'**
  String get moreMatchingOpportunities;

  /// No description provided for @newOpportunitiesForYou.
  ///
  /// In ar, this message translates to:
  /// **'فرص جديدة مناسبة ليك'**
  String get newOpportunitiesForYou;

  /// No description provided for @noOpportunityMatches.
  ///
  /// In ar, this message translates to:
  /// **'ملقيناش فرص بالفلاتر دي'**
  String get noOpportunityMatches;

  /// No description provided for @noOpportunityMatchesHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب توسّع نطاق البحث أو تمسح بعض الفلاتر، وهنعرضلك الفرص الجديدة أول ما تنزل.'**
  String get noOpportunityMatchesHint;

  /// No description provided for @notSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSpecified;

  /// No description provided for @opportunityAcceptingOffers.
  ///
  /// In ar, this message translates to:
  /// **'تستقبل عروض'**
  String get opportunityAcceptingOffers;

  /// No description provided for @opportunityClosed.
  ///
  /// In ar, this message translates to:
  /// **'الفرصة اتقفلت'**
  String get opportunityClosed;

  /// No description provided for @opportunityDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الفرصة'**
  String get opportunityDetailsTitle;

  /// No description provided for @opportunityFiltersTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفية الفرص'**
  String get opportunityFiltersTitle;

  /// No description provided for @opportunityOpen.
  ///
  /// In ar, this message translates to:
  /// **'الفرصة مفتوحة'**
  String get opportunityOpen;

  /// No description provided for @opportunityQuality.
  ///
  /// In ar, this message translates to:
  /// **'جودة الفرصة'**
  String get opportunityQuality;

  /// No description provided for @opportunityRemovedFromSaved.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة الفرصة من المحفوظات'**
  String get opportunityRemovedFromSaved;

  /// No description provided for @opportunitySaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الفرصة'**
  String get opportunitySaved;

  /// No description provided for @opportunityTimeline.
  ///
  /// In ar, this message translates to:
  /// **'خط زمني للفرصة'**
  String get opportunityTimeline;

  /// No description provided for @opportunityViewed.
  ///
  /// In ar, this message translates to:
  /// **'شفتها قبل كده'**
  String get opportunityViewed;

  /// No description provided for @ownerNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة صاحب الطلب'**
  String get ownerNoteTitle;

  /// No description provided for @ownerPrivacyHint.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل بتفضل خاصة لحد ما يبدأ التواصل من خلال العرض.'**
  String get ownerPrivacyHint;

  /// No description provided for @projectDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المشروع'**
  String get projectDetailsTitle;

  /// No description provided for @quoteAlreadySent.
  ///
  /// In ar, this message translates to:
  /// **'قدّمت عرضك'**
  String get quoteAlreadySent;

  /// No description provided for @radarFresh.
  ///
  /// In ar, this message translates to:
  /// **'جديدة اليوم'**
  String get radarFresh;

  /// No description provided for @radarInYourAreas.
  ///
  /// In ar, this message translates to:
  /// **'في مناطق شغلك'**
  String get radarInYourAreas;

  /// No description provided for @radarMatchesThisWeek.
  ///
  /// In ar, this message translates to:
  /// **'مناسبة هذا الأسبوع'**
  String get radarMatchesThisWeek;

  /// No description provided for @recommendedForYou.
  ///
  /// In ar, this message translates to:
  /// **'موصى بيها ليك'**
  String get recommendedForYou;

  /// No description provided for @relevantOpportunity.
  ///
  /// In ar, this message translates to:
  /// **'فرصة مناسبة'**
  String get relevantOpportunity;

  /// No description provided for @removeOpportunityFromSaved.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الفرصة من المحفوظات'**
  String get removeOpportunityFromSaved;

  /// No description provided for @resetFilters.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get resetFilters;

  /// No description provided for @clearAllFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح كل الفلاتر'**
  String get clearAllFilters;

  /// No description provided for @saveOpportunity.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الفرصة'**
  String get saveOpportunity;

  /// No description provided for @searchPreferencesCompletion.
  ///
  /// In ar, this message translates to:
  /// **'اكتمال تفضيلات البحث {percent}%'**
  String searchPreferencesCompletion(int percent);

  /// No description provided for @showOpportunityCount.
  ///
  /// In ar, this message translates to:
  /// **'عرض {count} فرصة'**
  String showOpportunityCount(int count);

  /// No description provided for @strongMatch.
  ///
  /// In ar, this message translates to:
  /// **'توافق قوي'**
  String get strongMatch;

  /// No description provided for @submitYourQuote.
  ///
  /// In ar, this message translates to:
  /// **'قدّم عرضك'**
  String get submitYourQuote;

  /// No description provided for @timelineAcceptOffers.
  ///
  /// In ar, this message translates to:
  /// **'استقبال العروض'**
  String get timelineAcceptOffers;

  /// No description provided for @timelineChooseContractor.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المقاول'**
  String get timelineChooseContractor;

  /// No description provided for @timelineStartWork.
  ///
  /// In ar, this message translates to:
  /// **'بدء التنفيذ'**
  String get timelineStartWork;

  /// No description provided for @viewOpportunityDetails.
  ///
  /// In ar, this message translates to:
  /// **'شوف التفاصيل'**
  String get viewOpportunityDetails;

  /// No description provided for @whyOpportunityMatches.
  ///
  /// In ar, this message translates to:
  /// **'ليه الفرصة دي مناسبة ليك؟'**
  String get whyOpportunityMatches;

  /// No description provided for @youHaveNewOpportunities.
  ///
  /// In ar, this message translates to:
  /// **'عندك'**
  String get youHaveNewOpportunities;

  /// No description provided for @homeownerAccountRole.
  ///
  /// In ar, this message translates to:
  /// **'صاحب شقة'**
  String get homeownerAccountRole;

  /// No description provided for @homeownerAreaFallback.
  ///
  /// In ar, this message translates to:
  /// **'موقعك المفضل'**
  String get homeownerAreaFallback;

  /// No description provided for @homeownerQuickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get homeownerQuickActions;

  /// No description provided for @homeownerSettingsPreview.
  ///
  /// In ar, this message translates to:
  /// **'إعداداتك'**
  String get homeownerSettingsPreview;

  /// No description provided for @homeownerAccountExperienceSection.
  ///
  /// In ar, this message translates to:
  /// **'تجربة حسابك'**
  String get homeownerAccountExperienceSection;

  /// No description provided for @homeownerEditProfileAction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get homeownerEditProfileAction;

  /// No description provided for @homeownerDiscoverSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن الأفضل'**
  String get homeownerDiscoverSubtitle;

  /// No description provided for @homeownerRequestsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تابع طلباتك'**
  String get homeownerRequestsSubtitle;

  /// No description provided for @homeownerSavedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'المحترفين المحفوظين'**
  String get homeownerSavedSubtitle;

  /// No description provided for @homeownerAppearanceRow.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get homeownerAppearanceRow;

  /// No description provided for @homeownerMotionRow.
  ///
  /// In ar, this message translates to:
  /// **'الحركة'**
  String get homeownerMotionRow;

  /// No description provided for @homeownerLanguageRow.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get homeownerLanguageRow;

  /// No description provided for @homeownerSettingsRow.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات والتفضيلات'**
  String get homeownerSettingsRow;

  /// No description provided for @homeownerSettingsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحكّم في إعدادات التطبيق'**
  String get homeownerSettingsSubtitle;

  /// No description provided for @homeownerLogoutSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تقدر ترجع في أي وقت'**
  String get homeownerLogoutSubtitle;

  /// No description provided for @homeownerSettingsExperienceSection.
  ///
  /// In ar, this message translates to:
  /// **'تجربة التطبيق'**
  String get homeownerSettingsExperienceSection;

  /// No description provided for @homeownerAppearanceAndMotionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر والحركة'**
  String get homeownerAppearanceAndMotionTitle;

  /// No description provided for @homeownerAppearanceAndMotionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار الشكل والحركة المناسبين ليك'**
  String get homeownerAppearanceAndMotionSubtitle;

  /// No description provided for @homeownerLegalSection.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والقانون'**
  String get homeownerLegalSection;

  /// No description provided for @homeownerPrivacySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اعرف إزاي بنحمي بياناتك'**
  String get homeownerPrivacySubtitle;

  /// No description provided for @homeownerTermsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع شروط استخدام شطّب'**
  String get homeownerTermsSubtitle;

  /// No description provided for @homeownerAccountSection.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get homeownerAccountSection;

  /// No description provided for @homeownerDeleteSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف نهائي لكل بيانات الحساب'**
  String get homeownerDeleteSubtitle;

  /// No description provided for @homeownerMotionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحركة'**
  String get homeownerMotionTitle;

  /// No description provided for @homeownerMotionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحكّم في حركة واجهات التطبيق'**
  String get homeownerMotionSubtitle;

  /// No description provided for @homeownerMotionAccessibility.
  ///
  /// In ar, this message translates to:
  /// **'لو الحركة بتتعبك، اختار مخفّضة أو بدون حركة لواجهة أهدى.'**
  String get homeownerMotionAccessibility;

  /// No description provided for @homeownerSaveSettings.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإعدادات'**
  String get homeownerSaveSettings;

  /// No description provided for @homeownerLanguageChoose.
  ///
  /// In ar, this message translates to:
  /// **'اختار لغة التطبيق'**
  String get homeownerLanguageChoose;

  /// No description provided for @homeownerLanguageArabicHint.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get homeownerLanguageArabicHint;

  /// No description provided for @homeownerLanguageEnglishHint.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get homeownerLanguageEnglishHint;

  /// No description provided for @homeownerLanguagePreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة اتجاه النص'**
  String get homeownerLanguagePreview;

  /// No description provided for @homeownerLanguageLtr.
  ///
  /// In ar, this message translates to:
  /// **'LTR'**
  String get homeownerLanguageLtr;

  /// No description provided for @homeownerLanguageRtl.
  ///
  /// In ar, this message translates to:
  /// **'RTL'**
  String get homeownerLanguageRtl;

  /// No description provided for @homeownerSaveLanguage.
  ///
  /// In ar, this message translates to:
  /// **'حفظ اللغة'**
  String get homeownerSaveLanguage;

  /// No description provided for @homeownerPrivacyIntro.
  ///
  /// In ar, this message translates to:
  /// **'بنحافظ على بياناتك ونستخدمها عشان نقدملك تجربة آمنة وأنسب ترشيحات للتشطيب.'**
  String get homeownerPrivacyIntro;

  /// No description provided for @homeownerTermsIntro.
  ///
  /// In ar, this message translates to:
  /// **'باستخدام شطّب، أنت بتوافق على القواعد اللي بتنظّم استخدام المنصة والتواصل مع المحترفين.'**
  String get homeownerTermsIntro;

  /// No description provided for @homeownerPrivacySection1Title.
  ///
  /// In ar, this message translates to:
  /// **'البيانات اللي بنجمعها'**
  String get homeownerPrivacySection1Title;

  /// No description provided for @homeownerPrivacySection1Body.
  ///
  /// In ar, this message translates to:
  /// **'بنستخدم بيانات الحساب الأساسية، ومعلومات السكن واهتمامات التشطيب اللي تختار تشاركها عشان نشغّل الخدمة.'**
  String get homeownerPrivacySection1Body;

  /// No description provided for @homeownerPrivacySection2Title.
  ///
  /// In ar, this message translates to:
  /// **'إزاي بنستخدم بياناتك'**
  String get homeownerPrivacySection2Title;

  /// No description provided for @homeownerPrivacySection2Body.
  ///
  /// In ar, this message translates to:
  /// **'بنستخدم بياناتك لعرض محترفين مناسبين، وتنظيم طلباتك، وتحسين أداء التطبيق وتقديم الدعم.'**
  String get homeownerPrivacySection2Body;

  /// No description provided for @homeownerPrivacySection3Title.
  ///
  /// In ar, this message translates to:
  /// **'حماية بياناتك'**
  String get homeownerPrivacySection3Title;

  /// No description provided for @homeownerPrivacySection3Body.
  ///
  /// In ar, this message translates to:
  /// **'بنطبّق ضوابط وصول وحماية مناسبة، ومش بنعرض بيانات التواصل في الملفات العامة بدون سبب واضح.'**
  String get homeownerPrivacySection3Body;

  /// No description provided for @homeownerPrivacySection4Title.
  ///
  /// In ar, this message translates to:
  /// **'اختياراتك'**
  String get homeownerPrivacySection4Title;

  /// No description provided for @homeownerPrivacySection4Body.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تعدّل بيانات ملفك، وتتحكّم في الإشعارات، وتطلب حذف حسابك من إعدادات الحساب.'**
  String get homeownerPrivacySection4Body;

  /// No description provided for @homeownerPrivacySection5Title.
  ///
  /// In ar, this message translates to:
  /// **'التواصل معنا'**
  String get homeownerPrivacySection5Title;

  /// No description provided for @homeownerPrivacySection5Body.
  ///
  /// In ar, this message translates to:
  /// **'لو عندك سؤال عن بياناتك أو الخصوصية، تواصل مع فريق الدعم من الزر الموجود أسفل الصفحة.'**
  String get homeownerPrivacySection5Body;

  /// No description provided for @homeownerTermsSection1Title.
  ///
  /// In ar, this message translates to:
  /// **'استخدام شطّب'**
  String get homeownerTermsSection1Title;

  /// No description provided for @homeownerTermsSection1Body.
  ///
  /// In ar, this message translates to:
  /// **'استخدم شطّب بطريقة قانونية ومحترمة، وقدّم معلومات حقيقية تساعد المحترفين على فهم طلبك.'**
  String get homeownerTermsSection1Body;

  /// No description provided for @homeownerTermsSection2Title.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات والتواصل'**
  String get homeownerTermsSection2Title;

  /// No description provided for @homeownerTermsSection2Body.
  ///
  /// In ar, this message translates to:
  /// **'المنصة بتنظّم الوصول للمحترفين، لكن الاتفاق النهائي وتفاصيل التنفيذ مسؤولية الأطراف المعنية.'**
  String get homeownerTermsSection2Body;

  /// No description provided for @homeownerTermsSection3Title.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى والصور'**
  String get homeownerTermsSection3Title;

  /// No description provided for @homeownerTermsSection3Body.
  ///
  /// In ar, this message translates to:
  /// **'اتأكد إن عندك الحق في الصور والمعلومات اللي ترفعها، وماتضيفش محتوى مخالف أو يعرّض حد للضرر.'**
  String get homeownerTermsSection3Body;

  /// No description provided for @homeownerTermsSection4Title.
  ///
  /// In ar, this message translates to:
  /// **'المحترفون المستقلون'**
  String get homeownerTermsSection4Title;

  /// No description provided for @homeownerTermsSection4Body.
  ///
  /// In ar, this message translates to:
  /// **'المحترفون بيقدّموا خدماتهم بشكل مستقل، فراجع ملفهم وتقييماتهم واتفق على التفاصيل قبل بدء العمل.'**
  String get homeownerTermsSection4Body;

  /// No description provided for @homeownerTermsSection5Title.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الشروط'**
  String get homeownerTermsSection5Title;

  /// No description provided for @homeownerTermsSection5Body.
  ///
  /// In ar, this message translates to:
  /// **'ممكن نحدّث الشروط لما تتغير الخدمة. هنوضح أي تغييرات مهمة داخل التطبيق.'**
  String get homeownerTermsSection5Body;

  /// No description provided for @homeownerContactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم'**
  String get homeownerContactSupport;

  /// No description provided for @homeownerLogoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج؟'**
  String get homeownerLogoutTitle;

  /// No description provided for @homeownerLogoutBody.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تسجّل دخولك تاني في أي وقت من غير ما تفقد طلباتك أو المحترفين المحفوظين.'**
  String get homeownerLogoutBody;

  /// No description provided for @homeownerStaySignedIn.
  ///
  /// In ar, this message translates to:
  /// **'البقاء في الحساب'**
  String get homeownerStaySignedIn;

  /// No description provided for @homeownerOrdersAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get homeownerOrdersAll;

  /// No description provided for @homeownerOrdersNew.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get homeownerOrdersNew;

  /// No description provided for @homeownerOrdersActive.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get homeownerOrdersActive;

  /// No description provided for @homeownerOrdersCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get homeownerOrdersCompleted;

  /// No description provided for @homeownerOrdersEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش طلبات'**
  String get homeownerOrdersEmptyTitle;

  /// No description provided for @homeownerOrdersEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'أول ما تبعت طلب لمحترف، هتقدر تتابع تفاصيله من هنا.'**
  String get homeownerOrdersEmptyMessage;

  /// No description provided for @homeownerOrdersDiscoverAction.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف المحترفين'**
  String get homeownerOrdersDiscoverAction;

  /// No description provided for @homeownerOrdersBackToAccount.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع لحسابي'**
  String get homeownerOrdersBackToAccount;

  /// No description provided for @homeownerSavedEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحترفين المحفوظين فاضية'**
  String get homeownerSavedEmptyTitle;

  /// No description provided for @homeownerSavedEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'احفظ المحترفين اللي عجبوك عشان ترجع لهم بسهولة.'**
  String get homeownerSavedEmptyMessage;

  /// No description provided for @homeownerSavedDiscoverAction.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف المحترفين'**
  String get homeownerSavedDiscoverAction;

  /// No description provided for @homeownerSavedHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط علامة الحفظ على أي محترف عشان يظهر هنا.'**
  String get homeownerSavedHint;

  /// No description provided for @changeLocation.
  ///
  /// In ar, this message translates to:
  /// **'غيّر مكان التصفح'**
  String get changeLocation;

  /// No description provided for @changeLocationDescription.
  ///
  /// In ar, this message translates to:
  /// **'اختار محافظة عشان تشوف المحترفين فيها'**
  String get changeLocationDescription;

  /// No description provided for @useProfileLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقع الملف'**
  String get useProfileLocation;

  /// No description provided for @notificationInboxTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationInboxTitle;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إشعارات جديدة'**
  String get notificationEmptyTitle;

  /// No description provided for @notificationEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'هنبلغك هنا بأي تحديثات تخص طلباتك وشغلك.'**
  String get notificationEmptyBody;

  /// No description provided for @notificationNewQuoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرض سعر جديد'**
  String get notificationNewQuoteTitle;

  /// No description provided for @notificationNewQuoteBody.
  ///
  /// In ar, this message translates to:
  /// **'وصلك عرض جديد على طلبك.'**
  String get notificationNewQuoteBody;

  /// No description provided for @notificationQuoteDecisionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث على عرضك'**
  String get notificationQuoteDecisionTitle;

  /// No description provided for @notificationQuoteAcceptedBody.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الطلب وافق على عرضك.'**
  String get notificationQuoteAcceptedBody;

  /// No description provided for @notificationQuoteDeclinedBody.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الطلب اختار عرضًا آخر للطلب.'**
  String get notificationQuoteDeclinedBody;

  /// No description provided for @notificationCompletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث على الشغل'**
  String get notificationCompletionTitle;

  /// No description provided for @notificationCompletionRequestedBody.
  ///
  /// In ar, this message translates to:
  /// **'المحترف بيقول إن الشغل خلص. راجع تفاصيل الطلب.'**
  String get notificationCompletionRequestedBody;

  /// No description provided for @notificationJobCompletedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد اكتمال المشروع.'**
  String get notificationJobCompletedBody;

  /// No description provided for @notificationNewReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييم جديد'**
  String get notificationNewReviewTitle;

  /// No description provided for @notificationNewReviewBody.
  ///
  /// In ar, this message translates to:
  /// **'العميل أضاف تقييمًا جديدًا على شغلك.'**
  String get notificationNewReviewBody;

  /// No description provided for @notificationVerificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث التوثيق'**
  String get notificationVerificationTitle;

  /// No description provided for @notificationVerificationApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'حسابك اتوثق بنجاح.'**
  String get notificationVerificationApprovedBody;

  /// No description provided for @notificationVerificationRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'راجع ملاحظات التوثيق وقدّم الطلب مرة تانية.'**
  String get notificationVerificationRejectedBody;

  /// No description provided for @notificationPaymentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الاشتراك'**
  String get notificationPaymentTitle;

  /// No description provided for @notificationPaymentApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل اشتراكك.'**
  String get notificationPaymentApprovedBody;

  /// No description provided for @notificationPaymentRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'طلب الدفع محتاج مراجعة.'**
  String get notificationPaymentRejectedBody;

  /// No description provided for @notificationCommunityTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاعل جديد'**
  String get notificationCommunityTitle;

  /// No description provided for @notificationPostLikedBody.
  ///
  /// In ar, this message translates to:
  /// **'حد عمل إعجاب على منشورك.'**
  String get notificationPostLikedBody;

  /// No description provided for @notificationPostCommentedBody.
  ///
  /// In ar, this message translates to:
  /// **'حد كتب تعليق على منشورك.'**
  String get notificationPostCommentedBody;

  /// No description provided for @notificationCommentRepliedBody.
  ///
  /// In ar, this message translates to:
  /// **'حد رد على تعليقك.'**
  String get notificationCommentRepliedBody;

  /// No description provided for @notificationCommentLikedBody.
  ///
  /// In ar, this message translates to:
  /// **'حد عمل إعجاب على تعليقك.'**
  String get notificationCommentLikedBody;

  /// No description provided for @homeHeroTitleLead.
  ///
  /// In ar, this message translates to:
  /// **'بيتك'**
  String get homeHeroTitleLead;

  /// No description provided for @homeHeroTitleRest.
  ///
  /// In ar, this message translates to:
  /// **'يستاهل حد يتقنه'**
  String get homeHeroTitleRest;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'محترفين موثوقين، قريبين من بيتك'**
  String get homeHeroSubtitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن خدمة أو محترف...'**
  String get homeSearchHint;

  /// No description provided for @homeQuickStartTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ طلبك بسرعة'**
  String get homeQuickStartTitle;

  /// No description provided for @homeQuickNearbyTitle.
  ///
  /// In ar, this message translates to:
  /// **'محترفون قريبون منك'**
  String get homeQuickNearbyTitle;

  /// No description provided for @homeQuickNearbySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل أسهل وأسرع'**
  String get homeQuickNearbySubtitle;

  /// No description provided for @homeQuickRequestsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تابع طلباتك'**
  String get homeQuickRequestsTitle;

  /// No description provided for @homeQuickRequestsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كلها في مكان واحد'**
  String get homeQuickRequestsSubtitle;

  /// No description provided for @homeQuickQuoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'اطلب عرض سعر'**
  String get homeQuickQuoteTitle;

  /// No description provided for @homeQuickQuoteSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مجانًا وسريعة'**
  String get homeQuickQuoteSubtitle;

  /// No description provided for @homeActiveRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبك الحالي'**
  String get homeActiveRequestTitle;

  /// No description provided for @homeActiveRequestFallback.
  ///
  /// In ar, this message translates to:
  /// **'طلبك جاهز للمتابعة مع المحترفين.'**
  String get homeActiveRequestFallback;

  /// No description provided for @homeViewProfile.
  ///
  /// In ar, this message translates to:
  /// **'عرض الملف'**
  String get homeViewProfile;

  /// No description provided for @homeContactWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'تواصل واتساب'**
  String get homeContactWhatsApp;

  /// No description provided for @homeStartTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من هنا'**
  String get homeStartTitle;

  /// No description provided for @homeStartDiscoverTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف المحترفين'**
  String get homeStartDiscoverTitle;

  /// No description provided for @homeStartDiscoverSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اعرف مين يناسب بيتك'**
  String get homeStartDiscoverSubtitle;

  /// No description provided for @homeStartQuoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'اطلب عرض سعر'**
  String get homeStartQuoteTitle;

  /// No description provided for @homeStartQuoteSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'احكي لنا عن اللي محتاجه'**
  String get homeStartQuoteSubtitle;

  /// No description provided for @homeStartWorkTitle.
  ///
  /// In ar, this message translates to:
  /// **'شوف شغل اتعمل'**
  String get homeStartWorkTitle;

  /// No description provided for @homeStartWorkSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاريع حقيقية قبل وبعد'**
  String get homeStartWorkSubtitle;

  /// No description provided for @homeStartCommunityTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسأل أهل الخبرة'**
  String get homeStartCommunityTitle;

  /// No description provided for @homeStartCommunitySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تجارب ونصايح من مجتمعنا'**
  String get homeStartCommunitySubtitle;

  /// No description provided for @homeProcessTitle.
  ///
  /// In ar, this message translates to:
  /// **'من الفكرة للتنفيذ'**
  String get homeProcessTitle;

  /// No description provided for @homeProcessStepOne.
  ///
  /// In ar, this message translates to:
  /// **'احكي عن احتياجك'**
  String get homeProcessStepOne;

  /// No description provided for @homeProcessStepOneBody.
  ///
  /// In ar, this message translates to:
  /// **'قول لنا عايز تشطب إيه'**
  String get homeProcessStepOneBody;

  /// No description provided for @homeProcessStepTwo.
  ///
  /// In ar, this message translates to:
  /// **'اختار المناسب ليك'**
  String get homeProcessStepTwo;

  /// No description provided for @homeProcessStepTwoBody.
  ///
  /// In ar, this message translates to:
  /// **'شوف شغل حقيقي وتواصل'**
  String get homeProcessStepTwoBody;

  /// No description provided for @homeProcessStepThree.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بثقة'**
  String get homeProcessStepThree;

  /// No description provided for @homeProcessStepThreeBody.
  ///
  /// In ar, this message translates to:
  /// **'تابع طلبك خطوة بخطوة'**
  String get homeProcessStepThreeBody;

  /// No description provided for @homeCommunityInviteTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسأل أهل الخبرة'**
  String get homeCommunityInviteTitle;

  /// No description provided for @homeCommunityInviteBody.
  ///
  /// In ar, this message translates to:
  /// **'شوف تجارب حقيقية من ناس بدأت من نفس المكان.'**
  String get homeCommunityInviteBody;

  /// No description provided for @homeClosingCtaTitle.
  ///
  /// In ar, this message translates to:
  /// **'جاهز تبدأ؟'**
  String get homeClosingCtaTitle;

  /// No description provided for @homeClosingCtaBody.
  ///
  /// In ar, this message translates to:
  /// **'احكي لنا عن بيتك وخلي الاختيار أسهل.'**
  String get homeClosingCtaBody;

  /// No description provided for @homeClosingCtaAction.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ طلبك'**
  String get homeClosingCtaAction;

  /// No description provided for @profileVerifiedStat.
  ///
  /// In ar, this message translates to:
  /// **'موثوق ومعتمد'**
  String get profileVerifiedStat;

  /// No description provided for @profileAboutCompany.
  ///
  /// In ar, this message translates to:
  /// **'نبذة عن الشركة'**
  String get profileAboutCompany;

  /// No description provided for @profileShowMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get profileShowMore;

  /// No description provided for @profileShowLess.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get profileShowLess;

  /// No description provided for @profileServicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'خدماتنا'**
  String get profileServicesTitle;

  /// No description provided for @profileHighlightsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أبرز الأعمال'**
  String get profileHighlightsTitle;

  /// No description provided for @profileProjectsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاريع منفذة'**
  String get profileProjectsTitle;

  /// No description provided for @profileTabAbout.
  ///
  /// In ar, this message translates to:
  /// **'نبذة'**
  String get profileTabAbout;

  /// No description provided for @profileTabWork.
  ///
  /// In ar, this message translates to:
  /// **'أعمالنا'**
  String get profileTabWork;

  /// No description provided for @profileTabReviews.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get profileTabReviews;

  /// No description provided for @profileClosingTitle.
  ///
  /// In ar, this message translates to:
  /// **'جاهز نبدأ مشروعك؟'**
  String get profileClosingTitle;

  /// No description provided for @profileClosingBody.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معه الآن واحصل على عرض سعر مجاني.'**
  String get profileClosingBody;

  /// No description provided for @profileClosingAction.
  ///
  /// In ar, this message translates to:
  /// **'اطلب عرض سعر الآن'**
  String get profileClosingAction;

  /// No description provided for @profileDirectCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصال مباشر'**
  String get profileDirectCall;

  /// No description provided for @profileFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get profileFilterAll;

  /// No description provided for @homeLiveActivityTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديثات طلبك'**
  String get homeLiveActivityTitle;

  /// No description provided for @homeLiveLatestActivity.
  ///
  /// In ar, this message translates to:
  /// **'آخر نشاط'**
  String get homeLiveLatestActivity;

  /// No description provided for @homeLiveEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مابدأتش'**
  String get homeLiveEmptyTitle;

  /// No description provided for @homeLiveEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بطلب سريع، وخلي المحترفين يشوفوا احتياجك.'**
  String get homeLiveEmptyMessage;

  /// No description provided for @homeLiveStartAction.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ طلبك'**
  String get homeLiveStartAction;

  /// No description provided for @homeLiveOpenRequests.
  ///
  /// In ar, this message translates to:
  /// **'شوف طلباتك'**
  String get homeLiveOpenRequests;

  /// No description provided for @homeLiveOpenNotifications.
  ///
  /// In ar, this message translates to:
  /// **'شوف الإشعارات'**
  String get homeLiveOpenNotifications;

  /// No description provided for @homeLiveErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نجيب آخر تحديث'**
  String get homeLiveErrorTitle;

  /// No description provided for @homeLiveAwaitingOffers.
  ///
  /// In ar, this message translates to:
  /// **'مستنيين العروض'**
  String get homeLiveAwaitingOffers;

  /// No description provided for @homeLiveWorkInProgress.
  ///
  /// In ar, this message translates to:
  /// **'الشغل شغال'**
  String get homeLiveWorkInProgress;

  /// No description provided for @homeLiveReviewCompletion.
  ///
  /// In ar, this message translates to:
  /// **'راجع الانتهاء'**
  String get homeLiveReviewCompletion;

  /// No description provided for @homeLiveCompleted.
  ///
  /// In ar, this message translates to:
  /// **'المشروع اكتمل'**
  String get homeLiveCompleted;

  /// No description provided for @homeLiveRequestPosted.
  ///
  /// In ar, this message translates to:
  /// **'اتنشر'**
  String get homeLiveRequestPosted;

  /// Number of unread notifications shown on the homeowner home activity card
  ///
  /// In ar, this message translates to:
  /// **'{count} إشعار'**
  String homeLiveUnreadCount(int count);

  /// No description provided for @quoteSentTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرضك اتبعت'**
  String get quoteSentTitle;

  /// No description provided for @quoteSentMessage.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الطلب استلم تفاصيل عرضك. هتوصلك أي تحديثات هنا.'**
  String get quoteSentMessage;

  /// No description provided for @draftRestored.
  ///
  /// In ar, this message translates to:
  /// **'رجعنا لك المسودة اللي حفظتها'**
  String get draftRestored;

  /// No description provided for @draftSavedAutomatically.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ تلقائياً على الجهاز ده'**
  String get draftSavedAutomatically;

  /// No description provided for @trustEvidenceTitle.
  ///
  /// In ar, this message translates to:
  /// **'علامات واضحة تساعدك تختار'**
  String get trustEvidenceTitle;

  /// No description provided for @trustEvidenceBody.
  ///
  /// In ar, this message translates to:
  /// **'راجع الأدلة اللي نقدر نثبتها قبل ما تبدأ كلامك مع المحترف.'**
  String get trustEvidenceBody;

  /// No description provided for @trustNewProfessional.
  ///
  /// In ar, this message translates to:
  /// **'محترف جديد على شطب'**
  String get trustNewProfessional;

  /// No description provided for @trustSafetyBody.
  ///
  /// In ar, this message translates to:
  /// **'لو حاجة مش واضحة، راجع التفاصيل أو كلّم شطب قبل ما تاخد قرار.'**
  String get trustSafetyBody;

  /// No description provided for @profileSafetyTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختيارك على وضوح'**
  String get profileSafetyTitle;

  /// No description provided for @profileSafetyBody.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تبلغ عن الحساب أو تحظره، وفريق شطب موجود لو احتجت مساعدة.'**
  String get profileSafetyBody;

  /// No description provided for @reportProfileAction.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ عن الحساب'**
  String get reportProfileAction;

  /// No description provided for @blockProfileAction.
  ///
  /// In ar, this message translates to:
  /// **'حظر الحساب'**
  String get blockProfileAction;

  /// No description provided for @homeFeaturedEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'هنرشح لك محترف مناسب قريب'**
  String get homeFeaturedEmptyTitle;

  /// No description provided for @homeFeaturedEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'لما تتوفر بيانات أكتر، هنظهر لك اختيار مبني على التقييمات والشغل المنشور.'**
  String get homeFeaturedEmptyMessage;

  /// No description provided for @homeProjectsLoadErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نعرض الشغل دلوقتي'**
  String get homeProjectsLoadErrorTitle;

  /// No description provided for @homeProjectsLoadErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني عشان تشوف أعمال حقيقية من محترفين شطب.'**
  String get homeProjectsLoadErrorMessage;

  /// No description provided for @homeProjectsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشغل الحقيقي هيظهر هنا'**
  String get homeProjectsEmptyTitle;

  /// No description provided for @homeProjectsEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'استكشف أعمال المحترفين وشوف تفاصيل التنفيذ قبل ما تختار.'**
  String get homeProjectsEmptyMessage;
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
