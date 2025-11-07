//
//  PlacesSearchRepresentable.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import SwiftUI
import GooglePlaces

struct PlacesSearchRepresentable: UIViewControllerRepresentable {
    
    // Binding to handle the selected place and presentation state
    @Binding var selectedPlace: GMSPlace?
    @Binding var isPresented: Bool
    
//    @EnvironmentObject var themeManager: ThemeManager
    
    // Coordinator to manage the delegate methods
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // Create the GMSAutocompleteViewController instance
    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        UINavigationBar.appearance().tintColor = UIColor(ThemeManager.shared.currentTheme.label)
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator
//        autocompleteController.overrideUserInterfaceStyle = themeManager.currentTheme == .dark ? .dark : .light
//        let filters = GMSAutocompleteFilter()
//        filters.types = ["restaurant", "casino"]
        return autocompleteController
    }
    
    // Dismiss the controller
    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {
        // Leave empty, no need to update the view controller here
    }
    
    // Coordinator that handles the GMSAutocompleteViewControllerDelegate
    class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        var parent: PlacesSearchRepresentable
        
        init(_ parent: PlacesSearchRepresentable) {
            self.parent = parent
        }
        
        // Called when a place is selected
        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            parent.selectedPlace = place
            parent.isPresented = false // Dismiss the search view when a place is selected
        }
        
        // Called when the user cancels the search
        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: \(error.localizedDescription)")
            print(error)
            parent.isPresented = false // Dismiss on failure
        }
        
        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            parent.isPresented = false // Dismiss when canceled
        }
    }
}

