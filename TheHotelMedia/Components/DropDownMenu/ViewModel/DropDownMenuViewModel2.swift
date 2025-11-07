//
//  DropDownMenuViewModel2.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Foundation


final class DropDownMenuViewModel2: ObservableObject {
    
    @Published var dropDownOpen: Bool = false
    var model: DropDownModel2
    @Published var selectedOption: String?
    
    init(model: DropDownModel2) {
        self.model = model
        selectedOption = model.selectedAnswer
    }
}
