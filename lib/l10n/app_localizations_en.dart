// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CIMS';

  @override
  String get tarumt => 'TARUMT';

  @override
  String get splashTagline => 'Centralised Internship\nManagement System';

  @override
  String get loading => 'Loading...';

  @override
  String get welcomeToCims => 'Welcome to CIMS';

  @override
  String get cimsFullName => 'Centralised Internship Management System';

  @override
  String get emailAddress => 'Email address';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get logIn => 'Log in';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get footerCopyright => '© 2026 TARUMT · CIMS v1.0';

  @override
  String get errorEnterEmail => 'Please enter your email.';

  @override
  String get errorEnterPassword => 'Please enter your password.';

  @override
  String get errorIncorrectCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get errorConfirmEmail =>
      'Please confirm your email before logging in.';

  @override
  String get errorSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get resetYourPassword => 'Reset your password';

  @override
  String get resetPasswordInstructions =>
      'Enter your account email and we\'ll send you a link to reset your password.';

  @override
  String get cancel => 'Cancel';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetLinkSentMessage =>
      'If an account exists for this email, a reset link has been sent.';

  @override
  String get createYourAccount => 'Create your CIMS account';

  @override
  String get signupRoleNote =>
      'Student/staff emails are assigned a role automatically.\nGmail, Outlook, or Hotmail addresses will be asked to pick a role below.';

  @override
  String get createAPassword => 'Create a password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get reEnterYourPassword => 'Re-enter your password';

  @override
  String get selectYourRole => 'Select your role';

  @override
  String get notInstitutionalEmailNote =>
      'Your email is not a TARC institutional address. Please select the role that applies to you.';

  @override
  String get parentGuardian => 'Parent/Guardian';

  @override
  String get hrPersonnel => 'HR Personnel';

  @override
  String get companySupervisor => 'Company Supervisor';

  @override
  String get signUp => 'Sign up';

  @override
  String get alreadyHaveAccountLogIn => 'Already have an account? Log in';

  @override
  String get errorFillAllFields => 'Please fill in all fields.';

  @override
  String get errorPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get errorSelectRole => 'Please select your role to continue.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get overview => 'Overview';

  @override
  String get internshipProgress => 'Internship progress';

  @override
  String get upcomingDeadlines => 'Upcoming deadlines';

  @override
  String get viewAll => 'View all';

  @override
  String get recentFeedback => 'Recent feedback';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get overallProgress => 'Overall progress';

  @override
  String get urgent => 'Urgent';

  @override
  String get stepApplied => 'Applied';

  @override
  String get stepAccepted => 'Accepted';

  @override
  String get stepOngoing => 'Ongoing';

  @override
  String get stepCompleted => 'Completed';

  @override
  String get submitCompanyReview => 'Submit company review';

  @override
  String get viewMyProgress => 'View my progress';

  @override
  String goodMorning(String name) {
    return 'Good morning, $name!';
  }

  @override
  String get personalInformation => 'Personal information';

  @override
  String get academicInformation => 'Academic information';

  @override
  String get resume => 'Resume';

  @override
  String get account => 'Account';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get address => 'Address';

  @override
  String get notSet => 'Not set';

  @override
  String get programme => 'Programme';

  @override
  String get studentRegNo => 'Student Reg. No.';

  @override
  String get studentRegNoHint => 'e.g. 24WMR12345';

  @override
  String get semester => 'Semester';

  @override
  String get faculty => 'Faculty';

  @override
  String get cgpa => 'CGPA';

  @override
  String get academicSupervisor => 'Academic Supervisor';

  @override
  String get assignedBySystem => 'Assigned by system';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get changePassword => 'Change password';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirmTitle => 'Log out?';

  @override
  String get logOutConfirmMessage =>
      'You will need to log in again to access your account.';

  @override
  String get noResumeUploaded => 'No resume uploaded yet';

  @override
  String get resumeFormatNote => 'PDF or DOCX only, max 5MB.';

  @override
  String get uploadResume => 'Upload resume';

  @override
  String get uploading => 'Uploading...';

  @override
  String get view => 'View';

  @override
  String get replace => 'Replace';

  @override
  String get remove => 'Remove';

  @override
  String get scanResumeToAutofill => 'Scan resume to autofill profile';

  @override
  String get tapToSelectDateOfBirth => 'Tap to select date of birth';

  @override
  String get tapToSelectAddress => 'Tap to select your address on the map';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get change => 'Change';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get hrRecruitmentOverview => 'Recruitment overview';

  @override
  String get hrActivePostings => 'Active postings';

  @override
  String get hrNewApplicants => 'New applicants';

  @override
  String get hrInterviewsPending => 'Interviews pending';

  @override
  String get hrCurrentInterns => 'Current interns';

  @override
  String get hrUpcomingInterviews => 'Upcoming interviews';

  @override
  String get hrNoInterviewsScheduled => 'No interviews scheduled.';

  @override
  String get hrNewPosting => 'New posting';

  @override
  String get hrReviewApplicants => 'Review applicants';

  @override
  String get hrPersonnelLabel => 'HR Personnel';

  @override
  String get hrJobPostings => 'Job postings';

  @override
  String hrPostingsCount(int count) {
    return '$count postings';
  }

  @override
  String hrActiveCount(int count) {
    return '$count active';
  }

  @override
  String get hrNoPostingsYet => 'No postings yet';

  @override
  String get hrCreateFirstPosting => 'Create your first internship posting.';

  @override
  String get hrClosePosting => 'Close posting';

  @override
  String get hrReopenPosting => 'Reopen posting';

  @override
  String get hrDeletePostingTitle => 'Delete posting?';

  @override
  String get hrDeletePostingMessage =>
      'This will permanently remove this job posting. Existing applications will be retained for records.';

  @override
  String hrApplicantsCount(int count) {
    return '$count applicants';
  }

  @override
  String hrPostedAgo(String time) {
    return 'Posted $time';
  }

  @override
  String get hrEditPosting => 'Edit posting';

  @override
  String get hrPostingDetails => 'Posting details';

  @override
  String get hrJobTitle => 'Job title';

  @override
  String get hrJobTitleHint => 'e.g. Software Engineering Intern';

  @override
  String get hrJobDescription => 'Job description';

  @override
  String get hrJobDescriptionHint => 'Describe the role and responsibilities';

  @override
  String get hrCategory => 'Category';

  @override
  String get hrLogistics => 'Logistics';

  @override
  String get hrLocationHint => 'Location — tap to select on map';

  @override
  String get hrJobType => 'Job type';

  @override
  String get hrDuration => 'Duration';

  @override
  String hrMonths(int count) {
    return '$count months';
  }

  @override
  String get hrMonthlyAllowance => 'Monthly allowance (RM)';

  @override
  String get hrMonthlyAllowanceHint => 'e.g. 1500';

  @override
  String hrDeadlineLabel(String date) {
    return 'Deadline: $date';
  }

  @override
  String get hrApplicationDeadlineOptional => 'Application deadline (optional)';

  @override
  String get hrSkillsRequired => 'Skills required';

  @override
  String get hrAddASkill => 'Add a skill';

  @override
  String get hrSaveChanges => 'Save changes';

  @override
  String get hrPublishPosting => 'Publish posting';

  @override
  String get hrTitleLocationRequired => 'Job title and location are required.';

  @override
  String get hrDescriptionRequired => 'Please add a job description.';

  @override
  String get hrValidAllowanceRequired => 'Enter a valid monthly allowance.';

  @override
  String get hrSkillRequired => 'Add at least one required skill.';

  @override
  String get hrApplicants => 'Applicants';

  @override
  String hrTabNew(int count) {
    return 'New ($count)';
  }

  @override
  String hrTabInterview(int count) {
    return 'Interview ($count)';
  }

  @override
  String hrTabAccepted(int count) {
    return 'Accepted ($count)';
  }

  @override
  String hrTabRejected(int count) {
    return 'Rejected ($count)';
  }

  @override
  String get hrNoApplicantsHere => 'No applicants here';

  @override
  String get hrApplicantsAppearHere =>
      'Applicants in this stage will appear here.';

  @override
  String hrInterviewColon(String time) {
    return 'Interview: $time';
  }

  @override
  String hrAppliedAgo(String time) {
    return 'Applied $time';
  }

  @override
  String get hrApplicantProfile => 'Applicant profile';

  @override
  String get hrAppliedFor => 'Applied for';

  @override
  String get hrNoResumeUploaded => 'No resume uploaded';

  @override
  String get hrCoverLetter => 'Cover letter';

  @override
  String get hrNoCoverLetterProvided => 'No cover letter provided.';

  @override
  String get hrSkills => 'Skills';

  @override
  String get hrReject => 'Reject';

  @override
  String get hrScheduleInterview => 'Schedule Interview';

  @override
  String hrInterviewScheduledColon(String time) {
    return 'Interview scheduled: $time';
  }

  @override
  String get hrAccept => 'Accept';

  @override
  String get hrDate => 'Date';

  @override
  String get hrSelectDate => 'Select date';

  @override
  String get hrTime => 'Time';

  @override
  String get hrSelectTime => 'Select time';

  @override
  String get hrInterviewMode => 'Interview mode';

  @override
  String get hrOnline => 'Online';

  @override
  String get hrInPerson => 'In-person';

  @override
  String get hrMeetingLink => 'Meeting link';

  @override
  String get hrLocation => 'Location';

  @override
  String get hrMeetingLinkHint => 'e.g. Zoom/Google Meet link';

  @override
  String get hrLocationTapToSelect => 'Tap to select on map';

  @override
  String get hrOfficeAddressHint => 'Office address';

  @override
  String get hrMeetingLinkRequired => 'Meeting link is required.';

  @override
  String get hrLocationRequired => 'Location is required.';

  @override
  String get hrConfirmNotifyApplicant => 'Confirm & notify applicant';

  @override
  String get hrPostings => 'Postings';

  @override
  String get hrInterns => 'Interns';

  @override
  String get hrClosedStatus => 'Closed';

  @override
  String get supAssignedStudents => 'Assigned students';

  @override
  String get supPendingReviews => 'Pending reviews';

  @override
  String get supApprovedThisMonth => 'Approved this month';

  @override
  String get supUnreadMessages => 'Unread messages';

  @override
  String get supPendingYourReview => 'Pending your review';

  @override
  String get supNothingPendingReview => 'Nothing pending review right now.';

  @override
  String get supMyStudents => 'My students';

  @override
  String get supNoStudentsYet => 'No students yet.';

  @override
  String get supUpToDate => 'Up to date';

  @override
  String supPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get supMyStudentsTitle => 'My students';

  @override
  String get supSearchByNameOrProgramme => 'Search by name or programme...';

  @override
  String supStudentsCount(int count) {
    return '$count students';
  }

  @override
  String get supNoStudents => 'No students';

  @override
  String get supNoStudentsMatch => 'No students match your search.';

  @override
  String get supActiveInternship => 'Active internship';

  @override
  String get supNoActiveInternship => 'No active internship';

  @override
  String supLastReportAgo(String time) {
    return 'Last report $time';
  }

  @override
  String get supNoReportsYet => 'No reports yet';

  @override
  String get supStudentDetails => 'Student details';

  @override
  String get supEvaluate => 'Evaluate';

  @override
  String get supMessage => 'Message';

  @override
  String get supLatestEvaluation => 'Latest evaluation';

  @override
  String supSubmittedAgo(String time) {
    return 'Submitted $time';
  }

  @override
  String get supSubmissionHistory => 'Submission history';

  @override
  String get supNoSubmissionsYet => 'No submissions yet.';

  @override
  String get supReviews => 'Reviews';

  @override
  String get supTabPending => 'Pending';

  @override
  String get supTabApproved => 'Approved';

  @override
  String get supTabRejected => 'Rejected';

  @override
  String get supNothingHere => 'Nothing here';

  @override
  String get supItemsAppearHere => 'Items in this category will appear here.';

  @override
  String get supNoFileAttached => 'No file attached to this submission.';

  @override
  String get supAwaitingCompanyReview =>
      'Awaiting company supervisor review before you can approve.';

  @override
  String get supRejectedByCompany =>
      'Rejected by the company supervisor — waiting on the student to resubmit.';

  @override
  String get supRejectSubmission => 'Reject submission';

  @override
  String get supApproveSubmission => 'Approve submission';

  @override
  String get supRejectFeedbackPrompt =>
      'Please provide feedback explaining why this is being rejected.';

  @override
  String get supApproveCommentPrompt =>
      'Add an optional comment for the student.';

  @override
  String get supTypeYourComment => 'Type your comment...';

  @override
  String get supPleaseAddFeedback => 'Please add feedback before rejecting.';

  @override
  String get supApprove => 'Approve';

  @override
  String get supEvaluateStudent => 'Evaluate student';

  @override
  String get supRatingInstruction =>
      'Rate each criterion from 1 (poor) to 5 (excellent) based on internship performance.';

  @override
  String get supOverallAverageScore => 'Overall average score';

  @override
  String get supAdditionalComments => 'Additional comments';

  @override
  String get supQualitativeFeedbackHint =>
      'Provide qualitative feedback on the student\'s overall performance...';

  @override
  String get supSubmitEvaluation => 'Submit evaluation';

  @override
  String get supEvaluationSubmitted => 'Evaluation submitted';

  @override
  String supEvaluationRecorded(String name) {
    return 'Your evaluation for $name has been recorded.';
  }

  @override
  String get supBackToStudent => 'Back to student';

  @override
  String get supStudents => 'Students';

  @override
  String get csCurrentInterns => 'Current interns';

  @override
  String get csReportsToReview => 'Reports to review';

  @override
  String get csApprovedThisMonth => 'Approved this month';

  @override
  String get csEvaluations => 'Evaluations';

  @override
  String get csPendingYourReview => 'Pending your review';

  @override
  String get csNothingPendingReview => 'Nothing pending review.';

  @override
  String get csInternProgress => 'Intern progress';

  @override
  String get csNoInternsYet => 'No interns yet.';

  @override
  String get csInterns => 'Interns';

  @override
  String csCurrentInternsCount(int count) {
    return '$count current interns';
  }

  @override
  String csNeedsAttention(int count) {
    return '$count needs attention';
  }

  @override
  String get csNoInternsTitle => 'No interns yet';

  @override
  String get csNoInternsDescription =>
      'Accepted applicants at your company will appear here.';

  @override
  String get csInternDetails => 'Intern details';

  @override
  String get csReportSubmissions => 'Report submissions';

  @override
  String get csNoReportsSubmittedYet => 'No reports submitted yet.';

  @override
  String get csEvaluateIntern => 'Evaluate intern';

  @override
  String get csRatingInstruction =>
      'Rate each criterion from 1 (poor) to 5 (excellent) based on workplace performance.';

  @override
  String get csAdditionalComments => 'Additional comments';

  @override
  String get csPerformanceCommentHint =>
      'Describe the intern\'s overall performance, attitude, and growth during the internship period...';

  @override
  String get csSubmitEvaluation => 'Submit evaluation';

  @override
  String get csEvaluationSubmitted => 'Evaluation submitted';

  @override
  String csEvaluationRecorded(String name) {
    return 'Your workplace evaluation for $name has been recorded and shared with the university.';
  }

  @override
  String get csBackToIntern => 'Back to intern';

  @override
  String get csReportReviews => 'Report reviews';

  @override
  String get csTabPending => 'Pending';

  @override
  String get csTabApproved => 'Approved';

  @override
  String get csTabRejected => 'Rejected';

  @override
  String get csNothingHere => 'Nothing here';

  @override
  String get csReportsAppearHere =>
      'Reports in this category will appear here.';

  @override
  String get csRejectReport => 'Reject report';

  @override
  String get csApproveReport => 'Approve report';

  @override
  String get csRejectReasonPrompt =>
      'Provide feedback explaining the rejection reason.';

  @override
  String get csApproveCommentPrompt =>
      'Add an optional comment for the intern.';

  @override
  String get csPleaseAddFeedback => 'Please add feedback before rejecting.';

  @override
  String get csGradeExcellent => 'Excellent';

  @override
  String get csGradeGood => 'Good';

  @override
  String get csGradeSatisfactory => 'Satisfactory';

  @override
  String get csGradeNeedsImprovement => 'Needs improvement';

  @override
  String get csAverageScore => 'Average score';

  @override
  String get setupYourCompany => 'Set up your company';

  @override
  String get setupLinkCompanyNote =>
      'Link your account to a company before you can manage postings, applicants, or interns.';

  @override
  String get setupJoinExisting => 'Join existing';

  @override
  String get setupRegisterNew => 'Register new';

  @override
  String get setupNoCompaniesYet => 'No companies yet';

  @override
  String get setupSwitchToRegister =>
      'Switch to \"Register new\" to add your company.';

  @override
  String get setupIndustryNotSet => 'Industry not set';

  @override
  String get setupJoinCompany => 'Join company';

  @override
  String get setupCompanyName => 'Company name';

  @override
  String get setupIndustryOptional => 'Industry (optional)';

  @override
  String get setupLocationOptional =>
      'Location (optional) — tap to select on map';

  @override
  String get setupRegisterCompany => 'Register company';

  @override
  String get setupCompanyNameRequired => 'Company name is required.';

  @override
  String get profileMyProfile => 'My profile';

  @override
  String get profilePersonalInformation => 'Personal information';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileAddress => 'Address';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profilePhoneHint => 'e.g. 012-345 6789';

  @override
  String get profileTapToSelectOnMap => 'Tap to select on map';

  @override
  String get profileEmailCannotChange =>
      'Email is your login and cannot be changed here.';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileNotificationPreferencesTitle => 'Notification preferences';

  @override
  String get profileChooseWhatToBeNotified =>
      'Choose what you want to be notified about.';

  @override
  String get profileApplicationApplicantUpdates =>
      'Application & applicant updates';

  @override
  String get profileReportDocumentReviews => 'Report & document reviews';

  @override
  String get profileMessages => 'Messages';

  @override
  String get profileEvaluationReminders => 'Evaluation reminders';

  @override
  String get profileNotificationPrefsUpdated =>
      'Notification preferences updated.';

  @override
  String get profileSelectLanguage => 'Select language';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profileUpdatePhoto => 'Update profile photo';

  @override
  String get profileTakePhoto => 'Take a photo';

  @override
  String get profileChooseFromGallery => 'Choose from gallery';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profilePasswordChanged => 'Password changed successfully.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get chatConversationFallbackName => 'this conversation';

  @override
  String get chatDeleteConversationTitle => 'Delete conversation?';

  @override
  String chatDeleteConversationMessage(String name) {
    return 'This deletes the whole conversation with $name for both of you. This cannot be undone.';
  }

  @override
  String chatCouldNotLoadContacts(String error) {
    return 'Could not load contacts: $error';
  }

  @override
  String get chatNewMessageTitle => 'New message';

  @override
  String get chatNoContactsToMessage => 'No other accounts to message yet.';

  @override
  String get chatTabTitle => 'Messages';

  @override
  String get chatArchivedChatsTitle => 'Archived chats';

  @override
  String get chatNoConversationsYetTitle => 'No conversations yet';

  @override
  String get chatTapPencilToMessage =>
      'Tap the pencil icon to message someone.';

  @override
  String get chatNoArchivedChatsTitle => 'No archived chats';

  @override
  String get chatArchivedConversationsDescription =>
      'Conversations you archive show up here.';

  @override
  String get chatUnknownUser => 'Unknown user';

  @override
  String get chatUnarchiveAction => 'Unarchive';

  @override
  String get chatRoleStudent => 'Student';

  @override
  String get chatPhotoAttachmentPreview => '📷 Photo';

  @override
  String get chatArchiveAction => 'Archive';

  @override
  String chatCouldNotSendMessage(String error) {
    return 'Could not send message: $error';
  }

  @override
  String get chatFileTooLarge => 'File is too large. Maximum size is 10MB.';

  @override
  String chatCouldNotSendAttachment(String error) {
    return 'Could not send attachment: $error';
  }

  @override
  String get chatDeleteForMeAction => 'Delete for me';

  @override
  String get chatDeleteForEveryoneAction => 'Delete for everyone';

  @override
  String get chatDeleteForMeTitle => 'Delete for me?';

  @override
  String get chatDeleteForMeMessage =>
      'This message will be removed from your view only. The other person will still see it.';

  @override
  String chatCouldNotDeleteMessage(String error) {
    return 'Could not delete message: $error';
  }

  @override
  String get chatEditMessageTitle => 'Edit message';

  @override
  String chatCouldNotEditMessage(String error) {
    return 'Could not edit message: $error';
  }

  @override
  String get chatDeleteMessageTitle => 'Delete message?';

  @override
  String get chatCannotBeUndone => 'This cannot be undone.';

  @override
  String get chatSayHello => 'Say hello 👋';

  @override
  String get chatTypeMessageHint => 'Type a message...';

  @override
  String get chatEditedLabel => 'edited';

  @override
  String get chatAttachmentFallbackName => 'Attachment';

  @override
  String chatCouldNotUpdateMute(String error) {
    return 'Could not update mute: $error';
  }

  @override
  String get chatBlockContactTitle => 'Block this contact?';

  @override
  String get chatUnblockContactTitle => 'Unblock this contact?';

  @override
  String get chatBlockContactMessage =>
      'They will no longer be able to send you messages in this conversation.';

  @override
  String get chatUnblockContactMessage =>
      'They will be able to send you messages again.';

  @override
  String get chatBlockAction => 'Block';

  @override
  String get chatUnblockAction => 'Unblock';

  @override
  String chatCouldNotUpdateBlock(String error) {
    return 'Could not update block: $error';
  }

  @override
  String chatCouldNotDeleteConversation(String error) {
    return 'Could not delete conversation: $error';
  }

  @override
  String get chatContactInfoTitle => 'Contact info';

  @override
  String get chatPhoneNotAvailable => 'Not available';

  @override
  String get chatSharedMediaFiles => 'Shared media & files';

  @override
  String get chatNoSharedMediaYet => 'No shared media yet.';

  @override
  String get chatMuteNotifications => 'Mute notifications';

  @override
  String get chatBlockContactToggle => 'Block contact';

  @override
  String get chatDeleteConversationButton => 'Delete conversation';

  @override
  String errorAddressSearchFailed(String error) {
    return 'Address search failed: $error';
  }

  @override
  String unknownLocationCoords(String lat, String lng) {
    return 'Unknown location ($lat, $lng)';
  }

  @override
  String get errorCouldNotResolveAddress =>
      'Could not resolve address for this location.';

  @override
  String get selectYourAddress => 'Select your address';

  @override
  String get searchForYourAddressHint => 'Search for your address...';

  @override
  String get mapSearchOrTapHint =>
      'Search above, or tap the map to fine-tune the pin';

  @override
  String get resolvingAddress => 'Resolving address...';

  @override
  String get confirmThisAddress => 'Confirm this address';

  @override
  String get coverLetterLoadedFromFile =>
      'Cover letter loaded from file — review and edit before continuing.';

  @override
  String errorCouldNotReadFile(String error) {
    return 'Could not read file: $error';
  }

  @override
  String get notifApplicationSubmittedTitle => 'Application submitted';

  @override
  String notifApplicationSubmittedBody(String company) {
    return 'Your application to $company has been sent.';
  }

  @override
  String get apply => 'Apply';

  @override
  String get coverLetter => 'Cover Letter';

  @override
  String get review => 'Review';

  @override
  String get back => 'Back';

  @override
  String get submitApplication => 'Submit application';

  @override
  String get continueLabel => 'Continue';

  @override
  String get errorCouldNotOpenResume => 'Could not open resume.';

  @override
  String get resumeCvHeading => 'Resume / CV';

  @override
  String get resumeSubmittedWithApplicationNote =>
      'This is the resume that will be submitted with your application.';

  @override
  String get noResumeOnFile => 'No resume on file';

  @override
  String get uploadResumeBeforeApplyingNote =>
      'Upload a resume to your profile before applying.';

  @override
  String get goToProfile => 'Go to profile';

  @override
  String get coverLetterIntroNote =>
      'Tell the company why you are a great fit — type it yourself or upload a file.';

  @override
  String get readingFile => 'Reading file...';

  @override
  String get uploadCoverLetterButton => 'Upload cover letter (PDF/DOCX)';

  @override
  String get coverLetterHint =>
      'Dear Hiring Manager,\n\nI am writing to express my interest in...';

  @override
  String get coverLetterTip => 'Tip: Mention relevant skills and experiences.';

  @override
  String get relevantSkillsHeading => 'Relevant skills';

  @override
  String get selectMatchingSkillsNote =>
      'Select skills that match this internship.';

  @override
  String get reviewYourApplication => 'Review your application';

  @override
  String get pleaseReviewBeforeSubmitting => 'Please review before submitting.';

  @override
  String get position => 'Position';

  @override
  String get noResume => 'No resume';

  @override
  String get noCoverLetterProvided => 'No cover letter provided';

  @override
  String get applicationCannotBeEditedNote =>
      'Once submitted, your application cannot be edited.';

  @override
  String get applicationSubmittedExclaim => 'Application submitted!';

  @override
  String applicationSubmittedDetail(String company) {
    return 'Your application to $company has been sent. You will be notified when there is an update.';
  }

  @override
  String get backToSearch => 'Back to search';

  @override
  String get withdrawApplicationTitle => 'Withdraw application?';

  @override
  String withdrawApplicationMessage(String title) {
    return 'You will be able to re-apply to $title later if you change your mind.';
  }

  @override
  String get withdraw => 'Withdraw';

  @override
  String errorCouldNotWithdraw(String error) {
    return 'Could not withdraw: $error';
  }

  @override
  String get coverLetterLabel => 'COVER LETTER';

  @override
  String get skillsLabel => 'SKILLS';

  @override
  String get myApplications => 'My applications';

  @override
  String get total => 'Total';

  @override
  String get active => 'Active';

  @override
  String get interview => 'Interview';

  @override
  String get pending => 'Pending';

  @override
  String get tabAll => 'All';

  @override
  String get rejected => 'Rejected';

  @override
  String get noApplicationsHere => 'No applications here';

  @override
  String get applicationsAppearHere =>
      'Applications in this category will appear here.';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get noInterviewScheduled => 'No interview scheduled';

  @override
  String get interviewNotifiedOnceScheduled =>
      'You will be notified once the company schedules your interview.';

  @override
  String get onlineInterviewLabel => 'Online interview';

  @override
  String get inPersonInterviewLabel => 'In-person interview';

  @override
  String get joinInterview => 'Join interview';

  @override
  String get directionsUnavailableNote =>
      'Directions unavailable — see address above';

  @override
  String get inPersonNoJoinLinkNote =>
      'This is an in-person interview — no online join link is needed.';

  @override
  String get errorCouldNotOpenMeetingLink => 'Could not open the meeting link.';

  @override
  String get internshipDetails => 'Internship details';

  @override
  String get monthlyAllowance => 'Monthly allowance';

  @override
  String get applicationDeadline => 'Application deadline';

  @override
  String get openUntilFilled => 'Open until filled';

  @override
  String get noDescriptionProvided => 'No description provided.';

  @override
  String get aboutTheCompany => 'About the company';

  @override
  String get industry => 'Industry';

  @override
  String get hrContact => 'HR contact';

  @override
  String get contactEmail => 'Contact email';

  @override
  String get applyOnceVerifiedNote =>
      'You\'ll be able to apply once this company is verified.';

  @override
  String get alreadyApplied => 'Already applied';

  @override
  String get companyPendingVerification => 'Company pending verification';

  @override
  String get applyNow => 'Apply now';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notificationsEmptyDescription =>
      'Updates about your applications, reports, and messages will show up here.';

  @override
  String get newLabel => 'New';

  @override
  String get notificationApprove => 'Approve';

  @override
  String get notificationReject => 'Reject';

  @override
  String get errorParentAlreadyLinked =>
      'This student already has an approved parent linked. Only one approved parent can be linked at a time.';

  @override
  String errorCouldNotRespondToRequest(String error) {
    return 'Could not respond to this request: $error';
  }

  @override
  String get earlier => 'Earlier';

  @override
  String get docTypeOfferLetter => 'Offer Letter';

  @override
  String get docTypeIndemnityLetter => 'Indemnity Letter';

  @override
  String get docTypeCompanyAcceptanceLetter => 'Company Acceptance Letter';

  @override
  String get submissions => 'Submissions';

  @override
  String get reports => 'Reports';

  @override
  String get documents => 'Documents';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get tapSubmitFirstReportNote =>
      'Tap Submit to upload your first monthly or final report.';

  @override
  String get submit => 'Submit';

  @override
  String get finalReportLabel => 'Final Report';

  @override
  String get monthlyReportLabel => 'Monthly Report';

  @override
  String get approvedByCompanyAwaitingUniversity =>
      'Approved by company supervisor · awaiting university review';

  @override
  String get attachment => 'Attachment';

  @override
  String get requiredDocuments => 'Required documents';

  @override
  String get otherDocuments => 'Other documents';

  @override
  String get addOtherDocument => 'Add other document';

  @override
  String get documentTitleDialogTitle => 'Document title';

  @override
  String get documentTitleHint => 'e.g. Transcript';

  @override
  String get notUploadedYet => 'Not uploaded yet';

  @override
  String get manage => 'Manage';

  @override
  String get upload => 'Upload';

  @override
  String get errorFileTooLarge10mb =>
      'File is too large. Maximum size is 10MB.';

  @override
  String errorUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get errorEnterPeriod => 'Please enter a period, e.g. \"June 2026\".';

  @override
  String errorCouldNotSubmit(String error) {
    return 'Could not submit: $error';
  }

  @override
  String get newSubmission => 'New submission';

  @override
  String get submissionType => 'Submission type';

  @override
  String get period => 'Period';

  @override
  String get periodHint => 'e.g. June 2026';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get notesForSupervisorHint => 'Add any notes for your supervisor...';

  @override
  String get tapToSelectFile => 'Tap to select file';

  @override
  String get pdfDocxUpTo10mb => 'PDF, DOCX up to 10MB';

  @override
  String errorLoadInternships(String error) {
    return 'Could not load internships: $error';
  }

  @override
  String get searchInternships => 'Search internships';

  @override
  String get titleSomethingWentWrong => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get searchByRoleCompanySkillHint =>
      'Search by role, company, or skill...';

  @override
  String opportunitiesFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opportunities found',
      one: '1 opportunity found',
    );
    return '$_temp0';
  }

  @override
  String get noMatches => 'No matches';

  @override
  String get tryAdjustingSearchFilters =>
      'Try adjusting your search or filters.';

  @override
  String get pendingVerification => 'Pending verification';

  @override
  String get viewDetails => 'View details';

  @override
  String get filters => 'Filters';

  @override
  String get reset => 'Reset';

  @override
  String get allowanceRange => 'Allowance range';

  @override
  String get minAllowanceLabel => 'Min allowance (RM)';

  @override
  String get maxAllowanceLabel => 'Max allowance (RM)';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get search => 'Search';

  @override
  String get applications => 'Applications';

  @override
  String get programmeNotSet => 'Programme not set';

  @override
  String get applicationsSent => 'Applications sent';

  @override
  String get interviewsScheduled => 'Interviews scheduled';

  @override
  String get reportsSubmitted => 'Reports submitted';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get dashboardEmptyActivityMessage =>
      'Nothing here yet — apply to an internship or submit a report to get started.';

  @override
  String get errorUnsupportedImageFormat =>
      'Unsupported file format. Please upload a JPG, JPEG, or PNG image.';

  @override
  String get errorPhotoEmpty =>
      'The selected photo is empty (0 bytes). Try a different photo.';

  @override
  String get errorPhotoNotFound =>
      'The selected photo could not be found on disk.';

  @override
  String errorCouldNotAccessSource(String source, String error) {
    return 'Could not access $source: $error';
  }

  @override
  String errorCouldNotRemovePhoto(String error) {
    return 'Could not remove photo: $error';
  }

  @override
  String get selectDateOfBirthHelpText => 'Select date of birth';

  @override
  String get errorFullNameBlank => 'Full name cannot be blank.';

  @override
  String get errorPhoneBlank => 'Phone number cannot be blank.';

  @override
  String get errorInvalidPhone => 'Enter a valid phone number.';

  @override
  String get errorSelectDob => 'Please select your date of birth.';

  @override
  String get errorDobInFuture => 'Date of birth cannot be in the future.';

  @override
  String get errorMinAge17 => 'You must be at least 17 years old.';

  @override
  String get errorSelectAddress => 'Please select your address on the map.';

  @override
  String get personalInfoUpdated => 'Personal information updated.';

  @override
  String errorCouldNotSave(String error) {
    return 'Could not save: $error';
  }

  @override
  String get errorSelectProgramme => 'Please select your programme.';

  @override
  String get errorSelectFaculty => 'Please select your faculty.';

  @override
  String get errorSelectSemester => 'Please select your semester.';

  @override
  String get errorCgpaBlank => 'CGPA cannot be blank.';

  @override
  String get errorInvalidCgpaRange =>
      'Enter a valid CGPA between 0.00 and 4.00.';

  @override
  String get academicInfoUpdated => 'Academic information updated.';

  @override
  String get skillsUpdated => 'Skills updated.';

  @override
  String get addWorkExperience => 'Add work experience';

  @override
  String get editWorkExperience => 'Edit work experience';

  @override
  String get positionJobTitleLabel => 'Position / Job title';

  @override
  String get startYearHint => 'e.g. 2023';

  @override
  String get startYearLabel => 'Start year';

  @override
  String get endYearLabel => 'End year';

  @override
  String get iCurrentlyWorkHere => 'I currently work here';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get errorPositionCompanyRequired =>
      'Position and company are required.';

  @override
  String get removeThisEntryTitle => 'Remove this entry?';

  @override
  String errorCouldNotRemove(String error) {
    return 'Could not remove: $error';
  }

  @override
  String get unknownCompany => 'Unknown company';

  @override
  String get unknownPosition => 'Unknown position';

  @override
  String get errorEnterCurrentPassword => 'Enter your current password.';

  @override
  String get errorNewPasswordsMismatch => 'New passwords do not match.';

  @override
  String get errorInvalidResumeFormat =>
      'The file is not in an acceptable format. Only PDF or DOCX files are allowed.';

  @override
  String get errorFileTooLarge5mb => 'File is too large. Maximum size is 5MB.';

  @override
  String get resumeUploaded => 'Resume uploaded.';

  @override
  String get autofillFromResumeTitle => 'Autofill from resume?';

  @override
  String get resumeScanFoundDetailsNote =>
      'We found the following details in your resume. Review and edit before saving — nothing is saved automatically.';

  @override
  String get parsedWithAi => 'Parsed with AI';

  @override
  String get parsedOffline => 'Parsed offline';

  @override
  String get discard => 'Discard';

  @override
  String get reviewAndApply => 'Review & apply';

  @override
  String get fieldsFilledReviewNote =>
      'Fields filled in below — review and tap Save (or Add, for work experience) to confirm.';

  @override
  String errorCouldNotOpenResumeColon(String error) {
    return 'Could not open resume: $error';
  }

  @override
  String errorCouldNotRemoveResume(String error) {
    return 'Could not remove resume: $error';
  }

  @override
  String get prefApplicationUpdates => 'Application updates';

  @override
  String get prefReportDeadlines => 'Report deadlines';

  @override
  String get prefMessages => 'Messages';

  @override
  String get prefSupervisorFeedback => 'Supervisor feedback';

  @override
  String errorCouldNotSaveLanguage(String error) {
    return 'Could not save language: $error';
  }

  @override
  String errorCouldNotSaveTheme(String error) {
    return 'Could not save theme: $error';
  }

  @override
  String get yourNamePlaceholder => 'Your name';

  @override
  String get workExperience => 'Work Experience';

  @override
  String get selectYourProgrammeHint => 'Select your programme';

  @override
  String get selectYourFacultyHint => 'Select your faculty';

  @override
  String get selectYourSemesterHint => 'Select your semester';

  @override
  String semesterNumber(int number) {
    return 'Semester $number';
  }

  @override
  String get cgpaHint => 'e.g. 3.62';

  @override
  String get noSkillsAddedYet => 'No skills added yet.';

  @override
  String get addSkillHint => 'e.g. HTML, CSS, Java, Public Speaking';

  @override
  String get suggestedFromResume => 'Suggested from your resume';

  @override
  String get present => 'Present';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get noWorkExperienceAddedYet => 'No work experience added yet.';

  @override
  String updatedOnDate(String date) {
    return '· Updated $date';
  }

  @override
  String get adminStudentsTitle => 'Students';

  @override
  String get adminCompaniesTitle => 'Companies';

  @override
  String get adminSupervisorsTitle => 'Supervisors';

  @override
  String get adminMoreTitle => 'More';

  @override
  String get adminBrandLabel => 'CIMS Admin';

  @override
  String adminWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get adminFallbackName => 'Admin';

  @override
  String get adminSystemOverview => 'System overview';

  @override
  String get adminTotalStudents => 'Total students';

  @override
  String get adminActiveInternships => 'Active internships';

  @override
  String get adminPartnerCompanies => 'Partner companies';

  @override
  String get adminNeedsAttention => 'Needs attention';

  @override
  String get adminAllClear =>
      'All clear — nothing needs your attention right now.';

  @override
  String adminStudentsUnassignedCount(int count) {
    return '$count students unassigned';
  }

  @override
  String get adminNoSupervisorAssignedYet =>
      'No academic supervisor assigned yet';

  @override
  String adminSubmissionsPendingReviewCount(int count) {
    return '$count submissions pending review';
  }

  @override
  String get adminAwaitingReview => 'Awaiting supervisor or admin review';

  @override
  String get adminAddCompany => 'Add Company';

  @override
  String get adminAssignSupervisor => 'Assign Supervisor';

  @override
  String get adminRecentlyRegistered => 'Recently registered';

  @override
  String adminStudentRegisteredActivity(String name) {
    return '$name registered';
  }

  @override
  String get adminUnnamedStudent => 'Unnamed student';

  @override
  String get adminSearchCompaniesHint => 'Search companies...';

  @override
  String adminRegisteredCompaniesCount(int count) {
    return '$count registered companies';
  }

  @override
  String adminPendingVerificationCount(int count) {
    return '$count pending verification';
  }

  @override
  String get adminNoCompaniesTitle => 'No companies';

  @override
  String get adminNoCompaniesDescription =>
      'Try adjusting your search, or add one.';

  @override
  String get adminLocationNotSet => 'Location not set';

  @override
  String get adminStatusPending => 'Pending';

  @override
  String get adminStatusVerified => 'Verified';

  @override
  String adminCouldNotVerify(String error) {
    return 'Could not verify: $error';
  }

  @override
  String get adminRemoveCompanyTitle => 'Remove company?';

  @override
  String adminRemoveCompanyMessage(String name) {
    return 'This removes $name from the registry. This cannot be undone.';
  }

  @override
  String adminCouldNotRemove(String error) {
    return 'Could not remove: $error';
  }

  @override
  String get adminCompanyDetailsTitle => 'Company details';

  @override
  String get adminCompanyInformation => 'Company information';

  @override
  String get adminLocationLabel => 'Location';

  @override
  String get adminHrContactLabel => 'HR Contact';

  @override
  String get adminHrEmailLabel => 'HR Email';

  @override
  String get adminHrPhoneLabel => 'HR Phone';

  @override
  String get adminStatusLabel => 'Status';

  @override
  String get adminVerifyCompany => 'Verify company';

  @override
  String get adminRemoveCompanyButton => 'Remove company';

  @override
  String get adminCompanyNameRequired => 'Company name is required.';

  @override
  String adminCouldNotSave(String error) {
    return 'Could not save: $error';
  }

  @override
  String get adminEditCompanyTitle => 'Edit Company';

  @override
  String get adminCompanyNameLabel => 'Company name';

  @override
  String get adminIndustryLabel => 'Industry';

  @override
  String get adminOtherIndustryOption => 'Other (type below)';

  @override
  String get adminIndustryNameLabel => 'Industry name';

  @override
  String get adminSelectLocation => 'Select location';

  @override
  String get adminHrContactSection => 'HR contact';

  @override
  String get adminHrContactNameLabel => 'HR contact name';

  @override
  String get adminHrEmailFieldLabel => 'HR email';

  @override
  String get adminHrPhoneNumberLabel => 'HR phone number';

  @override
  String get adminUnassign => 'Unassign';

  @override
  String get adminUnnamed => 'Unnamed';

  @override
  String adminCouldNotAssign(String error) {
    return 'Could not assign: $error';
  }

  @override
  String get adminSearchByNameHint => 'Search by name...';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterAssigned => 'Assigned';

  @override
  String get adminFilterUnassigned => 'Unassigned';

  @override
  String get adminNoStudentsFoundTitle => 'No students found';

  @override
  String get adminNoStudentsFoundDescription =>
      'Try adjusting your search or filters.';

  @override
  String get adminProgrammeNotSet => 'Programme not set';

  @override
  String adminSupervisorColonName(String name) {
    return 'Supervisor: $name';
  }

  @override
  String get adminNoSupervisorAssigned => 'No supervisor assigned';

  @override
  String get adminAssign => 'Assign';

  @override
  String get adminSearchSupervisorsHint => 'Search supervisors...';

  @override
  String adminAcademicSupervisorsCount(int count) {
    return '$count academic supervisors';
  }

  @override
  String get adminNoSupervisorsFoundTitle => 'No supervisors found';

  @override
  String get adminNoSupervisorsFoundDescription =>
      'No academic supervisor accounts have signed up yet.';

  @override
  String get adminFacultyNotSet => 'Faculty not set';

  @override
  String get adminThisSupervisorFallback => 'this supervisor';

  @override
  String get adminPromoteToAdminTitle => 'Promote to admin?';

  @override
  String adminPromoteToAdminMessage(String name) {
    return '$name will immediately become a System Administrator — their account will gain full admin access on next login and they will no longer appear in the supervisors list. This cannot be undone from here.';
  }

  @override
  String get adminPromote => 'Promote';

  @override
  String adminCouldNotPromote(String error) {
    return 'Could not promote: $error';
  }

  @override
  String get adminSupervisorDetailsTitle => 'Supervisor details';

  @override
  String get adminPromoteToAdminButton => 'Promote to admin';

  @override
  String get adminNoStudentsAssignedYet => 'No students assigned yet.';

  @override
  String adminCouldNotSaveReview(String error) {
    return 'Could not save review: $error';
  }

  @override
  String adminCouldNotOpenFile(String error) {
    return 'Could not open file: $error';
  }

  @override
  String get adminMonitorTitle => 'Monitor';

  @override
  String get adminTabStudentProgress => 'Student progress';

  @override
  String get adminTabReports => 'Reports';

  @override
  String get adminTabDocuments => 'Documents';

  @override
  String get adminNoStudentsTitle => 'No students';

  @override
  String get adminNoStudentsRegisteredDescription =>
      'No students have registered yet.';

  @override
  String get adminSubmissionsAppearHere => 'Submissions will appear here.';

  @override
  String get adminEnterCurrentPassword => 'Enter your current password.';

  @override
  String get adminNewPasswordsDoNotMatch => 'New passwords do not match.';

  @override
  String get adminPasswordChanged => 'Password changed';

  @override
  String get adminLogOutConfirmMessage =>
      'You will need to log in again to access the admin console.';

  @override
  String get adminSystemAdministrator => 'System Administrator';

  @override
  String get adminSectionOversight => 'Oversight';

  @override
  String get adminMonitorSubtitle => 'Student progress, reports & documents';

  @override
  String get adminDocumentTemplatesTitle => 'Document Templates';

  @override
  String get adminDocumentTemplatesSubtitle =>
      'Manage fillable PDF forms (e.g. parent acknowledgement)';

  @override
  String get adminSectionCommunication => 'Communication';

  @override
  String get adminMessagesSubtitle =>
      'Message students, supervisors, or companies';

  @override
  String get adminNotifications => 'Notifications';

  @override
  String get adminNotificationsSubtitle => 'View system alerts and updates';

  @override
  String get adminSectionPreferences => 'Preferences';

  @override
  String get adminNotifPrefsSubtitle => 'Choose what you get notified about';

  @override
  String get adminSectionSystem => 'System';

  @override
  String get adminFullNameCannotBeBlank => 'Full name cannot be blank.';

  @override
  String get adminUnsupportedFileFormat =>
      'Unsupported file format. Please upload a JPG, JPEG, or PNG image.';

  @override
  String get adminPhotoEmptyError =>
      'The selected photo is empty (0 bytes). Try a different photo.';

  @override
  String get adminPhotoNotFoundError =>
      'The selected photo could not be found on disk.';

  @override
  String adminUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get adminSourceCamera => 'camera';

  @override
  String get adminSourceGallery => 'gallery';

  @override
  String adminCouldNotAccessSource(String source, String error) {
    return 'Could not access $source: $error';
  }

  @override
  String adminCouldNotRemovePhoto(String error) {
    return 'Could not remove photo: $error';
  }

  @override
  String get cropPhotoTitle => 'Position your photo';

  @override
  String get cropPhotoConfirm => 'Done';

  @override
  String get errorCropFailed => 'Could not crop the photo. Please try again.';

  @override
  String get clear => 'Clear';

  @override
  String parentWelcomeName(String name) {
    return 'Welcome, $name';
  }

  @override
  String get parentWelcomeDefault => 'Welcome, Parent';

  @override
  String get parentDashboardSubtitle =>
      'Monitor your children\'s internship progress';

  @override
  String get parentNoChildrenTitle => 'No children linked yet';

  @override
  String get parentNoChildrenDescription =>
      'Link your child\'s account to start monitoring their internship progress. They\'ll need to approve the request before you can see anything.';

  @override
  String get parentLinkChildButton => 'Link a child';

  @override
  String get parentUnnamedStudent => 'Unnamed student';

  @override
  String get parentNoApplicationYet => 'No internship application yet';

  @override
  String get parentSignFormButton => 'Sign form';

  @override
  String get parentProgressButton => 'Progress';

  @override
  String get parentStudentEmailLabel => 'Student email';

  @override
  String get parentStudentEmailHint => 'e.g. john.doe';

  @override
  String get parentRelationshipLabel => 'Relationship';

  @override
  String get parentRelationshipFather => 'Father';

  @override
  String get parentRelationshipMother => 'Mother';

  @override
  String get parentRelationshipGuardian => 'Guardian';

  @override
  String get parentNoStudentFoundError => 'No student found with that email.';

  @override
  String parentSearchError(String error) {
    return 'Could not search: $error';
  }

  @override
  String get parentSendRequestButton => 'Send request';

  @override
  String get parentRequestSentMessage =>
      'Request sent. The student needs to approve it.';

  @override
  String parentSendRequestError(String error) {
    return 'Could not send request: $error';
  }

  @override
  String parentCancelRequestError(String error) {
    return 'Could not cancel: $error';
  }

  @override
  String get parentYourRequestsTitle => 'Your requests';

  @override
  String get parentNoRequestsYet => 'No requests sent yet.';

  @override
  String parentAsRelationship(String relationship) {
    return 'As $relationship';
  }

  @override
  String get parentUnknownStudent => 'Unknown student';

  @override
  String get parentProgressTitle => 'Internship Progress';

  @override
  String get parentApplicationStatusTitle => 'Application status';

  @override
  String get parentNoApplicationSubmittedYet =>
      'No internship application submitted yet.';

  @override
  String get parentUnknownCompany => 'Unknown company';

  @override
  String get parentAtAGlanceTitle => 'At a glance';

  @override
  String get parentReportsSubmittedLabel => 'Reports submitted';

  @override
  String get parentDurationLabel => 'Duration';

  @override
  String get parentEvaluationTitle => 'Evaluation';

  @override
  String get parentNoEvaluationsYet => 'No evaluations submitted yet.';

  @override
  String get parentAcademicSupervisorEvaluation =>
      'Academic Supervisor Evaluation';

  @override
  String get parentCompanySupervisorEvaluation =>
      'Company Supervisor Evaluation';

  @override
  String get parentRequiredDocumentsTitle => 'Required documents';

  @override
  String get parentDocNotSubmitted => 'Not submitted';

  @override
  String get parentMonthlyReportsTitle => 'Monthly reports';

  @override
  String get parentNoMonthlyReportsYet => 'No monthly reports submitted yet.';

  @override
  String get parentFinalReportTitle => 'Final report';

  @override
  String get parentNoFinalReportYet => 'No final report submitted yet.';

  @override
  String parentMonthlyReportLabel(String period) {
    return 'Monthly Report — $period';
  }

  @override
  String parentFinalReportLabel(String period) {
    return 'Final Report — $period';
  }

  @override
  String parentSubmittedDate(String date) {
    return 'Submitted $date';
  }

  @override
  String get parentReadOnlyNotice =>
      'This is a read-only view. Contact the university for queries regarding your child\'s internship.';

  @override
  String get parentAcknowledgementTitle => 'Acknowledgement Form';

  @override
  String get parentFormNotConfiguredError =>
      'The acknowledgement form has not been set up yet. Please contact the university.';

  @override
  String parentCouldNotLoadFormError(String error) {
    return 'Could not load the acknowledgement form: $error';
  }

  @override
  String get parentTapToFillInstruction =>
      'Tap directly on the form to fill it in, then submit at the bottom.';

  @override
  String get parentSignAndSubmitButton => 'Sign & Submit';

  @override
  String get parentSignatureTimestampNote =>
      'Your digital signature will be recorded with a timestamp.';

  @override
  String get parentDrawSignatureTitle => 'Draw your signature';

  @override
  String parentCouldNotSubmitError(String error) {
    return 'Could not submit form: $error';
  }

  @override
  String parentCouldNotOpenFormError(String error) {
    return 'Could not open form: $error';
  }

  @override
  String get parentFormSubmittedTitle => 'Form submitted successfully';

  @override
  String get parentFormSubmittedDescription =>
      'Your acknowledgement has been recorded.';

  @override
  String parentSignedOnDate(String date) {
    return 'Signed on $date';
  }

  @override
  String get parentViewPdfButton => 'View PDF';

  @override
  String get parentBackToHomeButton => 'Back to home';

  @override
  String get viewCompanyProfile => 'View company profile';

  @override
  String get companyProfileTitle => 'Company Profile';

  @override
  String get companyProfileJobPostings => 'Job Postings';

  @override
  String get companyProfileNoPostings => 'No postings from this company yet.';

  @override
  String get companyProfilePastInterns => 'Past Interns';

  @override
  String companyProfileInternCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students have interned here',
      one: '1 student has interned here',
    );
    return '$_temp0';
  }

  @override
  String get companyProfileReviews => 'Reviews';

  @override
  String companyProfileReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get companyProfileNoReviewsYet =>
      'No reviews yet. Be the first to share your experience.';

  @override
  String get companyProfileWriteReview => 'Write a review';

  @override
  String get companyProfileEditReview => 'Edit your review';

  @override
  String get companyProfileRatingLabel => 'Your rating';

  @override
  String get companyProfileReviewHint =>
      'Share your experience working here (optional)';

  @override
  String get companyProfileReviewSubmitted => 'Review submitted. Thank you!';

  @override
  String companyProfileReviewError(String error) {
    return 'Could not submit review: $error';
  }

  @override
  String get companyProfileMustApplyNote =>
      'Only students who have applied to this company can leave a review.';
}
