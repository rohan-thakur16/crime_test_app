import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
void main() {
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
      home: DefaultTabController(
        length: 2,
        child: CrimeAlertMap(),
      ),
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
  LatLng userLocation = const LatLng(52.629729, -1.131592); // Initial user location
  Map<String, List<dynamic>> crimes = {}; // Map to store the crimes
  String _selectedCrimeCategory = 'default'; // Initial value
  int _currentPage = 0; // Initial page
  int _numCrimesToDisplay = 5; // Number of crimes per page
  int _numCrimes = 0; // Counter for the number of crimes
  Marker? _highlightedMarker;
  MarkerId? _selectedMarkerId;

  @override
  void initState() {
    super.initState();
    _getCrimes();
    _getUserLocation();
  }
  Set<Circle> circles = {
    Circle(
      circleId: CircleId("circle_1"),
      center: LatLng(52.629729, -1.131592), // same position as the marker
      radius: 100,
      strokeWidth: 2,
      strokeColor: Colors.red,
      fillColor: Colors.red.withOpacity(0.1),
    ),
  };
  void _getCrimes() async {
    try {
      String url = 'https://data.police.uk/api/crimes-street/all-crime?lat=${userLocation.latitude}&lng=${userLocation.longitude}';

      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> crimesFromApi = jsonDecode(response.body);
        if (_selectedCrimeCategory != 'default') {
          crimesFromApi = crimesFromApi.where((crime) => crime['category'] == _selectedCrimeCategory).toList();
        }
        int start = _currentPage * _numCrimesToDisplay;// Calculate the start and end indices based on the current page number
        int end = min(start + _numCrimesToDisplay, crimesFromApi.length);
        crimesFromApi = crimesFromApi.sublist(start, end);
        markers = _createMarkers(crimesFromApi);
        _numCrimes = markers.length; // Update the counter
        // Store the crimes in the Map
        for (dynamic crime in crimesFromApi) {
          String latitude = crime['location']['latitude'];
          if (crimes.containsKey(latitude)) {
            crimes[latitude]!.add(crime);
          } else {
            crimes[latitude] = [crime];
          }
        }
        print('crime alert is here');
        setState(() {});
      }
    } catch (e) {
      print('An error occurred while fetching crimes: $e');
    }
  }

  Set<Marker> _createMarkers(List<dynamic> crimes) {
    Set<Marker> markers = {};
    circles.clear(); // Clear the circles set before creating new circles
    for (dynamic crime in crimes) {
      double latitude = double.parse(crime['location']['latitude']);
      double longitude = double.parse(crime['location']['longitude']);
      Marker detailMarker = Marker(
        markerId: MarkerId(crime['id'].toString()),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: crime['category'],
          snippet: 'Date: ${crime['month']}\nStreet: ${crime['location']['street']['name']}', // Add more details as needed
          onTap: () => _showCrimeDetails(crime), // Show the dialog when the InfoWindow is tapped
        ),
      );

      // Create a circle for each crime
      Circle detailCircle = Circle(
        circleId: CircleId('circle_${crime['id']}'),
        center: LatLng(latitude, longitude),
        radius: 100,
        strokeWidth: 2,
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.1),
      );

      markers.add(detailMarker);
      circles.add(detailCircle);
      setState(() {}); // Update the state to reflect the new markers and circles
    }
    return markers;
  }

  Future<BitmapDescriptor> _getMarkerImageFromAsset(String assetPath) async {
    const ImageConfiguration imageConfiguration = ImageConfiguration(size: Size(528, 528)); // Set the size of the image
    final BitmapDescriptor bitmapDescriptor = await BitmapDescriptor.fromAssetImage(imageConfiguration, assetPath);
    return bitmapDescriptor;
  }

  Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))?.buffer.asUint8List();
  }


  Future<void> _getUserLocation() async {
  //  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
   // double latitude = position.latitude==null? 52.629729:position.latitude;
    double latitude=52.629729;
    double longitude = -1.131592;
    final Uint8List? markerIcon = await getBytesFromAsset('assets/location.png', 120);

    setState(() {
      print("user location");
      // print(position.latitude);
      userLocationMarker =   userLocationMarker = {
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.fromBytes(markerIcon!),
        ),
      };
    });
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _getCrimes();
      });
    }
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
      _getCrimes();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _showCrimeDetails(dynamic crime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(crime['category']),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Date: ${crime['month']}'),
                Text('Street: ${crime['location']['street']['name']}'),
                // Add more details as needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent,
      bottomNavigationBar:
      Container(
        color: Colors.red,
        child: const TabBar(

          tabs: [
            Tab(icon: Icon(Icons.map_outlined,color: Colors.white,)),
            Tab(icon: Icon(Icons.notifications,color: Colors.white)),
          ],
        ),
      ),
      // backgroundColor: Colors.red,
      appBar: AppBar(

        backgroundColor: Colors.red,
        title: const Center(child: Text('Crime Alert',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black87),)),

        // bottom: const
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Text(
                'Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.filter_list),
              title: DropdownButton<int>(
                value: _numCrimesToDisplay,
                items: [5, 10].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('Display recent $value Crimes'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _numCrimesToDisplay = newValue;
                      _getCrimes(); // Fetch the crimes again with the new filter
                      Navigator.pop(context); // Close the drawer
                    });
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: DropdownButton<String>(
                value: _selectedCrimeCategory,
                items: ['default', 'anti-social-behaviour', 'bicycle-theft', 'burglary', 'criminal-damage-arson'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCrimeCategory = newValue;
                      _getCrimes(); // Fetch the crimes again with the new filter
                      Navigator.pop(context); // Close the drawer
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        physics: NeverScrollableScrollPhysics(), // Add this line
        children: [
          Stack(
            children: [
              GoogleMap(
                circles: circles,
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: userLocation,
                  zoom: 15.0,
                  tilt: 60.0,
                ),
                markers: {...markers, ...userLocationMarker},
              ),
              Positioned(
               bottom: 10,
                child: Container(
                  color: Colors.grey,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: _previousPage,
                      ),
                      Text('Page $_currentPage'),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: _nextPage,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  height: 20,
                  color: Colors.grey,
                  child: Text('Selected Crime Category: $_selectedCrimeCategory'),
                ),
              ),
            ],
          ),
          ListView(
            children: crimes.entries.expand((entry) {
              String latitude = entry.key;
              List<dynamic> crimesAtLatitude = _selectedCrimeCategory == 'default' ? entry.value : entry.value.where((crime) => crime['category'] == _selectedCrimeCategory).toList();  // Filter the crimes by category
              if (crimesAtLatitude.isNotEmpty) { // Only include crimes with a count greater than 0
                return [
                  ExpansionTile(
                    title: Text('No of Crimes reported: ${crimesAtLatitude.length}'),
                    children: crimesAtLatitude.map((crime) {
                      String category = crime['category'];
                      String date = crime['month'];
                      String streetName = crime['location']['street']['name']; // Get the street name
                      double latitude = double.parse(crime['location']['latitude']);
                      double longitude = double.parse(crime['location']['longitude']);
                      return ListTile(
                        title: Text(category),
                        subtitle: Text('Date: $date, Street: $streetName'), // Display the street name
                        onTap: () {
                          _selectedMarkerId = MarkerId(crime['id'].toString());
                          _mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(latitude, longitude),
                                zoom: 100.0, // Increase the zoom level
                              ),
                            ),
                          );

                          // Reset the color of the currently highlighted marker
                          if (_highlightedMarker != null) {
                            Marker resetMarker = Marker(
                              markerId: _highlightedMarker!.markerId,
                              position: _highlightedMarker!.position,
                              icon: BitmapDescriptor.defaultMarker, // Reset the color to the default
                              infoWindow: _highlightedMarker!.infoWindow,
                            );
                            markers.remove(_highlightedMarker);
                            markers.add(resetMarker);
                          }

                          // Highlight the new marker
                          MarkerId selectedMarkerId = MarkerId(crime['id'].toString());
                          Marker selectedMarker = markers.firstWhere((marker) => marker.markerId == selectedMarkerId);
                          Marker highlightedMarker = Marker(
                            markerId: selectedMarkerId,
                            position: selectedMarker.position,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Change the color of the marker
                            infoWindow: selectedMarker.infoWindow,
                          );

                          // Update the markers set and the highlighted marker
                          setState(() {
                            markers.remove(selectedMarker);
                            markers.add(highlightedMarker);
                            _highlightedMarker = highlightedMarker;
                            if (_selectedMarkerId != null) {
                              Future.delayed(Duration(milliseconds: 500)).then((_) {
                                _mapController.showMarkerInfoWindow(_selectedMarkerId!);
                                _selectedMarkerId = null;
                              });
                            }
                          });

                          DefaultTabController.of(context)!.animateTo(0); // Switch to the map tab
                        },
                      );
                    }).toList(),
                  ),
                ];
              } else {
                return const Iterable<ExpansionTile>.empty(); // Return an empty iterable if the count is 0
              }
            }).toList(),
          ),
        ],
      ),
    );
  }
}
