import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _currentPosition = LatLng(0, 0); // initialize with a default value
  String _currentAddress = ''; // store the address of the current position

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: FutureBuilder<Position>(
        future: getLocation(), // call getLocation method
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // if location is retrieved, update _currentPosition and show GoogleMap widget
            _currentPosition =
                LatLng(snapshot.data!.latitude, snapshot.data!.longitude);
            return GoogleMapWidget(
              currentPosition: _currentPosition,
              onPositionChanged: (position) {
                // update _currentPosition when user moves the map
                setState(() {
                  _currentPosition = position;
                });
              },
              onPositionIdle: () async {
                // get the address of the current position when user stops moving the map
                List<Placemark> placemarks = await placemarkFromCoordinates(
                    _currentPosition.latitude, _currentPosition.longitude);
                setState(() {
                  _currentAddress = placemarks.first.street ?? '';
                });
              },
            );
          } else if (snapshot.hasError) {
            // if location is not retrieved, show an error message
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            // if location is not yet retrieved, show a loading indicator
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // show a dialog with the current address
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Current Address'),
              content: Text(
                _currentAddress,
                style: TextStyle(color: Colors.black),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
        label: Text('Show Address'),
        icon: Icon(Icons.location_on),
      ),
    );
  }

  Future<Position> getLocation() async {
    // request location permission and get current position
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position;
  }
}

class GoogleMapWidget extends StatefulWidget {
  // custom widget for Google Maps
  final LatLng currentPosition;
  final Function(LatLng) onPositionChanged;
  final Function() onPositionIdle;

  const GoogleMapWidget({
    Key? key,
    required this.currentPosition,
    required this.onPositionChanged,
    required this.onPositionIdle,
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.currentPosition,
        zoom: 16.0,
      ),
      onCameraMove: (position) {
        // call the callback function when the camera moves
        widget.onPositionChanged(position.target);
      },
      onCameraIdle: () {
        // call the callback function when the camera stops moving
        widget.onPositionIdle();
      },
    );
  }
}
