//
//  AllAmenitiesViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 21/02/25.
//

import SwiftUI
import Combine


class AllAmenitiesViewModel: ObservableObject {
    
    let amenities: [AmenitiesRef]
    @Published var sortedAmenties: [[AmenitiesRef]] = []
    
    init(amenities: [AmenitiesRef]) {
        self.amenities = amenities
        self.sortedAmenties = groupAndSortAmenities(amenities)
    }
    
    
    func groupAndSortAmenities(_ amenities: [AmenitiesRef]) -> [[AmenitiesRef]] {
        var groupedAmenities = Dictionary(grouping: amenities) { $0.category?.isEmpty == false ? $0.category! : "Uncategorized" }
        
        let sortedGroups = groupedAmenities.sorted { $0.key < $1.key }
        
        return sortedGroups.map { $0.value.sorted { ($0.name ?? "") < ($1.name ?? "") } }
    }
}
