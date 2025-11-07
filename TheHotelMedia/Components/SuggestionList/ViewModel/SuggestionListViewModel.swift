//
//  SuggestionListViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 15/01/25.
//

import Foundation


class SuggestionListViewModel: ObservableObject {
    
    @Published var postData: PostData
    
    init(postData: PostData) {
        self.postData = postData
    }
}
