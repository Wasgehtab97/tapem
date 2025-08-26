import UIKit
import Flutter

import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Push / Notifications (iOS 10+)
    let center = UNUserNotificationCenter.current()
    center.delegate = self

    center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
      // optional: handle result
    }

    // APNs-Registrierung NUR auf echtem Gerät
    #if !targetEnvironment(simulator)
    DispatchQueue.main.async {
      application.registerForRemoteNotifications()
    }
    #endif

    // FCM-Delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: APNs Token → FCM
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNs registration failed: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // MARK: FCM Registration Token
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: ["token": fcmToken ?? ""]
    )
  }

  // MARK: Foreground-Notifications (iOS 10+)
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // MARK: Tap auf Notification (iOS 10+)
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
