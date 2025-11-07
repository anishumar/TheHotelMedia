//
//  StoryScreenUIModel.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import Foundation


struct THMStoryUIModel: Identifiable, Hashable {
    var id: String
    var user: THMStoryUIUser
    var isSeen: Bool = false
    var stories: [THMStory]
    var isMyStory: Bool = false
    
    init(id: String = UUID().uuidString, user: THMStoryUIUser, isSeen: Bool = false, stories: [THMStory], isMyStory: Bool = false) {
        self.id = id
        self.user = user
        self.isSeen = isSeen
        self.stories = stories
        self.isMyStory = isMyStory
    }
}
