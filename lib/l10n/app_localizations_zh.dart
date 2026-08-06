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
  String get signUpCheckEmailMessage => '账户已创建！请检查您的电子邮件以确认账户，然后再登录。';

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
  String get studentRegNo => '学生注册号';

  @override
  String get studentRegNoHint => '例如 24WMR12345';

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

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 周前',
    );
    return '$_temp0';
  }

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个月前',
    );
    return '$_temp0';
  }

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
    );
    return '$_temp0';
  }

  @override
  String get chatConversationFallbackName => '此对话';

  @override
  String get chatDeleteConversationTitle => '删除对话？';

  @override
  String chatDeleteConversationMessage(String name) {
    return '这将删除您与$name的整个对话，双方都会受到影响。此操作无法撤销。';
  }

  @override
  String chatCouldNotLoadContacts(String error) {
    return '无法加载联系人：$error';
  }

  @override
  String get chatNewMessageTitle => '新消息';

  @override
  String get chatNoContactsToMessage => '暂无其他可联系的账号。';

  @override
  String get chatTabTitle => '消息';

  @override
  String get chatArchivedChatsTitle => '已归档聊天';

  @override
  String get chatNoConversationsYetTitle => '暂无对话';

  @override
  String get chatTapPencilToMessage => '点击铅笔图标给某人发消息。';

  @override
  String get chatNoArchivedChatsTitle => '暂无已归档聊天';

  @override
  String get chatArchivedConversationsDescription => '您归档的对话会显示在这里。';

  @override
  String get chatUnknownUser => '未知用户';

  @override
  String get chatUnarchiveAction => '取消归档';

  @override
  String get chatRoleStudent => '学生';

  @override
  String get chatPhotoAttachmentPreview => '📷 照片';

  @override
  String get chatArchiveAction => '归档';

  @override
  String chatCouldNotSendMessage(String error) {
    return '无法发送消息：$error';
  }

  @override
  String get chatFileTooLarge => '文件过大，最大为10MB。';

  @override
  String chatCouldNotSendAttachment(String error) {
    return '无法发送附件：$error';
  }

  @override
  String get chatDeleteForMeAction => '为我删除';

  @override
  String get chatDeleteForEveryoneAction => '为所有人删除';

  @override
  String get chatDeleteForMeTitle => '为我删除？';

  @override
  String get chatDeleteForMeMessage => '此消息将仅从您的视图中移除，对方仍可看到该消息。';

  @override
  String chatCouldNotDeleteMessage(String error) {
    return '无法删除消息：$error';
  }

  @override
  String get chatEditMessageTitle => '编辑消息';

  @override
  String chatCouldNotEditMessage(String error) {
    return '无法编辑消息：$error';
  }

  @override
  String get chatDeleteMessageTitle => '删除消息？';

  @override
  String get chatCannotBeUndone => '此操作无法撤销。';

  @override
  String get chatSayHello => '打个招呼 👋';

  @override
  String get chatTypeMessageHint => '输入消息...';

  @override
  String get chatEditedLabel => '已编辑';

  @override
  String get chatAttachmentFallbackName => '附件';

  @override
  String chatCouldNotUpdateMute(String error) {
    return '无法更新静音设置：$error';
  }

  @override
  String get chatBlockContactTitle => '屏蔽此联系人？';

  @override
  String get chatUnblockContactTitle => '取消屏蔽此联系人？';

  @override
  String get chatBlockContactMessage => '对方将无法在此对话中再向您发送消息。';

  @override
  String get chatUnblockContactMessage => '对方将可以再次向您发送消息。';

  @override
  String get chatBlockAction => '屏蔽';

  @override
  String get chatUnblockAction => '取消屏蔽';

  @override
  String chatCouldNotUpdateBlock(String error) {
    return '无法更新屏蔽状态：$error';
  }

  @override
  String chatCouldNotDeleteConversation(String error) {
    return '无法删除对话：$error';
  }

  @override
  String get chatContactInfoTitle => '联系人信息';

  @override
  String get chatPhoneNotAvailable => '不可用';

  @override
  String get chatSharedMediaFiles => '共享媒体与文件';

  @override
  String get chatNoSharedMediaYet => '暂无共享媒体。';

  @override
  String get chatMuteNotifications => '静音通知';

  @override
  String get chatBlockContactToggle => '屏蔽联系人';

  @override
  String get chatDeleteConversationButton => '删除对话';

  @override
  String errorAddressSearchFailed(String error) {
    return '地址搜索失败：$error';
  }

  @override
  String unknownLocationCoords(String lat, String lng) {
    return '未知位置（$lat, $lng）';
  }

  @override
  String get errorCouldNotResolveAddress => '无法解析此位置的地址。';

  @override
  String get selectYourAddress => '选择您的地址';

  @override
  String get searchForYourAddressHint => '搜索您的地址...';

  @override
  String get mapSearchOrTapHint => '在上方搜索，或点击地图微调图钉位置';

  @override
  String get resolvingAddress => '正在解析地址...';

  @override
  String get confirmThisAddress => '确认此地址';

  @override
  String get coverLetterLoadedFromFile => '求职信已从文件加载——请在继续前检查并编辑。';

  @override
  String errorCouldNotReadFile(String error) {
    return '无法读取文件：$error';
  }

  @override
  String get notifApplicationSubmittedTitle => '申请已提交';

  @override
  String notifApplicationSubmittedBody(String company) {
    return '您对$company的申请已发送。';
  }

  @override
  String get apply => '申请';

  @override
  String get coverLetter => '求职信';

  @override
  String get review => '查看';

  @override
  String get back => '返回';

  @override
  String get submitApplication => '提交申请';

  @override
  String get continueLabel => '继续';

  @override
  String get errorCouldNotOpenResume => '无法打开简历。';

  @override
  String get resumeCvHeading => '简历';

  @override
  String get resumeSubmittedWithApplicationNote => '这是将随您的申请一起提交的简历。';

  @override
  String get noResumeOnFile => '暂无简历';

  @override
  String get uploadResumeBeforeApplyingNote => '申请前请先将简历上传至您的个人资料。';

  @override
  String get goToProfile => '前往个人资料';

  @override
  String get coverLetterIntroNote => '告诉公司您为何是合适的人选——可自行输入或上传文件。';

  @override
  String get readingFile => '正在读取文件...';

  @override
  String get uploadCoverLetterButton => '上传求职信（PDF/DOCX）';

  @override
  String get coverLetterHint => '尊敬的招聘经理，\n\n我写此信是想表达我对……的兴趣';

  @override
  String get coverLetterTip => '提示：提及相关技能与经验。';

  @override
  String get relevantSkillsHeading => '相关技能';

  @override
  String get selectMatchingSkillsNote => '选择与此实习相符的技能。';

  @override
  String get reviewYourApplication => '查看您的申请';

  @override
  String get pleaseReviewBeforeSubmitting => '提交前请仔细查看。';

  @override
  String get position => '职位';

  @override
  String get noResume => '无简历';

  @override
  String get noCoverLetterProvided => '未提供求职信';

  @override
  String get applicationCannotBeEditedNote => '提交后，您的申请将无法编辑。';

  @override
  String get applicationSubmittedExclaim => '申请已提交！';

  @override
  String applicationSubmittedDetail(String company) {
    return '您对$company的申请已发送。如有更新我们会通知您。';
  }

  @override
  String get backToSearch => '返回搜索';

  @override
  String get withdrawApplicationTitle => '撤回申请？';

  @override
  String withdrawApplicationMessage(String title) {
    return '如果您改变主意，之后仍可重新申请$title。';
  }

  @override
  String get withdraw => '撤回';

  @override
  String errorCouldNotWithdraw(String error) {
    return '无法撤回：$error';
  }

  @override
  String get coverLetterLabel => '求职信';

  @override
  String get skillsLabel => '技能';

  @override
  String get myApplications => '我的申请';

  @override
  String get total => '总数';

  @override
  String get active => '进行中';

  @override
  String get interview => '面试';

  @override
  String get pending => '待处理';

  @override
  String get tabAll => '全部';

  @override
  String get rejected => '已拒绝';

  @override
  String get noApplicationsHere => '此处暂无申请';

  @override
  String get applicationsAppearHere => '此类别的申请将显示在这里。';

  @override
  String get statusApproved => '已批准';

  @override
  String get statusSubmitted => '已提交';

  @override
  String get noInterviewScheduled => '尚未安排面试';

  @override
  String get interviewNotifiedOnceScheduled => '公司安排面试后将通知您。';

  @override
  String get onlineInterviewLabel => '线上面试';

  @override
  String get inPersonInterviewLabel => '现场面试';

  @override
  String get joinInterview => '加入面试';

  @override
  String get directionsUnavailableNote => '路线不可用 — 请参见上方地址';

  @override
  String get inPersonNoJoinLinkNote => '这是现场面试 — 无需线上加入链接。';

  @override
  String get errorCouldNotOpenMeetingLink => '无法打开会议链接。';

  @override
  String get internshipDetails => '实习详情';

  @override
  String get monthlyAllowance => '每月津贴';

  @override
  String get applicationDeadline => '申请截止日期';

  @override
  String get openUntilFilled => '开放至额满为止';

  @override
  String get noDescriptionProvided => '未提供说明。';

  @override
  String get aboutTheCompany => '关于公司';

  @override
  String get industry => '行业';

  @override
  String get hrContact => '人事联系人';

  @override
  String get contactEmail => '联系邮箱';

  @override
  String get applyOnceVerifiedNote => '该公司通过验证后您即可申请。';

  @override
  String get alreadyApplied => '已申请';

  @override
  String get companyPendingVerification => '公司待验证';

  @override
  String get applyNow => '立即申请';

  @override
  String get notifications => '通知';

  @override
  String get markAllRead => '全部标记为已读';

  @override
  String get noNotificationsYet => '暂无通知';

  @override
  String get notificationsEmptyDescription => '有关您的申请、报告和消息的更新将显示在这里。';

  @override
  String get newLabel => '新';

  @override
  String get notificationApprove => '批准';

  @override
  String get notificationReject => '拒绝';

  @override
  String get errorParentAlreadyLinked => '该学生已有一位已批准并关联的家长。同一时间只能关联一位已批准的家长。';

  @override
  String errorCouldNotRespondToRequest(String error) {
    return '无法回应此请求：$error';
  }

  @override
  String get earlier => '更早';

  @override
  String get docTypeOfferLetter => '录取信';

  @override
  String get docTypeIndemnityLetter => '弥偿书';

  @override
  String get docTypeCompanyAcceptanceLetter => '公司接受函';

  @override
  String get submissions => '提交';

  @override
  String get reports => '报告';

  @override
  String get documents => '文件';

  @override
  String get noReportsYet => '暂无报告';

  @override
  String get tapSubmitFirstReportNote => '点击提交以上传您的第一份月度或最终报告。';

  @override
  String get submit => '提交';

  @override
  String get finalReportLabel => '最终报告';

  @override
  String get monthlyReportLabel => '月度报告';

  @override
  String get approvedByCompanyAwaitingUniversity => '已获公司主管批准 · 等待大学审核';

  @override
  String get attachment => '附件';

  @override
  String get requiredDocuments => '所需文件';

  @override
  String get otherDocuments => '其他文件';

  @override
  String get addOtherDocument => '添加其他文件';

  @override
  String get documentTitleDialogTitle => '文件标题';

  @override
  String get documentTitleHint => '例如：成绩单';

  @override
  String get notUploadedYet => '尚未上传';

  @override
  String get manage => '管理';

  @override
  String get upload => '上传';

  @override
  String get errorFileTooLarge10mb => '文件过大。最大限制为 10MB。';

  @override
  String errorUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get errorEnterPeriod => '请输入期间，例如“2026年6月”。';

  @override
  String errorCouldNotSubmit(String error) {
    return '无法提交：$error';
  }

  @override
  String get newSubmission => '新提交';

  @override
  String get submissionType => '提交类型';

  @override
  String get period => '期间';

  @override
  String get periodHint => '例如：2026年6月';

  @override
  String get notesOptional => '备注（可选）';

  @override
  String get notesForSupervisorHint => '为您的主管添加任何备注...';

  @override
  String get tapToSelectFile => '点击选择文件';

  @override
  String get pdfDocxUpTo10mb => 'PDF、DOCX，最大 10MB';

  @override
  String errorLoadInternships(String error) {
    return '无法加载实习：$error';
  }

  @override
  String get searchInternships => '搜索实习';

  @override
  String get titleSomethingWentWrong => '出了点问题';

  @override
  String get retry => '重试';

  @override
  String get searchByRoleCompanySkillHint => '按职位、公司或技能搜索...';

  @override
  String opportunitiesFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '找到 $count 个机会',
    );
    return '$_temp0';
  }

  @override
  String get noMatches => '没有匹配结果';

  @override
  String get tryAdjustingSearchFilters => '请尝试调整您的搜索或筛选条件。';

  @override
  String get pendingVerification => '待验证';

  @override
  String get viewDetails => '查看详情';

  @override
  String get filters => '筛选';

  @override
  String get reset => '重置';

  @override
  String get allowanceRange => '津贴范围';

  @override
  String get minAllowanceLabel => '最低津贴 (RM)';

  @override
  String get maxAllowanceLabel => '最高津贴 (RM)';

  @override
  String get applyFilters => '应用筛选';

  @override
  String get search => '搜索';

  @override
  String get applications => '申请';

  @override
  String get programmeNotSet => '尚未设置课程';

  @override
  String get applicationsSent => '已发送申请';

  @override
  String get interviewsScheduled => '已安排面试';

  @override
  String get reportsSubmitted => '已提交报告';

  @override
  String get recentActivity => '最近活动';

  @override
  String get dashboardEmptyActivityMessage => '这里还没有内容 — 申请实习或提交报告即可开始。';

  @override
  String get errorUnsupportedImageFormat => '不支持的文件格式。请上传 JPG、JPEG 或 PNG 图片。';

  @override
  String get errorPhotoEmpty => '所选照片为空（0 字节）。请尝试其他照片。';

  @override
  String get errorPhotoNotFound => '在磁盘上找不到所选照片。';

  @override
  String errorCouldNotAccessSource(String source, String error) {
    return '无法访问$source：$error';
  }

  @override
  String errorCouldNotRemovePhoto(String error) {
    return '无法移除照片：$error';
  }

  @override
  String get selectDateOfBirthHelpText => '选择出生日期';

  @override
  String get errorFullNameBlank => '全名不能为空。';

  @override
  String get errorPhoneBlank => '电话号码不能为空。';

  @override
  String get errorInvalidPhone => '请输入有效的电话号码。';

  @override
  String get errorSelectDob => '请选择您的出生日期。';

  @override
  String get errorDobInFuture => '出生日期不能是将来的日期。';

  @override
  String get errorMinAge17 => '您必须年满 17 岁。';

  @override
  String get errorSelectAddress => '请在地图上选择您的地址。';

  @override
  String get personalInfoUpdated => '个人信息已更新。';

  @override
  String errorCouldNotSave(String error) {
    return '无法保存：$error';
  }

  @override
  String get errorSelectProgramme => '请选择您的课程。';

  @override
  String get errorSelectFaculty => '请选择您的学院。';

  @override
  String get errorSelectSemester => '请选择您的学期。';

  @override
  String get errorCgpaBlank => 'CGPA 不能为空。';

  @override
  String get errorInvalidCgpaRange => '请输入 0.00 至 4.00 之间的有效 CGPA。';

  @override
  String get academicInfoUpdated => '学术信息已更新。';

  @override
  String get skillsUpdated => '技能已更新。';

  @override
  String get addWorkExperience => '添加工作经验';

  @override
  String get editWorkExperience => '编辑工作经验';

  @override
  String get positionJobTitleLabel => '职位 / 职称';

  @override
  String get startYearHint => '例如：2023';

  @override
  String get startYearLabel => '开始年份';

  @override
  String get endYearLabel => '结束年份';

  @override
  String get iCurrentlyWorkHere => '我目前在此工作';

  @override
  String get descriptionOptionalLabel => '描述（可选）';

  @override
  String get errorPositionCompanyRequired => '职位和公司为必填项。';

  @override
  String get removeThisEntryTitle => '移除此条目？';

  @override
  String errorCouldNotRemove(String error) {
    return '无法移除：$error';
  }

  @override
  String get unknownCompany => '未知公司';

  @override
  String get unknownPosition => '未知职位';

  @override
  String get errorEnterCurrentPassword => '请输入您的当前密码。';

  @override
  String get errorNewPasswordsMismatch => '新密码不匹配。';

  @override
  String get errorInvalidResumeFormat => '该文件格式不被接受。仅允许 PDF 或 DOCX 文件。';

  @override
  String get errorFileTooLarge5mb => '文件过大。最大限制为 5MB。';

  @override
  String get resumeUploaded => '简历已上传。';

  @override
  String get autofillFromResumeTitle => '从简历自动填写？';

  @override
  String get resumeScanFoundDetailsNote =>
      '我们在您的简历中找到了以下信息。保存前请检查并编辑 — 不会自动保存任何内容。';

  @override
  String get parsedWithAi => '使用 AI 解析';

  @override
  String get parsedOffline => '离线解析';

  @override
  String get discard => '放弃';

  @override
  String get reviewAndApply => '检查并申请';

  @override
  String get fieldsFilledReviewNote => '以下字段已填写 — 请检查并点击保存（工作经验则点击添加）以确认。';

  @override
  String errorCouldNotOpenResumeColon(String error) {
    return '无法打开简历：$error';
  }

  @override
  String errorCouldNotRemoveResume(String error) {
    return '无法移除简历：$error';
  }

  @override
  String get prefApplicationUpdates => '申请更新';

  @override
  String get prefReportDeadlines => '报告截止日期';

  @override
  String get prefMessages => '消息';

  @override
  String get prefSupervisorFeedback => '主管反馈';

  @override
  String errorCouldNotSaveLanguage(String error) {
    return '无法保存语言：$error';
  }

  @override
  String errorCouldNotSaveTheme(String error) {
    return '无法保存主题：$error';
  }

  @override
  String get yourNamePlaceholder => '您的姓名';

  @override
  String get workExperience => '工作经验';

  @override
  String get selectYourProgrammeHint => '选择您的课程';

  @override
  String get selectYourFacultyHint => '选择您的学院';

  @override
  String get selectYourSemesterHint => '选择您的学期';

  @override
  String semesterNumber(int number) {
    return '第 $number 学期';
  }

  @override
  String get cgpaHint => '例如：3.62';

  @override
  String get noSkillsAddedYet => '尚未添加技能。';

  @override
  String get addSkillHint => '例如：HTML、CSS、Java、公开演讲';

  @override
  String get suggestedFromResume => '根据您的简历建议';

  @override
  String get present => '至今';

  @override
  String get dismiss => '关闭';

  @override
  String get noWorkExperienceAddedYet => '尚未添加工作经验。';

  @override
  String updatedOnDate(String date) {
    return '· 更新于 $date';
  }

  @override
  String get adminStudentsTitle => '学生';

  @override
  String get adminCompaniesTitle => '公司';

  @override
  String get adminSupervisorsTitle => '主管';

  @override
  String get adminMoreTitle => '更多';

  @override
  String get adminBrandLabel => 'CIMS 管理端';

  @override
  String adminWelcomeBack(String name) {
    return '欢迎回来，$name';
  }

  @override
  String get adminFallbackName => '管理员';

  @override
  String get adminSystemOverview => '系统概览';

  @override
  String get adminTotalStudents => '学生总数';

  @override
  String get adminActiveInternships => '进行中的实习';

  @override
  String get adminPartnerCompanies => '合作公司';

  @override
  String get adminNeedsAttention => '需要关注';

  @override
  String get adminAllClear => '一切正常 — 目前没有需要您关注的事项。';

  @override
  String adminStudentsUnassignedCount(int count) {
    return '$count 名学生未分配';
  }

  @override
  String get adminNoSupervisorAssignedYet => '尚未分配学术主管';

  @override
  String adminSubmissionsPendingReviewCount(int count) {
    return '$count 份提交待审核';
  }

  @override
  String get adminAwaitingReview => '等待主管或管理员审核';

  @override
  String get adminAddCompany => '添加公司';

  @override
  String get adminAssignSupervisor => '分配主管';

  @override
  String get adminRecentlyRegistered => '最近注册';

  @override
  String adminStudentRegisteredActivity(String name) {
    return '$name 已注册';
  }

  @override
  String get adminUnnamedStudent => '未命名学生';

  @override
  String get adminSearchCompaniesHint => '搜索公司...';

  @override
  String adminRegisteredCompaniesCount(int count) {
    return '$count 家注册公司';
  }

  @override
  String adminPendingVerificationCount(int count) {
    return '$count 家待验证';
  }

  @override
  String get adminNoCompaniesTitle => '没有公司';

  @override
  String get adminNoCompaniesDescription => '请尝试调整搜索条件，或添加一家公司。';

  @override
  String get adminLocationNotSet => '位置未设置';

  @override
  String get adminStatusPending => '待处理';

  @override
  String get adminStatusVerified => '已验证';

  @override
  String adminCouldNotVerify(String error) {
    return '无法验证：$error';
  }

  @override
  String get adminRemoveCompanyTitle => '移除公司？';

  @override
  String adminRemoveCompanyMessage(String name) {
    return '这将从名录中移除 $name。此操作无法撤销。';
  }

  @override
  String adminCouldNotRemove(String error) {
    return '无法移除：$error';
  }

  @override
  String get adminCompanyDetailsTitle => '公司详情';

  @override
  String get adminCompanyInformation => '公司信息';

  @override
  String get adminLocationLabel => '位置';

  @override
  String get adminHrContactLabel => '人事联系人';

  @override
  String get adminHrEmailLabel => '人事邮箱';

  @override
  String get adminHrPhoneLabel => '人事电话';

  @override
  String get adminStatusLabel => '状态';

  @override
  String get adminVerifyCompany => '验证公司';

  @override
  String get adminRemoveCompanyButton => '移除公司';

  @override
  String get adminCompanyNameRequired => '公司名称为必填项。';

  @override
  String adminCouldNotSave(String error) {
    return '无法保存：$error';
  }

  @override
  String get adminEditCompanyTitle => '编辑公司';

  @override
  String get adminCompanyNameLabel => '公司名称';

  @override
  String get adminIndustryLabel => '行业';

  @override
  String get adminOtherIndustryOption => '其他（在下方输入）';

  @override
  String get adminIndustryNameLabel => '行业名称';

  @override
  String get adminSelectLocation => '选择位置';

  @override
  String get adminHrContactSection => '人事联系人';

  @override
  String get adminHrContactNameLabel => '人事联系人姓名';

  @override
  String get adminHrEmailFieldLabel => '人事邮箱';

  @override
  String get adminHrPhoneNumberLabel => '人事电话号码';

  @override
  String get adminUnassign => '取消分配';

  @override
  String get adminUnnamed => '未命名';

  @override
  String adminCouldNotAssign(String error) {
    return '无法分配：$error';
  }

  @override
  String get adminSearchByNameHint => '按姓名搜索...';

  @override
  String get adminFilterAll => '全部';

  @override
  String get adminFilterAssigned => '已分配';

  @override
  String get adminFilterUnassigned => '未分配';

  @override
  String get adminNoStudentsFoundTitle => '未找到学生';

  @override
  String get adminNoStudentsFoundDescription => '请尝试调整您的搜索或筛选条件。';

  @override
  String get adminProgrammeNotSet => '尚未设置课程';

  @override
  String adminSupervisorColonName(String name) {
    return '主管：$name';
  }

  @override
  String get adminNoSupervisorAssigned => '未分配主管';

  @override
  String get adminAssign => '分配';

  @override
  String get adminSearchSupervisorsHint => '搜索主管...';

  @override
  String adminAcademicSupervisorsCount(int count) {
    return '$count 位学术主管';
  }

  @override
  String get adminNoSupervisorsFoundTitle => '未找到主管';

  @override
  String get adminNoSupervisorsFoundDescription => '尚未有学术主管账户注册。';

  @override
  String get adminFacultyNotSet => '学院未设置';

  @override
  String get adminThisSupervisorFallback => '此主管';

  @override
  String get adminPromoteToAdminTitle => '提升为管理员？';

  @override
  String adminPromoteToAdminMessage(String name) {
    return '$name 将立即成为系统管理员 — 其账户将在下次登录时获得完整管理员权限，并且不再出现在主管列表中。此操作无法在此撤销。';
  }

  @override
  String get adminPromote => '提升';

  @override
  String adminCouldNotPromote(String error) {
    return '无法提升：$error';
  }

  @override
  String get adminSupervisorDetailsTitle => '主管详情';

  @override
  String get adminPromoteToAdminButton => '提升为管理员';

  @override
  String get adminNoStudentsAssignedYet => '尚未分配学生。';

  @override
  String adminCouldNotSaveReview(String error) {
    return '无法保存审核：$error';
  }

  @override
  String adminCouldNotOpenFile(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get adminMonitorTitle => '监控';

  @override
  String get adminTabStudentProgress => '学生进度';

  @override
  String get adminTabReports => '报告';

  @override
  String get adminTabDocuments => '文件';

  @override
  String get adminNoStudentsTitle => '没有学生';

  @override
  String get adminNoStudentsRegisteredDescription => '尚未有学生注册。';

  @override
  String get adminSubmissionsAppearHere => '提交内容将显示在这里。';

  @override
  String get adminEnterCurrentPassword => '请输入您的当前密码。';

  @override
  String get adminNewPasswordsDoNotMatch => '新密码不匹配。';

  @override
  String get adminPasswordChanged => '密码已更改';

  @override
  String get adminLogOutConfirmMessage => '您需要重新登录才能访问管理控制台。';

  @override
  String get adminSystemAdministrator => '系统管理员';

  @override
  String get adminSectionOversight => '监督';

  @override
  String get adminMonitorSubtitle => '学生进度、报告与文件';

  @override
  String get adminDocumentTemplatesTitle => '文件模板';

  @override
  String get adminDocumentTemplatesSubtitle => '管理可填写的PDF表格（如家长确认书）';

  @override
  String get adminSectionCommunication => '通讯';

  @override
  String get adminMessagesSubtitle => '向学生、主管或公司发送消息';

  @override
  String get adminNotifications => '通知';

  @override
  String get adminNotificationsSubtitle => '查看系统提醒和更新';

  @override
  String get adminSectionPreferences => '偏好设置';

  @override
  String get adminNotifPrefsSubtitle => '选择您想接收的通知';

  @override
  String get adminSectionSystem => '系统';

  @override
  String get adminFullNameCannotBeBlank => '全名不能为空。';

  @override
  String get adminUnsupportedFileFormat => '不支持的文件格式。请上传 JPG、JPEG 或 PNG 图片。';

  @override
  String get adminPhotoEmptyError => '所选照片为空（0 字节）。请尝试其他照片。';

  @override
  String get adminPhotoNotFoundError => '在磁盘上找不到所选照片。';

  @override
  String adminUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get adminSourceCamera => '相机';

  @override
  String get adminSourceGallery => '相册';

  @override
  String adminCouldNotAccessSource(String source, String error) {
    return '无法访问$source：$error';
  }

  @override
  String adminCouldNotRemovePhoto(String error) {
    return '无法移除照片：$error';
  }

  @override
  String get cropPhotoTitle => '调整照片位置';

  @override
  String get cropPhotoConfirm => '完成';

  @override
  String get errorCropFailed => '无法裁剪照片，请重试。';

  @override
  String get clear => '清除';

  @override
  String parentWelcomeName(String name) {
    return '欢迎，$name';
  }

  @override
  String get parentWelcomeDefault => '欢迎，家长';

  @override
  String get parentDashboardSubtitle => '监督您孩子的实习进度';

  @override
  String get parentNoChildrenTitle => '尚未关联任何孩子';

  @override
  String get parentNoChildrenDescription =>
      '关联您孩子的账户以开始监督其实习进度。他们需要先批准请求，您才能查看任何信息。';

  @override
  String get parentLinkChildButton => '关联孩子';

  @override
  String get parentUnnamedStudent => '未命名学生';

  @override
  String get parentNoApplicationYet => '尚无实习申请';

  @override
  String get parentSignFormButton => '签署表格';

  @override
  String get parentProgressButton => '进度';

  @override
  String get parentStudentEmailLabel => '学生电子邮件';

  @override
  String get parentStudentEmailHint => '例如 john.doe';

  @override
  String get parentRelationshipLabel => '关系';

  @override
  String get parentRelationshipFather => '父亲';

  @override
  String get parentRelationshipMother => '母亲';

  @override
  String get parentRelationshipGuardian => '监护人';

  @override
  String get parentNoStudentFoundError => '找不到该电子邮件对应的学生。';

  @override
  String parentSearchError(String error) {
    return '无法搜索：$error';
  }

  @override
  String get parentSendRequestButton => '发送请求';

  @override
  String get parentRequestSentMessage => '请求已发送。学生需要批准该请求。';

  @override
  String parentSendRequestError(String error) {
    return '无法发送请求：$error';
  }

  @override
  String parentCancelRequestError(String error) {
    return '无法取消：$error';
  }

  @override
  String get parentYourRequestsTitle => '您的请求';

  @override
  String get parentNoRequestsYet => '尚未发送任何请求。';

  @override
  String parentAsRelationship(String relationship) {
    return '身份：$relationship';
  }

  @override
  String get parentUnknownStudent => '未知学生';

  @override
  String get parentProgressTitle => '实习进度';

  @override
  String get parentApplicationStatusTitle => '申请状态';

  @override
  String get parentNoApplicationSubmittedYet => '尚未提交实习申请。';

  @override
  String get parentUnknownCompany => '未知公司';

  @override
  String get parentAtAGlanceTitle => '概览';

  @override
  String get parentReportsSubmittedLabel => '已提交报告';

  @override
  String get parentDurationLabel => '时长';

  @override
  String get parentEvaluationTitle => '评估';

  @override
  String get parentNoEvaluationsYet => '尚未提交任何评估。';

  @override
  String get parentAcademicSupervisorEvaluation => '学术导师评估';

  @override
  String get parentCompanySupervisorEvaluation => '公司主管评估';

  @override
  String get parentRequiredDocumentsTitle => '所需文件';

  @override
  String get parentDocNotSubmitted => '尚未提交';

  @override
  String get parentMonthlyReportsTitle => '月度报告';

  @override
  String get parentNoMonthlyReportsYet => '尚未提交任何月度报告。';

  @override
  String get parentFinalReportTitle => '最终报告';

  @override
  String get parentNoFinalReportYet => '尚未提交最终报告。';

  @override
  String parentMonthlyReportLabel(String period) {
    return '月度报告 — $period';
  }

  @override
  String parentFinalReportLabel(String period) {
    return '最终报告 — $period';
  }

  @override
  String parentSubmittedDate(String date) {
    return '提交于 $date';
  }

  @override
  String get parentReadOnlyNotice => '这是只读视图。如有关于您孩子实习的疑问，请联系大学。';

  @override
  String get parentAcknowledgementTitle => '确认书';

  @override
  String get parentFormNotConfiguredError => '确认表格尚未设置。请联系大学。';

  @override
  String parentCouldNotLoadFormError(String error) {
    return '无法加载确认表格：$error';
  }

  @override
  String get parentTapToFillInstruction => '直接点击表格进行填写，然后在底部提交。';

  @override
  String get parentSignAndSubmitButton => '签署并提交';

  @override
  String get parentSignatureTimestampNote => '您的电子签名将附带时间戳记录。';

  @override
  String get parentDrawSignatureTitle => '绘制您的签名';

  @override
  String parentCouldNotSubmitError(String error) {
    return '无法提交表格：$error';
  }

  @override
  String parentCouldNotOpenFormError(String error) {
    return '无法打开表格：$error';
  }

  @override
  String get parentFormSubmittedTitle => '表格提交成功';

  @override
  String get parentFormSubmittedDescription => '您的确认书已记录。';

  @override
  String parentSignedOnDate(String date) {
    return '签署于 $date';
  }

  @override
  String get parentViewPdfButton => '查看PDF';

  @override
  String get parentBackToHomeButton => '返回主页';

  @override
  String get viewCompanyProfile => '查看公司简介';

  @override
  String get companyProfileTitle => '公司简介';

  @override
  String get companyProfileJobPostings => '职位发布';

  @override
  String get companyProfileNoPostings => '该公司尚未发布任何职位。';

  @override
  String get companyProfilePastInterns => '历届实习生';

  @override
  String companyProfileInternCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已有$count名学生在此实习',
    );
    return '$_temp0';
  }

  @override
  String get companyProfileReviews => '评价';

  @override
  String companyProfileReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count则评价',
    );
    return '$_temp0';
  }

  @override
  String get companyProfileNoReviewsYet => '暂无评价。成为第一个分享经验的人吧。';

  @override
  String get companyProfileWriteReview => '撰写评价';

  @override
  String get companyProfileEditReview => '编辑您的评价';

  @override
  String get companyProfileRatingLabel => '您的评分';

  @override
  String get companyProfileReviewHint => '分享您在这里工作的经验（选填）';

  @override
  String get companyProfileReviewSubmitted => '评价已提交，谢谢！';

  @override
  String companyProfileReviewError(String error) {
    return '无法提交评价：$error';
  }

  @override
  String get companyProfileMustApplyNote => '只有申请过该公司的学生才能发表评价。';
}
