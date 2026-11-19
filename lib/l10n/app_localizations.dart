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

  /// No description provided for @signUpCheckEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to confirm your account before logging in.'**
  String get signUpCheckEmailMessage;

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

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

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

  /// No description provided for @studentRegNo.
  ///
  /// In en, this message translates to:
  /// **'Student Reg. No.'**
  String get studentRegNo;

  /// No description provided for @studentRegNoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 24WMR12345'**
  String get studentRegNoHint;

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

  /// No description provided for @supEvaluateLockedNote.
  ///
  /// In en, this message translates to:
  /// **'Evaluation unlocks once this student\'s internship period has ended.'**
  String get supEvaluateLockedNote;

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

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 week ago} other{{count} weeks ago}}'**
  String weeksAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 month ago} other{{count} months ago}}'**
  String monthsAgo(int count);

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 year ago} other{{count} years ago}}'**
  String yearsAgo(int count);

  /// No description provided for @chatConversationFallbackName.
  ///
  /// In en, this message translates to:
  /// **'this conversation'**
  String get chatConversationFallbackName;

  /// No description provided for @chatDeleteConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get chatDeleteConversationTitle;

  /// No description provided for @chatDeleteConversationMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes the whole conversation with {name} for both of you. This cannot be undone.'**
  String chatDeleteConversationMessage(String name);

  /// No description provided for @chatCouldNotLoadContacts.
  ///
  /// In en, this message translates to:
  /// **'Could not load contacts: {error}'**
  String chatCouldNotLoadContacts(String error);

  /// No description provided for @chatNewMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get chatNewMessageTitle;

  /// No description provided for @chatNoContactsToMessage.
  ///
  /// In en, this message translates to:
  /// **'No other accounts to message yet.'**
  String get chatNoContactsToMessage;

  /// No description provided for @chatTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTabTitle;

  /// No description provided for @chatArchivedChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived chats'**
  String get chatArchivedChatsTitle;

  /// No description provided for @chatNoConversationsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoConversationsYetTitle;

  /// No description provided for @chatTapPencilToMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the pencil icon to message someone.'**
  String get chatTapPencilToMessage;

  /// No description provided for @chatNoArchivedChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived chats'**
  String get chatNoArchivedChatsTitle;

  /// No description provided for @chatArchivedConversationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Conversations you archive show up here.'**
  String get chatArchivedConversationsDescription;

  /// No description provided for @chatUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get chatUnknownUser;

  /// No description provided for @chatUnarchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get chatUnarchiveAction;

  /// No description provided for @chatRoleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get chatRoleStudent;

  /// No description provided for @chatPhotoAttachmentPreview.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get chatPhotoAttachmentPreview;

  /// No description provided for @chatArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get chatArchiveAction;

  /// No description provided for @chatCouldNotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not send message: {error}'**
  String chatCouldNotSendMessage(String error);

  /// No description provided for @chatFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large. Maximum size is 10MB.'**
  String get chatFileTooLarge;

  /// No description provided for @chatCouldNotSendAttachment.
  ///
  /// In en, this message translates to:
  /// **'Could not send attachment: {error}'**
  String chatCouldNotSendAttachment(String error);

  /// No description provided for @chatDeleteForMeAction.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteForMeAction;

  /// No description provided for @chatDeleteForEveryoneAction.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForEveryoneAction;

  /// No description provided for @chatDeleteForMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete for me?'**
  String get chatDeleteForMeTitle;

  /// No description provided for @chatDeleteForMeMessage.
  ///
  /// In en, this message translates to:
  /// **'This message will be removed from your view only. The other person will still see it.'**
  String get chatDeleteForMeMessage;

  /// No description provided for @chatCouldNotDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not delete message: {error}'**
  String chatCouldNotDeleteMessage(String error);

  /// No description provided for @chatEditMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatEditMessageTitle;

  /// No description provided for @chatCouldNotEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not edit message: {error}'**
  String chatCouldNotEditMessage(String error);

  /// No description provided for @chatDeleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get chatDeleteMessageTitle;

  /// No description provided for @chatCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get chatCannotBeUndone;

  /// No description provided for @chatSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello 👋'**
  String get chatSayHello;

  /// No description provided for @chatTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessageHint;

  /// No description provided for @chatEditedLabel.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get chatEditedLabel;

  /// No description provided for @chatAttachmentFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get chatAttachmentFallbackName;

  /// No description provided for @chatCouldNotUpdateMute.
  ///
  /// In en, this message translates to:
  /// **'Could not update mute: {error}'**
  String chatCouldNotUpdateMute(String error);

  /// No description provided for @chatBlockContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this contact?'**
  String get chatBlockContactTitle;

  /// No description provided for @chatUnblockContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock this contact?'**
  String get chatUnblockContactTitle;

  /// No description provided for @chatBlockContactMessage.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to send you messages in this conversation.'**
  String get chatBlockContactMessage;

  /// No description provided for @chatUnblockContactMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be able to send you messages again.'**
  String get chatUnblockContactMessage;

  /// No description provided for @chatBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlockAction;

  /// No description provided for @chatUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get chatUnblockAction;

  /// No description provided for @chatCouldNotUpdateBlock.
  ///
  /// In en, this message translates to:
  /// **'Could not update block: {error}'**
  String chatCouldNotUpdateBlock(String error);

  /// No description provided for @chatCouldNotDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Could not delete conversation: {error}'**
  String chatCouldNotDeleteConversation(String error);

  /// No description provided for @chatContactInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact info'**
  String get chatContactInfoTitle;

  /// No description provided for @chatPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get chatPhoneNotAvailable;

  /// No description provided for @chatSharedMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'Shared media & files'**
  String get chatSharedMediaFiles;

  /// No description provided for @chatNoSharedMediaYet.
  ///
  /// In en, this message translates to:
  /// **'No shared media yet.'**
  String get chatNoSharedMediaYet;

  /// No description provided for @chatMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatMuteNotifications;

  /// No description provided for @chatBlockContactToggle.
  ///
  /// In en, this message translates to:
  /// **'Block contact'**
  String get chatBlockContactToggle;

  /// No description provided for @chatDeleteConversationButton.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get chatDeleteConversationButton;

  /// No description provided for @errorAddressSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Address search failed: {error}'**
  String errorAddressSearchFailed(String error);

  /// No description provided for @unknownLocationCoords.
  ///
  /// In en, this message translates to:
  /// **'Unknown location ({lat}, {lng})'**
  String unknownLocationCoords(String lat, String lng);

  /// No description provided for @errorCouldNotResolveAddress.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve address for this location.'**
  String get errorCouldNotResolveAddress;

  /// No description provided for @selectYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Select your address'**
  String get selectYourAddress;

  /// No description provided for @searchForYourAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Search for your address...'**
  String get searchForYourAddressHint;

  /// No description provided for @mapSearchOrTapHint.
  ///
  /// In en, this message translates to:
  /// **'Search above, or tap the map to fine-tune the pin'**
  String get mapSearchOrTapHint;

  /// No description provided for @resolvingAddress.
  ///
  /// In en, this message translates to:
  /// **'Resolving address...'**
  String get resolvingAddress;

  /// No description provided for @confirmThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Confirm this address'**
  String get confirmThisAddress;

  /// No description provided for @coverLetterLoadedFromFile.
  ///
  /// In en, this message translates to:
  /// **'Cover letter loaded from file — review and edit before continuing.'**
  String get coverLetterLoadedFromFile;

  /// No description provided for @errorCouldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read file: {error}'**
  String errorCouldNotReadFile(String error);

  /// No description provided for @notifApplicationSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get notifApplicationSubmittedTitle;

  /// No description provided for @notifApplicationSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your application to {company} has been sent.'**
  String notifApplicationSubmittedBody(String company);

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitApplication;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @errorCouldNotOpenResume.
  ///
  /// In en, this message translates to:
  /// **'Could not open resume.'**
  String get errorCouldNotOpenResume;

  /// No description provided for @resumeCvHeading.
  ///
  /// In en, this message translates to:
  /// **'Resume / CV'**
  String get resumeCvHeading;

  /// No description provided for @resumeSubmittedWithApplicationNote.
  ///
  /// In en, this message translates to:
  /// **'This is the resume that will be submitted with your application.'**
  String get resumeSubmittedWithApplicationNote;

  /// No description provided for @noResumeOnFile.
  ///
  /// In en, this message translates to:
  /// **'No resume on file'**
  String get noResumeOnFile;

  /// No description provided for @uploadResumeBeforeApplyingNote.
  ///
  /// In en, this message translates to:
  /// **'Upload a resume to your profile before applying.'**
  String get uploadResumeBeforeApplyingNote;

  /// No description provided for @goToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to profile'**
  String get goToProfile;

  /// No description provided for @coverLetterIntroNote.
  ///
  /// In en, this message translates to:
  /// **'Tell the company why you are a great fit — type it yourself or upload a file.'**
  String get coverLetterIntroNote;

  /// No description provided for @readingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading file...'**
  String get readingFile;

  /// No description provided for @uploadCoverLetterButton.
  ///
  /// In en, this message translates to:
  /// **'Upload cover letter (PDF/DOCX)'**
  String get uploadCoverLetterButton;

  /// No description provided for @coverLetterHint.
  ///
  /// In en, this message translates to:
  /// **'Dear Hiring Manager,\n\nI am writing to express my interest in...'**
  String get coverLetterHint;

  /// No description provided for @coverLetterTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Mention relevant skills and experiences.'**
  String get coverLetterTip;

  /// No description provided for @relevantSkillsHeading.
  ///
  /// In en, this message translates to:
  /// **'Relevant skills'**
  String get relevantSkillsHeading;

  /// No description provided for @selectMatchingSkillsNote.
  ///
  /// In en, this message translates to:
  /// **'Select skills that match this internship.'**
  String get selectMatchingSkillsNote;

  /// No description provided for @reviewYourApplication.
  ///
  /// In en, this message translates to:
  /// **'Review your application'**
  String get reviewYourApplication;

  /// No description provided for @pleaseReviewBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Please review before submitting.'**
  String get pleaseReviewBeforeSubmitting;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @noResume.
  ///
  /// In en, this message translates to:
  /// **'No resume'**
  String get noResume;

  /// No description provided for @noCoverLetterProvided.
  ///
  /// In en, this message translates to:
  /// **'No cover letter provided'**
  String get noCoverLetterProvided;

  /// No description provided for @applicationCannotBeEditedNote.
  ///
  /// In en, this message translates to:
  /// **'Once submitted, your application cannot be edited.'**
  String get applicationCannotBeEditedNote;

  /// No description provided for @applicationSubmittedExclaim.
  ///
  /// In en, this message translates to:
  /// **'Application submitted!'**
  String get applicationSubmittedExclaim;

  /// No description provided for @applicationSubmittedDetail.
  ///
  /// In en, this message translates to:
  /// **'Your application to {company} has been sent. You will be notified when there is an update.'**
  String applicationSubmittedDetail(String company);

  /// No description provided for @backToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get backToSearch;

  /// No description provided for @withdrawApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw application?'**
  String get withdrawApplicationTitle;

  /// No description provided for @withdrawApplicationMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be able to re-apply to {title} later if you change your mind.'**
  String withdrawApplicationMessage(String title);

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @errorCouldNotWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Could not withdraw: {error}'**
  String errorCouldNotWithdraw(String error);

  /// No description provided for @coverLetterLabel.
  ///
  /// In en, this message translates to:
  /// **'COVER LETTER'**
  String get coverLetterLabel;

  /// No description provided for @skillsLabel.
  ///
  /// In en, this message translates to:
  /// **'SKILLS'**
  String get skillsLabel;

  /// No description provided for @myApplications.
  ///
  /// In en, this message translates to:
  /// **'My applications'**
  String get myApplications;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @interview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get interview;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @noApplicationsHere.
  ///
  /// In en, this message translates to:
  /// **'No applications here'**
  String get noApplicationsHere;

  /// No description provided for @applicationsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Applications in this category will appear here.'**
  String get applicationsAppearHere;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @noInterviewScheduled.
  ///
  /// In en, this message translates to:
  /// **'No interview scheduled'**
  String get noInterviewScheduled;

  /// No description provided for @interviewNotifiedOnceScheduled.
  ///
  /// In en, this message translates to:
  /// **'You will be notified once the company schedules your interview.'**
  String get interviewNotifiedOnceScheduled;

  /// No description provided for @onlineInterviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Online interview'**
  String get onlineInterviewLabel;

  /// No description provided for @inPersonInterviewLabel.
  ///
  /// In en, this message translates to:
  /// **'In-person interview'**
  String get inPersonInterviewLabel;

  /// No description provided for @joinInterview.
  ///
  /// In en, this message translates to:
  /// **'Join interview'**
  String get joinInterview;

  /// No description provided for @directionsUnavailableNote.
  ///
  /// In en, this message translates to:
  /// **'Directions unavailable — see address above'**
  String get directionsUnavailableNote;

  /// No description provided for @inPersonNoJoinLinkNote.
  ///
  /// In en, this message translates to:
  /// **'This is an in-person interview — no online join link is needed.'**
  String get inPersonNoJoinLinkNote;

  /// No description provided for @errorCouldNotOpenMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the meeting link.'**
  String get errorCouldNotOpenMeetingLink;

  /// No description provided for @internshipDetails.
  ///
  /// In en, this message translates to:
  /// **'Internship details'**
  String get internshipDetails;

  /// No description provided for @monthlyAllowance.
  ///
  /// In en, this message translates to:
  /// **'Monthly allowance'**
  String get monthlyAllowance;

  /// No description provided for @applicationDeadline.
  ///
  /// In en, this message translates to:
  /// **'Application deadline'**
  String get applicationDeadline;

  /// No description provided for @openUntilFilled.
  ///
  /// In en, this message translates to:
  /// **'Open until filled'**
  String get openUntilFilled;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @aboutTheCompany.
  ///
  /// In en, this message translates to:
  /// **'About the company'**
  String get aboutTheCompany;

  /// No description provided for @industry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industry;

  /// No description provided for @hrContact.
  ///
  /// In en, this message translates to:
  /// **'HR contact'**
  String get hrContact;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get contactEmail;

  /// No description provided for @applyOnceVerifiedNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to apply once this company is verified.'**
  String get applyOnceVerifiedNote;

  /// No description provided for @alreadyApplied.
  ///
  /// In en, this message translates to:
  /// **'Already applied'**
  String get alreadyApplied;

  /// No description provided for @companyPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Company pending verification'**
  String get companyPendingVerification;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get applyNow;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Updates about your applications, reports, and messages will show up here.'**
  String get notificationsEmptyDescription;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @notificationApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get notificationApprove;

  /// No description provided for @notificationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get notificationReject;

  /// No description provided for @errorCouldNotRespondToRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not respond to this request: {error}'**
  String errorCouldNotRespondToRequest(String error);

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @docTypeOfferLetter.
  ///
  /// In en, this message translates to:
  /// **'Offer Letter'**
  String get docTypeOfferLetter;

  /// No description provided for @docTypeIndemnityLetter.
  ///
  /// In en, this message translates to:
  /// **'Indemnity Letter'**
  String get docTypeIndemnityLetter;

  /// No description provided for @docTypeCompanyAcceptanceLetter.
  ///
  /// In en, this message translates to:
  /// **'Company Acceptance Letter'**
  String get docTypeCompanyAcceptanceLetter;

  /// No description provided for @submissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get submissions;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @tapSubmitFirstReportNote.
  ///
  /// In en, this message translates to:
  /// **'Tap Submit to upload your first monthly or final report.'**
  String get tapSubmitFirstReportNote;

  /// No description provided for @reportsRequireActiveInternshipNote.
  ///
  /// In en, this message translates to:
  /// **'You can submit monthly and final reports once you\'ve been accepted into an internship.'**
  String get reportsRequireActiveInternshipNote;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @finalReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Final Report'**
  String get finalReportLabel;

  /// No description provided for @monthlyReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReportLabel;

  /// No description provided for @approvedByCompanyAwaitingUniversity.
  ///
  /// In en, this message translates to:
  /// **'Approved by company supervisor · awaiting university review'**
  String get approvedByCompanyAwaitingUniversity;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required documents'**
  String get requiredDocuments;

  /// No description provided for @otherDocuments.
  ///
  /// In en, this message translates to:
  /// **'Other documents'**
  String get otherDocuments;

  /// No description provided for @addOtherDocument.
  ///
  /// In en, this message translates to:
  /// **'Add other document'**
  String get addOtherDocument;

  /// No description provided for @documentTitleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Document title'**
  String get documentTitleDialogTitle;

  /// No description provided for @documentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Transcript'**
  String get documentTitleHint;

  /// No description provided for @notUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded yet'**
  String get notUploadedYet;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @errorFileTooLarge10mb.
  ///
  /// In en, this message translates to:
  /// **'File is too large. Maximum size is 10MB.'**
  String get errorFileTooLarge10mb;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String errorUploadFailed(String error);

  /// No description provided for @errorEnterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Please enter a period, e.g. \"June 2026\".'**
  String get errorEnterPeriod;

  /// No description provided for @errorCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit: {error}'**
  String errorCouldNotSubmit(String error);

  /// No description provided for @newSubmission.
  ///
  /// In en, this message translates to:
  /// **'New submission'**
  String get newSubmission;

  /// No description provided for @submissionType.
  ///
  /// In en, this message translates to:
  /// **'Submission type'**
  String get submissionType;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @periodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. June 2026'**
  String get periodHint;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @notesForSupervisorHint.
  ///
  /// In en, this message translates to:
  /// **'Add any notes for your supervisor...'**
  String get notesForSupervisorHint;

  /// No description provided for @tapToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select file'**
  String get tapToSelectFile;

  /// No description provided for @pdfDocxUpTo10mb.
  ///
  /// In en, this message translates to:
  /// **'PDF, DOCX up to 10MB'**
  String get pdfDocxUpTo10mb;

  /// No description provided for @errorLoadInternships.
  ///
  /// In en, this message translates to:
  /// **'Could not load internships: {error}'**
  String errorLoadInternships(String error);

  /// No description provided for @searchInternships.
  ///
  /// In en, this message translates to:
  /// **'Search internships'**
  String get searchInternships;

  /// No description provided for @titleSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get titleSomethingWentWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @searchByRoleCompanySkillHint.
  ///
  /// In en, this message translates to:
  /// **'Search by role, company, or skill...'**
  String get searchByRoleCompanySkillHint;

  /// No description provided for @opportunitiesFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 opportunity found} other{{count} opportunities found}}'**
  String opportunitiesFoundCount(int count);

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @tryAdjustingSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get tryAdjustingSearchFilters;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending verification'**
  String get pendingVerification;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @allowanceRange.
  ///
  /// In en, this message translates to:
  /// **'Allowance range'**
  String get allowanceRange;

  /// No description provided for @minAllowanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Min allowance (RM)'**
  String get minAllowanceLabel;

  /// No description provided for @maxAllowanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Max allowance (RM)'**
  String get maxAllowanceLabel;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// No description provided for @programmeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Programme not set'**
  String get programmeNotSet;

  /// No description provided for @applicationsSent.
  ///
  /// In en, this message translates to:
  /// **'Applications sent'**
  String get applicationsSent;

  /// No description provided for @interviewsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interviews scheduled'**
  String get interviewsScheduled;

  /// No description provided for @reportsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Reports submitted'**
  String get reportsSubmitted;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @dashboardEmptyActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet — apply to an internship or submit a report to get started.'**
  String get dashboardEmptyActivityMessage;

  /// No description provided for @errorUnsupportedImageFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format. Please upload a JPG, JPEG, or PNG image.'**
  String get errorUnsupportedImageFormat;

  /// No description provided for @errorPhotoEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected photo is empty (0 bytes). Try a different photo.'**
  String get errorPhotoEmpty;

  /// No description provided for @errorPhotoNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected photo could not be found on disk.'**
  String get errorPhotoNotFound;

  /// No description provided for @errorCouldNotAccessSource.
  ///
  /// In en, this message translates to:
  /// **'Could not access {source}: {error}'**
  String errorCouldNotAccessSource(String source, String error);

  /// No description provided for @errorCouldNotRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo: {error}'**
  String errorCouldNotRemovePhoto(String error);

  /// No description provided for @selectDateOfBirthHelpText.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get selectDateOfBirthHelpText;

  /// No description provided for @errorFullNameBlank.
  ///
  /// In en, this message translates to:
  /// **'Full name cannot be blank.'**
  String get errorFullNameBlank;

  /// No description provided for @errorPhoneBlank.
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be blank.'**
  String get errorPhoneBlank;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get errorInvalidPhone;

  /// No description provided for @errorSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth.'**
  String get errorSelectDob;

  /// No description provided for @errorDobInFuture.
  ///
  /// In en, this message translates to:
  /// **'Date of birth cannot be in the future.'**
  String get errorDobInFuture;

  /// No description provided for @errorMinAge17.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 17 years old.'**
  String get errorMinAge17;

  /// No description provided for @errorSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select your address on the map.'**
  String get errorSelectAddress;

  /// No description provided for @personalInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Personal information updated.'**
  String get personalInfoUpdated;

  /// No description provided for @errorCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String errorCouldNotSave(String error);

  /// No description provided for @errorSelectProgramme.
  ///
  /// In en, this message translates to:
  /// **'Please select your programme.'**
  String get errorSelectProgramme;

  /// No description provided for @errorSelectFaculty.
  ///
  /// In en, this message translates to:
  /// **'Please select your faculty.'**
  String get errorSelectFaculty;

  /// No description provided for @errorSelectSemester.
  ///
  /// In en, this message translates to:
  /// **'Please select your semester.'**
  String get errorSelectSemester;

  /// No description provided for @errorCgpaBlank.
  ///
  /// In en, this message translates to:
  /// **'CGPA cannot be blank.'**
  String get errorCgpaBlank;

  /// No description provided for @errorInvalidCgpaRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid CGPA between 0.00 and 4.00.'**
  String get errorInvalidCgpaRange;

  /// No description provided for @academicInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Academic information updated.'**
  String get academicInfoUpdated;

  /// No description provided for @skillsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Skills updated.'**
  String get skillsUpdated;

  /// No description provided for @addWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Add work experience'**
  String get addWorkExperience;

  /// No description provided for @editWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Edit work experience'**
  String get editWorkExperience;

  /// No description provided for @positionJobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Position / Job title'**
  String get positionJobTitleLabel;

  /// No description provided for @startYearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2023'**
  String get startYearHint;

  /// No description provided for @startYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Start year'**
  String get startYearLabel;

  /// No description provided for @endYearLabel.
  ///
  /// In en, this message translates to:
  /// **'End year'**
  String get endYearLabel;

  /// No description provided for @iCurrentlyWorkHere.
  ///
  /// In en, this message translates to:
  /// **'I currently work here'**
  String get iCurrentlyWorkHere;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @errorPositionCompanyRequired.
  ///
  /// In en, this message translates to:
  /// **'Position and company are required.'**
  String get errorPositionCompanyRequired;

  /// No description provided for @removeThisEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this entry?'**
  String get removeThisEntryTitle;

  /// No description provided for @errorCouldNotRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove: {error}'**
  String errorCouldNotRemove(String error);

  /// No description provided for @unknownCompany.
  ///
  /// In en, this message translates to:
  /// **'Unknown company'**
  String get unknownCompany;

  /// No description provided for @unknownPosition.
  ///
  /// In en, this message translates to:
  /// **'Unknown position'**
  String get unknownPosition;

  /// No description provided for @errorEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get errorEnterCurrentPassword;

  /// No description provided for @errorNewPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get errorNewPasswordsMismatch;

  /// No description provided for @errorInvalidResumeFormat.
  ///
  /// In en, this message translates to:
  /// **'The file is not in an acceptable format. Only PDF or DOCX files are allowed.'**
  String get errorInvalidResumeFormat;

  /// No description provided for @errorFileTooLarge5mb.
  ///
  /// In en, this message translates to:
  /// **'File is too large. Maximum size is 5MB.'**
  String get errorFileTooLarge5mb;

  /// No description provided for @resumeUploaded.
  ///
  /// In en, this message translates to:
  /// **'Resume uploaded.'**
  String get resumeUploaded;

  /// No description provided for @autofillFromResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Autofill from resume?'**
  String get autofillFromResumeTitle;

  /// No description provided for @resumeScanFoundDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'We found the following details in your resume. Review and edit before saving — nothing is saved automatically.'**
  String get resumeScanFoundDetailsNote;

  /// No description provided for @parsedWithAi.
  ///
  /// In en, this message translates to:
  /// **'Parsed with AI'**
  String get parsedWithAi;

  /// No description provided for @parsedOffline.
  ///
  /// In en, this message translates to:
  /// **'Parsed offline'**
  String get parsedOffline;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @reviewAndApply.
  ///
  /// In en, this message translates to:
  /// **'Review & apply'**
  String get reviewAndApply;

  /// No description provided for @fieldsFilledReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Fields filled in below — review and tap Save (or Add, for work experience) to confirm.'**
  String get fieldsFilledReviewNote;

  /// No description provided for @errorCouldNotOpenResumeColon.
  ///
  /// In en, this message translates to:
  /// **'Could not open resume: {error}'**
  String errorCouldNotOpenResumeColon(String error);

  /// No description provided for @errorCouldNotRemoveResume.
  ///
  /// In en, this message translates to:
  /// **'Could not remove resume: {error}'**
  String errorCouldNotRemoveResume(String error);

  /// No description provided for @prefApplicationUpdates.
  ///
  /// In en, this message translates to:
  /// **'Application updates'**
  String get prefApplicationUpdates;

  /// No description provided for @prefReportDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Report deadlines'**
  String get prefReportDeadlines;

  /// No description provided for @prefMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get prefMessages;

  /// No description provided for @prefSupervisorFeedback.
  ///
  /// In en, this message translates to:
  /// **'Supervisor feedback'**
  String get prefSupervisorFeedback;

  /// No description provided for @errorCouldNotSaveLanguage.
  ///
  /// In en, this message translates to:
  /// **'Could not save language: {error}'**
  String errorCouldNotSaveLanguage(String error);

  /// No description provided for @errorCouldNotSaveTheme.
  ///
  /// In en, this message translates to:
  /// **'Could not save theme: {error}'**
  String errorCouldNotSaveTheme(String error);

  /// No description provided for @yourNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNamePlaceholder;

  /// No description provided for @workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get workExperience;

  /// No description provided for @selectYourProgrammeHint.
  ///
  /// In en, this message translates to:
  /// **'Select your programme'**
  String get selectYourProgrammeHint;

  /// No description provided for @selectYourFacultyHint.
  ///
  /// In en, this message translates to:
  /// **'Select your faculty'**
  String get selectYourFacultyHint;

  /// No description provided for @selectYourSemesterHint.
  ///
  /// In en, this message translates to:
  /// **'Select your semester'**
  String get selectYourSemesterHint;

  /// No description provided for @semesterNumber.
  ///
  /// In en, this message translates to:
  /// **'Semester {number}'**
  String semesterNumber(int number);

  /// No description provided for @cgpaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3.62'**
  String get cgpaHint;

  /// No description provided for @noSkillsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet.'**
  String get noSkillsAddedYet;

  /// No description provided for @addSkillHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HTML, CSS, Java, Public Speaking'**
  String get addSkillHint;

  /// No description provided for @suggestedFromResume.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your resume'**
  String get suggestedFromResume;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @noWorkExperienceAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No work experience added yet.'**
  String get noWorkExperienceAddedYet;

  /// No description provided for @updatedOnDate.
  ///
  /// In en, this message translates to:
  /// **'· Updated {date}'**
  String updatedOnDate(String date);

  /// No description provided for @adminStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get adminStudentsTitle;

  /// No description provided for @adminCompaniesTitle.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get adminCompaniesTitle;

  /// No description provided for @adminSupervisorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisors'**
  String get adminSupervisorsTitle;

  /// No description provided for @adminMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get adminMoreTitle;

  /// No description provided for @adminBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'CIMS Admin'**
  String get adminBrandLabel;

  /// No description provided for @adminWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String adminWelcomeBack(String name);

  /// No description provided for @adminFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminFallbackName;

  /// No description provided for @adminSystemOverview.
  ///
  /// In en, this message translates to:
  /// **'System overview'**
  String get adminSystemOverview;

  /// No description provided for @adminTotalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total students'**
  String get adminTotalStudents;

  /// No description provided for @adminActiveInternships.
  ///
  /// In en, this message translates to:
  /// **'Active internships'**
  String get adminActiveInternships;

  /// No description provided for @adminPartnerCompanies.
  ///
  /// In en, this message translates to:
  /// **'Partner companies'**
  String get adminPartnerCompanies;

  /// No description provided for @adminNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get adminNeedsAttention;

  /// No description provided for @adminAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear — nothing needs your attention right now.'**
  String get adminAllClear;

  /// No description provided for @adminStudentsUnassignedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students unassigned'**
  String adminStudentsUnassignedCount(int count);

  /// No description provided for @adminNoSupervisorAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No academic supervisor assigned yet'**
  String get adminNoSupervisorAssignedYet;

  /// No description provided for @adminSubmissionsPendingReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} submissions pending review'**
  String adminSubmissionsPendingReviewCount(int count);

  /// No description provided for @adminAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting supervisor or admin review'**
  String get adminAwaitingReview;

  /// No description provided for @adminAddCompany.
  ///
  /// In en, this message translates to:
  /// **'Add Company'**
  String get adminAddCompany;

  /// No description provided for @adminAssignSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Assign Supervisor'**
  String get adminAssignSupervisor;

  /// No description provided for @adminRecentlyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Recently registered'**
  String get adminRecentlyRegistered;

  /// No description provided for @adminStudentRegisteredActivity.
  ///
  /// In en, this message translates to:
  /// **'{name} registered'**
  String adminStudentRegisteredActivity(String name);

  /// No description provided for @adminUnnamedStudent.
  ///
  /// In en, this message translates to:
  /// **'Unnamed student'**
  String get adminUnnamedStudent;

  /// No description provided for @adminSearchCompaniesHint.
  ///
  /// In en, this message translates to:
  /// **'Search companies...'**
  String get adminSearchCompaniesHint;

  /// No description provided for @adminRegisteredCompaniesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} registered companies'**
  String adminRegisteredCompaniesCount(int count);

  /// No description provided for @adminPendingVerificationCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending verification'**
  String adminPendingVerificationCount(int count);

  /// No description provided for @adminNoCompaniesTitle.
  ///
  /// In en, this message translates to:
  /// **'No companies'**
  String get adminNoCompaniesTitle;

  /// No description provided for @adminNoCompaniesDescription.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search, or add one.'**
  String get adminNoCompaniesDescription;

  /// No description provided for @adminLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get adminLocationNotSet;

  /// No description provided for @adminStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminStatusPending;

  /// No description provided for @adminStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminStatusVerified;

  /// No description provided for @adminCouldNotVerify.
  ///
  /// In en, this message translates to:
  /// **'Could not verify: {error}'**
  String adminCouldNotVerify(String error);

  /// No description provided for @adminRemoveCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove company?'**
  String get adminRemoveCompanyTitle;

  /// No description provided for @adminRemoveCompanyMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes {name} from the registry. This cannot be undone.'**
  String adminRemoveCompanyMessage(String name);

  /// No description provided for @adminCouldNotRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove: {error}'**
  String adminCouldNotRemove(String error);

  /// No description provided for @adminCompanyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get adminCompanyDetailsTitle;

  /// No description provided for @adminCompanyInformation.
  ///
  /// In en, this message translates to:
  /// **'Company information'**
  String get adminCompanyInformation;

  /// No description provided for @adminLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get adminLocationLabel;

  /// No description provided for @adminHrContactLabel.
  ///
  /// In en, this message translates to:
  /// **'HR Contact'**
  String get adminHrContactLabel;

  /// No description provided for @adminHrEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'HR Email'**
  String get adminHrEmailLabel;

  /// No description provided for @adminHrPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'HR Phone'**
  String get adminHrPhoneLabel;

  /// No description provided for @adminStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminStatusLabel;

  /// No description provided for @adminVerifyCompany.
  ///
  /// In en, this message translates to:
  /// **'Verify company'**
  String get adminVerifyCompany;

  /// No description provided for @adminRemoveCompanyButton.
  ///
  /// In en, this message translates to:
  /// **'Remove company'**
  String get adminRemoveCompanyButton;

  /// No description provided for @adminCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required.'**
  String get adminCompanyNameRequired;

  /// No description provided for @adminCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String adminCouldNotSave(String error);

  /// No description provided for @adminEditCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Company'**
  String get adminEditCompanyTitle;

  /// No description provided for @adminCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get adminCompanyNameLabel;

  /// No description provided for @adminIndustryLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get adminIndustryLabel;

  /// No description provided for @adminOtherIndustryOption.
  ///
  /// In en, this message translates to:
  /// **'Other (type below)'**
  String get adminOtherIndustryOption;

  /// No description provided for @adminIndustryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry name'**
  String get adminIndustryNameLabel;

  /// No description provided for @adminSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get adminSelectLocation;

  /// No description provided for @adminHrContactSection.
  ///
  /// In en, this message translates to:
  /// **'HR contact'**
  String get adminHrContactSection;

  /// No description provided for @adminHrContactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HR contact name'**
  String get adminHrContactNameLabel;

  /// No description provided for @adminHrEmailFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'HR email'**
  String get adminHrEmailFieldLabel;

  /// No description provided for @adminHrPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'HR phone number'**
  String get adminHrPhoneNumberLabel;

  /// No description provided for @adminUnassign.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get adminUnassign;

  /// No description provided for @adminUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get adminUnnamed;

  /// No description provided for @adminCouldNotAssign.
  ///
  /// In en, this message translates to:
  /// **'Could not assign: {error}'**
  String adminCouldNotAssign(String error);

  /// No description provided for @adminSearchByNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get adminSearchByNameHint;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get adminFilterAssigned;

  /// No description provided for @adminFilterUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get adminFilterUnassigned;

  /// No description provided for @adminNoStudentsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get adminNoStudentsFoundTitle;

  /// No description provided for @adminNoStudentsFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get adminNoStudentsFoundDescription;

  /// No description provided for @adminProgrammeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Programme not set'**
  String get adminProgrammeNotSet;

  /// No description provided for @adminSupervisorColonName.
  ///
  /// In en, this message translates to:
  /// **'Supervisor: {name}'**
  String adminSupervisorColonName(String name);

  /// No description provided for @adminNoSupervisorAssigned.
  ///
  /// In en, this message translates to:
  /// **'No supervisor assigned'**
  String get adminNoSupervisorAssigned;

  /// No description provided for @adminAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get adminAssign;

  /// No description provided for @adminSearchSupervisorsHint.
  ///
  /// In en, this message translates to:
  /// **'Search supervisors...'**
  String get adminSearchSupervisorsHint;

  /// No description provided for @adminAcademicSupervisorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} academic supervisors'**
  String adminAcademicSupervisorsCount(int count);

  /// No description provided for @adminNoSupervisorsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No supervisors found'**
  String get adminNoSupervisorsFoundTitle;

  /// No description provided for @adminNoSupervisorsFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'No academic supervisor accounts have signed up yet.'**
  String get adminNoSupervisorsFoundDescription;

  /// No description provided for @adminFacultyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Faculty not set'**
  String get adminFacultyNotSet;

  /// No description provided for @adminThisSupervisorFallback.
  ///
  /// In en, this message translates to:
  /// **'this supervisor'**
  String get adminThisSupervisorFallback;

  /// No description provided for @adminPromoteToAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote to admin?'**
  String get adminPromoteToAdminTitle;

  /// No description provided for @adminPromoteToAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will immediately become a System Administrator — their account will gain full admin access on next login and they will no longer appear in the supervisors list. This cannot be undone from here.'**
  String adminPromoteToAdminMessage(String name);

  /// No description provided for @adminPromote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get adminPromote;

  /// No description provided for @adminCouldNotPromote.
  ///
  /// In en, this message translates to:
  /// **'Could not promote: {error}'**
  String adminCouldNotPromote(String error);

  /// No description provided for @adminSupervisorDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor details'**
  String get adminSupervisorDetailsTitle;

  /// No description provided for @adminPromoteToAdminButton.
  ///
  /// In en, this message translates to:
  /// **'Promote to admin'**
  String get adminPromoteToAdminButton;

  /// No description provided for @adminNoStudentsAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No students assigned yet.'**
  String get adminNoStudentsAssignedYet;

  /// No description provided for @adminCouldNotSaveReview.
  ///
  /// In en, this message translates to:
  /// **'Could not save review: {error}'**
  String adminCouldNotSaveReview(String error);

  /// No description provided for @adminCouldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String adminCouldNotOpenFile(String error);

  /// No description provided for @adminMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get adminMonitorTitle;

  /// No description provided for @adminTabStudentProgress.
  ///
  /// In en, this message translates to:
  /// **'Student progress'**
  String get adminTabStudentProgress;

  /// No description provided for @adminTabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminTabReports;

  /// No description provided for @adminTabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get adminTabDocuments;

  /// No description provided for @adminNoStudentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No students'**
  String get adminNoStudentsTitle;

  /// No description provided for @adminNoStudentsRegisteredDescription.
  ///
  /// In en, this message translates to:
  /// **'No students have registered yet.'**
  String get adminNoStudentsRegisteredDescription;

  /// No description provided for @adminSubmissionsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Submissions will appear here.'**
  String get adminSubmissionsAppearHere;

  /// No description provided for @adminEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get adminEnterCurrentPassword;

  /// No description provided for @adminNewPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match.'**
  String get adminNewPasswordsDoNotMatch;

  /// No description provided for @adminPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get adminPasswordChanged;

  /// No description provided for @adminLogOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again to access the admin console.'**
  String get adminLogOutConfirmMessage;

  /// No description provided for @adminSystemAdministrator.
  ///
  /// In en, this message translates to:
  /// **'System Administrator'**
  String get adminSystemAdministrator;

  /// No description provided for @adminSectionOversight.
  ///
  /// In en, this message translates to:
  /// **'Oversight'**
  String get adminSectionOversight;

  /// No description provided for @adminMonitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Student progress, reports & documents'**
  String get adminMonitorSubtitle;

  /// No description provided for @adminDocumentTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Templates'**
  String get adminDocumentTemplatesTitle;

  /// No description provided for @adminDocumentTemplatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage fillable PDF forms (e.g. parent acknowledgement)'**
  String get adminDocumentTemplatesSubtitle;

  /// No description provided for @adminIntakesTitle.
  ///
  /// In en, this message translates to:
  /// **'Intakes'**
  String get adminIntakesTitle;

  /// No description provided for @adminIntakesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set internship windows and assign students'**
  String get adminIntakesSubtitle;

  /// No description provided for @adminSectionCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get adminSectionCommunication;

  /// No description provided for @adminMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message students, supervisors, or companies'**
  String get adminMessagesSubtitle;

  /// No description provided for @adminNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminNotifications;

  /// No description provided for @adminNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View system alerts and updates'**
  String get adminNotificationsSubtitle;

  /// No description provided for @adminSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get adminSectionPreferences;

  /// No description provided for @adminNotifPrefsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what you get notified about'**
  String get adminNotifPrefsSubtitle;

  /// No description provided for @adminSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get adminSectionSystem;

  /// No description provided for @adminFullNameCannotBeBlank.
  ///
  /// In en, this message translates to:
  /// **'Full name cannot be blank.'**
  String get adminFullNameCannotBeBlank;

  /// No description provided for @adminUnsupportedFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format. Please upload a JPG, JPEG, or PNG image.'**
  String get adminUnsupportedFileFormat;

  /// No description provided for @adminPhotoEmptyError.
  ///
  /// In en, this message translates to:
  /// **'The selected photo is empty (0 bytes). Try a different photo.'**
  String get adminPhotoEmptyError;

  /// No description provided for @adminPhotoNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'The selected photo could not be found on disk.'**
  String get adminPhotoNotFoundError;

  /// No description provided for @adminUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String adminUploadFailed(String error);

  /// No description provided for @adminSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'camera'**
  String get adminSourceCamera;

  /// No description provided for @adminSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'gallery'**
  String get adminSourceGallery;

  /// No description provided for @adminCouldNotAccessSource.
  ///
  /// In en, this message translates to:
  /// **'Could not access {source}: {error}'**
  String adminCouldNotAccessSource(String source, String error);

  /// No description provided for @adminCouldNotRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo: {error}'**
  String adminCouldNotRemovePhoto(String error);

  /// No description provided for @cropPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Position your photo'**
  String get cropPhotoTitle;

  /// No description provided for @cropPhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cropPhotoConfirm;

  /// No description provided for @errorCropFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not crop the photo. Please try again.'**
  String get errorCropFailed;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @parentAcknowledgementTitle.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgement Form'**
  String get parentAcknowledgementTitle;

  /// No description provided for @parentFormNotConfiguredError.
  ///
  /// In en, this message translates to:
  /// **'The acknowledgement form has not been set up yet. Please contact the university.'**
  String get parentFormNotConfiguredError;

  /// No description provided for @parentCouldNotLoadFormError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the acknowledgement form: {error}'**
  String parentCouldNotLoadFormError(String error);

  /// No description provided for @parentSignAndSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Sign & Submit'**
  String get parentSignAndSubmitButton;

  /// No description provided for @parentSignatureTimestampNote.
  ///
  /// In en, this message translates to:
  /// **'Your digital signature will be recorded with a timestamp.'**
  String get parentSignatureTimestampNote;

  /// No description provided for @parentDrawSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature'**
  String get parentDrawSignatureTitle;

  /// No description provided for @parentCouldNotSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit form: {error}'**
  String parentCouldNotSubmitError(String error);

  /// No description provided for @parentCouldNotOpenFormError.
  ///
  /// In en, this message translates to:
  /// **'Could not open form: {error}'**
  String parentCouldNotOpenFormError(String error);

  /// No description provided for @parentFormSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Form submitted successfully'**
  String get parentFormSubmittedTitle;

  /// No description provided for @parentFormSubmittedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your acknowledgement has been recorded.'**
  String get parentFormSubmittedDescription;

  /// No description provided for @parentSignedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Signed on {date}'**
  String parentSignedOnDate(String date);

  /// No description provided for @parentViewPdfButton.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get parentViewPdfButton;

  /// No description provided for @parentBackToHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get parentBackToHomeButton;

  /// No description provided for @viewCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'View company profile'**
  String get viewCompanyProfile;

  /// No description provided for @companyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Profile'**
  String get companyProfileTitle;

  /// No description provided for @companyProfileJobPostings.
  ///
  /// In en, this message translates to:
  /// **'Job Postings'**
  String get companyProfileJobPostings;

  /// No description provided for @companyProfileNoPostings.
  ///
  /// In en, this message translates to:
  /// **'No postings from this company yet.'**
  String get companyProfileNoPostings;

  /// No description provided for @companyProfilePastInterns.
  ///
  /// In en, this message translates to:
  /// **'Past Interns'**
  String get companyProfilePastInterns;

  /// No description provided for @companyProfileInternCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 student has interned here} other{{count} students have interned here}}'**
  String companyProfileInternCount(int count);

  /// No description provided for @companyProfileReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get companyProfileReviews;

  /// No description provided for @companyProfileReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 review} other{{count} reviews}}'**
  String companyProfileReviewCount(int count);

  /// No description provided for @companyProfileNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to share your experience.'**
  String get companyProfileNoReviewsYet;

  /// No description provided for @companyProfileWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get companyProfileWriteReview;

  /// No description provided for @companyProfileEditReview.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get companyProfileEditReview;

  /// No description provided for @companyProfileRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get companyProfileRatingLabel;

  /// No description provided for @companyProfileReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience working here (optional)'**
  String get companyProfileReviewHint;

  /// No description provided for @companyProfileReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted. Thank you!'**
  String get companyProfileReviewSubmitted;

  /// No description provided for @companyProfileReviewError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit review: {error}'**
  String companyProfileReviewError(String error);

  /// No description provided for @companyProfileMustApplyNote.
  ///
  /// In en, this message translates to:
  /// **'Only students who have applied to this company can leave a review.'**
  String get companyProfileMustApplyNote;

  /// No description provided for @docFillAndSignAction.
  ///
  /// In en, this message translates to:
  /// **'Fill & Sign'**
  String get docFillAndSignAction;

  /// No description provided for @docAwaitingCompanyUpload.
  ///
  /// In en, this message translates to:
  /// **'Awaiting upload from company'**
  String get docAwaitingCompanyUpload;

  /// No description provided for @docAvailableOnceAccepted.
  ///
  /// In en, this message translates to:
  /// **'Available once your application is accepted'**
  String get docAvailableOnceAccepted;

  /// No description provided for @studentLetterNotConfiguredError.
  ///
  /// In en, this message translates to:
  /// **'This form has not been set up yet. Please contact the university.'**
  String get studentLetterNotConfiguredError;

  /// No description provided for @studentLetterCouldNotLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the form: {error}'**
  String studentLetterCouldNotLoadError(String error);

  /// No description provided for @studentLetterTapToFillInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap directly on the form to fill it in, then submit at the bottom.'**
  String get studentLetterTapToFillInstruction;

  /// No description provided for @studentLetterSignAndSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Sign & Submit'**
  String get studentLetterSignAndSubmitButton;

  /// No description provided for @studentLetterSignatureTimestampNote.
  ///
  /// In en, this message translates to:
  /// **'Your digital signature will be recorded with a timestamp.'**
  String get studentLetterSignatureTimestampNote;

  /// No description provided for @studentLetterDrawSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw your signature'**
  String get studentLetterDrawSignatureTitle;

  /// No description provided for @studentLetterCouldNotSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit form: {error}'**
  String studentLetterCouldNotSubmitError(String error);

  /// No description provided for @studentLetterCouldNotOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open form: {error}'**
  String studentLetterCouldNotOpenError(String error);

  /// No description provided for @studentLetterSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Form submitted successfully'**
  String get studentLetterSubmittedTitle;

  /// No description provided for @studentLetterSubmittedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your signed letter has been saved.'**
  String get studentLetterSubmittedDescription;

  /// No description provided for @studentLetterSignedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Signed on {date}'**
  String studentLetterSignedOnDate(String date);

  /// No description provided for @studentLetterViewPdfButton.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get studentLetterViewPdfButton;

  /// No description provided for @studentLetterBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get studentLetterBackButton;

  /// No description provided for @hrOfferLetterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Letter'**
  String get hrOfferLetterSectionTitle;

  /// No description provided for @hrUploadOfferLetter.
  ///
  /// In en, this message translates to:
  /// **'Upload Offer Letter'**
  String get hrUploadOfferLetter;

  /// No description provided for @hrReplaceOfferLetter.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get hrReplaceOfferLetter;

  /// No description provided for @csDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get csDocuments;

  /// No description provided for @csNoDocumentsOnFile.
  ///
  /// In en, this message translates to:
  /// **'No documents on file yet.'**
  String get csNoDocumentsOnFile;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @calendarCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open your calendar.'**
  String get calendarCouldNotOpen;

  /// No description provided for @calendarEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview: {title}'**
  String calendarEventTitle(String title);

  /// No description provided for @calendarEventDetails.
  ///
  /// In en, this message translates to:
  /// **'CIMS interview with {company}'**
  String calendarEventDetails(String company);

  /// No description provided for @hrSearchApplicants.
  ///
  /// In en, this message translates to:
  /// **'Search by name, programme or skill'**
  String get hrSearchApplicants;

  /// No description provided for @hrAllPostings.
  ///
  /// In en, this message translates to:
  /// **'All postings'**
  String get hrAllPostings;

  /// No description provided for @hrShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get hrShortlisted;

  /// No description provided for @hrShortlist.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get hrShortlist;

  /// No description provided for @hrRemoveShortlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from shortlist'**
  String get hrRemoveShortlist;

  /// No description provided for @hrPrivateNotes.
  ///
  /// In en, this message translates to:
  /// **'Private notes'**
  String get hrPrivateNotes;

  /// No description provided for @hrPrivateNotesInfo.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this. The student never does.'**
  String get hrPrivateNotesInfo;

  /// No description provided for @hrNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a note about this applicant'**
  String get hrNoteHint;

  /// No description provided for @hrSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get hrSaveNote;

  /// No description provided for @hrNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get hrNoteSaved;

  /// No description provided for @hrNoMatchingApplicants.
  ///
  /// In en, this message translates to:
  /// **'No applicants match your search.'**
  String get hrNoMatchingApplicants;

  /// No description provided for @hrTabOffered.
  ///
  /// In en, this message translates to:
  /// **'Offered ({count})'**
  String hrTabOffered(int count);

  /// No description provided for @hrTabClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed ({count})'**
  String hrTabClosed(int count);

  /// No description provided for @hrClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get hrClearFilters;

  /// No description provided for @adminAuditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get adminAuditLogTitle;

  /// No description provided for @adminAuditLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who approved, created or changed what'**
  String get adminAuditLogSubtitle;

  /// No description provided for @auditFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get auditFilterAll;

  /// No description provided for @auditFilterAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get auditFilterAccounts;

  /// No description provided for @auditFilterCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get auditFilterCompanies;

  /// No description provided for @auditFilterStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get auditFilterStudents;

  /// No description provided for @auditFilterSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get auditFilterSetup;

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been recorded yet.'**
  String get auditEmpty;

  /// No description provided for @auditSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auditSystem;

  /// No description provided for @auditLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get auditLoadMore;

  /// No description provided for @adminAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Placement analytics'**
  String get adminAnalyticsTitle;

  /// No description provided for @adminAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Placement rate, applications and students still without an internship'**
  String get adminAnalyticsSubtitle;

  /// No description provided for @analyticsPlacementRate.
  ///
  /// In en, this message translates to:
  /// **'Placement rate'**
  String get analyticsPlacementRate;

  /// No description provided for @analyticsPlacedOf.
  ///
  /// In en, this message translates to:
  /// **'{placed} of {total} students placed'**
  String analyticsPlacedOf(int placed, int total);

  /// No description provided for @analyticsStudentsApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get analyticsStudentsApplied;

  /// No description provided for @analyticsApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get analyticsApplications;

  /// No description provided for @analyticsWithoutPlacement.
  ///
  /// In en, this message translates to:
  /// **'No placement yet'**
  String get analyticsWithoutPlacement;

  /// No description provided for @analyticsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Applications by status'**
  String get analyticsByStatus;

  /// No description provided for @analyticsByProgramme.
  ///
  /// In en, this message translates to:
  /// **'By programme'**
  String get analyticsByProgramme;

  /// No description provided for @analyticsByCompany.
  ///
  /// In en, this message translates to:
  /// **'By company'**
  String get analyticsByCompany;

  /// No description provided for @analyticsTopPostings.
  ///
  /// In en, this message translates to:
  /// **'Most applied postings'**
  String get analyticsTopPostings;

  /// No description provided for @analyticsUnplaced.
  ///
  /// In en, this message translates to:
  /// **'Students without a placement'**
  String get analyticsUnplaced;

  /// No description provided for @analyticsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get analyticsExportCsv;

  /// No description provided for @analyticsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create or open the file.'**
  String get analyticsExportFailed;

  /// No description provided for @analyticsRowStudentsPlaced.
  ///
  /// In en, this message translates to:
  /// **'{placed}/{students} placed'**
  String analyticsRowStudentsPlaced(int placed, int students);

  /// No description provided for @analyticsRowCompany.
  ///
  /// In en, this message translates to:
  /// **'{postings} postings · {applications} applications · {placed} placed'**
  String analyticsRowCompany(int postings, int applications, int placed);

  /// No description provided for @analyticsRowPosting.
  ///
  /// In en, this message translates to:
  /// **'{company} · {applications} applications · {offered} offered'**
  String analyticsRowPosting(String company, int applications, int offered);

  /// No description provided for @analyticsNoStudentsUnplaced.
  ///
  /// In en, this message translates to:
  /// **'Every student has a placement.'**
  String get analyticsNoStudentsUnplaced;

  /// No description provided for @ivTheCompany.
  ///
  /// In en, this message translates to:
  /// **'The company'**
  String get ivTheCompany;

  /// No description provided for @ivTheStudent.
  ///
  /// In en, this message translates to:
  /// **'The student'**
  String get ivTheStudent;

  /// No description provided for @ivTheSystem.
  ///
  /// In en, this message translates to:
  /// **'The system'**
  String get ivTheSystem;

  /// No description provided for @ivRequestSentCompany.
  ///
  /// In en, this message translates to:
  /// **'Request sent. The interview moves only if the company accepts.'**
  String get ivRequestSentCompany;

  /// No description provided for @ivDeclineNewTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline the new time'**
  String get ivDeclineNewTimeTitle;

  /// No description provided for @ivDeclinePromptToCompany.
  ///
  /// In en, this message translates to:
  /// **'Tell the company why you are declining. The interview stays on its current time.'**
  String get ivDeclinePromptToCompany;

  /// No description provided for @ivDeclineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I cannot attend at that time.'**
  String get ivDeclineHint;

  /// No description provided for @ivDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get ivDecline;

  /// No description provided for @ivAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get ivAccept;

  /// No description provided for @ivAcceptedMoved.
  ///
  /// In en, this message translates to:
  /// **'Accepted. Your interview has been moved.'**
  String get ivAcceptedMoved;

  /// No description provided for @ivDeclinedStays.
  ///
  /// In en, this message translates to:
  /// **'Declined. The interview stays as it was.'**
  String get ivDeclinedStays;

  /// No description provided for @ivCancelInterview.
  ///
  /// In en, this message translates to:
  /// **'Cancel interview'**
  String get ivCancelInterview;

  /// No description provided for @ivCancelPromptToCompany.
  ///
  /// In en, this message translates to:
  /// **'Tell the company why you are cancelling the interview on {when}. They will see this reason.'**
  String ivCancelPromptToCompany(String when);

  /// No description provided for @ivCancelledNotified.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled. The company has been notified with your reason.'**
  String get ivCancelledNotified;

  /// No description provided for @ivCouldNotCancel.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel: {error}'**
  String ivCouldNotCancel(String error);

  /// No description provided for @ivCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ivCancelButton;

  /// No description provided for @ivRescheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get ivRescheduleButton;

  /// No description provided for @ivChangeWindowStudent.
  ///
  /// In en, this message translates to:
  /// **'An interview can only be cancelled or rescheduled up to 2 hours before it starts. If you cannot attend, please message the company.'**
  String get ivChangeWindowStudent;

  /// No description provided for @ivCompanyWillArrange.
  ///
  /// In en, this message translates to:
  /// **'The company will arrange a new time if your application continues.'**
  String get ivCompanyWillArrange;

  /// No description provided for @ivChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get ivChangesTitle;

  /// No description provided for @ivChangeMoved.
  ///
  /// In en, this message translates to:
  /// **'{actor} moved the interview'**
  String ivChangeMoved(String actor);

  /// No description provided for @ivChangeMovedFromTo.
  ///
  /// In en, this message translates to:
  /// **'{actor} moved the interview from {from} to {to}'**
  String ivChangeMovedFromTo(String actor, String from, String to);

  /// No description provided for @ivChangeAsked.
  ///
  /// In en, this message translates to:
  /// **'{actor} asked to move the interview'**
  String ivChangeAsked(String actor);

  /// No description provided for @ivChangeAskedTo.
  ///
  /// In en, this message translates to:
  /// **'{actor} asked to move the interview to {to}'**
  String ivChangeAskedTo(String actor, String to);

  /// No description provided for @ivChangeDeclined.
  ///
  /// In en, this message translates to:
  /// **'{actor} declined the new time'**
  String ivChangeDeclined(String actor);

  /// No description provided for @ivChangeDeclinedFor.
  ///
  /// In en, this message translates to:
  /// **'{actor} declined the new time ({time})'**
  String ivChangeDeclinedFor(String actor, String time);

  /// No description provided for @ivAutoCancelled.
  ///
  /// In en, this message translates to:
  /// **'The interview was cancelled automatically'**
  String get ivAutoCancelled;

  /// No description provided for @ivChangeCancelled.
  ///
  /// In en, this message translates to:
  /// **'{actor} cancelled the interview'**
  String ivChangeCancelled(String actor);

  /// No description provided for @ivReasonLine.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String ivReasonLine(String reason);

  /// No description provided for @ivYouAskedToReschedule.
  ///
  /// In en, this message translates to:
  /// **'You asked to reschedule'**
  String get ivYouAskedToReschedule;

  /// No description provided for @ivAskedToReschedule.
  ///
  /// In en, this message translates to:
  /// **'{who} asked to reschedule'**
  String ivAskedToReschedule(String who);

  /// No description provided for @ivLineNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get ivLineNow;

  /// No description provided for @ivLineProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get ivLineProposed;

  /// No description provided for @ivLineReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get ivLineReason;

  /// No description provided for @ivWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {who}. The interview stays on its current time unless they accept.'**
  String ivWaitingFor(String who);

  /// No description provided for @ivMovesOnlyIfYouAccept.
  ///
  /// In en, this message translates to:
  /// **'The interview only moves if you accept. If you decline, it stays on its current time.'**
  String get ivMovesOnlyIfYouAccept;

  /// No description provided for @ivWithdrawRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get ivWithdrawRequest;

  /// No description provided for @ivTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get ivTryAgain;

  /// No description provided for @ivNoFreeTimes.
  ///
  /// In en, this message translates to:
  /// **'No free interview times in the next {days} days.'**
  String ivNoFreeTimes(int days);

  /// No description provided for @ivNoFreeTimesHint.
  ///
  /// In en, this message translates to:
  /// **'Interview times come from the interviewer\'s weekly availability. All their slots may be booked, or no availability has been set.'**
  String get ivNoFreeTimesHint;

  /// No description provided for @ivChooseDay.
  ///
  /// In en, this message translates to:
  /// **'Choose a day'**
  String get ivChooseDay;

  /// No description provided for @ivChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get ivChooseTime;

  /// No description provided for @ivPickFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a new day and time first.'**
  String get ivPickFirst;

  /// No description provided for @ivRequestNewTime.
  ///
  /// In en, this message translates to:
  /// **'Request a new time'**
  String get ivRequestNewTime;

  /// No description provided for @ivReasonForChange.
  ///
  /// In en, this message translates to:
  /// **'Reason for the change'**
  String get ivReasonForChange;

  /// No description provided for @ivWillSeeReason.
  ///
  /// In en, this message translates to:
  /// **'{who} will see this reason. The interview only moves if they accept; until then it stays on its current time.'**
  String ivWillSeeReason(String who);

  /// No description provided for @ivReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I have a university exam at that time.'**
  String get ivReasonHint;

  /// No description provided for @ivSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get ivSendRequest;

  /// No description provided for @offAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept this offer?'**
  String get offAcceptTitle;

  /// No description provided for @offAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'{title} at {company} will become your active internship.'**
  String offAcceptBody(String title, String company);

  /// No description provided for @offAcceptCloses.
  ///
  /// In en, this message translates to:
  /// **'Your {count} other open applications will be closed and cannot be reopened.'**
  String offAcceptCloses(int count);

  /// No description provided for @offAcceptOne.
  ///
  /// In en, this message translates to:
  /// **'You can only have one active internship.'**
  String get offAcceptOne;

  /// No description provided for @offNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get offNotYet;

  /// No description provided for @offAcceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept offer'**
  String get offAcceptOffer;

  /// No description provided for @offAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted. {company} has been notified.'**
  String offAccepted(String company);

  /// No description provided for @offCouldNotAccept.
  ///
  /// In en, this message translates to:
  /// **'Could not accept the offer: {error}'**
  String offCouldNotAccept(String error);

  /// No description provided for @appTabOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers ({count})'**
  String appTabOffers(int count);

  /// No description provided for @appInterviewCancelledTap.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled. Tap to see why.'**
  String get appInterviewCancelledTap;

  /// No description provided for @appOfferedBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, this company has offered you the internship. You can hold several offers; accepting one closes the others.'**
  String get appOfferedBody;

  /// No description provided for @appReasonFromCompany.
  ///
  /// In en, this message translates to:
  /// **'Reason from the company'**
  String get appReasonFromCompany;

  /// No description provided for @appNoReasonRecorded.
  ///
  /// In en, this message translates to:
  /// **'No reason was recorded.'**
  String get appNoReasonRecorded;

  /// No description provided for @appClosedAcceptedOther.
  ///
  /// In en, this message translates to:
  /// **'Closed because you accepted another offer.'**
  String get appClosedAcceptedOther;

  /// No description provided for @pushOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts outside the app are off'**
  String get pushOffTitle;

  /// No description provided for @pushOffBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone is blocking CIMS notifications, so new interviews, offers and messages only show up here. Turn them on to be alerted straight away.'**
  String get pushOffBody;

  /// No description provided for @pushTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushTurnOn;

  /// No description provided for @reasonRequiredHelper.
  ///
  /// In en, this message translates to:
  /// **'Required, at least {min} characters.'**
  String reasonRequiredHelper(int min);

  /// No description provided for @reasonOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional.'**
  String get reasonOptionalHelper;

  /// No description provided for @ivSlotsFree.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String ivSlotsFree(int count);

  /// No description provided for @avHoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Hours saved.'**
  String get avHoursSaved;

  /// No description provided for @avRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove these hours?'**
  String get avRemoveTitle;

  /// No description provided for @avRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{day} {from} to {to} will no longer be offered for new interviews. Interviews already booked in this window stay as they are.'**
  String avRemoveBody(String day, String from, String to);

  /// No description provided for @avKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get avKeep;

  /// No description provided for @avRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get avRemove;

  /// No description provided for @avDayOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Day you are not available'**
  String get avDayOffHelp;

  /// No description provided for @avTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview availability'**
  String get avTitle;

  /// No description provided for @avAddHours.
  ///
  /// In en, this message translates to:
  /// **'Add hours'**
  String get avAddHours;

  /// No description provided for @avIntro.
  ///
  /// In en, this message translates to:
  /// **'Set the hours you can interview. Each window is cut into slots of the length you choose, and a slot disappears as soon as it is booked, so nobody can book the same time twice. Times are in Malaysian time.'**
  String get avIntro;

  /// No description provided for @avWeeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours'**
  String get avWeeklyHours;

  /// No description provided for @avNoHoursYet.
  ///
  /// In en, this message translates to:
  /// **'No hours set yet. Tap \"Add hours\" so interviews can be scheduled with you.'**
  String get avNoHoursYet;

  /// No description provided for @avDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Days off'**
  String get avDaysOff;

  /// No description provided for @avAddDayOff.
  ///
  /// In en, this message translates to:
  /// **'Add day off'**
  String get avAddDayOff;

  /// No description provided for @avNoDaysOff.
  ///
  /// In en, this message translates to:
  /// **'No upcoming days off. Add leave or public holidays here and no interviews will be offered on those days.'**
  String get avNoDaysOff;

  /// No description provided for @avNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get avNotAvailable;

  /// No description provided for @avMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String avMinutesShort(int minutes);

  /// No description provided for @avPickOneDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get avPickOneDay;

  /// No description provided for @avEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start time.'**
  String get avEndAfterStart;

  /// No description provided for @avShorterThanSlot.
  ///
  /// In en, this message translates to:
  /// **'This window is shorter than one {minutes}-minute slot.'**
  String avShorterThanSlot(int minutes);

  /// No description provided for @avOverlap.
  ///
  /// In en, this message translates to:
  /// **'These hours overlap hours you have already set on one of the chosen days. Remove or change the existing hours first.'**
  String get avOverlap;

  /// No description provided for @avAddAvailableHours.
  ///
  /// In en, this message translates to:
  /// **'Add available hours'**
  String get avAddAvailableHours;

  /// No description provided for @avDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get avDays;

  /// No description provided for @avMonFri.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri'**
  String get avMonFri;

  /// No description provided for @avEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get avEveryDay;

  /// No description provided for @avFromTime.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String avFromTime(String time);

  /// No description provided for @avToTime.
  ///
  /// In en, this message translates to:
  /// **'To {time}'**
  String avToTime(String time);

  /// No description provided for @avLengthOfInterview.
  ///
  /// In en, this message translates to:
  /// **'Length of each interview'**
  String get avLengthOfInterview;

  /// No description provided for @avSlotsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} slots of {minutes} minutes per selected day.'**
  String avSlotsSummary(int count, int minutes);

  /// No description provided for @avSaveHours.
  ///
  /// In en, this message translates to:
  /// **'Save hours'**
  String get avSaveHours;

  /// No description provided for @apTitle.
  ///
  /// In en, this message translates to:
  /// **'Student profile'**
  String get apTitle;

  /// No description provided for @apUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed student'**
  String get apUnnamed;

  /// No description provided for @apCouldNotOpenResume.
  ///
  /// In en, this message translates to:
  /// **'Could not open resume: {error}'**
  String apCouldNotOpenResume(String error);

  /// No description provided for @apCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the full profile: {error}'**
  String apCouldNotLoad(String error);

  /// No description provided for @apContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get apContact;

  /// No description provided for @apEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get apEmail;

  /// No description provided for @apPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get apPhone;

  /// No description provided for @apStudies.
  ///
  /// In en, this message translates to:
  /// **'Studies'**
  String get apStudies;

  /// No description provided for @apProgramme.
  ///
  /// In en, this message translates to:
  /// **'Programme'**
  String get apProgramme;

  /// No description provided for @apFaculty.
  ///
  /// In en, this message translates to:
  /// **'Faculty'**
  String get apFaculty;

  /// No description provided for @apSemester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get apSemester;

  /// No description provided for @apCgpa.
  ///
  /// In en, this message translates to:
  /// **'CGPA'**
  String get apCgpa;

  /// No description provided for @apSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get apSkills;

  /// No description provided for @apNoSkills.
  ///
  /// In en, this message translates to:
  /// **'No skills listed.'**
  String get apNoSkills;

  /// No description provided for @apWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Work experience'**
  String get apWorkExperience;

  /// No description provided for @apNoExperience.
  ///
  /// In en, this message translates to:
  /// **'No work experience listed.'**
  String get apNoExperience;

  /// No description provided for @apResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get apResume;

  /// No description provided for @apNoResume.
  ///
  /// In en, this message translates to:
  /// **'No resume uploaded'**
  String get apNoResume;

  /// No description provided for @apView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get apView;

  /// No description provided for @apNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get apNotProvided;

  /// No description provided for @apPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get apPresent;

  /// No description provided for @hrViewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View full profile'**
  String get hrViewFullProfile;

  /// No description provided for @hrvInterviewCancelledWas.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled (was {when})'**
  String hrvInterviewCancelledWas(String when);

  /// No description provided for @hrvInterviewLine.
  ///
  /// In en, this message translates to:
  /// **'Interview: {when}'**
  String hrvInterviewLine(String when);

  /// No description provided for @hrvAcceptedAnother.
  ///
  /// In en, this message translates to:
  /// **'The student accepted another offer.'**
  String get hrvAcceptedAnother;

  /// No description provided for @hrvCouldNotUploadOffer.
  ///
  /// In en, this message translates to:
  /// **'Could not upload offer letter: {error}'**
  String hrvCouldNotUploadOffer(String error);

  /// No description provided for @hrvWithdrawOffer.
  ///
  /// In en, this message translates to:
  /// **'Withdraw offer'**
  String get hrvWithdrawOffer;

  /// No description provided for @hrvRejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject application'**
  String get hrvRejectApplication;

  /// No description provided for @hrvWithdrawPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} why the offer is being withdrawn. They will see this reason.'**
  String hrvWithdrawPrompt(String name);

  /// No description provided for @hrvRejectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} why the application is not successful. They will see this reason.'**
  String hrvRejectPrompt(String name);

  /// No description provided for @hrvReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get hrvReject;

  /// No description provided for @hrvRejectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The position has been filled by a candidate with more relevant experience.'**
  String get hrvRejectHint;

  /// No description provided for @hrvCouldNotReject.
  ///
  /// In en, this message translates to:
  /// **'Could not reject: {error}'**
  String hrvCouldNotReject(String error);

  /// No description provided for @hrvMakeOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Make an offer?'**
  String get hrvMakeOfferTitle;

  /// No description provided for @hrvMakeOfferBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be notified and can accept the offer from their Applications screen. They may hold offers from several companies; once they accept one, the others are closed.'**
  String hrvMakeOfferBody(String name);

  /// No description provided for @hrvMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make offer'**
  String get hrvMakeOffer;

  /// No description provided for @hrvCouldNotMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'Could not make the offer: {error}'**
  String hrvCouldNotMakeOffer(String error);

  /// No description provided for @hrvNoResumeUploaded.
  ///
  /// In en, this message translates to:
  /// **'No resume uploaded.'**
  String get hrvNoResumeUploaded;

  /// No description provided for @hrvSetMyAvailability.
  ///
  /// In en, this message translates to:
  /// **'Set my availability'**
  String get hrvSetMyAvailability;

  /// No description provided for @hrvDeclinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} why you are declining. The interview stays on its current time.'**
  String hrvDeclinePrompt(String name);

  /// No description provided for @hrvDeclineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. That day the interviewer is not available.'**
  String get hrvDeclineHint;

  /// No description provided for @hrvAcceptedMoved.
  ///
  /// In en, this message translates to:
  /// **'Accepted. The interview has been moved.'**
  String get hrvAcceptedMoved;

  /// No description provided for @hrvCancelPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell {name} why the interview on {when} is cancelled. They will see this reason.'**
  String hrvCancelPrompt(String name, String when);

  /// No description provided for @hrvCancelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. The interviewer is unavailable on that day.'**
  String get hrvCancelHint;

  /// No description provided for @hrvCancelledNotified.
  ///
  /// In en, this message translates to:
  /// **'Interview cancelled. {name} has been notified with your reason.'**
  String hrvCancelledNotified(String name);

  /// No description provided for @hrvChangeWindow.
  ///
  /// In en, this message translates to:
  /// **'An interview can only be cancelled or rescheduled up to 2 hours before it starts.'**
  String get hrvChangeWindow;

  /// No description provided for @hrvNoInterviewBooked.
  ///
  /// In en, this message translates to:
  /// **'No interview is booked.'**
  String get hrvNoInterviewBooked;

  /// No description provided for @hrvInterviewWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'The interview on {when} was cancelled.'**
  String hrvInterviewWasCancelled(String when);

  /// No description provided for @hrvScheduleNew.
  ///
  /// In en, this message translates to:
  /// **'Schedule a new interview'**
  String get hrvScheduleNew;

  /// No description provided for @hrvOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent. Waiting for {name} to accept. The offer letter and acceptance letter can be added once they accept.'**
  String hrvOfferSent(String name);

  /// No description provided for @hrvAcceptedAnotherCompany.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted another company\'s offer, so this application was closed automatically.'**
  String hrvAcceptedAnotherCompany(String name);

  /// No description provided for @hrvPickDayTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a day and a time first.'**
  String get hrvPickDayTime;

  /// No description provided for @hrvChangeNote.
  ///
  /// In en, this message translates to:
  /// **'{actor} {verb}. Reason: {reason}'**
  String hrvChangeNote(String actor, String verb, String reason);

  /// No description provided for @ivVerbAsked.
  ///
  /// In en, this message translates to:
  /// **'asked to move the interview'**
  String get ivVerbAsked;

  /// No description provided for @ivVerbDeclined.
  ///
  /// In en, this message translates to:
  /// **'declined moving the interview'**
  String get ivVerbDeclined;

  /// No description provided for @ivVerbMoved.
  ///
  /// In en, this message translates to:
  /// **'moved the interview'**
  String get ivVerbMoved;

  /// No description provided for @ivVerbAutoCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled the interview automatically'**
  String get ivVerbAutoCancelled;

  /// No description provided for @ivVerbCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled the interview'**
  String get ivVerbCancelled;

  /// No description provided for @ivVerbBooked.
  ///
  /// In en, this message translates to:
  /// **'booked the interview'**
  String get ivVerbBooked;

  /// No description provided for @acTabOne.
  ///
  /// In en, this message translates to:
  /// **'One student'**
  String get acTabOne;

  /// No description provided for @acTabMany.
  ///
  /// In en, this message translates to:
  /// **'Many (list / CSV)'**
  String get acTabMany;

  /// No description provided for @acHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Each student gets a random password that meets the password rules. You will see it once, on the next screen, to send to the student. At their first login they must choose a new password.'**
  String get acHowItWorks;

  /// No description provided for @acFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get acFullName;

  /// No description provided for @acFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'As on the student card'**
  String get acFullNameHint;

  /// No description provided for @acEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get acEmail;

  /// No description provided for @acRegNoOptional.
  ///
  /// In en, this message translates to:
  /// **'Registration number (optional)'**
  String get acRegNoOptional;

  /// No description provided for @acProgrammeOptional.
  ///
  /// In en, this message translates to:
  /// **'Programme (optional)'**
  String get acProgrammeOptional;

  /// No description provided for @acProgrammeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bachelor of Computer Science'**
  String get acProgrammeHint;

  /// No description provided for @acCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get acCreateAccount;

  /// No description provided for @acFileCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read.'**
  String get acFileCouldNotRead;

  /// No description provided for @acFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large for a student list (512 KB at most).'**
  String get acFileTooLarge;

  /// No description provided for @acOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One student per line:'**
  String get acOnePerLine;

  /// No description provided for @acLineFormat.
  ///
  /// In en, this message translates to:
  /// **'email, full name, registration number, programme (the last two are optional). A header row is fine.'**
  String get acLineFormat;

  /// No description provided for @acChooseCsv.
  ///
  /// In en, this message translates to:
  /// **'Choose a CSV file'**
  String get acChooseCsv;

  /// No description provided for @acFileName.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String acFileName(String name);

  /// No description provided for @acCreateAccounts.
  ///
  /// In en, this message translates to:
  /// **'Create accounts'**
  String get acCreateAccounts;

  /// No description provided for @acCreateN.
  ///
  /// In en, this message translates to:
  /// **'Create {count} accounts'**
  String acCreateN(int count);

  /// No description provided for @acRowsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Rows with a problem are skipped. Fix them and add them again.'**
  String get acRowsSkipped;

  /// No description provided for @acNoEmailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app could be opened. Copy the details and send them another way.'**
  String get acNoEmailApp;

  /// No description provided for @acLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this screen?'**
  String get acLeaveTitle;

  /// No description provided for @acLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The temporary passwords are shown only here and cannot be seen again. Make sure you have copied or sent them.'**
  String get acLeaveBody;

  /// No description provided for @acStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get acStay;

  /// No description provided for @acLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get acLeave;

  /// No description provided for @acNewAccounts.
  ///
  /// In en, this message translates to:
  /// **'New accounts'**
  String get acNewAccounts;

  /// No description provided for @acSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send each student their email and password now. The passwords are shown only on this screen. Students must choose a new password the first time they log in.'**
  String get acSendNow;

  /// No description provided for @acCopiedCsv.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} accounts as CSV.'**
  String acCopiedCsv(int count);

  /// No description provided for @acCopyAllCsv.
  ///
  /// In en, this message translates to:
  /// **'Copy all as CSV'**
  String get acCopyAllCsv;

  /// No description provided for @acLoginCopied.
  ///
  /// In en, this message translates to:
  /// **'Login details copied.'**
  String get acLoginCopied;

  /// No description provided for @acNotCreated.
  ///
  /// In en, this message translates to:
  /// **'Not created'**
  String get acNotCreated;

  /// No description provided for @acDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get acDone;

  /// No description provided for @acCopyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy details'**
  String get acCopyDetails;

  /// No description provided for @acEmailStudent.
  ///
  /// In en, this message translates to:
  /// **'Email student'**
  String get acEmailStudent;

  /// No description provided for @fpIntro.
  ///
  /// In en, this message translates to:
  /// **'You logged in with a temporary password from your administrator. Choose your own password now. You cannot use the app until you do.'**
  String get fpIntro;

  /// No description provided for @fpNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fpNewPassword;

  /// No description provided for @fpConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get fpConfirmPassword;

  /// No description provided for @fpSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get fpSaveContinue;

  /// No description provided for @fpLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get fpLogOut;

  /// No description provided for @ceNewCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code was sent to {email}.'**
  String ceNewCodeSent(String email);

  /// No description provided for @ceTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get ceTitle;

  /// No description provided for @ceIntro.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}. Type it below to confirm your account. It can take a minute and may land in your spam folder.'**
  String ceIntro(String email);

  /// No description provided for @ceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get ceCodeLabel;

  /// No description provided for @ceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get ceCodeHint;

  /// No description provided for @ceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm account'**
  String get ceConfirm;

  /// No description provided for @ceResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String ceResendIn(int seconds);

  /// No description provided for @ceResend.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get ceResend;

  /// No description provided for @ceBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get ceBackToLogin;

  /// No description provided for @fgCodeRequested.
  ///
  /// In en, this message translates to:
  /// **'A new code was requested.'**
  String get fgCodeRequested;

  /// No description provided for @fgCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the code.'**
  String get fgCheckEmail;

  /// No description provided for @fgTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get fgTitle;

  /// No description provided for @fgEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of your account. We will email you a code.'**
  String get fgEnterEmail;

  /// No description provided for @fgEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get fgEmailLabel;

  /// No description provided for @fgEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get fgEmailHint;

  /// No description provided for @fgSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get fgSendCode;

  /// No description provided for @fgSentIntro.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we have emailed a code. It can take a minute, and may land in your spam folder. The code expires after a short time.'**
  String fgSentIntro(String email);

  /// No description provided for @fgVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get fgVerifyCode;

  /// No description provided for @fgDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get fgDifferentEmail;

  /// No description provided for @fgCodeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Code accepted. Choose a new password.'**
  String get fgCodeAccepted;

  /// No description provided for @fgNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get fgNewPasswordHint;

  /// No description provided for @fgConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get fgConfirmHint;

  /// No description provided for @fgSaveNew.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get fgSaveNew;

  /// No description provided for @suPrivacyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please read and accept the privacy notice to continue.'**
  String get suPrivacyRequired;

  /// No description provided for @suPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Account created. An administrator must approve it before you can log in.'**
  String get suPendingApproval;

  /// No description provided for @suCreatedLoginConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your account is created. Log in to confirm your email with a new code.'**
  String get suCreatedLoginConfirm;

  /// No description provided for @suEmailConfirmedPending.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed. An administrator must approve your account before you can log in.'**
  String get suEmailConfirmedPending;

  /// No description provided for @suExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account already exists'**
  String get suExistsTitle;

  /// No description provided for @suExistsBody.
  ///
  /// In en, this message translates to:
  /// **'An account has already been created with {email}. Log in with it, or reset the password if you have forgotten it. No new email is sent for an existing account.'**
  String suExistsBody(String email);

  /// No description provided for @suForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get suForgotPassword;

  /// No description provided for @suStudentsCreatedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Student accounts are created by your administrator. Log in with the email and password you were given.'**
  String get suStudentsCreatedByAdmin;

  /// No description provided for @suFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get suFullNameHint;

  /// No description provided for @suAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the '**
  String get suAgreePrefix;

  /// No description provided for @suPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'privacy notice'**
  String get suPrivacyNotice;

  /// No description provided for @loPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Log in with your new password.'**
  String get loPasswordChanged;

  /// No description provided for @stMyInterviewTimes.
  ///
  /// In en, this message translates to:
  /// **'My interview days and times'**
  String get stMyInterviewTimes;

  /// No description provided for @stPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get stPrivacyNotice;

  /// No description provided for @stDeleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get stDeleteMyAccount;

  /// No description provided for @errUnsupportedImage.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format. Please upload a JPG, JPEG, or PNG image.'**
  String get errUnsupportedImage;

  /// No description provided for @errPhotoEmpty.
  ///
  /// In en, this message translates to:
  /// **'The selected photo is empty (0 bytes). Try a different photo.'**
  String get errPhotoEmpty;

  /// No description provided for @errPhotoNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected photo could not be found on disk.'**
  String get errPhotoNotFound;

  /// No description provided for @errUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String errUploadFailed(String error);

  /// No description provided for @errCouldNotAccessCamera.
  ///
  /// In en, this message translates to:
  /// **'Could not access camera: {error}'**
  String errCouldNotAccessCamera(String error);

  /// No description provided for @errCouldNotAccessGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not access gallery: {error}'**
  String errCouldNotAccessGallery(String error);

  /// No description provided for @errCouldNotRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo: {error}'**
  String errCouldNotRemovePhoto(String error);

  /// No description provided for @errCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String errCouldNotSave(String error);

  /// No description provided for @errCouldNotSaveLanguage.
  ///
  /// In en, this message translates to:
  /// **'Could not save language: {error}'**
  String errCouldNotSaveLanguage(String error);

  /// No description provided for @errCouldNotSaveTheme.
  ///
  /// In en, this message translates to:
  /// **'Could not save theme: {error}'**
  String errCouldNotSaveTheme(String error);

  /// No description provided for @hpDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'The deadline of this posting has passed. Edit the posting and choose a later deadline to reopen it.'**
  String get hpDeadlinePassed;

  /// No description provided for @hpExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get hpExpired;

  /// No description provided for @hpRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended candidates'**
  String get hpRecommended;

  /// No description provided for @hpChooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose the internship location on the map.'**
  String get hpChooseLocation;

  /// No description provided for @hpAddOneSkill.
  ///
  /// In en, this message translates to:
  /// **'Add at least one required skill.'**
  String get hpAddOneSkill;

  /// No description provided for @hpCloseBeforeDeadline.
  ///
  /// In en, this message translates to:
  /// **'The posting cannot close before its application deadline.'**
  String get hpCloseBeforeDeadline;

  /// No description provided for @hpFixFields.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields before publishing.'**
  String get hpFixFields;

  /// No description provided for @hpCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save posting: {error}'**
  String hpCouldNotSave(String error);

  /// No description provided for @hpCouldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete posting: {error}'**
  String hpCouldNotDelete(String error);

  /// No description provided for @hpCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get hpCustom;

  /// No description provided for @hpCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get hpCustomCategory;

  /// No description provided for @hpCustomCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Marketing'**
  String get hpCustomCategoryHint;

  /// No description provided for @hpAllowancePositive.
  ///
  /// In en, this message translates to:
  /// **'Allowance must be more than 0.'**
  String get hpAllowancePositive;

  /// No description provided for @hpAutoCloseCaption.
  ///
  /// In en, this message translates to:
  /// **'Posting closes automatically after (optional)'**
  String get hpAutoCloseCaption;

  /// No description provided for @hpClosesOn.
  ///
  /// In en, this message translates to:
  /// **'Posting closes on {date}'**
  String hpClosesOn(String date);

  /// No description provided for @hpAutoCloseOptional.
  ///
  /// In en, this message translates to:
  /// **'Auto-close date (optional)'**
  String get hpAutoCloseOptional;

  /// No description provided for @acTitleStudents.
  ///
  /// In en, this message translates to:
  /// **'Create student accounts'**
  String get acTitleStudents;

  /// No description provided for @acTitleSupervisors.
  ///
  /// In en, this message translates to:
  /// **'Create supervisor accounts'**
  String get acTitleSupervisors;

  /// No description provided for @acHowItWorksSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Each supervisor gets a random password that meets the password rules, and the account is approved straight away. You will see the password once, on the next screen, to send to them. At their first login they must choose a new password.'**
  String get acHowItWorksSupervisor;

  /// No description provided for @acLineFormatSupervisor.
  ///
  /// In en, this message translates to:
  /// **'email, full name. A header row is fine.'**
  String get acLineFormatSupervisor;

  /// No description provided for @acSendNowSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Send each supervisor their email and password now. The passwords are shown only on this screen. They must choose a new password the first time they log in.'**
  String get acSendNowSupervisor;

  /// No description provided for @adminAddSupervisors.
  ///
  /// In en, this message translates to:
  /// **'Add supervisors'**
  String get adminAddSupervisors;

  /// No description provided for @adminAddStudents.
  ///
  /// In en, this message translates to:
  /// **'Add students'**
  String get adminAddStudents;

  /// No description provided for @stSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stSummaryTitle;

  /// No description provided for @stViewFull.
  ///
  /// In en, this message translates to:
  /// **'View full statistics'**
  String get stViewFull;

  /// No description provided for @stNoCompany.
  ///
  /// In en, this message translates to:
  /// **'Join or register a company to see statistics here.'**
  String get stNoCompany;

  /// No description provided for @stNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet.'**
  String get stNothingYet;

  /// No description provided for @stCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the statistics: {error}'**
  String stCouldNotLoad(String error);

  /// No description provided for @stTitleHr.
  ///
  /// In en, this message translates to:
  /// **'Hiring statistics'**
  String get stTitleHr;

  /// No description provided for @stTitleAcademic.
  ///
  /// In en, this message translates to:
  /// **'Student progress'**
  String get stTitleAcademic;

  /// No description provided for @stTitleCompanySup.
  ///
  /// In en, this message translates to:
  /// **'Intern progress'**
  String get stTitleCompanySup;

  /// No description provided for @stTitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Platform statistics'**
  String get stTitleAdmin;

  /// No description provided for @stPostings.
  ///
  /// In en, this message translates to:
  /// **'Postings'**
  String get stPostings;

  /// No description provided for @stOpenPostings.
  ///
  /// In en, this message translates to:
  /// **'Open postings'**
  String get stOpenPostings;

  /// No description provided for @stApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get stApplications;

  /// No description provided for @stApplicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get stApplicants;

  /// No description provided for @stInterviewing.
  ///
  /// In en, this message translates to:
  /// **'In interview'**
  String get stInterviewing;

  /// No description provided for @stOffered.
  ///
  /// In en, this message translates to:
  /// **'Offered'**
  String get stOffered;

  /// No description provided for @stAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get stAccepted;

  /// No description provided for @stRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get stRejected;

  /// No description provided for @stPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get stPending;

  /// No description provided for @stClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get stClosed;

  /// No description provided for @stAcceptRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance rate'**
  String get stAcceptRate;

  /// No description provided for @stInterviewsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming interviews'**
  String get stInterviewsUpcoming;

  /// No description provided for @stInterviewsDone.
  ///
  /// In en, this message translates to:
  /// **'Interviews done'**
  String get stInterviewsDone;

  /// No description provided for @stByStatus.
  ///
  /// In en, this message translates to:
  /// **'Applications by status'**
  String get stByStatus;

  /// No description provided for @stPerPosting.
  ///
  /// In en, this message translates to:
  /// **'Per posting'**
  String get stPerPosting;

  /// No description provided for @stPostingRow.
  ///
  /// In en, this message translates to:
  /// **'{applications} applications · {interview} interview · {offered} offered · {accepted} accepted'**
  String stPostingRow(
    int applications,
    int interview,
    int offered,
    int accepted,
  );

  /// No description provided for @stWeekly.
  ///
  /// In en, this message translates to:
  /// **'Applications per week (last 8 weeks)'**
  String get stWeekly;

  /// No description provided for @stStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get stStudents;

  /// No description provided for @stPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get stPlaced;

  /// No description provided for @stNotPlaced.
  ///
  /// In en, this message translates to:
  /// **'Not placed yet'**
  String get stNotPlaced;

  /// No description provided for @stReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get stReports;

  /// No description provided for @stReportsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your review'**
  String get stReportsWaiting;

  /// No description provided for @stReportsApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get stReportsApproved;

  /// No description provided for @stReportsSentBack.
  ///
  /// In en, this message translates to:
  /// **'Sent back'**
  String get stReportsSentBack;

  /// No description provided for @stDocsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Documents to review'**
  String get stDocsWaiting;

  /// No description provided for @stDocsApproved.
  ///
  /// In en, this message translates to:
  /// **'Documents approved'**
  String get stDocsApproved;

  /// No description provided for @stEvaluationsDone.
  ///
  /// In en, this message translates to:
  /// **'Evaluations done'**
  String get stEvaluationsDone;

  /// No description provided for @stReportProgress.
  ///
  /// In en, this message translates to:
  /// **'Report progress'**
  String get stReportProgress;

  /// No description provided for @stPerStudent.
  ///
  /// In en, this message translates to:
  /// **'Per student'**
  String get stPerStudent;

  /// No description provided for @stStudentRow.
  ///
  /// In en, this message translates to:
  /// **'{reports} reports · {approved} approved · {pending} waiting'**
  String stStudentRow(int reports, int approved, int pending);

  /// No description provided for @stPlacedBadge.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get stPlacedBadge;

  /// No description provided for @stNotPlacedBadge.
  ///
  /// In en, this message translates to:
  /// **'Not placed'**
  String get stNotPlacedBadge;

  /// No description provided for @stInterns.
  ///
  /// In en, this message translates to:
  /// **'Interns'**
  String get stInterns;

  /// No description provided for @stEvaluatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Evaluated'**
  String get stEvaluatedBadge;

  /// No description provided for @stNotEvaluatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Not evaluated'**
  String get stNotEvaluatedBadge;

  /// No description provided for @stEvaluatedStudents.
  ///
  /// In en, this message translates to:
  /// **'Interns evaluated'**
  String get stEvaluatedStudents;

  /// No description provided for @stPeople.
  ///
  /// In en, this message translates to:
  /// **'People on the platform'**
  String get stPeople;

  /// No description provided for @stCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get stCompanies;

  /// No description provided for @stCompaniesVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get stCompaniesVerified;

  /// No description provided for @stCompaniesPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification'**
  String get stCompaniesPending;

  /// No description provided for @stNewCompanies.
  ///
  /// In en, this message translates to:
  /// **'New companies (30 days)'**
  String get stNewCompanies;

  /// No description provided for @stCompaniesWithPostings.
  ///
  /// In en, this message translates to:
  /// **'Companies with postings'**
  String get stCompaniesWithPostings;

  /// No description provided for @stNewPeople.
  ///
  /// In en, this message translates to:
  /// **'New people (30 days)'**
  String get stNewPeople;

  /// No description provided for @stPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get stPendingApprovals;

  /// No description provided for @stUsersByRole.
  ///
  /// In en, this message translates to:
  /// **'People by role'**
  String get stUsersByRole;

  /// No description provided for @stCompaniesByStatus.
  ///
  /// In en, this message translates to:
  /// **'Companies by status'**
  String get stCompaniesByStatus;

  /// No description provided for @stCompaniesJoined.
  ///
  /// In en, this message translates to:
  /// **'Companies joined per month (last 6)'**
  String get stCompaniesJoined;

  /// No description provided for @stPeopleJoined.
  ///
  /// In en, this message translates to:
  /// **'People joined per month (last 6)'**
  String get stPeopleJoined;

  /// No description provided for @stRoleStudent.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get stRoleStudent;

  /// No description provided for @stRoleAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic supervisors'**
  String get stRoleAcademic;

  /// No description provided for @stRoleHr.
  ///
  /// In en, this message translates to:
  /// **'Company HR'**
  String get stRoleHr;

  /// No description provided for @stRoleCompanySup.
  ///
  /// In en, this message translates to:
  /// **'Company supervisors'**
  String get stRoleCompanySup;

  /// No description provided for @stRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrators'**
  String get stRoleAdmin;

  /// No description provided for @roleLabelStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleLabelStudent;

  /// No description provided for @roleLabelAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic supervisor'**
  String get roleLabelAcademic;

  /// No description provided for @roleLabelHr.
  ///
  /// In en, this message translates to:
  /// **'Company HR'**
  String get roleLabelHr;

  /// No description provided for @roleLabelCompanySup.
  ///
  /// In en, this message translates to:
  /// **'Company supervisor'**
  String get roleLabelCompanySup;

  /// No description provided for @roleLabelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleLabelAdmin;

  /// No description provided for @acTabOneSupervisor.
  ///
  /// In en, this message translates to:
  /// **'One supervisor'**
  String get acTabOneSupervisor;

  /// No description provided for @acTabManySupervisor.
  ///
  /// In en, this message translates to:
  /// **'Many (list / CSV)'**
  String get acTabManySupervisor;

  /// No description provided for @acFullNameHintSupervisor.
  ///
  /// In en, this message translates to:
  /// **'As on the employee card'**
  String get acFullNameHintSupervisor;

  /// No description provided for @acEmailSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Email supervisor'**
  String get acEmailSupervisor;

  /// No description provided for @acCreateFailedReason.
  ///
  /// In en, this message translates to:
  /// **'The account could not be created: {reason}'**
  String acCreateFailedReason(String reason);

  /// No description provided for @adminNeverLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in yet'**
  String get adminNeverLoggedIn;

  /// No description provided for @adminAwaitingApprovalBadge.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get adminAwaitingApprovalBadge;

  /// No description provided for @adminNotApprovedBadge.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get adminNotApprovedBadge;

  /// No description provided for @adminFilterVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminFilterVerified;

  /// No description provided for @adminFilterNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get adminFilterNotVerified;

  /// No description provided for @adminNoCompaniesInFilter.
  ///
  /// In en, this message translates to:
  /// **'No companies in this group'**
  String get adminNoCompaniesInFilter;

  /// No description provided for @hpClosesAfterDeadline.
  ///
  /// In en, this message translates to:
  /// **'The posting closes automatically after the application deadline. Without a deadline it stays open until you close it.'**
  String get hpClosesAfterDeadline;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}!'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}!'**
  String goodEvening(String name);
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
