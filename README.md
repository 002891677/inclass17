InClass17 – Firebase Cloud Messaging Demo

This project is a simple Flutter app that demonstrates Firebase Cloud Messaging (FCM).
The app displays the device’s FCM token and shows a list of received notifications.

Features

Initializes Firebase using firebase_core and firebase_messaging

Retrieves and displays the FCM token

Receives push notifications while app is in foreground / background

Distinguishes between:

Regular notifications (type = regular)

Important notifications (type = important)

Shows different dialog styles and card colors for regular vs important messages

How to Run
flutter pub get
flutter run


Make sure the project is connected to your Firebase project (firebase_options.dart generated via flutterfire configure).

Sending Test Notifications

Go to Firebase Console → Cloud Messaging.

Create a new notification.

Use the FCM token shown in the app as the target.

Under custom data:

For regular notification: type = regular

For important notification: type = important

Send and verify the notification appears in the app list with proper styling.
