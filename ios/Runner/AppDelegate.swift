import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseAppCheck
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM token: \(fcmToken ?? "")")
  }
}
