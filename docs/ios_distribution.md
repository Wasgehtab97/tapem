# iOS Distribution Guide

## Inviting Internal TestFlight Testers
1. Archive and upload the app to App Store Connect.
2. In App Store Connect, navigate to *TestFlight* and add internal users from the *Users and Access* section.
3. Assign the latest build to the testers and send them an invitation.

## Resolving CocoaPods Issues
If `pod install` fails:
1. Run `pod deintegrate` inside the `ios/` directory.
2. Remove the `Podfile.lock` and `Pods/` folder if they remain.
3. Execute `pod install` again.

## Push Notifications & App Check
- Confirm that APNs certificates or keys are configured in Apple Developer Center and App Store Connect.
- Verify that the Firebase Cloud Messaging token is received in `messaging(_:didReceiveRegistrationToken:)`.
- For App Check, ensure the chosen provider (e.g. App Attest or Device Check) is correctly set up in Firebase.

## NFC Limitations
NFC is available only on compatible devices (iPhone 7 or later) and requires the device to be unlocked.

## Collecting UDIDs for Ad-Hoc Builds
As an alternative to TestFlight, you can distribute ad-hoc builds:
1. Collect device UDIDs from testers.
2. Add the UDIDs to your provisioning profile in the Apple Developer portal.
3. Generate and distribute the IPA built with the ad-hoc profile.

