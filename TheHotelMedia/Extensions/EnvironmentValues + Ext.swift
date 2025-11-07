//
//  EnvironmentValues + Ext.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import SwiftUI


struct BusinessTypeKey: EnvironmentKey {
    static let defaultValue: String = "BusinessType"
}

struct BusinessSubTypeKey: EnvironmentKey {
    static let defaultValue: String = "BusinessSubType"
}

extension EnvironmentValues {
    var businessTypeID: String {
        get { self[BusinessTypeKey.self] }
        set { self[BusinessTypeKey.self] = newValue }
    }
    
    var businessSubTypeID: String {
        get { self[BusinessSubTypeKey.self] }
        set { self[BusinessSubTypeKey.self] = newValue }
    }
}
