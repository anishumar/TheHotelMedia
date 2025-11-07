//
//  DropDownMenuViewModel.swift
//  HotelMedia
//
//  Created by MAC on 23/08/24.
//

import Foundation


final class DropDownMenuViewModel: ObservableObject {
    
    @Published var dropDownOpen: Bool = false
    var model: DropDownModel
    @Published var selectedOption: String?
    
    init(model: DropDownModel) {
        self.model = model
        selectedOption = model.selectedAnswer
    }
}
