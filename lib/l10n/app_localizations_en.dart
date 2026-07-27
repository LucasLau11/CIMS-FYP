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
}
