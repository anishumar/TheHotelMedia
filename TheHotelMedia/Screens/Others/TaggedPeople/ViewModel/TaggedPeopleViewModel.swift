//
//  TaggedPeopleViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 24/12/24.
//

import Foundation


class TaggedPeopleViewModel: ObservableObject {
    
    @Published var taggedPeople: [TaggedRef] = []
    
    init(taggedPeople: [TaggedRef]) {
        self.taggedPeople = taggedPeople
    }
}
