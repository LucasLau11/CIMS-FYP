import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

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
    Locale('en'),
    Locale('ms'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CIMS'**
  String get appTitle;

  /// No description provided for @tarumt.
  ///
  /// In en, this message translates to:
  /// **'TARUMT'**
  String get tarumt;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Centralised Internship\nManagement System'**
  String get splashTagline;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @welcomeToCims.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CIMS'**
  String get welcomeToCims;

  /// No description provided for @cimsFullName.
  ///
  /// In en, this message translates to:
  /// **'Centralised Internship Management System'**
  String get cimsFullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @noAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountSignUp;

  /// No description provided for @footerCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 TARUMT · CIMS v1.0'**
  String get footerCopyright;

  /// No description provided for @errorEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get errorEnterEmail;

  /// No description provided for @errorEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get errorEnterPassword;

  /// No description provided for @errorIncorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get errorIncorrectCredentials;

  /// No description provided for @errorConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in.'**
  String get errorConfirmEmail;

  /// No description provided for @errorSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSomethingWrong;

  /// No description provided for @resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetYourPassword;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we\'ll send you a link to reset your password.'**
  String get resetPasswordInstructions;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link has been sent.'**
  String get resetLinkSentMessage;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your CIMS account'**
  String get createYourAccount;

  /// No description provided for @signupRoleNote.
  ///
  /// In en, this message translates to:
  /// **'Student/staff emails are assigned a role automatically.\nGmail, Outlook, or Hotmail addresses will be asked to pick a role below.'**
  String get signupRoleNote;

  /// No description provided for @createAPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createAPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @reEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterYourPassword;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectYourRole;

  /// No description provided for @notInstitutionalEmailNote.
  ///
  /// In en, this message translates to:
  /// **'Your email is not a TARC institutional address. Please select the role that applies to you.'**
  String get notInstitutionalEmailNote;

  /// No description provided for @parentGuardian.
  ///
  /// In en, this message translates to:
  /// **'Parent/Guardian'**
  String get parentGuardian;

  /// No description provided for @hrPersonnel.
  ///
  /// In en, this message translates to:
  /// **'HR Personnel'**
  String get hrPersonnel;

  /// No description provided for @companySupervisor.
  ///
  /// In en, this message translates to:
  /// **'Company Supervisor'**
  String get companySupervisor;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccountLogIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccountLogIn;

  /// No description provided for @errorFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get errorFillAllFields;

  /// No description provided for @errorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get errorPasswordsDoNotMatch;

  /// No description provided for @errorSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select your role to continue.'**
  String get errorSelectRole;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @internshipProgress.
  ///
  /// In en, this message translates to:
  /// **'Internship progress'**
  String get internshipProgress;

  /// No description provided for @upcomingDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Upcoming deadlines'**
  String get upcomingDeadlines;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @recentFeedback.
  ///
  /// In en, this message translates to:
  /// **'Recent feedback'**
  String get recentFeedback;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get overallProgress;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @stepApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get stepApplied;

  /// No description provided for @stepAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get stepAccepted;

  /// No description provided for @stepOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get stepOngoing;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stepCompleted;

  /// No description provided for @submitCompanyReview.
  ///
  /// In en, this message translates to:
  /// **'Submit company review'**
  String get submitCompanyReview;

  /// No description provided for @viewMyProgress.
  ///
  /// In en, this message translates to:
  /// **'View my progress'**
  String get viewMyProgress;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}!'**
  String goodMorning(String name);

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @academicInformation.
  ///
  /// In en, this message translates to:
  /// **'Academic information'**
  String get academicInformation;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @programme.
  ///
  /// In en, this message translates to:
  /// **'Programme'**
  String get programme;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @faculty.
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get faculty;

  /// No description provided for @cgpa.
  ///
  /// In en, this message translates to:
  /// **'CGPA'**
  String get cgpa;

  /// No description provided for @academicSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Academic Supervisor'**
  String get academicSupervisor;

  /// No description provided for @assignedBySystem.
  ///
  /// In en, this message translates to:
  /// **'Assigned by system'**
  String get assignedBySystem;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select theme'**
  String get selectTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again to access your account.'**
  String get logOutConfirmMessage;

  /// No description provided for @noResumeUploaded.
  ///
  /// In en, this message translates to:
  /// **'No resume uploaded yet'**
  String get noResumeUploaded;

  /// No description provided for @resumeFormatNote.
  ///
  /// In en, this message translates to:
  /// **'PDF or DOCX only, max 5MB.'**
  String get resumeFormatNote;

  /// No description provided for @uploadResume.
  ///
  /// In en, this message translates to:
  /// **'Upload resume'**
  String get uploadResume;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @scanResumeToAutofill.
  ///
  /// In en, this message translates to:
  /// **'Scan resume to autofill profile'**
  String get scanResumeToAutofill;

  /// No description provided for @tapToSelectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Tap to select date of birth'**
  String get tapToSelectDateOfBirth;

  /// No description provided for @tapToSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap to select your address on the map'**
  String get tapToSelectAddress;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @hrRecruitmentOverview.
  ///
  /// In en, this message translates to:
  /// **'Recruitment overview'**
  String get hrRecruitmentOverview;

  /// No description provided for @hrActivePostings.
  ///
  /// In en, this message translates to:
  /// **'Active postings'**
  String get hrActivePostings;

  /// No description provided for @hrNewApplicants.
  ///
  /// In en, this message translates to:
  /// **'New applicants'**
  String get hrNewApplicants;

  /// No description provided for @hrInterviewsPending.
  ///
  /// In en, this message translates to:
  /// **'Interviews pending'**
  String get hrInterviewsPending;

  /// No description provided for @hrCurrentInterns.
  ///
  /// In en, this message translates to:
  /// **'Current interns'**
  String get hrCurrentInterns;

  /// No description provided for @hrUpcomingInterviews.
  ///
  /// In en, this message translates to:
  /// **'Upcoming interviews'**
  String get hrUpcomingInterviews;

  /// No description provided for @hrNoInterviewsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No interviews scheduled.'**
  String get hrNoInterviewsScheduled;

  /// No description provided for @hrNewPosting.
  ///
  /// In en, this message translates to:
  /// **'New posting'**
  String get hrNewPosting;

  /// No description provided for @hrReviewApplicants.
  ///
  /// In en, this message translates to:
  /// **'Review applicants'**
  String get hrReviewApplicants;

  /// No description provided for @hrPersonnelLabel.
  ///
  /// In en, this message translates to:
  /// **'HR Personnel'**
  String get hrPersonnelLabel;

  /// No description provided for @hrJobPostings.
  ///
  /// In en, this message translates to:
  /// **'Job postings'**
  String get hrJobPostings;

  /// No description provided for @hrPostingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} postings'**
  String hrPostingsCount(int count);

  /// No description provided for @hrActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String hrActiveCount(int count);

  /// No description provided for @hrNoPostingsYet.
  ///
  /// In en, this message translates to:
  /// **'No postings yet'**
  String get hrNoPostingsYet;

  /// No description provided for @hrCreateFirstPosting.
  ///
  /// In en, this message translates to:
  /// **'Create your first internship posting.'**
  String get hrCreateFirstPosting;

  /// No description provided for @hrClosePosting.
  ///
  /// In en, this message translates to:
  /// **'Close posting'**
  String get hrClosePosting;

  /// No description provided for @hrReopenPosting.
  ///
  /// In en, this message translates to:
  /// **'Reopen posting'**
  String get hrReopenPosting;

  /// No description provided for @hrDeletePostingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete posting?'**
  String get hrDeletePostingTitle;

  /// No description provided for @hrDeletePostingMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this job posting. Existing applications will be retained for records.'**
  String get hrDeletePostingMessage;

  /// No description provided for @hrApplicantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} applicants'**
  String hrApplicantsCount(int count);

  /// No description provided for @hrPostedAgo.
  ///
  /// In en, this message translates to:
  /// **'Posted {time}'**
  String hrPostedAgo(String time);

  /// No description provided for @hrEditPosting.
  ///
  /// In en, this message translates to:
  /// **'Edit posting'**
  String get hrEditPosting;

  /// No description provided for @hrPostingDetails.
  ///
  /// In en, this message translates to:
  /// **'Posting details'**
  String get hrPostingDetails;

  /// No description provided for @hrJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get hrJobTitle;

  /// No description provided for @hrJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software Engineering Intern'**
  String get hrJobTitleHint;

  /// No description provided for @hrJobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job description'**
  String get hrJobDescription;

  /// No description provided for @hrJobDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the role and responsibilities'**
  String get hrJobDescriptionHint;

  /// No description provided for @hrCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get hrCategory;

  /// No description provided for @hrLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get hrLogistics;

  /// No description provided for @hrLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Location — tap to select on map'**
  String get hrLocationHint;

  /// No description provided for @hrJobType.
  ///
  /// In en, this message translates to:
  /// **'Job type'**
  String get hrJobType;

  /// No description provided for @hrDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get hrDuration;

  /// No description provided for @hrMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String hrMonths(int count);

  /// No description provided for @hrMonthlyAllowance.
  ///
  /// In en, this message translates to:
  /// **'Monthly allowance (RM)'**
  String get hrMonthlyAllowance;

  /// No description provided for @hrMonthlyAllowanceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1500'**
  String get hrMonthlyAllowanceHint;

  /// No description provided for @hrDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String hrDeadlineLabel(String date);

  /// No description provided for @hrApplicationDeadlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Application deadline (optional)'**
  String get hrApplicationDeadlineOptional;

  /// No description provided for @hrSkillsRequired.
  ///
  /// In en, this message translates to:
  /// **'Skills required'**
  String get hrSkillsRequired;

  /// No description provided for @hrAddASkill.
  ///
  /// In en, this message translates to:
  /// **'Add a skill'**
  String get hrAddASkill;

  /// No description provided for @hrSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get hrSaveChanges;

  /// No description provided for @hrPublishPosting.
  ///
  /// In en, this message translates to:
  /// **'Publish posting'**
  String get hrPublishPosting;

  /// No description provided for @hrTitleLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Job title and location are required.'**
  String get hrTitleLocationRequired;

  /// No description provided for @hrDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a job description.'**
  String get hrDescriptionRequired;

  /// No description provided for @hrValidAllowanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid monthly allowance.'**
  String get hrValidAllowanceRequired;

  /// No description provided for @hrSkillRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one required skill.'**
  String get hrSkillRequired;

  /// No description provided for @hrApplicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get hrApplicants;

  /// No description provided for @hrTabNew.
  ///
  /// In en, this message translates to:
  /// **'New ({count})'**
  String hrTabNew(int count);

  /// No description provided for @hrTabInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview ({count})'**
  String hrTabInterview(int count);

  /// No description provided for @hrTabAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted ({count})'**
  String hrTabAccepted(int count);

  /// No description provided for @hrTabRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected ({count})'**
  String hrTabRejected(int count);

  /// No description provided for @hrNoApplicantsHere.
  ///
  /// In en, this message translates to:
  /// **'No applicants here'**
  String get hrNoApplicantsHere;

  /// No description provided for @hrApplicantsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Applicants in this stage will appear here.'**
  String get hrApplicantsAppearHere;

  /// No description provided for @hrInterviewColon.
  ///
  /// In en, this message translates to:
  /// **'Interview: {time}'**
  String hrInterviewColon(String time);

  /// No description provided for @hrAppliedAgo.
  ///
  /// In en, this message translates to:
  /// **'Applied {time}'**
  String hrAppliedAgo(String time);

  /// No description provided for @hrApplicantProfile.
  ///
  /// In en, this message translates to:
  /// **'Applicant profile'**
  String get hrApplicantProfile;

  /// No description provided for @hrAppliedFor.
  ///
  /// In en, this message translates to:
  /// **'Applied for'**
  String get hrAppliedFor;

  /// No description provided for @hrNoResumeUploaded.
  ///
  /// In en, this message translates to:
  /// **'No resume uploaded'**
  String get hrNoResumeUploaded;

  /// No description provided for @hrCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover letter'**
  String get hrCoverLetter;

  /// No description provided for @hrNoCoverLetterProvided.
  ///
  /// In en, this message translates to:
  /// **'No cover letter provided.'**
  String get hrNoCoverLetterProvided;

  /// No description provided for @hrSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get hrSkills;

  /// No description provided for @hrReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get hrReject;

  /// No description provided for @hrScheduleInterview.
  ///
  /// In en, this message translates to:
  /// **'Schedule Interview'**
  String get hrScheduleInterview;

  /// No description provided for @hrInterviewScheduledColon.
  ///
  /// In en, this message translates to:
  /// **'Interview scheduled: {time}'**
  String hrInterviewScheduledColon(String time);

  /// No description provided for @hrAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get hrAccept;

  /// No description provided for @hrDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get hrDate;

  /// No description provided for @hrSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get hrSelectDate;

  /// No description provided for @hrTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get hrTime;

  /// No description provided for @hrSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get hrSelectTime;

  /// No description provided for @hrInterviewMode.
  ///
  /// In en, this message translates to:
  /// **'Interview mode'**
  String get hrInterviewMode;

  /// No description provided for @hrOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get hrOnline;

  /// No description provided for @hrInPerson.
  ///
  /// In en, this message translates to:
  /// **'In-person'**
  String get hrInPerson;

  /// No description provided for @hrMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Meeting link'**
  String get hrMeetingLink;

  /// No description provided for @hrLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get hrLocation;

  /// No description provided for @hrMeetingLinkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Zoom/Google Meet link'**
  String get hrMeetingLinkHint;

  /// No description provided for @hrLocationTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select on map'**
  String get hrLocationTapToSelect;

  /// No description provided for @hrOfficeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Office address'**
  String get hrOfficeAddressHint;

  /// No description provided for @hrMeetingLinkRequired.
  ///
  /// In en, this message translates to:
  /// **'Meeting link is required.'**
  String get hrMeetingLinkRequired;

  /// No description provided for @hrLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required.'**
  String get hrLocationRequired;

  /// No description provided for @hrConfirmNotifyApplicant.
  ///
  /// In en, this message translates to:
  /// **'Confirm & notify applicant'**
  String get hrConfirmNotifyApplicant;

  /// No description provided for @hrPostings.
  ///
  /// In en, this message translates to:
  /// **'Postings'**
  String get hrPostings;

  /// No description provided for @hrInterns.
  ///
  /// In en, this message translates to:
  /// **'Interns'**
  String get hrInterns;

  /// No description provided for @hrClosedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get hrClosedStatus;

  /// No description provided for @supAssignedStudents.
  ///
  /// In en, this message translates to:
  /// **'Assigned students'**
  String get supAssignedStudents;

  /// No description provided for @supPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending reviews'**
  String get supPendingReviews;

  /// No description provided for @supApprovedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Approved this month'**
  String get supApprovedThisMonth;

  /// No description provided for @supUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get supUnreadMessages;

  /// No description provided for @supPendingYourReview.
  ///
  /// In en, this message translates to:
  /// **'Pending your review'**
  String get supPendingYourReview;

  /// No description provided for @supNothingPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending review right now.'**
  String get supNothingPendingReview;

  /// No description provided for @supMyStudents.
  ///
  /// In en, this message translates to:
  /// **'My students'**
  String get supMyStudents;

  /// No description provided for @supNoStudentsYet.
  ///
  /// In en, this message translates to:
  /// **'No students yet.'**
  String get supNoStudentsYet;

  /// No description provided for @supUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get supUpToDate;

  /// No description provided for @supPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String supPendingCount(int count);

  /// No description provided for @supMyStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My students'**
  String get supMyStudentsTitle;

  /// No description provided for @supSearchByNameOrProgramme.
  ///
  /// In en, this message translates to:
  /// **'Search by name or programme...'**
  String get supSearchByNameOrProgramme;

  /// No description provided for @supStudentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String supStudentsCount(int count);

  /// No description provided for @supNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students'**
  String get supNoStudents;

  /// No description provided for @supNoStudentsMatch.
  ///
  /// In en, this message translates to:
  /// **'No students match your search.'**
  String get supNoStudentsMatch;

  /// No description provided for @supActiveInternship.
  ///
  /// In en, this message translates to:
  /// **'Active internship'**
  String get supActiveInternship;

  /// No description provided for @supNoActiveInternship.
  ///
  /// In en, this message translates to:
  /// **'No active internship'**
  String get supNoActiveInternship;

  /// No description provided for @supLastReportAgo.
  ///
  /// In en, this message translates to:
  /// **'Last report {time}'**
  String supLastReportAgo(String time);

  /// No description provided for @supNoReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get supNoReportsYet;

  /// No description provided for @supStudentDetails.
  ///
  /// In en, this message translates to:
  /// **'Student details'**
  String get supStudentDetails;

  /// No description provided for @supEvaluate.
  ///
  /// In en, this message translates to:
  /// **'Evaluate'**
  String get supEvaluate;

  /// No description provided for @supMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supMessage;

  /// No description provided for @supLatestEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Latest evaluation'**
  String get supLatestEvaluation;

  /// No description provided for @supSubmittedAgo.
  ///
  /// In en, this message translates to:
  /// **'Submitted {time}'**
  String supSubmittedAgo(String time);

  /// No description provided for @supSubmissionHistory.
  ///
  /// In en, this message translates to:
  /// **'Submission history'**
  String get supSubmissionHistory;

  /// No description provided for @supNoSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet.'**
  String get supNoSubmissionsYet;

  /// No description provided for @supReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get supReviews;

  /// No description provided for @supTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get supTabPending;

  /// No description provided for @supTabApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get supTabApproved;

  /// No description provided for @supTabRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get supTabRejected;

  /// No description provided for @supNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get supNothingHere;

  /// No description provided for @supItemsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Items in this category will appear here.'**
  String get supItemsAppearHere;

  /// No description provided for @supNoFileAttached.
  ///
  /// In en, this message translates to:
  /// **'No file attached to this submission.'**
  String get supNoFileAttached;

  /// No description provided for @supAwaitingCompanyReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting company supervisor review before you can approve.'**
  String get supAwaitingCompanyReview;

  /// No description provided for @supRejectedByCompany.
  ///
  /// In en, this message translates to:
  /// **'Rejected by the company supervisor — waiting on the student to resubmit.'**
  String get supRejectedByCompany;

  /// No description provided for @supRejectSubmission.
  ///
  /// In en, this message translates to:
  /// **'Reject submission'**
  String get supRejectSubmission;

  /// No description provided for @supApproveSubmission.
  ///
  /// In en, this message translates to:
  /// **'Approve submission'**
  String get supApproveSubmission;

  /// No description provided for @supRejectFeedbackPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please provide feedback explaining why this is being rejected.'**
  String get supRejectFeedbackPrompt;

  /// No description provided for @supApproveCommentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add an optional comment for the student.'**
  String get supApproveCommentPrompt;

  /// No description provided for @supTypeYourComment.
  ///
  /// In en, this message translates to:
  /// **'Type your comment...'**
  String get supTypeYourComment;

  /// No description provided for @supPleaseAddFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please add feedback before rejecting.'**
  String get supPleaseAddFeedback;

  /// No description provided for @supApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get supApprove;

  /// No description provided for @supEvaluateStudent.
  ///
  /// In en, this message translates to:
  /// **'Evaluate student'**
  String get supEvaluateStudent;

  /// No description provided for @supRatingInstruction.
  ///
  /// In en, this message translates to:
  /// **'Rate each criterion from 1 (poor) to 5 (excellent) based on internship performance.'**
  String get supRatingInstruction;

  /// No description provided for @supOverallAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Overall average score'**
  String get supOverallAverageScore;

  /// No description provided for @supAdditionalComments.
  ///
  /// In en, this message translates to:
  /// **'Additional comments'**
  String get supAdditionalComments;

  /// No description provided for @supQualitativeFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Provide qualitative feedback on the student\'s overall performance...'**
  String get supQualitativeFeedbackHint;

  /// No description provided for @supSubmitEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Submit evaluation'**
  String get supSubmitEvaluation;

  /// No description provided for @supEvaluationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Evaluation submitted'**
  String get supEvaluationSubmitted;

  /// No description provided for @supEvaluationRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your evaluation for {name} has been recorded.'**
  String supEvaluationRecorded(String name);

  /// No description provided for @supBackToStudent.
  ///
  /// In en, this message translates to:
  /// **'Back to student'**
  String get supBackToStudent;

  /// No description provided for @supStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get supStudents;

  /// No description provided for @csCurrentInterns.
  ///
  /// In en, this message translates to:
  /// **'Current interns'**
  String get csCurrentInterns;

  /// No description provided for @csReportsToReview.
  ///
  /// In en, this message translates to:
  /// **'Reports to review'**
  String get csReportsToReview;

  /// No description provided for @csApprovedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Approved this month'**
  String get csApprovedThisMonth;

  /// No description provided for @csEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Evaluations'**
  String get csEvaluations;

  /// No description provided for @csPendingYourReview.
  ///
  /// In en, this message translates to:
  /// **'Pending your review'**
  String get csPendingYourReview;

  /// No description provided for @csNothingPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending review.'**
  String get csNothingPendingReview;

  /// No description provided for @csInternProgress.
  ///
  /// In en, this message translates to:
  /// **'Intern progress'**
  String get csInternProgress;

  /// No description provided for @csNoInternsYet.
  ///
  /// In en, this message translates to:
  /// **'No interns yet.'**
  String get csNoInternsYet;

  /// No description provided for @csInterns.
  ///
  /// In en, this message translates to:
  /// **'Interns'**
  String get csInterns;

  /// No description provided for @csCurrentInternsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} current interns'**
  String csCurrentInternsCount(int count);

  /// No description provided for @csNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} needs attention'**
  String csNeedsAttention(int count);

  /// No description provided for @csNoInternsTitle.
  ///
  /// In en, this message translates to:
  /// **'No interns yet'**
  String get csNoInternsTitle;

  /// No description provided for @csNoInternsDescription.
  ///
  /// In en, this message translates to:
  /// **'Accepted applicants at your company will appear here.'**
  String get csNoInternsDescription;

  /// No description provided for @csInternDetails.
  ///
  /// In en, this message translates to:
  /// **'Intern details'**
  String get csInternDetails;

  /// No description provided for @csReportSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Report submissions'**
  String get csReportSubmissions;

  /// No description provided for @csNoReportsSubmittedYet.
  ///
  /// In en, this message translates to:
  /// **'No reports submitted yet.'**
  String get csNoReportsSubmittedYet;

  /// No description provided for @csEvaluateIntern.
  ///
  /// In en, this message translates to:
  /// **'Evaluate intern'**
  String get csEvaluateIntern;

  /// No description provided for @csRatingInstruction.
  ///
  /// In en, this message translates to:
  /// **'Rate each criterion from 1 (poor) to 5 (excellent) based on workplace performance.'**
  String get csRatingInstruction;

  /// No description provided for @csAdditionalComments.
  ///
  /// In en, this message translates to:
  /// **'Additional comments'**
  String get csAdditionalComments;

  /// No description provided for @csPerformanceCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the intern\'s overall performance, attitude, and growth during the internship period...'**
  String get csPerformanceCommentHint;

  /// No description provided for @csSubmitEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Submit evaluation'**
  String get csSubmitEvaluation;

  /// No description provided for @csEvaluationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Evaluation submitted'**
  String get csEvaluationSubmitted;

  /// No description provided for @csEvaluationRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your workplace evaluation for {name} has been recorded and shared with the university.'**
  String csEvaluationRecorded(String name);

  /// No description provided for @csBackToIntern.
  ///
  /// In en, this message translates to:
  /// **'Back to intern'**
  String get csBackToIntern;

  /// No description provided for @csReportReviews.
  ///
  /// In en, this message translates to:
  /// **'Report reviews'**
  String get csReportReviews;

  /// No description provided for @csTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get csTabPending;

  /// No description provided for @csTabApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get csTabApproved;

  /// No description provided for @csTabRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get csTabRejected;

  /// No description provided for @csNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get csNothingHere;

  /// No description provided for @csReportsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Reports in this category will appear here.'**
  String get csReportsAppearHere;

  /// No description provided for @csRejectReport.
  ///
  /// In en, this message translates to:
  /// **'Reject report'**
  String get csRejectReport;

  /// No description provided for @csApproveReport.
  ///
  /// In en, this message translates to:
  /// **'Approve report'**
  String get csApproveReport;

  /// No description provided for @csRejectReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Provide feedback explaining the rejection reason.'**
  String get csRejectReasonPrompt;

  /// No description provided for @csApproveCommentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add an optional comment for the intern.'**
  String get csApproveCommentPrompt;

  /// No description provided for @csPleaseAddFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please add feedback before rejecting.'**
  String get csPleaseAddFeedback;

  /// No description provided for @csGradeExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get csGradeExcellent;

  /// No description provided for @csGradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get csGradeGood;

  /// No description provided for @csGradeSatisfactory.
  ///
  /// In en, this message translates to:
  /// **'Satisfactory'**
  String get csGradeSatisfactory;

  /// No description provided for @csGradeNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement'**
  String get csGradeNeedsImprovement;

  /// No description provided for @csAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get csAverageScore;

  /// No description provided for @setupYourCompany.
  ///
  /// In en, this message translates to:
  /// **'Set up your company'**
  String get setupYourCompany;

  /// No description provided for @setupLinkCompanyNote.
  ///
  /// In en, this message translates to:
  /// **'Link your account to a company before you can manage postings, applicants, or interns.'**
  String get setupLinkCompanyNote;

  /// No description provided for @setupJoinExisting.
  ///
  /// In en, this message translates to:
  /// **'Join existing'**
  String get setupJoinExisting;

  /// No description provided for @setupRegisterNew.
  ///
  /// In en, this message translates to:
  /// **'Register new'**
  String get setupRegisterNew;

  /// No description provided for @setupNoCompaniesYet.
  ///
  /// In en, this message translates to:
  /// **'No companies yet'**
  String get setupNoCompaniesYet;

  /// No description provided for @setupSwitchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Switch to \"Register new\" to add your company.'**
  String get setupSwitchToRegister;

  /// No description provided for @setupIndustryNotSet.
  ///
  /// In en, this message translates to:
  /// **'Industry not set'**
  String get setupIndustryNotSet;

  /// No description provided for @setupJoinCompany.
  ///
  /// In en, this message translates to:
  /// **'Join company'**
  String get setupJoinCompany;

  /// No description provided for @setupCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get setupCompanyName;

  /// No description provided for @setupIndustryOptional.
  ///
  /// In en, this message translates to:
  /// **'Industry (optional)'**
  String get setupIndustryOptional;

  /// No description provided for @setupLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Location (optional) — tap to select on map'**
  String get setupLocationOptional;

  /// No description provided for @setupRegisterCompany.
  ///
  /// In en, this message translates to:
  /// **'Register company'**
  String get setupRegisterCompany;

  /// No description provided for @setupCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required.'**
  String get setupCompanyNameRequired;

  /// No description provided for @profileMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileMyProfile;

  /// No description provided for @profilePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profilePersonalInformation;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileAddress;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 012-345 6789'**
  String get profilePhoneHint;

  /// No description provided for @profileTapToSelectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to select on map'**
  String get profileTapToSelectOnMap;

  /// No description provided for @profileEmailCannotChange.
  ///
  /// In en, this message translates to:
  /// **'Email is your login and cannot be changed here.'**
  String get profileEmailCannotChange;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileNotificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get profileNotificationPreferencesTitle;

  /// No description provided for @profileChooseWhatToBeNotified.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to be notified about.'**
  String get profileChooseWhatToBeNotified;

  /// No description provided for @profileApplicationApplicantUpdates.
  ///
  /// In en, this message translates to:
  /// **'Application & applicant updates'**
  String get profileApplicationApplicantUpdates;

  /// No description provided for @profileReportDocumentReviews.
  ///
  /// In en, this message translates to:
  /// **'Report & document reviews'**
  String get profileReportDocumentReviews;

  /// No description provided for @profileMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get profileMessages;

  /// No description provided for @profileEvaluationReminders.
  ///
  /// In en, this message translates to:
  /// **'Evaluation reminders'**
  String get profileEvaluationReminders;

  /// No description provided for @profileNotificationPrefsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences updated.'**
  String get profileNotificationPrefsUpdated;

  /// No description provided for @profileSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get profileSelectLanguage;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profileUpdatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update profile photo'**
  String get profileUpdatePhoto;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profileTakePhoto;

  /// No description provided for @profileChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileChooseFromGallery;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profilePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get profilePasswordChanged;
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
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
