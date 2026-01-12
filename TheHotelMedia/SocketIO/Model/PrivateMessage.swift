//
//  PrivateMessage.swift
//  TheHotelMedia
//
//  Created by MAC on 27/11/24.
//

import UIKit


struct PrivateMessage: Identifiable {
    let id: String?
    let createdAt: String?
    let isSeen: Int?
    let content: String?
    var sentByMe: Int?
    let type: String?
    
    /// MongoDB `_id` (server-side). Present once the message is persisted / fetched.
    var messageID: String? = nil
    
    /// Client-generated UUID included in outgoing socket payloads so the backend can echo it back.
    var clientMessageID: String? = nil
    
    /// Edit/Delete metadata (optional; depends on backend payload).
    var isEdited: Bool? = nil
    var editedAt: String? = nil
    var isDeleted: Bool? = nil
    var deletedAt: String? = nil
    
    var mediaUrl: String? = nil
    var thumbnailUrl: String? = nil
    
    // Shared-post metadata (present when the message represents a shared post/media, not a normal upload)
    var mediaID: String? = nil
    var postID: String? = nil
    var postOwnerID: String? = nil
    var isSharedPost: Bool? = nil
    
    var from: String? = nil
    var to: String? = nil
    var thumbnail: UIImage? = nil
    var hasUploaded: Bool? = nil
    var isUploading: Bool? = nil
    /// 0.0 ... 1.0 upload progress for outgoing media messages.
    /// Only used for locally-created "sending" bubbles (WhatsApp-style progress UI).
    var uploadProgress: Double? = nil
    var isRemotePDF: Bool? = nil
    var isURL: Bool = false
    var showDate: Bool? = false
    var pdfData: Data? = nil
}
