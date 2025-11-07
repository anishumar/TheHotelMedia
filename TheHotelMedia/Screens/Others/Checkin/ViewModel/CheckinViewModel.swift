//
//  CheckinViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 01/10/24.
//

import SwiftfulRouting
import SwiftUI
import CoreLocation
import GooglePlaces
import Combine

class CheckinViewModel: ObservableObject {
    
    var router: AnyRouter
    var onSelectingPlace: ((ProfileData) -> Void)?
    let dataManager = PlacesDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var places: [Place] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var selectedSearchPlace: GMSPlace? = nil
    @Published var markers: [(CLLocationCoordinate2D, String)] = []
    @Published var selectedPlaceFromList: Place? = nil
    @Published var selectedPlace: ProfileData? = nil
    @Published var showSearchScreen: Bool = false
    @Published var refreshMap: Bool = false
    
    init(router: AnyRouter, onSelectingPlace: ((ProfileData) -> Void)? = nil) {
        self.router = router
        self.onSelectingPlace = onSelectingPlace
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $selectedSearchPlace
            .sink { [weak self] gmsPlace in
                guard let self else { return }
                if let gmsPlace {
                    print(gmsPlace)
                    if let placeID = gmsPlace.placeID {
                        getBusinessProfile(placeID: placeID)
                    }
                    
                }
            }
            .store(in: &cancellables)
        
        $selectedPlaceFromList
            .sink { [weak self] place in
                guard let self else { return }
                if let place {
                    if let placeID = place.placeID {
                        getBusinessProfile(placeID: placeID)
                    }
                }
            }
            .store(in: &cancellables)
        
        $selectedPlace
            .sink { [weak self] place in
                guard let self else { return }
                if let place {
                    onSelectingPlace?(place)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
                        guard let self else { return }
                        dismissScreen()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}


// MARK: - Networking
extension CheckinViewModel {
    func getPlaces(location: CLLocationCoordinate2D) {
        
        showLoadingIndicator = true
        
        Task {
            var querys: [URLQueryItem] = []
            
            querys.append(URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"))
            querys.append(URLQueryItem(name: "radius", value: "5000"))
            querys.append(URLQueryItem(name: "types", value: "restaurant|bar|hotel|night_club"))
            querys.append(URLQueryItem(name: "key", value: "\(googlePlacesKey)"))
            
            do {
                let result = try await dataManager.getPlaces(querys: querys)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    if var results = result.results {
                        results = results.map({ place in
                            var newPlace = place
                            let name = place.name?.capitalized
                            newPlace.name = name
                            
                            return newPlace
                        })
                        places = results
                        
                        var markers: [(CLLocationCoordinate2D, String)] = []
                        
                        for place in result.results ?? [] {
                            markers.append((CLLocationCoordinate2D(latitude: CLLocationDegrees(place.geometry?.location?.lat ?? 0.0), longitude: CLLocationDegrees(place.geometry?.location?.lng ?? 0.0)), place.name ?? ""))
                        }
                        
                        self.markers = markers
                        refreshMap.toggle()
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    
    func getBusinessProfile(placeID: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBusinessProfile(placeID: placeID)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if var data = result.data {
                            data.businessProfileRef?.placeID = placeID
                            onSelectingPlace?(data)
                            dismissScreen()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
}
