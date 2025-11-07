//
//  StoryScreenUIUser.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import Foundation


struct THMStoryUIUser: Identifiable, Hashable {
    public var id: String
    public var name: String
    public var username: String?
    public var image: String
    
    public init(id: String = UUID().uuidString, name: String, image: String, username: String? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.username = username
    }
}
