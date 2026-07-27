// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'CIMS';

  @override
  String get tarumt => '拉曼理工大学';

  @override
  String get splashTagline => '实习管理\n综合系统';

  @override
  String get loading => '加载中...';

  @override
  String get welcomeToCims => '欢迎使用 CIMS';

  @override
  String get cimsFullName => '实习管理综合系统';

  @override
  String get emailAddress => '电子邮箱';

  @override
  String get enterYourEmail => '请输入您的电子邮箱';

  @override
  String get password => '密码';

  @override
  String get enterYourPassword => '请输入您的密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get logIn => '登录';

  @override
  String get noAccountSignUp => '还没有账号？注册';

  @override
  String get footerCopyright => '© 2026 拉曼理工大学 · CIMS v1.0';

  @override
  String get errorEnterEmail => '请输入您的电子邮箱。';

  @override
  String get errorEnterPassword => '请输入您的密码。';

  @override
  String get errorIncorrectCredentials => '邮箱或密码不正确，请重试。';

  @override
  String get errorConfirmEmail => '请先确认您的电子邮箱后再登录。';

  @override
  String get errorSomethingWrong => '出现了一些问题，请重试。';

  @override
  String get resetYourPassword => '重置密码';

  @override
  String get resetPasswordInstructions => '输入您的账户邮箱，我们将发送重置密码的链接给您。';

  @override
  String get cancel => '取消';

  @override
  String get sendResetLink => '发送重置链接';

  @override
  String get resetLinkSentMessage => '如果该邮箱存在账户，重置链接已发送。';

  @override
  String get createYourAccount => '创建您的 CIMS 账户';

  @override
  String get signupRoleNote =>
      '学生/教职员邮箱将自动分配角色。\nGmail、Outlook 或 Hotmail 邮箱将需要在下方选择角色。';

  @override
  String get createAPassword => '设置密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get reEnterYourPassword => '请再次输入密码';

  @override
  String get selectYourRole => '选择您的角色';

  @override
  String get notInstitutionalEmailNote => '您的邮箱不是 TARC 机构邮箱，请选择适用于您的角色。';

  @override
  String get parentGuardian => '家长/监护人';

  @override
  String get hrPersonnel => '人力资源人员';

  @override
  String get companySupervisor => '公司主管';

  @override
  String get signUp => '注册';

  @override
  String get alreadyHaveAccountLogIn => '已有账号？登录';

  @override
  String get errorFillAllFields => '请填写所有字段。';

  @override
  String get errorPasswordsDoNotMatch => '两次输入的密码不一致。';

  @override
  String get errorSelectRole => '请选择您的角色以继续。';

  @override
  String get dashboard => '主页';

  @override
  String get overview => '概览';

  @override
  String get internshipProgress => '实习进度';

  @override
  String get upcomingDeadlines => '即将到期任务';

  @override
  String get viewAll => '查看全部';

  @override
  String get recentFeedback => '最新反馈';

  @override
  String get quickActions => '快捷操作';

  @override
  String get overallProgress => '总体进度';

  @override
  String get urgent => '紧急';

  @override
  String get stepApplied => '已申请';

  @override
  String get stepAccepted => '已接受';

  @override
  String get stepOngoing => '进行中';

  @override
  String get stepCompleted => '已完成';

  @override
  String get submitCompanyReview => '提交公司评价';

  @override
  String get viewMyProgress => '查看我的进度';

  @override
  String goodMorning(String name) {
    return '早上好，$name！';
  }

  @override
  String get personalInformation => '个人信息';

  @override
  String get academicInformation => '学业信息';

  @override
  String get resume => '简历';

  @override
  String get account => '账户';

  @override
  String get fullName => '姓名';

  @override
  String get phone => '电话';

  @override
  String get email => '电子邮箱';

  @override
  String get dateOfBirth => '出生日期';

  @override
  String get address => '地址';

  @override
  String get notSet => '未设置';

  @override
  String get programme => '课程';

  @override
  String get semester => '学期';

  @override
  String get faculty => '学院';

  @override
  String get cgpa => '累积平均积点';

  @override
  String get academicSupervisor => '学术导师';

  @override
  String get assignedBySystem => '由系统分配';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get changePassword => '更改密码';

  @override
  String get notificationPreferences => '通知偏好设置';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get selectTheme => '选择主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get logOut => '登出';

  @override
  String get logOutConfirmTitle => '登出？';

  @override
  String get logOutConfirmMessage => '您需要重新登录才能访问您的账户。';

  @override
  String get noResumeUploaded => '尚未上传简历';

  @override
  String get resumeFormatNote => '仅限 PDF 或 DOCX 格式，最大 5MB。';

  @override
  String get uploadResume => '上传简历';

  @override
  String get uploading => '正在上传...';

  @override
  String get view => '查看';

  @override
  String get replace => '替换';

  @override
  String get remove => '移除';

  @override
  String get scanResumeToAutofill => '扫描简历以自动填写个人资料';

  @override
  String get tapToSelectDateOfBirth => '点击选择出生日期';

  @override
  String get tapToSelectAddress => '点击在地图上选择您的地址';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get change => '更改';

  @override
  String get delete => '删除';

  @override
  String get add => '添加';

  @override
  String get confirm => '确认';

  @override
  String get close => '关闭';

  @override
  String get notSpecified => '未注明';

  @override
  String get hrRecruitmentOverview => '招聘概览';

  @override
  String get hrActivePostings => '招聘中职位';

  @override
  String get hrNewApplicants => '新申请者';

  @override
  String get hrInterviewsPending => '待面试';

  @override
  String get hrCurrentInterns => '现有实习生';

  @override
  String get hrUpcomingInterviews => '即将进行的面试';

  @override
  String get hrNoInterviewsScheduled => '暂无已安排的面试。';

  @override
  String get hrNewPosting => '新职位';

  @override
  String get hrReviewApplicants => '审核申请者';

  @override
  String get hrPersonnelLabel => '人力资源人员';

  @override
  String get hrJobPostings => '职位招聘';

  @override
  String hrPostingsCount(int count) {
    return '$count 个职位';
  }

  @override
  String hrActiveCount(int count) {
    return '$count 个招聘中';
  }

  @override
  String get hrNoPostingsYet => '尚无职位';

  @override
  String get hrCreateFirstPosting => '创建您的第一个实习职位。';

  @override
  String get hrClosePosting => '关闭职位';

  @override
  String get hrReopenPosting => '重新开放职位';

  @override
  String get hrDeletePostingTitle => '删除职位？';

  @override
  String get hrDeletePostingMessage => '此操作将永久删除此职位。现有申请将被保留作记录。';

  @override
  String hrApplicantsCount(int count) {
    return '$count 位申请者';
  }

  @override
  String hrPostedAgo(String time) {
    return '发布于 $time';
  }

  @override
  String get hrEditPosting => '编辑职位';

  @override
  String get hrPostingDetails => '职位详情';

  @override
  String get hrJobTitle => '职位名称';

  @override
  String get hrJobTitleHint => '例如：软件工程实习生';

  @override
  String get hrJobDescription => '职位描述';

  @override
  String get hrJobDescriptionHint => '描述该职位的角色与职责';

  @override
  String get hrCategory => '类别';

  @override
  String get hrLogistics => '详细信息';

  @override
  String get hrLocationHint => '地点 — 点击在地图上选择';

  @override
  String get hrJobType => '工作类型';

  @override
  String get hrDuration => '期限';

  @override
  String hrMonths(int count) {
    return '$count 个月';
  }

  @override
  String get hrMonthlyAllowance => '每月津贴 (RM)';

  @override
  String get hrMonthlyAllowanceHint => '例如：1500';

  @override
  String hrDeadlineLabel(String date) {
    return '截止日期：$date';
  }

  @override
  String get hrApplicationDeadlineOptional => '申请截止日期（可选）';

  @override
  String get hrSkillsRequired => '所需技能';

  @override
  String get hrAddASkill => '添加技能';

  @override
  String get hrSaveChanges => '保存更改';

  @override
  String get hrPublishPosting => '发布职位';

  @override
  String get hrTitleLocationRequired => '职位名称和地点为必填项。';

  @override
  String get hrDescriptionRequired => '请添加职位描述。';

  @override
  String get hrValidAllowanceRequired => '请输入有效的每月津贴。';

  @override
  String get hrSkillRequired => '请至少添加一项所需技能。';

  @override
  String get hrApplicants => '申请者';

  @override
  String hrTabNew(int count) {
    return '新申请 ($count)';
  }

  @override
  String hrTabInterview(int count) {
    return '面试中 ($count)';
  }

  @override
  String hrTabAccepted(int count) {
    return '已录取 ($count)';
  }

  @override
  String hrTabRejected(int count) {
    return '已拒绝 ($count)';
  }

  @override
  String get hrNoApplicantsHere => '暂无申请者';

  @override
  String get hrApplicantsAppearHere => '此阶段的申请者将显示在此处。';

  @override
  String hrInterviewColon(String time) {
    return '面试：$time';
  }

  @override
  String hrAppliedAgo(String time) {
    return '申请于 $time';
  }

  @override
  String get hrApplicantProfile => '申请者资料';

  @override
  String get hrAppliedFor => '申请职位';

  @override
  String get hrNoResumeUploaded => '尚未上传简历';

  @override
  String get hrCoverLetter => '求职信';

  @override
  String get hrNoCoverLetterProvided => '未提供求职信。';

  @override
  String get hrSkills => '技能';

  @override
  String get hrReject => '拒绝';

  @override
  String get hrScheduleInterview => '安排面试';

  @override
  String hrInterviewScheduledColon(String time) {
    return '面试已安排：$time';
  }

  @override
  String get hrAccept => '接受';

  @override
  String get hrDate => '日期';

  @override
  String get hrSelectDate => '选择日期';

  @override
  String get hrTime => '时间';

  @override
  String get hrSelectTime => '选择时间';

  @override
  String get hrInterviewMode => '面试方式';

  @override
  String get hrOnline => '线上';

  @override
  String get hrInPerson => '线下';

  @override
  String get hrMeetingLink => '会议链接';

  @override
  String get hrLocation => '地点';

  @override
  String get hrMeetingLinkHint => '例如：Zoom/Google Meet 链接';

  @override
  String get hrLocationTapToSelect => '点击在地图上选择';

  @override
  String get hrOfficeAddressHint => '办公室地址';

  @override
  String get hrMeetingLinkRequired => '会议链接为必填项。';

  @override
  String get hrLocationRequired => '地点为必填项。';

  @override
  String get hrConfirmNotifyApplicant => '确认并通知申请者';

  @override
  String get hrPostings => '职位';

  @override
  String get hrInterns => '实习生';

  @override
  String get hrClosedStatus => '已关闭';

  @override
  String get supAssignedStudents => '已分配学生';

  @override
  String get supPendingReviews => '待审核';

  @override
  String get supApprovedThisMonth => '本月已批准';

  @override
  String get supUnreadMessages => '未读消息';

  @override
  String get supPendingYourReview => '待您审核';

  @override
  String get supNothingPendingReview => '目前没有待审核项目。';

  @override
  String get supMyStudents => '我的学生';

  @override
  String get supNoStudentsYet => '尚无学生。';

  @override
  String get supUpToDate => '已是最新';

  @override
  String supPendingCount(int count) {
    return '$count 项待处理';
  }

  @override
  String get supMyStudentsTitle => '我的学生';

  @override
  String get supSearchByNameOrProgramme => '按姓名或课程搜索...';

  @override
  String supStudentsCount(int count) {
    return '$count 位学生';
  }

  @override
  String get supNoStudents => '暂无学生';

  @override
  String get supNoStudentsMatch => '没有符合搜索条件的学生。';

  @override
  String get supActiveInternship => '进行中的实习';

  @override
  String get supNoActiveInternship => '暂无进行中的实习';

  @override
  String supLastReportAgo(String time) {
    return '最近报告于 $time';
  }

  @override
  String get supNoReportsYet => '尚无报告';

  @override
  String get supStudentDetails => '学生详情';

  @override
  String get supEvaluate => '评估';

  @override
  String get supMessage => '消息';

  @override
  String get supLatestEvaluation => '最新评估';

  @override
  String supSubmittedAgo(String time) {
    return '提交于 $time';
  }

  @override
  String get supSubmissionHistory => '提交记录';

  @override
  String get supNoSubmissionsYet => '尚无提交记录。';

  @override
  String get supReviews => '审核';

  @override
  String get supTabPending => '待处理';

  @override
  String get supTabApproved => '已批准';

  @override
  String get supTabRejected => '已拒绝';

  @override
  String get supNothingHere => '暂无内容';

  @override
  String get supItemsAppearHere => '此类别的项目将显示在此处。';

  @override
  String get supNoFileAttached => '此提交没有附加文件。';

  @override
  String get supAwaitingCompanyReview => '需等待公司主管审核后您才能批准。';

  @override
  String get supRejectedByCompany => '已被公司主管拒绝 — 等待学生重新提交。';

  @override
  String get supRejectSubmission => '拒绝提交';

  @override
  String get supApproveSubmission => '批准提交';

  @override
  String get supRejectFeedbackPrompt => '请提供说明拒绝原因的反馈。';

  @override
  String get supApproveCommentPrompt => '为学生添加可选评语。';

  @override
  String get supTypeYourComment => '输入您的评语...';

  @override
  String get supPleaseAddFeedback => '拒绝前请添加反馈。';

  @override
  String get supApprove => '批准';

  @override
  String get supEvaluateStudent => '评估学生';

  @override
  String get supRatingInstruction => '根据实习表现，为每项标准评分，从 1（差）到 5（优秀）。';

  @override
  String get supOverallAverageScore => '总体平均分';

  @override
  String get supAdditionalComments => '补充意见';

  @override
  String get supQualitativeFeedbackHint => '请对学生的整体表现提供定性反馈...';

  @override
  String get supSubmitEvaluation => '提交评估';

  @override
  String get supEvaluationSubmitted => '评估已提交';

  @override
  String supEvaluationRecorded(String name) {
    return '您对 $name 的评估已记录。';
  }

  @override
  String get supBackToStudent => '返回学生页面';

  @override
  String get supStudents => '学生';

  @override
  String get csCurrentInterns => '现有实习生';

  @override
  String get csReportsToReview => '待审核报告';

  @override
  String get csApprovedThisMonth => '本月已批准';

  @override
  String get csEvaluations => '评估';

  @override
  String get csPendingYourReview => '待您审核';

  @override
  String get csNothingPendingReview => '暂无待审核项目。';

  @override
  String get csInternProgress => '实习生进度';

  @override
  String get csNoInternsYet => '尚无实习生。';

  @override
  String get csInterns => '实习生';

  @override
  String csCurrentInternsCount(int count) {
    return '$count 位现有实习生';
  }

  @override
  String csNeedsAttention(int count) {
    return '$count 项需要注意';
  }

  @override
  String get csNoInternsTitle => '尚无实习生';

  @override
  String get csNoInternsDescription => '贵公司录取的申请者将显示在此处。';

  @override
  String get csInternDetails => '实习生详情';

  @override
  String get csReportSubmissions => '报告提交记录';

  @override
  String get csNoReportsSubmittedYet => '尚未提交报告。';

  @override
  String get csEvaluateIntern => '评估实习生';

  @override
  String get csRatingInstruction => '根据职场表现，为每项标准评分，从 1（差）到 5（优秀）。';

  @override
  String get csAdditionalComments => '补充意见';

  @override
  String get csPerformanceCommentHint => '描述实习生在实习期间的整体表现、态度与成长...';

  @override
  String get csSubmitEvaluation => '提交评估';

  @override
  String get csEvaluationSubmitted => '评估已提交';

  @override
  String csEvaluationRecorded(String name) {
    return '您对 $name 的职场评估已记录并与学校共享。';
  }

  @override
  String get csBackToIntern => '返回实习生页面';

  @override
  String get csReportReviews => '报告审核';

  @override
  String get csTabPending => '待处理';

  @override
  String get csTabApproved => '已批准';

  @override
  String get csTabRejected => '已拒绝';

  @override
  String get csNothingHere => '暂无内容';

  @override
  String get csReportsAppearHere => '此类别的报告将显示在此处。';

  @override
  String get csRejectReport => '拒绝报告';

  @override
  String get csApproveReport => '批准报告';

  @override
  String get csRejectReasonPrompt => '请提供说明拒绝原因的反馈。';

  @override
  String get csApproveCommentPrompt => '为实习生添加可选评语。';

  @override
  String get csPleaseAddFeedback => '拒绝前请添加反馈。';

  @override
  String get csGradeExcellent => '优秀';

  @override
  String get csGradeGood => '良好';

  @override
  String get csGradeSatisfactory => '满意';

  @override
  String get csGradeNeedsImprovement => '需要改进';

  @override
  String get csAverageScore => '平均分';

  @override
  String get setupYourCompany => '设置您的公司';

  @override
  String get setupLinkCompanyNote => '请先将您的账户关联至公司，才能管理职位、申请者或实习生。';

  @override
  String get setupJoinExisting => '加入现有公司';

  @override
  String get setupRegisterNew => '注册新公司';

  @override
  String get setupNoCompaniesYet => '暂无公司';

  @override
  String get setupSwitchToRegister => '切换至「注册新公司」以添加您的公司。';

  @override
  String get setupIndustryNotSet => '行业未设置';

  @override
  String get setupJoinCompany => '加入公司';

  @override
  String get setupCompanyName => '公司名称';

  @override
  String get setupIndustryOptional => '行业（可选）';

  @override
  String get setupLocationOptional => '地点（可选）— 点击在地图上选择';

  @override
  String get setupRegisterCompany => '注册公司';

  @override
  String get setupCompanyNameRequired => '公司名称为必填项。';

  @override
  String get profileMyProfile => '我的资料';

  @override
  String get profilePersonalInformation => '个人信息';

  @override
  String get profileFullName => '姓名';

  @override
  String get profileEmail => '电子邮箱';

  @override
  String get profilePhone => '电话';

  @override
  String get profileAddress => '地址';

  @override
  String get profileNotSet => '未设置';

  @override
  String get profilePhoneHint => '例如：012-345 6789';

  @override
  String get profileTapToSelectOnMap => '点击在地图上选择';

  @override
  String get profileEmailCannotChange => '电子邮箱是您的登录账号，无法在此更改。';

  @override
  String get profileUpdated => '资料已更新。';

  @override
  String get profileAccount => '账户';

  @override
  String get profileNotificationPreferencesTitle => '通知偏好设置';

  @override
  String get profileChooseWhatToBeNotified => '选择您想接收通知的内容。';

  @override
  String get profileApplicationApplicantUpdates => '申请与申请者动态';

  @override
  String get profileReportDocumentReviews => '报告与文件审核';

  @override
  String get profileMessages => '消息';

  @override
  String get profileEvaluationReminders => '评估提醒';

  @override
  String get profileNotificationPrefsUpdated => '通知偏好设置已更新。';

  @override
  String get profileSelectLanguage => '选择语言';

  @override
  String get profilePhotoUpdated => '头像已更新。';

  @override
  String get profileUpdatePhoto => '更新头像';

  @override
  String get profileTakePhoto => '拍照';

  @override
  String get profileChooseFromGallery => '从相册选择';

  @override
  String get profileRemovePhoto => '移除照片';

  @override
  String get profilePasswordChanged => '密码已成功更改。';
}
