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

  static const String _oneSignalAppId = '4f4d4c81-bf4d-423e-9473-b742fe3e5070';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initialize() {
    OneSignal.initialize(_oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addClickListener(_handleNotificationClick);
  }

  Future<void> linkUser(String userId) async {
    try {
      await OneSignal.login(userId);
      // OneSignal can only reach a device whose subscription is opted in. After
      // a refused permission prompt, or a log out and in as someone else, it may
      // not be, and every push for this person is then dropped ("unsubscribed").
      await OneSignal.User.pushSubscription.optIn();
      if (!OneSignal.Notifications.permission) {
        await OneSignal.Notifications.requestPermission(false);
      }
    } catch (_) {
      // Non-fatal — push linking failing shouldn't block sign-in.
    }
  }

  /// Whether this phone currently lets CIMS show notifications. When it does
  /// not, no alert ever appears outside the app, whatever the server sends.
  bool get notificationsAllowed {
    try {
      return OneSignal.Notifications.permission;
    } catch (_) {
      return true; // cannot tell (for example in tests): do not nag
    }
  }

  /// Asks again; if the phone has already refused, it offers to open the app's
  /// notification settings. Returns whether notifications are now allowed.
  Future<bool> enableNotifications() async {
    try {
      await OneSignal.Notifications.requestPermission(true);
      await OneSignal.User.pushSubscription.optIn();
    } catch (_) {}
    return notificationsAllowed;
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
