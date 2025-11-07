//
//  THMStoryViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import Foundation

class THMStoryViewModel: ObservableObject {
    
    var isMyStory: Bool = false
    @Published var currentStoryUser: String = ""
    @Published var stories: [THMStoryUIModel] = []
    
    init() {
        
    }
    
//    func addSubscribers() {
//        $currentStoryUser
//            .sink { id in
//                
//            }
//    }
    
    func getVideoProgressBarFrame(duration: Double) -> Double {
        return duration * 0.1 // convert any second to  between 0 - 1 second
    }
    
    func getStoryModel() -> THMStoryUIModel? {
        if let i = stories.firstIndex(where: { $0.id == currentStoryUser }) {
            return stories[i]
        }
        return nil
    }
    
    func getStories() -> [THMStory]? {
        return getStoryModel()?.stories
    }
    
    func getStory(with index: Int) -> THMStory? {
        return getStories()?[index]
    }
}
