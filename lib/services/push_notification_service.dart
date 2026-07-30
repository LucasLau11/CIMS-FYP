import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'auth_service.dart';
import 'student_data_service.dart';
import '../screens/student/student_messages_screen.dart' show ChatScreen;
import '../screens/student/student_notifications_screen.dart' show StudentNotificationsScreen;

/// Wraps the OneSignal SDK: initialization, linking/unlinking the signed-in
/// Supabase user to this device, and routing a notification tap to the
/// right screen. OneSignal's click callback fires outside the widget tree,
/// so navigation here goes through [navigatorKey] rather than a BuildContext.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _oneSignalAppId = 'REPLACE_WITH_ONESIGNAL_APP_ID';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initialize() {
    OneSignal.initialize(_oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addClickListener(_handleNotificationClick);
  }

  Future<void> linkUser(String userId) async {
    try {
      await OneSignal.login(userId);
    } catch (_) {
      // Non-fatal — push linking failing shouldn't block sign-in.
    }
  }

  Future<void> unlinkUser() async {
    try {
      await OneSignal.logout();
    } catch (_) {
      // Non-fatal — should still be able to sign out of Supabase.
    }
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    // A tap can arrive before Supabase has restored a session (cold start)
    // — nothing sensible to navigate to yet, so just drop it. The user
    // will still see it in the in-app notifications list once signed in.
    if (AuthService.instance.currentUserId == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final data = event.notification.additionalData;
    final conversationId = data?['conversation_id'] as String?;
    if (conversationId != null) {
      _openConversation(navigator, conversationId);
      return;
    }
    navigator.push(MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()));
  }

  Future<void> _openConversation(NavigatorState navigator, String conversationId) async {
    try {
      final conversation = await StudentDataService.instance.getConversationById(conversationId);
      final otherProfile = conversation['other_profile'] as Map<String, dynamic>;
      navigator.push(MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: conversationId, otherProfile: otherProfile),
      ));
    } catch (_) {
      navigator.push(MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()));
    }
  }
}
