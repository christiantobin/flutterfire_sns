# Mobile Push Notifications

The flutter application needs to be registered with Google Firebase Cloud Messaging.
Once registered, you can use the Google API Key to register the platform with AWS SNS.

Every device has a unique mobile ID which is then sent to Firebase Cloud Messaging (FCM) for registration, a FCM Token then gets returned.
This FCM token needs to be sent to AWS SNS to create a PlatformEndpoint which gets stored in SNS.

## Android

Android Flutter applications have notifications permission set to allowed by default so registration should be requested for SNS subscription within the app to store the token with SNS

## iOS

You can use a FCM API to call for notifications permission which will bring up the native iOS permissions dialog for the user. Once accepted, the token can be generated and sent to SNS. An Apple Developer Account is required to enable this feature for applications and a certificate produced by Apple must be generated and registered for FCM to integrate the push notification service with FCM.
