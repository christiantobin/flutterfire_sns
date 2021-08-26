import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import './device_form.dart';

// Android Notification Channel for Local Notification
// This allows the heads up notification to appear while the app is both in the background and foreground
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    'This channel is used for important notifications.', // description
    importance: Importance.max,
    playSound: true);

// For Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background Message Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background Message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // iOS Notification Permission Settings
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // todo: iOS permissions
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Push Notifications Test'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Listens for incoming messages and routes to the appropriate Android Channel
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
    });

    // Displays the notifications when a user taps on the push notification, opening the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title ?? ""),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(notification.body ?? "")],
                  ),
                ),
              );
            });
      }
    });
    getFCMToken();
  }

  // Get FCM token (android only)
  // In order to receive the iOS formatted token, use .getAPNSToken() method.
  Future<void> getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("Firebase token = " + (token ?? ""));
  }

  Future<void> subscribe() async {
    var token;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      token = await FirebaseMessaging.instance.getAPNSToken();
      print('APNs Token: $token');
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      token = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $token');
    }
    var headers = {'Content-Type': 'application/json'};
    var url = Uri.parse(
        'https://0t52mixuj9.execute-api.us-east-1.amazonaws.com/prod/register');

    var data = {'token': token};
    var body = convert.jsonEncode(data);
    var response = await http.post(url, headers: headers, body: body);
    print(data);
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    // Navigator.of(context).pop();
  }

  Future<void> unsubscribe() async {
    print('This should delete the platformEndPoint');
  }

  // Future<void> subscribeDevice() async {
  //   print('This should send IoT Date to register and subscribe to');
  //   var url = Uri.parse(
  //       'https://0t52mixuj9.execute-api.us-east-1.amazonaws.com/prod/update');

  //   var data = {
  //     "serial": 'test',
  //     "payload": {
  //       "state": {
  //         "desired": {"heatTo": 100}
  //       }
  //     }
  //   };

  //   var body = convert.jsonEncode(data);

  //   var headers = {'Content-Type': 'application/json'};

  //   var response = await http.put(url, headers: headers, body: body);
  //   print('Response Status: ${response.statusCode}');
  //   print('Response Body: ${response.body}');
  // }

  Future<void> onActionSelected(String value) async {
    switch (value) {
      case 'unsubscribe':
        {
          await unsubscribe();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () => askPermissions(context));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: onActionSelected,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'subscribe',
                  child: Text('Subscribe to SNS'),
                ),
                const PopupMenuItem(
                  value: 'unsubscribe',
                  child: Text('Unsubscribe to SNS'),
                ),
              ];
            },
          ),
        ],
      ),
      body: DeviceForm(),
    );
  }

  void askPermissions(BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Push Notification Subscription"),
          content:
              new Text("Would you like to subscribe to push notifications?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new TextButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new TextButton(
              child: new Text("Subscribe"),
              onPressed: () {
                subscribe();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
