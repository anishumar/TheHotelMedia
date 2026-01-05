//
//  SocketMessageUpdates.swift
//  TheHotelMedia
//
//  Created by Cursor on 03/01/26.
//

import Foundation

struct SocketMessageEditUpdate {
    let messageID: String?
    let clientMessageID: String?
    let message: String?
    let isEdited: Bool?
    let editedAt: String?
    let from: String?
    let to: String?
}

struct SocketMessageDeleteUpdate {
    let messageID: String?
    let clientMessageID: String?
    let isDeleted: Bool?
    let from: String?
    let to: String?
}




