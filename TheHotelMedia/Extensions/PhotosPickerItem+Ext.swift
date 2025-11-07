//
//  PhotosPickerItem+Ext.swift
//  HotelMedia
//
//  Created by MAC on 12/08/24.
//

import Foundation
import PhotosUI
import SwiftUI


extension PhotosPickerItem {
    var isVideo: Bool {
        let videoUTTypes: [UTType] = [
            .avi,
            .video,
            .mpeg2Video,
            .mpeg4Movie,
            .mpeg,
            .appleProtectedMPEG4Video,
            .quickTimeMovie,
            .audiovisualContent
        ]
        
        return videoUTTypes.contains(where: supportedContentTypes.contains)
    }
}
