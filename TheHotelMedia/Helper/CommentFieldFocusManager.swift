//
//  CommentFieldFocusManager.swift
//  HotelMedia
//
//  Created by MAC on 13/08/24.
//

import SwiftUI

class CommentFieldFocusManager: ObservableObject {
    @Published var focusedField: Field? = nil
    
    enum Field: Hashable {
        case toolbar
        case comment
    }
}
