//
//  GoogleMapView.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import SwiftUI
import UIKit
import GoogleMaps

/*
struct GoogleMapView: UIViewRepresentable {
    @Binding var currentLocation: CLLocationCoordinate2D?
    var applyDarkTheme: Bool = true

    // Create GMSMapView
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        mapView.isMyLocationEnabled = true
//        mapView.settings.myLocationButton = true
        
        // Apply the custom style
        if applyDarkTheme {
            if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
                do {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } catch {
                    print("Failed to load map style: \(error)")
                }
            }
        }
        
        return mapView
    }

    // Update GMSMapView when currentLocation is set
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        if let location = currentLocation {
            let cameraUpdate = GMSCameraUpdate.setTarget(location, zoom: 15)
            mapView.animate(with: cameraUpdate)
        }
    }
    
    // Animate the map to user's current location
    static func dismantleUIView(_ uiView: GMSMapView, coordinator: ()) {
        // Clean up if necessary
    }
}
 */ // 

struct GoogleMapView: UIViewRepresentable {
    @Binding var currentLocation: CLLocationCoordinate2D?
    @Binding var markLocation: CLLocationCoordinate2D?
    var markers: [(CLLocationCoordinate2D, String)]?
    var applyDarkTheme: Bool = true
    var scrollGestures: Bool = true
    var zoom: Float = 15

    func makeUIView(context: Context) -> GMSMapView {
        let mapView = MapViewProvider.shared.mapView
        mapView.isMyLocationEnabled = true
        mapView.settings.scrollGestures = scrollGestures
        mapView.delegate = context.coordinator
        // Set the delegate for handling marker taps

        // Apply the custom style if needed
        if applyDarkTheme, let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
            do {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } catch {
                print("Failed to load map style: \(error)")
            }
        } else {
            mapView.mapStyle = nil
        }
        
        if let location = currentLocation, markLocation == nil {
            let cameraUpdate = GMSCameraUpdate.setTarget(location, zoom: zoom)
            mapView.animate(with: cameraUpdate)
        }
        
        if let markLocation = markLocation {
            // Add a marker at the specified location
            let marker = GMSMarker(position: markLocation)
            marker.title = "Event Location"  // Optional: set a title
            marker.snippet = "Tap to get directions!"  // Optional: set a subtitle
            marker.map = mapView  // Attach the marker to the map
            MapViewProvider.shared.marker = marker
            
            let cameraUpdate = GMSCameraUpdate.setTarget(markLocation, zoom: zoom)
            mapView.animate(with: cameraUpdate)
        }
        
        if let markers {
            var gmsMarkers: [GMSMarker] = []
            for marker in markers {
                let mapMarker = GMSMarker(position: marker.0)
                mapMarker.title = marker.1  // Optional: set a title
//                mapMarker.snippet = "Tap to get directions!"  // Optional: set a subtitle
                mapMarker.map = mapView
                gmsMarkers.append(mapMarker)
            }
            
            MapViewProvider.shared.otherMarkers = gmsMarkers
        }
        
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Update the camera to focus on the user's current location if it’s available
        if let location = currentLocation, markLocation == nil {
            let cameraUpdate = GMSCameraUpdate.setTarget(location, zoom: zoom)
            mapView.animate(with: cameraUpdate)
        }
        
        if let markLocation = markLocation {
            // Add a marker at the specified location
            let marker = GMSMarker(position: markLocation)
            marker.title = "Event Location"  // Optional: set a title
            marker.snippet = "Long press to get directions!"  // Optional: set a subtitle
            marker.map = mapView  // Attach the marker to the map
            MapViewProvider.shared.marker = marker
            
            let cameraUpdate = GMSCameraUpdate.setTarget(markLocation, zoom: zoom)
            mapView.animate(with: cameraUpdate)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            // Open Google Maps or Apple Maps for directions
            
            if mapView.selectedMarker == marker {
                mapView.selectedMarker = nil
            } else {
                mapView.selectedMarker = marker
            }
            
            return true
        }
        
        
        func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
            guard marker.position.latitude == MapViewProvider.shared.marker.position.latitude, marker.position.longitude == MapViewProvider.shared.marker.position.longitude else { return }
            
            let destination = "\(marker.position.latitude),\(marker.position.longitude)"
            if let url = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback to Apple Maps if Google Maps is not installed
                    if let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination)&dirflg=d") {
                        UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
                    }
                }
            }
        }
        
//        func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
//            // Customize the info window view
//            let infoWindow = UIView()
//            infoWindow.backgroundColor = .white
//            infoWindow.layer.cornerRadius = 8
//            infoWindow.layer.borderWidth = 1
//            infoWindow.layer.borderColor = UIColor.gray.cgColor
//            
//            let titleLabel = UILabel()
//            titleLabel.text = marker.title
//            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
//            titleLabel.textAlignment = .center
//            titleLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
//            
//            infoWindow.addSubview(titleLabel)
//            return infoWindow
//        }
    }
}

class MapViewProvider {
    static let shared = MapViewProvider()
    
    private init() {}
    
    lazy var mapView: GMSMapView = {
        let mapView = GMSMapView()
        mapView.isMyLocationEnabled = true
        return mapView
    }()
    
    
    lazy var marker: GMSMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
        didSet {
            oldValue.map = nil
//            marker.map = mapView
        }
//        
//        willSet {
//            newValue.map = mapView
//        }
    }
    
    lazy var otherMarkers: [GMSMarker] = []{
        didSet {
            for marker in oldValue {
                marker.map = nil
            }
        }
    }
}
