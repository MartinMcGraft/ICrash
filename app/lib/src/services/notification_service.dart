/// Placeholder contract (spec section 50). The prototype only needs
/// in-app/local notifications; keeping the interface separate means a later
/// commercial version can swap in FCM/Cloud Functions-backed delivery
/// without touching callers.
abstract class NotificationService {
  Future<void> showLocalNotification({required String title, required String body});
}
