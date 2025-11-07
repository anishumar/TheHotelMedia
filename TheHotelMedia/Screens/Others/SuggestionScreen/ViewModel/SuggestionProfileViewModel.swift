//
//  SuggestionProfileViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

import Foundation



class SuggestionProfileViewModel: ObservableObject {
    
    var suggestion: Suggestion
    
    init(suggestion: Suggestion) {
        self.suggestion = suggestion
    }
    
}
