# crime_test_app

Project Summary:
The provided code is a Dart codebase for a mobile application called "Crime Alert" built using the Flutter framework. This app allows users to view crime-related data on a map and receive notifications related to crimes.

Main Components:
1. **Firebase Messaging**: The app integrates Firebase Cloud Messaging (FCM) to handle push notifications. It sets up notification channels and handles incoming messages.

2. **Flutter Local Notifications**: The Flutter Local Notifications plugin is used to show local notifications to the user when a new crime-related notification is received.

3. **Google Maps Integration**: The app utilizes the `google_maps_flutter` package to display a map with markers indicating crime locations. It also uses polygons to represent dangerous areas.

4. **HTTP Requests**: The app makes HTTP requests to fetch crime data from the Police API (`https://data.police.uk/api/crimes-street/all-crime`). It then processes the data and creates markers on the map accordingly.

5. **Geolocation**: The app uses the `geolocator` package to get the user's location and display it on the map as a marker with a magenta hue.

6. **User Interface**: The app has a bottom navigation bar with two tabs: "Map" and "Notifications". The "Map" tab displays the crime data on the map, and the "Notifications" tab shows crime-related notifications.

Functionality Overview:
- The app initializes Firebase, sets up notification handling, and requests permission for displaying notifications.
- It fetches crime data from the Police API, processes it, and displays crime markers on the map.
- The user's location is displayed on the map as a marker with a magenta hue.
- The user can adjust the zoom level using a slider to view crimes in different zoom levels.
- The "Notifications" tab displays a list of crime-related notifications received by the user.
- When the user taps on a notification in the "Notifications" tab, the app will navigate to the map and zoom to the corresponding crime marker's location.

Potential Improvements:
- The app could benefit from additional features, such as filtering crimes by type or date.
- Adding user authentication to enable personalized crime alerts based on the user's location could be valuable.
- Improving the UI and UX to make the app more user-friendly and visually appealing.

