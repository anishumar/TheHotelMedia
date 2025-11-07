//
//  StoryEnums.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import Foundation


// MARK: - StoryType
enum THMStoryType: Equatable, Hashable {
    case plain(config: THMStoryInteractionConfig? = nil)
    case message(
        config: THMStoryInteractionConfig? = nil,
        emojis: [[String]]? = nil,
        placeholder: String
    )
}

// MARK: - StoryUIMediaType
enum THMStoryUIMediaType: Equatable {
    case image
    case video
}

// MARK: - StoryUIMediaStateType
enum THMStoryUIMediaStateType {
    case seen
    case notSeen
}

// MARK: - StoryDirectionEnum
enum THMStoryDirectionEnum {
    case previous
    case next
}

 // MARK: - MediaState
enum THMMediaState {
    case started
    case notStarted
    case restart
    case ready
    case stopped
    case playbackStarted
    case playbackStopped
}


struct THMStoryInteractionConfig: Equatable, Hashable {
    let showLikeButton: Bool
    
    init(showLikeButton: Bool = false) {
        self.showLikeButton = showLikeButton
    }
    
}


struct THMStoryConfiguration: Equatable, Hashable {
    var storyType: THMStoryType
    var mediaType: THMStoryUIMediaType
    
    init(storyType: THMStoryType = .plain(), mediaType: THMStoryUIMediaType) {
        self.storyType = storyType
        self.mediaType = mediaType
    }
}


extension NSNotification.Name {
    static let stopVideoTHM = Notification.Name("stopVideo")
    static let restartVideoTHM = Notification.Name("restartVideo")
    static let replaceCurrentItemTHM = Notification.Name("replaceCurrentItem")
    static let stopAndRestartVideoTHM = Notification.Name("stopAndRestartVideo")
}
