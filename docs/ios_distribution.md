# iOS Distribution Guide

## TestFlight Internal Testing
1. Create an App Store Connect record.
2. Upload a build (see workflow `ios_testflight.yml`).
3. In App Store Connect, add users under **TestFlight > Internal Testing**.
4. Each tester installs the TestFlight app and accepts the invitation.

## Handling CocoaPods Issues
If `pod install` fails:
1. From the `ios` folder run `pod deintegrate`.
2. Remove the `Pods/` directory and `Podfile.lock`.
3. Run `pod install` again.

## Troubleshooting
- **Push Notifications** – Ensure APNs certificates/keys are valid and `application.registerForRemoteNotifications()` is called.
- **App Check** – Debug builds can use `AppCheckDebugProviderFactory`. Production builds require a real provider such as DeviceCheck.
- **NFC** – iOS only reads NDEF tags; other formats are unsupported. Devices without NFC cannot scan tags.

## UDID Collection & Ad-Hoc Distribution
As an alternative to TestFlight:
1. Collect device UDIDs from testers.
2. Add the UDIDs in the Apple Developer portal and create an Ad-Hoc provisioning profile.
3. Build the IPA using this profile and share it directly with testers.

