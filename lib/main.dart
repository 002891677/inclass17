import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

/// Background message handler (must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolates
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Just logging for background – this won’t show UI
  print('⚙️ Background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  const MessagingTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class NotificationItem {
  final String title;
  final String body;
  final String type; // "regular" or "important"

  NotificationItem({
    required this.title,
    required this.body,
    required this.type,
  });
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging _messaging;
  String? _token;
  final List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Ask for permission (iOS/macOS; safe for Android too)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permission: ${settings.authorizationStatus}');

    // Subscribe to topic (optional, matches assignment)
    await _messaging.subscribeToTopic("messaging");

    // Get FCM token
    _messaging.getToken().then((value) {
      setState(() {
        _token = value;
      });
      print('📱 FCM Token: $value');
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("💬 Foreground message received");
      _handleMessage(message);
    });

    // When app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Notification clicked!');
      _handleMessage(message);
    });

    // If app opened from terminated state via notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final String type = (data['type'] ?? 'regular').toString(); // custom key
    final String title = notification?.title ?? 'New Notification';
    final String body = notification?.body ?? '';

    print('🔎 Notification type: $type');
    print('Data payload: ${message.data}');

    setState(() {
      _notifications.insert(
        0,
        NotificationItem(title: title, body: body, type: type),
      );
    });

    // Show dialog with different styling for important vs regular
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isImportant = type.toLowerCase() == 'important';
        return AlertDialog(
          backgroundColor: isImportant
              ? Colors.red.shade50
              : Colors.blue.shade50,
          title: Text(
            isImportant
                ? "🔥 Important Notification"
                : "📩 Regular Notification",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isImportant ? Colors.red : Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(body),
              const SizedBox(height: 12),
              Text(
                "Type: $type",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isImportant ? Colors.red : Colors.blueGrey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Color _cardColor(String type) {
    if (type.toLowerCase() == 'important') {
      return Colors.red.shade50;
    }
    return Colors.blue.shade50;
  }

  Color _borderColor(String type) {
    if (type.toLowerCase() == 'important') {
      return Colors.red;
    }
    return Colors.blue;
  }

  IconData _iconForType(String type) {
    if (type.toLowerCase() == 'important') {
      return Icons.priority_high;
    }
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Firebase Messaging')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Token card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your FCM Token:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _token == null
                        ? const Text("Generating token...")
                        : SelectableText(
                            _token!,
                            style: const TextStyle(fontSize: 12),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Received Notifications",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No notifications yet. Send one from Firebase Console.",
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        final isImportant =
                            item.type.toLowerCase() == 'important';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _borderColor(item.type),
                              width: 1.5,
                            ),
                          ),
                          color: _cardColor(item.type),
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: ListTile(
                            leading: Icon(
                              _iconForType(item.type),
                              color: isImportant
                                  ? Colors.redAccent
                                  : Colors.blue,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isImportant
                                    ? Colors.red.shade700
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(item.body),
                                const SizedBox(height: 4),
                                Text(
                                  'Type: ${item.type}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
