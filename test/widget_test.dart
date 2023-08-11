import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'lib/main.dart';
import 'package:http/http.dart' as http;

void main() {
  group('CrimeData model', () {
    test('fromJson creates a CrimeData', () {
      final crimeDataJson = {
        'id': 123,
        'category': 'robbery',
        'month': '2023-08',
        'location': {
          'latitude': '51.5074',
          'longitude': '0.1278',
          'street': {
            'id': 456,
            'name': 'Baker Street',
          }
        },
      };

      final crimeData = CrimeData.fromJson(crimeDataJson);

      expect(crimeData.id, 123);
      expect(crimeData.category, 'robbery');
      expect(crimeData.month, '2023-08');
      expect(crimeData.location.latitude, '51.5074');
      expect(crimeData.location.longitude, '0.1278');
      expect(crimeData.location.street.id, 456);
      expect(crimeData.location.street.name, 'Baker Street');
    });


    // 2 nd test case

    test('fromJson handles null values', () {
      final crimeDataJson = {
        'id': null,
        'category': null,
        'month': null,
        'location': null,
      };

      final crimeData = CrimeData.fromJson(crimeDataJson);

      expect(crimeData.id, 0);
      expect(crimeData.category, '');
      expect(crimeData.month, '');
      expect(crimeData.location.latitude, '');
      expect(crimeData.location.longitude, '');
      expect(crimeData.location.street.id, 0);
      expect(crimeData.location.street.name, '');
    });


    test('toJson creates a valid map', () {
      final crimeData = CrimeData(
        id: 123,
        category: 'robbery',
        month: '2023-08',
        location: Location(
          latitude: '51.5074',
          longitude: '0.1278',
          street: Street(
            id: 456,
            name: 'Baker Street',
          ),
        ),
      );

      final crimeDataJson = crimeData.toJson();

      expect(crimeDataJson['id'], 123);
      expect(crimeDataJson['category'], 'robbery');
      expect(crimeDataJson['month'], '2023-08');
      expect(crimeDataJson['location']['latitude'], '51.5074');
      expect(crimeDataJson['location']['longitude'], '0.1278');
      expect(crimeDataJson['location']['street']['id'], 456);
      expect(crimeDataJson['location']['street']['name'], 'Baker Street');
    });
  });

  group('Location model', () {
    test('fromJson creates a Location', () {
      final locationJson = {
        'latitude': '51.5074',
        'longitude': '0.1278',
        'street': {
          'id': 456,
          'name': 'Baker Street',
        },
      };

      final location = Location.fromJson(locationJson);

      expect(location.latitude, '51.5074');
      expect(location.longitude, '0.1278');
      expect(location.street.id, 456);
      expect(location.street.name, 'Baker Street');
    });

    test('fromJson handles null values', () {
      final locationJson = {
        'latitude': null,
        'longitude': null,
        'street': null,
      };

      final location = Location.fromJson(locationJson);

      expect(location.latitude, '');
      expect(location.longitude, '');
      expect(location.street.id, 0);
      expect(location.street.name, '');
    });



    test('toJson creates a valid map', () {
      final location = Location(
        latitude: '51.5074',
        longitude: '0.1278',
        street: Street(
          id: 456,
          name: 'Baker Street',
        ),
      );

      final locationJson = location.toJson();

      expect(locationJson['latitude'], '51.5074');
      expect(locationJson['longitude'], '0.1278');
      expect(locationJson['street']['id'], 456);
      expect(locationJson['street']['name'], 'Baker Street');
    });
  });

  group('Street model', () {
    test('fromJson creates a Street', () {
      final streetJson = {
        'id': 456,
        'name': 'Baker Street',
      };

      final street = Street.fromJson(streetJson);

      expect(street.id, 456);
      expect(street.name, 'Baker Street');
    });

    test('fromJson handles null values', () {
      final streetJson = {
        'id': null,
        'name': null,
      };

      final street = Street.fromJson(streetJson);

      expect(street.id, 0);
      expect(street.name, '');
    });


    test('toJson creates a valid map', () {
      final street = Street(
        id: 456,
        name: 'Baker Street',
      );

      final streetJson = street.toJson();

      expect(streetJson['id'], 456);
      expect(streetJson['name'], 'Baker Street');
    });
  });

  group('API test', () {
    test('Fetches data from API', () async {
      const url = 'https://data.police.uk/api/crimes-street/all-crime?lat=52.629729&lng=-1.131592';
      final response = await http.get(Uri.parse(url));

      print('API response status code: ${response.statusCode}');
      print('API response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      expect(response.statusCode, 200); // Expecting a successful response
    });
  });
}

class CrimeData {
  final int id;
  final String category;
  final String month;
  final Location location;

  CrimeData({
    required this.id,
    required this.category,
    required this.month,
    required this.location,
  });

  factory CrimeData.fromJson(Map<String, dynamic> json) {
    return CrimeData(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      month: json['month'] ?? '',
      location: json['location'] != null ? Location.fromJson(json['location']) : Location(latitude: '', longitude: '', street: Street(id: 0, name: '')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'month': month,
      'location': location.toJson(),
    };
  }
}

class Location {
  final String latitude;
  final String longitude;
  final Street street;

  Location({
    required this.latitude,
    required this.longitude,
    required this.street,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      street: json['street'] != null ? Street.fromJson(json['street']) : Street(id: 0, name: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'street': street.toJson(),
    };
  }
}

class Street {
  final int id;
  final String name;

  Street({
    required this.id,
    required this.name,
  });

  factory Street.fromJson(Map<String, dynamic> json) {
    return Street(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}