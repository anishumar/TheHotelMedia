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
    let sentByMe: Int?
    let type: String?
    var mediaUrl: String? = nil
    var thumbnailUrl: String? = nil
    var from: String? = nil
    var to: String? = nil
    var thumbnail: UIImage? = nil
    var hasUploaded: Bool? = nil
    var isUploading: Bool? = nil
    var isRemotePDF: Bool? = nil
    var isURL: Bool = false
    var showDate: Bool? = false
    var pdfData: Data? = nil
}
