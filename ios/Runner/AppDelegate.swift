import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import FirebaseAppCheck
import UserNotifications

// App Attest/DeviceCheck provider factory for Firebase App Check
class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
          if #available(iOS 14.0, *) {
                  return AppAttestProvider(app: app)
                } else {
                  return DeviceCheckProvider(app: app)
                }
        }
  }

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    override func application(
          _ application: UIApplication,
          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
          // Configure Firebase
          FirebaseApp.configure()

          // Configure Firebase App Check to use App Attest or Device Check depending on availability
          let providerFactory = AppAttestProviderFactory()
          AppCheck.setAppCheckProviderFactory(providerFactory)

          // Set the messaging delegate to receive FCM token updates
          Messaging.messaging().delegate = self

          // Register for remote notifications
          UNUserNotificationCenter.current().delegate = self
          application.registerForRemoteNotifications()

          GeneratedPluginRegistrant.register(with: self)
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

    // Called when FCM token is updated. Send token to application server if needed.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
          print("FCM registration token: \(fcmToken ?? "")")
        }
  }
