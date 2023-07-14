import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(CrimeAlertApp());
}

class CrimeAlertApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crime Alert',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CrimeAlertMap(),
    );
  }
}

class CrimeAlertMap extends StatefulWidget {
  @override
  _CrimeAlertMapState createState() => _CrimeAlertMapState();
}

class _CrimeAlertMapState extends State<CrimeAlertMap> {
  late GoogleMapController _mapController;
  Set<Marker> markers = {};
  Set<Marker> userLocationMarker = {};
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  double _currentZoom = 8.0;
  double _maxZoom = 20.0;
  double _minZoom = 5.0;
  final List<double> _zoomOptions = [5.0, 10.0, 15.0, 20.0];
  int _currentIndex = 0;

  final Set<Polygon> polygons = {
    Polygon(
      polygonId: const PolygonId('danger_area'),
      points: const[
        LatLng(55.9296, -4.3862),
        LatLng(55.866, -4.2519),
        LatLng(55.855, -4.389),
        LatLng(55.867, -4.398),
      ],
      fillColor: Colors.red.withOpacity(0.5),
      strokeColor: Colors.red,
      strokeWidth: 2,
    ),
  };

  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    _configureFirebaseMessaging();
    _getCrimes();
    _getUserLocation();
    _initializeNotifications();
  }

  void _configureFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
      _addNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotification(message);
    });

    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _showNotification(RemoteMessage message) async {
    print('Received notification:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'crime_alert_channel',
      'Crime Alert Channel',
      // 'Channel for Crime Alert notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  void _handleNotification(RemoteMessage message) {
    print('Received notification:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    // final IOSInitializationSettings initializationSettingsIOS =
    // IOSInitializationSettings();

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsIOS,
    );

    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _getCrimes() async {
    try {
      String url =
          'https://data.police.uk/api/crimes-street/all-crime?poly=55.9296,-4.3862:55.866,-4.2519:55.855,-4.389:55.867,-4.398';
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> crimes = jsonDecode(response.body);
        markers = _createMarkers(crimes);
        print('crime alert is here');
        setState(() {});
      }
    } catch (e) {
      print('An error occurred while fetching crimes: $e');
    }
  }

  Set<Marker> _createMarkers(List<dynamic> crimes) {
    Set<Marker> markers = {};

    for (dynamic crime in crimes) {
      double latitude = double.parse(crime['location']['latitude']);
      double longitude = double.parse(crime['location']['longitude']);
      Marker detailMarker = Marker(
        markerId: MarkerId(crime['id'].toString()),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: crime['category'],
          snippet: 'Date: ${crime['month']}',
        ),
      );
      markers.add(detailMarker);
    }

    return markers;
  }

  void _updateZoom() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(55.8642, -4.2518),
          zoom: _currentZoom,
        ),
      ),
    );
  }

  String _getZoomLabel() {
    if (_currentZoom <= _zoomOptions[0]) {
      return '5 miles';
    } else if (_currentZoom <= _zoomOptions[1]) {
      return '10 miles';
    } else if (_currentZoom <= _zoomOptions[2]) {
      return '15 miles';
    } else {
      return '20 miles';
    }
  }

  void _updateUserLocation(Position position) {
    setState(() {
      userLocationMarker = {
        Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(position.latitude, position.longitude),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    });
  }

  void _getUserLocation() async {
    double latitude = 55.860916;
    double longitude = -4.251433;

    setState(() {
      userLocationMarker = {
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueMagenta),
        ),
      };
    });
  }

  void _addNotification(RemoteMessage message) {
    setState(() {
      notifications.add(message.notification?.title ?? '');
    });
  }
  String latitude='55.860916';
  void _goToMarker(latitude) {
    Marker? selectedMarker;

    for (var marker in markers) {
      if (marker.infoWindow.snippet == '$latitude') {
        selectedMarker = marker;
        break;
      }
    }

    if (selectedMarker != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: selectedMarker.position,
            zoom: _currentZoom,
          ),
        ),
      );
    } else {
      print('Marker not found for the given latitude: $latitude');
    }
  }

  double _calculateDistance(double latitude) {
    final double targetLatitude = 55.860916; // Change it to the desired latitude
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1Rad = latitude * (3.141592653589793 / 180);
    double lat2Rad = targetLatitude * (3.141592653589793 / 180);
    double deltaLatRad = (targetLatitude - latitude) * (3.141592653589793 / 180);
    double deltaLonRad = 0 * (3.141592653589793 / 180); // Change 0 to the desired longitude difference

    double a = pow(sin(deltaLatRad / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(deltaLonRad / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }


  Future<List<Map<String, dynamic>>?> _fetchDataa() async {
    const url =
        'https://data.police.uk/api/crimes-street/all-crime?poly=55.9296,-4.3862:55.866,-4.2519:55.855,-4.389:55.867,-4.398';
    http.Response response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<Map<String, dynamic>> items = data.map<Map<String, dynamic>>((item) {
        double latitude = double.parse(item['location']['latitude']);
        double distance = _calculateDistance(latitude);
        return {
          'category': item['category'],
          'latitude': latitude,
          'distance': distance,
        };
      }).toList();

      return items;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    switch (_currentIndex) {
      case 0:
        currentScreen = Scaffold(
          appBar: AppBar(
            title: const Text('Crime Alert Map'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        setState(() {
                          _mapController = controller;
                        });
                      },
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(55.8642, -4.2518),
                        zoom: 12.0,
                      ),
                      markers: {...markers, ...userLocationMarker},
                      polygons: polygons,
                    ),
                    Positioned(
                      bottom: 16.0,
                      left: 16.0,
                      right: 16.0,
                      child: Slider(
                        value: _currentZoom,
                        min: _minZoom,
                        max: _maxZoom,
                        onChanged: (value) {
                          setState(() {
                            _currentZoom = value;
                          });
                          _updateZoom();
                        },
                        divisions: _zoomOptions.length - 1,
                        label: _getZoomLabel(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;
      case 1:
        currentScreen = Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            centerTitle: true,
          ),
          body: FutureBuilder<List<Map<String, dynamic>>?>(
            future: _fetchDataa(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<Map<String, dynamic>> data = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final List<String> items =
                    List<String>.generate(10, (i) => '$i');
                    return GestureDetector(
                      onTap: () =>
                          _goToMarker(data[index]['latitude'].toString()),
                      child: ListTile(
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Text(
                            items[index],
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text('${data[index]['category']}'),
                        subtitle: Text(
                          'Distance: ${data[index]['distance'].toStringAsFixed(2)} miles away from you',
                        ),
                        trailing: const Icon(Icons.more_vert),
                      ),
                    );
                  },
                );
              }
            },
          ),
        );
        break;
      default:
        currentScreen = Container();
        break;
    }

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
